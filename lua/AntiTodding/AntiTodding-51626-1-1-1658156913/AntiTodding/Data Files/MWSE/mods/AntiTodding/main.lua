local Lines = 0		local Errors = 0	local Last		local dir = string.lower(tes3.installDirectory .. "\\mwse.log")

local function loaded(e)
	timer.start{type = timer.real, iterations = -1, duration = 1, callback = function()		local Cur = lfs.attributes(dir, "size")
		if Cur ~= Last then Last = Cur
			local num = 0	local mode = false		local t = {}
			for line in io.lines("mwse.log") do num = num + 1
				if num > Lines then
					if not mode then mode = string.find(line, "rror ") end		--string.startswith(line, "Error ") end
					if mode then
						local f, last = string.find(line, [[mods\]])
						if last then
							t[#t+1] = line:sub(last+1)
							Errors = Errors + 1
							mode = false
						end
					end
				end
			end
			Lines = num
			
			if #t > 0 then
				tes3.messageBox("%s  (%s)", table.concat(t, "\n"), Errors)
			end
		end
	end}
end		event.register("loaded", loaded)



local function initialized(e)
	for line in io.lines("mwse.log") do Lines = Lines + 1 end
	Last = lfs.attributes(dir, "size")
end		event.register("initialized", initialized)

--[[
local filewatcher = require("filewatcher")

local file = string.lower(tes3.installDirectory .. "\\mwse.log")
filewatcher.registerWatcher(file)

local logModified = false
local function onFileModified(e)
    logModified = true
end
event.register("fileWatcher:fileModified", onFileModified, { filter = file })

event.register("loaded", function()
    timer.start({
        iterations = -1,
        duration = 1.0,
        callback = function()
            if logModified then
                tes3.messageBox("LOG WAS UPDATED!")
                logModified = false
            end
        end
    })
end)


local lastUpdate = os.clock()
local function onFileModified(e)
    if (os.clock() - lastUpdate) >= 1.0 then
        lastUpdate = os.clock()
        doSomething()
    end
end

--]]