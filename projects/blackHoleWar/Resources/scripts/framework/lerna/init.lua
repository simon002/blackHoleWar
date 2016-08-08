----------------------------------------
-- Common lua library by zrong.
--
-- Creation 2015-02-09
-- Modifiction 2015-12-04 Modify it for Lerna
----------------------------------------

print("===========================================================")
print("              LOAD LERNA FRAMEWORK")

local CURRENT_MODULE_NAME = ...

lerna = lerna or {}
lerna.PACKAGE_NAME = string.sub(CURRENT_MODULE_NAME, 1, -6)

-- function 依赖 log ，因此需要提前载入。
-- load utils library
lerna.utils = import(".utils.init")
-- load log library
lerna.log = import(".log.init")

-- functions 中对 dump 的重载依赖 debug
require(lerna.PACKAGE_NAME .. ".debug")
require(lerna.PACKAGE_NAME .. ".functions")



-- As same as cc.ui.init.makeUIControl_
-- but remove EventProtocol:exportMethods
function makeUIControlWithoutEvent(control)
    cc(control)
    control:addComponent("components.ui.LayoutProtocol"):exportMethods()

    control:setCascadeOpacityEnabled(true)
    control:setCascadeColorEnabled(true)
end

--- only export EventProtocol to view
function makeEventDispatcher(view)
    cc(view)
    view:addComponent("components.behavior.EventProtocol"):exportMethods()
    if view.addNodeEventListener then
        view:addNodeEventListener(cc.NODE_EVENT, function(event)
            if event.name == "cleanup" then
                view:removeAllEventListeners()
            end
        end)
    end
end

lerna.FileUtil            = import('.FileUtil')
lerna.SharedObject        = import('.SharedObject')
lerna.ResourceManager     = import('.ResourceManager')
lerna.ResourceCache       = import('.ResourceCache')
lerna.UIProgressBar       = import('.UIProgressBar')
-- 2016-2-19 paili  Lerna 暂时不支持Webview
-- lerna.WebView             = import('.WebView')
lerna.Network             = import('.Network')
lerna.Shop                = import('.Shop')

-- 2015-12-10 zrong  禁用 Lerna 不支持的实现
-- Lerna 下的许多组件是从 zrong 的 cocos2d-x 3.3 修改版移植过来
-- 在 Lerna 中并不能使用
-- Lerna 还不需要 Dragonbones
-- 其中的 C++ 源码位于项目源码库中，而非引擎源码库中
-- 因此，这个 dragonbones 封装在 Lerna 中不能使用
-- lerna.dragonbones         = import('.dragonbones')

-- 依赖 cocos2d-x 3.x 不能使用
-- lerna.CaptureScreenUtil   = import('.CaptureScreenUtil')

-- 依赖Dragonbones for cocos2d-x 3.3 ，Lerna 中不能使用
-- import(".DBCCArmatureNodeEx")

-- 依赖 zrong 的 cocos2d-x-filter 库，暂时不能使用
-- 在 Quick 中已经包含了 cocos2d-x-filter 实现
-- import(".FilterSpriteEx")

print("                    DONE")
print("===========================================================")
