local modName = "Morrowind Reading"

local configModule = require("MorrowindReading.config")
local config = configModule.current
local defaultConfig = configModule.default
local configPath = configModule.path

local saveDataKey = "MorrowindReading"

local function getReadBooks()
    if not tes3.player then
        return {}
    end

    local data = tes3.player.data[saveDataKey] or {}
    return data.readBooks or {}
end

local function countReadBooks()
    local count = 0

    for _ in pairs(getReadBooks()) do
        count = count + 1
    end

    return count
end

local function resetReadBooks()
    if not tes3.player then
        return
    end

    tes3.player.data[saveDataKey] = {
        readBooks = {}
    }

    tes3.messageBox("Morrowind Reading: read book list reset for this save.")
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate({
        name = modName,
        config = config,
        defaultConfig = defaultConfig,
        showDefaultSetting = true,
    })

    local page = template:createSideBarPage({
        label = "Settings",
        description =
            "Morrowind Reading\n\n" ..
            "Tracks books you have opened and shows whether books are Read or Unread in tooltips.",
    })

    page:createYesNoButton({
        label = "Enable Morrowind Reading",
        configKey = "enabled",
        description = "Turns the book read tracker on or off.",
    })

    page:createYesNoButton({
        label = "Show Tooltip Status",
        configKey = "showTooltipStatus",
        description = "Shows Read/Unread status when hovering over books.",
    })

	page:createYesNoButton({
		label = "Allow Reading From List",
		configKey = "allowReadingFromList",
		description = "If enabled, clicking a book in the read list opens a read-only viewer for that book.",
	})

	page:createYesNoButton({
		label = "Add Scrolls to Reading List",
		configKey = "addScrollsToReadingList",
		description = "If enabled, scrolls you open will be added to the read list.",
	})

	page:createYesNoButton({
		label = "Show Translated Scroll Text",
		configKey = "showTranslatedScrollText",
		description = "If enabled, scroll text can be shown in the read-list viewer. If disabled, scrolls show as unintelligible.",
	})

    page:createButton({
        buttonText = "Reset Read Books",
        inGameOnly = true,
        description = "Clears the saved read book list for this save.",
        callback = resetReadBooks,
    })

    template:saveOnClose(configPath, config)
    template:register()
end

event.register(tes3.event.modConfigReady, registerModConfig)