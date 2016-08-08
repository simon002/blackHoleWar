------------------------------------------
-- function.lua for Lerna
-- 2015-12-11 added by zrong 
------------------------------------------

os.gettime = (pcall(require, 'socket') and socket.gettime) or os.time

--------------------------------
-- 处理 log 文件，定义调试输出
--
local starttime = os.gettime()
local logFilePath = nil
local logFileHandler = nil
local writeToLog = nil
local flog = nil
local echo = print
local olddump = dump
log = nil

function initlog(level, filePath)
	if filePath then
		logFilePath = filePath
	end
	if logFilePath and DEBUG_LOG then
		logFileHandler = io.open(logFilePath, 'w+b')
		-- 定义写入 log 到文件的方法
		writeToLog = function(args)
			local strlist = {string.format('[%.4f]', os.gettime() - starttime)}
			for i=1, #args do
				strlist[#strlist+1] = tostring(args[i])
			end
			strlist[#strlist+1] = '\n'
			logfileHandler:write(table.concat(strlist, ''))
			logfileHandler:flush()
		end
	end
	if logFileHandler then
		flog = lerna.log.FileHandler.new(logFileHandler, nil, true, starttime, os.gettime)
	elseif logFilePath then
		flog = lerna.log.FileHandler.new(logFilePath, 'w+b', true, starttime, os.gettime)
	end
	log = lerna.log.Logger.new(level,
		lerna.log.PrintHandler.new(echo),
		flog)
end

function print(...)
	if DEBUG > 0 then
		echo(...)
		-- 将标准的 print 信息写入 log 文件
		if writeToLog then
			writeToLog({...})
		end
	end
end

function dump(value, nesting, behavior)
	if DEBUG > 0 then
		return olddump(value, nesting, behavior)
	end
end

function d(fmt, ...)
	if log then
		log:debug(fmt, ...)
	else
		printf(fmt, ...)
	end
end
--------------------------------

-- start --

--------------------------------
-- 根据系统时间初始化随机数种子，让后续的 math.random() 返回更随机的值
-- @function [parent=#math] newrandomseed

-- end --

function math.newrandomseed()
	-- 2015-02-06 zrong os.gettime 定义见本文件，覆盖原有 function 中的内容
	math.randomseed(os.gettime())
    math.random()
    math.random()
    math.random()
    math.random()
end

-- start --

--------------------------------
-- 对数值进行四舍五入，如果不是数值则返回 0
-- @function [parent=#math] round
-- @param number value 输入值
-- @return number#number 

-- end --

function math.round(value)
    value = checknumber(value)
    return math.floor(value + 0.5)
end

-- start --

--------------------------------
-- 遍历表格，确保其中的值唯一
-- @function [parent=#table] unique
-- @param table t 表格
-- @param boolean bArray t是否是数组,是数组,t中重复的项被移除后,后续的项会前移
-- @return table#table  包含所有唯一值的新表格

--[[--

遍历表格，确保其中的值唯一

~~~ lua

local t = {"a", "a", "b", "c"} -- 重复的 a 会被过滤掉
local n = table.unique(t)

for k, v in pairs(n) do
    print(v)
end

-- 输出
-- a
-- b
-- c

~~~

]]

-- end --

function table.unique(t, bArray)
    local check = {}
    local n = {}
    local idx = 1
    for k, v in pairs(t) do
        if not check[v] then
            if bArray then
                n[idx] = v
                idx = idx + 1
            else
                n[k] = v
            end
            check[v] = true
        end
    end
    return n
end

-- 从字符串右边开始搜索
-- @author zrong(zengrong.net) 2015-02-06
-- @param 同 string.find
-- @param 同 string.find
-- @param 0 代表从最后一个字符开始搜索，-1 代表从倒数第二个字符开始搜索。大于 0 的值都会被认为是 0。
-- @param 同 string.find
function string.rfind(s, pattern, init, plain)
	local len, pos = #s, 0
	if not init or init > 0 then init = 0 end
	init = len + init
	local rsi, rei = nil, nil
	for si, ei in function()
			return string.find(s, pattern, pos, plain)
		end 
	do
		if ei > init then
			break
		end
		rsi = si
		rei = ei
		pos = ei + 1
	end
	return rsi, rei
end
