local config = require("Open the Door.config")
local i18n = require("Open the Door.common").i18n
local mcmConfig = config.getConfig()

local function newline(container)
	container:createInfo({ text = "\n" })
end

local function addDefaultSideBar(container)
    container.sidebar:createInfo({
		text = ("\n\n%s %s!\n\n%s.\n\n"):format(i18n("mcm.welcome"), i18n("mcm.modName"), i18n("mcm.hoverDefault"))
	})
	container.sidebar:createHyperLink({
        text = i18n("mcm.madeBy") .. " C3pa",
        url = "https://www.nexusmods.com/users/37172285?tab=user+files",
        postCreate = function(self)
			self.elements.info.layoutOriginFractionX = 0.5
		end,
    })
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate({
		name = "Open the Door",
		headerImagePath = "MWSE/mods/Open the Door/MCMHeader.tga",
		onClose = function()
			config.saveConfig(mcmConfig)
		end
	})
	template:register()

	local page = template:createSideBarPage({ label = i18n("mcm.settings") })
	addDefaultSideBar(page)

	do -- General settings
		local general = page:createCategory({ label = i18n("mcm.general") .. " " .. i18n("mcm.settings") })
		general:createSlider({
			label = i18n("mcm.minDistance.label") .. ": %s",
			description = ("\n%s.\n\n%s: 225"):format(i18n("mcm.minDistance.description"), i18n("mcm.default")),
			min = 195,
			max = 300,
			step = 5,
			jump = 10,
			variable = mwse.mcm.createTableVariable({ id = "minDistance", table = mcmConfig })
		})

		--[[
		newline(general)
		general:createSlider({
			label = i18n("mcm.delay.label") .. ": %s ms",
			description = ("\n%s.\n\n%s: 0"):format(i18n("mcm.delay.description"), i18n("mcm.default")),
			min = 0,
			max = 1000,
			step = 20,
			jump = 20,
			variable = mwse.mcm.createTableVariable({ id = "delay", table = mcmConfig })
		})]]

		newline(general)
		general:createYesNoButton({
			label = i18n("mcm.loadDoors.label") .. "?",
			description = ("\n%s."):format(i18n("mcm.loadDoors.description")),
			variable = mwse.mcm.createTableVariable({ id = "loadDoors", table = mcmConfig })
		})

		newline(general)
		general:createYesNoButton({
			label = i18n("mcm.interiorDoors.label") .. "?",
			description = ("\n%s."):format(i18n("mcm.interiorDoors.description")),
			variable = mwse.mcm.createTableVariable({ id = "interiorDoors", table = mcmConfig })
		})

		newline(general)
		general:createYesNoButton({
			label = i18n("mcm.barDoors.label") .. "?",
			description = ("\n%s."):format(i18n("mcm.barDoors.description")),
			variable = mwse.mcm.createTableVariable({ id = "barDoors", table = mcmConfig })
		})

		newline(general)
		general:createYesNoButton({
			label = i18n("mcm.skipLocked.label") .. "?",
			description = ("\n%s."):format(i18n("mcm.skipLocked.description")),
			variable = mwse.mcm.createTableVariable({ id = "skipLocked", table = mcmConfig })
		})

		newline(general)
		general:createYesNoButton({
			label = i18n("mcm.skipTrapped.label") .. "?",
			description = ("\n%s."):format(i18n("mcm.skipTrapped.description")),
			variable = mwse.mcm.createTableVariable({ id = "skipTrapped", table = mcmConfig })
		})

		newline(general)
		general:createYesNoButton({
			label = i18n("mcm.showMessages.label") .. "?",
			description = ("\n%s."):format(i18n("mcm.showMessages.description")),
			variable = mwse.mcm.createTableVariable({ id = "showMessages", table = mcmConfig })
		})
	end
	do -- Cooldown settings
		local cooldown = page:createCategory({ label = i18n("mcm.cooldownTitle") .. " " .. i18n("mcm.settings") })

		cooldown:createOnOffButton({
			label = i18n("mcm.useCooldowns.label") .. "?",
			description = ("\n%s."):format(i18n("mcm.useCooldowns.description")),
			variable = mwse.mcm.createTableVariable({ id = "useCooldowns", table = mcmConfig })
		})

		newline(cooldown)
		cooldown:createSlider({
			label = i18n("mcm.cooldown.label") .. ": %s",
			description = ("\n%s.\n\n%s: 5"):format(i18n("mcm.cooldown.description"), i18n("mcm.default")),
			min = 1,
			max = 15,
			step = 1,
			jump = 1,
			variable = mwse.mcm.createTableVariable({ id = "cooldown", table = mcmConfig })
		})

		newline(cooldown)
		cooldown:createYesNoButton({
			label = i18n("mcm.clearOnCellChange.label") .. "?",
			description = ("\n%s."):format(i18n("mcm.clearOnCellChange.description")),
			variable = mwse.mcm.createTableVariable({ id = "clearOnCellChange", table = mcmConfig })
		})
	end
end

event.register(tes3.event.modConfigReady, registerModConfig)
