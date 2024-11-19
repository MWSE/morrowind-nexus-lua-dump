local self = require('openmw.self')
local nearby = require('openmw.nearby')
local input = require('openmw.input')
local ui = require('openmw.ui')
local util = require('openmw.util')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local core = require('openmw.core')
local ambient = require('openmw.ambient')


local func_table={}

local ToggleUseButton = false
local MenuSelectStop = true
local SavingSelection=1
local SavingDescription=""
local Saving=false
local SavingLetter=4
local Timer=0



func_table.RunningUI=function(MoveForward,MoveBackward,TurnLeft,TurnRight,Colors,Saves,SavingMenuUI, MapUI, RoomsVisited, Maps,Cross)


	if SavingMenuUI and SavingMenuUI.layout then
		

		if MoveForward(-0.2) == "Up" and MenuSelectStop == false and SavingSelection>1 and Saving==false then
			MenuSelectStop = true
			SavingMenuUI.layout.content[2].content[SavingSelection*2-1].props.visible=false	
			SavingSelection=SavingSelection-1
			SavingMenuUI.layout.content[2].content[SavingSelection*2-1].props.visible=true
			SavingMenuUI:update()
			ambient.playSound("Cursor")
		elseif MoveBackward(0.2) == "Down" and MenuSelectStop == false and SavingSelection<10 and Saving==false then
			MenuSelectStop = true
			SavingMenuUI.layout.content[2].content[SavingSelection*2-1].props.visible=false
			SavingSelection=SavingSelection+1
			SavingMenuUI.layout.content[2].content[SavingSelection*2-1].props.visible=true
			SavingMenuUI:update()
			ambient.playSound("Cursor")
		end

		
		if Cross == true and ToggleUseButton == true and Saving==false then
			for i, save in pairs(Saves) do print(save) end
			print(Saves[11])
			ToggleUseButton=false
			ambient.playSound("REdecide")
			Saving=true
			Timer=core.getRealTime()
			Saves[11]=Saves[11]+1
			SavingMenuUI.layout.content[1].content[SavingSelection].props.text=SavingMenuUI.layout.content[1].content[SavingSelection].props.text:sub(1,5)
			SavingDescription=SavingSelection.." . "..types.NPC.record(self).race.."  /"..(Saves[11]).."/ "..self.cell.name
--			SavingMenuUI.layout.content[1].content[SavingSelection].props.visible=true--------------------------------------	
--			SavingMenuUI.layout.content[2].content[SavingSelection*2-1].props.visible=false---------------------------------

--			SavingDescription="       October 1st. Daylight...."-------------------------------------------------------------------
--			SavingDescription="       The monsters have overtaken the city."-------------------------------------------------------------------
--			SavingDescription="       Somehow, i'm still alive."-------------------------------------------------------------------
--			SavingDescription="       For three days I have been hiding here."-------------------------------------------------------------------
--			SavingDescription="       I can't stay anymore....."-------------------------------------------------------------------
			SavingMenuUI:update()
			--core.sendGlobalEvent('RemoveItem', { Item = types.Actor.inventory(self):find("ink ribbon"), number = 1 })
			if Saves[SavingSelection]["description"]~="No Data" then
				types.Player.sendMenuEvent(self, 'deleteSave', {directory=Saves[SavingSelection]["directory"],slotName=Saves[SavingSelection]["slotName"]})
			end
			types.Player.sendMenuEvent(self, 'Save', {value=types.NPC.record(self).race.."  /"..(Saves[11]).."/ "..self.cell.name,savenum=(Saves[11])})
			core.sendGlobalEvent("ReceiveSaveNum",{ savenum=Saves[11]})

		end

		if Saving ==true then
			if SavingLetter<=7 then
				I.UI.setMode(I.UI.MODE.Interface, { windows = {} })
			end
			if (core.getRealTime()-Timer)>0.3 then
				SavingLetter=SavingLetter+1
				Timer=core.getRealTime()
				if SavingDescription:sub(SavingLetter,SavingLetter)~="" then
					SavingMenuUI.layout.content[1].content[SavingSelection].props.text=SavingMenuUI.layout.content[1].content[SavingSelection].props.text..SavingDescription:sub(SavingLetter,SavingLetter)
					SavingMenuUI:update()
					if SavingDescription:sub(SavingLetter,SavingLetter)==" " then 
						ambient.playSound("TypewriterSpace")
					else
						ambient.playSound("Typewriter")
					end
				else
					I.UI.removeMode(I.UI.MODE.Interface)
					SavingMenuUI:destroy()
					Saving =false
					ambient.playSound("RECancel")
					SavingLetter=4
				end
			end


		end

	elseif SavingSelection~=1 or Saving then
		SavingSelection=1
		Saving=false
	end




	if I.UI.getMode() then
		if MoveBackward(0.2) == false and MoveForward(-0.2) == false and TurnLeft(-0.2) == false and TurnRight(0.2) == false and MenuSelectStop == true then
			MenuSelectStop = false
		end
		if ToggleUseButton == false and Cross == false then
			ToggleUseButton = true
		end
	elseif ToggleUseButton==true and I.UI.getMode()==nil then
		ToggleUseButton = false
	end

end



return func_table
