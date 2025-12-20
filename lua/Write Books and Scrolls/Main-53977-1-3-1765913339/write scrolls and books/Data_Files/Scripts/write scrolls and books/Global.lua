local world = require('openmw.world')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local players = world.players

local WriteKeys={}

local function ApplyWriteKey(data)
	WriteKeys[data.Actor.id]=data.Bolean
end



I.ItemUsage.addHandlerForType(types.Book, function(book, actor)
    if WriteKeys[actor.id]==true then
		actor:sendEvent("Write",{Book=book})
        return false
    end
end)


local function CreateWritting(data)
--	print(data.Book)
--	print(data.Title)
--	print(data.Text)
	world.createObject(world.createRecord(types.Book.createRecordDraft({name=data.Title,
																		isScroll=types.Book.records[data.Book.recordId].isScroll,
																		model=types.Book.records[data.Book.recordId].model,
																		text=tostring(data.Text).."<BR>",
																		weight=types.Book.records[data.Book.recordId].weight,
																		value=5,
																		icon=types.Book.records[data.Book.recordId].icon}
																	)).id,1):moveInto(types.Actor.inventory(data.actor))
	data.Book:remove()

end




return {
	eventHandlers = {CreateWritting=CreateWritting,
					ApplyWriteKey=ApplyWriteKey},
	engineHandlers = {

	},
}