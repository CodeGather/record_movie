package com.jokui.rao.record_movie;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.hardware.Camera;
import android.media.MediaRecorder;
import android.os.Bundle;
import android.os.SystemClock;
import android.util.Log;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.alibaba.fastjson.JSONObject;
import com.gyf.immersionbar.BarHide;
import com.gyf.immersionbar.ImmersionBar;

import java.io.File;
import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.concurrent.atomic.AtomicBoolean;

/**
 * 仿微信录制视频
 * 基于ffmpeg视频编译
 * Created by zhaoshuang on 19/6/18.
 */
public class RecordedActivity extends BaseActivity {

    public static final String INTENT_PATH = "intent_path";
    public static final String INTENT_DATA_TYPE = "result_data_type";
    private static final String TAG = "MainActivity";

    public static final int RESULT_TYPE_VIDEO = 1;
    public static final int RESULT_TYPE_PHOTO = 2;

    public static final int REQUEST_CODE_KEY = 100;

    // 布局相关
    //预览SurfaceView
    private SurfaceView surfaceView;
    private ImageView iv_back;
    private ImageView iv_next;
    private ImageView iv_close;
    private ImageView iv_change_camera;
    //底部 "点击拍照, 长按录制" 按钮
    private RecordedButton rb_start;
    private ImageView iv_finish;
    private ImageView iv_change_flash;
    private TextView tv_hint;
    private CameraHelp mCameraHelp;
    private SurfaceHolder mSurfaceHolder;

    // 整体布局用于适配导航栏
    private RelativeLayout buttonLayout;
    private RelativeLayout rl_bottom;
    private RelativeLayout back_bottom;
    private RelativeLayout rl_bottom2;
    private RelativeLayout rl_top;

    // 视频录制时间
    private long videoDuration;
    //拍照
    private AtomicBoolean isShotPhoto = new AtomicBoolean(false);
    //录制视频
    private MediaRecorder mMediaRecorder;
    //判断是否正在录制
    private AtomicBoolean isRecordVideo = new AtomicBoolean(false);
    //段视频保存的目录
    private File mTargetFile;
    //当前进度/时间
    private long recordTime;
    //录制最大时间
    public static float MAX_VIDEO_TIME = 90f*1000;
    //最小录制时间
    public static float MIN_VIDEO_TIME = 2f*1000;
    //分段视频地址
    private ArrayList<String> videoPath = new ArrayList<>();
    //分段视频时间
    private ArrayList<Long> timeList = new ArrayList<>();

    private String dirPath;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_recorded);

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
        surfaceView = findViewById(R.id.surfaceView);
        // 返回按钮
        iv_back = findViewById(R.id.iv_back);
        // 下一步按钮
        iv_next = findViewById(R.id.iv_next);
        iv_close = findViewById(R.id.iv_close);

        // 闪光灯按钮
        if(getIntent().getBooleanExtra("showFlash", true)){
            iv_change_flash = findViewById(R.id.iv_change_flash);
            iv_change_flash.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    mCameraHelp.changeFlash();
                    if (mCameraHelp.isFlashOpen()) {
                        iv_change_flash.setImageResource(R.mipmap.video_flash_open);
                    } else {
                        iv_change_flash.setImageResource(R.mipmap.video_flash_close);
                    }
                }
            });
        }

        // 切换相机按钮
        if(getIntent().getBooleanExtra("showCamera", true)){
            iv_change_camera = findViewById(R.id.iv_change_camera);
            iv_change_camera.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    if(mCameraHelp.getCameraId() == Camera.CameraInfo.CAMERA_FACING_BACK){
                        mCameraHelp.openCamera(mContext, Camera.CameraInfo.CAMERA_FACING_FRONT, mSurfaceHolder);
                    }else{
                        mCameraHelp.openCamera(mContext, Camera.CameraInfo.CAMERA_FACING_BACK, mSurfaceHolder);
                    }
                    // 需要判断是否有闪关灯按钮
                    if(getIntent().getBooleanExtra("showFlash", true)){
                        iv_change_flash.setImageResource(R.mipmap.video_flash_close);
                    }
                }
            });
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

        // 相机预览界面
        surfaceView.post(new Runnable() {
            @Override
            public void run() {
                int width = surfaceView.getWidth();
                int height = surfaceView.getHeight();
                float viewRatio = width*1f/height;
                float videoRatio = 9f/16f;
                ViewGroup.LayoutParams layoutParams = surfaceView.getLayoutParams();
                if(viewRatio > videoRatio){
                    layoutParams.width = width;
                    layoutParams.height = (int) (width/viewRatio);
                }else{
                    layoutParams.width = (int) (height*viewRatio);
                    layoutParams.height = height;
                }
                surfaceView.setLayoutParams(layoutParams);
            }
        });

        /* 监听返回按钮 */
        rb_close.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
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
    private void initMediaRecorder() {
        mCameraHelp = new CameraHelp();
        mMediaRecorder = new MediaRecorder();

        mCameraHelp.setPreviewCallback(new Camera.PreviewCallback() {
            @Override
            public void onPreviewFrame(byte[] data, Camera camera) {
                if(isShotPhoto.get()){
                    isShotPhoto.set(false);
                    shotPhoto(data);
//                }else{
//                    if(isRecordVideo.get() && mOnPreviewFrameListener!=null){
//                        mOnPreviewFrameListener.onPreviewFrame(data);
//                    }
                }
            }
        });

        surfaceView.getHolder().addCallback(new SurfaceHolder.Callback() {
            @Override
            public void surfaceCreated(SurfaceHolder holder) {
                mSurfaceHolder = holder;
                mCameraHelp.openCamera(mContext, Camera.CameraInfo.CAMERA_FACING_BACK, mSurfaceHolder);
            }
            @Override
            public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {

            }
            @Override
            public void surfaceDestroyed(SurfaceHolder holder) {
                mCameraHelp.release();
            }
        });

        surfaceView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mCameraHelp.callFocusMode();
            }
        });

//        mVideoEditor.setOnProgessListener(new onVideoEditorProgressListener() {
//            @Override
//            public void onProgress(VideoEditor v, int percent) {
//                if(percent==100){
//                    executeProgress++;
//                }
//                int pro = (int) (executeProgress/executeCount*100);
//                editorTextView.setText("视频编辑中"+pro+"%");
//            }
//        });
    }

    // 拍照
    private void shotPhoto(final byte[] nv21){

//        TextView textView = showProgressDialog();
//        textView.setText("图片截取中");
        RxJavaUtil.run(new RxJavaUtil.OnRxAndroidListener<String>() {
            @Override
            public String doInBackground() throws Throwable {

                boolean isFrontCamera = mCameraHelp.getCameraId()== Camera.CameraInfo.CAMERA_FACING_FRONT;
                int rotation;
                if(isFrontCamera){
                    rotation = 270;
                }else{
                    rotation = 90;
                }

                byte[] yuvI420 = new byte[nv21.length];
                byte[] tempYuvI420 = new byte[nv21.length];

                int videoWidth =  mCameraHelp.getHeight();
                int videoHeight =  mCameraHelp.getWidth();

//                LibyuvUtil.convertNV21ToI420(nv21, yuvI420, mCameraHelp.getWidth(), mCameraHelp.getHeight());
//                LibyuvUtil.compressI420(yuvI420, mCameraHelp.getWidth(), mCameraHelp.getHeight(), tempYuvI420,
//                        mCameraHelp.getWidth(), mCameraHelp.getHeight(), rotation, isFrontCamera);

                Bitmap bitmap = Bitmap.createBitmap(videoWidth, videoHeight, Bitmap.Config.ARGB_8888);

//                LibyuvUtil.convertI420ToBitmap(tempYuvI420, bitmap, videoWidth, videoHeight);

//                String photoPath = LanSongFileUtil.DEFAULT_DIR+System.currentTimeMillis()+".jpeg";
//                FileOutputStream fos = new FileOutputStream(photoPath);
//                bitmap.compress(Bitmap.CompressFormat.JPEG, 100, fos);
//                fos.close();

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

    private void initData() {
        // 设置最小时间
        MIN_VIDEO_TIME = getIntent().getFloatExtra("minTime", 1)*1000;
        // 设置最大时间
        MAX_VIDEO_TIME = getIntent().getFloatExtra("maxTime", 20)*1000;

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

                // 开始录制
                startRecord();
            }

            @Override
            public void onClick() {
//                if(!isRecordVideo.get()){
//                    // 隐藏按钮
//                    goneRecordLayout();
//                    isShotPhoto.set(true);
//                }
            }

            @Override
            public void onLift() {
                isRecordVideo.set(false);
                // 完成录制
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

                jsonObject.put("code", "200");
                jsonObject.put("msg", "视频录制完成");
                jsonObject.put("data", result);
                //转化成json字符串

                // 返回数据
                RecordMoviePlugin._eventSink.success(jsonObject);
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

    /**
     * 开始录制
     */
    private void startRecord() {
        if (mMediaRecorder != null) {
            try {
                mMediaRecorder.reset();
                mCameraHelp.getCamera().unlock();
                mMediaRecorder.setCamera(mCameraHelp.getCamera());
                // 设置最大时间
                long countTime = 0;
                for (long time : timeList) {
                    countTime += time;
                }
                Log.d(TAG, "startRecord: 剩余时间"+(getIntent().getFloatExtra("maxTime", 20)*1000-countTime));
                // 设置文件最大大小
                // mMediaRecorder.setMaxFileSize(100000);
                // 设置视频录制的最大时间
                mMediaRecorder.setMaxDuration((int) (getIntent().getFloatExtra("maxTime", 20)*1000-countTime));
                // 从相机采集视频
                mMediaRecorder.setVideoSource(MediaRecorder.VideoSource.CAMERA);
                // 从麦克采集音频信息
                mMediaRecorder.setAudioSource(MediaRecorder.AudioSource.MIC);
                // TODO: 2016/10/20  设置视频格式
                mMediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4);

                mMediaRecorder.setVideoSize(mCameraHelp.getWidth(), mCameraHelp.getHeight());
                Log.d(TAG, "startRecord: "+mCameraHelp.getWidth() + "------" + mCameraHelp.getHeight());
                // 每秒的帧数
                // mMediaRecorder.setVideoFrameRate(24);
                // 编码格式
                mMediaRecorder.setVideoEncoder(MediaRecorder.VideoEncoder.DEFAULT);
                mMediaRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB);
                // mediarecorder.setProfile(CamcorderProfile.get(CamcorderProfile.QUALITY_480P));            //7.43M  10frame
                // mediarecorder.setProfile(CamcorderProfile.get(CamcorderProfile.QUALITY_1080P));           //70.94M  10frame
                // mediarecorder.setProfile(CamcorderProfile.get(CamcorderProfile.QUALITY_CIF));             // 2.6M  5frame/10frame
                // mediarecorder.setProfile(CamcorderProfile.get(CamcorderProfile.QUALITY_QCIF));            //0.76M   30frame  模糊
                // mediarecorder.setProfile(CamcorderProfile.get(CamcorderProfile.QUALITY_QVGA));            //2.1M
                // mediarecorder.setProfile(CamcorderProfile.get(CamcorderProfile.QUALITY_TIME_LAPSE_CIF));  //不支持
                // mediarecorder.setProfile(CamcorderProfile.get(CamcorderProfile.QUALITY_LOW));             //766KB  还行  比QUALITY_QCIF好
                //mMediaRecorder.setProfile(CamcorderProfile.get(CamcorderProfile.QUALITY_TIME_LAPSE_LOW)); //1M 质量类似LOW
                // mediarecorder.setProfile(CamcorderProfile.get(CamcorderProfile.QUALITY_TIME_LAPSE_480P)); //480p效果


                // 设置帧频率，然后就清晰了
                mMediaRecorder.setVideoEncodingBitRate(1024 * 1024 * 2);
                // TODO: 2016/10/20 临时写个文件地址, 稍候该!!!x
                // File targetDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES);
                mTargetFile = new File(dirPath + SystemClock.currentThreadTimeMillis() + ".mp4");
                mMediaRecorder.setOutputFile(mTargetFile.getAbsolutePath());
                mMediaRecorder.setPreviewDisplay(mSurfaceHolder.getSurface());
                // 解决录制视频, 播放器横向问题
                final boolean isFrontCamera = mCameraHelp.getCameraId()== Camera.CameraInfo.CAMERA_FACING_FRONT;
                int rotation = 270;
                if(!isFrontCamera){
                    rotation = 90;
                }
                mMediaRecorder.setOrientationHint(rotation);
                // 录制出现错误时
                mMediaRecorder.setOnErrorListener(onErrorListener);
                // 录制完成时
                mMediaRecorder.setOnInfoListener(onInfoListener);

                mMediaRecorder.prepare();

                // 正式录制
                mMediaRecorder.start();

                // 设置录制状态
                isRecordVideo.set(true);

                new Thread() {
                    @Override
                    public void run() {
                        super.run();
                        try {
                            Thread.sleep(601);//休眠3秒
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        }
                        runLoopPro();
                    }
                }.start();

            } catch (Exception e) {
                e.printStackTrace();
            }

        }
    }

    /**
     * 停止录制 并且保存
     */
//    private void stopRecordSave() {
//        Log.d(TAG, "视频已经放至" + mTargetFile.getAbsolutePath());
//        videoPath.add(mTargetFile.getAbsolutePath());
//        // Toast.makeText(this, "视频已经放至" + mTargetFile.getAbsolutePath(), Toast.LENGTH_SHORT).show();
//    }

//    private void downTime(){
//        mProgress = 0;
//        mProgressThread = new Thread() {
//            @Override
//            public void run() {
//                super.run();
//                try {
//                    isRunning = true;
//                    while (isRunning) {
//                        mProgress++;
//                        rb_start.setProgress(mProgress);
//                        Log.d(TAG, "run: "+mProgress);
//                        // mHandler.obtainMessage(0).sendToTarget();
//                        Thread.sleep(100);
//                    }
//                } catch (InterruptedException e) {
//                    e.printStackTrace();
//                }
//            }
//        };
//
//        mProgressThread.start();
//    }

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
                mMediaRecorder.stop();
                timeList.add( Utils.getVideoDuration(mTargetFile.getAbsolutePath()));
                Log.d(TAG, "视频时长-" + Utils.getVideoDuration(mTargetFile.getAbsolutePath()) + "\n已放至--" + mTargetFile.getAbsolutePath());

                videoPath.add(mTargetFile.getAbsolutePath());
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

//        stopRecordSave();
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
                Toast.makeText(RecordedActivity.this, e.getMessage(), Toast.LENGTH_SHORT).show();
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

    // 离开界面是暂停
    @Override
    public void onPause() {
        super.onPause();
        Log.d(TAG, "onPause: ");
    }

    // 销毁页面
    @Override
    protected void onDestroy() {
        super.onDestroy();

        if(mCameraHelp != null){
            mCameraHelp.release();
        }
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
