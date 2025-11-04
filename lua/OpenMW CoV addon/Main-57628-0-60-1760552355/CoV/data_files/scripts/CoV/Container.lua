local self=require('openmw.self')
local AI=require('openmw.interfaces').AI
local I = require('openmw.interfaces')
local anim = require('openmw.animation')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local core = require('openmw.core')
local util = require('openmw.util')
local time=require('openmw_aux.time')
local Combat=require('openmw.interfaces').Combat


local function onActivated(actor)
--	I.AnimationController.playBlendedAnimation('ContainerOpen',{priority=anim.PRIORITY.Scripted})
	anim.playBlended(self,"containeropen",{priority=anim.PRIORITY.Scripted})
	core.sendGlobalEvent("CoVEmptyInventory",{Object=self})
end


return {
	eventHandlers = {	
						Died=Died,
					},
	engineHandlers = {
						onUpdate=onUpdate,
						onActivated=onActivated

	}

}