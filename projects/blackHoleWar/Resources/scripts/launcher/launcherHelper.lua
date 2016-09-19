
require("lfs")
LauncherHelper = {}

LauncherHelper.server = "http://192.168.1.119/xxoo/"
LauncherHelper.fListName = "flist.lua"
LauncherHelper.libDir = "lib/"
LauncherHelper.lcherZipName = "launcher.zip"
LauncherHelper.updateFilePostfix = ".upd"
--是否需要更新
LauncherHelper.needUpdate = true

--请求类型
LauncherHelper.RequestType = { LAUNCHER = 0, FLIST = 1, RES = 2 }
--更新结果
LauncherHelper.UpdateRetType = { SUCCESSED = 0, NETWORK_ERROR = 1, MD5_ERROR = 2, OTHER_ERROR = 3 }

LauncherHelper.writablePath = CCFileUtils:sharedFileUtils():getWritablePath()

local sharedApplication = CCApplication:sharedApplication()
local sharedDirector = CCDirector:sharedDirector()
local target = sharedApplication:getTargetPlatform()
LauncherHelper.platform    = "unknown"
LauncherHelper.model       = "unknown"

local sharedApplication = CCApplication:sharedApplication()
local target = sharedApplication:getTargetPlatform()
if target == kTargetWindows then
    LauncherHelper.platform = "windows"
elseif target == kTargetMacOS then
    LauncherHelper.platform = "mac"
elseif target == kTargetAndroid then
    LauncherHelper.platform = "android"
elseif target == kTargetIphone or target == kTargetIpad then
    LauncherHelper.platform = "ios"
    if target == kTargetIphone then
        LauncherHelper.model = "iphone"
    else
        LauncherHelper.model = "ipad"
    end
end

local winSize = sharedDirector:getWinSize()
LauncherHelper.size = {width = winSize.width, height = winSize.height}
LauncherHelper.width              = LauncherHelper.size.width
LauncherHelper.height             = LauncherHelper.size.height
LauncherHelper.cx                 = LauncherHelper.width / 2
LauncherHelper.cy                 = LauncherHelper.height / 2

function LauncherHelper.lcher_handler(obj, method)
    return function(...)
        return method(obj, ...)
    end
end

function LauncherHelper.lcher_class(classname, super)
    local superType = type(super)
    local cls

    if superType ~= "function" and superType ~= "table" then
        superType = nil
        super = nil
    end

    if superType == "function" or (super and super.__ctype == 1) then
        -- inherited from native C++ Object
        cls = {}

        if superType == "table" then
            -- copy fields from super
            for k,v in pairs(super) do cls[k] = v end
            cls.__create = super.__create
            cls.super    = super
        else
            cls.__create = super
            cls.ctor = function() end
        end

        cls.__cname = classname
        cls.__ctype = 1

        function cls.new(...)
            local instance = cls.__create(...)
            -- copy fields from class to native object
            for k,v in pairs(cls) do instance[k] = v end
            instance.class = cls
            instance:ctor(...)
            return instance
        end

    else
        -- inherited from Lua Object
        if super then
            cls = {}
            setmetatable(cls, {__index = super})
            cls.super = super
        else
            cls = {ctor = function() end}
        end

        cls.__cname = classname
        cls.__ctype = 2 -- lua
        cls.__index = cls

        function cls.new(...)
            local instance = setmetatable({}, cls)
            instance.class = cls
            instance:ctor(...)
            return instance
        end
    end

    return cls
end

function LauncherHelper.performWithDelayGlobal(listener, time)
    local scheduler = CCDirector:sharedDirector():getScheduler()
    local handle = nil
    handle = scheduler:scheduleScriptFunc(function()
        scheduler:unscheduleScriptEntry(handle)
        listener()
    end, time, false)
end

function LauncherHelper.runWithScene(scene)
    local curScene = sharedDirector:getRunningScene()
    if curScene then
        sharedDirector:replaceScene(scene)
    else
        sharedDirector:runWithScene(scene)
    end
end

function LauncherHelper.fileExists(path)
    return CCFileUtils:sharedFileUtils():isFileExist(path)
end

function LauncherHelper.mkDir(path)
    if not LauncherHelper.fileExists(path) then
        return lfs.mkdir(path)
    end
    return true
end

function LauncherHelper.doFile(path)
    local fileData = CZHelperFunc:getFileData(path)
    local fun = loadstring(fileData)
    print(fun)
    local ret, flist = pcall(fun)
    if ret then
        return flist
    end

    return flist
end

function LauncherHelper.removePath(path)
    local mode = lfs.attributes(path, "mode")
    if mode == "directory" then
        local dirPath = path.."/"
        for file in lfs.dir(dirPath) do
            if file ~= "." and file ~= ".." then 
                local f = dirPath..file 
                Launcher.removePath(f)
            end 
        end
        os.remove(path)
    else
        os.remove(path)
    end
end

return LauncherHelper