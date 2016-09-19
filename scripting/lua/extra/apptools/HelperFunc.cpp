#include "cocos2d.h"
extern "C" {
#include "lua.h"
//#include "xxtea.h"
}
#include "xxtea.h"
#include "CCLuaEngine.h"
#include "HelperFunc.h"


USING_NS_CC;

unsigned char* CZHelperFunc::getFileData(const char* pszFileName, const char* pszMode, unsigned long * pSize)
{
#if 0
    unsigned long size;
    unsigned char* buf = CCFileUtils::sharedFileUtils()->getFileData(pszFileName, pszMode, &size);
    if (NULL==buf || size<1) return NULL;
    
    CCLuaStack* stack = CCLuaEngine::defaultEngine()->getLuaStack();
    unsigned char* buffer = NULL;
    
    bool isXXTEA = stack && stack->m_xxteaEnabled;
    for (unsigned int i = 0; isXXTEA && ((int)i) < stack->m_xxteaSignLen && i < size; ++i)
    {
        isXXTEA = buf[i] == stack->m_xxteaSign[i];
    }
    
    if (isXXTEA)
    {
        // decrypt XXTEA
        xxtea_long len = 0;
        buffer = xxtea_decrypt(buf + stack->m_xxteaSignLen,
                               (xxtea_long)size - (xxtea_long)stack->m_xxteaSignLen,
                               (unsigned char*)stack->m_xxteaKey,
                               (xxtea_long)stack->m_xxteaKeyLen,
                               &len);
        delete []buf;
        buf = NULL;
        size = len;
    }
    else
    {
        buffer = buf;
    }
    
    if (pSize) *pSize = size;
    return buffer;
#else
    unsigned long size;
    unsigned char* buf = CCFileUtils::sharedFileUtils()->getFileData(pszFileName, pszMode, &size);
    if (NULL==buf) {
        return NULL;
    } else if (size < 1) {
        delete []buf;
        return NULL;
    }
    
    CCLuaStack* stack = CCLuaEngine::defaultEngine()->getLuaStack();
    
    unsigned char* buffer;
    if (stack && stack->m_xxteaEnabled && size > stack->m_xxteaSignLen && memcmp(buf, stack->m_xxteaSign, stack->m_xxteaSignLen) == 0) {
        // decrypt XXTEA
        xxtea_long len = 0;
        unsigned char * tbuff;
        tbuff = xxtea_decrypt(buf + stack->m_xxteaSignLen,
                              (xxtea_long)size - (xxtea_long)stack->m_xxteaSignLen,
                              (unsigned char*)stack->m_xxteaKey,
                              (xxtea_long)stack->m_xxteaKeyLen,
                              &len);
        delete []buf;
        buffer = new unsigned char[len];
        memcpy(buffer, tbuff, len);
        free(tbuff);
        size = len;
    } else {
        buffer = buf;
    }
    
    if (pSize) *pSize = size;
    return buffer;
#endif
}

int CZHelperFunc::getFileData(const char *pPathFile)
{
    unsigned long size;
    unsigned char* buf = CZHelperFunc::getFileData(pPathFile, "rb", &size);
    if (NULL==buf) return 0;
    
    CCLuaStack* stack = CCLuaEngine::defaultEngine()->getLuaStack();
	stack->clean();
    stack->pushString((const char*)(buf), size);
#ifdef CC_QUICK_LUA_SURPPORT
    delete[] buf;
#else
    delete buf;
#endif
    return 1;
}
