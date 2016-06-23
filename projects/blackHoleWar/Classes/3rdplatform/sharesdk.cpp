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
}

void ShareSdk::showShareMenu()
{
	CCDictionary *content = CCDictionary::create();
	content -> setObject(CCString::create("这是一条测试内容"), "content");
	content -> setObject(CCString::create("http://img0.bdstatic.com/img/image/shouye/systsy-11927417755.jpg"), "image");
	content -> setObject(CCString::create("测试标题"), "title");
	content -> setObject(CCString::create("测试描述"), "description");
	content -> setObject(CCString::create("http://sharesdk.cn"), "url");
	content -> setObject(CCString::createWithFormat("%d", C2DXContentTypeNews), "type");
	content -> setObject(CCString::create("http://sharesdk.cn"), "siteUrl");
	content -> setObject(CCString::create("ShareSDK"), "site");
	content -> setObject(CCString::create("http://mp3.mwap8.com/destdir/Music/2009/20090601/ZuiXuanMinZuFeng20090601119.mp3"), "musicUrl");
	content -> setObject(CCString::create("extInfo"), "extInfo");
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
		default:
			break;
	}
}

void ShareSdk::showShareResultToast(const char *msg)
{

}
