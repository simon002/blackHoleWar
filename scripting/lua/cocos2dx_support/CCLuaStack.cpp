/****************************************************************************
 Copyright (c) 2011 cocos2d-x.org
 
 http://www.cocos2d-x.org
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 ****************************************************************************/

#include "CCLuaStack.h"

extern "C" {
#include "lua.h"
#include "tolua++.h"
#include "lualib.h"
#include "lauxlib.h"
#include "tolua_fix.h"
}

#include "LuaCocos2d.h"
#include "Cocos2dxLuaLoader.h"
#include "LuaCocoStudio.h"
#include "lua_cocos2dx_manual.h"
#include "lua_cocos2dx_extensions_manual.h"
#include "lua_cocos2dx_cocostudio_manual.h"
#include "../extra/luabinding/cocos2dx_httprequest_luabinding.h"
#include "xxtea.h"
#include "platform/CCZipFile.h"
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS || CC_TARGET_PLATFORM == CC_PLATFORM_MAC)
#include "platform/ios/CCLuaObjcBridge.h"
#endif

namespace {
int lua_print(lua_State * luastate)
{
    int nargs = lua_gettop(luastate);

    std::string t;
    for (int i=1; i <= nargs; i++)
    {
        if (lua_istable(luastate, i))
            t += "table";
        else if (lua_isnone(luastate, i))
            t += "none";
        else if (lua_isnil(luastate, i))
            t += "nil";
        else if (lua_isboolean(luastate, i))
        {
            if (lua_toboolean(luastate, i) != 0)
                t += "true";
            else
                t += "false";
        }
        else if (lua_isfunction(luastate, i))
            t += "function";
        else if (lua_islightuserdata(luastate, i))
            t += "lightuserdata";
        else if (lua_isthread(luastate, i))
            t += "thread";
        else
        {
            const char * str = lua_tostring(luastate, i);
            if (str)
                t += lua_tostring(luastate, i);
            else
                t += lua_typename(luastate, lua_type(luastate, i));
        }
        if (i!=nargs)
            t += "\t";
    }
    CCLOG("[LUA-print] %s", t.c_str());

    return 0;
}
}  // namespace {

NS_CC_BEGIN
CCLuaStack* CCLuaStack::s_stack;
CCLuaStack *CCLuaStack::create(void)
{
    CCLuaStack *stack = new CCLuaStack();
    stack->init();
    stack->autorelease();
    return stack;
}


CCLuaStack *CCLuaStack::attach(lua_State *L)
{
    CCLuaStack *stack = new CCLuaStack();
    stack->initWithLuaState(L);
    stack->autorelease();
    return stack;
}

bool CCLuaStack::init(void)
{
    m_state = lua_open();
    luaL_openlibs(m_state);
    tolua_Cocos2d_open(m_state);
    toluafix_open(m_state);

    // Register our version of the global "print" function
    const luaL_reg global_functions [] = {
        {"print", lua_print},
        {NULL, NULL}
    };
    luaL_register(m_state, "_G", global_functions);
    tolua_CocoStudio_open(m_state);
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS || CC_TARGET_PLATFORM == CC_PLATFORM_MAC)
    CCLuaObjcBridge::luaopen_luaoc(m_state);
#endif

	luaopen_cocos2dx_httprequest_luabinding(m_state);
    register_all_cocos2dx_manual(m_state);
    register_all_cocos2dx_extension_manual(m_state);
    register_all_cocos2dx_studio_manual(m_state);
    // add cocos2dx loader
    addLuaLoader(cocos2dx_lua_loader);
	lua_pushcfunction(m_state, lua_loadChunksFromZIP);
	lua_setglobal(m_state, "CCLuaLoadChunksFromZIP");
	s_stack = this;
    return true;
}

bool CCLuaStack::initWithLuaState(lua_State *L)
{
    m_state = L;
    return true;
}

void CCLuaStack::addSearchPath(const char* path)
{
    lua_getglobal(m_state, "package");                                  /* L: package */
    lua_getfield(m_state, -1, "path");                /* get package.path, L: package path */
    const char* cur_path =  lua_tostring(m_state, -1);
    lua_pushfstring(m_state, "%s;%s/?.lua", cur_path, path);            /* L: package path newpath */
    lua_setfield(m_state, -3, "path");          /* package.path = newpath, L: package path */
    lua_pop(m_state, 2);                                                /* L: - */
}

void CCLuaStack::addLuaLoader(lua_CFunction func)
{
    if (!func) return;
    
    // stack content after the invoking of the function
    // get loader table
    lua_getglobal(m_state, "package");                                  /* L: package */
    lua_getfield(m_state, -1, "loaders");                               /* L: package, loaders */
    
    // insert loader into index 2
    lua_pushcfunction(m_state, func);                                   /* L: package, loaders, func */
    for (int i = lua_objlen(m_state, -2) + 1; i > 2; --i)
    {
        lua_rawgeti(m_state, -2, i - 1);                                /* L: package, loaders, func, function */
        // we call lua_rawgeti, so the loader table now is at -3
        lua_rawseti(m_state, -3, i);                                    /* L: package, loaders, func */
    }
    lua_rawseti(m_state, -2, 2);                                        /* L: package, loaders */
    
    // set loaders into package
    lua_setfield(m_state, -2, "loaders");                               /* L: package */
    
    lua_pop(m_state, 1);
}


void CCLuaStack::removeScriptObjectByCCObject(CCObject* pObj)
{
    toluafix_remove_ccobject_by_refid(m_state, pObj->m_nLuaID);
}

void CCLuaStack::removeScriptHandler(int nHandler)
{
    toluafix_remove_function_by_refid(m_state, nHandler);
}

int CCLuaStack::executeString(const char *codes)
{
    luaL_loadstring(m_state, codes);
    return executeFunction(0);
}

int CCLuaStack::executeScriptFile(const char* filename)
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_ANDROID)
    std::string code("require \"");
    code.append(filename);
    code.append("\"");
    return executeString(code.c_str());
#else
    std::string fullPath = CCFileUtils::sharedFileUtils()->fullPathForFilename(filename);
    ++m_callFromLua;
    int nRet = luaL_dofile(m_state, fullPath.c_str());
    --m_callFromLua;
    CC_ASSERT(m_callFromLua >= 0);
    // lua_gc(m_state, LUA_GCCOLLECT, 0);
    
    if (nRet != 0)
    {
        CCLOG("[LUA ERROR] %s", lua_tostring(m_state, -1));
        lua_pop(m_state, 1);
        return nRet;
    }
    return 0;
#endif
}

int CCLuaStack::executeGlobalFunction(const char* functionName)
{
    lua_getglobal(m_state, functionName);       /* query function by name, stack: function */
    if (!lua_isfunction(m_state, -1))
    {
        CCLOG("[LUA ERROR] name '%s' does not represent a Lua function", functionName);
        lua_pop(m_state, 1);
        return 0;
    }
    return executeFunction(0);
}

void CCLuaStack::clean(void)
{
    lua_settop(m_state, 0);
}

void CCLuaStack::pushInt(int intValue)
{
    lua_pushinteger(m_state, intValue);
}

void CCLuaStack::pushFloat(float floatValue)
{
    lua_pushnumber(m_state, floatValue);
}

void CCLuaStack::pushBoolean(bool boolValue)
{
    lua_pushboolean(m_state, boolValue);
}

void CCLuaStack::pushString(const char* stringValue)
{
    lua_pushstring(m_state, stringValue);
}

void CCLuaStack::pushString(const char* stringValue, int length)
{
    lua_pushlstring(m_state, stringValue, length);
}

void CCLuaStack::pushNil(void)
{
    lua_pushnil(m_state);
}

void CCLuaStack::pushCCObject(CCObject* objectValue, const char* typeName)
{
    toluafix_pushusertype_ccobject(m_state, objectValue->m_uID, &objectValue->m_nLuaID, objectValue, typeName);
}

void CCLuaStack::pushCCLuaValue(const CCLuaValue& value)
{
    const CCLuaValueType type = value.getType();
    if (type == CCLuaValueTypeInt)
    {
        return pushInt(value.intValue());
    }
    else if (type == CCLuaValueTypeFloat)
    {
        return pushFloat(value.floatValue());
    }
    else if (type == CCLuaValueTypeBoolean)
    {
        return pushBoolean(value.booleanValue());
    }
    else if (type == CCLuaValueTypeString)
    {
        return pushString(value.stringValue().c_str());
    }
    else if (type == CCLuaValueTypeDict)
    {
        pushCCLuaValueDict(value.dictValue());
    }
    else if (type == CCLuaValueTypeArray)
    {
        pushCCLuaValueArray(value.arrayValue());
    }
    else if (type == CCLuaValueTypeCCObject)
    {
        pushCCObject(value.ccobjectValue(), value.getCCObjectTypename().c_str());
    }
}

void CCLuaStack::pushCCLuaValueDict(const CCLuaValueDict& dict)
{
    lua_newtable(m_state);                                              /* L: table */
    for (CCLuaValueDictIterator it = dict.begin(); it != dict.end(); ++it)
    {
        lua_pushstring(m_state, it->first.c_str());                     /* L: table key */
        pushCCLuaValue(it->second);                                     /* L: table key value */
        lua_rawset(m_state, -3);                     /* table.key = value, L: table */
    }
}

void CCLuaStack::pushCCLuaValueArray(const CCLuaValueArray& array)
{
    lua_newtable(m_state);                                              /* L: table */
    int index = 1;
    for (CCLuaValueArrayIterator it = array.begin(); it != array.end(); ++it)
    {
        pushCCLuaValue(*it);                                            /* L: table value */
        lua_rawseti(m_state, -2, index);          /* table[index] = value, L: table */
        ++index;
    }
}

bool CCLuaStack::pushFunctionByHandler(int nHandler)
{
    toluafix_get_function_by_refid(m_state, nHandler);                  /* L: ... func */
    if (!lua_isfunction(m_state, -1))
    {
        CCLOG("[LUA ERROR] function refid '%d' does not reference a Lua function", nHandler);
        lua_pop(m_state, 1);
        return false;
    }
    return true;
}

int CCLuaStack::executeFunction(int numArgs)
{
    int functionIndex = -(numArgs + 1);
    if (!lua_isfunction(m_state, functionIndex))
    {
        CCLOG("value at stack [%d] is not function", functionIndex);
        lua_pop(m_state, numArgs + 1); // remove function and arguments
        return 0;
    }

    int traceback = 0;
    lua_getglobal(m_state, "__G__TRACKBACK__");                         /* L: ... func arg1 arg2 ... G */
    if (!lua_isfunction(m_state, -1))
    {
        lua_pop(m_state, 1);                                            /* L: ... func arg1 arg2 ... */
    }
    else
    {
        lua_insert(m_state, functionIndex - 1);                         /* L: ... G func arg1 arg2 ... */
        traceback = functionIndex - 1;
    }
    
    int error = 0;
    ++m_callFromLua;
    error = lua_pcall(m_state, numArgs, 1, traceback);                  /* L: ... [G] ret */
    --m_callFromLua;
    if (error)
    {
        if (traceback == 0)
        {
            CCLOG("[LUA ERROR] %s", lua_tostring(m_state, - 1));        /* L: ... error */
            lua_pop(m_state, 1); // remove error message from stack
        }
        else                                                            /* L: ... G error */
        {
            lua_pop(m_state, 2); // remove __G__TRACKBACK__ and error message from stack
        }
        return 0;
    }
    
    // get return value
    int ret = 0;
    if (lua_isnumber(m_state, -1))
    {
        ret = lua_tointeger(m_state, -1);
    }
    else if (lua_isboolean(m_state, -1))
    {
        ret = lua_toboolean(m_state, -1);
    }
    // remove return value from stack
    lua_pop(m_state, 1);                                                /* L: ... [G] */
    
    if (traceback)
    {
        lua_pop(m_state, 1); // remove __G__TRACKBACK__ from stack      /* L: ... */
    }
    
    return ret;
}

int CCLuaStack::executeFunctionByHandler(int nHandler, int numArgs)
{
    int ret = 0;
    if (pushFunctionByHandler(nHandler))                                /* L: ... arg1 arg2 ... func */
    {
        if (numArgs > 0)
        {
            lua_insert(m_state, -(numArgs + 1));                        /* L: ... func arg1 arg2 ... */
        }
        ret = executeFunction(numArgs);
    }
    lua_settop(m_state, 0);
    return ret;
}

bool CCLuaStack::handleAssert(const char *msg)
{
    if (m_callFromLua == 0) return false;
    
    lua_pushfstring(m_state, "ASSERT FAILED ON LUA EXECUTE: %s", msg ? msg : "unknown");
    lua_error(m_state);
    return true;
}

int CCLuaStack::reallocateScriptHandler(int nHandler)
{
    LUA_FUNCTION  nNewHandle = -1;
    
    if (pushFunctionByHandler(nHandler))
    {
       nNewHandle = toluafix_ref_function(m_state,lua_gettop(m_state),0);
    }
/*
    toluafix_get_function_by_refid(m_state,nNewHandle);
    if (!lua_isfunction(m_state, -1))
    {
        CCLOG("Error!");
    }
    lua_settop(m_state, 0);
*/
    return nNewHandle;

}

int CCLuaStack::executeFunctionReturnArray(int nHandler,int nNumArgs,int nNummResults,CCArray* pResultArray)
{
    if (NULL == pResultArray)
        return 0;

    if (pushFunctionByHandler(nHandler))                 /* L: ... arg1 arg2 ... func */
    {
        if (nNumArgs > 0)
        {
            lua_insert(m_state, -(nNumArgs + 1));         /* L: ... func arg1 arg2 ... */
            int functionIndex = -(nNumArgs + 1);
            if (!lua_isfunction(m_state, functionIndex))
            {
                CCLOG("value at stack [%d] is not function", functionIndex);
                lua_pop(m_state, nNumArgs + 1); // remove function and arguments
                return 0;
            }
            
            int traceback = 0;
            lua_getglobal(m_state, "__G__TRACKBACK__");                         /* L: ... func arg1 arg2 ... G */
            if (!lua_isfunction(m_state, -1))
            {
                lua_pop(m_state, 1);                                            /* L: ... func arg1 arg2 ... */
            }
            else
            {
                lua_insert(m_state, functionIndex - 1);                         /* L: ... G func arg1 arg2 ... */
                traceback = functionIndex - 1;
            }
            
            int error = 0;
            ++m_callFromLua;
            error = lua_pcall(m_state, nNumArgs, nNummResults, traceback);                  /* L: ... [G] ret1 ret2 ... retResults*/
            --m_callFromLua;
            if (error)
            {
                if (traceback == 0)
                {
                    CCLOG("[LUA ERROR] %s", lua_tostring(m_state, - 1));        /* L: ... error */
                    lua_pop(m_state, 1); // remove error message from stack
                }
                else                                                            /* L: ... G error */
                {
                    lua_pop(m_state, 2); // remove __G__TRACKBACK__ and error message from stack
                }
                return 0;
            }
            
            // get return value,don't pass LUA_MULTRET to numResults,
            if (nNummResults <= 0)
                return 0;
            
            for (int i = 0 ; i < nNummResults; i++)
            {
                if (lua_type(m_state, -1) == LUA_TBOOLEAN) {
                    
                    bool value = lua_toboolean(m_state, -1);
                    pResultArray->addObject(CCBool::create(value)) ;
                    
                }else if (lua_type(m_state, -1) == LUA_TNUMBER) {
                    
                    double value = lua_tonumber(m_state, -1);
                    pResultArray->addObject(CCDouble::create(value));
                    
                }else if (lua_type(m_state, -1) == LUA_TSTRING) {
                    
                    const char* value = lua_tostring(m_state, -1);
                    pResultArray->addObject(CCString::create(value));
                    
                }else{
                    
                    pResultArray->addObject(static_cast<CCObject*>(tolua_tousertype(m_state, -1, NULL)));
                }
                // remove return value from stack
                lua_pop(m_state, 1);                                                /* L: ... [G] ret1 ret2 ... ret*/
            }
            /* L: ... [G]*/
            
            if (traceback)
            {
                lua_pop(m_state, 1); // remove __G__TRACKBACK__ from stack      /* L: ... */
            }
        }
    }
    
    lua_settop(m_state, 0);
    
    return 1;
}

void CCLuaStack::setXXTEAKeyAndSign(const char *key, int keyLen, const char *sign, int signLen)
{
    cleanupXXTEAKeyAndSign();
    
    if (key && keyLen && sign && signLen)
    {
        m_xxteaKey = (char*)malloc(keyLen);
        memcpy(m_xxteaKey, key, keyLen);
        m_xxteaKeyLen = keyLen;
        
        m_xxteaSign = (char*)malloc(signLen);
        memcpy(m_xxteaSign, sign, signLen);
        m_xxteaSignLen = signLen;
        
        m_xxteaEnabled = true;
    }
    else
    {
        m_xxteaEnabled = false;
    }
}

int CCLuaStack::loadChunksFromZIP(const char *zipFilePath)
{
	pushString(zipFilePath);
	lua_loadChunksFromZIP(m_state);
	int ret = lua_toboolean(m_state, -1);
	lua_pop(m_state, 1);
	return ret;
}

void CCLuaStack::cleanupXXTEAKeyAndSign()
{
    if (m_xxteaKey)
    {
        free(m_xxteaKey);
        m_xxteaKey = NULL;
        m_xxteaKeyLen = 0;
    }
    if (m_xxteaSign)
    {
        free(m_xxteaSign);
        m_xxteaSign = NULL;
        m_xxteaSignLen = 0;
    }
}

int CCLuaStack::lua_loadChunksFromZIP(lua_State *L)
{
	if (lua_gettop(L) < 1)
	{
		CCLOG("lua_loadChunksFromZIP() - invalid arguments");
		return 0;
	}

	const char *zipFilename = lua_tostring(L, -1);
	lua_settop(L, 0);
	CCFileUtils *utils = CCFileUtils::sharedFileUtils();
	string zipFilePath = utils->fullPathForFilename(zipFilename);
	zipFilename = NULL;

	CCLuaStack *stack = s_stack;

	do
	{
		unsigned long size = 0;
		void *buffer = NULL;
		unsigned char *zipFileData = utils->getFileData(zipFilePath.c_str(), "rb", &size);
		CCZipFile *zip = NULL;

		bool isXXTEA = stack && stack->m_xxteaEnabled && zipFileData;
		for (unsigned int i = 0; isXXTEA && i < stack->m_xxteaSignLen && i < size; ++i)
		{
			isXXTEA = zipFileData[i] == stack->m_xxteaSign[i];
		}

		if (isXXTEA)
		{
			// decrypt XXTEA
			xxtea_long len = 0;
			buffer = xxtea_decrypt(zipFileData + stack->m_xxteaSignLen,
				(xxtea_long)size - (xxtea_long)stack->m_xxteaSignLen,
				(unsigned char*)stack->m_xxteaKey,
				(xxtea_long)stack->m_xxteaKeyLen,
				&len);
			delete[]zipFileData;
			zipFileData = NULL;
			zip = CCZipFile::createWithBuffer(buffer, len);
		}
		else
		{
			if (zipFileData) {
				zip = CCZipFile::createWithBuffer(zipFileData, size);
			}
		}

		if (zip)
		{
			CCLOG("lua_loadChunksFromZIP() - load zip file: %s%s", zipFilePath.c_str(), isXXTEA ? "*" : "");
			lua_getglobal(L, "package");
			lua_getfield(L, -1, "preload");

			int count = 0;
			string filename = zip->getFirstFilename();
			while (filename.length())
			{
				unsigned long bufferSize = 0;
				unsigned char *buffer = zip->getFileData(filename.c_str(), &bufferSize);
				if (bufferSize)
				{
					if (stack->luaLoadBuffer(L, (char*)buffer, (int)bufferSize, filename.c_str()) == 0)
					{
						lua_setfield(L, -2, filename.c_str());
						++count;
					}
					delete[]buffer;
				}
				filename = zip->getNextFilename();
			}
			CCLOG("lua_loadChunksFromZIP() - loaded chunks count: %d", count);
			lua_pop(L, 2);
			lua_pushboolean(L, 1);
		}
		else
		{
			CCLOG("lua_loadChunksFromZIP() - not found or invalid zip file: %s", zipFilePath.c_str());
			lua_pushboolean(L, 0);
		}

		if (zipFileData)
		{
			delete[]zipFileData;
		}
		if (buffer)
		{
			free(buffer);
		}
	} while (0);

	return 1;
}


int CCLuaStack::luaLoadBuffer(lua_State* L, const char* chunk, int chunkSize, const char* chunkName)
{
    int r = 0;
    
    if (m_xxteaEnabled && strncmp(chunk, m_xxteaSign, m_xxteaSignLen) == 0)
    {
        // decrypt XXTEA
        xxtea_long len = 0;
        unsigned char* result = xxtea_decrypt((unsigned char*)chunk + m_xxteaSignLen,
                                              (xxtea_long)chunkSize - m_xxteaSignLen,
                                              (unsigned char*)m_xxteaKey,
                                              (xxtea_long)m_xxteaKeyLen,
                                              &len);
        r = luaL_loadbuffer(L, (char*)result, len, chunkName);
        free(result);
    }
    else
    {
        r = luaL_loadbuffer(L, chunk, chunkSize, chunkName);
    }

#if defined(COCOS2D_DEBUG) && COCOS2D_DEBUG > 0
    if (r)
    {
        switch (r)
        {
            case LUA_ERRSYNTAX:
                CCLOG("[LUA ERROR] load \"%s\", error: syntax error during pre-compilation.", chunkName);
                break;
                
            case LUA_ERRMEM:
                CCLOG("[LUA ERROR] load \"%s\", error: memory allocation error.", chunkName);
                break;
                
            case LUA_ERRFILE:
                CCLOG("[LUA ERROR] load \"%s\", error: cannot open/read file.", chunkName);
                break;
                
            default:
                CCLOG("[LUA ERROR] load \"%s\", error: unknown.", chunkName);
        }
    }
#endif
    return r;
}

NS_CC_END

USING_NS_CC;

static map<unsigned int, char*> hash_type_mapping;

static unsigned int _Hash(const char *key)
{
	unsigned int len = (unsigned int)strlen(key);
	const char *end = key + len;
	unsigned int hash;

	for (hash = 0; key < end; key++)
	{
		hash *= 16777619;
		hash ^= (unsigned int)(unsigned char)toupper(*key);
	}
	return (hash);
}

unsigned int class_hash_code(const std::type_info& info)
{
	// hash name() to size_t value by pseudorandomizing transform
	return _Hash(info.name());
}

TOLUA_API void toluafix_add_type_mapping(unsigned int type, const char *clsName)
{
	if (hash_type_mapping.find(type) == hash_type_mapping.end())
	{
		hash_type_mapping[type] = strdup(clsName);
	}
}

TOLUA_API int toluafix_pushusertype_ccobject(lua_State *L,
	int refid,
	int *p_refid,
	void *vptr,
	const char *vtype)
{
	if (vptr == NULL || p_refid == NULL)
	{
		lua_pushnil(L);
		return -1;
	}

	CCObject *ptr = static_cast<CCObject*>(vptr);
	unsigned int hash = class_hash_code(typeid(*ptr));
	char* type = hash_type_mapping[hash];
	if (type == NULL)
	{
		// CCLOG("[TOLUA] Unable to find type map for object %s:%p,", vtype, vptr);
	}

	if (*p_refid == 0)
	{
		*p_refid = refid;

		lua_pushstring(L, TOLUA_REFID_PTR_MAPPING);
		lua_rawget(L, LUA_REGISTRYINDEX);                           /* stack: refid_ptr */
		lua_pushinteger(L, refid);                                  /* stack: refid_ptr refid */
		lua_pushlightuserdata(L, ptr);                              /* stack: refid_ptr refid ptr */

		lua_rawset(L, -3);                  /* refid_ptr[refid] = ptr, stack: refid_ptr */
		lua_pop(L, 1);                                              /* stack: - */

		lua_pushstring(L, TOLUA_REFID_TYPE_MAPPING);
		lua_rawget(L, LUA_REGISTRYINDEX);                           /* stack: refid_type */
		lua_pushinteger(L, refid);                                  /* stack: refid_type refid */
		lua_pushstring(L, type ? type : vtype);                     /* stack: refid_type refid type */
		lua_rawset(L, -3);                /* refid_type[refid] = type, stack: refid_type */
		lua_pop(L, 1);                                              /* stack: - */

		//printf("[LUA] push CCObject OK - refid: %d, ptr: %x, type: %s\n", *p_refid, (int)ptr, type);
	}

	tolua_pushusertype_and_addtoroot(L, ptr, type ? type : vtype);
	return 0;
}
