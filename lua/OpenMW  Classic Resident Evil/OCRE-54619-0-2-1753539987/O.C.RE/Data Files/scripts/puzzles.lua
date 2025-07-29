local types = require('openmw.types')
local ambient = require('openmw.ambient')
local core = require('openmw.core')
local self = require('openmw.self')
local util = require('openmw.util')
local ui = require('openmw.ui')
local I = require('openmw.interfaces')

local func_table={}

local ToggleUseButton = false
local MenuSelectStop = true
local SavingSelection=1
local SavingDescription=""
local Saving=false
local SavingLetter=4
local Timer=0






--[[

func_table.RunningPuzzles=function(DeltaT,MoveForward,MoveBackward,TurnLeft,TurnRight,Colors,ElectricalPanelPuzzleUI,MenuSelection,Lockpicking,Cross,CrowbarPuzzleUI,ButtonToggle,Toggle)

	
	if CrowbarPuzzleUI.UI and CrowbarPuzzleUI.UI.layout then
		if CrowbarPuzzleUI.UI.layout.content[1].props.relativePosition.x>0.96 then
			CrowbarPuzzleUI.Way=-1
		elseif CrowbarPuzzleUI.UI.layout.content[1].props.relativePosition.x<0.04 then
			CrowbarPuzzleUI.Way=1		
		end
		CrowbarPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(CrowbarPuzzleUI.UI.layout.content[1].props.relativePosition.x+DeltaT*CrowbarPuzzleUI.Way*CrowbarPuzzleUI.Speed,CrowbarPuzzleUI.UI.layout.content[1].props.relativePosition.y)
		
		if CrowbarPuzzleUI.UI.layout.content[1].props.color~=Colors.White and (core.getRealTime()-CrowbarPuzzleUI.timer)>0.1 then
			CrowbarPuzzleUI.UI.layout.content[1].props.color=Colors.White
		end


		if (core.getRealTime()-CrowbarPuzzleUI.timer)>0 and (core.getRealTime()-CrowbarPuzzleUI.timer)<0.05 then
			CrowbarPuzzleUI.UI.layout.props.relativePosition=CrowbarPuzzleUI.UI.layout.props.relativePosition+util.vector2(0,0.01)
		elseif CrowbarPuzzleUI.UI.layout.props.relativePosition.y>0.75 then
			CrowbarPuzzleUI.UI.layout.props.relativePosition=CrowbarPuzzleUI.UI.layout.props.relativePosition+util.vector2(0,-0.01)
		end


		if Cross==true and ToggleUseButton == true  then
			ToggleUseButton = false 
			if CrowbarPuzzleUI.UI.layout.content[1].props.relativePosition.x>0.45 and CrowbarPuzzleUI.UI.layout.content[1].props.relativePosition.x<0.55 then
				ambient.playSound("WoodBreak")
				if CrowbarPuzzleUI.Speed>=0.5+(CrowbarPuzzleUI.value-1)*0.2 then
					core.sendGlobalEvent("ReturnLocalScriptVariable",
						{ value = 11, Player = self, Variable = "crowbarvalue",GameObject=CrowbarPuzzleUI.Object })
					CrowbarPuzzleUI.UI:destroy()
					I.UI.removeMode(I.UI.MODE.Interface)
				else 
					CrowbarPuzzleUI.Speed=CrowbarPuzzleUI.Speed+0.2
					CrowbarPuzzleUI.UI.layout.content[1].props.color=Colors.Blue
					CrowbarPuzzleUI.timer=core.getRealTime()
				end
			else
				if CrowbarPuzzleUI.Speed>0.5 then
					CrowbarPuzzleUI.Speed=CrowbarPuzzleUI.Speed-0.2
				end
				ambient.playSound("decidewrong")
				CrowbarPuzzleUI.UI.layout.content[1].props.color=Colors.Red
				CrowbarPuzzleUI.timer=core.getRealTime()
			end
		end
		CrowbarPuzzleUI.UI:update()

	end
	
	if ElectricalPanelPuzzleUI.UI and ElectricalPanelPuzzleUI.UI.layout then
		if ElectricalPanelPuzzleUI.States[1]==nil then
			ElectricalPanelPuzzleUI.States[1]=1
		end
		if MoveForward(-0.2) then
			if ElectricalPanelPuzzleUI.States[4] then
				ElectricalPanelPuzzleUI.States[4]=1
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(25/36, 12/28)
			elseif ElectricalPanelPuzzleUI.States[3] then
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(16/32, 12/28)
				ElectricalPanelPuzzleUI.States[3]=1
			elseif ElectricalPanelPuzzleUI.States[2] then
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(11/31, 12/28)
				ElectricalPanelPuzzleUI.States[2]=1
			elseif ElectricalPanelPuzzleUI.States[1] then
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(6/30, 12/28)
				ElectricalPanelPuzzleUI.States[1]=1
			end
			ElectricalPanelPuzzleUI.UI:update()
		elseif MoveBackward(0.2) then
			if ElectricalPanelPuzzleUI.States[4] then
				ElectricalPanelPuzzleUI.States[4]=-1
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(25/36, 15/31)
			elseif ElectricalPanelPuzzleUI.States[3] then
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(16/32, 15/31)
				ElectricalPanelPuzzleUI.States[3]=-1
			elseif ElectricalPanelPuzzleUI.States[2] then
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(11/31, 17/35)
				ElectricalPanelPuzzleUI.States[2]=-1
			elseif ElectricalPanelPuzzleUI.States[1] then
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(6/30, 17/35)
				ElectricalPanelPuzzleUI.States[1]=-1
			end
			ElectricalPanelPuzzleUI.UI:update()
		end
		
		if Cross == true and ToggleUseButton == true then
			ToggleUseButton =false
			
			if ElectricalPanelPuzzleUI.States[5] then
				core.sendGlobalEvent("ReturnLocalScriptVariable",
					{ value = tonumber(ElectricalPanelPuzzleUI.UI.layout.content[6].props.text), Player = self, Variable = "electricalpanelpuzzle",GameObject=ElectricalPanelPuzzleUI.Object })
				--ElectricalPanelPuzzleUI.UI:destroy()
				I.UI.removeMode(I.UI.MODE.Interface)
			end

			if ElectricalPanelPuzzleUI.States[4] then
				ElectricalPanelPuzzleUI.States[5]=1
				ambient.playSound("Button1")
				ElectricalPanelPuzzleUI.UI.layout.content[10].props.relativePosition=ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition
				if ElectricalPanelPuzzleUI.States[4]==1 then
					ElectricalPanelPuzzleUI.UI.layout.content[10].props.color=Colors.Red
				else
					ElectricalPanelPuzzleUI.UI.layout.content[10].props.color=Colors.Blue
				end
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.visible=false
				ElectricalPanelPuzzleUI.UI.layout.content[6].props.text=tostring(ElectricalPanelPuzzleUI.UI.layout.content[5].props.text+(ElectricalPanelPuzzleUI.States[4]*15*4))
			elseif ElectricalPanelPuzzleUI.States[3] then
				ElectricalPanelPuzzleUI.States[4]=1
				ambient.playSound("Button1")
				ElectricalPanelPuzzleUI.UI.layout.content[9].props.relativePosition=ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition
				if ElectricalPanelPuzzleUI.States[3]==1 then
					ElectricalPanelPuzzleUI.UI.layout.content[9].props.color=Colors.Red
				else
					ElectricalPanelPuzzleUI.UI.layout.content[9].props.color=Colors.Blue
				end
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(25/36, 12/28)
				ElectricalPanelPuzzleUI.UI.layout.content[5].props.text=tostring(ElectricalPanelPuzzleUI.UI.layout.content[4].props.text+(ElectricalPanelPuzzleUI.States[3]*5*3))
			elseif ElectricalPanelPuzzleUI.States[2] then
				ElectricalPanelPuzzleUI.States[3]=1
				ambient.playSound("Button1")
				ElectricalPanelPuzzleUI.UI.layout.content[8].props.relativePosition=ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition
				if ElectricalPanelPuzzleUI.States[2]==1 then
					ElectricalPanelPuzzleUI.UI.layout.content[8].props.color=Colors.Red
				else
					ElectricalPanelPuzzleUI.UI.layout.content[8].props.color=Colors.Blue
				end
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(16/32, 12/28)
				ElectricalPanelPuzzleUI.UI.layout.content[4].props.text=tostring(ElectricalPanelPuzzleUI.UI.layout.content[3].props.text+(ElectricalPanelPuzzleUI.States[2]*15*2))
			elseif ElectricalPanelPuzzleUI.States[1] then
				ElectricalPanelPuzzleUI.States[2]=1
				ambient.playSound("Button1")
				ElectricalPanelPuzzleUI.UI.layout.content[7].props.relativePosition=ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition
				if ElectricalPanelPuzzleUI.States[1]==1 then
					ElectricalPanelPuzzleUI.UI.layout.content[7].props.color=Colors.Red
				else
					ElectricalPanelPuzzleUI.UI.layout.content[7].props.color=Colors.Blue
				end
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(11/31, 12/28)
				ElectricalPanelPuzzleUI.UI.layout.content[3].props.text=tostring(ElectricalPanelPuzzleUI.UI.layout.content[2].props.text+(ElectricalPanelPuzzleUI.States[1]*5))
			end
			ElectricalPanelPuzzleUI.UI:update()
		end

	end


	if MenuSelection and MenuSelection.layout then
		if TurnRight(0.2) == "Right" and MenuSelectStop == false then
			MenuSelectStop = true
			for i, content in ipairs(MenuSelection.layout.content) do
				if type(i)=="number" then
					if i % 2 == 1 and MenuSelection.layout.content[i + 2] and content.props.visible == true then
						content.props.visible = false
						MenuSelection.layout.content[i + 2].props.visible = true
						MenuSelection:update()
						ambient.playSound("Cursor")
						break
					end
				end
			end
		elseif TurnLeft(-0.2) == "Left" and MenuSelectStop == false then
			MenuSelectStop = true
			for i, content in ipairs(MenuSelection.layout.content) do
				if type(i)=="number" then
					if i % 2 == 1 and i >= 3 and content.props.visible == true then
						content.props.visible = false
						MenuSelection.layout.content[i - 2].props.visible = true
						MenuSelection:update()
						ambient.playSound("Cursor")
						break
					end
				end
			end
		end
		if Cross == true and ToggleUseButton == true then
			ToggleUseButton=false
			for i, content in ipairs(MenuSelection.layout.content) do
				if i % 2 == 1 and content.props.visible == true then
					print(i)
					print(MenuSelection.layout.content[i+1].props.text)
					core.sendGlobalEvent("ReturnGlobalVariable",{value =1,Player = self,variable =MenuSelection.layout.content[i+1].props.text})
					ambient.playSound("REdecide")
				end
			end
			I.UI.removeMode(I.UI.MODE.Interface)
			MenuSelection:destroy()
			MenuSelection=nil
		end

		
	end



	--print("MenuSelectStop "..tostring(MenuSelectStop))
	--print("ToggleUseButton "..tostring(ToggleUseButton))
	--print(input.isActionPressed(input.ACTION.Use))


	----[[
	if Lockpicking and Lockpicking.UI and Lockpicking.UI.layout then
--		print("Rot "..Lockpicking.RotRot)
--		print("Lock "..Lockpicking.LockRot)
--		print(((-2*math.pi/Lockpicking.ConvRot)-math.abs(Lockpicking.LockRot-Lockpicking.Value))-5)
--		print("LockPick "..tostring(Lockpicking.Object.LockPick.position))
--		print("Rot "..tostring(Lockpicking.Object.Rot.position))
--		print("Fixe "..tostring(Lockpicking.Object.Fixe.position))
--		print("Light "..tostring(Lockpicking.Object.Light.position))
--		print(DeltaT)
--		print(math.floor(DeltaT*100+0.5)/2)
--		print("Rot "..Lockpicking.RotRot)
--		print("Lock "..Lockpicking.LockRot)
--		print("lockvalue "..Lockpicking.Value)
--		print("Lockpick rot : "..tostring(Lockpicking.Object.LockPick.rotation))
--		print("Rotpart rot : "..tostring(Lockpicking.Object.Rot.rotation))

		if Lockpicking.RotRot<-178 then
			print("Solved")
			if Lockpicking.Solved==nil then
				Lockpicking.Solved=true
				ambient.playSound("UnlockDoor")
				core.sendGlobalEvent("Unlock",{Lockable=Lockpicking.Lockable})
			end
			if Cross==false then
				I.UI.removeMode(I.UI.MODE.Interface)
				Lockpicking.UI:destroy()
				core.sendGlobalEvent('RemoveItem', { Item = Lockpicking.Object.Fixe, number = 1 })
				core.sendGlobalEvent('RemoveItem', { Item = Lockpicking.Object.Rot, number = 1 })
				core.sendGlobalEvent('RemoveItem', { Item = Lockpicking.Object.LockPick, number = 1 })
				core.sendGlobalEvent('RemoveItem', { Item = Lockpicking.Object.Light, number = 1 })
				Lockpicking={}
			end
		elseif Cross==true and Lockpicking.RotRot>(-180+math.abs(Lockpicking.LockRot-Lockpicking.Value)) and Lockpicking.Object.Rot.count>0 and Lockpicking.Object.LockPick.count>0 then
			Lockpicking.RotRot=Lockpicking.RotRot-math.floor(DeltaT*200+0.5)
			core.sendGlobalEvent('Teleport',
					{
						object = Lockpicking.Object.Rot,
						position =Lockpicking.Object.Rot.position,
						rotation = Lockpicking.RotBaseRot*util.transform.rotateY(Lockpicking.RotRot/180*math.pi)
					})	
			core.sendGlobalEvent('Teleport',
					{
						object = Lockpicking.Object.LockPick,
						position =Lockpicking.Object.LockPick.position,
						rotation = Lockpicking.LockBaseRot*util.transform.rotateY(Lockpicking.RotRot/180*math.pi)*util.transform.rotateY(Lockpicking.LockRot/360*2*math.pi)
					})	
			
		elseif Cross==true and ambient.isSoundPlaying("DoorForced")==false and Lockpicking.Object.Rot.count>0 and Lockpicking.Object.LockPick.count>0  then
			ambient.playSound("DoorForced") 
		elseif Lockpicking.RotRot<=0 and Cross==false and Lockpicking.Object.Rot.count>0 and Lockpicking.Object.LockPick.count>0 then
			Lockpicking.RotRot=Lockpicking.RotRot+math.floor(DeltaT*200+0.5)
			-------------------------------------------------------------Probleme
			if Lockpicking.Object.Rot.position~=util.vector3(0,0,0) and Lockpicking.Object.LockPick.position~=util.vector3(0,0,0) then
			core.sendGlobalEvent('Teleport',
					{
						object = Lockpicking.Object.Rot,
						position =Lockpicking.Object.Rot.position,
						rotation = Lockpicking.RotBaseRot*util.transform.rotateY(Lockpicking.RotRot/180*math.pi)
					})	
			core.sendGlobalEvent('Teleport',
				{
					object = Lockpicking.Object.LockPick,
					position =Lockpicking.Object.LockPick.position,
					rotation = Lockpicking.LockBaseRot*util.transform.rotateY(Lockpicking.RotRot/180*math.pi)*util.transform.rotateY(Lockpicking.LockRot/360*2*math.pi)
				})	
			end
			------------------------------------------------
		elseif Cross==false and TurnLeft(-0.2) and Lockpicking.LockRot>0 and Lockpicking.Object.LockPick.count>0 then
			Lockpicking.LockRot=Lockpicking.LockRot-math.floor(DeltaT*100+0.5)

			core.sendGlobalEvent('Teleport',
					{
						object = Lockpicking.Object.LockPick,
						position =Lockpicking.Object.LockPick.position,
						rotation = Lockpicking.LockBaseRot*util.transform.rotateY(Lockpicking.LockRot/360*2*math.pi)
					})	
		elseif Cross==false and TurnRight(0.2) and Lockpicking.LockRot<360 and Lockpicking.Object.LockPick.count>0 then
			Lockpicking.LockRot=Lockpicking.LockRot+math.floor(DeltaT*100+0.5)
			core.sendGlobalEvent('Teleport',
					{
						object = Lockpicking.Object.LockPick,
						position =Lockpicking.Object.LockPick.position,
						rotation = Lockpicking.LockBaseRot*util.transform.rotateY(Lockpicking.LockRot/360*2*math.pi)
					})	
		end

--		print(Lockpicking.Object.Rot.rotation:getAnglesZYX())
	end
	----]
	
--	if I.UI.getMode() == nil then
--		if MenuSelection and MenuSelection.layout then
--			MenuSelection:destroy()
--			for i, variable in pairs(MenuSelection.layout.content) do
--				if type(i)=="number" then
--					if i%2==0 then
--						core.sendGlobalEvent("ReturnGlobalVariable",{player=self,variable=variable.props.text,value=0})
--					end
--				end
--			end
--			ambient.playSound("RECancel")
--		end
--	end

	if I.UI.getMode() and 
							((Lockpicking and Lockpicking.UI and Lockpicking.UI.layout) 
							or (CrowbarPuzzleUI and CrowbarPuzzleUI.UI and CrowbarPuzzleUI.UI.layout) 
							or ( MenuSelection and MenuSelection.layout ) 
							or (ElectricalPanelPuzzleUI and ElectricalPanelPuzzleUI.UI and ElectricalPanelPuzzleUI.UI.layout)) then
		if MoveBackward(0.2) == false and MoveForward(-0.2) == false and TurnLeft(-0.2) == false and TurnRight(0.2) == false and MenuSelectStop == true then
			MenuSelectStop = false
		end
		if ToggleUseButton == false and Cross == false then
			ToggleUseButton = true
		end
	end

end

]]--






func_table.ElectricalPanel=function(DeltaT,MoveForward,MoveBackward,TurnLeft,TurnRight,Colors,ElectricalPanelPuzzleUI,Cross,ButtonToggle,Toggle)

	if ElectricalPanelPuzzleUI.UI and ElectricalPanelPuzzleUI.UI.layout then
		if ElectricalPanelPuzzleUI.States[1]==nil then
			ElectricalPanelPuzzleUI.States[1]=1
		end
		if MoveForward(-0.2) then
			if ElectricalPanelPuzzleUI.States[4] then
				ElectricalPanelPuzzleUI.States[4]=1
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(25/36, 12/28)
			elseif ElectricalPanelPuzzleUI.States[3] then
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(16/32, 12/28)
				ElectricalPanelPuzzleUI.States[3]=1
			elseif ElectricalPanelPuzzleUI.States[2] then
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(11/31, 12/28)
				ElectricalPanelPuzzleUI.States[2]=1
			elseif ElectricalPanelPuzzleUI.States[1] then
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(6/30, 12/28)
				ElectricalPanelPuzzleUI.States[1]=1
			end
			ElectricalPanelPuzzleUI.UI:update()
		elseif MoveBackward(0.2) then
			if ElectricalPanelPuzzleUI.States[4] then
				ElectricalPanelPuzzleUI.States[4]=-1
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(25/36, 15/31)
			elseif ElectricalPanelPuzzleUI.States[3] then
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(16/32, 15/31)
				ElectricalPanelPuzzleUI.States[3]=-1
			elseif ElectricalPanelPuzzleUI.States[2] then
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(11/31, 17/35)
				ElectricalPanelPuzzleUI.States[2]=-1
			elseif ElectricalPanelPuzzleUI.States[1] then
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(6/30, 17/35)
				ElectricalPanelPuzzleUI.States[1]=-1
			end
			ElectricalPanelPuzzleUI.UI:update()
		end
		
		if Cross == true and ToggleUseButton == true then
			ToggleUseButton =false
			
			if ElectricalPanelPuzzleUI.States[5] then
				core.sendGlobalEvent("ReturnLocalScriptVariable",
					{ value = tonumber(ElectricalPanelPuzzleUI.UI.layout.content[6].props.text), Player = self, Variable = "electricalpanelpuzzle",GameObject=ElectricalPanelPuzzleUI.Object })
				--ElectricalPanelPuzzleUI.UI:destroy()
				I.UI.removeMode(I.UI.MODE.Interface)
			end

			if ElectricalPanelPuzzleUI.States[4] then
				ElectricalPanelPuzzleUI.States[5]=1
				ambient.playSound("Button1")
				ElectricalPanelPuzzleUI.UI.layout.content[10].props.relativePosition=ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition
				if ElectricalPanelPuzzleUI.States[4]==1 then
					ElectricalPanelPuzzleUI.UI.layout.content[10].props.color=Colors.Red
				else
					ElectricalPanelPuzzleUI.UI.layout.content[10].props.color=Colors.Blue
				end
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.visible=false
				ElectricalPanelPuzzleUI.UI.layout.content[6].props.text=tostring(ElectricalPanelPuzzleUI.UI.layout.content[5].props.text+(ElectricalPanelPuzzleUI.States[4]*15*4))
			elseif ElectricalPanelPuzzleUI.States[3] then
				ElectricalPanelPuzzleUI.States[4]=1
				ambient.playSound("Button1")
				ElectricalPanelPuzzleUI.UI.layout.content[9].props.relativePosition=ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition
				if ElectricalPanelPuzzleUI.States[3]==1 then
					ElectricalPanelPuzzleUI.UI.layout.content[9].props.color=Colors.Red
				else
					ElectricalPanelPuzzleUI.UI.layout.content[9].props.color=Colors.Blue
				end
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(25/36, 12/28)
				ElectricalPanelPuzzleUI.UI.layout.content[5].props.text=tostring(ElectricalPanelPuzzleUI.UI.layout.content[4].props.text+(ElectricalPanelPuzzleUI.States[3]*5*3))
			elseif ElectricalPanelPuzzleUI.States[2] then
				ElectricalPanelPuzzleUI.States[3]=1
				ambient.playSound("Button1")
				ElectricalPanelPuzzleUI.UI.layout.content[8].props.relativePosition=ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition
				if ElectricalPanelPuzzleUI.States[2]==1 then
					ElectricalPanelPuzzleUI.UI.layout.content[8].props.color=Colors.Red
				else
					ElectricalPanelPuzzleUI.UI.layout.content[8].props.color=Colors.Blue
				end
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(16/32, 12/28)
				ElectricalPanelPuzzleUI.UI.layout.content[4].props.text=tostring(ElectricalPanelPuzzleUI.UI.layout.content[3].props.text+(ElectricalPanelPuzzleUI.States[2]*15*2))
			elseif ElectricalPanelPuzzleUI.States[1] then
				ElectricalPanelPuzzleUI.States[2]=1
				ambient.playSound("Button1")
				ElectricalPanelPuzzleUI.UI.layout.content[7].props.relativePosition=ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition
				if ElectricalPanelPuzzleUI.States[1]==1 then
					ElectricalPanelPuzzleUI.UI.layout.content[7].props.color=Colors.Red
				else
					ElectricalPanelPuzzleUI.UI.layout.content[7].props.color=Colors.Blue
				end
				ElectricalPanelPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(11/31, 12/28)
				ElectricalPanelPuzzleUI.UI.layout.content[3].props.text=tostring(ElectricalPanelPuzzleUI.UI.layout.content[2].props.text+(ElectricalPanelPuzzleUI.States[1]*5))
			end
			ElectricalPanelPuzzleUI.UI:update()
		end

	end

	if I.UI.getMode() then
		if MoveBackward(0.2) == false and MoveForward(-0.2) == false and TurnLeft(-0.2) == false and TurnRight(0.2) == false and MenuSelectStop == true then
			MenuSelectStop = false
		end
		if ToggleUseButton == false and Cross == false then
			ToggleUseButton = true
		end
	end
end









func_table.MenuSelection=function(DeltaT,MoveForward,MoveBackward,TurnLeft,TurnRight,Colors,MenuSelection,Cross,ButtonToggle,Toggle)

	if MenuSelection and MenuSelection.layout then
		if TurnRight(0.2) == "Right" and MenuSelectStop == false then
			MenuSelectStop = true
			for i, content in ipairs(MenuSelection.layout.content) do
				if type(i)=="number" then
					if i % 2 == 1 and MenuSelection.layout.content[i + 2] and content.props.visible == true then
						content.props.visible = false
						MenuSelection.layout.content[i + 2].props.visible = true
						MenuSelection:update()
						ambient.playSound("Cursor")
						break
					end
				end
			end
		elseif TurnLeft(-0.2) == "Left" and MenuSelectStop == false then
			MenuSelectStop = true
			for i, content in ipairs(MenuSelection.layout.content) do
				if type(i)=="number" then
					if i % 2 == 1 and i >= 3 and content.props.visible == true then
						content.props.visible = false
						MenuSelection.layout.content[i - 2].props.visible = true
						MenuSelection:update()
						ambient.playSound("Cursor")
						break
					end
				end
			end
		end
		if Cross == true and ToggleUseButton == true then
			ToggleUseButton=false
			for i, content in ipairs(MenuSelection.layout.content) do
				if i % 2 == 1 and content.props.visible == true then
					print(i)
					print(MenuSelection.layout.content[i+1].props.text)
					core.sendGlobalEvent("ReturnGlobalVariable",{value =1,Player = self,variable =MenuSelection.layout.content[i+1].props.text})
					ambient.playSound("REdecide")
				end
			end
			I.UI.removeMode(I.UI.MODE.Interface)
			MenuSelection:destroy()
			MenuSelection=nil
		end

		
	end



	if I.UI.getMode() and MenuSelection and MenuSelection.layout then
		if MoveBackward(0.2) == false and MoveForward(-0.2) == false and TurnLeft(-0.2) == false and TurnRight(0.2) == false and MenuSelectStop == true then
			MenuSelectStop = false
		end
		if ToggleUseButton == false and Cross == false then
			ToggleUseButton = true
		end
	end
end





func_table.LockPicking=function(DeltaT,MoveForward,MoveBackward,TurnLeft,TurnRight,Colors,Lockpicking,Cross,ButtonToggle,Toggle)

	--print("MenuSelectStop "..tostring(MenuSelectStop))
	--print("ToggleUseButton "..tostring(ToggleUseButton))
	--print(input.isActionPressed(input.ACTION.Use))
	----[[
	if Lockpicking and Lockpicking.UI and Lockpicking.UI.layout then
--		print("Rot "..Lockpicking.RotRot)
--		print("Lock "..Lockpicking.LockRot)
--		print(((-2*math.pi/Lockpicking.ConvRot)-math.abs(Lockpicking.LockRot-Lockpicking.Value))-5)
--		print("LockPick "..tostring(Lockpicking.Object.LockPick.position))
--		print("Rot "..tostring(Lockpicking.Object.Rot.position))
--		print("Fixe "..tostring(Lockpicking.Object.Fixe.position))
--		print("Light "..tostring(Lockpicking.Object.Light.position))
--		print(DeltaT)
--		print(math.floor(DeltaT*100+0.5)/2)
--		print("Rot "..Lockpicking.RotRot)
--		print("Lock "..Lockpicking.LockRot)
--		print("lockvalue "..Lockpicking.Value)
--		print("Lockpick rot : "..tostring(Lockpicking.Object.LockPick.rotation))
--		print("Rotpart rot : "..tostring(Lockpicking.Object.Rot.rotation))

		if Lockpicking.RotRot<-178 then
			print("Solved")
			if Lockpicking.Solved==nil then
				Lockpicking.Solved=true
				ambient.playSound("UnlockDoor")
				core.sendGlobalEvent("Unlock",{Lockable=Lockpicking.Lockable})
			end
			if Cross==false then
				I.UI.removeMode(I.UI.MODE.Interface)
				Lockpicking.UI:destroy()
				core.sendGlobalEvent('RemoveItem', { Item = Lockpicking.Object.Fixe, number = 1 })
				core.sendGlobalEvent('RemoveItem', { Item = Lockpicking.Object.Rot, number = 1 })
				core.sendGlobalEvent('RemoveItem', { Item = Lockpicking.Object.LockPick, number = 1 })
				core.sendGlobalEvent('RemoveItem', { Item = Lockpicking.Object.Light, number = 1 })
				Lockpicking={}
			end
		elseif Cross==true and Lockpicking.RotRot>(-180+math.abs(Lockpicking.LockRot-Lockpicking.Value)) and Lockpicking.Object.Rot.count>0 and Lockpicking.Object.LockPick.count>0 then
			Lockpicking.RotRot=Lockpicking.RotRot-math.floor(DeltaT*200+0.5)
			core.sendGlobalEvent('Teleport',
					{
						object = Lockpicking.Object.Rot,
						position =Lockpicking.Object.Rot.position,
						rotation = Lockpicking.RotBaseRot*util.transform.rotateY(Lockpicking.RotRot/180*math.pi)
					})	
			core.sendGlobalEvent('Teleport',
					{
						object = Lockpicking.Object.LockPick,
						position =Lockpicking.Object.LockPick.position,
						rotation = Lockpicking.LockBaseRot*util.transform.rotateY(Lockpicking.RotRot/180*math.pi)*util.transform.rotateY(Lockpicking.LockRot/360*2*math.pi)
					})	
			
		elseif Cross==true and ambient.isSoundPlaying("DoorForced")==false and Lockpicking.Object.Rot.count>0 and Lockpicking.Object.LockPick.count>0  then
			ambient.playSound("DoorForced") 
		elseif Lockpicking.RotRot<=0 and Cross==false and Lockpicking.Object.Rot.count>0 and Lockpicking.Object.LockPick.count>0 then
			Lockpicking.RotRot=Lockpicking.RotRot+math.floor(DeltaT*200+0.5)
			-------------------------------------------------------------Probleme
			if Lockpicking.Object.Rot.position~=util.vector3(0,0,0) and Lockpicking.Object.LockPick.position~=util.vector3(0,0,0) then
			core.sendGlobalEvent('Teleport',
					{
						object = Lockpicking.Object.Rot,
						position =Lockpicking.Object.Rot.position,
						rotation = Lockpicking.RotBaseRot*util.transform.rotateY(Lockpicking.RotRot/180*math.pi)
					})	
			core.sendGlobalEvent('Teleport',
				{
					object = Lockpicking.Object.LockPick,
					position =Lockpicking.Object.LockPick.position,
					rotation = Lockpicking.LockBaseRot*util.transform.rotateY(Lockpicking.RotRot/180*math.pi)*util.transform.rotateY(Lockpicking.LockRot/360*2*math.pi)
				})	
			end
			------------------------------------------------
		elseif Cross==false and TurnLeft(-0.2) and Lockpicking.LockRot>0 and Lockpicking.Object.LockPick.count>0 then
			Lockpicking.LockRot=Lockpicking.LockRot-math.floor(DeltaT*100+0.5)

			core.sendGlobalEvent('Teleport',
					{
						object = Lockpicking.Object.LockPick,
						position =Lockpicking.Object.LockPick.position,
						rotation = Lockpicking.LockBaseRot*util.transform.rotateY(Lockpicking.LockRot/360*2*math.pi)
					})	
		elseif Cross==false and TurnRight(0.2) and Lockpicking.LockRot<360 and Lockpicking.Object.LockPick.count>0 then
			Lockpicking.LockRot=Lockpicking.LockRot+math.floor(DeltaT*100+0.5)
			core.sendGlobalEvent('Teleport',
					{
						object = Lockpicking.Object.LockPick,
						position =Lockpicking.Object.LockPick.position,
						rotation = Lockpicking.LockBaseRot*util.transform.rotateY(Lockpicking.LockRot/360*2*math.pi)
					})	
		end

--		print(Lockpicking.Object.Rot.rotation:getAnglesZYX())
	end
	----]]
	
--	if I.UI.getMode() == nil then
--		if MenuSelection and MenuSelection.layout then
--			MenuSelection:destroy()
--			for i, variable in pairs(MenuSelection.layout.content) do
--				if type(i)=="number" then
--					if i%2==0 then
--						core.sendGlobalEvent("ReturnGlobalVariable",{player=self,variable=variable.props.text,value=0})
--					end
--				end
--			end
--			ambient.playSound("RECancel")
--		end
--	end

	if I.UI.getMode() then
		if MoveBackward(0.2) == false and MoveForward(-0.2) == false and TurnLeft(-0.2) == false and TurnRight(0.2) == false and MenuSelectStop == true then
			MenuSelectStop = false
		end
		if ToggleUseButton == false and Cross == false then
			ToggleUseButton = true
		end
	end

end





func_table.CrowbarPuzzle=function(DeltaT,MoveForward,MoveBackward,TurnLeft,TurnRight,Colors,Cross,CrowbarPuzzleUI,ButtonToggle,Toggle)

	
	if CrowbarPuzzleUI.UI and CrowbarPuzzleUI.UI.layout then
		if CrowbarPuzzleUI.UI.layout.content[1].props.relativePosition.x>0.96 then
			CrowbarPuzzleUI.Way=-1
		elseif CrowbarPuzzleUI.UI.layout.content[1].props.relativePosition.x<0.04 then
			CrowbarPuzzleUI.Way=1		
		end
		CrowbarPuzzleUI.UI.layout.content[1].props.relativePosition=util.vector2(CrowbarPuzzleUI.UI.layout.content[1].props.relativePosition.x+DeltaT*CrowbarPuzzleUI.Way*CrowbarPuzzleUI.Speed,CrowbarPuzzleUI.UI.layout.content[1].props.relativePosition.y)
		
		if CrowbarPuzzleUI.UI.layout.content[1].props.color~=Colors.White and (core.getRealTime()-CrowbarPuzzleUI.timer)>0.1 then
			CrowbarPuzzleUI.UI.layout.content[1].props.color=Colors.White
		end


		if (core.getRealTime()-CrowbarPuzzleUI.timer)>0 and (core.getRealTime()-CrowbarPuzzleUI.timer)<0.05 then
			CrowbarPuzzleUI.UI.layout.props.relativePosition=CrowbarPuzzleUI.UI.layout.props.relativePosition+util.vector2(0,0.01)
		elseif CrowbarPuzzleUI.UI.layout.props.relativePosition.y>0.75 then
			CrowbarPuzzleUI.UI.layout.props.relativePosition=CrowbarPuzzleUI.UI.layout.props.relativePosition+util.vector2(0,-0.01)
		end


		if Cross==true and ToggleUseButton == true  then
			ToggleUseButton = false 
			if CrowbarPuzzleUI.UI.layout.content[1].props.relativePosition.x>0.45 and CrowbarPuzzleUI.UI.layout.content[1].props.relativePosition.x<0.55 then
				ambient.playSound("WoodBreak")
				if CrowbarPuzzleUI.Speed>=0.5+(CrowbarPuzzleUI.value-1)*0.2 then
					core.sendGlobalEvent("ReturnLocalScriptVariable",
						{ value = 11, Player = self, Variable = "crowbarvalue",GameObject=CrowbarPuzzleUI.Object })
					I.UI.removeMode(I.UI.MODE.Interface)
				else 
					CrowbarPuzzleUI.Speed=CrowbarPuzzleUI.Speed+0.2
					CrowbarPuzzleUI.UI.layout.content[1].props.color=Colors.Blue
					CrowbarPuzzleUI.timer=core.getRealTime()
				end
			else
				if CrowbarPuzzleUI.Speed>0.5 then
					CrowbarPuzzleUI.Speed=CrowbarPuzzleUI.Speed-0.2
				end
				ambient.playSound("decidewrong")
				CrowbarPuzzleUI.UI.layout.content[1].props.color=Colors.Red
				CrowbarPuzzleUI.timer=core.getRealTime()
			end
		end
		CrowbarPuzzleUI.UI:update()

	end

	if I.UI.getMode() then
		if MoveBackward(0.2) == false and MoveForward(-0.2) == false and TurnLeft(-0.2) == false and TurnRight(0.2) == false and MenuSelectStop == true then
			MenuSelectStop = false
		end
		if ToggleUseButton == false and Cross == false then
			ToggleUseButton = true
		end
	end

end



func_table.BlowtorchPaterns=function(Patern)
	local BlowtorchPuzzlePatern={
		{
		0,0,0,0,0,0,0,0,0,0,
		0,0,1,1,1,1,1,1,0,0,
		0,0,1,0,0,0,0,1,0,0,
		0,0,1,0,0,0,0,1,0,0,
		0,0,1,0,0,0,0,1,0,0,
		0,0,1,0,0,0,0,1,0,0,
		0,0,1,0,0,0,0,1,0,0,
		0,0,1,1,1,1,1,1,0,0,
		0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,
		},
		{
		0,0,0,0,0,0,0,0,0,0,
		0,0,0,1,1,1,1,0,0,0,
		0,0,1,1,0,0,1,0,0,0,
		0,0,1,0,0,0,1,0,0,0,
		0,0,1,0,0,0,1,1,0,0,
		0,0,1,0,0,0,0,1,0,0,
		0,0,1,0,0,0,0,1,1,0,
		0,0,1,0,0,0,0,0,1,0,
		0,0,1,1,1,1,1,1,1,0,
		0,0,0,0,0,0,0,0,0,0,
		},
		{
		0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,
		0,0,1,1,1,1,0,0,0,0,
		0,0,1,0,0,1,0,0,0,0,
		0,0,1,0,0,1,1,1,1,0,
		0,0,1,0,0,0,0,0,1,0,
		0,0,1,1,1,0,0,0,1,0,
		0,0,0,0,1,0,0,0,1,0,
		0,0,0,0,1,1,1,1,1,0,
		0,0,0,0,0,0,0,0,0,0,
		},
		{
		0,0,0,0,0,0,0,0,0,0,
		0,0,1,1,1,1,1,1,1,0,
		0,0,1,0,0,0,0,0,1,0,
		0,0,1,1,1,1,0,1,1,0,
		0,0,0,0,0,1,0,1,0,0,
		0,0,0,0,1,1,0,1,1,0,
		0,0,0,0,1,0,0,0,1,0,
		0,0,0,0,1,1,1,0,1,0,
		0,0,0,0,0,0,1,1,1,0,
		0,0,0,0,0,0,0,0,0,0,
		},
		{
		0,0,0,0,0,0,0,1,1,1,
		0,1,1,1,1,1,1,1,0,1,
		0,1,0,0,0,0,0,0,0,1,
		0,1,0,0,0,0,0,0,0,1,
		0,1,1,1,0,0,0,0,0,1,
		0,0,0,1,0,0,0,0,0,1,
		0,0,0,1,0,0,1,1,1,1,
		0,0,0,1,0,0,1,0,0,0,
		0,0,0,1,1,1,1,0,0,0,
		0,0,0,0,0,0,0,0,0,0,
		},
	}
	return(BlowtorchPuzzlePatern[Patern])
end


local traceDt=0.03
func_table.Blowtorch=function(DeltaT,MoveForward,MoveBackward,TurnLeft,TurnRight,BlowtorchPuzzleUI,Cross,ButtonToggle,Toggle)

	print(BlowtorchPuzzleUI.UI.layout.content)
	print(BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition)
	BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition=BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition+util.vector2(((math.random(10)-5)/50000),((math.random(10)-5)/50000))

	if MoveForward(-0.2) and BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition.y-0.1*DeltaT>0.15 then
		BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition=BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition+util.vector2(0,-0.1*DeltaT)
	elseif MoveBackward(0.2) and BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition.y+0.1*DeltaT<0.75 then
		BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition=BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition+util.vector2(0,0.1*DeltaT)
	end
	if TurnLeft(-0.2) and BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition.x-0.1*DeltaT>0.15 then
		BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition=BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition+util.vector2(-0.1*DeltaT,0)
	elseif TurnRight(0.2) and BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition.x+0.1*DeltaT<0.85 then
		BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition=BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition+util.vector2(0.1*DeltaT,0)
	end




	BlowtorchPuzzleUI.UI.layout.content.Flame.props.timer=BlowtorchPuzzleUI.UI.layout.content.Flame.props.timer-DeltaT
	if BlowtorchPuzzleUI.UI.layout.content.Flame.props.timer<0 then
		BlowtorchPuzzleUI.UI.layout.content.Flame.props.timer=BlowtorchPuzzleUI.UI.layout.content.Flame.props.baseTimer
		BlowtorchPuzzleUI.UI.layout.content.Flame.props.value=BlowtorchPuzzleUI.UI.layout.content.Flame.props.value+1
		if BlowtorchPuzzleUI.UI.layout.content.Flame.props.value==10 then
			BlowtorchPuzzleUI.UI.layout.content.Flame.props.value=0
		end
		BlowtorchPuzzleUI.UI.layout.content.Flame.props.resource=ui.texture{path ="textures/Puzzles/blowtorch/flame.dds", 
																					offset = util.vector2(50*BlowtorchPuzzleUI.UI.layout.content.Flame.props.value, 0),
																					size = util.vector2(50, 60), }
	end


	if BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition.x>0.27 and BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition.x<0.77 and BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition.y>0.27 and BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition.y<0.77 then
		BlowtorchPuzzleUI.UI.layout.content.Sparks.props.timer=BlowtorchPuzzleUI.UI.layout.content.Sparks.props.timer-DeltaT
		if BlowtorchPuzzleUI.UI.layout.content.Sparks.props.timer<0 then
			BlowtorchPuzzleUI.UI.layout.content.Sparks.props.timer=BlowtorchPuzzleUI.UI.layout.content.Sparks.props.baseTimer
			BlowtorchPuzzleUI.UI.layout.content.Sparks.props.value=BlowtorchPuzzleUI.UI.layout.content.Sparks.props.value+1
			if BlowtorchPuzzleUI.UI.layout.content.Sparks.props.value==20 then
				BlowtorchPuzzleUI.UI.layout.content.Sparks.props.value=0
			end
			BlowtorchPuzzleUI.UI.layout.content.Sparks.props.resource=ui.texture{path ="textures/Puzzles/blowtorch/Sparks.dds", 
																						offset = util.vector2(480*BlowtorchPuzzleUI.UI.layout.content.Sparks.props.value, 0),
																						size = util.vector2(480, 480), }
		end
		
		traceDt=traceDt-DeltaT
		if BlowtorchPuzzleUI.Patern[math.floor((BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition.y-.25)*20)*10+math.floor((BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition.x-.25)*20)+1]>0 then
			
			BlowtorchPuzzleUI.Patern[math.floor((BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition.y-.25)*20)*10+math.floor((BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition.x-.25)*20)+1]=2
			if BlowtorchPuzzleUI.UI.layout.content.Sparks.props.visible==false then
				BlowtorchPuzzleUI.UI.layout.content.Sparks.props.visible=true
			end
			if ambient.isSoundPlaying("Welding")==false then
				ambient.playSound("Welding")
			end
			if traceDt<0 then
				BlowtorchPuzzleUI.UI.layout.content.Deeps.content:add({ type = ui.TYPE.Image, props = {resource = ui.texture{path ="textures/Puzzles/blowtorch/deep.dds"},relativeSize=util.vector2(0.02, 0.02),relativePosition=BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition-util.vector2(0.03,0.03),} })
				BlowtorchPuzzleUI.UI.layout.content.Welds.content:add({ type = ui.TYPE.Image, props = {resource = ui.texture{path ="textures/Puzzles/blowtorch/weld.dds"},relativeSize=util.vector2(0.025, 0.025),relativePosition=BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition-util.vector2(0.03,0.03),} })
				traceDt=0.03
			end


		else
			if BlowtorchPuzzleUI.UI.layout.content.Sparks.props.visible==true then
				BlowtorchPuzzleUI.UI.layout.content.Sparks.props.visible=false
			end
			if ambient.isSoundPlaying("Welding")==true then
				ambient.stopSound("Welding")
			end
			if traceDt<0 then
				BlowtorchPuzzleUI.UI.layout.content[2].content:add({ type = ui.TYPE.Image, props = {resource = ui.texture{path ="textures/Puzzles/blowtorch/surface.dds"},relativeSize=util.vector2(0.02, 0.02),relativePosition=BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition-util.vector2(0.03,0.03),} })
				traceDt=0.03
			end
		end
	else 
			if BlowtorchPuzzleUI.UI.layout.content.Sparks.props.visible==true then
				BlowtorchPuzzleUI.UI.layout.content.Sparks.props.visible=false
			end
			if ambient.isSoundPlaying("Welding")==true then
				ambient.stopSound("Welding")
			end
	end

	BlowtorchPuzzleUI.UI.layout.content.Sparks.props.relativePosition=BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition-util.vector2(0.16,0.16)
	BlowtorchPuzzleUI.UI.layout.content.Flame.props.relativePosition=BlowtorchPuzzleUI.UI.layout.content.Torch.props.relativePosition-util.vector2(0.05,0.06)

	if ambient.isSoundPlaying("BlowtorchSound")==false then
		ambient.playSound("BlowtorchSound")
	end

	BlowtorchPuzzleUI.UI:update()



	BlowtorchPuzzleUI.TimerChecking=BlowtorchPuzzleUI.TimerChecking-DeltaT
	if BlowtorchPuzzleUI.TimerChecking<0 then
		BlowtorchPuzzleUI.TimerChecking=1
		for i,patern in pairs(BlowtorchPuzzleUI.Patern) do
			if patern==1 then
				break
			elseif BlowtorchPuzzleUI.Patern[i+1]==nil then
				ambient.playSoundFile("sound/ROOM20D 00004.wav")
				core.sendGlobalEvent("ReturnLocalScriptVariable",
					{ value = -1, Player = self, Variable = "blowtorch",GameObject=BlowtorchPuzzleUI.Object })
				I.UI.removeMode(I.UI.MODE.Interface)
			ambient.stopSound("BlowtorchSound")
			ambient.stopSound("Welding")
			end
		end
	end

		if I.UI.getMode() then
			if MoveBackward(0.2) == false and MoveForward(-0.2) == false and TurnLeft(-0.2) == false and TurnRight(0.2) == false and MenuSelectStop == true then
				MenuSelectStop = false
			end
			if ToggleUseButton == false and Cross == false then
				ToggleUseButton = true
			end
		end
end

func_table.HotAndColdPuzzle=function(DeltaT,MoveForward,MoveBackward,TurnLeft,TurnRight,HotAndColdPuzzleUI,Cross,ButtonToggle,Toggle,Colors)
	if HotAndColdPuzzleUI.DisableTempo>=1 then
		if (HotAndColdPuzzleUI.UI.layout.content.GameSphere.content.Seek.props.relativePosition-util.vector2(0.5,0.5)):length()+0.2*DeltaT/0.004<0.65 then
			if MoveForward(-0.2) then
				HotAndColdPuzzleUI.UI.layout.content.GameSphere.content.Seek.props.relativePosition=HotAndColdPuzzleUI.UI.layout.content.GameSphere.content.Seek.props.relativePosition+util.vector2(0,-0.2*DeltaT)
				if ambient.isSoundPlaying("CreakandCrack")==false then
					ambient.playSound("CreakandCrack")
				end
			elseif MoveBackward(0.2) then
				HotAndColdPuzzleUI.UI.layout.content.GameSphere.content.Seek.props.relativePosition=HotAndColdPuzzleUI.UI.layout.content.GameSphere.content.Seek.props.relativePosition+util.vector2(0,0.2*DeltaT)
				if ambient.isSoundPlaying("CreakandCrack")==false then
					ambient.playSound("CreakandCrack")
				end
			end
			if TurnLeft(-0.2) then
				HotAndColdPuzzleUI.UI.layout.content.GameSphere.content.Seek.props.relativePosition=HotAndColdPuzzleUI.UI.layout.content.GameSphere.content.Seek.props.relativePosition+util.vector2(-0.2*DeltaT,0)
				if ambient.isSoundPlaying("CreakandCrack")==false then
					ambient.playSound("CreakandCrack")
				end
			elseif TurnRight(0.2) then
				HotAndColdPuzzleUI.UI.layout.content.GameSphere.content.Seek.props.relativePosition=HotAndColdPuzzleUI.UI.layout.content.GameSphere.content.Seek.props.relativePosition+util.vector2(0.2*DeltaT,0)
				if ambient.isSoundPlaying("CreakandCrack")==false then
					ambient.playSound("CreakandCrack")
				end			
			end
		end

		if Cross==true then	
			if HotAndColdPuzzleUI.UI.layout.content.Bar.content.Progress.props.relativeSize.y<1 then
				HotAndColdPuzzleUI.UI.layout.content.Bar.content.Progress.props.relativeSize=util.vector2(HotAndColdPuzzleUI.UI.layout.content.Bar.content.Progress.props.relativeSize.x,HotAndColdPuzzleUI.UI.layout.content.Bar.content.Progress.props.relativeSize.y+0.002*DeltaT/0.004)
				if ambient.isSoundPlaying("WoodCreak")==false then
					ambient.playSound("WoodCreak")
				end
			end
		elseif HotAndColdPuzzleUI.UI.layout.content.Bar.content.Progress.props.relativeSize.y>0 then
			HotAndColdPuzzleUI.UI.layout.content.Bar.content.Progress.props.relativeSize=util.vector2(HotAndColdPuzzleUI.UI.layout.content.Bar.content.Progress.props.relativeSize.x,HotAndColdPuzzleUI.UI.layout.content.Bar.content.Progress.props.relativeSize.y-0.002*DeltaT/0.004)
		end

		if (HotAndColdPuzzleUI.UI.layout.content.GameSphere.content.Seek.props.relativePosition-HotAndColdPuzzleUI.UI.layout.content.GameSphere.content.Target.props.relativePosition):length()<(HotAndColdPuzzleUI.UI.layout.content.GameSphere.content.Seek.props.relativeSize.x/5+HotAndColdPuzzleUI.UI.layout.content.GameSphere.content.Target.props.relativeSize.x/3) then
			if HotAndColdPuzzleUI.UI.layout.content.GameSphere.content.Seek.props.color==Colors.Red then
				HotAndColdPuzzleUI.UI.layout.content.GameSphere.content.Seek.props.color=Colors.Orange
			end
		elseif HotAndColdPuzzleUI.UI.layout.content.GameSphere.content.Seek.props.color==Colors.Orange then
			HotAndColdPuzzleUI.UI.layout.content.GameSphere.content.Seek.props.color=Colors.Red
		end
	end
	HotAndColdPuzzleUI.UI.layout.content.GameSphere.content.Seek.props.relativeSize=util.vector2(1.1-HotAndColdPuzzleUI.UI.layout.content.Bar.content.Progress.props.relativeSize.y,1.1-HotAndColdPuzzleUI.UI.layout.content.Bar.content.Progress.props.relativeSize.y)
	
	HotAndColdPuzzleUI.UI:update()

	if HotAndColdPuzzleUI.UI.layout.content.Bar.content.Progress.props.relativeSize.y>=1 then
		if HotAndColdPuzzleUI.DisableTempo==1 then
			if HotAndColdPuzzleUI.UI.layout.content.GameSphere.content.Seek.props.color==Colors.Orange then
				ambient.playSound("REdecide")
				core.sendGlobalEvent("ReturnLocalScriptVariable",
					{ value = -1, Player = self, Variable = "hacpuzzle",GameObject=HotAndColdPuzzleUI.Object })
			else
				ambient.playSound("decidewrong")
			end
		end

		HotAndColdPuzzleUI.UI.layout.content.GameSphere.content.Target.props.visible=true
		HotAndColdPuzzleUI.DisableTempo=HotAndColdPuzzleUI.DisableTempo-DeltaT
		if HotAndColdPuzzleUI.DisableTempo<=0 then
			I.UI.removeMode(I.UI.MODE.Interface)
		end
	end

end


return func_table
