local config = require("OEA.OEA10 Fresh.config")
local health = require("OEA.OEA10 Fresh.health")

local CNconfig
if tes3.getFileExists("MWSE\\mods\\OEA\\OEA3 Prices\\main.lua") then
	if tes3.getFileExists("MWSE\\mods\\OEA\\OEA3 Prices\\config.lua") then
		CNconfig = require("OEA.OEA3 Prices.config")
	end
end

local H = {}

local millions
local hundredThousands
local tenThousands
local thousands
local hundreds
local tens
local ones

local block

function H.forwardBlock(thing)
	block = thing
end

--I really wanted compatibility with Caveat Nerevar, it being a mod about money made by me. This applies its formula to all costs, but only to door costs once (since you pay them many times).
function H.Caveat(cost)
	if (CNconfig ~= nil) and (cost > (10 * CNconfig.Y2)) and (CNconfig.TurnedOn == true) then
		if (tes3.player.data.OEA10.doorFirstTime == nil) or (tes3.player.data.OEA10.doorFirstTime == 1) then
			if (CNconfig.Logarithm == true) then
				cost = (CNconfig.X1) * (cost / math.log(cost / CNconfig.Y2))
				cost = math.floor(cost)
				if (cost < 1) then
					cost = 1
				end
			elseif (CNconfig.Logarithm == false) then
				cost = (CNconfig.X1) * (cost / math.log10(cost / CNconfig.Y2))
				cost = math.floor(cost)
				if (cost < 1) then
					cost = 1
				end
			end
		end
	end
	return cost
end

local function updateText()
	local MenuID = tes3ui.registerID("OEA10_Menu")
	local menu = tes3ui.findMenu(MenuID)
	if (menu == nil) then
		return
	end

	local LID = tes3ui.registerID("OEA10_Label")
	local label = menu:findChild(LID)
	if (label == nil) then
		return
	end

    	label.autoWidth = true
    	label.autoHeight = true
	label.widthProportional = 1
	label.heightProportional = 1
	label.wrapText = true
	label.justifyText = "right"
	label.font = 1

	if (tes3.player.data.OEA10.menuNumber == nil) then
		tes3.player.data.OEA10.menuNumber = 0
	end
	label.text = tostring(tes3.player.data.OEA10.menuNumber)
end

local function calcNumber()
	local number = (1000000 * millions) + (100000 * hundredThousands) + (10000 * tenThousands) + (1000 * thousands) + (100 * hundreds) + (10 * tens) + ones
	return number
end

local function changeNumber(choice)
	millions = hundredThousands
	hundredThousands = tenThousands
	tenThousands = thousands
	thousands = hundreds
	hundreds = tens
	tens = ones
	ones = choice

	tes3.player.data.OEA10.menuNumber = calcNumber()
	updateText()
end

local reward

local function Callback(e)
	local MenuID = tes3ui.registerID("OEA10_Menu")
	local menu = tes3ui.findMenu(MenuID)

	tes3ui.leaveMenuMode(menu)

	if (reward ~= nil) then
		tes3.messageBox(("[Caveat Nerevar] After economic adjustment, you only receive %s Gold."):format(reward))
		reward = nil
	end
end

local function ExitingMenu(giving, cost)
	local MenuID = tes3ui.registerID("OEA10_Menu")
	local menu = tes3ui.findMenu(MenuID)
	menu:destroy()

	if (giving == true) then
		if (tes3.player.data.OEA10.menuNumber >= cost) then
			tes3.messageBox({
				message = "You stare into a pair of cold, dark eyes. Awash in the glow of your mighty septims, they too light aflame, filled with the incomparable joy of greed fulfilled.",
				buttons = { "Okay" },
				callback = Callback
			})
			tes3.removeItem({ reference = tes3.player, item = "Gold_001", count = tes3.player.data.OEA10.menuNumber })
			tes3.playSound({ sound = "Item Gold Up" })

			if (tes3.player.data.OEA10.reClick ~= nil) and (block ~= nil) then
				block:triggerEvent("mouseClick")
				block = nil

				if (config.Money == true) then
					health.updateMenuMulti()
				end
			end
		else
			tes3.messageBox({
				message = "You stare into a pair of cold, dark eyes. Hope brightens them for a moment, but the flame is promptly extinguished, cooled to a dull resentment of your patronizing offer.",
				buttons = { "Okay" },
				callback = Callback
			})

--since mercenaries would be using dialogue boxes i wanted shifted anyway, i figured this was the best way to make only them not take your money. so try not to set messageTime in other such spots please
			if (tes3.player.data.OEA10.messageTime == nil) or (tes3.player.data.OEA10.messageTime == 0) then
				tes3.removeItem({ reference = tes3.player, item = "Gold_001", count = tes3.player.data.OEA10.menuNumber })
				tes3.playSound({ sound = "Item Gold Up" })
			end

			tes3.player.data.OEA10.messageTime = 0

			if (tes3.player.data.OEA10.reClick ~= nil) and (block ~= nil) then
				tes3.player.data.OEA10.reClick = nil
				block = nil
				tes3ui.showDialogueMessage({ text = " " })
				tes3ui.showDialogueMessage({ text = "For that paltry sum, I don't think I'll be telling you a word." })

				if (config.Money == true) then
					health.updateMenuMulti()
				end
			end
		end
	elseif (giving == false) then
		if (tes3.player.data.OEA10.menuNumber <= cost) then
			tes3.messageBox({
				message = "You stare into a pair of cold, dark eyes. In their corners you can see traces of a mischievous grin, the suppressed excitement of a successful hornswoggler.",
				buttons = { "Okay" },
				callback = Callback
			})
			tes3.addItem({ reference = tes3.player, item = "Gold_001", count = tes3.player.data.OEA10.menuNumber })
			tes3.playSound({ sound = "Item Gold Up" })

			tes3ui.showDialogueMessage({ text = " " })
			tes3ui.showDialogueMessage({ text = ("I am glad to see that I was right about you and your gullib--err, honor. Here's your %s gold, as promised."):format(tes3.player.data.OEA10.menuNumber) })

			if (CNconfig ~= nil) and (CNconfig.TurnedOn == true) and (CNconfig.Dialogue == true) then
				reward = H.Caveat(tes3.player.data.OEA10.menuNumber)
				tes3.removeItem({ reference = tes3.player, item = "Gold_001", count = (tes3.player.data.OEA10.menuNumber - reward) })
				tes3.player.data.OEA10.menuNumber = reward
			end

			if (config.Money == true) then
				health.updateMenuMulti()
			end
		elseif	(tes3.player.data.OEA10.menuNumber > cost) then
			tes3.messageBox({
				message = "You stare into a pair of cold, dark eyes. Jumping at the realization that you have erred in exposing your full greed, they pounce, ready to deny you every last septim.",
				buttons = { "Okay" },
				callback = Callback
			})
			tes3.addItem({ reference = tes3.player, item = "Gold_001", count = 1 })
			tes3.playSound({ sound = "Item Gold Up" })

			tes3ui.showDialogueMessage({ text = " " })
			tes3ui.showDialogueMessage({ text = "Hmph. It looks like I shouldn't have trusted you after all." })

			if (config.Money == true) then
				health.updateMenuMulti()
			end
		end
	end		

	--mwse.log("[OEA10] Giving is %s, cost is %s", giving, cost)
end

local function OnClickN0(e)
	e.source:forwardEvent(e)

	local choice = 0
	changeNumber(choice)
end

local function OnClickN1(e)
	e.source:forwardEvent(e)

	local choice = 1
	changeNumber(choice)
end

local function OnClickN2(e)
	e.source:forwardEvent(e)

	local choice = 2
	changeNumber(choice)
end

local function OnClickN3(e)
	e.source:forwardEvent(e)

	local choice = 3
	changeNumber(choice)
end

local function OnClickN4(e)
	e.source:forwardEvent(e)

	local choice = 4
	changeNumber(choice)
end

local function OnClickN5(e)
	e.source:forwardEvent(e)

	local choice = 5
	changeNumber(choice)
end

local function OnClickN6(e)
	e.source:forwardEvent(e)

	local choice = 6
	changeNumber(choice)
end

local function OnClickN7(e)
	e.source:forwardEvent(e)

	local choice = 7
	changeNumber(choice)
end

local function OnClickN8(e)
	e.source:forwardEvent(e)

	local choice = 8
	changeNumber(choice)
end

local function OnClickN9(e)
	e.source:forwardEvent(e)

	local choice = 9
	changeNumber(choice)
end

local function OnOkayClick(e, data)
	e.source:forwardEvent(e)

	local giving = data.givingCheck
	local cost = data.costForward

	if (tes3.player.data.OEA10.menuNumber >= mwscript.getItemCount({ reference = tes3.player, item = "Gold_001" })) then
		if (giving == true) then
			tes3.messageBox("You do not have enough septims to complete this transaction.")
			return
		end
	end

	ExitingMenu(giving, cost)
end

local function OnDelClick(e)
	e.source:forwardEvent(e)

	ones = tens
	tens = hundreds
	hundreds = thousands
	thousands = tenThousands
	tenThousands = hundredThousands
	hundredThousands = millions
	millions = 0

	tes3.player.data.OEA10.menuNumber = calcNumber()
	updateText()
end

function H.CreateMenu(giving, cost)
	millions = 0
	hundredThousands = 0
	tenThousands = 0
	thousands = 0
	hundreds = 0
	tens = 0
	ones = 0

	local MenuID = tes3ui.registerID("OEA10_Menu")
	local menu = tes3ui.findMenu(MenuID)
	if (menu == nil) then
		menu = tes3ui.createMenu{
			id = MenuID,
			dragFrame = false,
			fixedFrame = true
		}
	end
	menu.autoWidth = true
	menu.autoHeight = true

	if (tes3.player.data.OEA10 == nil) then
		tes3.player.data.OEA10 = {}
	end

	local LID = tes3ui.registerID("OEA10_Label")
	local label = menu:findChild(LID)
	if (label == nil) then
		label = menu:createLabel{ id = LID, text = "0" }
	end
    	label.autoWidth = true
    	label.autoHeight = true
	label.widthProportional = 1
	label.heightProportional = 1
	label.wrapText = true
	label.justifyText = "right"
	label.font = 1

	tes3.player.data.OEA10.menuNumber = 0
	label.text = tostring(tes3.player.data.OEA10.menuNumber)

	local OBID = tes3ui.registerID("OEA10_OuterBlock")
	local OuterBlock = menu:findChild(OBID)
	if (OuterBlock == nil) then
		OuterBlock = menu:createBlock{ id = OBID }
	end
	OuterBlock.flowDirection = "top_to_bottom"
    	OuterBlock.autoWidth = true
    	OuterBlock.autoHeight = true

	local IB1ID = tes3ui.registerID("OEA10_InnerBlock_1")
	local InnerBlock1 = menu:findChild(IB1ID)
	if (InnerBlock1 == nil) then
		InnerBlock1 = OuterBlock:createBlock{ id = IB1ID }
	end
	InnerBlock1.flowDirection = "left-to-right"
    	InnerBlock1.autoWidth = true
    	InnerBlock1.autoHeight = true

	local N0ID = tes3ui.registerID("OEA10_Number_0")
	local Numbers0 = menu:findChild(N0ID)
	if (Numbers0 == nil) then
		local path0 = "Textures\\OEA\\Numbers 0.tga"
		Numbers0 = InnerBlock1:createImageButton{ id = N0ID, idle = path0, over = path0, pressed = path0 }
	end
	Numbers0.imageScaleX = 1.00
	Numbers0.imageScaleY = 1.00
	Numbers0.borderAllSides = 10
	Numbers0:register("mouseClick", OnClickN0)

	local N1ID = tes3ui.registerID("OEA10_Number_1")
	local Numbers1 = menu:findChild(N1ID)
	if (Numbers1 == nil) then
		local path1 = "Textures\\OEA\\Numbers 1.tga"
		Numbers1 = InnerBlock1:createImageButton{ id = N1ID, idle = path1, over = path1, pressed = path1 }
	end
	Numbers1.imageScaleX = 1.00
	Numbers1.imageScaleY = 1.00
	Numbers1.borderAllSides = 10
	Numbers1:register("mouseClick", OnClickN1)

	local N2ID = tes3ui.registerID("OEA10_Number_2")
	local Numbers2 = menu:findChild(N2ID)
	if (Numbers2 == nil) then
		local path2 = "Textures\\OEA\\Numbers 2.tga"
		Numbers2 = InnerBlock1:createImageButton{ id = N2ID, idle = path2, over = path2, pressed = path2 }
	end
	Numbers2.imageScaleX = 1.00
	Numbers2.imageScaleY = 1.00
	Numbers2.borderAllSides = 10
	Numbers2:register("mouseClick", OnClickN2)

	local N3ID = tes3ui.registerID("OEA10_Number_3")
	local Numbers3 = menu:findChild(N3ID)
	if (Numbers3 == nil) then
		local path3 = "Textures\\OEA\\Numbers 3.tga"
		Numbers3 = InnerBlock1:createImageButton{ id = N3ID, idle = path3, over = path3, pressed = path3 }
	end
	Numbers3.imageScaleX = 1.00
	Numbers3.imageScaleY = 1.00
	Numbers3.borderAllSides = 10
	Numbers3:register("mouseClick", OnClickN3)

	local N4ID = tes3ui.registerID("OEA10_Number_4")
	local Numbers4 = menu:findChild(N4ID)
	if (Numbers4 == nil) then
		local path4 = "Textures\\OEA\\Numbers 4.tga"
		Numbers4 = InnerBlock1:createImageButton{ id = N4ID, idle = path4, over = path4, pressed = path4 }
	end
	Numbers4.imageScaleX = 1.00
	Numbers4.imageScaleY = 1.00
	Numbers4.borderAllSides = 10
	Numbers4:register("mouseClick", OnClickN4)

	local IB2ID = tes3ui.registerID("OEA10_InnerBlock_2")
	local InnerBlock2 = menu:findChild(IB2ID)
	if (InnerBlock2 == nil) then
		InnerBlock2 = OuterBlock:createBlock{ id = IB2ID }
	end
	InnerBlock2.flowDirection = "left_to_right"
    	InnerBlock2.autoWidth = true
    	InnerBlock2.autoHeight = true

	local N5ID = tes3ui.registerID("OEA10_Number_5")
	local Numbers5 = menu:findChild(N5ID)
	if (Numbers5 == nil) then
		local path5 = "Textures\\OEA\\Numbers 5.tga"
		Numbers5 = InnerBlock2:createImageButton{ id = N5ID, idle = path5, over = path5, pressed = path5 }
	end
	Numbers5.imageScaleX = 1.00
	Numbers5.imageScaleY = 1.00
	Numbers5.borderAllSides = 10
	Numbers5:register("mouseClick", OnClickN5)

	local N6ID = tes3ui.registerID("OEA10_Number_6")
	local Numbers6 = menu:findChild(N6ID)
	if (Numbers6 == nil) then
		local path6 = "Textures\\OEA\\Numbers 6.tga"
		Numbers6 = InnerBlock2:createImageButton{ id = N6ID, idle = path6, over = path6, pressed = path6 }
	end
	Numbers6.imageScaleX = 1.00
	Numbers6.imageScaleY = 1.00
	Numbers6.borderAllSides = 10
	Numbers6:register("mouseClick", OnClickN6)

	local N7ID = tes3ui.registerID("OEA10_Number_7")
	local Numbers7 = menu:findChild(N7ID)
	if (Numbers7 == nil) then
		local path7 = "Textures\\OEA\\Numbers 7.tga"
		Numbers7 = InnerBlock2:createImageButton{ id = N7ID, idle = path7, over = path7, pressed = path7 }
	end
	Numbers7.imageScaleX = 1.00
	Numbers7.imageScaleY = 1.00
	Numbers7.borderAllSides = 10
	Numbers7:register("mouseClick", OnClickN7)

	local N8ID = tes3ui.registerID("OEA10_Number_8")
	local Numbers8 = menu:findChild(N8ID)
	if (Numbers8 == nil) then
		local path8 = "Textures\\OEA\\Numbers 8.tga"
		Numbers8 = InnerBlock2:createImageButton{ id = N8ID, idle = path8, over = path8, pressed = path8 }
	end
	Numbers8.imageScaleX = 1.00
	Numbers8.imageScaleY = 1.00
	Numbers8.borderAllSides = 10
	Numbers8:register("mouseClick", OnClickN8)

	local N9ID = tes3ui.registerID("OEA10_Number_9")
	local Numbers9 = menu:findChild(N9ID)
	if (Numbers9 == nil) then
		local path9 = "Textures\\OEA\\Numbers 9.tga"
		Numbers9 = InnerBlock2:createImageButton{ id = N9ID, idle = path9, over = path9, pressed = path9 }
	end
	Numbers9.imageScaleX = 1.00
	Numbers9.imageScaleY = 1.00
	Numbers9.borderAllSides = 10
	Numbers9:register("mouseClick", OnClickN9)


	local BBID = tes3ui.registerID("OEA10_ButtonBlock")
	local ButtonBlock = menu:findChild(BBID)
	if (ButtonBlock == nil) then
		ButtonBlock = menu:createBlock{ id = BBID }
	end
	ButtonBlock.flowDirection = "left-to-right"
    	ButtonBlock.autoWidth = true
    	ButtonBlock.autoHeight = true

	local DBID = tes3ui.registerID("OEA10_DelButton")
	local DelButton = menu:findChild(DBID)
	if (DelButton == nil) then
		DelButton = ButtonBlock:createButton{ id = DBID }
	end
    	DelButton.autoWidth = true
    	DelButton.autoHeight = true
	DelButton.text = "DEL"
	DelButton:register("mouseClick", OnDelClick)

	local OKBID = tes3ui.registerID("OEA10_OkayButton")
	local OkayButton = menu:findChild(OKBID)
	if (OkayButton == nil) then
		OkayButton = ButtonBlock:createButton{ id = OKBID }
	end
    	OkayButton.autoWidth = true
    	OkayButton.autoHeight = true
	OkayButton.borderLeft = 300
	OkayButton.text = "Okay"

	if (giving == true) then
		cost = H.Caveat(cost)
	end

	local data = { givingCheck = giving, costForward = cost }
	OkayButton:register("mouseClick", function(e) OnOkayClick(e, data) end)

	--tes3ui.enterMenuMode(menu)
end

local function KeyDown(e)
	local MenuID = tes3ui.registerID("OEA10_Menu")
	local menu = tes3ui.findMenu(MenuID)

	if (e.keyCode == 28) then --Enter
		if (menu ~= nil) then
			ExitingMenu()
			return false
		--else
			--if (tes3.menuMode() == false) then
				--H.CreateMenu()
			--end
		end
	end

	if (e.keyCode == 14) then --Backspace
		if (menu ~= nil) then
			ones = tens
			tens = hundreds
			hundreds = thousands
			thousands = tenThousands
			tenThousands = hundredThousands
			hundredThousands = millions
			millions = 0

			tes3.player.data.OEA10.menuNumber = calcNumber()
			updateText()
		end
	end
end
event.register("keyDown", KeyDown, { priorty = 100000 })

return H