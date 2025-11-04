local ui=require('openmw.ui')
local core=require('openmw.core')
local self=require('openmw.self')
local storage = require('openmw.storage')
local nearby = require('openmw.nearby')

local function ShowMessage(data)
    ui.showMessage(data.text)
end

local function PlaySound(data)
	core.sound.playSound3d(data.Sound,self)
end


local onStrikeOnly=false
local function onUpdate(dt)
	if dt>0 then
		if onStrikeOnly~=storage.playerSection('BACOSGeneralSettings'):get('OnlyOnstrike') then
			onStrikeOnly=storage.playerSection('BACOSGeneralSettings'):get('OnlyOnstrike')
		end
		for i,actor in pairs(nearby.actors) do
			actor:sendEvent("BACOSDeclareType",{onStrikeOnly=onStrikeOnly})
		end
	end
end


local function BACOSDeclareTypeAsked(data)
	data.Actor:sendEvent("BACOSDeclareType",{onStrikeOnly=onStrikeOnly})
end
	
return {
	eventHandlers = {	
						BACOSPlaySound=PlaySound,
						BACOSDeclareTypeAsked=BACOSDeclareTypeAsked,
					},
	engineHandlers = {
        onUpdate = onUpdate,
	}

}