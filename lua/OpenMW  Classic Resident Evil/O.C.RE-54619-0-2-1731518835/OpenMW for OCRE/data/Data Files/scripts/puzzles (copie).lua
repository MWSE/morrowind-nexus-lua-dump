
local types = require('openmw.types')
local ambient = require('openmw.ambient')
local core = require('openmw.core')

local func_table={}

local ToggleUseButton = false
local MenuSelectStop = true
local SavingSelection=1
local SavingDescription=""
local Saving=false
local SavingLetter=4
local Timer=0








func_table.RunningPuzzles=function(self,input,util,DeltaT,core,I,MoveForward,MoveBackward,TurnLeft,TurnRight,Colors,ElectricalPanelPuzzleUI,MenuSelection,Lockpicking,Cross,CrowbarPuzzleUI,ButtonToggle,Toggle)

	
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
		print(DeltaT)
		print(math.floor(DeltaT*100+0.5)/2)
		if Lockpicking.RotRot<(-2*math.pi/Lockpicking.ConvRot) then
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
		elseif Cross==true and Lockpicking.RotRot>((-2*math.pi/Lockpicking.ConvRot)+math.abs(Lockpicking.LockRot-Lockpicking.Value)-5) then
			Lockpicking.RotRot=Lockpicking.RotRot-1
			core.sendGlobalEvent('Teleport',
					{
						object = Lockpicking.Object.Rot,
						position =Lockpicking.Object.Rot.position,
						rotation = Lockpicking.Object.Rot.rotation*util.transform.rotateY(-Lockpicking.ConvRot*math.floor(DeltaT*100+0.5)/2)
					})	
			core.sendGlobalEvent('Teleport',
					{
						object = Lockpicking.Object.LockPick,
						position =Lockpicking.Object.LockPick.position,
						rotation = Lockpicking.Object.LockPick.rotation*util.transform.rotateY(-Lockpicking.ConvRot*math.floor(DeltaT*100+0.5)/2)
					})	
			
		elseif Cross==true and ambient.isSoundPlaying("DoorForced")==false then
			ambient.playSound("DoorForced") 
		elseif Lockpicking.RotRot<=0 and Cross==false then
			Lockpicking.RotRot=Lockpicking.RotRot+1
			-------------------------------------------------------------Probleme
			if Lockpicking.Object.Rot.position~=util.vector3(0,0,0) and Lockpicking.Object.LockPick.position~=util.vector3(0,0,0) then
			core.sendGlobalEvent('Teleport',
					{
						object = Lockpicking.Object.Rot,
						position =Lockpicking.Object.Rot.position,
						rotation = Lockpicking.Object.Rot.rotation*util.transform.rotateY(Lockpicking.ConvRot*math.floor(DeltaT*100+0.5)/2)
					})	
			core.sendGlobalEvent('Teleport',
				{
					object = Lockpicking.Object.LockPick,
					position =Lockpicking.Object.LockPick.position,
					rotation = Lockpicking.Object.LockPick.rotation*util.transform.rotateY(Lockpicking.ConvRot*math.floor(DeltaT*100+0.5)/2)
				})	
			end
			------------------------------------------------
		elseif TurnLeft(-0.2) and Lockpicking.LockRot>0 then
			Lockpicking.LockRot=Lockpicking.LockRot-1

			core.sendGlobalEvent('Teleport',
					{
						object = Lockpicking.Object.LockPick,
						position =Lockpicking.Object.LockPick.position,
						rotation = Lockpicking.Object.LockPick.rotation*util.transform.rotateY(-Lockpicking.ConvRot*math.floor(DeltaT*100+0.5)/2)
					})	
		elseif TurnRight(0.2) and Lockpicking.LockRot<(4*math.pi/Lockpicking.ConvRot) then
			Lockpicking.LockRot=Lockpicking.LockRot+1
			core.sendGlobalEvent('Teleport',
					{
						object = Lockpicking.Object.LockPick,
						position =Lockpicking.Object.LockPick.position,
						rotation = Lockpicking.Object.LockPick.rotation*util.transform.rotateY(Lockpicking.ConvRot*math.floor(DeltaT*100+0.5)/2)
					})	
		end

		print(Lockpicking.Object.Rot.rotation:getAnglesZYX())
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



return func_table
