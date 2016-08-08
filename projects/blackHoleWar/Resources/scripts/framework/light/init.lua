----------------------------------------
-- Common lua library by xuli.
-- it for light
-- Creation 2016-4-20
----------------------------------------

print("===========================================================")
print("              light init")
local CURRENT_MODULE_NAME = ...

print('path = '..CURRENT_MODULE_NAME)

light = light or {}
light.PACKAGE_NAME = string.sub(CURRENT_MODULE_NAME, 1, -6)


light.NetChat             = import('.NetChat')


print("                    DONE")
print("===========================================================")
