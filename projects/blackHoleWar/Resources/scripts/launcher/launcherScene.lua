local LauncherHelper = require("launcher.LauncherHelper")
local LauncherScene = LauncherHelper.lcher_class("LauncherScene", function()
	local scene = CCScene:create()
	scene.name = "LauncherScene"
    return scene
end)

function LauncherScene:ctor()
    self._path = LauncherHelper.writablePath .. "upd/"
    CCFileUtils:sharedFileUtils():addSearchPath(self._path)
    CCFileUtils:sharedFileUtils():addSearchPath("Resources/")

	self._textLabel = CCLabelTTF:create("正在检测更新,请耐心等待...", "fonts/arial.ttf", 20)
	self._textLabel:setColor(ccc3(255, 255, 255))
	self._textLabel:setPosition(LauncherHelper.cx, LauncherHelper.cy - 60)
	self:addChild(self._textLabel)
	self:_checkUpdate()
    --Launcher.performWithDelayGlobal(function()
    --	 if (LauncherHelper.platform == "android" or LauncherHelper.platform == "ios") then
	--		Launcher.initPlatform(LauncherHelper.lcher_handler(self, self._initPlatformResult))
	--	else
	--		enter_game()
	--	end
    --end, 0.1)
end

function LauncherScene:_checkUpdate()
	LauncherHelper.mkDir(self._path)

	self._curListFile =  self._path .. LauncherHelper.fListName
	if LauncherHelper.fileExists(self._curListFile) then
        self._fileList = LauncherHelper.doFile(self._curListFile)
    end

    if self._fileList ~= nil then
        local appVersionCode = Launcher.getAppVersionCode()
        if appVersionCode ~= self._fileList.appVersion then
            --新的app已经更新需要删除upd/目录下的所有文件
            LauncherHelper.removePath(self._path)
            require("main")
            return
        end
    else
    	--self._fileList = LauncherHelper.doFile("scripts/"..LauncherHelper.fListName)
		local flist = "scripts/" .. LauncherHelper.fListName
		self._fileList = dofile(flist)
    end
    print(self._fileList)
    if self._fileList == nil then
    	self._updateRetType = LauncherHelper.UpdateRetType.OTHER_ERROR
    	self:_endUpdate()
    end
--
    --self:_requestFromServer(Launcher.libDir .. Launcher.lcherZipName, Launcher.RequestType.LAUNCHER, 30)
end

function LauncherScene:_requestFromServer(filename, requestType, waittime)
    local url = LauncherHelper.server .. filename

    if LauncherHelper.needUpdate then
        local request = CCHTTPRequest:createWithUrl(function(event) 
        	self:_onResponse(event, requestType)
        end, url, kCCHTTPRequestMethodGET)

        if request then
        	request:setTimeout(waittime or 60)
        	request:start()
    	else
    		--初始化网络错误
    		self._updateRetType = UpdateRetType.NETWORK_ERROR
        	self:_endUpdate()
    	end
    else
    	--不更新
    	enter_game()
    end
end

function LauncherScene:_onResponse(event, requestType)
    local request = event.request
    if event.name == "completed" then
        if request:getResponseStatusCode() ~= 200 then
            self._updateRetType = LauncherHelper.UpdateRetType.NETWORK_ERROR
        	self:_endUpdate()
        else
            local dataRecv = request:getResponseData()
            if requestType == LauncherHelper.RequestType.LAUNCHER then
            	self:_onLauncherPacakgeFinished(dataRecv)
            elseif requestType == LauncherHelper.RequestType.FLIST then
            	self:_onFileListDownloaded(dataRecv)
            else
            	self:_onResFileDownloaded(dataRecv)
            end
        end
    elseif event.name == "inprogress" then
    	 if requestType == LauncherHelper.RequestType.RES then
    	 	self:_onResProgress(event.dlnow)
    	 end
    else
        self._updateRetType = LauncherHelper.UpdateRetType.NETWORK_ERROR
        self:_endUpdate()
    end
end

function LauncherScene:_onFileListDownloaded(dataRecv)
	self._newListFile = self._curListFile .. LauncherHelper.updateFilePostfix
	LauncherHelper.writefile(self._newListFile, dataRecv)

	self._fileListNew = LauncherHelper.doFile(self._newListFile)
	if self._fileListNew == nil then
        self._updateRetType = LauncherHelper.UpdateRetType.OTHER_ERROR
		self:_endUpdate()
		return
	end

	if self._fileListNew.version == self._fileList.version then
		LauncherHelper.removePath(self._newListFile)
		self._updateRetType = LauncherHelper.UpdateRetType.SUCCESSED
		self:_endUpdate()
		return
	end

	--创建资源目录
	local dirPaths = self._fileListNew.dirPaths
    for i=1,#(dirPaths) do
        LauncherHelper.mkDir(self._path..(dirPaths[i].name))
    end

    self:_updateNeedDownloadFiles()

    self._numFileCheck = 0
    self:_reqNextResFile()

end


local lchr = LauncherScene.new()
LauncherHelper.runWithScene(lchr)