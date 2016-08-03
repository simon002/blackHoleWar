-- cclog
require("lfs")
print("ffffffffffffffffffffff\0")
cclog = function(...)
    print(string.format(...))
end

-- for CCLuaEngine traceback
function __G__TRACKBACK__(msg)
    cclog("----------------------------------------")
    cclog("LUA ERROR: " .. tostring(msg) .. "\n")
    cclog(debug.traceback())
    cclog("----------------------------------------")
end

local function main()
    -- avoid memory leak
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 5000)
    -- run
    local sceneGame = CCScene:create()
	local sprite = CCSprite:create("HelloWorld.png")
	sceneGame:addChild(sprite)

    CCDirector:sharedDirector():runWithScene(sceneGame)
	print("jjjjjjjjjjjjjjjjjjjjjjjjj")
end

xpcall(main, __G__TRACKBACK__)
