#include "HelloWorldScene.h"
#include "3rdplatform/platformhelper.h"
#include "script_support/CCScriptSupport.h"
#include "CCLuaEngine.h"
#include "3rdplatform/shareimplement.h"


CCScene* HelloWorld::scene()
{
    // 'scene' is an autorelease object
    CCScene *scene = CCScene::create();
    
    // 'layer' is an autorelease object
    HelloWorld *layer = HelloWorld::create();

    // add layer as a child to scene
    scene->addChild(layer);

    // return the scene
    return scene;
}

// on "init" you need to initialize your instance
bool HelloWorld::init()
{
	m_Time = 0.0f;
	m_maxTime = 200.0f;
	m_angle = 0.0f;
	m_radius = 0.0f;
	m_angleSpeed = 1.5f;
	m_radiusSpeed = 0.5f;
	m_radius = 0.5f;
	gettimeofday(&m_lasttime, NULL);
    //////////////////////////////
    // 1. super init first
    if ( !CCLayer::init() )
    {
        return false;
    }
    
    CCSize visibleSize = CCDirector::sharedDirector()->getVisibleSize();
    CCPoint origin = CCDirector::sharedDirector()->getVisibleOrigin();

    /////////////////////////////
    // 2. add a menu item with "X" image, which is clicked to quit the program
    //    you may modify it.

    // add a "close" icon to exit the progress. it's an autorelease object
    CCMenuItemImage *pCloseItem = CCMenuItemImage::create(
                                        "CloseNormal.png",
                                        "CloseSelected.png",
                                        this,
                                        menu_selector(HelloWorld::menuCloseCallback));
    
	pCloseItem->setPosition(ccp(origin.x + visibleSize.width - pCloseItem->getContentSize().width/2 ,
                                origin.y + pCloseItem->getContentSize().height/2));

    // create menu, it's an autorelease object
    CCMenu* pMenu = CCMenu::create(pCloseItem, NULL);
    pMenu->setPosition(CCPointZero);
    this->addChild(pMenu, 1);

    /////////////////////////////
    // 3. add your codes below...

    // add a label shows "Hello World"
    // create and initialize a label
    
    CCLabelTTF* pLabel = CCLabelTTF::create("Hello World", "Arial", 24);
    
    // position the label on the center of the screen
    pLabel->setPosition(ccp(origin.x + visibleSize.width/2,
                            origin.y + visibleSize.height - pLabel->getContentSize().height));

    // add the label as a child to this layer
    this->addChild(pLabel, 1);

    // add "HelloWorld" splash screen"
	m_pSprite = CCSprite::create("HelloWorld.png");

    // position the sprite on the center of the screen
	m_pSprite->setPosition(ccp(visibleSize.width / 2 + origin.x, visibleSize.height / 2 + origin.y));

    // add the sprite as a child to this layer
	this->addChild(m_pSprite, 0);
    
	CCGLProgram * p = new CCGLProgram();
	p->initWithVertexShaderFilename("Vortex.vsh", "Vortex.fsh");
	p->addAttribute(kCCAttributeNamePosition, kCCVertexAttrib_Position);
	p->addAttribute(kCCAttributeNameColor, kCCVertexAttrib_Color);
	p->addAttribute(kCCAttributeNameTexCoord, kCCVertexAttrib_TexCoords);
	p->link();
	p->updateUniforms();
	m_pSprite->setShaderProgram(p);
	GLuint angle = glGetUniformLocation(m_pSprite->getShaderProgram()->getProgram(), "angle");
	GLuint radius = glGetUniformLocation(m_pSprite->getShaderProgram()->getProgram(), "radius");
	
	m_pSprite->getShaderProgram()->setUniformLocationWith1f(radius, 0.0f);
	m_pSprite->getShaderProgram()->setUniformLocationWith1f(angle, 0.0f);
	
	scheduleUpdate();
    return true;
}

void HelloWorld::update(float delta)
{
	//计算时间间隔
	timeval		currtime;
	gettimeofday(&currtime, NULL);
	float dt = (currtime.tv_sec - m_lasttime.tv_sec) + (currtime.tv_usec - m_lasttime.tv_usec) / 1000000.0f;

	if (m_Time < m_maxTime)
	{
		setAngle(getAngle() + m_angleSpeed*dt);
		//setRadius(getRadius() + m_radiusSpeed*dt);
		m_Time += dt;

	}
	else
	{
		m_Time = 0.0;
		setAngle(0.0f);
		//setRadius(0.0f);
	}

	m_lasttime = currtime;
	GLuint angle = glGetUniformLocation(m_pSprite->getShaderProgram()->getProgram(), "angle");
	GLuint radius = glGetUniformLocation(m_pSprite->getShaderProgram()->getProgram(), "radius");
	m_pSprite->getShaderProgram()->use();
	m_pSprite->getShaderProgram()->setUniformLocationWith1f(radius, m_radius);
	m_pSprite->getShaderProgram()->setUniformLocationWith1f(angle, m_angle);
}

void HelloWorld::menuCloseCallback(CCObject* pSender)
{
	//PlatFormHelper::weixin_sendToFriend();
	ShareImplement::shareInstance()->showShareMenu();
//#if (CC_TARGET_PLATFORM == CC_PLATFORM_WINRT) || (CC_TARGET_PLATFORM == CC_PLATFORM_WP8)
//	CCMessageBox("You pressed the close button. Windows Store Apps do not implement a close button.","Alert");
//#else
//    CCDirector::sharedDirector()->end();
//#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
//    exit(0);
//#endif
//#endif

	//设置Shader的参数。
	//GLProgramState* programstate = getGLProgramState();
	//
	//programstate->setUniformFloat("radius", m_radius);
	//programstate->setUniformFloat("angle", m_angle);
	//programstate->setUniformTexture("u_texture", m_pTarget->getSprite()->getTexture());



}
