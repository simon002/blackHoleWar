local CURRENT_MODULE_NAME = ...
local PACKAGE_NAME = string.sub(CURRENT_MODULE_NAME, 1, -9)

if not USING_OLD_PROTO then
    require (PACKAGE_NAME..".protobuf.protobuf")
    require (PACKAGE_NAME..".protobuf.parser")
end

local Network = class("Network")


function Network:ctor()
    -- self.name = "Network"
    -- d("Network:ctor()")
    self.cmdHandlersTable = {}
    if not USING_OLD_PROTO then
        self.protobuf = require "protobuf"
    end
    -- local filePath = "proto/account.pb"
    -- local buffer = lerna.FileUtil.readFile(filePath)
    -- self.protobuf.register(buffer)
 --    local filePath = lerna.FileUtil.getFullPath("proto/addressbook.pb")
    -- filePath = "proto/addressbook.pb"
 --    local filePath = "proto/account.pb"
    -- buffer = lerna.FileUtil.readFile(filePath)
    -- -- -- print(buffer)
    -- self.protobuf.register(buffer)
    -- print ("CMSG_SERVER_CONFIG_REQ"..self.protobuf.enum_id("protocol.AccountOpcode", "CMSG_SERVER_CONFIG_REQ"))

    -- local person = {
    --     name = "Alice",
    --     id = 123,
    --     phone = {
    --         { number = "123456789" , type = "MOBILE" },
    --         { number = "87654321" , type = "HOME" },
    --     }
    -- }

    -- local buffer = protobuf.encode("tutorial.Person", person)
    -- -- print("buffer = "..buffer)
    -- -- print("end")
    -- local t = protobuf.decode("tutorial.Person", buffer)

    -- for k,v in pairs(t) do
    --     if type(k) == "string" then
    --         print(k,v)
    --     end
    -- end

    -- print(t.phone[2].type)

    -- for k,v in pairs(t.phone[1]) do
    --     print(k,v)
    -- end
end

-- 初始化PB文件
function Network:load(pbFilesTable)
    for i=1, #pbFilesTable do
        local filePath = pbFilesTable[i]
        local buffer = lerna.FileUtil.readFile(filePath)
        self.protobuf.register(buffer)
    end
end

function Network:Init(serverIp, serverPort)
    local game = Game:instance()
    local gameSession = game:GetSession()
    gameSession:setSessionPacketHandler(handler(self, self._handlePacketAfterClientSession))
    -- d("serverIp = "..serverIp.." serverPort = "..serverPort)
    if serverIp and serverPort then
        game:setServerIp(serverIp)
        game:setServerPort(serverPort)
        local gameApp = AppDelegate:instance()
        gameApp:netWorkRun()
    end
end

-- 请求连接网络
function Network:connect()
    local game = Game:instance()
    game:Connect()
end

-- 网络连接成功
function Network:onConnected(callback)
    if type(callback) == 'function' then
        local game = Game:instance()
        game:addConnectLuaListener(callback)
    end
end

-- 网络连接失败
function Network:onConnectFailed(callback)
    if type(callback) == 'function' then
        local game = Game:instance()
        game:addConnectFailedLuaListener(callback)
    end
end

-- 网络断线
function Network:onDisconnected(callback)
    if type(callback) == 'function' then
        local game = Game:instance()
        game:addDisconnectLuaListener(callback)
    end
end

-- 账号登出
function Network:logOut()
    local game = Game:instance()
    game:Logout()
end

-- protobuffer加密
function Network:DecodeProto(protoname, packet)
    return self.protobuf.decode(protoname, packet)
end

-- protobuffer解密
function Network:EndcodeProto(protoname, propTable)
    -- print("Network:EndcodeProto = "..protoname.." propTable = "..tostring(propTable))
    local buffer = self.protobuf.encode(protoname, propTable)
    return buffer
end

-- 获得OPCMD
function Network:GetOpCMD(protoname, keyname)
    return self.protobuf.enum_id(protoname, keyname)
end

-- 添加响应函数
function Network:AddPacketHandler(nOptCmd, obj, callback)
    -- body
    local hasRegistHandler = false;

    local cmdHandlers = self.cmdHandlersTable[nOptCmd]

    if cmdHandlers==nil then
        cmdHandlers = {}
        self.cmdHandlersTable[nOptCmd] = cmdHandlers
    else
        for k,v in pairs(cmdHandlers) do
            if v[1]==obj and v[2]==callback then
                --
                hasRegistHandler = true
                break
            end
        end
    end

    if hasRegistHandler==false then
        local callbackDataTable = {}
        callbackDataTable[1] = obj
        callbackDataTable[2] = callback
        table.insert(cmdHandlers, callbackDataTable)
        -- print("table.insert obj = "..tostring(obj).." callback = "..tostring(callback))
    end
end

-- 移除响应函数
function Network:removePacketHandler(nOptCmd, obj, callback)
    -- body
    local cmdHandlers = self.cmdHandlersTable[nOptCmd]
    if cmdHandlers~=nil then
        for k,v in pairs(cmdHandlers) do
            if v[1]==obj and v[2]==callback then
                --
                table.remove(cmdHandlers, k)
                break
            end
        end
    end
end

-- 消息接收回调，这个回调函数在C++中被调用
function Network:_handlePacketAfterClientSession(isProto, nOptCmd, packet)
    -- body
    -- print("Network:_handlePacketAfterClientSession nOptCmd = "..nOptCmd)
    local cmdHandlers = self.cmdHandlersTable[nOptCmd]
    if cmdHandlers~=nil then
        local packetTable = nil

        for i=1, #cmdHandlers do
            local callbackDataTable = cmdHandlers[i]
            if packetTable == nil then
                packetTable = {}
                if isProto then
                    packetTable.protobuf = packet:readString()
                    -- packetTable = self.protobuf.decode("tutorial.Person", packet)
                else
                    -- local _p = packet:copyNew()
                    -- packetTable = self:_parsePacket(nOptCmd, _p)
                    -- _p:release()
                    packetTable = self:_parsePacket(nOptCmd, packet)
                end
            end

            if type(callbackDataTable) == "table" and callbackDataTable[1] and callbackDataTable[2] then
                callbackDataTable[2](callbackDataTable[1], packetTable, isProto)
            end
        end
    end
end

--packet解析函数，在上面的回调函数中被自动调用，无需手动调用
function Network:_parsePacket(nOptCmd, packet)
    local packetTable = {}
    if Protocal then
        local p = packet
        local protcalDefinition = Protocal[nOptCmd]
        if protcalDefinition~=nil then
            -- packetTable["protocal_ident"] = protcalDefinition["protocal_ident"]
            -- packetTable["protocal_name"] = protcalDefinition["protocal_name"]
            local propertiesTable = protcalDefinition["properties"]
            for i=1, #propertiesTable do

                local propertyTable = propertiesTable[i]
                local pkey = propertyTable[1]        --key值
                local ptype = propertyTable[2]        --value值所属类型
                local pdesc = propertyTable[3]        --key描述
                local value = nil
                -- 解析value值
                if self:_isCollectionTypeNormal(ptype) then
                    value = self:_readNormalValue(ptype, packet)
                elseif ptype==Protocal_TYPE_CLASS then
                    local className = propertyTable[4]
                    local classOptCmd = Protocal[className]
                    value = self:_parsePacket(classOptCmd, packet)
                elseif ptype==Protocal_TYPE_VECTOR then
                    local vectorSize = tonumber(propertyTable[4])
                    local realSize = p:readInt()
                    if vectorSize ~= 0 then
                        if realSize > vectorSize then
                            realSize = vectorSize
                        end
                    end
                    local vectorTable = {}
                    local className = propertyTable[5]
                    if self:_isCollectionTypeNormal(className) then
                        for j=1, realSize do
                            vectorTable[j] = self:_readNormalValue(className, packet)
                        end
                    else
                        local classOptCmd = Protocal[className]
                        for j=1, realSize do
                            vectorTable[j] = self:_parsePacket(classOptCmd, packet)
                        end
                    end
                    value = vectorTable
                elseif ptype==Protocal_TYPE_LIST then
                    local listSize = tonumber(propertyTable[4])
                    local realSize = p:readInt()
                    if listSize ~= 0 then
                        if realSize>listSize then
                            realSize = listSize
                        end
                    end
                    local listTable = {}
                    local className = propertyTable[5]
                    if self:_isCollectionTypeNormal(className) then
                        for j=1, realSize do
                            listTable[j] = self:_readNormalValue(className, packet)
                        end
                    else
                        local classOptCmd = Protocal[className]
                        for j=1, realSize do
                            listTable[j] = self:_parsePacket(classOptCmd, packet)
                        end
                    end
                    value = listTable
                elseif ptype==Protocal_TYPE_MAP then
                    local mapSize = tonumber(propertyTable[4])
                    local realSize = p:readInt()
                    if mapSize ~= 0 then
                        if realSize>mapSize then
                            realSize = mapSize
                        end
                    end
                    local mapTable = {}
                    local keyClassName = propertyTable[5]
                    local valueClassName = propertyTable[6]
                    if self:_isCollectionTypeNormal(valueClassName) then
                        for j=1, realSize do
                            local keyValue = self:_readNormalValue(keyClassName, packet)
                            local valueValue = self:_readNormalValue(valueClassName, packet)
                            mapTable[keyValue] = valueValue
                        end
                    else
                        for j=1, realSize do
                            local classOptCmd = Protocal[valueClassName]
                            local keyValue = self:_readNormalValue(keyClassName, packet)
                            local valueValue = self:_parsePacket(classOptCmd, packet)
                            mapTable[keyValue] = valueValue
                        end
                    end
                    value = mapTable
                end
                -- print ("解析 pkey ＝ "..pkey.." ptype = "..ptype.." value = "..tostring(value))
                packetTable[pkey] = value
            end
        else
            --错误，没有找到协议体定义
            d("错误，Protocal中没有找到协议体定义")
        end
    else
        d("没有协议结构定义Protocal")
    end
    return packetTable
end

-- protobuf 发送函数，需要手动调用
-- nOptCmd 协议ID
-- protoname proto 文件名
-- packetTable 协议的数据体（数据体跟proto文件对应）
function Network:SendProtoPacket(nOptCmd, protoname, packetTable)
    -- body
    local packetLua = INetPacketLua:createINetPacketLua()
    if protoname~=nil and packetTable~=nil then
        local buffer = self:EndcodeProto(protoname, packetTable)
        packetLua:writeStringWithSize(buffer, string.len(buffer))
    end
    local game = Game:instance()
    local gameSession = game:GetSession()
    gameSession:send(packetLua, nOptCmd+32768)
end

function Network:SendProtoPacket(opcmdProtoName, opcmdKeyName, protoname, packetTable)
    -- body
    local packetLua = INetPacketLua:createINetPacketLua()
    if protoname~=nil and packetTable~=nil then
        local buffer = self:EndcodeProto(protoname, packetTable)
        packetLua:writeStringWithSize(buffer, string.len(buffer))
    end
    local game = Game:instance()
    local gameSession = game:GetSession()
    local nOptCmd = self:GetOpCMD(opcmdProtoName, opcmdKeyName)
    gameSession:send(packetLua, nOptCmd+32768)
end

-- packet 发送函数，需要手动调用
-- protocalname: 协议名称
-- packetTable: 协议的数据体（数据体需要详细介绍）
function Network:SendPacket(protocalname, packetTable)
    -- body
    local packetLua = INetPacketLua:createINetPacketLua()
    if packetTable~= nil then
        if self:_fillPacket(protocalname, packetTable, packetLua) then
            -- 这里调用的C++的接口发包，目前根据项目有些获取Game实例会不一样（LHJ和MJ是这个）
            -- DN好像是sharedGame
            local game = Game:instance()
            local gameSession = game:GetSession()
            gameSession:send(packetLua, Protocal[protocalname])
        end
    else
        local game = Game:instance()
        local gameSession = game:GetSession()
        gameSession:send(packetLua, Protocal[protocalname])
    end
    packetLua:release()
end

--根据协议配置和现有数据填充packet，无需手动调用
function Network:_fillPacket(protocalname, packetTable, packet)
    -- body
    if Protocal==nil then
        d("没有协议结构定义Protocal")
        return false
    end
    local classOptCmd = Protocal[protocalname]
    local res = true
    if classOptCmd~=nil then
        local protcalDefinition = Protocal[classOptCmd]
        local propertiesTable = protcalDefinition["properties"]
        for i=1, #propertiesTable do
            local propertyTable = propertiesTable[i]
            local pkey = propertyTable[1]        --key值
            local ptype = propertyTable[2]        --value值所属类型
            local pdesc = propertyTable[3]        --key描述
            local value = packetTable[pkey]
            if self:_isCollectionTypeNormal(ptype) then
                self:_writeNormalValue(ptype, packet, value)
            elseif ptype==Protocal_TYPE_CLASS then
                local className = propertyTable[4]
                res = self:_fillPacket(className, value, packet)
            elseif ptype==Protocal_TYPE_VECTOR then
                local vectorSize = #value
                local maxVectorSize = tonumber(propertyTable[4])
                if maxVectorSize ~= 0 then
                    if vectorSize>maxVectorSize then
                        vectorSize = maxVectorSize
                    end
                end
                packet:writeInt(vectorSize)
                local className = propertyTable[5]
                for j=1, vectorSize do
                    res = self:_fillPacket(className, value[j], packet)
                    if res==false then
                        break
                    end
                end
            elseif ptype==Protocal_TYPE_LIST then
                local listSize = #value
                local maxListSize = tonumber(propertyTable[4])
                if maxListSize ~= 0 then
                    if listSize>maxListSize then
                        listSize = maxListSize
                    end
                end
                packet:writeInt(listSize)
                local className = propertyTable[5]
                for j=1, listSize do
                    res = self:_fillPacket(className, value[j], packet)
                    if res==false then
                        break
                    end
                end
            elseif ptype==Protocal_TYPE_MAP then
                local mapSize = 0
                for k,v in pairs(value) do
                    mapSize = mapSize+1
                end
                local maxMapSize = tonumber(propertyTable[4])
                if maxMapSize ~= 0 then
                    if mapSize>maxMapSize then
                        mapSize = maxMapSize
                    end
                end
                packet:writeInt(mapSize)
                local keyClassName = propertyTable[5]
                local valueClassName = propertyTable[6]
                for k,v in pairs(value) do
                    self:_writeNormalValue(keyClassName, packet, k)
                    if self:_isCollectionTypeNormal(valueClassName) then
                        self:_writeNormalValue(valueClassName, packet, v)
                    else
                        res = self:_fillPacket(valueClassName, v, packet)
                        if res==false then
                            break
                        end
                    end
                end
            end
            if res==false then
                break
            end
        end
    else
        d("错误，Protocal中没有找到协议体定义 "..protocalname)
        res = false
    end
    return res
end

-- 检查 list，vector，map 中的类型是不是普通类型。无需手动调用
function Network:_isCollectionTypeNormal(type)
    if type==Protocal_TYPE_CHAR then
        return true
    elseif type==Protocal_TYPE_UCHAR then
        return true
    elseif type==Protocal_TYPE_SHORT then
        return true
    elseif type==Protocal_TYPE_USHORT then
        return true
    elseif type==Protocal_TYPE_INT then
        return true
    elseif type==Protocal_TYPE_UINT then
        return true
    elseif type==Protocal_TYPE_LONGLONG then
        return true
    elseif type==Protocal_TYPE_BOOL then
        return true
    elseif type==Protocal_TYPE_FLOAT then
        return true
    elseif type==Protocal_TYPE_STRING then
        return true
    end

    return false
end

-- 从packet中读取普通类型。无需手动调用
function Network:_readNormalValue(ptype, packet)
    local value = nil
    if ptype==Protocal_TYPE_CHAR then
        value = packet:readChar()
    elseif ptype==Protocal_TYPE_UCHAR then
        value = packet:readChar()
    elseif ptype==Protocal_TYPE_SHORT then
        value = packet:readShort()
    elseif ptype==Protocal_TYPE_USHORT then
        value = packet:readShort()
    elseif ptype==Protocal_TYPE_INT then
        value = packet:readInt()
    elseif ptype==Protocal_TYPE_UINT then
        value = packet:readInt()
    elseif ptype==Protocal_TYPE_LONGLONG then
        value = packet:readLongLong()
    elseif ptype==Protocal_TYPE_BOOL then
        value = packet:readBool()
    elseif ptype==Protocal_TYPE_FLOAT then
        value = packet:readFloat()
    elseif ptype==Protocal_TYPE_STRING then
        value = packet:readString()
    end
    -- print ("readNormalValue type = "..ptype.." value = "..tostring(value))
    return value
end

-- 写一个普通类型字段到packet。无需手动调用
function Network:_writeNormalValue(ptype, packet, value)
    if ptype==Protocal_TYPE_CHAR then
        packet:writeChar(value)
    elseif ptype==Protocal_TYPE_UCHAR then
        packet:writeChar(value)
    elseif ptype==Protocal_TYPE_SHORT then
        packet:writeShort(value)
    elseif ptype==Protocal_TYPE_USHORT then
        packet:writeShort(value)
    elseif ptype==Protocal_TYPE_INT then
        packet:writeInt(value)
    elseif ptype==Protocal_TYPE_UINT then
        packet:writeInt(value)
    elseif ptype==Protocal_TYPE_LONGLONG then
        packet:writeLongLong(value)
    elseif ptype==Protocal_TYPE_BOOL then
        packet:writeBool(value)
    elseif ptype==Protocal_TYPE_FLOAT then
        packet:writeFloat(value)
    elseif ptype==Protocal_TYPE_STRING then
        packet:writeString(value)
    end
    -- print ("readNormalValue type = "..ptype.." value = "..tostring(value))
    return value
end


return Network
