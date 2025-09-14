local ui=require('openmw.ui')
local core=require('openmw.core')
local self=require('openmw.self')

local function ShowMessage(data)
    ui.showMessage(data.text)
end

local function PlaySound(data)
	core.sound.playSound3d(data.Sound,self)
end

return {
	eventHandlers = {	
						BACOSShowMessage=ShowMessage,
						BACOSPlaySound=PlaySound,
					},
	engineHandlers = {
        onUpdate = onUpdate,
	}

}