local menu=require('openmw.menu')
local core = require('openmw.core')
local Saves={}
local SaveChecked=0




local function AskSaves(data)
		for j, saves in pairs(menu.getAllSaves()) do
			for k, save in pairs(saves) do
				SaveChecked=SaveChecked+1
				if SaveChecked==11 then
					core.sendGlobalEvent('ReceiveSaves',{saves=Saves})
					SaveChecked=0
					--break
				else
					Saves[SaveChecked]={}
					Saves[SaveChecked]["directory"]=j
					Saves[SaveChecked]["slotName"]=k
					Saves[SaveChecked]["description"]=save.description
					print(Saves[SaveChecked]["description"])
				end
			end
		end
		if SaveChecked<10 then
			for i=(SaveChecked+1),10 do
				Saves[i]={}
				Saves[i]["description"]="No Data"
				print(Saves[i]["description"])
				if i==10 then
					print(Saves[11])
					core.sendGlobalEvent('ReceiveSaves',{saves=Saves})
					SaveChecked=0
					break
				end
			end
		end
end

local function Save(data)
	menu.saveGame(data.value,data.value)
end

local function Load()

end

local function deleteSave(data)
	menu.deleteGame(data.directory, data.slotName)
end


return {
	eventHandlers = {AskSaves=AskSaves, Save=Save, Load=Load, deleteSave=deleteSave},

}


