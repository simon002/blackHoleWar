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
void AppDelegate::initShareSDK()
{
	// sina weibo
	//CCDictionary *sinaConfigDict = CCDictionary::create();
	//sinaConfigDict->setObject(CCString::create("YOUR_WEIBO_APPKEY"), "app_key");
	//sinaConfigDict->setObject(CCString::create("YOUR_WEBIO_APPSECRET"), "app_secret");
	//sinaConfigDict->setObject(CCString::create("http://www.sharesdk.cn"), "redirect_uri");
	//C2DXShareSDK::setPlatformConfig(C2DXPlatTypeSinaWeibo, sinaConfigDict);

	// wechat
	CCDictionary *wcConfigDict = CCDictionary::create();
	wcConfigDict->setObject(CCString::create("wx4d7504c20ece06ed"), "app_id");
	C2DXShareSDK::setPlatformConfig(C2DXPlatTypeWeixiSession, wcConfigDict);
	C2DXShareSDK::setPlatformConfig(C2DXPlatTypeWeixiTimeline, wcConfigDict);
	C2DXShareSDK::setPlatformConfig(C2DXPlatTypeWeixiFav, wcConfigDict);

	C2DXShareSDK::open(CCString::create("13e9816460b2c"), false);
}

void shareResultHandler(C2DXResponseState state,
						C2DXPlatType platType,
						CCDictionary *shareInfo,
						CCDictionary *error)
{
	AppDelegate *app = (AppDelegate*)CCApplication::sharedApplication();
	switch (state) {
	case C2DXResponseStateSuccess:
		CCLog("Share Ok");
		app->showShareResultToast("分享成功");
		break;
	case C2DXResponseStateFail:
		app->showShareResultToast("分享失败");
		CCLog("Share Failed");
		break;
	default:
		break;
	}
}


void AppDelegate::shareCallBack()
{
	CCDictionary *content = CCDictionary::create();

	content->setObject(CCString::create("ShareSDK for Cocos2d-x 3.0rc2社交分享测试。")
		, "content");
	content->setObject(CCString::create("ShareSDK分享测试"), "title");
	content->setObject(CCString::create("http://tonybai.com"), "titleUrl");
	content->setObject(CCString::create("http://tonybai.com"), "url");
	content->setObject(CCString::create("Tony Bai"), "site");
	content->setObject(CCString::create("http://tonybai.com"), "siteUrl");
	content->setObject(CCString::createWithFormat("%s", "CloseSelected.png")
		, "image");
	content->setObject(CCString::createWithFormat("%d", C2DXContentTypeNews)
		, "type");

	C2DXShareSDK::showShareMenu(NULL, content, CCPointMake(100, 100),
		C2DXMenuArrowDirectionLeft, shareResultHandler);

}
void AppDelegate::showShareResultToast(const char *msg)
{
	JniMethodInfo t;
	if (JniHelper::getStaticMethodInfo(t, "YOUR_ACTIVITY_NAME",
		"showShareResultToast", "(Ljava/lang/String;)V")) {
			jstring jmsg = t.env->NewStringUTF(msg);
			t.env->CallStaticVoidMethod(t.classID, t.methodID, jmsg);
			if (t.env->ExceptionOccurred()) {
				t.env->ExceptionDescribe();
				t.env->ExceptionClear();
				return;
			}
			t.env->DeleteLocalRef(t.classID);
	}
}

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
   // pDirector->runWithScene(pScene);
	CCLuaEngine* pEngine = CCLuaEngine::defaultEngine();
	CCScriptEngineManager::sharedManager()->setScriptEngine(pEngine);

	std::string path = CCFileUtils::sharedFileUtils()->fullPathForFilename("scripts/hello.lua");
	pEngine->executeScriptFile(path.c_str());
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
