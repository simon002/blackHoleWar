#ifndef __HELLOWORLD_SCENE_H__
#define __HELLOWORLD_SCENE_H__

#include "cocos2d.h"
USING_NS_CC;
class HelloWorld : public cocos2d::CCLayer
{
public:
    // Here's a difference. Method 'init' in cocos2d-x returns bool, instead of returning 'id' in cocos2d-iphone
    virtual bool init();  

    // there's no 'id' in cpp, so we recommend returning the class instance pointer
    static cocos2d::CCScene* scene();
    
    // a selector callback
    void menuCloseCallback(CCObject* pSender);
	virtual void update(float delta);
    // implement the "static node()" method manually
    CREATE_FUNC(HelloWorld);
	void setAngle(float _angle){ m_angle = _angle; }
	float getAngle(){ return m_angle; }
	void setRadius(float _radius){ m_radius = _radius; }
	float getRadius(){ return m_radius; }
private:
	timeval m_lasttime;
	float m_Time;
	float m_maxTime;
	float m_angle;
	float m_radius;
	float m_angleSpeed; 
	float m_radiusSpeed; 
	CCSprite* m_pSprite;
};

#endif // __HELLOWORLD_SCENE_H__
