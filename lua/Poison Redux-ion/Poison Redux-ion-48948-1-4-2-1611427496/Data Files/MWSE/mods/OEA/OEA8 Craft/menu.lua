local Naming = tes3ui.registerID("OEA8_Potion_Name_Block")
local TextBlock = tes3ui.registerID("OEA8_Acquire_Text")
local Menu = tes3ui.registerID("OEA8_Fabricated_Menu")
local Text
local SubName

local H = {}

local function OnClick(e)
	e.source:forwardEvent(e)
	if (Text ~= nil) and (SubName ~= nil) then
		if (tes3.player.data.OEA8 == nil) then
			tes3.player.data.OEA8 = {}
		end
		tes3.player.data.OEA8[69] = Text.text
		--mwse.log("[OEA8] The text should be %s", Text.text)

		local Magic = tes3ui.findMenu(tes3ui.registerID("MenuMagic"))
		local Map = tes3ui.findMenu(tes3ui.registerID("MenuMap"))
		local Stuff = tes3ui.findMenu(tes3ui.registerID("MenuInventory"))
		local Stat = tes3ui.findMenu(tes3ui.registerID("MenuStat"))

		Magic:destroy()
		Map:destroy()
		Stuff:destroy()
		Stat:destroy()
		SubName:destroy()
		tes3ui.leaveMenuMode(SubName)
		SubName = nil
		Text = nil
	end
end

function H.CreateMenu()
	if (tes3.player.data.OEA8 == nil) or (tes3.player.data.OEA8[4] == nil) or (tes3.player.data.OEA8[4] ~= 20) then
		return
	end

	SubName = tes3ui.createMenu{
		id = Menu,
		dragFrame = false,
		fixedFrame = true
	}
    	SubName.autoWidth = true
    	SubName.autoHeight = true

	local OuterBlock = SubName:createBlock{ id = Naming }
	OuterBlock.flowDirection = "top-to-bottom"
    	OuterBlock.autoWidth = true
    	OuterBlock.autoHeight = true

	Text = OuterBlock:createTextInput{ id = TextBlock }
    	Text.autoWidth = true
    	Text.autoHeight = true
	Text.borderAllSides = 10

	local Button = OuterBlock:createButton{ id = nil }
    	Button.autoWidth = true
    	Button.autoHeight = true
	Button.text = "Done"
	Button:register("mouseClick", OnClick)

	SubName:updateLayout()

	tes3ui.acquireTextInput(Text)
end

local function KeyDown(e)
	if (e.keyCode == 28) then
		if (Text ~= nil) and (SubName ~= nil) then
			if (tes3.player.data.OEA8 == nil) then
				tes3.player.data.OEA8 = {}
			end
			tes3.player.data.OEA8[69] = Text.text
			--mwse.log("[OEA8] The text should be %s", Text.text)

			local Magic = tes3ui.findMenu(tes3ui.registerID("MenuMagic"))
			local Map = tes3ui.findMenu(tes3ui.registerID("MenuMap"))
			local Stuff = tes3ui.findMenu(tes3ui.registerID("MenuInventory"))
			local Stat = tes3ui.findMenu(tes3ui.registerID("MenuStat"))

			Magic:destroy()
			Map:destroy()
			Stuff:destroy()
			Stat:destroy()
			SubName:destroy()
			tes3ui.leaveMenuMode(SubName)
			SubName = nil
			Text = nil
			return false
		end
	end
end
event.register("keyDown", KeyDown, { priorty = 100000 })

return H