local world = require('openmw.world')
local types = require('openmw.types')
local interfaces = require('openmw.interfaces')
local players = world.players


local function CreateWritting(data)
	local booknbr=1
	local pagejump="<BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR><BR> "
	print(data.Title)
	world.createObject(world.createRecord(types.Book.createRecordDraft({name=data.Title,isScroll=data.scroll,model=types.Book.record(data.Book).model,text=tostring(data.Text)..pagejump..pagejump..pagejump..pagejump,weight=0.2,value=5,icon=types.Book.record(data.Book).icon})).id,1):moveInto(types.Actor.inventory(data.actor))
	data.Book:remove()

end


return {
	eventHandlers = {CreateWritting=CreateWritting},
	engineHandlers = {
        onUpdate = function()

		end

	},
}