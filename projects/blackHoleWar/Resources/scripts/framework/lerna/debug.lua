------------------------------------------
-- debug.lua for Lerna
-- 2015-12-11 added by zrong 
------------------------------------------

--[[--

输出值的内容

### 用法示例

~~~ lua

local t = {comp = "chukong", engine = "quick"}

dump(t)

~~~

@param mixed value 要输出的值

@parma [integer nesting] 输出时的嵌套层级，默认为 3

@param [string behavior] 值为 'string' 则返回 string，为 'table' 则返回包含 dump 内容的 table，为 'print' 则打印 string
]]
function dump(value, nesting, behavior)
    if type(nesting) ~= "number" then nesting = 3 end
    if not behavior then behavior = 'print' end

    local lookupTable = {}
    local result = {}

    local function _v(v)
        if type(v) == "string" then
            v = "\"" .. v .. "\""
        end
        return tostring(v)
    end

    if behavior == 'print' then
        local traceback = string.split(debug.traceback("", 2), "\n")
        print("dump from: " .. string.trim(traceback[4]))
    end

    local function _dump(value, desciption, indent, nest, keylen)
        local spc = ""
        if nest > 1 then spc = ',' end
        --[[
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(_v(desciption)))
        end
        --]]
        if type(value) ~= "table" then
            if type(desciption) == 'string' then
                if nest <= nesting then
                    result[#result +1] = string.format("%s[\"%s\"] = %s%s", indent, desciption, _v(value), spc)
                elseif nest - nesting == 1 then
                    result[#result+1] = string.format("%s[\"%s\"] = \"*MAX NESTING*\",", indent, desciption)
                end
            else
                if nest <= nesting then
                    result[#result +1] = string.format("%s%s%s", indent, _v(value), spc)
                end
            end
        elseif not lookupTable[value] then
            lookupTable[value] = true

            if type(desciption) == 'string' then
                if nest <= nesting then
                    result[#result+1] = string.format("%s[\"%s\"] = {", indent, desciption)
                else
                    result[#result+1] = string.format("%s[\"%s\"] = \"*MAX NESTING*\",", indent, desciption)
                end
            else
                if nest <= nesting then
                    result[#result+1] = string.format("%s{", indent)
                end
            end
            local indent2 = indent.."    "
            local keys = {}
            local keylen = 0
            local values = {}
            for k, v in pairs(value) do
                keys[#keys + 1] = k
                local vk = _v(k)
                local vkl = string.len(vk)
                if vkl > keylen then keylen = vkl end
                values[k] = v
            end
            table.sort(keys, function(a, b)
                if type(a) == "number" and type(b) == "number" then
                    return a < b
                else
                    return tostring(a) < tostring(b)
                end
            end)
            for i, k in ipairs(keys) do
                _dump(values[k], k, indent2, nest + 1, keylen)
            end
            if nest <= nesting then
                result[#result+1] = string.format("%s}%s", indent, spc)
            end
        end
    end
    _dump(value, nil, "", 1)

    if behavior == 'table' then
        return result
    elseif behavior == 'string' then
        return table.concat(result, '\n')
    elseif behavior == 'print' then
        for i, line in ipairs(result) do
            print(line)
        end
    end
end
