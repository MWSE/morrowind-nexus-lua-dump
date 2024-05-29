
local types = require('openmw.types')
local ambient = require('openmw.ambient')
local core = require('openmw.core')

local func_table={}

local ToggleUseButton = false
local MenuSelectStop = true
local ElecPanPuzzle={}
local SavingSelection=1
local SavingDescription=""
local Saving=false
local SavingLetter=4
local Timer=0








func_table.RunningPuzzles=function(self,input,util,core,I,MoveForward,MoveBackward,TurnLeft,TurnRight,Colors,
	MenuYesNo,Menu15,ElectricalPanelPuzzleUI,MenuSelection)


	if ElectricalPanelPuzzleUI and ElectricalPanelPuzzleUI.layout then
		if ElecPanPuzzle[1]==nil then
			ElecPanPuzzle[1]=1
		end
		if MoveForward(-0.2) == true then
			if ElecPanPuzzle[4] then
				ElecPanPuzzle[4]=1
				ElectricalPanelPuzzleUI.layout.content[1].props.relativePosition=util.vector2(25/36, 12/28)
			elseif ElecPanPuzzle[3] then
				ElectricalPanelPuzzleUI.layout.content[1].props.relativePosition=util.vector2(16/32, 12/28)
				ElecPanPuzzle[3]=1
			elseif ElecPanPuzzle[2] then
				ElectricalPanelPuzzleUI.layout.content[1].props.relativePosition=util.vector2(11/31, 12/28)
				ElecPanPuzzle[2]=1
			elseif ElecPanPuzzle[1] then
				ElectricalPanelPuzzleUI.layout.content[1].props.relativePosition=util.vector2(6/30, 12/28)
				ElecPanPuzzle[1]=1
			end
			ElectricalPanelPuzzleUI:update()
		elseif MoveBackward(0.2) == true then
			if ElecPanPuzzle[4] then
				ElecPanPuzzle[4]=-1
				ElectricalPanelPuzzleUI.layout.content[1].props.relativePosition=util.vector2(25/36, 15/31)
			elseif ElecPanPuzzle[3] then
				ElectricalPanelPuzzleUI.layout.content[1].props.relativePosition=util.vector2(16/32, 15/31)
				ElecPanPuzzle[3]=-1
			elseif ElecPanPuzzle[2] then
				ElectricalPanelPuzzleUI.layout.content[1].props.relativePosition=util.vector2(11/31, 17/35)
				ElecPanPuzzle[2]=-1
			elseif ElecPanPuzzle[1] then
				ElectricalPanelPuzzleUI.layout.content[1].props.relativePosition=util.vector2(6/30, 17/35)
				ElecPanPuzzle[1]=-1
			end
			ElectricalPanelPuzzleUI:update()
		end
		
		if input.isActionPressed(input.ACTION.Use) == true and ToggleUseButton == true then
			ToggleUseButton =false
			
			if ElecPanPuzzle[5] then
				core.sendGlobalEvent("ReturnGlobalVariable",
					{ value = tonumber(ElectricalPanelPuzzleUI.layout.content[6].props.text), player = self, variable = "ElectricalPanelPuzzle" })
				ElectricalPanelPuzzleUI:destroy()
				ElecPanPuzzle={}
				I.UI.removeMode(I.UI.MODE.Interface)
			end

			if ElecPanPuzzle[4] then
				ElecPanPuzzle[5]=1
				ambient.playSound("Button1")
				ElectricalPanelPuzzleUI.layout.content[10].props.relativePosition=ElectricalPanelPuzzleUI.layout.content[1].props.relativePosition
				if ElecPanPuzzle[4]==1 then
					ElectricalPanelPuzzleUI.layout.content[10].props.color=Colors.Red
				else
					ElectricalPanelPuzzleUI.layout.content[10].props.color=Colors.Blue
				end
				ElectricalPanelPuzzleUI.layout.content[1].props.visible=false
				ElectricalPanelPuzzleUI.layout.content[6].props.text=tostring(ElectricalPanelPuzzleUI.layout.content[5].props.text+(ElecPanPuzzle[4]*15*4))
			elseif ElecPanPuzzle[3] then
				ElecPanPuzzle[4]=1
				ambient.playSound("Button1")
				ElectricalPanelPuzzleUI.layout.content[9].props.relativePosition=ElectricalPanelPuzzleUI.layout.content[1].props.relativePosition
				if ElecPanPuzzle[3]==1 then
					ElectricalPanelPuzzleUI.layout.content[9].props.color=Colors.Red
				else
					ElectricalPanelPuzzleUI.layout.content[9].props.color=Colors.Blue
				end
				ElectricalPanelPuzzleUI.layout.content[1].props.relativePosition=util.vector2(25/36, 12/28)
				ElectricalPanelPuzzleUI.layout.content[5].props.text=tostring(ElectricalPanelPuzzleUI.layout.content[4].props.text+(ElecPanPuzzle[3]*5*3))
			elseif ElecPanPuzzle[2] then
				ElecPanPuzzle[3]=1
				ambient.playSound("Button1")
				ElectricalPanelPuzzleUI.layout.content[8].props.relativePosition=ElectricalPanelPuzzleUI.layout.content[1].props.relativePosition
				if ElecPanPuzzle[2]==1 then
					ElectricalPanelPuzzleUI.layout.content[8].props.color=Colors.Red
				else
					ElectricalPanelPuzzleUI.layout.content[8].props.color=Colors.Blue
				end
				ElectricalPanelPuzzleUI.layout.content[1].props.relativePosition=util.vector2(16/32, 12/28)
				ElectricalPanelPuzzleUI.layout.content[4].props.text=tostring(ElectricalPanelPuzzleUI.layout.content[3].props.text+(ElecPanPuzzle[2]*15*2))
			elseif ElecPanPuzzle[1] then
				ElecPanPuzzle[2]=1
				ambient.playSound("Button1")
				ElectricalPanelPuzzleUI.layout.content[7].props.relativePosition=ElectricalPanelPuzzleUI.layout.content[1].props.relativePosition
				if ElecPanPuzzle[1]==1 then
					ElectricalPanelPuzzleUI.layout.content[7].props.color=Colors.Red
				else
					ElectricalPanelPuzzleUI.layout.content[7].props.color=Colors.Blue
				end
				ElectricalPanelPuzzleUI.layout.content[1].props.relativePosition=util.vector2(11/31, 12/28)
				ElectricalPanelPuzzleUI.layout.content[3].props.text=tostring(ElectricalPanelPuzzleUI.layout.content[2].props.text+(ElecPanPuzzle[1]*5))
			end
			ElectricalPanelPuzzleUI:update()
		end

	end



	if MenuYesNo and MenuYesNo.layout then
		if TurnRight(0.2) == true and MenuSelectStop == false  then
			MenuSelectStop = true
			MenuYesNoLayout.content[1].props.visible = false
			MenuYesNoLayout.content[3].props.visible = true
			MenuYesNo:update()
			ambient.playSound("Cursor")
		elseif TurnLeft(-0.2) == true and MenuSelectStop == false  then
			MenuSelectStop = true
			MenuYesNoLayout.content[1].props.visible = true
			MenuYesNoLayout.content[3].props.visible = false
			MenuYesNo:update()
			ambient.playSound("Cursor")
		end
		if input.isActionPressed(input.ACTION.Use) == true and ToggleUseButton == true then
			ToggleUseButton=false
			if MenuYesNoLayout.content[1].props.visible == true then
				core.sendGlobalEvent("ReturnLocalScriptVariable",
					{ value = 1, Player = self, GameObject = MWscriptGameObject, Variable = "choiceYesNo" })
					ambient.playSound("REdecide")
			else
				core.sendGlobalEvent("ReturnLocalScriptVariable",
					{ value = 2, Player = self, GameObject = MWscriptGameObject, Variable = "choiceYesNo" })
					ambient.playSound("RECancel")
			end
			I.UI.removeMode(I.UI.MODE.Interface)
			MenuYesNo:destroy()
			MWscriptGameObject = nil
		end
	end


	if MenuSelection and MenuSelection.layout then
		if TurnRight(0.2) == true and MenuSelectStop == false then
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
		elseif TurnLeft(-0.2) == true and MenuSelectStop == false then
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
		if input.isActionPressed(input.ACTION.Use) == true and ToggleUseButton == true then
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




	if Menu15 and Menu15.layout then
		if TurnRight(0.2) == true and MenuSelectStop == false then
			MenuSelectStop = true
			for i, content in ipairs(Menu15Layout.content) do
				if i % 2 == 1 and Menu15Layout.content[i + 2] and content.props.visible == true then
					content.props.visible = false
					Menu15Layout.content[i + 2].props.visible = true
					Menu15:update()
					ambient.playSound("Cursor")
					break
				end
			end
		elseif TurnLeft(-0.2) == true and MenuSelectStop == false then
			MenuSelectStop = true
			for i, content in ipairs(Menu15Layout.content) do
				if i % 2 == 1 and i >= 3 and content.props.visible == true then
					content.props.visible = false
					Menu15Layout.content[i - 2].props.visible = true
					Menu15:update()
					ambient.playSound("Cursor")
					break
				end
			end
		end
		if input.isActionPressed(input.ACTION.Use) == true and ToggleUseButton == true then
			ToggleUseButton=false
			for i, content in ipairs(Menu15Layout.content) do
				if i % 2 == 1 and content.props.visible == true then
					print((math.ceil(i / 2)))
					print(self)
					print(MWscriptGameObject)
					core.sendGlobalEvent("ReturnLocalScriptVariable",
						{
							value = (math.ceil(i / 2)),
							Player = self,
							GameObject = MWscriptGameObject,
							Variable =
							"Choice1-5"
						})
					ambient.playSound("REdecide")
				end
			end
			I.UI.removeMode(I.UI.MODE.Interface)
			Menu15:destroy()
			MWscriptGameObject = nil
		end
	end
	--print("MenuSelectStop "..tostring(MenuSelectStop))
	--print("ToggleUseButton "..tostring(ToggleUseButton))
	--print(input.isActionPressed(input.ACTION.Use))
	if I.UI.getMode() then
		if MoveBackward(0.2) == nil and MoveForward(-0.2) == nil and TurnLeft(-0.2) == nil and TurnRight(0.2) == nil and MenuSelectStop == true then
			MenuSelectStop = false
		end
		if ToggleUseButton == false and input.isActionPressed(input.ACTION.Use) == false then
			ToggleUseButton = true
		end
	elseif ToggleUseButton==true and I.UI.getMode()==nil and input.isActionPressed(input.ACTION.Use) == false then
		ToggleUseButton = false
	end


	
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

end



return func_table
