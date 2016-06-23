/****************************************************************************
Copyright (c) 2010-2011 cocos2d-x.org

http://www.cocos2d-x.org

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
****************************************************************************/
package com.xm.game;
import cn.sharesdk.*;

import com.mob.tools.utils.R;
import com.tencent.*;
import com.tencent.mm.sdk.modelmsg.SendMessageToWX;
import com.tencent.mm.sdk.modelmsg.WXMediaMessage;
import com.tencent.mm.sdk.modelmsg.WXWebpageObject;
import com.tencent.mm.sdk.openapi.IWXAPI;
import com.tencent.mm.sdk.openapi.WXAPIFactory;

import org.cocos2dx.lib.Cocos2dxActivity;
import org.cocos2dx.lib.Cocos2dxGLSurfaceView;


import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.widget.Toast;

public class blackHoleWar extends Cocos2dxActivity{
	private static final String APP_ID = "wx4d7504c20ece06ed";//AppID���ӵ��Ĳ���ȡ
	private static IWXAPI api;//΢��API�ӿ�
	private static blackHoleWar instance;//�ྲ̬ʵ��Ϊ�˷�����澲̬����ĵ���
	private static final int SHOW_MESSAGE = 0;
	private static final Handler msgHandler = new Handler(){  
        public void handleMessage(Message msg) {   
                	Toast.makeText(instance, msg.obj.toString(), Toast.LENGTH_SHORT).show();
 
                }  
    };
    protected void onCreate(Bundle savedInstanceState){
		super.onCreate(savedInstanceState);	
		instance = this;
		//regToWX();
		ShareSDKUtils.prepare();
	}
    private void regToWX(){
        api = WXAPIFactory.createWXAPI(this, APP_ID, true);
        api.registerApp(APP_ID);
    }

public static void sendMsgToFriend(){
 
    if(api.openWXApp())
    {
        WXWebpageObject webpage = new WXWebpageObject();
        webpage.webpageUrl = "http://www.fusijie.com";
        WXMediaMessage msg = new WXMediaMessage(webpage);
        msg.title = "Tittle";
        msg.description = "Description";
 
        //Bitmap thumb = BitmapFactory.decodeResource(instance.getResources(), R.drawable.icon);
        //msg.thumbData = Util.bmpToByteArray(thumb, true);
 
        //SendMessageToWX.Req req = new SendMessageToWX.Req();
        //req.transaction = buildTransaction("webpage");
        //req.message = msg;
        //req.scene = SendMessageToWX.Req.WXSceneSession;
       // api.sendReq(req);
    }
    else
    {
    	///Looper.prepare();
         //Toast.makeText(instance, "δ��װ΢��", Toast.LENGTH_SHORT).show();
         //Looper.loop();
         Message msg = msgHandler.obtainMessage();  
         msg.obj = "δ��װ΢��";  
         msgHandler.sendMessage(msg);
    	  //Message msg=new Message();  
          //msg.what=SHOW_MESSAGE;  
          //msg.obj="showmessage demos";  //���Դ��ݲ���  
          //handler.sendMessage(msg);
    }
}


public static void sendMsgToTimeLine(){
 
    if(api.openWXApp())
    {
        if(api.getWXAppSupportAPI() >= 0x21020001)
        {               
            WXWebpageObject webpage = new WXWebpageObject();
            webpage.webpageUrl = "http://www.fusijie.com";
            WXMediaMessage msg = new WXMediaMessage(webpage);
            msg.title = "Tittle";
            msg.description = "Description";
 
           // Bitmap thumb = BitmapFactory.decodeResource(instance.getResources(), R.drawable.icon);
           // msg.thumbData = Util.bmpToByteArray(thumb, true);
 
            SendMessageToWX.Req req = new SendMessageToWX.Req();
            req.transaction = buildTransaction("webpage");
            req.message = msg;
            req.scene = SendMessageToWX.Req.WXSceneTimeline;
            api.sendReq(req);
        }
        else{
            Toast.makeText(instance, "΢�Ű汾���", Toast.LENGTH_SHORT).show();
        }
    }
    else
    {
         Toast.makeText(instance, "δ��װ΢��", Toast.LENGTH_SHORT).show();
    }
}
private static String buildTransaction(final String type) {
    return (type == null) ? String.valueOf(System.currentTimeMillis()) : type + System.currentTimeMillis();
}
    public Cocos2dxGLSurfaceView onCreateView() {
    	Cocos2dxGLSurfaceView glSurfaceView = new Cocos2dxGLSurfaceView(this);
    	// blackHoleWar should create stencil buffer
    	glSurfaceView.setEGLConfigChooser(5, 6, 5, 0, 16, 8);
    	
    	return glSurfaceView;
    }

    static {
        System.loadLibrary("cocos2dcpp");
    }     
}
