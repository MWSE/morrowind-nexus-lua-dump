local config = require("mer.realisticRepair.config")
local INDICATOR_ID = "AnvilRepair_Tooltip"

local function getEnabled()
    return config.mcm.enableRealisticRepair
        and config.mcm.enableStations
end


---Get the current station the player is looking at
local function getCurrentStation()
    return tes3.player.tempData.realisticRepairCurrentStation
end

---Set the current station the player is looking at
local function setCurrentStation(station)
    tes3.player.tempData.realisticRepairCurrentStation = station
end


local function openRepairMenu(e)
    if e.item then
        tes3.player.tempData.realisticRepairAtStation = true
        tes3.mobilePlayer:equip{ item = e.item }
        tes3ui.leaveMenuMode()
        timer.delayOneFrame(function()
            tes3.player.tempData.realisticRepairAtStation = false
        end)
    end
end


local function repairItemFilter(e)
    for _, pattern in ipairs(getCurrentStation().toolPatterns) do
        local isViableTool = (
            e.item.objectType == tes3.objectType.repairItem and
            string.find(
                string.lower(e.item.name),
                string.lower(pattern)
            )
        )
        if isViableTool then return true end
    end
    return false
end


local function openRepairToolSelect()
    tes3ui.showInventorySelectMenu({
        title = getCurrentStation().name,
        noResultsText = "You do not have any tools.",
        filter = repairItemFilter,
        callback = openRepairMenu
    })
end


local isBlocked
event.register("keyDown", function(e)
    if not getEnabled() then return end
    if isBlocked then return end
    local inputController = tes3.worldController.inputController
    local keyTest = inputController:keybindTest(tes3.keybind.activate)
    if (keyTest and not tes3.menuMode() and getCurrentStation()) then
         openRepairToolSelect()
    end
end)


event.register("BlockScriptedActivate", function(e)
    isBlocked = e.doBlock
end)


local function createActivatorIndicator()
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if menu then
        local mainBlock = menu:findChild(INDICATOR_ID)
        local currentStation = getCurrentStation()
        if currentStation and not tes3.menuMode() then
            if not mainBlock then
                mainBlock = menu:createBlock({id = INDICATOR_ID })
                mainBlock.absolutePosAlignX = 0.5
                mainBlock.absolutePosAlignY = 0.01
                mainBlock.autoHeight = true
                mainBlock.autoWidth = true

                local labelBackground = mainBlock:createRect({color = {0, 0, 0}})
                --labelBackground.borderTop = 4
                labelBackground.autoHeight = true
                labelBackground.autoWidth = true

                local labelBorder = labelBackground:createThinBorder({})
                labelBorder.autoHeight = true
                labelBorder.autoWidth = true
                labelBorder.paddingAllSides = 10

                local label = labelBorder:createLabel{ text = currentStation.name}
                label.autoHeight = true
                label.autoWidth = true
                label.wrapText = true
                label.justifyText = "center"
            end
        elseif mainBlock then
            mainBlock:destroy()
        end
    end
end


local function checkForStation()
    if not getEnabled() then return end
    local result = tes3.rayTest{
        position = tes3.getPlayerEyePosition(),
        direction = tes3.getPlayerEyeVector(),
        maxDistance = tes3.getPlayerActivationDistance(),
        accurateSkinned = true,
    }
    if result and result.reference and result.reference.object.objectType == tes3.objectType.static then
        setCurrentStation(config.stations[result.reference.object.id])
    else
        setCurrentStation(nil)
    end
    createActivatorIndicator()
end

event.register("loaded", function()
    timer.start{
        type = timer.real,
        duration = 0.25,
        iterations = -1,
        callback = checkForStation
    }
end)