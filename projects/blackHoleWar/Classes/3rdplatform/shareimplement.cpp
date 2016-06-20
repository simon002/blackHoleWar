#include "shareimplement.h"

ShareImplement* ShareImplement::m_pInstance = 0;

ShareImplement* ShareImplement::shareInstance()
{
	if (m_pInstance == 0)
	{
		m_pInstance = new ShareImplement;
	}
	return m_pInstance;
}

void ShareImplement::initShareSDK()
{
	if (m_pShareInterface != 0)
	{
		m_pShareInterface->initShareSDK();
	}
}

void ShareImplement::configSharePlatform()
{
	if (m_pShareInterface != 0)
	{
		m_pShareInterface->configSharePlatform();
	}
}

void ShareImplement::showShareMenu()
{
	if (m_pShareInterface != 0)
	{
		m_pShareInterface->showShareMenu();
	}
}