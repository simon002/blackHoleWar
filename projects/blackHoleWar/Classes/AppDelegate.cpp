#include "AppDelegate.h"
#include "3rdplatform/C2DXShareSDK/C2DXShareSDK.h"
#include "HelloWorldScene.h"
#include "script_support/CCScriptSupport.h"
#include "CCLuaEngine.h"
//#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
#include <jni.h>
#include "platform/android/jni/JniHelper.h"
//#endif
using namespace cn::sharesdk;
USING_NS_CC;

AppDelegate::AppDelegate() {

}

AppDelegate::~AppDelegate() 
{
}





//void AppDelegate::showShareResultToast(const char *msg)
//{
//	JniMethodInfo t;
//	if (JniHelper::getStaticMethodInfo(t, "YOUR_ACTIVITY_NAME",
//		"showShareResultToast", "(Ljava/lang/String;)V")) {
//			jstring jmsg = t.env->NewStringUTF(msg);
//			t.env->CallStaticVoidMethod(t.classID, t.methodID, jmsg);
//			if (t.env->ExceptionOccurred()) {
//				t.env->ExceptionDescribe();
//				t.env->ExceptionClear();
//				return;
//			}
//			t.env->DeleteLocalRef(t.classID);
//	}
//}

bool AppDelegate::applicationDidFinishLaunching() {
    // initialize directors
	

    CCDirector* pDirector = CCDirector::sharedDirector();
    CCEGLView* pEGLView = CCEGLView::sharedOpenGLView();

    pDirector->setOpenGLView(pEGLView);
	
    // turn on display FPS
    pDirector->setDisplayStats(true);

    // set FPS. the default value is 1.0/60 if you don't call this
    pDirector->setAnimationInterval(1.0 / 60);

    // create a scene. it's an autorelease object
    CCScene *pScene = HelloWorld::scene();

    // run
    pDirector->runWithScene(pScene);
	//CCLuaEngine* pEngine = CCLuaEngine::defaultEngine();
	//CCScriptEngineManager::sharedManager()->setScriptEngine(pEngine);

	//std::string path = CCFileUtils::sharedFileUtils()->fullPathForFilename("scripts/hello.lua");
	//pEngine->executeScriptFile(path.c_str());
	ShareImplement::shareInstance()->setShareInterface(new ShareSdk);
	ShareImplement::shareInstance()->initShareSDK();
	ShareImplement::shareInstance()->configSharePlatform();
	
    return true;
}

// This function will be called when the app is inactive. When comes a phone call,it's be invoked too
void AppDelegate::applicationDidEnterBackground() {
    CCDirector::sharedDirector()->stopAnimation();

    // if you use SimpleAudioEngine, it must be pause
    // SimpleAudioEngine::sharedEngine()->pauseBackgroundMusic();
}

// this function will be called when the app is active again
void AppDelegate::applicationWillEnterForeground() {
    CCDirector::sharedDirector()->startAnimation();

    // if you use SimpleAudioEngine, it must resume here
    // SimpleAudioEngine::sharedEngine()->resumeBackgroundMusic();
}
