#pragma once
#include "../../../../cocos2dx/platform/CCPlatformConfig.h"
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
#include <jni.h>
#include "platform/android/jni/JniHelper.h"
#include <cocos2d.h>
USING_NS_CC;
#endif

class PlatFormHelper
{
public:
	static void weixin_sendToFriend();
};