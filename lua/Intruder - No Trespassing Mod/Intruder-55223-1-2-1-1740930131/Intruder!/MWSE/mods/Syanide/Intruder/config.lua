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

    local settings = template:createSideBarPage({ label = "Settings" })
    settings.showReset = true

    settings:createSlider({
        label = "Starting Hour to Begin Trespassing", 
        configKey = "startTrespass",
        min = 18, max = 24, step = 1, jump = 1,
        description = "Default: 9 p.m. Works in 24-Hour Clock."
    })

    settings:createSlider({
        label = "Starting Hour to Stop Trespassing",
        configKey = "endTrespass",
        min = 4, max = 10, step = 1, jump = 1,
        description = "Default: 6 a.m. Works in 24-Hour Clock."
    })

    settings:createSlider({
        label = "How Many Seconds for Homeowners to Start Combat",
        configKey = "timerSeconds",
        min = 5, max = 30, step = 1, jump = 1,
        description = "Only counts seconds that pass when menus are closed. Default: 10 Seconds"
    })

    settings:createYesNoButton({
		label = "Disposition Affects Trespass",
		configKey = "dispOn",
        description = "NPCs with high disposition will not consider you a trespasser. Default: Yes"
	})

    settings:createSlider({
        label = "Minimum Disposition for an Actor to Not Become Upset at Trespass",
        configKey = "disposition",
        min = 70, max = 100, step = 1, jump = 1,
        description = "The minimum disposition amount for NPCs to not consider the player a potential trespasser. Only works if previous option is yes. Default: 90"
    })

    settings:createYesNoButton({
		label = "Allow Combat on Trespass",
		configKey = "combat",
        description = "NPCs will start combat with the player when they are considered a trespasser. Default: Yes"
	})

    settings:createYesNoButton({
		label = "Lower Level Enemies Refrain from Combat",
		configKey = "playerLevel",
        description = "NPCs that are a lower level than the player will not start combat. Only works if previous option is yes. Default: Yes"
	})

    settings:createSlider({
        label = "Level Difference for Lower Level Enemies to Refrain from Combat",
        configKey = "level",
        min = 1, max = 10, step = 1, jump = 1,
        description = "Lower level difference for NPCs to refrain from combat. Example: If set to 10 and the player is level 40, NPCs that are level 30 or lower will not start combat. Only works if previous option is yes. Default: 5"
    })

    settings:createYesNoButton({
		label = "Disposition Decrease on Trespass",
		configKey = "decreaseDisposition",
        description = "NPC disposition will descrease with the player when they consider you a trespasser. Default: Yes"
	})

    settings:createSlider({
        label = "Disposition Decrease Amount",
        configKey = "dispositionDecrease",
        min = 1, max = 20, step = 1, jump = 1,
        description = "The amount disposition will descrease with the player. Only works if previous option is yes. Default: 5"
    })

    settings:createYesNoButton({
		label = "Prevents Waiting and Resting on Trespass",
		configKey = "noWait",
        description = "The amount disposition will descrease with the player. Only works if previous option is yes. Default: 5"
	})

    settings:createYesNoButton({
		label = "Messages Showing Who Has Witnessed Trespass in Case of Missed Verbal Cues",
		configKey = "messagesOn",
        description = "Shows the name of the NPC(s) that detect the player as well as those that consider the player a trespasser. Default: No"
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