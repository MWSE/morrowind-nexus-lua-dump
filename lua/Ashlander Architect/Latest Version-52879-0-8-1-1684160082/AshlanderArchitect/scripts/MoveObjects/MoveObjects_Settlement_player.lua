local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local v3 = require("openmw.util").vector3
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local storage = require("openmw.storage")
local camera = require("openmw.camera")
local input = require("openmw.input")
local ui = require("openmw.ui")
local async = require("openmw.async")
local activeObjectTypes = {}
local settlementModData = storage.globalSection("AASettlements")

local renameWindow = nil
local uithing = nil

local CreateSettlementBox = nil

local currentText = ""
local buttonContext = ""
local doorID = ""
local settlementMarker = nil
local function textChanged(firstField)
    currentText = (firstField)
end
local function buttonClick()
    print(currentText)
    core.sendGlobalEvent("addSettlementEvent", { settlementName = currentText, settlementMarker = settlementMarker ,npcSpawnPosition = I.ZackUtils.findPosByOnNavMesh(settlementMarker.position,self.position)})
    CreateSettlementBox:destroy()
end

local function destroyWindow()
    renameWindow:destory()
end
local function onInputAction(id)
    if id == input.ACTION.Activate then
        local obj = I.ZackUtils.getObjInCrosshairs().hitObject
        if (obj == nil) then
            return
        end
        if (obj.recordId == "zhac_settlement_marker") then
            for x, settlement in ipairs(settlementModData:get("settlementList")) do
                if (settlement.markerId == obj.id) then
                    --Can't create a settlement if one exists here already.
                    return
                end
            end

            if (obj.cell.name ~= "") then
                ui.showMessage("You can't create a settlement in a named area.")
                return
            end
            for _, object in ipairs(nearby.activators) do
                if (object.recordId == "zhac_settlement_marker" and object ~= obj) then
                    local dist = math.sqrt((object.position.x - obj.position.x) ^ 2 +
                    (object.position.y - obj.position.y) ^ 2 + (object.position.z - obj.position.z) ^ 2)
                    if (dist < 10000) then
                        ui.showMessage("This marker is too close to an existing settlement!")
                        return
                    end
                end
            end
            settlementMarker = obj
            CreateSettlementBox = I.ZackUtilsUI.renderTextInput(
            { "(To interact with this window, open your inventory/player menu)", "",
                "What would you like this settlement to be named?" }, "", textChanged, buttonClick)
        end
    end
end


local function onConsoleCommand(mode, command, selectedObject)

    if(command == "luasettler" and selectedObject.recordId == "zhac_settlement_marker") then
        core.sendGlobalEvent("addActorToSettlement",selectedObject.id)
    end
end

return {
    interfaceName = "SettlerPlayer",
    interface = {
        version = 1,
        createWindow = createWindow,
        destroyWindow = destroyWindow,
    },
    eventHandlers = {

    },
    engineHandlers = {
        onFrame = onFrame,
        onInputAction = onInputAction,
        onSave = onSave,
        onConsoleCommand = onConsoleCommand,
    }
}
