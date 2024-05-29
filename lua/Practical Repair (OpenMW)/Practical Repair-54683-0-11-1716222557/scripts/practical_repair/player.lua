local util = require("openmw.util")
local ui = require("openmw.ui")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local input = require("openmw.input")
local camera = require("openmw.camera")
local core = require("openmw.core")
local types = require("openmw.types")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local settings = storage.globalSection("Settings_practical_repair_main_option")
local modInfo = require("scripts.practical_repair.modInfo")
local l10n = core.l10n("practical_repair")

I.Settings.registerPage {
    key = "practical_repair_main_page",
    l10n = "practical_repair",
    name = "settings_modName",
    description = l10n("settings_modDesc"):format(modInfo.MOD_VERSION)
}

local menu = nil
local stations = {}
local pickingRepairTool
local targetStation
local lastBoostedAmount = 0
local iMaxActivateDist = core.getGMST("iMaxActivateDist")

local function destroyIndicator()
    if menu then
        menu:destroy()
        menu = nil
    end
end

local function modDisabled()
    local disabled = settings:get("Mod Status") == false
    if disabled then
        targetStation = nil
        pickingRepairTool = false
        destroyIndicator()
    end
    return disabled
end

local function getTarget(distanceLimit, viewPort_v2)
    local cameraPos = camera.getPosition()
    local cursorVector = camera.viewportToWorldVector(viewPort_v2 or util.vector2(0.5, 0.5))
    local maxRayDistance = distanceLimit or camera.getViewDistance()
    local finalPos = cameraPos + cursorVector * maxRayDistance
    local rayResult = nearby.castRenderingRay(cameraPos, finalPos,
        { -- seems like castRenderingRay is better than castRay for this
            collisionType = nearby.COLLISION_TYPE.World,
            ignore = self
        })
    return rayResult, cameraPos, finalPos
end

local function pad(layout)
    return {
        template = I.MWUI.templates.padding,
        content = ui.content {{
            template = I.MWUI.templates.padding,
            content = ui.content {{
                template = I.MWUI.templates.padding,
                content = ui.content {layout}
            }}
        }}
    }
end

local function createIndicator(targetStation)
    local stationName = stations[targetStation.recordId]
    if stationName:len() <= 0 then
        return
    end
    local layout = {
        name = targetStation.id,
        layer = "Notification",
        type = ui.TYPE.Flex,
        props = {
            relativePosition = util.vector2(0.50, 0.45)
        },
        content = ui.content {{
            template = I.MWUI.templates.boxSolid,
            content = ui.content {pad {
                template = I.MWUI.templates.textHeader,
                props = {
                    text = stationName
                }
            }}
        }}
    }
    if not menu then
        menu = ui.create(layout)
        menu:update()
    elseif menu.layout.name ~= targetStation.id then
        destroyIndicator()
    end
end

local function checkTargetIsStation()
    if I.UI.getMode() ~= nil then
        destroyIndicator()
        return
    end
    local telekinesisRange = types.Actor.activeEffects(self):getEffect("telekinesis").magnitude
    local activationDist = iMaxActivateDist + (telekinesisRange * 21.33333333)
    local res = getTarget(activationDist)
    if res.hit and res.hitObject and stations[res.hitObject.recordId] then
        local canActivate = (res.hitPos - self.position):length() <= activationDist
        if canActivate then
            targetStation = res.hitObject
            createIndicator(targetStation)
        end
    else
        destroyIndicator()
        targetStation = nil
    end
end

local function clearBonus()
    local armorerStat = types.NPC.stats.skills.armorer(self)
    armorerStat.modifier = armorerStat.modifier - lastBoostedAmount
    lastBoostedAmount = 0
end

return {
    engineHandlers = {
        onInputAction = function(action)
            if action == input.ACTION.Activate and not pickingRepairTool then
                if targetStation and I.UI.getMode() == nil then
                    if targetStation.type == types.Static then
                        targetStation:activateBy(self)
                    end
                end
            end
        end,
        onFrame = function(dt)
            if modDisabled() then
                return
            end
            if not pickingRepairTool and I.UI.getMode() == "Repair" then
                self:sendEvent("PracticalRepair_message_eqnx", {
                    msg = l10n("PracticalRepair_findAnvilOrForge")
                })
                I.UI.removeMode("Repair")
            end
            checkTargetIsStation()
        end,
        onActive = function()
            core.sendGlobalEvent("PracticalRepair_initPlayer_eqnx", self)
        end,
        onSave = function()
            return {
                lastBoostedAmount = lastBoostedAmount
            }
        end,
        onLoad = function(data)
            if data and data.lastBoostedAmount then
                lastBoostedAmount = data.lastBoostedAmount
                clearBonus()
            end
        end
    },
    eventHandlers = {
        PracticalRepair_setPickingRepairTool_eqnx = function(bool)
            pickingRepairTool = bool
        end,
        PracticalRepair_repairBoost_eqnx = function()
            if settings:get("Repair Boost") then
                local armorerStat = types.NPC.stats.skills.armorer(self)
                armorerStat.modifier = armorerStat.modifier + settings:get("Boost Amount")
                lastBoostedAmount = settings:get("Boost Amount")
                -- better to use fortify spell instead of modifying skill directly

            end
        end,
        PracticalRepair_updateStation_eqnx = function(station)
            stations[station.id] = station.name
        end,
        UiModeChanged = function(data)
            if data.oldMode == "Repair" then
                core.sendGlobalEvent("PracticalRepair_returnTools_eqnx", self)
                pickingRepairTool = false
                clearBonus()
            end
        end
    }
}
