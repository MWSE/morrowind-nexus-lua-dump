local ui      = require("openmw.ui")
local util    = require("openmw.util")
local self    = require("openmw.self")
local types   = require("openmw.types")
local nearby  = require("openmw.nearby")
local storage = require("openmw.storage")
local async   = require("openmw.async")
local I       = require("openmw.interfaces")
local Actor   = types.Actor

local shared   = require("scripts.hud_shared")
local DEFAULTS = shared.DEFAULTS

local BAR_W      = 150
local BAR_H      = 10
local HALF       = BAR_W / 2
local FRAME_W    = math.floor(BAR_W * 1.193)
local FRAME_H    = math.floor(BAR_H * 3.778)

local SUB_H      = 5
local SUB_GAP    = -13
local SUB_W      = math.floor(BAR_W * 0.98)
local SUB_HALF   = SUB_W / 2

local CONTAINER_H = FRAME_H

local FADE_SPEED = 1.0
local HOLD_TIME  = 3.0

local TEX_BG    = "textures/Horizontal_Compass/background.png"
local TEX_FILL  = "textures/Horizontal_Compass/health_bar.png"
local TEX_FRAME = "textures/Horizontal_Compass/frame.png"

local COLOR_FRAME = util.color.rgb(1, 0.8, 0.4)

local HUD_CHECK_INTERVAL    = 0.25
local FOCUS_CHECK_INTERVAL  = 0.1
local HOSTILE_SCAN_INTERVAL = 0.5

local VEC_FORWARD = util.vector3(0, 1, 0)

local togglesSection = storage.playerSection("SettingsHudToggles")
local colorsSection  = storage.playerSection("SettingsHudColors")

local function getToggle(key)
    local v = togglesSection:get(key)
    if v == nil then return DEFAULTS[key] end
    return v
end

local function readColor(rKey, gKey, bKey)
    local r = colorsSection:get(rKey); if r == nil then r = DEFAULTS[rKey] end
    local g = colorsSection:get(gKey); if g == nil then g = DEFAULTS[gKey] end
    local b = colorsSection:get(bKey); if b == nil then b = DEFAULTS[bKey] end
    return util.color.rgb(r, g, b)
end

local COLOR_HP             = readColor("COLOR_HP_R", "COLOR_HP_G", "COLOR_HP_B")
local COLOR_ENEMY_FATIGUE  = readColor("COLOR_ENEMY_FATIGUE_R", "COLOR_ENEMY_FATIGUE_G", "COLOR_ENEMY_FATIGUE_B")
local showEnemyFatigue     = getToggle("SHOW_ENEMY_FATIGUE")

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
local cachedHpRatio  = 0
local cachedFatRatio = 0
local hudVisible   = true
local inMenu       = false
local ENEMY_TIMEOUT = 1.5
local enemyTimers  = {}
local lastFillHp   = -1
local lastFillFat  = -1
local lastAlpha    = -1
local hudCheckTimer    = 0
local focusCheckTimer  = 0
local hostileScanTimer = 0

local root = ui.create {
    layer = "HUD",
    type  = ui.TYPE.Widget,
    props = { relativeSize = util.vector2(1, 1) },
    content = ui.content {}
}

local container = ui.create {
    type = ui.TYPE.Widget,
    props = {
        relativePosition = util.vector2(0.5, 0.12),
        anchor           = util.vector2(0.5, 0.5),
        size             = util.vector2(FRAME_W, CONTAINER_H),
        alpha            = 0,
    },
    content = ui.content {}
}

local hpCx = FRAME_W / 2
local hpCy = FRAME_H / 2

local bgBar = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = tex(TEX_BG),
        size     = util.vector2(BAR_W, BAR_H),
        position = util.vector2(hpCx, hpCy),
        anchor   = util.vector2(0.5, 0.5),
    }
}
local fillL = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = tex(TEX_FILL),
        size     = util.vector2(HALF, BAR_H),
        position = util.vector2(hpCx, hpCy),
        anchor   = util.vector2(1, 0.5),
        color    = COLOR_HP,
    }
}
local fillR = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = tex(TEX_FILL),
        size     = util.vector2(HALF, BAR_H),
        position = util.vector2(hpCx, hpCy),
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

local subTop = FRAME_H + SUB_GAP
local subCy  = subTop + SUB_H / 2

local fatBg = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = tex(TEX_BG),
        size     = util.vector2(SUB_W, SUB_H),
        position = util.vector2(hpCx, subCy),
        anchor   = util.vector2(0.5, 0.5),
        visible  = showEnemyFatigue,
    }
}
local fatFillL = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = tex(TEX_FILL),
        size     = util.vector2(SUB_HALF, SUB_H),
        position = util.vector2(hpCx, subCy),
        anchor   = util.vector2(1, 0.5),
        color    = COLOR_ENEMY_FATIGUE,
        visible  = showEnemyFatigue,
    }
}
local fatFillR = ui.create {
    type = ui.TYPE.Image,
    props = {
        resource = tex(TEX_FILL),
        size     = util.vector2(SUB_HALF, SUB_H),
        position = util.vector2(hpCx, subCy),
        anchor   = util.vector2(0, 0.5),
        color    = COLOR_ENEMY_FATIGUE,
        visible  = showEnemyFatigue,
    }
}

container.layout.content:add(fatBg)
container.layout.content:add(fatFillL)
container.layout.content:add(fatFillR)
container.layout.content:add(bgBar)
container.layout.content:add(fillL)
container.layout.content:add(fillR)
container.layout.content:add(frameBar)
root.layout.content:add(container)

local function applyColors()
    fillL.layout.props.color    = COLOR_HP
    fillR.layout.props.color    = COLOR_HP
    fatFillL.layout.props.color = COLOR_ENEMY_FATIGUE
    fatFillR.layout.props.color = COLOR_ENEMY_FATIGUE
    fillL:update()
    fillR:update()
    fatFillL:update()
    fatFillR:update()
    lastFillHp  = -1
    lastFillFat = -1
end

local function applyFatigueVisibility()
    fatBg.layout.props.visible    = showEnemyFatigue
    fatFillL.layout.props.visible = showEnemyFatigue
    fatFillR.layout.props.visible = showEnemyFatigue
    fatBg:update()
    fatFillL:update()
    fatFillR:update()
    lastFillFat = -1
end

colorsSection:subscribe(async:callback(function(_, key)
    if key == nil
        or key == "COLOR_HP_R" or key == "COLOR_HP_G" or key == "COLOR_HP_B"
        or key == "COLOR_ENEMY_FATIGUE_R" or key == "COLOR_ENEMY_FATIGUE_G" or key == "COLOR_ENEMY_FATIGUE_B"
    then
        COLOR_HP            = readColor("COLOR_HP_R", "COLOR_HP_G", "COLOR_HP_B")
        COLOR_ENEMY_FATIGUE = readColor("COLOR_ENEMY_FATIGUE_R", "COLOR_ENEMY_FATIGUE_G", "COLOR_ENEMY_FATIGUE_B")
        applyColors()
    end
end))

togglesSection:subscribe(async:callback(function(_, key)
    if key == nil or key == "SHOW_ENEMY_FATIGUE" then
        showEnemyFatigue = getToggle("SHOW_ENEMY_FATIGUE")
        applyFatigueVisibility()
    end
end))

local function cacheRatios(e)
    cachedHpRatio  = math.max(0, math.min(1, e.health / e.maxHealth))
    cachedFatRatio = math.max(0, math.min(1, e.fatigue / e.maxFatigue))
    lastFillHp  = -1
    lastFillFat = -1
end

local function removeEnemy(id)
    enemies[id]     = nil
    enemyTimers[id] = nil
    enemyCount      = math.max(0, enemyCount - 1)
    if id == activeId then
        activeId = next(enemies)
        if activeId then
            cacheRatios(enemies[activeId])
        else
            cachedHpRatio  = 0
            cachedFatRatio = 0
            lastFillHp  = -1
            lastFillFat = -1
        end
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
        activeId = bestId
        cacheRatios(enemies[bestId])
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
    enemies[id] = {
        health     = data.health,
        maxHealth  = data.maxHealth,
        fatigue    = data.fatigue    or 0,
        maxFatigue = data.maxFatigue or 1,
        object     = data.object,
    }
    enemyTimers[id] = 0

    if tookDamage or (isNew and not activeId) then
        activeId = id
        cacheRatios(enemies[id])
    elseif id == activeId then
        cacheRatios(enemies[id])
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
            cachedHpRatio  = 0
            cachedFatRatio = 0
            lastFillHp  = -1
            lastFillFat = -1
        end
    end

    local iFillHp     = math.floor(HALF * cachedHpRatio)
    local alphaChanged = currentAlpha ~= lastAlpha
    local hpChanged    = iFillHp ~= lastFillHp

    local iFillFat, fatChanged = 0, false
    if showEnemyFatigue then
        iFillFat   = math.floor(SUB_HALF * cachedFatRatio)
        fatChanged = iFillFat ~= lastFillFat
    end

    if hpChanged or fatChanged or alphaChanged then
        if hpChanged then
            fillL.layout.props.size = util.vector2(iFillHp, BAR_H)
            fillR.layout.props.size = util.vector2(iFillHp, BAR_H)
            fillL:update()
            fillR:update()
            lastFillHp = iFillHp
        end
        if fatChanged then
            fatFillL.layout.props.size = util.vector2(iFillFat, SUB_H)
            fatFillR.layout.props.size = util.vector2(iFillFat, SUB_H)
            fatFillL:update()
            fatFillR:update()
            lastFillFat = iFillFat
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