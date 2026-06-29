local types = require('openmw.types')
local I = require('openmw.interfaces')
local anim = require('openmw.animation')
local self = require('openmw.self')
local core = require('openmw.core')
local async = require('openmw.async')
local nearby = require('openmw.nearby')
local util = require('openmw.util')
local time = require('openmw_aux.time')
local input = require('openmw.input')

local Cell


input.registerTriggerHandler(input.triggers["Activate"].key, async:callback(function ()
	core.sendGlobalEvent("DisableFakeWater")
end))  


local function onUpdate(dt)
    if dt>0 then
        if self.cell~=Cell then
            Cell=self.cell
            core.sendGlobalEvent("NewCell",{Actor=self})
        end
    end
end

return {


	eventHandlers = {   	},
	engineHandlers = {  onUpdate=onUpdate,
    
		
	}

}