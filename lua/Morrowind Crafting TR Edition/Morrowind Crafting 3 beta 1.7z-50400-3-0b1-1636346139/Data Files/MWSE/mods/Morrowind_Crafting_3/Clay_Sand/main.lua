--[[ Scripting clay, sand harvesting from claybank & sandbar
	part of Morrowind Crafting 3
	Toccatta and Drac  c/r 2019 ]]--

local mc = require("Morrowind_Crafting_3.mc_common")
local skillModule = require("OtherSkills.skillModule")
local configPath = "Morrowind_Crafting_3"
local config = mwse.loadConfig(configPath)

local this = {}
local currentKit, itemID, skillID, itemObject, material, deposit
local skillValue, labelText, numberMaterial, menu

-- initializations
function this.init()
	this.id_menu = tes3ui.registerID("sand_clay_menu")
	this.id_button1 = tes3ui.registerID("sand_clay_gather_button")
	this.id_button2 = tes3ui.registerID("sand_clay_fastgather_button")
	this.id_button3 = tes3ui.registerID("sand_clay_cancel_button")
end



function this.onCancel(e)
	local menu = tes3ui.findMenu(this.id_menu)
	if (menu) then
		tes3ui.leaveMenuMode()
		menu:destroy()
	end
end

function this.onFastGather()
	local config = mwse.loadConfig(configPath)
	local materialCap = 10000
	local gathered = 0
	local loopStatus = false -- Becomes true when the deposit fouls
	repeat
		skillValue = mc.fetchSkill(skillID)
		if config.casualmode == true then
			materialCap = 20
		end
		if material == "Clay" then
			itemObject.context.clay = itemObject.context.clay + 1
			numberMaterial = itemObject.context.clay
		else
			itemObject.context.sand = itemObject.context.sand + 1
			numberMaterial = itemObject.context.sand
		end
		tes3.addItem({ reference = tes3.player, item = "mc_"..string.lower(material), count = 1, playSound = false })
		gathered = gathered + 1
		if (mc.skillCheck(skillID, numberMaterial * 5) == true) and (numberMaterial < materialCap) then
			if skillValue < 30 then
				mc.skillReward(skillID, skillValue, numberMaterial * 5)
			end
		else -- skillcheck failed.. end of this run
			itemObject.context.state = 4
			tes3.playSound{ sound = "enchant fail", volume = 1.0, pitch = 1.0 }
			timer.delayOneFrame(function()
				tes3.setGlobal("mc_skill_results", -1)
			end)
			loopStatus = true
			tes3.messageBox({ message = "You managed to collect "..gathered.." samples of "..
			string.lower(material).."." })
			menu:destroy()
			tes3ui.leaveMenuMode()
			return false
		end
	until(loopStatus == true)
end
	
function this.onGather()
	local config = mwse.loadConfig(configPath)
	local materialCap = 10000
	skillValue = mc.fetchSkill(skillID)
	if config.casualmode == true then
		materialCap = 20
	end
	if material == "Clay" then
		itemObject.context.clay = itemObject.context.clay + 1
		numberMaterial = itemObject.context.clay
	else
		itemObject.context.sand = itemObject.context.sand + 1
		numberMaterial = itemObject.context.sand
	end
	tes3.addItem({ reference = tes3.player, item = "mc_"..string.lower(material), count = 1, playSound = false })
	if (mc.skillCheck(skillID, numberMaterial * 5) == true) and (numberMaterial < materialCap) then
		if skillValue < 30 then
			mc.skillReward(skillID, skillValue, numberMaterial * config.learningcurve)
		end
		tes3.playSound{ sound = "enchant success", volume = 1.0, pitch = 1.0 }
		menu:destroy()
		this.createWindow()
	else -- failed skillcheck! Kill the deposit!
		tes3.playSound{ sound = "enchant fail", volume = 1.0, pitch = 1.0 }
		itemObject.context.state = 4
		timer.delayOneFrame(function()
			tes3.setGlobal("mc_skill_results", -1)
		end)
		menu:destroy()
		tes3ui.leaveMenuMode()
		return false
	end
end

-- Established that is claybank or sandbar, and unfouled. Check amount previously gathered & allow to gather more if wanted
-- create window & buttons
function this.createWindow()
	-- Return if window is already open
    if (tes3ui.findMenu(this.id_menu) ~= nil) then
        return
    end
	skillID = "mc_Crafting"
	skillValue = mc.fetchSkill(skillID)

	if material == "Clay" then
		numberMaterial = itemObject.context.clay
	elseif material == "Sand" then
		numberMaterial = itemObject.context.sand
	else
		mwse.log("material designation error, clay or sandbank")
	end
	if numberMaterial == 0 then
		labelText = "You see an undisturbed deposit of "..string.lower(material).."."
	elseif numberMaterial == 1 then
		labelText = "You see a disturbed spot where you have previously collected "..string.lower(material).."."
	else
		labelText = "You see "..numberMaterial.." disturbed spots where you have previously gathered "..string.lower(material).."."
	end
	if skillValue >= 30 then
		labelText = labelText.." Your skill is high enough that you can no longer learn "..
		"anything more from collecting "..string.lower(material)..". "
	end
		labelText = labelText.." Would you like to:"
	menu = tes3ui.createMenu{ id = this.id_menu, fixedFrame = true }
	menu.width = 320
	menu.height = 300
	menu.minWidth = 320
	menu.minHeight = 70
	menu.positionX = menu.width / -2
	menu.positionY = menu.height / 2
	menu.widthProportional = true
	menu.flowDirection = "top_to_bottom"
	local label = menu:createLabel{ text = labelText }
	label.autoHeight = true
	label.wrapText = true
	label.justifyText = "center"
	label.width = 250
	local buttonBlock = menu:createBlock{}
	buttonBlock.widthProportional = 1.0
	buttonBlock.autoHeight = true
	buttonBlock.childAlignX = 0.5
	local button_1 = buttonBlock:createButton{ id = this.id_button1, text = "Gather "..material }
	local button_2 = buttonBlock:createButton{ id = this.id_button2, text = "Fast Gather" }
	local button_3 = buttonBlock:createButton{ id = this.id_button3, text = tes3.findGMST("sCancel").value  }
	-- Events
	button_3:register("mouseClick", this.onCancel)
	button_2:register("mouseClick", this.onFastGather)
	button_1:register("mouseClick", this.onGather)
	
	menu:updateLayout()
	tes3ui.enterMenuMode(this.id_menu)
end
event.register("initialized", this.init)

local function checkHarvest(e)
	itemID = ""
	numberMaterial = 0
	skillValue = 0
	labelText = ""
	--thing = nil
	itemID = itemObject.id
	--thing = tes3.getReference(itemObject.id).context
	--thing = itemObject.context
	if itemID == "mc_claybank" then
		material = "Clay"
		deposit = "claybank"
	elseif itemID == "mc_sandbar" then
		material = "Sand"
		deposit = "sandbar"
	end
end
	
local function onActivate(e)
	if (e.activator == tes3.player) then
		itemID = e.target.object.id
		if (itemID == "mc_claybank") or (itemID == "mc_sandbar") then
			if not tes3.menuMode() then
				itemObject = e.target
			end
			checkHarvest()
			this.createWindow()
			return false
		end
    end
end

event.register("activate", onActivate)