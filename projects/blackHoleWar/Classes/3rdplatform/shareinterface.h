#pragma once
class ShareInterface
{
public:
	virtual void initShareSDK() = 0;
	virtual void configSharePlatform() = 0;
	virtual void showShareMenu() = 0;
private:
};