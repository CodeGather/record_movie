package com.civiccloud.rao.record_movie;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.ImageFormat;
import android.graphics.Matrix;
import android.graphics.RectF;
import android.graphics.SurfaceTexture;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CameraMetadata;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.params.StreamConfigurationMap;
import android.media.Image;
import android.media.ImageReader;
import android.media.MediaRecorder;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.HandlerThread;
import android.os.SystemClock;
import android.util.Log;
import android.util.Size;
import android.util.SparseIntArray;
import android.view.Surface;
import android.view.TextureView;
import android.view.View;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import com.alibaba.fastjson.JSONObject;
import com.gyf.immersionbar.BarHide;
import com.gyf.immersionbar.ImmersionBar;

import java.io.File;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * 仿微信录制视频
 * 基于ffmpeg视频编译
 * Created by zhaoshuang on 19/6/18.
 */
@RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
public class RecordedActivity2 extends BaseActivity {

    public static final String INTENT_PATH = "intent_path";
    public static final String INTENT_DATA_TYPE = "result_data_type";
    private static final String TAG = "MainActivity";

    public static final int RESULT_TYPE_VIDEO = 1;
    public static final int RESULT_TYPE_PHOTO = 2;

    public static final int REQUEST_CODE_KEY = 100;

    // 布局相关
    //预览SurfaceView
    private AutoFitTextureView textureView;
    private ImageView iv_back;
    private ImageView iv_next;
    private ImageView iv_close;
    private ImageView iv_change_camera;
    //底部 "点击拍照, 长按录制" 按钮
    private RecordedButton rb_start;
    private ImageView iv_finish;
    private ImageView iv_change_flash;
    private TextView tv_hint;

    // 整体布局用于适配导航栏
    private RelativeLayout buttonLayout;
    private RelativeLayout rl_bottom;
    private RelativeLayout back_bottom;
    private RelativeLayout rl_bottom2;
    private RelativeLayout rl_top;

    private Handler mHandler;

    private ImageReader mImageReader;

    // 视频录制时间
    private long videoDuration;
    //拍照
    private AtomicBoolean isShotPhoto = new AtomicBoolean(false);
    //录制视频
    private MediaRecorder mMediaRecorder;
    //判断是否正在录制
    private AtomicBoolean isRecordVideo = new AtomicBoolean(false);
    //段视频保存的目录
    private String mTargetFile;
    //当前进度/时间
    private long recordTime;
    //录制最大时间
    public static float MAX_VIDEO_TIME = 20f*1000;
    //最小录制时间
    public static float MIN_VIDEO_TIME = 2f*1000;
    //分段视频地址
    private ArrayList<String> videoPath = new ArrayList<>();
    //分段视频时间
    private ArrayList<Long> timeList = new ArrayList<>();

    private String dirPath;

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_recorded2);

        ImmersionBar.with(this)
                .hideBar(BarHide.FLAG_HIDE_BAR)
                .init();

        initUI();
        initData();
        createPath();
        initMediaRecorder();
    }

    private void initUI() {
        // 关闭按钮
        ImageView rb_close = findViewById(R.id.record_close);
        // 相机预览
        textureView = (AutoFitTextureView)findViewById(R.id.texture);
        // 返回按钮
        iv_back = findViewById(R.id.iv_back);
        // 下一步按钮
        iv_next = findViewById(R.id.iv_next);
        iv_close = findViewById(R.id.iv_close);

        // 闪光灯按钮
        if(getIntent().getBooleanExtra("showFlash", true)){
            iv_change_flash = findViewById(R.id.iv_change_flash);
            iv_change_flash.setOnClickListener(new View.OnClickListener() {
                @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
                @Override
                public void onClick(View v) {
//                    mCameraHelp2.changeFlash();
//                    if (mCameraHelp2.isFlashOpen()) {
//                        iv_change_flash.setImageResource(R.mipmap.video_flash_open);
//                    } else {
//                        iv_change_flash.setImageResource(R.mipmap.video_flash_close);
//                    }
                }
            });
        }

        // 切换相机按钮
        if(getIntent().getBooleanExtra("showCamera", true)){
            iv_change_camera = findViewById(R.id.iv_change_camera);
//            iv_change_camera.setOnClickListener(new View.OnClickListener() {
//                @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
//                @Override
//                public void onClick(View v) {
//                    if(mCameraHelp2.getCameraId() == Camera.CameraInfo.CAMERA_FACING_BACK){
//                        mCameraHelp2.openCamera(mContext, Camera.CameraInfo.CAMERA_FACING_FRONT, mSurfaceHolder);
//                    }else{
//                        mCameraHelp2.openCamera(mContext, Camera.CameraInfo.CAMERA_FACING_BACK, mSurfaceHolder);
//                    }
//                    // 需要判断是否有闪关灯按钮
//                    if(getIntent().getBooleanExtra("showFlash", true)){
//                        iv_change_flash.setImageResource(R.mipmap.video_flash_close);
//                    }
//                }
//            });
        }

        // 提示文字
        tv_hint = findViewById(R.id.tv_hint);
        tv_hint.setText(getIntent().getStringExtra("tipText"));

        rb_start = findViewById(R.id.rb_start);

        // 动态修改整体布局适配
        int barHeight = ImmersionBar.getNavigationBarHeight(this);
        Log.d(TAG, "获得到底部导航栏高度: "+barHeight);
        buttonLayout = findViewById(R.id.buttonLayout);
        RelativeLayout.LayoutParams ly = (RelativeLayout.LayoutParams) buttonLayout.getLayoutParams();
        ly.setMargins(0, 0, 0, barHeight);
        buttonLayout.setLayoutParams(ly);

        iv_finish = findViewById(R.id.iv_finish);

        rl_bottom = (RelativeLayout) findViewById(R.id.rl_bottom);
        rl_bottom2 = (RelativeLayout) findViewById(R.id.rl_bottom2);
        back_bottom = (RelativeLayout) findViewById(R.id.back_bottom);

        // 拍摄界面顶部布局
        rl_top = (RelativeLayout) findViewById(R.id.rl_top);

        /* 监听返回按钮 */
        rb_close.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                JSONObject jsonObject = new JSONObject();
                jsonObject.put("code", 205);
                jsonObject.put("status", false);
                jsonObject.put("msg", "取消录制");
                jsonObject.put("data", "");
                //转化成json字符串

                // 返回数据
                if( RecordMoviePlugin._eventSink != null ){
                    RecordMoviePlugin._eventSink.success(jsonObject);
                }
                RecordMoviePlugin.resultData.success(jsonObject);

                // 判断是否开启回删功能，否则点击时直接退出页面
                if(getIntent().getBooleanExtra("isOpenDel", true)){
                    onBackPressed();
                } else {
                    finish();
                }
            }
        });
    }

    // 监听操作
    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    private void initMediaRecorder() {
        mMediaRecorder = new MediaRecorder();

        startBackgroundThread();

        if (textureView.isAvailable()) {
            openCamera(textureView.getWidth(), textureView.getHeight());
        } else {
            textureView.setSurfaceTextureListener(mSurfaceTextureListener);
        }
    }

    /**
     * Tries to open a {@link CameraDevice}. The result is listened by `mStateCallback`.
     */
    private Integer mSensorOrientation;
    private CaptureRequest.Builder mPreviewBuilder;
    /**
     * The {@link android.util.Size} of camera preview.
     */
    private Size mPreviewSize;

    /**
     * The {@link android.util.Size} of video recording.
     */
    private Size mVideoSize;
    private Semaphore mCameraOpenCloseLock = new Semaphore(1);
    private CameraDevice mCameraDevice;

    @SuppressWarnings("MissingPermission")
    private void openCamera(int width, int height) {

        mImageReader = ImageReader.newInstance(1080, 1920, ImageFormat.JPEG,1);
        mImageReader.setOnImageAvailableListener(new ImageReader.OnImageAvailableListener() { //可以在这里处理拍照得到的临时照片 例如，写入本地
            @Override
            public void onImageAvailable(ImageReader reader) {
                mCameraDevice.close();
                // 拿到拍照照片数据
                Image image = reader.acquireNextImage();
                ByteBuffer buffer = image.getPlanes()[0].getBuffer();
                byte[] bytes = new byte[buffer.remaining()];
                buffer.get(bytes);//由缓冲区存入字节数组
                final Bitmap bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
                if (bitmap != null) {
//                    iv_show.setImageBitmap(bitmap);
                }
            }
        }, null);

        CameraManager manager = (CameraManager) this.getSystemService(Context.CAMERA_SERVICE);
        try {
            Log.d(TAG, "tryAcquire");
            if (!mCameraOpenCloseLock.tryAcquire(2500, TimeUnit.MILLISECONDS)) {
                throw new RuntimeException("Time out waiting to lock camera opening.");
            }
            String cameraId = manager.getCameraIdList()[0];

            // Choose the sizes for camera preview and video recording
            CameraCharacteristics characteristics = manager.getCameraCharacteristics(cameraId);
            StreamConfigurationMap map = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP);
            mSensorOrientation = characteristics.get(CameraCharacteristics.SENSOR_ORIENTATION);
            if (map == null) {
                throw new RuntimeException("Cannot get available preview/video sizes");
            }
            mVideoSize = chooseVideoSize(map.getOutputSizes(MediaRecorder.class));
            mPreviewSize = chooseOptimalSize(map.getOutputSizes(SurfaceTexture.class), width, height, mVideoSize);

            int orientation = getResources().getConfiguration().orientation;
            if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
                textureView.setAspectRatio(mPreviewSize.getWidth(), mPreviewSize.getHeight());
            } else {
                textureView.setAspectRatio(mPreviewSize.getHeight(), mPreviewSize.getWidth());
            }
            configureTransform(width, height);
            manager.openCamera(cameraId, new CameraDevice.StateCallback() {
                @Override
                public void onOpened(@NonNull CameraDevice cameraDevice) {
                    mCameraDevice = cameraDevice;
                    startPreview();
                    mCameraOpenCloseLock.release();
                    if (null != textureView) {
                        configureTransform(textureView.getWidth(), textureView.getHeight());
                    }
                }

                @Override
                public void onDisconnected(@NonNull CameraDevice cameraDevice) {
                    mCameraOpenCloseLock.release();
                    cameraDevice.close();
                    mCameraDevice = null;
                }

                @Override
                public void onError(@NonNull CameraDevice cameraDevice, int error) {
                    mCameraOpenCloseLock.release();
                    cameraDevice.close();
                    mCameraDevice = null;
                    finish();
                }

            }, null);
        } catch (CameraAccessException e) {
            Toast.makeText(getApplicationContext(), "Cannot access the camera.", Toast.LENGTH_SHORT).show();
            finish();
        } catch (NullPointerException e) {
            // Currently an NPE is thrown when the Camera2API is used but not supported on the
            // device this code runs.
        } catch (InterruptedException e) {
            throw new RuntimeException("Interrupted while trying to lock camera opening.");
        }
    }

    // 配置预览界面
    private void configureTransform(int viewWidth, int viewHeight) {
        if (null == textureView) {
            return;
        }
        int rotation = this.getWindowManager().getDefaultDisplay().getRotation();
        Matrix matrix = new Matrix();
        RectF viewRect = new RectF(0, 0, viewWidth, viewHeight);
        RectF bufferRect = new RectF(0, 0, textureView.getHeight(), textureView.getWidth());
        float centerX = viewRect.centerX();
        float centerY = viewRect.centerY();
        if (Surface.ROTATION_90 == rotation || Surface.ROTATION_270 == rotation) {
            bufferRect.offset(centerX - bufferRect.centerX(), centerY - bufferRect.centerY());
            matrix.setRectToRect(viewRect, bufferRect, Matrix.ScaleToFit.FILL);
            float scale = Math.max( (float) viewHeight / mPreviewSize.getHeight(), (float) viewWidth / mPreviewSize.getWidth());
            matrix.postScale(scale, scale, centerX, centerY);
            matrix.postRotate(90 * (rotation - 2), centerX, centerY);
        }
        textureView.setTransform(matrix);
    }

    /**
     * In this sample, we choose a video size with 3x4 aspect ratio. Also, we don't use sizes
     * larger than 1080p, since MediaRecorder cannot handle such a high-resolution video.
     *
     * @param choices The list of available sizes
     * @return The video size
     */
    private static Size chooseVideoSize(Size[] choices) {
        for (Size size : choices) {
            if (size.getWidth() == size.getHeight() * 4 / 3 && size.getWidth() <= 1080) {
                return size;
            }
        }
        Log.e(TAG, "Couldn't find any suitable video size");
        return choices[choices.length - 1];
    }

    /**
     * Given {@code choices} of {@code Size}s supported by a camera, chooses the smallest one whose
     * width and height are at least as large as the respective requested values, and whose aspect
     * ratio matches with the specified value.
     *
     * @param choices     The list of sizes that the camera supports for the intended output class
     * @param width       The minimum desired width
     * @param height      The minimum desired height
     * @param aspectRatio The aspect ratio
     * @return The optimal {@code Size}, or an arbitrary one if none were big enough
     */
    private static Size chooseOptimalSize(Size[] choices, int width, int height, Size aspectRatio) {
        // Collect the supported resolutions that are at least as big as the preview Surface
        List<Size> bigEnough = new ArrayList<>();
        int w = aspectRatio.getWidth();
        int h = aspectRatio.getHeight();
        for (Size option : choices) {
            if (option.getHeight() == option.getWidth() * h / w &&
                    option.getWidth() >= width && option.getHeight() >= height) {
                bigEnough.add(option);
            }
        }

        // Pick the smallest of those, assuming we found any
        if (bigEnough.size() > 0) {
            return Collections.min(bigEnough, new CompareSizesByArea());
        } else {
            Log.e(TAG, "Couldn't find any suitable preview size");
            return choices[0];
        }
    }

    /**
     * Compares two {@code Size}s based on their areas.
     */
    static class CompareSizesByArea implements Comparator<Size> {

        @Override
        public int compare(Size lhs, Size rhs) {
            // We cast here to ensure the multiplications won't overflow
            return Long.signum((long) lhs.getWidth() * lhs.getHeight() - (long) rhs.getWidth() * rhs.getHeight());
        }

    }

    private CameraCaptureSession mPreviewSession;

    private void closePreviewSession() {
        if (mPreviewSession != null) {
            mPreviewSession.close();
            mPreviewSession = null;
        }
    }

    // 开始预览相机
    private void startPreview() {
        if (null == mCameraDevice || !textureView.isAvailable() || null == mPreviewSize) {
            return;
        }
        try {
            closePreviewSession();
            SurfaceTexture texture = textureView.getSurfaceTexture();
            assert texture != null;
            texture.setDefaultBufferSize(mPreviewSize.getWidth(), mPreviewSize.getHeight());
            mPreviewBuilder = mCameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);

            Surface previewSurface = new Surface(texture);
            mPreviewBuilder.addTarget(previewSurface);

            mCameraDevice.createCaptureSession(Collections.singletonList(previewSurface), new CameraCaptureSession.StateCallback() {
                @Override
                public void onConfigured(@NonNull CameraCaptureSession session) {
                    mPreviewSession = session;
                    updatePreview();
                }

                @Override
                public void onConfigureFailed(@NonNull CameraCaptureSession session) {
                    Toast.makeText(RecordedActivity2.this, "Failed", Toast.LENGTH_SHORT).show();
                }
            }, mBackgroundHandler);
        } catch (CameraAccessException e) {
            e.printStackTrace();
        }
    }

    // 更新相机预览
    private void updatePreview() {
        if (null == mCameraDevice) {
            return;
        }
        try {
            mPreviewBuilder.set(CaptureRequest.CONTROL_MODE, CameraMetadata.CONTROL_MODE_AUTO);
            HandlerThread thread = new HandlerThread("CameraPreview");
            thread.start();
            mPreviewSession.setRepeatingRequest(mPreviewBuilder.build(), null, mBackgroundHandler);
        } catch (CameraAccessException e) {
            e.printStackTrace();
        }
    }

    /**
     * An additional thread for running tasks that shouldn't block the UI.
     */
    private HandlerThread mBackgroundThread;

    /**
     * A {@link Handler} for running tasks in the background.
     */
    private Handler mBackgroundHandler;

    /**
     * Starts a background thread and its {@link Handler}.
     */
    private void startBackgroundThread() {
        mBackgroundThread = new HandlerThread("CameraBackground");
        mBackgroundThread.start();
        mBackgroundHandler = new Handler(mBackgroundThread.getLooper());
    }

    private static final int SENSOR_ORIENTATION_DEFAULT_DEGREES = 90;
    private static final int SENSOR_ORIENTATION_INVERSE_DEGREES = 270;
    private static final SparseIntArray DEFAULT_ORIENTATIONS = new SparseIntArray();
    private static final SparseIntArray INVERSE_ORIENTATIONS = new SparseIntArray();
    static {
        DEFAULT_ORIENTATIONS.append(Surface.ROTATION_0, 90);
        DEFAULT_ORIENTATIONS.append(Surface.ROTATION_90, 0);
        DEFAULT_ORIENTATIONS.append(Surface.ROTATION_180, 270);
        DEFAULT_ORIENTATIONS.append(Surface.ROTATION_270, 180);
    }

    static {
        INVERSE_ORIENTATIONS.append(Surface.ROTATION_0, 270);
        INVERSE_ORIENTATIONS.append(Surface.ROTATION_90, 180);
        INVERSE_ORIENTATIONS.append(Surface.ROTATION_180, 90);
        INVERSE_ORIENTATIONS.append(Surface.ROTATION_270, 0);
    }

    // 开始录制
    private void startRecordingVideo() {
        if (null == mCameraDevice || !textureView.isAvailable() || null == mPreviewSize) {
            return;
        }
        try {
            closePreviewSession();
            setUpMediaRecorder();
            SurfaceTexture texture = textureView.getSurfaceTexture();
            assert texture != null;
            texture.setDefaultBufferSize(mPreviewSize.getWidth(), mPreviewSize.getHeight());
            mPreviewBuilder = mCameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_RECORD);
            List<Surface> surfaces = new ArrayList<>();

            // Set up Surface for the camera preview
            Surface previewSurface = new Surface(texture);
            surfaces.add(previewSurface);
            mPreviewBuilder.addTarget(previewSurface);

            // Set up Surface for the MediaRecorder
            Surface recorderSurface = mMediaRecorder.getSurface();
            surfaces.add(recorderSurface);
            mPreviewBuilder.addTarget(recorderSurface);

            // Start a capture session
            // Once the session starts, we can update the UI and start recording
            mCameraDevice.createCaptureSession(surfaces, new CameraCaptureSession.StateCallback() {

                @Override
                public void onConfigured(@NonNull CameraCaptureSession cameraCaptureSession) {
                    mPreviewSession = cameraCaptureSession;
                    updatePreview();
                    RecordedActivity2.this.runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            // Start recording
                            mMediaRecorder.start();

                            isRecordVideo.set(true);

                            runLoopPro();
                        }
                    });
                }

                @Override
                public void onConfigureFailed(@NonNull CameraCaptureSession cameraCaptureSession) {
                    Toast.makeText(getApplicationContext(), "Failed", Toast.LENGTH_SHORT).show();
                }
            }, mBackgroundHandler);
        } catch (CameraAccessException | IOException e) {
            e.printStackTrace();
        }

    }

    // 设置录制参数
    private void setUpMediaRecorder() throws IOException {
        // 设置最大时间
        long countTime = 0;
        for (long time : timeList) {
            countTime += time;
        }
        Log.d(TAG, "startRecord: 剩余时间"+(getIntent().getFloatExtra("maxTime", 20)*1000-countTime));
        mMediaRecorder.setMaxDuration((int) (getIntent().getFloatExtra("maxTime", 20)*1000-countTime));

        mMediaRecorder.setAudioSource(MediaRecorder.AudioSource.MIC);
        mMediaRecorder.setVideoSource(MediaRecorder.VideoSource.SURFACE);
        mMediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4);

        mTargetFile = dirPath + SystemClock.currentThreadTimeMillis() + ".mp4";
        mMediaRecorder.setOutputFile(mTargetFile);

        mMediaRecorder.setVideoEncodingBitRate(1024 * 1024 * 2);
        mMediaRecorder.setVideoFrameRate(30);
        mMediaRecorder.setVideoSize(mVideoSize.getWidth(), mVideoSize.getHeight());

        Log.d(TAG, "startRecord: "+mVideoSize.getWidth() + "------" + mVideoSize.getHeight());

        mMediaRecorder.setVideoEncoder(MediaRecorder.VideoEncoder.H264);
        mMediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC);

        // 录制出现错误时
        mMediaRecorder.setOnErrorListener(onErrorListener);
        // 录制完成时
        mMediaRecorder.setOnInfoListener(onInfoListener);

        int rotation = this.getWindowManager().getDefaultDisplay().getRotation();
        switch (mSensorOrientation) {
            case SENSOR_ORIENTATION_DEFAULT_DEGREES:
                mMediaRecorder.setOrientationHint(DEFAULT_ORIENTATIONS.get(rotation));
                break;
            case SENSOR_ORIENTATION_INVERSE_DEGREES:
                mMediaRecorder.setOrientationHint(INVERSE_ORIENTATIONS.get(rotation));
                break;
        }
        mMediaRecorder.prepare();
    }

    // 停止录制
    private void stopRecordingVideo() {
        // Stop recording
        mMediaRecorder.stop();
        mMediaRecorder.reset();

        timeList.add(Utils.getVideoDuration(mTargetFile));
        Log.d(TAG, "视频时长-" + Utils.getVideoDuration(mTargetFile) + "\n已放至--" + mTargetFile);

        videoPath.add(mTargetFile);

        mTargetFile = null;
        startPreview();
    }

    // 拍照
    private void shotPhoto(final byte[] nv21){

//        TextView textView = showProgressDialog();
//        textView.setText("图片截取中");
        RxJavaUtil.run(new RxJavaUtil.OnRxAndroidListener<String>() {
            @Override
            public String doInBackground() throws Throwable {
                if (mCameraDevice == null) return null;
                // 创建拍照需要的CaptureRequest.Builder
                final CaptureRequest.Builder captureRequestBuilder;
                try {
                    captureRequestBuilder = mCameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_STILL_CAPTURE);
                    // 将imageReader的surface作为CaptureRequest.Builder的目标
                    captureRequestBuilder.addTarget(mImageReader.getSurface());
                    // 自动对焦
                    captureRequestBuilder.set(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE);
                    // 自动曝光
                    captureRequestBuilder.set(CaptureRequest.CONTROL_AE_MODE, CaptureRequest.CONTROL_AE_MODE_ON_AUTO_FLASH);
                    // 获取手机方向
                    int rotation = getWindowManager().getDefaultDisplay().getRotation();
                    // 根据设备方向计算设置照片的方向
//                    captureRequestBuilder.set(CaptureRequest.JPEG_ORIENTATION, ORIENTATIONS.get(rotation));
                    //拍照
                    CaptureRequest mCaptureRequest = captureRequestBuilder.build();
                    mPreviewSession.capture(mCaptureRequest, null, null);
                } catch (CameraAccessException e) {
                    e.printStackTrace();
                }

                return null;
            }
            @Override
            public void onFinish(String result) {
                // closeProgressDialog();

                Intent intent = new Intent();
                intent.putExtra(INTENT_PATH, result);
                intent.putExtra(INTENT_DATA_TYPE, RESULT_TYPE_PHOTO);
                setResult(Activity.RESULT_OK, intent);
                finish();
            }
            @Override
            public void onError(Throwable e) {
                // closeProgressDialog();
                Toast.makeText(getApplicationContext(), "图片截取失败", Toast.LENGTH_SHORT).show();
            }
        });
    }

    @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
    private void initData() {
        // 设置最小时间
        MIN_VIDEO_TIME = getIntent().getFloatExtra("minTime", 1)*1000;
        // 设置最大时间
        MAX_VIDEO_TIME = getIntent().getFloatExtra("maxTime", 20)*1000;

        HandlerThread handlerThread = new HandlerThread("CameraHelp2");
        handlerThread.start();
        mHandler = new Handler(handlerThread.getLooper());

        rb_start.setParame(MAX_VIDEO_TIME,  getIntent().getDoubleExtra("progressWidth", 6.0), getIntent().getStringExtra("progressColor"), getIntent().getStringExtra("progressBgColor"));
        rb_start.setOnGestureListener(new RecordedButton.OnGestureListener() {
            @Override
            public void onLongClick() {
                if (rb_start.getProgress() >= MAX_VIDEO_TIME) {
                    return;
                }

                // 设置录制时间
                recordTime = System.currentTimeMillis();

                // 设置视频长度
                videoDuration = 0;

                // 设置断点
                rb_start.setSplit();

                // 隐藏按钮
                goneRecordLayout();

                startRecordingVideo();
            }

            @Override
            public void onClick() {
//                if(!isRecordVideo.get()){
//                    // 隐藏按钮
//                    goneRecordLayout();
////                    shotPhoto();
//                }
            }

            @Override
            public void onLift() {
                isRecordVideo.set(false);
                upEvent();
            }

            @Override
            public void onOver() {
                rb_start.closeButton();
            }
        });

        // 删除视频按钮
        iv_back.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (rb_start.isDeleteMode()) {//判断是否要删除视频段落
                    iv_back.setImageResource(R.mipmap.video_delete);

                    if(videoPath.size()>0 && timeList.size()>0) {
                        videoPath.remove(videoPath.size() - 1);
                        timeList.remove(timeList.size() - 1);

                        // 删除视频段
                        rb_start.deleteSplit();

                        // 重新设置进度
                        long countTime = 0;
                        for (long time : timeList) {
                            countTime += time;
                        }
                        rb_start.setProgress(countTime);
                    } else {
                        // 没有数据清空段落
                        rb_start.cleanSplit();
                        isRecordVideo.set(false);
                        /* 返回按钮状态 */
                        back_bottom.setVisibility(View.VISIBLE);
                    }
                    initRecorderState();
                } else if (rb_start.getSplitCount() > 0) {
                    rb_start.setDeleteMode(true);
                    iv_back.setImageResource(R.mipmap.video_delete_click);
                }
            }
        });

        iv_next.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finishVideo();
            }
        });

        // 完成按钮
        iv_finish.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finishVideo();
            }
        });

    }

    // 录制和暂停时的布局切换
    private void changeButton(boolean flag){
        if(flag){
            // 提示文字
            tv_hint.setVisibility(View.VISIBLE);
            rl_bottom.setVisibility(View.VISIBLE);
            // 返回按钮
            back_bottom.setVisibility(View.GONE);
        }else{
            tv_hint.setVisibility(View.GONE);
            rl_bottom.setVisibility(View.GONE);
        }
    }

    public void finishVideo(){
        RxJavaUtil.run(new RxJavaUtil.OnRxAndroidListener<String>() {
            @Override
            public String doInBackground()throws Exception{
                String mp4Path = dirPath + System.currentTimeMillis()+".mp4";
                // 合成视频
                Utils.mergeVideos(videoPath, mp4Path);
                return mp4Path;
            }
            @Override
            public void onFinish(String result) {
                // closeProgressDialog();

                JSONObject jsonObject = new JSONObject();

                jsonObject.put("code", 200);
                jsonObject.put("status", true);
                jsonObject.put("msg", "视频录制完成");
                jsonObject.put("data", result);
                //转化成json字符串

                // 返回数据
                if( RecordMoviePlugin._eventSink != null ){
                    RecordMoviePlugin._eventSink.success(jsonObject);
                }
                RecordMoviePlugin.resultData.success(jsonObject);

                // 删除录制的分段视频
                deleteSplitFile();
                // 销毁页面
                finish();
                // Intent intent = new Intent(mContext, EditVideoActivity.class);
                // intent.putExtra(INTENT_PATH, result);
                // startActivityForResult(intent, REQUEST_CODE_KEY);
            }
            @Override
            public void onError(Throwable e) {
                e.printStackTrace();
                // closeProgressDialog();
                Toast.makeText(getApplicationContext(), "视频合成失败", Toast.LENGTH_SHORT).show();
            }
        });
    }

    // 倒计时
    private void runLoopPro(){
        RxJavaUtil.loop(20, new RxJavaUtil.OnRxLoopListener() {
            @Override
            public Boolean takeWhile(){
                return isRecordVideo.get();
            }
            @Override
            public void onExecute() {
                long currentTime = System.currentTimeMillis();
                videoDuration += 20;
                recordTime = currentTime;
                long countTime = videoDuration;
                for (long time : timeList) {
                    countTime += time;
                }
                if (videoDuration <= MAX_VIDEO_TIME) {
                    // 设置视频进度
                    rb_start.setProgress(countTime);
                }
            }
            @Override
            public void onFinish() {
                stopRecordingVideo();
                upEvent();
            }
            @Override
            public void onError(Throwable e) {
                e.printStackTrace();
                // 删除视频段
                rb_start.deleteSplit();
            }
        });
    }

    private void upEvent(){
        rb_start.closeButton();
        changeButton(rb_start.getSplitCount() > 0 );

        initRecorderState();
    }

    // 删除视频
    private void deleteSegment(){
        showConfirm("确认删除上一段视频?", new View.OnClickListener() {
            @Override
            public void onClick(View v) {
//                closeProgressDialog();

                if(videoPath.size()>0 && timeList.size()>0) {
                    videoPath.remove(videoPath.size() - 1);
                    timeList.remove(timeList.size() - 1);
                    // 删除视频段
                    rb_start.deleteSplit();
                }
                initRecorderState();
            }
        });
    }

    /**
     * 初始化视频拍摄状态
     */
    private void initRecorderState(){

        if (rb_start.getSplitCount() > 0) {
            // 关闭删除时显示返回按钮
            if(getIntent().getBooleanExtra("isOpenDel", true)){
                iv_back.setVisibility(View.VISIBLE);
            } else {
                iv_back.setVisibility(View.GONE);
                back_bottom.setVisibility(View.VISIBLE);
            }
            tv_hint.setText(getIntent().getStringExtra("tipPauseText"));
        } else {
            if(getIntent().getBooleanExtra("isOpenDel", true)){
                iv_back.setVisibility(View.GONE);
            }
            tv_hint.setText(getIntent().getStringExtra("tipText"));
            // 带返回按钮的布局
            back_bottom.setVisibility(View.VISIBLE);
            rl_bottom.setVisibility(View.GONE);
            iv_close.setVisibility(View.VISIBLE);
        }

        // 显示提示文字
        tv_hint.setVisibility(View.VISIBLE);

        if (rb_start.getProgress()* MAX_VIDEO_TIME < MIN_VIDEO_TIME) {
            iv_next.setVisibility(View.GONE);
        } else {
            iv_next.setVisibility(View.VISIBLE);
        }

    }

    // 点击按钮或者长按时切换按钮
    private void goneRecordLayout(){
        // 提示文字
        tv_hint.setVisibility(View.GONE);
        // 带删除以及完成按钮
        rl_bottom.setVisibility(View.GONE);
        // 带返回按钮布局
        back_bottom.setVisibility(View.GONE);
    }

    /**
     * 清除录制信息
     */
    private void cleanRecord(){
        // 清空断点数组
        rb_start.cleanSplit();
        // 清空路径数组
        videoPath.clear();
        // 清空时间数组
        timeList.clear();
        // 清空进度条
        rb_start.setProgress(0);

        // 显示返回按钮
        iv_back.setVisibility(View.INVISIBLE);
//        iv_next.setVisibility(View.INVISIBLE);
        // 显示切换相机那妞
        iv_change_flash.setVisibility(View.VISIBLE);
    }

    /**
     * 初始化视频拍摄状态
     */
    private void initMediaRecorderState(){

        isRecordVideo.set(false);

        rl_top.setVisibility(View.VISIBLE);
        rb_start.setVisibility(View.VISIBLE);
        rl_bottom2.setVisibility(View.GONE);
        changeButton(false);
        /* 在此定义按钮的初始状态，否则返回时状态报错 */
        back_bottom.setVisibility(View.VISIBLE);
        tv_hint.setVisibility(View.VISIBLE);


        rb_start.setProgress(0);
        rb_start.cleanSplit();
    }

    // 创建文件夹
    private void createPath(){
        dirPath = getIntent().getStringExtra("outFilePath").isEmpty() ? getExternalCacheDir().getPath() + "/video/" : getIntent().getStringExtra("outFilePath");
        File file = new File(dirPath);
        if (!file.exists()) {
            file.mkdirs();
        }
    }

    // 删除批量文件
    private  void deleteSplitFile(){
        for (String fileUrl : videoPath) {
            File itemFile = new File(fileUrl);
            if(itemFile.exists() && itemFile.isFile()){
                itemFile.delete();
            }
        }
    }

    //录制出错的回调
    private MediaRecorder.OnErrorListener onErrorListener = new MediaRecorder.OnErrorListener() {
        @Override
        public void onError(MediaRecorder mr, int what, int extra) {
            try {
                if (mMediaRecorder != null) {
                    mMediaRecorder.reset();
                }
            } catch (Exception e) {
                Toast.makeText(RecordedActivity2.this, e.getMessage(), Toast.LENGTH_SHORT).show();
            }
        }
    };

    //录制完成的回调
    private MediaRecorder.OnInfoListener onInfoListener = new MediaRecorder.OnInfoListener() {
        @Override
        public void onInfo(MediaRecorder mr, int what, int extra) {
            if(what==MediaRecorder.MEDIA_RECORDER_INFO_MAX_DURATION_REACHED){
                Log.v("VIDEOCAPTURE", "Maximum Duration Reached");
                isRecordVideo.set(false);
            }
        }
    };

    @Override
    public void onBackPressed() {
        if(rb_start.getSplitCount() == 0) {
            super.onBackPressed();
        }else{
            initMediaRecorderState();
        }
    }

    private TextureView.SurfaceTextureListener mSurfaceTextureListener = new TextureView.SurfaceTextureListener() {

        @Override
        public void onSurfaceTextureAvailable(SurfaceTexture surfaceTexture, int width, int height) {
            openCamera(width, height);
        }

        @Override
        public void onSurfaceTextureSizeChanged(SurfaceTexture surfaceTexture, int width, int height) {
            configureTransform(width, height);
        }

        @Override
        public boolean onSurfaceTextureDestroyed(SurfaceTexture surfaceTexture) {
            return true;
        }

        @Override
        public void onSurfaceTextureUpdated(SurfaceTexture surfaceTexture) {
        }

    };
    private void closeCamera() {
        try {
            mCameraOpenCloseLock.acquire();
            closePreviewSession();
            if (null != mCameraDevice) {
                mCameraDevice.close();
                mCameraDevice = null;
            }
            if (null != mMediaRecorder) {
                mMediaRecorder.release();
                mMediaRecorder = null;
            }
        } catch (InterruptedException e) {
            throw new RuntimeException("Interrupted while trying to lock camera closing.");
        } finally {
            mCameraOpenCloseLock.release();
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        startBackgroundThread();
        if (textureView.isAvailable()) {
            openCamera(textureView.getWidth(), textureView.getHeight());
        } else {
            textureView.setSurfaceTextureListener(mSurfaceTextureListener);
        }
    }

    /**
     * Stops the background thread and its {@link Handler}.
     */
    private void stopBackgroundThread() {
        mBackgroundThread.quitSafely();
        try {
            mBackgroundThread.join();
            mBackgroundThread = null;
            mBackgroundHandler = null;
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    // 离开界面是暂停
    @Override
    public void onPause() {
        closeCamera();
        stopBackgroundThread();
        super.onPause();
    }

    // 销毁页面
    @Override
    protected void onDestroy() {
        super.onDestroy();

        if(mMediaRecorder != null) {
            mMediaRecorder = null;
        }
        cleanRecord();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if(resultCode== Activity.RESULT_OK && data!=null){
            if(requestCode == REQUEST_CODE_KEY){
                Intent intent = new Intent();
                intent.putExtra(INTENT_PATH, data.getStringExtra(INTENT_PATH));
                intent.putExtra(INTENT_DATA_TYPE, RESULT_TYPE_VIDEO);
                setResult(Activity.RESULT_OK, intent);
                finish();
            }
        }else{
            cleanRecord();
            initRecorderState();
        }
    }
}
