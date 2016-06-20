#pragma once
#include "shareinterface.h"

class ShareImplement
{
public:
	ShareImplement():m_pShareInterface(0){}
	void initShareSDK();
	void configSharePlatform();
	void showShareMenu();
	void setShareInterface(ShareInterface* _shareInterface){ m_pShareInterface = _shareInterface; }
	static ShareImplement* shareInstance();
private:
	static ShareImplement* m_pInstance;
	ShareInterface* m_pShareInterface;
};