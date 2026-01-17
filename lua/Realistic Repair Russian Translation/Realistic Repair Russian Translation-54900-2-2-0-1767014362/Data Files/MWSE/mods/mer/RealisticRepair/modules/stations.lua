---Thin orchestrator module for repair station detection and activation.
---Delegates station state management to StationService.

local config = require("mer.realisticRepair.config")
local StationService = require("mer.RealisticRepair.services.StationService")

local INDICATOR_ID = "AnvilRepair_Tooltip"

---Check if stations system is enabled
---@return boolean
local function getEnabled()
    return config.mcm.enableRealisticRepair
        and config.mcm.enableStations
end

---Open repair menu after selecting a tool
---@param e table
local function openRepairMenu(e)
    if e.item then
        StationService.setRepairMenuStationFlag(true)
        tes3.mobilePlayer:equip{ item = e.item }
        tes3ui.leaveMenuMode()
        timer.delayOneFrame(function()
            StationService.clearRepairMenuStationFlag()
        end)
    end
end

---Filter inventory to show only valid repair tools for current station
---@param e table
---@return boolean
local function repairItemFilter(e)
    return StationService.isToolValidForStation(e.item)
end

---Open inventory select menu to choose repair tool
local function openRepairToolSelect()
    local station = StationService.getCurrentStation()
    if not station then return end

    tes3ui.showInventorySelectMenu({
        title = station.name,
        noResultsText = "У вас нет инструментов.",
        filter = repairItemFilter,
        callback = openRepairMenu
    })
end

---Create UI indicator showing station name
local function createActivatorIndicator()
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if not menu then return end

    local mainBlock = menu:findChild(INDICATOR_ID)
    local station = StationService.getCurrentStation()

    if station and not tes3.menuMode() then
        if not mainBlock then
            mainBlock = menu:createBlock({id = INDICATOR_ID })
            mainBlock.absolutePosAlignX = 0.5
            mainBlock.absolutePosAlignY = 0.01
            mainBlock.autoHeight = true
            mainBlock.autoWidth = true

            local labelBackground = mainBlock:createRect({color = {0, 0, 0}})
            labelBackground.autoHeight = true
            labelBackground.autoWidth = true

            local labelBorder = labelBackground:createThinBorder({})
            labelBorder.autoHeight = true
            labelBorder.autoWidth = true
            labelBorder.paddingAllSides = 10

            local label = labelBorder:createLabel{ text = station.name}
            label.autoHeight = true
            label.autoWidth = true
            label.wrapText = true
            label.justifyText = "center"
        end
    elseif mainBlock then
        mainBlock:destroy()
    end
end

---Raycast to detect if player is looking at a repair station
local function checkForStation()
    if not getEnabled() then return end

    local result = tes3.rayTest{
        position = tes3.getPlayerEyePosition(),
        direction = tes3.getPlayerEyeVector(),
        maxDistance = tes3.getPlayerActivationDistance(),
        accurateSkinned = true,
    }

    if result and result.reference and result.reference.object.objectType == tes3.objectType.static then
        local station = config.stations[result.reference.object.id]
        StationService.setCurrentStation(station)
    else
        StationService.setCurrentStation(nil)
    end

    createActivatorIndicator()
end

---Track blocked activation state
local isBlocked = false

---Handle activation key press to open station repair menu
event.register("keyDown", function(e)
    if not getEnabled() then return end
    if isBlocked then return end

    local inputController = tes3.worldController.inputController
    local keyTest = inputController:keybindTest(tes3.keybind.activate)

    if keyTest and not tes3.menuMode() and StationService.isAtStation() then
        openRepairToolSelect()
    end
end)

---Track when activation is blocked
event.register("BlockScriptedActivate", function(e)
    isBlocked = e.doBlock
end)

---Start station detection timer on game load
event.register("loaded", function()
    timer.start{
        type = timer.real,
        duration = 0.25,
        iterations = -1,
        callback = checkForStation
    }
end)