----------------------------------------
-- light框架的聊天网络模块
-- 作者：xuli
-- 如果使用此模块 C++功能必须包含 vendors/socketconnect 工程
-- 创建日期：2016-04-12
----------------------------------------

local CURRENT_MODULE_NAME = ...
local PACKAGE_NAME = string.sub(CURRENT_MODULE_NAME, 1, -14)

if not USING_OLD_PROTO then
    require (PACKAGE_NAME.."lerna.protobuf.protobuf")
    require (PACKAGE_NAME.."lerna.protobuf.parser")
end

local NetChat = class("NetChat")

function NetChat:ctor()
    self._net = nil

    self._tbHandler = {}

    self:_init()

    self._tbEventLuaHandler = nil
    
    self.e = 
    {
        ["CONNECT_FAIL"]            = "CONNECT_FAIL",
        ["SEND_MESSAGE_SUCCESS"]    = "SEND_MESSAGE_SUCCESS",
        ["CONNECT_DISCONNECTED"]    = "CONNECT_DISCONNECTED",
        ["CONNECT_SERVER_CLOSE"]    = "CONNECT_SERVER_CLOSE",
        ["CLIENT_HOST_PORT_ERROR"]  = "CLIENT_HOST_PORT_ERROR",
        ["CREATE_SOCKET_FAIL"]      = "CREATE_SOCKET_FAIL",
        ["CONNECT_SUCCESS"]         = "CONNECT_SUCCESS"
    }

    if not USING_OLD_PROTO then
        self.protobuf = require "protobuf"
    end
end

function NetChat:_init()
    if SocketConnect and SocketConnect.getInstance then
        self._net = SocketConnect:getInstance()
        self._net:registerLuaHandler(handler(self, self._handlerSocketPackage))
    end
end

function NetChat:connectServer(address, iport)
    if self._net then
        self._net:startSocker(address, iport)
    end
end

function NetChat:reconnect()
    if self._net then
        self._net:reConnect()
    end
end

function NetChat:sendSocketMeassge(proto_pb, buffer)
    if self._net then 
        local buffer = self:_EndcodeProto(proto_pb, buffer)
        self._net:sendSocketMssage(buffer, string.len(buffer))
    end
end

function NetChat:registerListern(opcode, luaHandler)
    if opcode and luaHandler then
        local opcmd = self:_GetOpCMD('protocol.opcode', opcode)
        if opcmd then
            self._tbHandler[opcmd] =  {}
            self._tbHandler[opcmd] = luaHandler
        end
    end
end

function NetChat:unregisterListren(opcode)
    if opcode then
        self._tbHandler[opcode] = {}
    end
end

-- RESP_ERROR_MSG=-4;  //出现错误
-- RESP_AUTH_FAILD=-2; //认证失败
-- RESP_ACK=0;         //请求已收到
function NetChat:_handlerSocketPackage(deltime, status, buffer, ilen)

    if CONNECT_FAIL == status then 
      self:_onEventMessageHandler(self.e.CONNECT_FAIL, deltime)

    elseif SEND_MESSAGE_SUCCESS == status then
     self:_onEventMessageHandler(self.e.SEND_MESSAGE_SUCCESS, deltime)

    elseif CONNECT_DISCONNECTED == status then 
       self:_onEventMessageHandler(self.e.CONNECT_DISCONNECTED, deltime)

    elseif CONNECT_SERVER_CLOSE == status then 
      self:_onEventMessageHandler(self.e.CONNECT_SERVER_CLOSE, deltime)

    elseif CLIENT_HOST_PORT_ERROR == status then 
       self:_onEventMessageHandler(self.e.CLIENT_HOST_PORT_ERROR, deltime)

    elseif CREATE_SOCKET_FAIL == status then
       self:_onEventMessageHandler(self.e.CREATE_SOCKET_FAIL, deltime)

    elseif CONNECT_SUCCESS == status then

       self:_onEventMessageHandler(self.e.CONNECT_SUCCESS, deltime)

    elseif RECV_MESSAGE_SUCCESS == status then ----------------------------------net package beg
        local probuf = self:_DecodeProto('protocol.S2C', buffer)
        if probuf and probuf.head and probuf.head.opcode then

            local opcmd = probuf.head.opcode

            if self:_GetOpCMD('protocol.opcode', "RESP_ERROR_MSG") == opcmd then --

                -- print("==_handlerSocketPackage===RESP_ERROR_MSG======beg")
                if probuf.body and probuf.body.errorMsgResp and probuf.body.errorMsgResp.errorMsg then
                    display.showErrorMessage(probuf.body.errorMsgResp.errorMsg)
                end
                -- print("===_handlerSocketPackage==RESP_ERROR_MSG======end")

            -- elseif gns.network:GetOpCMD('protocol.opcode', "RESP_AUTH_FAILD") == opcmd then --gns.network:GetOpCMD('protocol.S2COpcode', "RESP_AUTH_FAILD") == probuf.head.opcode
            --     print("==_handlerSocketPackage===RESP_AUTH_FAILD====")
                
            elseif self._tbHandler[opcmd] ~= nil then
                self._tbHandler[opcmd](probuf)
            else
                -- print("==========netsocket not add Handler ===========beg===: "..probuf.head.opcode)
                dump(probuf)
                -- print("=======netsocket not add Handler ===========beg===")
            end
        else
            -- print("=========NETCHAT===========DecodeProto error=====================")
        end
        self:_onEventMessageHandler(self.e.SEND_MESSAGE_SUCCESS, deltime)
    end
        
end

function NetChat:addLocalMessage(luaHandler)
    if not luaHandler then return end

    self._tbEventLuaHandler = luaHandler
end

function NetChat:_onEventMessageHandler(strEvent, deltime)
    if self._tbEventLuaHandler then
        self._tbEventLuaHandler(strEvent, deltime)
    end
end

function NetChat:_GetOpCMD(protoname, keyname)
    return self.protobuf.enum_id(protoname, keyname)
end

-- protobuffer加密
function NetChat:_DecodeProto(protoname, packet)
    return self.protobuf.decode(protoname, packet)
end

function NetChat:_EndcodeProto(protoname, propTable)
    local buffer = self.protobuf.encode(protoname, propTable)
    return buffer
end

return NetChat