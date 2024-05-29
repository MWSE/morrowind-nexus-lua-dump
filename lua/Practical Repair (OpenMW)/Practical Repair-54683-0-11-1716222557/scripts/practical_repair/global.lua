local types = require("openmw.types")
local I = require("openmw.interfaces")
local core = require("openmw.core")
local l10n = core.l10n("practical_repair")
local util = require("openmw.util")
local storage = require("openmw.storage")
local settings = storage.globalSection("Settings_practical_repair_main_option")

local tempTransfer = {}

local function nameOrIdMatch(tool, toolType)
    if tool.recordId:find(toolType) or tool.type.record(tool).name:lower():find(toolType) then
        return tool
    end
end

I.ItemUsage.addHandlerForType(types.Repair, function(object, actor)
    if settings:get("Mod Status") then
        actor:sendEvent("PracticalRepair_message_eqnx", {
            msg = l10n("PracticalRepair_findAnvilOrForge"),
            fail = true
        })
        return false
    end
end)

local function getToolTypeForStation(stationObj)
    for _, station in pairs(I.PracticalRepair_eqnx.stations) do
        if station.id:lower() == stationObj.recordId then
            return station.tool
        end
    end
end

local function returnTools(actor)
    for k, v in pairs(tempTransfer[actor.id] or {}) do
        v:moveInto(types.Actor.inventory(actor))
    end
    tempTransfer[actor.id] = {}
end

return {
    engineHandlers = {
        onSave = function()
            return {
                tempTransfer = tempTransfer
            }
        end,
        onLoad = function(data)
            if data and data.tempTransfer then
                tempTransfer = data.tempTransfer
            end
        end,
        -- future, refactor this block of code
        onActivate = function(obj, actor)
            local toolType = getToolTypeForStation(obj)
            if actor.type == types.Player and toolType then

                if #I.PracticalRepair_eqnx.activationBlock[actor.id] > 0 then
                    table.remove(I.PracticalRepair_eqnx.activationBlock[actor.id])
                    return
                end

                actor:sendEvent("PracticalRepair_setPickingRepairTool_eqnx", true)

                local repairtool
                for _, repairItem in pairs(types.Actor.inventory(actor):getAll(types.Repair)) do
                    local temp = nameOrIdMatch(repairItem, toolType)
                    if temp then
                        repairtool = temp
                    else
                        if not tempTransfer[actor.id] then
                            tempTransfer[actor.id] = {}
                        end
                        table.insert(tempTransfer[actor.id], repairItem)
                    end
                end
                if repairtool then
                    for _, repairItem in pairs(tempTransfer[actor.id] or {}) do
                        -- protected call because teleport() can be dodgy in *extremely* rare cases
                        local successful, res = pcall(repairItem.teleport, repairItem, actor.cell,
                            actor.position - util.vector3(0, 0, 10000))
                        if not successful then
                            print("[Practical Repair] Warning:", res)
                            returnTools(actor)
                            return
                        end
                    end
                    actor:sendEvent("AddUiMode", {
                        mode = "Repair",
                        target = repairtool
                    })
                    actor:sendEvent("PracticalRepair_repairBoost_eqnx")
                    return
                end

                tempTransfer[actor.id] = {}
                actor:sendEvent("PracticalRepair_setPickingRepairTool_eqnx", false)
                actor:sendEvent("PracticalRepair_message_eqnx", {
                    msg = string.format(l10n("PracticalRepair_equipToRepair"), toolType),
                    fail = true
                })
            end
        end
    },
    eventHandlers = {
        PracticalRepair_initPlayer_eqnx = function(player)
            for _, station in pairs(I.PracticalRepair_eqnx.stations) do
                player:sendEvent("PracticalRepair_updateStation_eqnx", {
                    id = station.id,
                    name = station.name
                })
            end
            core.sendGlobalEvent("PracticalRepair_returnTools_eqnx", player)
        end,
        PracticalRepair_returnTools_eqnx = returnTools
    }
}
