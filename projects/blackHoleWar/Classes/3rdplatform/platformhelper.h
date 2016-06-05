#pragma once
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
#include <jni.h>
#include "platform/android/jni/JniHelper.h"
#include <cocos2d.h>
#endif
USING_NS_CC;
class PlatFormHelper
{
public:
	static void weixin_sendToFriend();
};