local self=require('openmw.self')
local core=require('openmw.core')
local types=require('openmw.types')



local function onActivated(data)
	
	local pagejump="<BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR> "

	if self.type==types.Book and (types.Book.record(self).name=="Blank Book" or types.Book.record(self).name=="Blank Scroll" or string.find(types.Book.record(self).text,pagejump)) then
		data:sendEvent("Write",{Book=self})
	end



end



return {
	engineHandlers = { onActivated=onActivated}
}