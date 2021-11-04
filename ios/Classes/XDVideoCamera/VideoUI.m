#import "VideoUI.h"
#import "XDVideocamera.h"
#import "VideoRecordProgressView.h"


static const CGFloat KTimerInterval = 0.02;  //进度条timer
static const CGFloat KMaxRecordTime = 60;    //最大录制时间

//  闪光灯打开按钮
NSString *videoFlashOpen = @"iVBORw0KGgoAAAANSUhEUgAAADQAAABECAMAAAD5hOYYAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAACHUExURQAAAAAAAAAAAAAAAAAAAAAAAAAAAEdwTAAAAAAAAAEBAQAAAAAAAAAAAAMDAwEBAe/v79/f3wQEBIaGhv7+/k1NTfj4+Lu7u/39/dPT0////8bGxvX19b29vfb29qGhoerq6uTk5Pv7++vr6/z8/Pr6+nh4ePn5+d7e3vT09O/v76Ojo////w92BwUAAAAsdFJOUwEODAgTAgkAAwYRBBUaFx2eeiMo9x/NT+5i/Fu6QMY4l4DgiOfcOdRvsKhT6M4gaAAAA/dJREFUSMedl+liojAUhUFwaUyggohURa17zfs/35x7E5YgjJ25/0r9uPsh8ab/YV737zf2CvHjMdvMNfOw4jwX4Z/PB4xYplzIEB/91sYcholg0msBcbMuxAyIEZnftdEImKU6DBDfF46FbEKAm4DqQMTAhf2VNSkjY+DYF7mqITgC44vic8hOKblqQewomIzE7ksP2tbvQNZReBhm9MMfBS5EjpDPt9aHxavRu75TF6Lo2NFO63WmFCeOKkSRiuMkSa5413ofuuF5HkcnwhOCACKpxlRGS620XuZSuIUgRwEcyZvWBZeXGyrgi6Ct1l9FFCK6j6ZPNjoR7vHGjBkzFiIk6AcJLaKwduS50R1RVzDU/AkNB0EKIesDImZHLWg8M9Eh9rukV05obhmK7mB+mKky8uqUyFGK2FMweCXMQJsv9i78JjjPiW6hdWle+UHzjifRbqn1LWv5qTaXxoGjK5FwyxGY/ZmaGrnD6jnRIZLU/N8y6YWaqlqVq4Sljg4prziQgBMKo4ybGvdCNroQPTyajDkhqbipSQ3NHcjMXYac9zY6dvRJTU2SOFZSVE2yUB1dgTrZ6NgRNxXTyq78Vnxeq3YPrU9NdJShLp/PZ77ZFEWRdiHjKFtrvZMV5HdW+FJNK0NVdHKDjthpIU8nd2vXXIo2RNFFmOWDCZ5zSsvz9+VyW63KknzeXQjDyo1E73NT3EkQcPUULW2SHKkgoRueTSnX+hzbOhE0EpYqSFJ4A5tCWEiiKZ+x6aNdJl7AJEf3yqxe9akDIbpNYlz5dgNp1/eo6SWN2tE1EGRI35D0dnsSvLdmbUmGzvuX2bOacmyquxG1QPDE7lqj10Ckx7RsFRTWUmRliOZx3oiXVwtyttvleb5Z8koRI+zEypfPhYFM0alYV/QeY8FKKblBrwxPBLkKbLEwSytFAgumwCQ8ZN9niaDqiwENhrT8kJJDxU2DQtGROwtVFAWILI6KPwCmQY50tU4sTBkpjxT0aBODUkZSehkrLKaCyErh9dcYZiTFMnOXqcSymiVI7JKY+EENCs2SO0VonY0qCKO+IlE41A3qYRwIOVHxAC0GGtSB7PZS8ZKENP8RGX3uYRwIdaDiJU80aNXbIAeyKx8pLNX1ypove4vtQlQHbAKKd+UGReEw04FQvEtJDepu0CCEOtzNQhVKDhS7z5M54xxJJ/qL/QoJWlRokoqaD/n0LUQHI71VLyeGYQjNRfHQIPmOafrEa7hGg8K/NOgVIkk6pn1H1QGID7Ak4BN7KB6Ph5kG4iN50D5+T99CTM2rg/5f/TRT7jWXjNk7poHs5WRW3V5+c3+y16Nx+5r0i0tX92b1Dze1X9kfFumdI6DW+VoAAAAASUVORK5CYII=";

//  闪光灯关闭按钮
NSString *videoFlashClose = @"iVBORw0KGgoAAAANSUhEUgAAADQAAABECAMAAAD5hOYYAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAABIUExURQAAAAQEBAUFBRISEkdwTAAAAAAAAAAAAAEBAQAAAPb29v39/cXFxWxsbJmZmfn5+fv7++np6fLy8uHh4dPT0+7u7q6urv///0WeE+MAAAAXdFJOUwEWHCYABgoCEg3F9VYqONfmkLR7aKNLdBSGJwAAA6RJREFUSMeNl+mWgjAMhWkLyI6IwPu/6eQmTTfRM/kxZ47ymeRmaalqtkqs/p9VAaj+D3roIfZPqqojoti/IDzciAV33yyBmmiPX+a5SpkW1vy0EL5CrZo+0WYWOYX4kW3cerL2hwVKoX68rqnr+h8mmKcecNS/rms1pvthwApoIVe7+WWEMZVA3XZdz9lau7yGL3bMvXdVs3oEzc/r2giiOL/Z9gF17+saF+fG79A7Qhxf33dmuK6XmyjK6dMGOOpSSFyZk76YDgmSM8cf+t85R1FcLyNQlUGWgJWiO5lhmRmycH8NNoESauZ8no4grrNSJ32+ziZEV/Gsq6sd0AFH0hsCLU9UAx/lkFJPpAVH3DVQx9h5hazGJDLUqSuDhJcCIuHGKfRDCqmrlTNWCOGh2G/2o0zt5ze4Ytk1JXxAiqInUyaDWv/QCvE6kWFDUa1PKIOqGB/LvkuZKB8uqo2QbJYkp0ZyINnHWYbBTvQLg7uFeIlxeKzWyqWyWlTnLMvpZymFGskJ7YaeOcFIUZ1zvgacU4CUMTMgFGaghuOinsTM87IssbQKCUNjCAnsgspYN2SzdCC+CAW9d7Q/GvRA1575AD6TpKo6ji799I6kLcvuVnl6HLn39xISRzP3HQ8Qy+6gAWz3U5uFF3fEYL1Bdo9kUxvU0757SXRhVE9hUKwwtSWERBb1hEU2MLOEqc2K6yFE8VzJhje5wrNv1AgFziYwg7aoLlxh4RKECTyT1sugtp/GDOKF624mMK+TQbcsO8+Cl50n0JZMgGSYKJmNl6UR2f0E9n3G1HHveeqFvuPNCtl5AruCUcjX1/Dvn1ZGECI4my3W9MYCyrsiOXRuWfYESq852YpYIJ4/+lj22dxDnuJpf8vekyODZTdZB0VILgYc36a7nLcRn3MmbfAE4gq3sWvDQTNwg3efkuu21LVMB8C5e1eycLNuTSDd5RAPK/LwG5avF6WrAlp4O4wC4VCT60XhqoCoCwZZd50canK9yLZeAfFOfvEZxmcNKJxzWxFfAR2ygCT3ViuH30jjK8KTBfn2jd2G64WP7x6SFefbza93lv0HtMjp7tVSCudc1yZK5NDEK84fEY1f8Xyrm75BtCewrjoVWA+Tdicp/OmZQ0LtxxxukI94JV5MmxyEGcSxtHpXrbKLdNPc1Cm9aMdb8SO95z/uoM/vyzeKqoSq8oUjfpy8NBRDePt1df+alED6ffoSdf9ClmyLL69rNx/+ASAwZY9EY+1bAAAAAElFTkSuQmCC";

//  取消按钮
NSString *backImageStr = @"iVBORw0KGgoAAAANSUhEUgAAADoAAAAgCAYAAABD9mvVAAAAAXNSR0IArs4c6QAAAQFJREFUWAnd2dsJwzAMBdCEbpGf/meoLtUdOlC36BTuVYma2Djk5YeuBcIPTNBBkA+766Zwzt2QD10zj3AM0fon5AujxDN6iGRT6kd+kKNXMjakk4rE9BeUWFQuSA0fi907UjbDoMKi+CVSLW9M+n9nsRiRtFjUHkP6HVUtK/YQkhV7CsmGvYRkwSZBWscmRVrFZkFaw2ZFWsEWQdbGFkXWwlZBlsZWRZbCmkDmxppC5sKaRKbGmkamwlIgr2KpkGexlMijWGrkHiyAfRPIHVi5mQsjfpGlH7M+QrN2u7iEciO1CRvYNpAb2LaQK9g2kQFWfkb+A5AeaGkEcn4LKQj7AkzjlUFYls00AAAAAElFTkSuQmCC";

// 录制视频按钮
NSString *recordVideoCamera = @"iVBORw0KGgoAAAANSUhEUgAAADwAAAAtCAYAAADydghMAAAAAXNSR0IArs4c6QAABEtJREFUaAXtmr9rFEEUxz0NmpgIEjTREEglYhUr61gFFAtBEwQtjGX+gXQpRAL5D+zFqBEsLNRCFLSzEhRBhETiz8IgaISIen6+l53l5czu3t68I+Hwwffm7c7M973v7tzs7Nxt2+Zk1Wq1C1wGC+APiDVxLABxdjml+S8N5FfAKsgy1V2xPTneDh5mdXA4L+7tNqabD/G3BhL8ZgPS/nwDfWKbnLcx3XyyauYOPzZqZvF3xCYkDiCuYI9jOV36k80A+J1k9Yuy34UYEnEBccoUYyCW2+N7MU4SgedRpVL5HJtU6J9wPUqOFUOx4o0rNwiugw8gxibis1nPQDITMQnRV5qkbVDMlcR5jt+7PlTpo5/06OeufC3dM6cD+e2lWqNmZ06zRqqWaTSsYTILYsUq4H1vsSJNOO/LjzRpnNXEYIfxiUjSLdcdfSdBsA8a0tWQJVezEvx2Kq3GMLu2k75cLR25tU6VXGGNnFPgDDgGDoJd4BN4Cx6AOwywV5StNd3uYN6R4NUa+wJ4EWIUlPPUH2pBHmlYTVqpeQaCtBPcSckbd1ZoOuacSxq9JYJh7wVP0yhrzhcKveodB1ro6IIMgXFwG9S/Uk56iYY7tVYJvpdGWHNmKLrzBFB/FLxca1771Bp6NK9Po3WGs+ouGPKzJoCSvlQisT20tyNjiePol3+Tj69giHvAexNAq7hSRt/9dRxTpQg2aGzycRc8AvmPJMAi5e4N4heeot/FhEPF68IOBQ0Ml6/gEJcAGpp94TivpJ1We1eBdlos7CT23dRp8is1i9M+NffvcJ64rDqy0e7GXJpVtrNM1fEsnqzzls5dMOTTQAuIUqs42kv0TZBlb6g4nCUq77wldBMM6S5wzZA3I7qD/rcMR3Cf4OzLE5VXF0hUughWMkBJ1ZuSL3unJVoXK5guotbdTVsgUhktGI7DQMMty25QUWoXk/ZB9HTTKk1Hm1iUYIi0TNREUmSakEqJNvlGuza5pgVDMgb0iAiPEj06gumREs6HUo+ehjYYaNcHeqKVJgRwpda04I2SgfV1ysziYaM2RefovxssJjxaxIwU9SmqT7hqhbfgKUOuJWbpmZU+9tcGcUTfaZNT/KRlry7E+gVxyQR4ir/HtsnzaXsJ6IUj2Nm89o3WBTKVrndYCcA5CmzSeuU7mpcc9d1gBli7l9enTJ0ldResRAgwaYPgaxLTS74muiGgl/9BoFn+MtDkZ00jw2OvvHZdLHFLBCeitZOxYoM16GtbqLOWqdOHjdsywYnoQwSzqyYbu97XRp82/Ny3jm0gvZq1fCOeEEe4AKeBtmyGwAGwCj6CZ2Ae3GWbNs2FYzdbp3Hdwf9fHtwu8pYhcv++bBllGYn8F5xxYdrmtO6wZsqaMYGdDH67lHWaPuqxdB1x59pFYIGOOQnWnz08/uNREGvTq9f+48Gj9x2pDIM5kA7vTU/PLwFpkrZhaf0LHnAt9XQv4eoAAAAASUVORK5CYII=";

// 点击删除按钮图标
NSString * videoDelete = @"iVBORw0KGgoAAAANSUhEUgAAAJYAAACWCAMAAAAL34HQAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAABIUExURf///x949V+e+VaY+f///xdz9RFv9EdwTP///////yx+9v///////////xRw9cjf/5vD/P///0ON93qv+xt09TWF9iV69hFu9EcWMN8AAAAXdFJOUya6WGAh2PgAEwOZHAcM6y87GXJIyYeqbZXNwgAABMlJREFUeNrNnOm6oyAMhqOigwXq0u3+73Ss2nqqAgm4JD997Mx7IPkIEQL/4qzURjaNUkJAZ0Io1TTS6DLyn4Xwn3ZAqodZM6E6uMOxStNYif6wNaY8DktLBNIXTeojsEoK04es3BerNAqCTBFnE/YdqNAhAwIURBoBDA6DIoHBgVAEMBSWEbCZCbMRlm5gU2v0FlgSNjcZjVUq2MFUGYe1pVdRPAyOnkDcRLqwtIIdTekwLC1gVxM6BMvA7mboWAdQObjgeGfHOD6cSmXlgnOpbFxwMpWFC87ydrffw+lUq1xLLA2Hm/Zj7a3tOL1fYCk4wZQPS8IpJt1YBk4y48IqxVlYonRgKTjNlB1LwokmbVgaTjVtwWrOxWrWsQycbGYN67woXIlG4OHvc6//YpXAwMoFluSAJedYLAZrGi7gNFjTcAGrwfoOF7AarO9wARPNmmkX8BD4udRDQEJTZ4+L3drpxXR6+khJCQ6QHb66vNx2+bzZ/jy+3whOD1SHr68eqtf182ry+7zI8E7fYxEcvsp9VK/7593nnLdGOf0Hi5L+3ce/3G7TZFXJ9LT/VYJOB4E2h8MAPCpygKXvuS8q7CwCaQ4fA1VI4Pf+f8POIlDicAitZ5Aepe+fZthYBIKWpsWPR++GZXqshiQNebU7VtNjCYo04II8Dku8sTRFGooU9sfqJAKwrjVIQwtHYJkOS+4tDXQs2WGpGGmos/UIqNosAkt1WCJCGrrn17X/qs4XKw0FS/yDMkYa3jlC0Vrer4OxOigdIw3JahzceqrZAkjC0oAIxMQqDQPALBLStYc0LAMyShpGrsvCDxfvk7AkNHHSMCarU4xmPdXS4UhYjRcr82QN9ZCuJqMntYUlPyZieWTr5s0a6iFhvVeTvq35IQlLebAwWUM1cQ0Tfk0hGkv4g/B6w4TqK69Hqlvs4tNBObFqZNYwBOvVQUXF8i+FmKxh2tLmdfxSjRKHCv2mg2p7LFTmN25rixYOwEqxefIYjQ4uIpbbu/JJksCvXa71YMtIHBc43yb9o/RXBxcRS2HS0guG6rm2cO+j8p/Qd4nEH5gvYDSWN4NIPLWpn5xrtnDvl0F8ctObqxQzOVT1d+GOwPKngcNybZGJRXpVJeuySkwDEUnzmNxUdqpsuUDOuYhJM2avn9lqeelq0jdESR61xUBVtx6WwH+up1cDVxqzIcMVbCwycbEEw/vPKML3iQK72bdsyrq4y1dDNMvzNm6zjyuNeGRi+9IIspA0ZvX1EViGUHZzyMQeZTd0/TuLqDPTi5T4wyIPRDaxBVZDK4AjsolNsAzxc4GjdoOrJ+J+WVI/roTLxJBZ1EjXon6KGmSiuCdUG+QFqVr0D3eDTARaipQH+mfOUSaC7IKVh4CPwpDmYVAFMoJl2Cf0Lqie95xq9wd22SpDDxzsaor/8Qymh1mYHv3helCK6bEyrofwmB5Z5HrAk+lxWK6Hh5keteZ6MJ3rMX6mlx64XhHheqGG6fUjrpe1uF5t43oRkOm1Sa6XTLleyeV6gZnrdW+ul+O5thLg2niBa5sKrk09uLZA4dowhm17Ha7NiLi2bmLb6IprWzC2TdS4tpxj26CPbTtDts0f2bbK5NtYlG8bVr5Na/du8fsfOXD35ibUxFoAAAAASUVORK5CYII=";

// 点击删除按钮图标
NSString *videoClickDelete = @"iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAMAAABHPGVmAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAABIUExURf////////9TSf+rpv////+8t/9BNkdwTP////////////////9EOf94cP/d2v89Mv+Ujf////9NQ/9gV/9IPv+Eff9oYP87MDxVGDIAAAAXdFJOU0ALuV4kVugAOgYzGOGFSfVsLsii1HmWOJJf6wAAAxxJREFUaN7Fmtl2qzAMRWUw1ANhCpT//9PLcJMw2LIIRj0vWZQFu7KPhTzAD1FaWNkYoxSAUsY00gpNfRZIACvHdx+lpNVxIMIN+IDEVYi2BoIyoXhQiJZAlNRfQgQZMWPEFxB9CoFH44NYBael7CmIbuArNZoO+SYMLBgXRMIFSRJEG7gko8MQoeCilAhBrjMcFIjPOFLgBsYo4YdEY+xiWUN0NMZI0R6IgYgyboiEqJIuiIXIskdIzA7Zd8sb0kB0NXuIhRtkt5D4jbVuMLjFWTuHLRABN0msIPIuiPxANNwm/YbI+yDyBbkxkCUUCI+RrH8clP6/tVz1GT5WIJR9y2RwqJpfW1av6zbDsjGE/NsNTtVzIJ/rokRcDIFun+LokoMey93HctWOEf0iXT9CsIzyHJDHP3qMDebNLRNE4w8PCcFC6dheiL8A81ZdIf8hGWJHiL9L0grrUDJEjhBvl5TFMOQZXIaoH9CYeasarkNGhMDM26+N1vVbUxRPIkSAJZp3GniP3f2SBrEgqebtNtSJ0RIjkdBQzVtOlOeqLduSCGnAmR0zl3lnSvJOmgm5440T4jFv2S7vfv3SIcptLLd551bK1u1GgSgXpNyZd+ep6sAIQhzqkYz1O389fk8NRt/4zX0pa7LEUKUnIa5Ycm8oaT5HkqdwtU+m9nJ/RqbhUz2rgy9CEHPig1gvr59/erg4To7ZcQnwFcLcaI8TEHdamUb3vnv7T2dk+TbUUFrxJMgy3w/6KWW+/5IVG0ooQVrit3cq5Ipsm8jIqd770aqHrZGLoSu3iSwnf7Q0tR4q99kspaZ6jRQS1MqOUEhgVWriz5QnSyKkuHMZ+bviDitTj0b2Qjq0TEUL7tnIdRZQ2iIlswpPHeqBqBqfOojQrICiJ+CToMBiWpoUeUBFUkNgOnfP4s1+YsoyxWZZLOBZ9mBZwOFZimJZVONZHmRZ6ORZsuVZfGZZRufZEODZ2uDZpGHZbopHUeL+LUAQf7+ZybMty7PBzLNVzrTpz3N8gecgBtOREp7DMUzHfJgOLDEdveI6RBbhONw/vU9wP0NbQIIAAAAASUVORK5CYII=";

// 视频录制完成按钮图标
NSString * videoFinsh = @"iVBORw0KGgoAAAANSUhEUgAAAJYAAACWCAMAAAAL34HQAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAABIUExURUdwTP///////////////////////////////////////////4O0+xNv9KrM/UqR99bn/2Kg+BZx9St+9jqH9xt09SN59hFu9KLVwU8AAAAXdFJOUwAkPi0VMx5ABzoDDGj3V5RJfu2/qODQgzXOYAAAA8BJREFUeNrNnOnSqjAMhoUuaUEF9/u/049Bz1FRsEkX3vzW8Zk2a02y2cRJ02pbKWWM93Vde2OUqqxum81q4nSlPM2IV5V2ayDNEr2wFUVrK0PBYqq2yDlZBtODzGY+s0YrEonS+YygsZ7E4m0eMFdFQN0NwGWAqila6sRgjU0ANYKlvErtKZl4ner+FCUVleQmU93f603GH5WhDGIcjlal07CKskkFdoGxF9l6yipelFromjJLrRGpJFyWioiFMcEIgyxGxeKyVFCC71FTUdE4Nsi3x7Yw1cAV4Fedp+Lif8chQyuIAXINDDehaSXRaIoVoF6GVhMD4t2Dvb2r18Sq565R0aqiwKxw0RobvzaWb9D0fVbr19X3Wa2vCEAqxMP6clwQh/VxXOub4VdjtAQiFvGwJselCUY0TjSciYyuzC92py7gU66wwp9ut1vHUfoiSel5oLqdGGlqW8J/j1Qhp0VtQQ/f3QIP6+npC9zhYaS69oxiw5WiuvRhn3aFfOl2N1LtWR61KkN1DKV6KFfueLg/8qjIl1CtO9Vuy/iKy69a/YVNNSpXXtXqr6MRHtg5at7sQUI1ZhFZNf4UHHImOt/kDIR3qjP7i03WOH0WUg3ROqMhMsLzhynazFRXWf3D9A/bLtQDcZKGTw/B8w+HYLt6hGcR1eAhFN/gD+FUexJiGYFt/ebacsPzNBPkYQVGuEfSsCUxFtPJB+UDe0F4nrh5buwJyJ4eR3qgCCz2c9vPXFOUNEyiFh/rp+nLwvMES5BALDvKBFQC3frFJQ7P71ii2nU+CJ/F4TnGb/369S4J1YAlzJm/31VMeI6JicuazavpF7HEhc/1gysqaZgkNuI08MNrcmv6xTRQnjRPYsz+mIxqSJrlJUb9FpEFNf1SiRFTkL3kL/0lIdVQkEWVr/+zvQThefJkE1Xs/8uNk1KNxX7U00h9GLl2CcLz5Gkksn69u9AE4XnykBT57FZ3yanub7qxTzaJwvO7xid4dztLa/oF1UrxStmdzn1CLJ3s74KkfQFu9a6t7zkgVLPBu2qV+eOOFac3gLdo8Log7ilg4b/QWXaI23CA2p4B2swC2vqD2igF2laG2oQH2rKI2uAJ2g6L2jwM2mqN2piO2sYPOvSAOiKCOlADOn6EOqyFOtqGOggIOjaJOmSKOpKLOsCMOu6NOhyPukoAdfEC6poK1KUeqCtQUBfGwK7XQV1GhLq6CXbRFepaMNglaqgr52AX9MGuM4Rd/gi7KhN3sSjuGtYnGtrS2qcR5Fnx+wfCRwED+ftUlQAAAABJRU5ErkJggg==";


@interface VideoUI()
@property (nonatomic, strong) SelectImageView *changeBt;
@property (nonatomic, strong) SelectImageView *videoBt;
@property (nonatomic, strong) SelectView *VideoLayerView;
@property (nonatomic, strong) UIView *focusView;
@property (nonatomic, strong) UIView *headerContent;
@property (nonatomic, strong) UIView *footerContent;

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *tipLabel;
@property (nonatomic, strong) UIView *recordBackView;
@property (nonatomic, strong) VideoRecordProgressView *progressView;
@property (nonatomic, strong) UIView *recordButton;
@property (nonatomic, strong) UIButton *flashButton;
@property (nonatomic, strong) UIButton *switchCameraButton;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIButton *finishButton;

@property (nonatomic, strong) SelectImageView *cancel;
@property (nonatomic, strong) SelectImageView *combine;
@property (nonatomic, weak) UIWindow *originKeyWindow;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) CGFloat recordTime;                              //录制时间

@end

//          maxTime: (CGRect)maxRecordTime
//          minTime: (CGRect)minRecordTime
//       flashImage: (CGRect)flashImage
//  flashImageWidth: (CGRect)flashImageWidth
// flashImageHeight: (CGRect)flashImageHeight
//      cameraImage: (CGRect)cameraImage
// cameraImageWidth: (CGRect)cameraImageWidth
//cameraImageHeight: (CGRect)cameraImageHeight
//        backImage: (CGRect)backImage
//   backImageWidth: (CGRect)backImageWidth
//  backImageHeight: (CGRect)backImageHeight
//    inCircleColor: (NSString*) inCircleColor
//   outCircleColor: (NSString*) outCircleColor
//    progressColor: (NSString*) progressColor
//          tipText: (NSString*) tipText
//  tipContinueText: (NSString*) tipContinueText
//       radiusSize: (NSString*) radiusSize
@implementation VideoUI
- (instancetype)initWithFrame: (CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
      // 隐藏状态栏
      self.backgroundColor = [UIColor blackColor];
      frame.origin.y = frame.size.height;
      self.frame = frame;
      self.originKeyWindow = [[UIApplication sharedApplication].delegate window];
      self.originKeyWindow.windowLevel = UIWindowLevelStatusBar + 1;
      
      [self creatMainUI];
    }
    return self;
}

#pragma mark - 视图
- (void)creatMainUI {
  _VideoLayerView = [[SelectView alloc]initWithFrame:CGRectMake(0,0,self.frame.size.width,self.frame.size.height)];
  _VideoLayerView.backgroundColor = [UIColor blackColor];

  [_VideoLayerView tapGestureBlock:^(UITapGestureRecognizer *gesture) {
    [self.delegate videoLayerClick:self.VideoLayerView gesture:gesture];
  }];
  
  _focusView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 60, 60)];
  _focusView.backgroundColor = [UIColor clearColor];
  _focusView.layer.borderColor = [UIColor greenColor].CGColor;
  _focusView.layer.borderWidth = 1.5;
  _focusView.alpha = 0;

  [_VideoLayerView addSubview:_focusView];
  [_VideoLayerView addSubview:self.recordBackView];
  [_VideoLayerView addSubview:self.tipLabel];
  [_VideoLayerView addSubview:self.progressView];
  [_VideoLayerView addSubview:self.recordBtn];
  [_VideoLayerView addSubview:self.flashBtn];
  [_VideoLayerView addSubview:self.switchCameraBtn];
  [_VideoLayerView addSubview:self.backBtn];
  [_VideoLayerView addSubview:self.deleteBtn];
  [_VideoLayerView addSubview:self.finishBtn];
  
  
  [self addSubview:_VideoLayerView];
}

// 底部提示文字
- (UILabel *)tipLabel{
    if (!_tipLabel) {
      _tipLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, self.recordBackView.origin.y - 30, self.width, 20)];
      _tipLabel.textColor = [UIColor whiteColor];
      _tipLabel.text = @"点击拍照, 长按录制";
      _tipLabel.textAlignment = NSTextAlignmentCenter;
      _tipLabel.font = [UIFont systemFontOfSize:12];
    }
    return _tipLabel;
}

#pragma mark - 底部
- (UIView *)recordBackView{
    if (!_recordBackView) {
        CGRect rect = self.recordBtn.frame;
        CGFloat gap = 7.5;
        rect.size = CGSizeMake(rect.size.width + gap*2, rect.size.height + gap*2);
        rect.origin = CGPointMake(rect.origin.x - gap, rect.origin.y - gap);
        _recordBackView = [[UIView alloc]initWithFrame:rect];
        _recordBackView.backgroundColor = [UIColor grayColor];
        _recordBackView.alpha = 0.6;
        [_recordBackView.layer setCornerRadius:_recordBackView.frame.size.width/2];
    }
    return _recordBackView;
}

#pragma mark - 进度条
- (VideoRecordProgressView *)progressView{
    if (!_progressView) {
        _progressView = [[VideoRecordProgressView alloc] initWithFrame:self.recordBackView.frame];
    }
    return _progressView;
}

#pragma mark - 录制按钮
-(UIView *)recordBtn{
    if (!_recordButton) {
      _recordButton = [[UIView alloc]init];
      CGFloat deta = [UIScreen mainScreen].bounds.size.width/375;
      CGFloat width = 60.0*deta;
      _recordButton.frame = CGRectMake((self.width - width)/2, self.height - 107*deta, width, width);
      [_recordButton.layer setCornerRadius:_recordButton.frame.size.width/2];
      _recordButton.backgroundColor = [UIColor whiteColor];
      // 长按事件
      UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(startRecord:)];
      [_recordButton addGestureRecognizer:press];
      // 点击事件
      UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
      [_recordButton addGestureRecognizer:gesture];
      _recordButton.userInteractionEnabled = YES;
    }
    return _recordButton;
}

#pragma mark - 开始拍照
- (void)tapGesture:(UITapGestureRecognizer *)gesture {
  NSLog(@"点击了");
  [self.delegate shutterCamera];
}

#pragma mark - 开始录制
- (void)startRecord:(UILongPressGestureRecognizer *)gesture{
  // 先判断是否还有时间去录制
  if(_recordTime >= KMaxRecordTime){
    return;
  }
  if (gesture.state == UIGestureRecognizerStateBegan) {
    
    if ([self.delegate videoBtClick]) {
      NSLog(@"正在录制");
      [self startRecordAnimate: YES];
      
      CGRect rect = self.progressView.frame;
      rect.size = CGSizeMake(self.recordBackView.size.width - 3, self.recordBackView.size.height - 3);
      rect.origin = CGPointMake(self.recordBackView.origin.x + 1.5, self.recordBackView.origin.y + 1.5);
      self.progressView.frame = self.recordBackView.frame;
      
      // 点击开始时设置断点
      [self.progressView.splitList addObject:[NSNumber numberWithFloat: self.recordTime]];
      // 开始倒计时
      [self startTimer];
      
      // 切换按钮
      self.backButton.hidden = YES;
      self.flashButton.hidden = YES;
      self.tipLabel.hidden = YES;
      self.switchCameraButton.hidden = YES;
      [self switchBtn: YES];
    }
  }else if(gesture.state >= UIGestureRecognizerStateEnded){
    [self stopRecording];
  }else if(gesture.state >= UIGestureRecognizerStateCancelled){
    if (![self.delegate videoBtClick]) {
      NSLog(@"取消录制");
      [self startRecordAnimate: NO];
      [self.progressView changeRadius: NO];
    }
  }else if(gesture.state >= UIGestureRecognizerStateFailed){
    if (![self.delegate videoBtClick]) {
      NSLog(@"结束录制");
      [self startRecordAnimate: NO];
      [self.progressView changeRadius: NO];
    }
  }
}

#pragma mark - 切换状态
- (void)startRecordAnimate: (BOOL) changeStatus{
  [UIView animateWithDuration:0.2 animations:^{
    self.recordBtn.transform = CGAffineTransformMakeScale(changeStatus?0.66:1.0, changeStatus?0.66:1.0);
    self.recordBackView.transform = CGAffineTransformMakeScale(changeStatus? 6.5/5 : 1, changeStatus? 6.5/5 : 1);
    // 切换进度
    [self.progressView changeRadius: changeStatus];
  }];
}


// 闪关灯按钮
- (UIButton *)flashBtn{
    if (!_flashButton) {
        _flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        [_switchCameraButton setImage:[UIImage imageNamed:@"record_video_camera"] forState:UIControlStateNormal];
      
      NSData *imageData = [[NSData alloc] initWithBase64EncodedString: videoFlashClose options:NSDataBase64DecodingIgnoreUnknownCharacters];
      [_flashButton setImage: [UIImage imageWithData:imageData] forState:UIControlStateNormal];
//      _flashButton.backgroundColor = [UIColor purpleColor];
      // 设置图片的填充
      [_flashButton setImageEdgeInsets: UIEdgeInsetsMake(5, 10, 5, 10)];
      [_flashButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
      _flashButton.frame = CGRectMake(10, 20, 40, 40);
      [_flashButton addTarget:self action:@selector(clickSwitchFlash) forControlEvents:UIControlEventTouchUpInside];
    }
    return _flashButton;
}

#pragma mark - 闪关灯点击事件
- (void)clickSwitchFlash{
  BOOL openedFlash = [self.delegate switchFlash];
  
  NSData *flashImageData = [[NSData alloc] initWithBase64EncodedString: openedFlash ? videoFlashOpen : videoFlashClose options:NSDataBase64DecodingIgnoreUnknownCharacters];
  [self.flashButton setImage:[UIImage imageWithData:flashImageData] forState:UIControlStateNormal];
}

#pragma mark - 相机切换
- (UIButton *)switchCameraBtn{
    if (!_switchCameraButton) {
        _switchCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
      
//        [_switchCameraButton setImage:[UIImage imageNamed:@"record_video_camera"] forState:UIControlStateNormal];
      
      NSData *imageData = [[NSData alloc] initWithBase64EncodedString: recordVideoCamera options:NSDataBase64DecodingIgnoreUnknownCharacters];
      [_switchCameraButton setImage: [UIImage imageWithData:imageData] forState:UIControlStateNormal];
//      _switchCameraButton.backgroundColor = [UIColor purpleColor];
      // 设置图片的填充
      [_switchCameraButton setImageEdgeInsets: UIEdgeInsetsMake(10, 5, 10, 5)];
      [_switchCameraButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
      _switchCameraButton.frame = CGRectMake(self.width - 20 - 28, 20, 40, 40);
      [_switchCameraButton addTarget:self action:@selector(clickSwitchCamera) forControlEvents:UIControlEventTouchUpInside];
    }
    return _switchCameraButton;
}

#pragma mark - 点击事件
- (void)clickSwitchCamera{
   if ([self.delegate changeBtClick]) {
       NSLog(@"后置摄像头");
   } else {
       NSLog(@"前置摄像头");
   }
}

// 返回按钮
- (UIButton *)backBtn{
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
      
//        [_backButton setImage:[UIImage imageNamed:@"record_video_back"] forState:UIControlStateNormal];
      
      NSData *imageData = [[NSData alloc] initWithBase64EncodedString: backImageStr options:NSDataBase64DecodingIgnoreUnknownCharacters];
      [_backButton setImage: [UIImage imageWithData:imageData] forState:UIControlStateNormal];
      // 设置图片的填充
      [_backButton setImageEdgeInsets: UIEdgeInsetsMake(10, 5, 10, 5)];
      [_backButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
      
      _backButton.frame = CGRectMake(60, self.recordBtn.centerY - 18, 40, 40);
      [_backButton addTarget:self action:@selector(clickBackButton) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

#pragma mark - 返回点击事件
- (void)clickBackButton{
  // 取消
  if (self.cancelBlock) {
      self.cancelBlock();
  }
  
  [self initData];
}

- (void)initData{
  dispatch_async(dispatch_get_main_queue(), ^{
    //主线程执行
    self.originKeyWindow.windowLevel = UIWindowLevelNormal;
  });
  
  [self.delegate cancelClick];
}

//
//#pragma mark - 弹出视图
//- (void)present{
//    dispatch_async(dispatch_get_main_queue(), ^{
//        CGRect rect = self.frame;
//        rect.origin.y = 0;
//        [UIView animateWithDuration:0.25 animations:^{
//            self.frame = rect;
//        }];
//    });
//}


#pragma mark - 删除按钮
- (UIButton *)deleteBtn{
    if (!_deleteButton) {
      _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
      
      NSData *imageData = [[NSData alloc] initWithBase64EncodedString: videoDelete options:NSDataBase64DecodingIgnoreUnknownCharacters];
      [_deleteButton setImage: [UIImage imageWithData:imageData] forState:UIControlStateNormal];
      // 设置图片的填充
//      [_deleteButton setImageEdgeInsets: UIEdgeInsetsMake(10, 5, 10, 5)];
      [_deleteButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
      
//      [_deleteButton setImage:[UIImage imageNamed:@"video_delete"] forState:UIControlStateNormal];
      _deleteButton.frame = CGRectMake(60, self.recordBtn.centerY - 18, 36, 36);
      [_deleteButton addTarget:self action:@selector(deleteClick) forControlEvents:UIControlEventTouchUpInside];
      _deleteButton.alpha = 0;
    }
    return _deleteButton;
}

#pragma mark - 删除点击事件
- (void)deleteClick{
  if( ![self.progressView getDeleteStatus] ){
    [self.progressView setDeleteStatus: YES];
  } else {
    [self.progressView deleteSplit];
    if( [self.progressView getSplitCount] == 0 ){
      // 返回按钮
      self.backButton.hidden = NO;
      // 闪光灯
      self.flashButton.hidden = NO;
      // 切换相机
      self.switchCameraButton.hidden = NO;
      // 提示文字
      self.tipLabel.text = @"点击拍照, 长按录制";
      self.tipLabel.hidden = NO;
      
      [self switchBtn: YES];
    }
    // 重新进度条
    self.recordTime = [self.progressView getProgress];
  }
  
  BOOL deleteStatus = [self.progressView getDeleteStatus];
  
  NSData *imageData = [[NSData alloc] initWithBase64EncodedString: deleteStatus ? videoClickDelete : videoDelete options:NSDataBase64DecodingIgnoreUnknownCharacters];
  // 设置图片的填充
//  [_deleteButton setImageEdgeInsets: UIEdgeInsetsMake(10, 5, 10, 5)];
  [_deleteButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
  [_deleteButton setImage:[UIImage imageWithData:imageData] forState:UIControlStateNormal];
}

#pragma mark - 完成按钮
- (UIButton *)finishBtn{
    if (!_finishButton) {
      _finishButton = [UIButton buttonWithType:UIButtonTypeCustom];
      
      NSData *imageData = [[NSData alloc] initWithBase64EncodedString: videoFinsh options:NSDataBase64DecodingIgnoreUnknownCharacters];
      [_finishButton setImage: [UIImage imageWithData:imageData] forState:UIControlStateNormal];
      // 设置图片的填充
//      [_finishButton setImageEdgeInsets: UIEdgeInsetsMake(10, 5, 10, 5)];
      [_finishButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
      
//      [_finishButton setImage:[UIImage imageNamed:@"video_finish"] forState:UIControlStateNormal];
      _finishButton.frame = CGRectMake(self.width, self.recordBtn.centerY - 18, 36, 36);
      [_finishButton addTarget:self action:@selector(finishClick) forControlEvents:UIControlEventTouchUpInside];
      _finishButton.alpha = 0;
    }
    return _finishButton;
}

#pragma mark - 完成点击事件
- (void)finishClick{
  __weak typeof(self) weakSelf = self;
  [self.delegate mergeClick:^(NSMutableDictionary *info){
    // 清空断点数组
    [weakSelf.progressView cleanSplit];
    // 清空进度条
    weakSelf.progressView.progress = 0.0;
    weakSelf.recordTime = 0.0;
    
    dispatch_async(dispatch_get_main_queue(), ^{
      //主线程执行
      weakSelf.tipLabel.text = @"点击拍照, 长按录制";
      weakSelf.backButton.hidden = NO;
      weakSelf.tipLabel.hidden = NO;
      weakSelf.flashButton.hidden = NO;
      weakSelf.switchCameraButton.hidden = NO;
      
      weakSelf.deleteButton.alpha = 0;
      weakSelf.finishButton.alpha = 0;
    });
    
    if (self.completionBlock) {
        self.completionBlock(info);
    }
    
    [self initData];
   } failure:^(NSMutableDictionary *error){
     NSLog(@"失败%@", error);
     if ( error.count != 0 && error != nil &&![error isKindOfClass:[NSNull class]] ){
      if (self.completionBlock) {
          self.completionBlock(error);
      }
     } else {
      if (self.cancelBlock) {
          self.cancelBlock();
      }
     }
  }];
}

#pragma mark - 切换动画按钮
- (void) switchBtn: (BOOL) switchType{
  self.deleteBtn.hidden = switchType;
  self.finishBtn.hidden = switchType;
  
  CGFloat deta = [UIScreen mainScreen].bounds.size.width/375.0;
  CGFloat width = 36.0*deta;
  CGRect deleteRect = _deleteButton.frame;
  CGRect finshRect = _finishButton.frame;
  deleteRect.origin.x = 60*deta;
  finshRect.origin.x = self.width - 60*deta - width;
  
  [UIView animateWithDuration:0.2 animations:^{
    self.deleteBtn.frame = deleteRect;
    self.finishBtn.frame = finshRect;
    self.deleteButton.alpha = switchType ? 0 : 1;
    self.finishButton.alpha = switchType ? 0 : 1;
  }];
}

- (void)viewsLinkBlock:(neededViewBlock)block {
    if (block) {
        block(_focusView,_VideoLayerView);
    }
}

- (void)setFormData:(NSMutableDictionary *)formData {
  self.progressView.totolProgress = 60;
}

#pragma mark - 结束录制
- (void) stopRecording{
  if (![self.delegate videoBtClick]) {
    NSLog(@"结束录制");
    [self startRecordAnimate: NO];
    // 显示闪光灯、切换相机、删除、完成
    self.tipLabel.text = @"长按继续录制";
    self.tipLabel.hidden = NO;
    self.flashButton.hidden = NO;
    self.switchCameraButton.hidden = NO;
    
    // 结束倒计时
    [self stopTimer];
    
    [self switchBtn: NO];
  }
}

#pragma mark 计时器相关
- (NSTimer *)timer{
  if (!_timer){
    _timer = [NSTimer scheduledTimerWithTimeInterval:KTimerInterval target:self selector:@selector(fire:) userInfo:nil repeats:YES];
  }
  return _timer;
}

// 倒计时进行中
- (void)fire:(NSTimer *)timer{
  self.recordTime += KTimerInterval;
  self.progressView.progress = self.recordTime;
  if(_recordTime >= KMaxRecordTime){
    [self stopRecording];
  }
}

// 开始倒计时
- (void)startTimer{
  [self.timer invalidate];
  self.timer = nil;
  [self.timer fire];
}

// 关闭倒计时
- (void)stopTimer{
  [self.timer invalidate];
  self.timer = nil;
}

- (UIImage *)imageResize:(UIImage*)img andResizeTo:(CGSize)newSize {
    CGFloat scale = [[UIScreen mainScreen]scale];
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, scale);
    [img drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
