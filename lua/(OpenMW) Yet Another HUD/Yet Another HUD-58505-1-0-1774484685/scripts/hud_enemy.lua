
local ui     = require("openmw.ui")
local util   = require("openmw.util")
local self   = require("openmw.self")
local types  = require("openmw.types")
local nearby = require("openmw.nearby")
local I      = require("openmw.interfaces")
local Actor  = types.Actor

local BAR_W      = 150
local BAR_H      = 10
local HALF       = BAR_W / 2
local FRAME_W    = math.floor(BAR_W * 1.193)
local FRAME_H    = math.floor(BAR_H * 3.778)

local FADE_SPEED = 1.0
local HOLD_TIME  = 3.0

local TEX_BG    = "textures/Horizontal_Compass/background.png"
local TEX_FILL  = "textures/Horizontal_Compass/health_bar.png"
local TEX_FRAME = "textures/Horizontal_Compass/frame.png"

local COLOR_HP    = util.color.rgb(0.75, 0.05, 0.15)
local COLOR_FRAME = util.color.rgb(1, 0.8, 0.4)

local HUD_CHECK_INTERVAL   = 0.25
local FOCUS_CHECK_INTERVAL = 0.1
local HOSTILE_SCAN_INTERVAL = 0.5

local VEC_FORWARD = util.vector3(0, 1, 0)

local texCache = {}
local function tex(path)
    if not texCache[path] then texCache[path] = ui.texture { path = path } end
    return texCache[path]
end

local enemies      = {}
local enemyCount   = 0
local activeId     = nil
local holdTimer    = 0
local currentAlpha = 0
local cachedRatio  = 0
local hudVisible   = true
local inMenu       = false
local ENEMY_TIMEOUT = 1.5
local enemyTimers  = {}
local lastFill     = -1
local lastAlpha    = -1
local hudCheckTimer    = 0
local focusCheckTimer  = 0
local hostileScanTimer = 0

local root = ui.create {
    layer = "HUD",
    type  = ui.TYPE.Widget,
    props = { relativeSize = util.vector2(1, 1), mouseTransparent = true },
    content = ui.content {}
}

local cx = FRAME_W / 2
local cy = FRAME_H / 2

local container = ui.create {
    type = ui.TYPE.Widget,
    props = {
        relativePosition = util.vector2(0.5, 0.12),
        anchor           = util.vector2(0.5, 0.5),
        size             = util.vector2(FRAME_W, FRAME_H),
        alpha            = 0,
        mouseTransparent = true,
    },
    content = ui.content {}
}

local bgBar = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = tex(TEX_BG),
        size     = util.vector2(BAR_W, BAR_H),
        position = util.vector2(cx, cy),
        anchor   = util.vector2(0.5, 0.5),
    }
}
local fillL = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = tex(TEX_FILL),
        size     = util.vector2(HALF, BAR_H),
        position = util.vector2(cx, cy),
        anchor   = util.vector2(1, 0.5),
        color    = COLOR_HP,
    }
}
local fillR = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = tex(TEX_FILL),
        size     = util.vector2(HALF, BAR_H),
        position = util.vector2(cx, cy),
        anchor   = util.vector2(0, 0.5),
        color    = COLOR_HP,
    }
}
local frameBar = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = tex(TEX_FRAME),
        size     = util.vector2(FRAME_W, FRAME_H),
        color    = COLOR_FRAME,
    }
}

container.layout.content:add(bgBar)
container.layout.content:add(fillL)
container.layout.content:add(fillR)
container.layout.content:add(frameBar)
root.layout.content:add(container)

local function removeEnemy(id)
    enemies[id]     = nil
    enemyTimers[id] = nil
    enemyCount      = math.max(0, enemyCount - 1)
    if id == activeId then
        activeId    = next(enemies)
        cachedRatio = activeId and math.max(0, math.min(1, enemies[activeId].health / enemies[activeId].maxHealth)) or 0
        lastFill    = -1
    end
end

local FOCUS_HYSTERESIS = 0.20
local function findFocusedEnemy()
    if enemyCount <= 1 then return end
    local forward   = self.rotation:apply(VEC_FORWARD)
    local playerPos = self.position
    local bestDot   = -2
    local bestId    = nil
    local activeDot = -2
    for id, e in pairs(enemies) do
        if e.object and e.object:isValid() then
            local toEnemy = (e.object.position - playerPos):normalize()
            local dot = forward:dot(toEnemy)
            if dot > bestDot then
                bestDot = dot
                bestId  = id
            end
            if id == activeId then
                activeDot = dot
            end
        end
    end
    if bestId and bestId ~= activeId and (bestDot - activeDot) > FOCUS_HYSTERESIS then
        activeId    = bestId
        cachedRatio = math.max(0, math.min(1, enemies[bestId].health / enemies[bestId].maxHealth))
        lastFill    = -1
    end
end

local WAKE_COOLDOWN = 3.0
local wakeCooldown = {}

local function scanForHostiles(dt)
    for nid, t in pairs(wakeCooldown) do
        t = t - dt
        if t <= 0 then
            wakeCooldown[nid] = nil
        else
            wakeCooldown[nid] = t
        end
    end

    for _, actor in ipairs(nearby.actors) do
        if actor ~= self.object and actor:isValid() and not Actor.isDead(actor) then
            local stance = Actor.getStance(actor)
            if stance == 1 or stance == 2 then
                local rawId = tostring(actor.id)
                local numId = tonumber(rawId:match("0x([%da-fA-F]+)"), 16) or rawId
                if not enemies[numId] and not wakeCooldown[numId] then
                    actor:sendEvent("HudWakeUp", { player = self.object })
                    wakeCooldown[numId] = WAKE_COOLDOWN
                end
            end
        end
    end
end

local function onEnemyUpdate(data)
    local id = data.id

    if data.stopped then
        if enemies[id] then removeEnemy(id) end
        return
    end

    local isNew = not enemies[id]
    local prevHealth = not isNew and enemies[id].health or data.health
    local tookDamage = data.health < prevHealth

    if isNew then enemyCount = enemyCount + 1 end
    enemies[id] = { health = data.health, maxHealth = data.maxHealth, object = data.object }
    enemyTimers[id] = 0

    if tookDamage or (isNew and not activeId) then
        activeId    = id
        cachedRatio = math.max(0, math.min(1, data.health / data.maxHealth))
        lastFill    = -1
    elseif id == activeId then
        cachedRatio = math.max(0, math.min(1, data.health / data.maxHealth))
        lastFill    = -1
    end
end

local function onFrame(dt)
    hudCheckTimer = hudCheckTimer + dt
    if hudCheckTimer >= HUD_CHECK_INTERVAL then
        hudCheckTimer = 0
        local newHudVisible = I.UI.isHudVisible()
        if newHudVisible ~= hudVisible then
            hudVisible = newHudVisible
            root.layout.props.visible = hudVisible
            root:update()
        end
        inMenu = I.UI.getMode() ~= nil
    end

    if not hudVisible then return end

    if inMenu then
        if currentAlpha > 0 then
            currentAlpha = 0
            lastAlpha    = -1
            container.layout.props.alpha   = 0
            container.layout.props.visible = false
            container:update()
        end
        return
    end

    hostileScanTimer = hostileScanTimer + dt
    if hostileScanTimer >= HOSTILE_SCAN_INTERVAL then
        scanForHostiles(hostileScanTimer)
        hostileScanTimer = 0
    end

    for eid, t in pairs(enemyTimers) do
        enemyTimers[eid] = t + dt
        if enemyTimers[eid] > ENEMY_TIMEOUT then
            removeEnemy(eid)
        end
    end

    if enemyCount > 1 then
        focusCheckTimer = focusCheckTimer + dt
        if focusCheckTimer >= FOCUS_CHECK_INTERVAL then
            focusCheckTimer = 0
            findFocusedEnemy()
        end
    end

    local hasTarget = enemyCount > 0
    if not hasTarget then
        holdTimer = holdTimer - dt
    else
        holdTimer = HOLD_TIME
    end

    local shouldShow = hasTarget or holdTimer > 0

    if shouldShow then
        currentAlpha = math.min(1, currentAlpha + dt * FADE_SPEED)
    else
        currentAlpha = math.max(0, currentAlpha - dt * FADE_SPEED)
        if currentAlpha <= 0 then
            cachedRatio = 0
            lastFill    = -1
        end
    end

    local iFill = math.floor(HALF * cachedRatio)
    local alphaChanged = currentAlpha ~= lastAlpha

    if iFill ~= lastFill or alphaChanged then
        if iFill ~= lastFill then
            fillL.layout.props.size = util.vector2(iFill, BAR_H)
            fillR.layout.props.size = util.vector2(iFill, BAR_H)
            fillL:update()
            fillR:update()
            lastFill = iFill
        end
        if alphaChanged then
            container.layout.props.alpha   = currentAlpha
            container.layout.props.visible = currentAlpha > 0
            lastAlpha = currentAlpha
        end
        container:update()
    end
end

return {
    engineHandlers = { onFrame = onFrame },
    eventHandlers  = { HudEnemyUpdate = onEnemyUpdate },
}