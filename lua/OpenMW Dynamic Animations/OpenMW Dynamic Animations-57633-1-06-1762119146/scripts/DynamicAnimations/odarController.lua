local anim = require("openmw.animation")
local self = require("openmw.self")
local I = require("openmw.interfaces")
local async = require("openmw.async")
--	local aux_util = require("openmw_aux.util")
local core = require("openmw.core")

local logLevel = 0			local logSpam = false
local disabled = false
local playBlendedHandlers = {}

local function onPlayBlendedAnimation(groupname, options)    
    for i = #playBlendedHandlers, 1, -1 do
        local h = playBlendedHandlers[i].fn(groupname, options)
        if type(options.newGroupName) == "string" then
            groupname = options.newGroupName
            options.newGroupName = nil
        end
        if h == false then
            return groupname
        end
    end
    return groupname
end

local spamNames = { ["torch"] = true, ["idle1h"] = true, ["idle2c"] = true, ["idlehh"] = true }

local function playBlendedAnimation(groupname, options)
    if disabled then		return		end
    if logLevel > 1 then
        if not spamNames[groupname] then
            print(groupname, options.priority, options.blendMask)
        else
            if not logSpam then
                logSpam = true
                print(groupname, options.priority, options.blendMask)
            end
	end
    end
    local swap = onPlayBlendedAnimation(groupname, options)

    -- if logLevel > 1 then print(aux_util.deepToString(options)) end
    if options.skip then
        return
    end

    if swap ~= groupname then
        anim.playBlended(self, swap, options)
        options.skip = true
        return false
    end

end

I.AnimationController.addPlayBlendedAnimationHandler(playBlendedAnimation)


local handlers = { onUpdate = {n=0}, onInit = {}, onActive = {}, onSecond = {}, AIChange = {} }
handlers.scripts = {
	rebootAI = function()
		local p = I.AI.getActivePackage()
		if p and p.type == "Wander" and anim.getActiveGroup(self, 0) == "idle" then
			I.AI.startPackage(p)
		end
	end
}
handlers.events = {
	odarEnabled = {},
	rebootAI = { handlers.scripts.rebootAI }
}
handlers.run = function(h, e)
	for i = #h, 1, -1 do	h[i](e)		end
end
local updateHandlers = handlers.onUpdate
local odarScripts = {}

local AI = {}
handlers.updateAI = function()
	local p = I.AI.getActivePackage() or {}
	if (p and p.type) ~= AI.type then
		p = p or {}
		AI = { type=p.type, distance=p.distance }
		handlers.run(handlers.AIChange, AI)
	end
end
handlers.events.updateAI = { handlers.updateAI }

handlers.updateTimer = function()
	async:newUnsavableSimulationTimer(1, handlers.updateTimer)
--	print(core.getSimulationTime())
	logSpam = false
	handlers.updateAI()
	handlers.run(handlers.onSecond)
	if disabled then
		handlers.run(updateHandlers, 0.05)
	end
end
async:newUnsavableSimulationTimer(math.random(20) / 20, handlers.updateTimer)

local function onUpdate(dt)
	if dt <= 0 or disabled then		return		end
	for i = updateHandlers.n, 1, -1 do
		updateHandlers[i](dt)
	end
end

-- print("ODAR RELOADING")

return {
    engineHandlers = { 
        onUpdate = onUpdate,
        onActive = function()		handlers.run(handlers.onActive)		end
--	onLoad = function() print("ODAR ONLOAD")		end
    },
    eventHandlers = {
        odarEnabled = function(e)
            disabled = not e
            handlers.run(handlers.events.odarEnabled, e)
	end,
        odarAddScript = function(e)
            for _, file in ipairs(e) do
                for _, v in ipairs(odarScripts) do
                    if v.path == file:lower() then return end
                end
              --  print("reg", file)
                local m = require(file)
                local script = {}
                script.path = file:lower()		script.func = m
                odarScripts[#odarScripts+1] = script
                if m and m.engineHandlers then
                    for k, v in pairs(m.engineHandlers) do
                        local h = handlers[k]
                        if h then
                            h[#h + 1] = v
                            if h.n then h.n = #h		end
                            if k == "onInit" and e.initData then v(e.initData)		end
                        end
                    end
                end
                if m and m.eventHandlers then
                    for k, v in pairs(m.eventHandlers) do
                        -- print(k)
                        local h = handlers.events[k]
                        if not h then
                            h = {}		handlers.events[k] = h
                        end
                        h[#h + 1] = v
                    end
                end
                if m and m.interface then
                    local i = {}		handlers.scripts[m.interfaceName] = i
                    for k, v in pairs(m.interface) do
                       -- print(k)
                        i[k] = v
                    end
                end
            end
        end,
        odarEvent = function(e)
            if e.event and handlers.events[e.event] then
		handlers.run(handlers.events[e.event], e)
            end
        end,
	initNPCdiag = function()
		handlers.run(handlers.events.odarEnabled, false)
	end,
	closeNPCdiag = function()
		handlers.run(handlers.events.odarEnabled, not disabled)
	end
    },

    interfaceName = "ODAR",
    interface = {
        version = 100,
        playBlendedAnimation = function(g, o)
                playBlendedAnimation(g, o)
		if not o.skip then
			anim.playBlended(self, g, o)
		end
            end,

        addPlayBlendedAnimationHandler = function(handler, name)
            if type(name) ~= "string" then name = tostring(#playBlendedHandlers + 1) end
            playBlendedHandlers[#playBlendedHandlers + 1] = {id=name, fn=handler}
            if logLevel > 0 then
                print("ODAR handler "..name.." registered.")
            end
        end,

        addHandler = function(e, fn)
            local h = handlers[e]
            if not h or not fn then		return		end
            h[#h + 1] = fn
            if h.n then h.n = #h		end
        end,
	getAIStatus = function()		return AI	end,

	rebootAI = handlers.scripts.rebootAI,
	logLevel = function(e)
			logLevel = type(e) == "number" and e or logLevel
			print("Logging level "..logLevel)
	end,
        enabled = function(e)
            disabled = not e
            handlers.run(handlers.events.odarEnabled, e)
	end,
--[[
	scripts = handlers.scripts,
	events = handlers.events,
	handlers = handlers,
	list = function() print(#playBlendedHandlers, #odarScripts)		end,
--]]
    }
}
