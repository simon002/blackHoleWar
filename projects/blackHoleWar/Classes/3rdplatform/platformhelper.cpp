
#include "platformhelper.h"


void PlatFormHelper::weixin_sendToFriend()
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID) //�жϵ�ǰ�Ƿ�ΪAndroidƽ̨
	JniMethodInfo minfo;

	bool isHave = JniHelper::getStaticMethodInfo(minfo,"com/xm/game/blackHoleWar","sendMsgToFriend", "()V");

	if (!isHave) {
		CCLog("jni:sendMsgToFriend is null");
	}else{
		//���ô˺���
		minfo.env->CallStaticVoidMethod(minfo.classID, minfo.methodID);
	}
#endif
}