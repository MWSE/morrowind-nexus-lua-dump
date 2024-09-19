local configPath = "Intruder"
local cfg = {}  -- Initialize the cfg table
---@class Intruder
local defaults = {
    startTrespass = 21,
    endTrespass = 6,
    timerSeconds = 10,
    dispOn = true,
    disposition = 90,
    combat = true,
    playerLevel = true,
    level = 5,
    decreaseDisposition = true,
    dispositionDecrease = 5,
    noWait = true,
    messagesOn = false,
    blacklist = {
        ["Pelagiad, Ahnassi's House"] = true,
        ["Balmora, Caius Cosades' House"] = true,
        ["Ald-ruhn, Guild of Fighters"] = true,
        ["Ald-ruhn, Guild of Mages"] = true,
        ["Balmora, Guild of Fighters"] = true,
        ["Balmora, Guild of Mages"] = true,
        ["Ald-ruhn, Morag Tong Guildhall"] = true,
        ["Balmora, Morag Tong Guild"] = true,
        ["Sadrith Mora, Morag Tong Guild"] = true,
        ["Sadrith Mora: Wolverine Hall: Fighter's Guild"] = true,
        ["Sadrith Mora, Wolverine Hall: Mage's Guild"] = true,
        ["Vivec, Guild of Mages"] = true,
        ["Vivec, Guild of Fighters"] = true
    },
    blacklistNpc = {
        ["Caius Cosades"] = true,
        ["Ahnassi"] = true
    }
}

---@class Intruder
local config = mwse.loadConfig(configPath, defaults)

local function registerModConfig()
    local template = mwse.mcm.createTemplate({
        name = configPath,
        defaultConfig = defaults,
        config = config
    })
    template:saveOnClose(configPath, config)

    local settings = template:createPage({ label = "Settings - Intruder" })
    settings.showReset = true

    settings:createSlider({
        label = "Starting Hour to Begin Trespassing in 24-Hour Clock. Default: 9 pm",
        configKey = "startTrespass",
        min = 18, max = 24, step = 1, jump = 1,
    })

    settings:createSlider({
        label = "Starting Hour to Stop Trespassing in 24-Hour Clock. Default: 6 am",
        configKey = "endTrespass",
        min = 4, max = 10, step = 1, jump = 1,
    })

    settings:createSlider({
        label = "How Many Unpaused Real Time Seconds for Homeowners to Start Combat. Default: 10 Seconds",
        configKey = "timerSeconds",
        min = 5, max = 30, step = 1, jump = 1,
    })

    settings:createYesNoButton({
		label = "Disposition Affects Trespass. Default: Yes",
		configKey = "dispOn"
	})

    settings:createSlider({
        label = "Minimum Disposition for an Actor to Not Become Upset at Trespass. Only Works if Previous Option is Yes. Default: 90",
        configKey = "disposition",
        min = 70, max = 100, step = 1, jump = 1,
    })

    settings:createYesNoButton({
		label = "Allow Combat on Trespass. Default: Yes",
		configKey = "combat"
	})

    settings:createYesNoButton({
		label = "Lower Level Enemies Refrain from Combat. Only Works if Previous Option is Yes. Default: Yes",
		configKey = "playerLevel"
	})

    settings:createSlider({
        label = "Level Difference for Lower Level Enemies to Refrain from Combat. Only Works if Previous Option is Yes. Default: 5",
        configKey = "level",
        min = 1, max = 10, step = 1, jump = 1,
    })

    settings:createYesNoButton({
		label = "Disposition Decrease on Trespass. Default: Yes",
		configKey = "decreaseDisposition"
	})

    settings:createSlider({
        label = "Disposition Decrease Amount. Only Works if Previous Option is Yes. Default: 5",
        configKey = "dispositionDecrease",
        min = 1, max = 20, step = 1, jump = 1,
    })

    settings:createYesNoButton({
		label = "Prevents Waiting and Resting on Trespass. Default: Yes",
		configKey = "noWait"
	})

    settings:createYesNoButton({
		label = "Messages Showing Who Has Witnessed Trespass in Case of Missed Verbal Cues. Default: No",
		configKey = "messagesOn"
	})

    template:createExclusionsPage({
        label = "Excluded Cells",
        configKey = "blacklist",
        filters = {
            { label = "Cells", callback = cfg.getCells }
        },
        showReset = true
    })
    
    template:createExclusionsPage({
        label = "Excluded Npcs",
        configKey = "blacklistNpc",
        filters = {
            { label = "Npcs", callback = cfg.getAllNPCs }
        },
        showReset = true
    })

    template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)

function cfg.getCells()
    local cells = {}
    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        if cell.isInterior then  -- Check if the cell is an interior cell
            table.insert(cells, cell.id)
        end
    end
    table.sort(cells)
    return cells
end

function cfg.getAllNPCs()
    local npcList = {}
    -- Iterate over all the non-dynamic cells (both interior and exterior)
    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        -- Iterate over all NPC references in the current cell
        for reference in cell:iterateReferences(tes3.objectType.npc) do
            -- Add NPC name or ID to the list, ensuring it's unique
            local npcName = reference.object.name
            if npcName and not npcList[npcName] then
                npcList[npcName] = true  -- Avoid duplicates
                table.insert(npcList, npcName)
            end
        end
    end

    table.sort(npcList)  -- Sort alphabetically for better user experience in MCM
    return npcList
end


return config