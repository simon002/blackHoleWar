
#include "platformhelper.h"


void PlatFormHelper::weixin_sendToFriend()
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID) //判断当前是否为Android平台
	JniMethodInfo minfo;

	bool isHave = JniHelper::getStaticMethodInfo(minfo,"com/xm/game/blackHoleWar","sendMsgToFriend", "()V");

	if (!isHave) {
		CCLog("jni:sendMsgToFriend is null");
	}else{
		//调用此函数
		minfo.env->CallStaticVoidMethod(minfo.classID, minfo.methodID);
	}
#endif
}