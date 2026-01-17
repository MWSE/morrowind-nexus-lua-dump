local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local Camera = require("openmw.camera")
local camera = require("openmw.camera")
local input = require("openmw.input")
local async = require("openmw.async")
local storage = require("openmw.storage")
local ambient = require("openmw.ambient")
local constants = require("scripts.Portals.constants")
local labelData = {}
local drawState = false
local bluePortalActive = false
local function anglesToV(pitch, yaw)
    local xzLen = math.cos(pitch)
    return util.vector3(
        xzLen * math.sin(yaw), -- x
        xzLen * math.cos(yaw), -- y
        math.sin(pitch)        -- z
    )
end
local lastHit = 0          -- Time of the last click
local clickCount = 0       -- Number of clicks within the time window
local clickThreshold = 0.5 -- Time threshold to differentiate clicks (e.g., 0.5 seconds)

local function getCameraDirData()
    local pos = Camera.getPosition()
    local pitch, yaw

    pitch = -(Camera.getPitch() + Camera.getExtraPitch())
    yaw = (Camera.getYaw() + Camera.getExtraYaw())

    return pos, anglesToV(pitch, yaw)
end

local function getPosInCrosshairs(mdist)
    local pos, v = getCameraDirData()

    local dist = 500
    if (mdist ~= nil) then
        dist = mdist
    end

    return pos + v * dist
end
local useRenderingRay = false

local function getObjInCrosshairs(ignoreOb, mdist, force)
    --ignoreOb is the object we are ignoring
    --mdist is the maximum distance we will search for
    if ignoreOb and type(ignoreOb) ~= "table" then
        ignoreOb = { ignoreOb }
    end
    local pos, v = getCameraDirData() --this function gets the position of the camera, and the angle of the camera

    local dist = 500
    if (mdist ~= nil) then
        dist = mdist
    end

    if (ignoreOb and not force) then --current functionality, have to do normal cast ray. This isn't great for placing items, since it will hit the hitbox of a bookshelf, not the shelf.
        return nearby.castRay(pos, pos + v * dist, {
            ignore = ignoreOb[1],
            collisionType = nearby.COLLISION_TYPE.HeightMap + nearby.COLLISION_TYPE.Water,

        })
    else
        if (ignoreOb) then
            if useRenderingRay then
                local ret = nearby.castRenderingRay(getPosInCrosshairs(20), pos + v * dist)
                local hpos = ret.hitPos
                if (ret.hitPos == nil) then
                    hpos = pos + v * dist
                end
                local previousXdist = I.DaisyUtilsAA.distanceBetweenPos(getPosInCrosshairs(20), hpos)
                while true do
                    local res = nearby.castRenderingRay(pos, pos + v * dist)
                    if not res.hit or not isObjectInTable(res.hitObject, ignoreOb) then
                        return res
                    end
                    step = 128
                    for i = 1, 4 do
                        local backwardRay = nearby.castRenderingRay(pos + v * step, pos)
                        if not backwardRay.hit or isObjectInTable(backwardRay.hitObject, ignoreOb) then
                            break -- no other objects between `pos` and `pos + step * v`
                        else
                            step = step / 2
                        end
                    end
                    pos = pos + v * step
                    dist = dist - step
                end
                return ret
            else
                -- local ret = nearby.castRay(getPosInCrosshairs(20), pos + v * dist,{ignore = ignoreOb})
                return nearby.castRay(pos, pos + v * dist, { ignore = ignoreOb[1]

                })
            end
        end
        return nearby.castRenderingRay(pos, pos + v * dist)
    end
end

local function firePortalGun()
    local pos = getObjInCrosshairs(self)
    if pos and pos.hitPos then
        pos = pos.hitPos
        core.sendGlobalEvent("placePortalAt", { pos = pos, cell = self.cell })
    end
end
local wasAlphaActive = false
local wasBetaActive = false
local wasSpellDrawn = false
local function playPortalOpenSound()
    ambient.playSound(constants.openPortalSound)
end
local blockOpenPortal = false
local portalsClosed = false
local function onUpdate()

if core.isWorldPaused() then return end
    local activeSpells = types.Actor.activeSpells(self)
    local alphaActive = activeSpells:isSpellActive("zhac_portal_alpha")
    local betaActive = activeSpells:isSpellActive("zhac_portal_beta")
    local check = types.Player.isTeleportingEnabled(self)

    if input.isKeyPressed(input.KEY.LeftShift) then
        -- bluePortalActive = true
    else
        --  bluePortalActive = false
    end
    if not blockOpenPortal and not portalsClosed then
        if alphaActive and not wasAlphaActive and not bluePortalActive then
            if check then
            core.sendGlobalEvent("summonPortal", true)
            else
                ui.showMessage(core.getGMST("sTeleportDisabled"))
                return
            end
        end
        if alphaActive and not wasAlphaActive and bluePortalActive then
            if check then
            core.sendGlobalEvent("summonPortal", false)
        else
            ui.showMessage(core.getGMST("sTeleportDisabled"))
            return
        end
        end
    elseif alphaActive and not portalsClosed then
        async:newUnsavableSimulationTimer(1, function()
            blockOpenPortal = false
            portalsClosed = false
        end)
        portalsClosed = true
        core.sendGlobalEvent("closePortals")
    end
    wasAlphaActive = alphaActive
    --setAllowRightClick
    wasBetaActive = betaActive

    local selectedSpellId
    local spellDrawn = types.Actor.getStance(self) == types.Actor.STANCE.Spell
    if types.Actor.getSelectedSpell(self) ~= nil and types.Actor.getSelectedSpell(self).id == "zhac_portal_alpha" then
        selectedSpellId = "zhac_portal_alpha"
    else
        spellDrawn = false
        selectedSpellId = nil
    end
    if spellDrawn and not wasSpellDrawn and selectedSpellId == "zhac_portal_alpha" then
        -- I.JItem.setAllowRightClick(false)
        drawState = true
    elseif not spellDrawn and wasSpellDrawn then
        --I.JItem.setAllowRightClick(true)
        drawState = false
    end
    wasSpellDrawn = spellDrawn
end

local function onInputAction(act)
    if act == input.ACTION.Use then
        local currentTime = core.getRealTime()

        -- If the time between clicks is within the threshold, increment the click count
        if currentTime - lastHit <= clickThreshold then
            clickCount = clickCount + 1
        else
            clickCount = 1 -- Reset click count if the threshold time has passed
        end

        -- Perform actions based on the click count
        if clickCount == 1 then
            -- Single click action
            bluePortalActive = false
        elseif clickCount == 2 then
            -- Double click action
            bluePortalActive = true
        elseif clickCount == 3 then
            blockOpenPortal = true

        end

        -- Update last hit time
        lastHit = currentTime

        -- Reset click count after a small delay (e.g., 1 second) to avoid incorrect counting
        async:newUnsavableSimulationTimer(1, function()
            clickCount = 0
        end)
    end
end
return {
    interfaceName = "Portal",
    interface = {
        firePortalGun = firePortalGun,
        getObjInCrosshairs = getObjInCrosshairs,
        getLabelData = function()
            return labelData
        end
    },
    eventHandlers = {
        UpdateLabelData = function(data)
            labelData = data
        end,
        ReduceMagicak_Portal = function(amount)
            types.Actor.stats.dynamic.magicka(self).current = types.Actor.stats.dynamic.magicka(self).current - amount
        end,
        ShowMessage_Portal = function(msg)
            ui.showMessage(msg)
        end,
        playPortalOpenSound = playPortalOpenSound,
        playPortalCloseSound = function ()
            ambient.playSound(constants.closePortalSound)
            
        end
    },
    engineHandlers = {
        onSave = function()
            return { labelData = labelData }
        end,
        onInputAction = onInputAction,
        onMouseButtonPress = function(btn)
            if drawState and btn == 31 then
                ui.showMessage("RC      ")
                I.Controls.overrideCombatControls(true)
                -- bluePortalActive = true
                self.controls.use = 1
                async:newUnsavableSimulationTimer(0.1, function()
                    I.Controls.overrideCombatControls(false)
                end)
                --bluePortalActive
                async:newUnsavableSimulationTimer(2, function()
                    -- bluePortalActive = false
                end)
            end
        end,
        onLoad = function(data)
            labelData = data.labelData
        end,
        onUpdate = onUpdate,
    }
}
