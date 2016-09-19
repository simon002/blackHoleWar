local Launcher = {}
Launcher.writablePath = CCFileUtils:sharedFileUtils():getWritablePath()

function Launcher.requestFromServer(url,type)
	CCHTTPRequest:createWithUrl()
end

function Launcher.responeFromServer()
end

function LauncherScene:_requestFromServer(filename, requestType, waittime)
    local url = Launcher.server .. filename

    if Launcher.needUpdate then
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




