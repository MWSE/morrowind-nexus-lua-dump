local mcm = require("sb_compass.mcm")
local interop = { mcm = mcm }

local function markerDestroy(ref)
    mcm.uiMarkers[ref] = nil
end

local function subDestroy(ref)
    if (mcm.uiMarkers[ref]) then
        mcm.uiMarkers[ref].sub = false
    end
end

---registerMarker
---@param ref tes3reference
---@param id string
---@param path string
---@param color colours
function interop.registerMarker(ref, id, path, color)
    mcm.uiMarkers[ref] = {}

    mcm.uiMarkers[ref].marker = mcm.compass:createImage { id = id, path = "Icons\\sb_compass\\background.tga" }
    mcm.uiMarkers[ref].marker.absolutePosAlignY = 0.5
    mcm.uiMarkers[ref].marker:createImage { id = "icon", path = path }
    mcm.uiMarkers[ref].marker:findChild("icon").absolutePosAlignY = 0.5
    if (mcm.config.mrkBackground == 0) then
        mcm.uiMarkers[ref].marker.alpha = 1
        mcm.uiMarkers[ref].marker.color = color
        mcm.uiMarkers[ref].marker:findChild("icon").color = mcm.colours.black
    else
        mcm.uiMarkers[ref].marker.alpha = 0
        mcm.uiMarkers[ref].marker:findChild("icon").color = mcm.config.mrkBackground == 1 and mcm.colours.white or mcm.config.mrkBackground == 2 and color
    end
    mcm.uiMarkers[ref].marker:registerBefore("destroy", function()
        markerDestroy(ref)
    end)

    mcm.uiMarkers[ref].mini = mcm.compass:createImage { id = id .. "-mini", path = "Icons\\sb_compass\\background-mini.tga" }
    mcm.uiMarkers[ref].mini.absolutePosAlignY = 0.5
    mcm.uiMarkers[ref].mini:createImage { id = "icon", path = "Icons\\sb_compass\\above.tga" }
    mcm.uiMarkers[ref].mini:findChild("icon").absolutePosAlignY = 0.5
    if (mcm.config.mrkBackground == 0) then
        mcm.uiMarkers[ref].mini.alpha = 1
        mcm.uiMarkers[ref].mini.color = color
        mcm.uiMarkers[ref].mini:findChild("icon").color = mcm.colours.black
    else
        mcm.uiMarkers[ref].mini.alpha = 0
        mcm.uiMarkers[ref].mini:findChild("icon").color = mcm.config.mrkBackground == 1 and mcm.colours.white or mcm.config.mrkBackground == 2 and color
    end
    mcm.uiMarkers[ref].mini:registerBefore("destroy", function()
        markerDestroy(ref)
    end)

    mcm.uiMarkers[ref].marker.visible = false
    mcm.uiMarkers[ref].mini.visible = false
    mcm.uiMarkers[ref].sub = false
end

---registerSub
---@param ref tes3reference
---@param id string
---@param path string
---@param color colours
function interop.registerSub(ref, id, path, color)
    if (mcm.uiMarkers[ref]) then
        mcm.uiMarkers[ref].sub = mcm.compass:createImage { id = id .. "-sub", path = "Icons\\sb_compass\\background-sub.tga" }
        mcm.uiMarkers[ref].sub.absolutePosAlignY = 0.5
        mcm.uiMarkers[ref].sub:createImage { id = "icon", path = path }
        mcm.uiMarkers[ref].sub:findChild("icon").absolutePosAlignY = 0.5
        if (mcm.config.mrkBackground == 0) then
            mcm.uiMarkers[ref].sub.alpha = 1
            mcm.uiMarkers[ref].sub.color = color
            mcm.uiMarkers[ref].sub:findChild("icon").color = mcm.colours.black
        else
            mcm.uiMarkers[ref].sub.alpha = 0
            mcm.uiMarkers[ref].sub:findChild("icon").color = mcm.config.mrkBackground == 1 and mcm.colours.white or mcm.config.mrkBackground == 2 and color
        end
        mcm.uiMarkers[ref].sub:registerBefore("destroy", function()
            subDestroy(ref)
        end)

        mcm.uiMarkers[ref].sub.visible = false
    end
end

---updateMarkers
---@param ref tes3reference
function interop.updateMarkers(ref)
    local screenPoint = tes3.worldController.worldCamera.cameraData.camera:worldPointToScreenPoint(ref.position)
    local screenPos = screenPoint and (screenPoint.x + mcm.compass.width / 2) / mcm.compass.width or 2
    local screenPosSecondary = screenPoint and (screenPoint.x + 32 + mcm.compass.width / 2) / mcm.compass.width or 2

    mcm.uiMarkers[ref].marker.absolutePosAlignX = screenPos >= 0 and screenPos <= 1 and screenPos or 2
    if (type(mcm.uiMarkers[ref].sub) == "userdata") then
        mcm.uiMarkers[ref].sub.absolutePosAlignX = screenPosSecondary >= 0 and screenPosSecondary <= 1 and screenPosSecondary or 2
    end

    local dist = tes3.player.position.z - ref.position.z

    mcm.uiMarkers[ref].mini.visible = mcm.uiMarkers[ref].marker.visible and (dist >= 192 or dist <= -192)
    mcm.uiMarkers[ref].mini.absolutePosAlignX = screenPosSecondary >= 0 and screenPosSecondary <= 1 and screenPosSecondary or 2
    mcm.uiMarkers[ref].mini:findChild("icon").contentPath = dist >= 192 and "Icons\\sb_compass\\below.tga" or "Icons\\sb_compass\\above.tga"
end

---registerEvent
---@param event string
---@param userEvent table
function interop.registerEvent(event, userEvent)
    table.insert(mcm.uiEvents, { event, userEvent })
end

---getMarker
---@param ref tes3reference
---@return uiMarkers
function interop.getMarker(ref)
    return mcm.uiMarkers[ref]
end

---destroyMarker
---@param ref tes3reference
function interop.destroyMarker(ref)
    for _, category in pairs(mcm.distMarkers) do
        table.removevalue(category, ref)
    end
    if (mcm.uiMarkers[ref]) then
        local marker = mcm.uiMarkers[ref].marker
        local mini = mcm.uiMarkers[ref].mini
        local sub = mcm.uiMarkers[ref].sub
        marker:destroy()
        mini:destroy()
        if (type(sub) == "userdata") then
            sub:destroy()
        end
    end
end

---destroySub
---@param ref tes3reference
function interop.destroySub(ref)
    if (type(mcm.uiMarkers[ref].sub) == "userdata") then
        mcm.uiMarkers[ref].sub:destroy()
    else
        mcm.uiMarkers[ref].sub = false
    end
end

---isCompassEnabled
---@return boolean
function interop.isCompassEnabled()
    return mcm.config.enabled
end

---getCompass
---@return tes3reference
function interop.getCompass()
    return mcm.compass
end

---refreshUI
function interop.refreshUI()
    mcm.uiRefreshState = 1
end

---getRefreshState
---@return number
function interop.getRefreshState()
    return mcm.uiRefreshState
end

---registerFarSoon
---@param tab table
function interop.registerFarSoon(tab)
    mcm.soonMarkers.far[tab.obj] = { tab.icon, tab.colour }
end

---registerMidSoon
---@param tab table
function interop.registerMidSoon(tab)
    mcm.soonMarkers.mid[tab.obj] = { tab.icon, tab.colour }
end

---registerNearSoon
---@param tab table
function interop.registerNearSoon(tab)
    mcm.soonMarkers.near[tab.obj] = { tab.icon, tab.colour }
end

---registerDynamicSoon
---@param tab table
function interop.registerDynamicSoon(tab)
    mcm.soonMarkers.dyn[tab.obj] = { tab.icon, tab.colour }
end

---createDynamic
---@param ref tes3reference
---@param id string
---@param icon string
---@param colour colours
function interop.createDynamic(ref, id, icon, colour)
    table.insert(mcm.distMarkers.dyn, ref)
    interop.registerMarker(ref, id, icon, colour)
end

---getFarSoon
---@param objectID string
---@return table
function interop.getFarSoon(objectID)
    return mcm.soonMarkers.far[objectID]
end

---getMidSoon
---@param objectID string
---@return table
function interop.getMidSoon(objectID)
    return mcm.soonMarkers.mid[objectID]
end

---getNearSoon
---@param objectID string
---@return table
function interop.getNearSoon(objectID)
    return mcm.soonMarkers.near[objectID]
end

---getDynamicSoon
---@param objectID string
---@return table
function interop.getDynamicSoon(objectID)
    return mcm.soonMarkers.dyn[objectID]
end

---existsFarMarker
---@param ref tes3reference
---@return boolean
function interop.existsFarMarker(ref)
    return table.find(mcm.distMarkers.far, ref) and true or false
end

---existsMidMarker
---@param ref tes3reference
---@return boolean
function interop.existsMidMarker(ref)
    return table.find(mcm.distMarkers.mid, ref) and true or false
end

---existsNearMarker
---@param ref tes3reference
---@return boolean
function interop.existsNearMarker(ref)
    return table.find(mcm.distMarkers.near, ref) and true or false
end

---existsDynamicMarker
---@param ref tes3reference
---@return boolean
function interop.existsDynamicMarker(ref)
    return table.find(mcm.distMarkers.dyn, ref) and true or false
end

---unregisterFarSoon
---@param objectID string
function interop.unregisterFarSoon(objectID)
    mcm.soonMarkers.far[objectID] = nil
end

---unregisterMidSoon
---@param objectID string
function interop.unregisterMidSoon(objectID)
    mcm.soonMarkers.mid[objectID] = nil
end

---unregisterNearSoon
---@param objectID string
function interop.unregisterNearSoon(objectID)
    mcm.soonMarkers.near[objectID] = nil
end

---unregisterDynamicSoon
---@param objectID string
function interop.unregisterDynamicSoon(objectID)
    mcm.soonMarkers.dyn[objectID] = nil
end

---destroyDynamic
---@param ref tes3reference
function interop.destroyDynamic(ref)
    table.removevalue(mcm.distMarkers.dyn, ref)
    if (mcm.uiMarkers[ref]) then
        local marker = mcm.uiMarkers[ref].marker
        local mini = mcm.uiMarkers[ref].mini
        local sub = mcm.uiMarkers[ref].sub
        marker:destroy()
        mini:destroy()
        if (type(sub) == "userdata") then
            sub:destroy()
        end
    end
end

---showDynamic
---@param ref tes3reference
function interop.showDynamic(ref)
    if (mcm.uiMarkers[ref]) then
        mcm.uiMarkers[ref].marker.visible = true
        mcm.uiMarkers[ref].mini.visible = true
        if (type(mcm.uiMarkers[ref].sub) == "userdata") then
            mcm.uiMarkers[ref].sub.visible = true
        end
    end
end

---hideDynamic
---@param ref tes3reference
function interop.hideDynamic(ref)
    if (mcm.uiMarkers[ref]) then
        mcm.uiMarkers[ref].marker.visible = false
        mcm.uiMarkers[ref].mini.visible = false
        if (type(mcm.uiMarkers[ref].sub) == "userdata") then
            mcm.uiMarkers[ref].sub.visible = false
        end
    end
end

---showDynamicSub
---@param ref tes3reference
function interop.showDynamicSub(ref)
    mcm.uiMarkers[ref].sub.visible = true
end

---hideDynamicSub
---@param ref tes3reference
function interop.hideDynamicSub(ref)
    mcm.uiMarkers[ref].sub.visible = false
end

return interop