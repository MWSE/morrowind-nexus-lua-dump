local mod = { name = "Infectious Gutters", ver = "1.0" }
local cf = require("AU.Infectious Gutters.config")

local myTimer

local function getCells()
	local list = {}
	for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
		-- for _,cell in pairs(tes3.dataHandler.nonDynamicData.spells) do
		-- if (cell.isOrBehavesAsExterior == true and cell.restingIsIllegal == false) then
		--    if cell.castType == 3 then
		if string.find(cell.id:lower(), "canal") or string.find(cell.id:lower(), "underwor") or string.find(cell.id:lower(), "sewer") then
			table.insert(list, cell.id)
		end
	end
	table.sort(list)
	return list
end

local function getSpells()
	local list = {}
	local namelist = {}
	for _, spell in pairs(tes3.dataHandler.nonDynamicData.spells) do
		-- for _,cell in pairs(tes3.dataHandler.nonDynamicData.spells) do
		-- if (cell.isOrBehavesAsExterior == true and cell.restingIsIllegal == false) then
		if cf.blocked[spell.id] then
			-- if string.find(cell.id:lower(), "canalw") or string.find(cell.id:lower(), "underwor") or string.find(cell.id:lower(), "sewer" or string.find(cell.id:lower(), "swamp")) then
			table.insert(list, spell.id)
			table.insert(namelist, spell.name)
		end
	end

	table.sort(list)
	table.sort(namelist)
	return list, namelist
end

local function playerSpells()
	local list = {}
	for _, spell in pairs(tes3.mobilePlayer.object.spells) do
		if spell.castType == 3 then
			table.insert(list, spell.id)
		end
	end
	return list
end

local function diseaseMyTimer()
	-- tes3.messageBox("debug timer")
	local disease, diseaseName = getSpells()
	local playerDiseases = playerSpells()
	local r = math.random(0, 99)
	local p = math.random(1, 99)
	if tes3.mobilePlayer.isSwimming then
		r = math.clamp(r / 1.5, 1, 100)
	end
	local resistDisease = tes3.mobilePlayer.resistCommonDisease
	-- tes3.messageBox("Random : %d", r)
	-- tes3.messageBox("Resist : %d", resistDisease)
	if ((r < cf.sliderpercent) and (p > resistDisease)) then
		local oops = table.choice(disease)
		-- tes3.messageBox("%s", oops)
		if table.find(playerDiseases, oops) then
			return
		else
			tes3.addSpell({ reference = tes3.player, spell = oops })
			if cf.onOff then
				tes3.messageBox("You have been infected by %s.", diseaseName[table.find(disease, oops)])
			end
		end
	end
end

local function sewerCheck()
	if myTimer then
		myTimer:cancel()
		myTimer = nil
	end

	local cell = tes3.mobilePlayer.cell
	local celllist = getCells()
	if ((not table.find(celllist, cell.id)) or (cf.cells[cell.id])) then
		return
	else
		myTimer = timer.start({ duration = cf.slider, callback = diseaseMyTimer, iterations = -1 })
	end
end
event.register("cellChanged", sewerCheck)

local function getExclusionList()
	local list = {}
	-- for _,spell in pairs(tes3.dataHandler.nonDynamicData.spells) do\
	---@param spell tes3spell
	for spell in tes3.iterateObjects(tes3.objectType.spell) do
		if (spell.castType == tes3.spellType.disease or spell.castType == tes3.spellType.blight) then
			table.insert(list, spell.id)
		end
	end
	table.sort(list)
	return list
end

local function registerModConfig()
	local template = mwse.mcm.createTemplate(mod.name)
	template:saveOnClose(mod.name, cf)
	template:register()

	local page = template:createSideBarPage({ label = "\"" .. mod.name .. "\" Settings" })
	page.sidebar:createInfo{ text = "Welcome to " .. mod.name .. " Configuration Menu.\n\nMod revised by:" }
	page.sidebar:createHyperLink{ text = "ActuallyUlysses", url = "https://www.nexusmods.com/users/27648985?tab=user+files" }
	page.sidebar:createInfo{ text = "\nOriginal mod and lua code by:" }
	page.sidebar:createHyperLink{ text = "Spammer21", url = "https://www.nexusmods.com/users/140139148?tab=user+files" }
	page.sidebar:createInfo{ text = "\nChecked and corrected by:" }
	page.sidebar:createHyperLink{ text = "JosephMcKean", url = "https://www.nexusmods.com/users/147999863?tab=user+files" }
	page.sidebar:createInfo{ text = "\nHow mod works?\n\nOnce a sewer is entered, the player's character must make a first roll, which is then compared to the value given on the \"Chance to get a disease\" slider. If the roll result is lower than the given value, a second roll is made against the character's current Common Disease Resistance. If the roll result is higher than the resistance value, then the character becomes infected with a random disease from \"Catchable Diseases\" table. If the player's character is submerged in water, their chance of contracting a disease is higher.\n\nNote: it is not advised to use this mod with original Infectious Sewers - MWSE. They do the same thing." }


	local category = page:createCategory("Show message:")
	category:createOnOffButton{
		label = "On/Off",
		description = "If set to ON, the message informing you that you caught the disease will appear. [Default: ON]",
		variable = mwse.mcm.createTableVariable { id = "onOff", table = cf },
	}

	-- category:createKeyBinder{label = " ", description = " ", allowCombinations = false, variable = mwse.mcm.createTableVariable{id = "key", table = cf, restartRequired = true, defaultSetting = {keyCode = tes3.scanCode.l, isShiftDown = false, isAltDown = false, isControlDown = false}}}

	-- local category1 = page:createCategory(" ")
	--[[local elementGroup = category1:createCategory("")
    elementGroup:createDropdown { description = " ",
        options  = {
            { label = " ", value = 0 },
            { label = " ", value = 1 },
            { label = " ", value = 2 },
            { label = " ", value = 3 },
            { label = " ", value = 4 },
            { label = " ", value = -1 }
        },
        variable = mwse.mcm:createTableVariable {
            id    = "dropDown",
            table = cf
        }
    }]]

	local category2 = page:createCategory("Chance to get a disease:")
	local subcat = category2:createCategory("")
	subcat:createSlider{
		label = "Delay between checks",
		description = "You can choose how much time (in seconds) will elapse before the script tries once more to infect you. [Default: 30]",
		min = 0,
		max = 60,
		step = 1,
		jump = 1,
		variable = mwse.mcm.createTableVariable { id = "slider", table = cf },
	}

	subcat:createSlider{
		label = "Chance: " .. "%s%%",
		description = "Here you can choose the odds to get a disease by wandering the sewers. [Default:30]",
		min = 0,
		max = 100,
		step = 1,
		jump = 10,
		variable = mwse.mcm.createTableVariable { id = "sliderpercent", table = cf },
	}

	template:createExclusionsPage{
		label = "Diseases",
		leftListLabel = "Catchable Diseases",
		rightListLabel = "Diseases",
		description = "Here you can choose which disease you can contract by wandering the sewers.",
		variable = mwse.mcm.createTableVariable { id = "blocked", table = cf },
		filters = { { label = "Diseases", callback = getExclusionList } },
	}

	template:createExclusionsPage{
		label = "Cells",
		description = "Here you can blacklist certain cells so that you can't catch a disease if you're in them.",
		variable = mwse.mcm.createTableVariable { id = "cells", table = cf },
		filters = { { label = "Cells", callback = getCells } },
	}
end
event.register("modConfigReady", registerModConfig)

local function initialized()
	print("[" .. mod.name .. ", by Spammer] " .. mod.ver .. " Initialized!")
end
event.register("initialized", initialized)

