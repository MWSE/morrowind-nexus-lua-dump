local self=require('openmw.self')
local core=require('openmw.core')
local types=require('openmw.types')



local function onActivated(data)
	
	if self.type.record(self).id=="arcadecabinet0" then
		data:sendEvent("ArcadeCabinet",{Game=0})
	elseif self.type.record(self).id=="arcadecabinet1" then
		data:sendEvent("ArcadeCabinet",{Game=1})
	elseif self.type.record(self).id=="arcadecabinet2" then
		data:sendEvent("ArcadeCabinet",{Game=2})
	end



end



return {
	engineHandlers = { onActivated=onActivated}
}