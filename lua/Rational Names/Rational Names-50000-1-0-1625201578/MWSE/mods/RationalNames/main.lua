local modInfo = require("RationalNames.modInfo")
local config = require("RationalNames.config")
local data = require("RationalNames.data")
local common = require("RationalNames.common")
local rename = require("RationalNames.rename")
local ui = require("RationalNames.ui")

local function printLogList(logTable, tableName)
    common.logMsg(string.format("%s:", tableName))

    for _, line in ipairs(logTable) do
        common.logMsg(line)
    end

    common.logMsg(string.format("end %s.", tableName))
end

local function populateLogList(dataTable)
    local logTable = {}

    for key, value in pairs(dataTable) do
        local line = string.format("%s: %s", key, value)
        table.insert(logTable, line)
    end

    table.sort(logTable)
    return logTable
end

local function onInitialized()
    local buildDate = mwse.buildDate

    -- This mod takes advantage of a few recent fixes to MWSE, and won't work properly with an old version.
    if not buildDate
    or buildDate < 20210625 then
        local tooOld = string.format("%s MWSE is too out of date. Update MWSE to use this mod.", modInfo.modVersion)
        tes3.messageBox(tooOld)
        mwse.log(tooOld)
        return
    end

    if not config.enable then
        mwse.log("%s Mod disabled.", modInfo.modVersion)
        return
    end

    mwse.log("%s Initialized.", modInfo.modVersion)

    for _, objectType in ipairs(data.components) do
        local componentName = data.componentNames[objectType]

        if config.componentEnable[tostring(objectType)] then
            common.logMsg(string.format("Renaming %s.", componentName))
            rename.renameObjects(objectType)
        else
            common.logMsg(string.format("The %s component is disabled. Skipping %s.", componentName, componentName))
        end
    end

    -- Log a list of the full names of all objects with >31 char names, if logging enabled. Also log the "shortNameToID"
    -- reverse lookup table. We do it this way so the list will appear in the log in alphabetical order by ID (pairs
    -- results in random order).
    local fullNameLogList = populateLogList(data.fullNamesList)
    local shortNameLogList = populateLogList(data.shortNameToID)

    printLogList(fullNameLogList, "fullNamesList")
    printLogList(shortNameLogList, "shortNameToID")

    -- I remember I thought there was a compelling reason to set a high priority here at the time, but now I don't
    -- remember what it was. Maybe just to avoid messing up any other mods that modify tooltip names for some reason?
    -- Not sure, so I'm leaving it.
    event.register("uiObjectTooltip", ui.onTooltip, { priority = 10 })
    event.register("uiActivated", ui.menuMagicActivated, { filter = "MenuMagic" })
    event.register("uiActivated", ui.menuMagSelActivated, { filter = "MenuMagicSelect" })
    event.register("uiActivated", ui.menuInvSelActivated, { filter = "MenuInventorySelect" })
    -- This event is triggered whenever UI Expansion updates its filters in the inventory select menu (which overrides
    -- our name display changes, so we have to make our changes again every time).
    event.register("UIEXP:updatedInventorySelectTiles", ui.menuInvSelActivated)
    event.register("uiActivated", ui.menuRepairActivated, { filter = "MenuRepair" })
    event.register("uiActivated", ui.menuServiceRepairActivated, { filter = "MenuServiceRepair" })
    event.register("uiActivated", ui.hudActivated, { filter = "MenuMulti" })
    event.register("equipped", ui.onEquipmentChanged)
    event.register("unequipped", ui.onEquipmentChanged)
    event.register("enterFrame", ui.checkMagic)
    -- Low priority to make sure ui.checkMagic runs first (though it doesn't matter much - the HUD text would change the
    -- next frame anyway).
    event.register("enterFrame", ui.updateHudText, { priority = -10 })
    event.register("loaded", ui.onLoaded)
end

-- Low priority because fuck other MWSE renaming mods (mine are the only ones I'm aware of anyway).
event.register("initialized", onInitialized, { priority = -10 })

local function onModConfigReady()
    dofile("RationalNames.mcm")
end

event.register("modConfigReady", onModConfigReady)