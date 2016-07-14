#include "sharesdk.h"

void ShareSdk::initShareSDK()
{
	C2DXShareSDK::open(CCString::create("13e9816460b2c"), false);
}

void ShareSdk::configSharePlatform()
{
	//微信
	CCDictionary* wc_config = CCDictionary::create();
	wc_config->setObject(CCString::create("wx4d7504c20ece06ed"), "app_id");
	C2DXShareSDK::setPlatformConfig(C2DXPlatTypeWeixiSession, wc_config);
	C2DXShareSDK::setPlatformConfig(C2DXPlatTypeWeixiTimeline, wc_config);

	//人人网
	CCDictionary* rrConfigDict = CCDictionary::create();
	rrConfigDict ->setObject(CCString::create("482867"), "app_id");
	rrConfigDict ->setObject(CCString::create("6d8b03acac3b41089ede73599c59875d"), "app_key");
	rrConfigDict ->setObject(CCString::create("10b3a75cf14349158348b41ea9a4d872"), "secret_key");
	C2DXShareSDK::setPlatformConfig(C2DXPlatTypeRenren, rrConfigDict);

	//开心网
	CCDictionary* kxConfigDict = CCDictionary::create();
	kxConfigDict ->setObject(CCString::create("949838443955b3247f2f5064ab577b85"), "api_key");
	kxConfigDict ->setObject(CCString::create("6bd7fd6c853753d279b3f95ee139fbf2"), "secret_key");
	kxConfigDict ->setObject(CCString::create("http://www.sharesdk.cn/"), "redirect_uri");
	C2DXShareSDK::setPlatformConfig(C2DXPlatTypeKaixin, kxConfigDict);
}

void ShareSdk::showShareMenu()
{
	CCDictionary *content = CCDictionary::create();
	content->setObject(CCString::create("测试数据"),"content");

	content->setObject(CCString::create("http://img0.bdstatic.com/img/image/shouye/systsy-11927417755.jpg"), "image");
	content->setObject(CCString::create("测试标题"), "title");
	content->setObject(CCString::create("测试描述"), "description");
	content->setObject(CCString::create("http://sharesdk.cn"), "url");
	content->setObject(CCString::createWithFormat("%d", C2DXContentTypeNews), "type");
	content->setObject(CCString::create("http://sharesdk.cn"), "siteUrl");
	content->setObject(CCString::create("ShareSDK"), "site");
	content->setObject(CCString::create("extInfo"), "extInfo");
	C2DXShareSDK::showShareMenu(NULL, content, CCPointMake(100, 100), C2DXMenuArrowDirectionLeft, ShareSdk::shareResultHandler);

}

void ShareSdk::shareResultHandler(C2DXResponseState state, C2DXPlatType platType, CCDictionary *shareInfo, CCDictionary *error)
{
	switch (state) 
	{
		case C2DXResponseStateSuccess:
			ShareSdk::showShareResultToast("分享成功");
			break;
		case C2DXResponseStateFail:
			//app->showShareResultToast("分享失败");
			ShareSdk::showShareResultToast("分享失败");
			break;
		case C2DXResponseStateBegin:
			ShareSdk::showShareResultToast("分享开");
			break;
		case C2DXResponseStateCancel:
			ShareSdk::showShareResultToast("分享取消");
			break;
		default:
			break;
	}
}

void ShareSdk::showShareResultToast(const char *msg)
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
	JniMethodInfo minfo;

	bool isHave = JniHelper::getStaticMethodInfo(minfo,"com/xm/game/blackHoleWar","shareTips", "(Ljava/lang/String;)V");
	
	if (!isHave) {
		CCLog("jni:shareTips is null");
	}else{
		//调用此函数
		jstring jmsg = minfo.env->NewStringUTF(msg);
		minfo.env->CallStaticVoidMethod(minfo.classID, minfo.methodID,jmsg);
		//minfo.env->DeleteLocalRef (minfo.env, jmsg);
	}
#endif
}
