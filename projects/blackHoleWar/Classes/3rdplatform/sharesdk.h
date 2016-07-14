#pragma once
#include "cocos2d.h"
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
#include <jni.h>
#include "platform/android/jni/JniHelper.h"
#include <cocos2d.h>
USING_NS_CC;
#endif
#include "C2DXShareSDK/C2DXShareSDK.h"
#include "shareinterface.h"
using namespace cn::sharesdk;
class ShareSdk :public ShareInterface
{
public:
	virtual void initShareSDK();
	virtual void configSharePlatform();
	virtual void showShareMenu();
	static  void shareResultHandler(C2DXResponseState state, C2DXPlatType platType, CCDictionary *shareInfo, CCDictionary *error);
	static  void showShareResultToast(const char *msg);
private:
};