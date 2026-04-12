local input   = require('openmw.input')
local camera  = require('openmw.camera')
local core    = require('openmw.core')
local nearby  = require('openmw.nearby')
local ui      = require('openmw.ui')
local util    = require('openmw.util')
local types   = require('openmw.types')
local self_   = require('openmw.self')
local I       = require('openmw.interfaces')

local activeInspectMode = nil

local paused = false
local startingSimulationTimeScale = 1.0
local scrollAccum = 0

-- ─── Freezetime ─────────────────────────────────────────────────────────────── 

local FREEZE_TIME_DEFAULT

if FREEZE_TIME_DEFAULT == nil then
    FREEZE_TIME_DEFAULT = true  
end

-- ─── Config ───────────────────────────────────────────────────────────────────
local ROTATE_SPEED          = 0.003
local ZOOM_STEP             = 3.0
local MIN_DIST              = 40.0
local MAX_DIST              = 150.0
local DEFAULT_DIST          = 40.0
local DEFAULT_PITCH         = 0.4          
local MIN_PITCH             = -0.4
local MAX_PITCH             =  1.1								  
local RAY_LENGTH            = 5000
local SURFACE_SEARCH_RADIUS = 64.0

local CENTRE_RAY_OFFSETS = {
    util.vector2( 0,     0    ),   
    util.vector2( 0.01,  0    ),
    util.vector2(-0.01,  0    ),
    util.vector2( 0,     0.01 ),
    util.vector2( 0,    -0.01 ),
}							

-- ─── Item type whitelist ──────────────────────────────────────────────────────
local ITEM_TYPES = {
    [types.Weapon]        = true,
    [types.Armor]         = true,
    [types.Clothing]      = true,
    [types.Book]          = true,
    [types.Ingredient]    = true,
    [types.Potion]        = true,
    [types.Miscellaneous] = true,
    [types.Apparatus]     = true,
    [types.Lockpick]      = true,
    [types.Probe]         = true,
    [types.Repair]        = true,
    [types.Light]         = true,
    [types.Container]     = true,
    [types.Activator]     = true,
    [types.NPC]           = true,
    [types.Creature]      = true,
}

local function isInventoryItem(obj)
    if obj == nil then return false end
    local ok, result = pcall(function() return ITEM_TYPES[obj.type] end)
    return ok and result == true
end

-- ─── State ────────────────────────────────────────────────────────────────────
local active      = false
local target      = nil
local orbitCentre = nil																  
local orbitYaw    = 0.0
local orbitPitch  = DEFAULT_PITCH								   
local orbitDist   = DEFAULT_DIST
local prevMode    = nil
--local scrollAccum = 0
local overlay     = nil
local hintOverlay = nil
local inspectKeyWasDown = false

-- ─── Player visibility state ──────────────────────────────────────────────────
local playerHidden = false

-- ─── Key helper ───────────────────────────────────────────────────────────────
local cachedKey = nil

local function getInspectKeyState()
    if not active then
        return false
    end
    local state = input.getActionState('inspectItemAction')
    return state
end

-- ─── Helpers ──────────────────────────────────────────────────────────────────
local function safeField(rec, field)
    if rec == nil then return nil end
    local ok, v = pcall(function() return rec[field] end)
    return ok and v or nil
end

local function typeName(obj)
    local t = obj.type
    if     t == types.Weapon        then return 'Weapon'
    elseif t == types.Armor         then return 'Armor'
    elseif t == types.Clothing      then return 'Clothing'
    elseif t == types.Book          then return 'Book/Scroll'
    elseif t == types.Ingredient    then return 'Ingredient'
    elseif t == types.Potion        then return 'Potion'
    elseif t == types.Miscellaneous then return 'Misc. Item'
    elseif t == types.Apparatus     then return 'Apparatus'
    elseif t == types.Lockpick      then return 'Lockpick'
    elseif t == types.Probe         then return 'Probe'
    elseif t == types.Repair        then return 'Repair Item'
    elseif t == types.Light         then return 'Light'
    elseif t == types.Container     then return 'Container'
    elseif t == types.Activator     then return 'Activator'
    elseif t == types.NPC           then return 'NPC'
    elseif t == types.Creature      then return 'Creature'
    else                                 return 'Object'
    end
end

local function buildInfoText(obj)
    local ok, rec = pcall(function() return obj.type.record(obj) end)
    if not ok then rec = nil end

    local lines = {}
    lines[#lines+1] = '[ ' .. typeName(obj) .. ' ]'
    lines[#lines+1] = safeField(rec, 'name') or obj.recordId or '?'

    local w = safeField(rec, 'weight')
    local v = safeField(rec, 'value')
    if w then lines[#lines+1] = string.format('Weight: %.2f', w) end
    if v then lines[#lines+1] = string.format('Value: %d gold', v) end

    local t = obj.type
    if t == types.Weapon then
        local c1,c2 = safeField(rec,'chopMinDamage'),  safeField(rec,'chopMaxDamage')
        local s1,s2 = safeField(rec,'slashMinDamage'), safeField(rec,'slashMaxDamage')
        local h1,h2 = safeField(rec,'thrustMinDamage'),safeField(rec,'thrustMaxDamage')
        local hp    = safeField(rec,'health')
        if c1 and c2 then lines[#lines+1] = string.format('Chop: %d-%d',   c1, c2) end
        if s1 and s2 then lines[#lines+1] = string.format('Slash: %d-%d',  s1, s2) end
        if h1 and h2 then lines[#lines+1] = string.format('Thrust: %d-%d', h1, h2) end
        if hp         then lines[#lines+1] = string.format('Condition: %d', hp)     end
    elseif t == types.Armor then
        local ar = safeField(rec,'baseArmor')
        local hp = safeField(rec,'health')
        if ar then lines[#lines+1] = string.format('Armor Rating: %d', ar) end
        if hp then lines[#lines+1] = string.format('Condition: %d',    hp) end
    elseif t == types.Book then
        local sk = safeField(rec,'skill')
        if sk and sk ~= '' then lines[#lines+1] = 'Teaches: ' .. sk end
    elseif t == types.Lockpick or t == types.Probe then
        local q = safeField(rec,'quality')
        local u = safeField(rec,'maxCondition')
        if q then lines[#lines+1] = string.format('Quality: %.2f', q) end
        if u then lines[#lines+1] = string.format('Uses: %d',      u) end
    elseif t == types.Apparatus then
        local q = safeField(rec,'quality')
        if q then lines[#lines+1] = string.format('Quality: %.2f', q) end
    elseif t == types.NPC then
        local race = safeField(rec, 'race')
        local class = safeField(rec, 'class')
        if race then lines[#lines+1] = 'Race: ' .. race end
        if class then lines[#lines+1] = 'Class: ' .. class end
    elseif t == types.Creature then
        local type_ = safeField(rec, 'type')
        if type_ then lines[#lines+1] = 'Type: ' .. type_ end
    end

    return table.concat(lines, '\n')
end

-- ─── Ray direction builder ────────────────────────────────────────────────────
local function makeDir(yaw, pitch)
    local cp = math.cos(pitch)						  
    return util.vector3(
        math.sin(yaw) * math.cos(pitch),
        math.cos(yaw) * math.cos(pitch),
        math.sin(pitch)
    )
end

-- ─── Visual-centre estimator ──────────────────────────────────────────────────
local function estimateVisualCentre(obj, rayFrom, yaw, pitch)
    local baseDir = makeDir(yaw, pitch)
    local rayTo   = rayFrom + baseDir * RAY_LENGTH
    local result  = nearby.castRenderingRay(rayFrom, rayTo)

    local objPos = obj.position

    if result and result.hitPos then
        local hitPos  = result.hitPos
        local hitDist = (hitPos - objPos):length()

        local surfaceToOrigin = hitPos - objPos
        local verticalOffset  = util.vector3(0, 0, surfaceToOrigin.z * 0.5)

        local centre = objPos + verticalOffset
        return centre
    end

    return objPos
end

-- ─── Item finder ──────────────────────────────────────────────────────────────
local function findItemFromRay(rayFrom, yaw, pitch)
    local dirs = {
        makeDir(yaw,  pitch),
        makeDir(yaw, -pitch),
    }

    local hitPositions = {}

    for i, dir in ipairs(dirs) do
        local rayTo = rayFrom + dir * RAY_LENGTH
        local result = nearby.castRenderingRay(rayFrom, rayTo)

        if result then
            if result.hitObject and isInventoryItem(result.hitObject) then
                return result.hitObject
            end
            if result.hitPos then
                hitPositions[#hitPositions+1] = result.hitPos
            end
        end
    end

    hitPositions[#hitPositions+1] = rayFrom + makeDir(yaw, pitch) * 200

    local ok, items = pcall(function() return nearby.items end)
    if not ok or not items then
        return nil
    end

    local best     = nil
    local bestDist = SURFACE_SEARCH_RADIUS

    for _, obj in ipairs(items) do
        if isInventoryItem(obj) then
            local posOk, objPos = pcall(function() return obj.position end)
            if posOk then
                for _, center in ipairs(hitPositions) do
                    local dist = (objPos - center):length()
            if dist < bestDist then
                bestDist = dist
                best     = obj
            end
                end
            end
        end
    end

    return best
end

-- ─── Player model visibility ──────────────────────────────────────────────────
local function hidePlayer()
    core.sendGlobalEvent('InspectIt_SetPlayerVisible', { visible = false })
    playerHidden = true
end

local function showPlayer()
    if not playerHidden then return end
    core.sendGlobalEvent('InspectIt_SetPlayerVisible', { visible = true })
    playerHidden = false
end

-- ─── UI ───────────────────────────────────────────────────────────────────────
local function destroyUI()
    if overlay     then overlay:destroy();     overlay     = nil end
    if hintOverlay then hintOverlay:destroy(); hintOverlay = nil end
end

local function createUI(obj)
    destroyUI()
    overlay = ui.create {
        layer = 'HUD',
        type  = ui.TYPE.Flex,
        props = {
            position        = util.vector2(16, 16),
            autoSize        = true,
            vertical        = true,
            backgroundColor = util.color.rgba(0, 0, 0, 0.65),
        },
        content = ui.content {
            {
                type  = ui.TYPE.Text,
                props = {
                    text      = buildInfoText(obj),
                    textSize  = 16,
                    textColor = util.color.rgb(1.0, 0.88, 0.55),
                    autoSize  = true,
            wordWrap  = true,
            size      = util.vector2(320, 0),
                },
            },
        },
    }
    hintOverlay = ui.create {
        layer = 'HUD',
        type  = ui.TYPE.Text,
        props = {
            relativePosition = util.vector2(0.5, 1.0),
            anchor           = util.vector2(0.5, 1.0),
            position         = util.vector2(0, -14),
            text             = 'Move mouse for vertical inspect   [LMB drag] Rotate   [Scroll] Zoom   [Configured Key / RMB] Exit',
            textSize         = 13,
            textColor        = util.color.rgb(0.6, 0.6, 0.6),
            autoSize         = true,
        },
    }
end

-- ─── Camera helpers ───────────────────────────────────────────────────────────
local function setCameraPos(pos)
    if camera.setStaticPosition then
        camera.setStaticPosition(pos)
    else
        camera.setPosition(pos)
    end
end

local function setControls(enabled)
    local function trySwitch(name)
        pcall(function()
            local cs = types.Player.CONTROL_SWITCH
            types.Player.setControlSwitch(self_, cs[name], enabled)
        end)
    end
    trySwitch('playerWalking')
    trySwitch('playerFighting')
    trySwitch('playerViewSwitching')
    trySwitch('vanityMode')   
    trySwitch('viewMode')    
end

-- ─── Freeze time init ─────────────────────────────────────────────────────
local function freezeTime()
    if paused then
        return
    end
    paused = true
    startingSimulationTimeScale = core.getSimulationTimeScale()
    local success, err = pcall(function()
        core.sendGlobalEvent('toggleSimulation', 0)
    end)
end

local function unfreezeTime()
    if not paused then
        return
    end
    paused = false
    local success, err = pcall(function()
        core.sendGlobalEvent('toggleSimulation', startingSimulationTimeScale)
    end)
end

-- ── Objects edges (min/max by axis) ──────────
local function getObjectBounds(obj)
    local ok, rec = pcall(function() return obj.type.record(obj) end)
    if not ok or not rec then
        return {
            min = util.vector3(-20, -20, 0),
            max = util.vector3(20, 20, 100)
        }
    end

    local boundsMin = safeField(rec, 'boundMin')
    local boundsMax = safeField(rec, 'boundMax')

    if not boundsMin or not boundsMax then
        local objType = obj.type
        if objType == types.NPC then
            boundsMin = util.vector3(-40, -40, 30)
            boundsMax = util.vector3(40, 40, 120)
        elseif objType == types.Creature then
            boundsMin = util.vector3(-45, -50, 30)
            boundsMax = util.vector3(45, 50, 120)
        elseif objType == types.Weapon then
            boundsMin = util.vector3(-10, -25, 0)
            boundsMax = util.vector3(10, 25, 0)
        elseif objType == types.Armor then
            boundsMin = util.vector3(-20, -30, 0)
            boundsMax = util.vector3(20, 30, 0)
        elseif objType == types.Clothing then
            boundsMin = util.vector3(-25, -35, 0)
            boundsMax = util.vector3(25, 35, 0)
        elseif objType == types.Book then
            boundsMin = util.vector3(-8, -15, 0)
            boundsMax = util.vector3(8, 15, 0)
        elseif objType == types.Ingredient then
            boundsMin = util.vector3(-5, -5, 0)
            boundsMax = util.vector3(5, 5, 0)
        elseif objType == types.Potion then
            boundsMin = util.vector3(-6, -6, 0)
            boundsMax = util.vector3(6, 6, 0)
        elseif objType == types.Miscellaneous then
            boundsMin = util.vector3(-15, -15, 0)
            boundsMax = util.vector3(15, 15, 0)
        elseif objType == types.Apparatus then
            boundsMin = util.vector3(-20, -20, 0)
            boundsMax = util.vector3(20, 20, 0)
        elseif objType == types.Lockpick then
            boundsMin = util.vector3(-4, -20, 0)
            boundsMax = util.vector3(4, 20, 0)
        elseif objType == types.Probe then
            boundsMin = util.vector3(-4, -20, 0)
            boundsMax = util.vector3(4, 20, 0)
        elseif objType == types.Repair then
            boundsMin = util.vector3(-12, -18, 0)
            boundsMax = util.vector3(12, 18, 0)
        elseif objType == types.Light then
            boundsMin = util.vector3(-15, -15, 0)
            boundsMax = util.vector3(15, 15, 0)
        elseif objType == types.Container then
            boundsMin = util.vector3(-30, -40, 5)
            boundsMax = util.vector3(30, 40, 60)
        elseif objType == types.Activator then
            boundsMin = util.vector3(-20, -20, 5)
            boundsMax = util.vector3(20, 20, 50)
        else
            boundsMin = util.vector3(-20, -20, 20)
            boundsMax = util.vector3(20, 20, 40)
        end
    end

    local objPos = obj.position

    local adjustedBoundsMin = util.vector3(
        boundsMin.x,
        boundsMin.y,
        objPos.z + boundsMin.z
    )
    local adjustedBoundsMax = util.vector3(
        boundsMax.x,
        boundsMax.y,
        objPos.z + boundsMax.z
    )

    return {
        min = adjustedBoundsMin,
        max = adjustedBoundsMax
    }
end
-- ─── Inspect start / stop ─────────────────────────────────────────────────────
local function beginInspect(obj, rayFrom, yaw, pitch)
    active      = true
    target      = obj
    orbitYaw    = yaw + math.pi
    orbitPitch  = DEFAULT_PITCH
    scrollAccum = 0
    prevMode    = camera.getMode()

    local objectBounds = getObjectBounds(obj)
    local minZ = objectBounds.min.z
    local maxZ = objectBounds.max.z

    local heightFactor
    local objType = obj.type

    if objType == types.Weapon then
        heightFactor = 0.75
    elseif objType == types.Armor then
        heightFactor = 0.65
    elseif objType == types.Clothing then
        heightFactor = 0.7
    elseif objType == types.Book then
        heightFactor = 0.9
    elseif objType == types.Ingredient then
        heightFactor = 0.85
    elseif objType == types.Potion then
        heightFactor = 0.8
    elseif objType == types.Miscellaneous then
        heightFactor = 0.7
    elseif objType == types.Apparatus then
        heightFactor = 0.6
    elseif objType == types.Lockpick or objType == types.Probe then
        heightFactor = 0.8
    elseif objType == types.Repair then
        heightFactor = 0.75
    elseif objType == types.Light then
        heightFactor = 0.8
    elseif objType == types.Container then
        heightFactor = 0.6
    elseif objType == types.Activator then
        heightFactor = 0.8
    elseif objType == types.NPC then
        heightFactor = 0.55
    elseif objType == types.Creature then
        heightFactor = 0.45
    else
        heightFactor = 0.7
    end

    local centreZ = obj.position.z + (maxZ - minZ) * heightFactor

    orbitCentre = util.vector3(
        obj.position.x,
        obj.position.y,
        centreZ
    )

    local baseDir = makeDir(yaw, pitch)
    local rayTo   = rayFrom + baseDir * RAY_LENGTH
    local result  = nearby.castRenderingRay(rayFrom, rayTo)

    if result and result.hitPos then
        local d = (result.hitPos - orbitCentre):length()
        orbitDist = math.max(MIN_DIST, math.min(MAX_DIST, d + 20.0))
    else
        orbitDist = DEFAULT_DIST
    end

    camera.setMode(camera.MODE.Static, false)
    setControls(false)
    hidePlayer()
    createUI(obj)
    if FREEZE_TIME_DEFAULT then
        freezeTime()
    end
end

local function endInspect()
    if not active then return end
    active = false
    target = nil
    orbitCentre = nil

    showPlayer()
    setControls(true)
    if prevMode then camera.setMode(prevMode, false) end
    destroyUI()
    if FREEZE_TIME_DEFAULT then
        unfreezeTime()
    end
    activeInspectMode = nil
end

-- ─── Orbit camera ─────────────────────────────────────────────────────────────
local SMOOTH_DIST = 0.1
local SMOOTH_ANGLE = 0.15

local function updateCamera()
    local targetDist = math.max(MIN_DIST, math.min(MAX_DIST, orbitDist))
    orbitDist = orbitDist * (1.0 - SMOOTH_DIST) + targetDist * SMOOTH_DIST

    local targetPitch = math.max(MIN_PITCH, math.min(MAX_PITCH, orbitPitch))
    orbitPitch = orbitPitch * (1.0 - SMOOTH_ANGLE) + targetPitch * SMOOTH_ANGLE

    local targetYaw = orbitYaw
    orbitYaw = orbitYaw * (1.0 - SMOOTH_ANGLE) + targetYaw * SMOOTH_ANGLE

    local ABS_MAX_PITCH = 1.5
    if orbitPitch > ABS_MAX_PITCH then
        orbitPitch = ABS_MAX_PITCH
    elseif orbitPitch < -ABS_MAX_PITCH then
        orbitPitch = -ABS_MAX_PITCH
    end

    local cp = math.cos(orbitPitch)
    local sp = math.sin(orbitPitch)
    local cy = math.cos(orbitYaw)
    local sy = math.sin(orbitYaw)

    local offset = util.vector3(
        cp * sy * orbitDist,
        cp * cy * orbitDist,
        sp * orbitDist
    )
    local camPos = orbitCentre + offset

    local lookDir = (orbitCentre - camPos):normalize()

    local length = lookDir:length()
    if math.abs(length - 1.0) > 0.001 then
        lookDir = lookDir:normalize()
    end

    local newYaw = math.atan2(lookDir.x, lookDir.y)
    local newPitch = -math.atan2(lookDir.z, math.sqrt(lookDir.x^2 + lookDir.y^2))

    setCameraPos(camPos)
    camera.setYaw(newYaw)
    camera.setPitch(newPitch)
end

-- ── Zoom: apply accumulated scroll ──────────
local function applyZoom()
    if scrollAccum == 0 then return end

    local zoomDelta = scrollAccum * ZOOM_STEP
    orbitDist = orbitDist - zoomDelta
    orbitDist = math.max(MIN_DIST, math.min(MAX_DIST, orbitDist))
    scrollAccum = 0
end

local function onMouseWheelLegacy(x, y)
    if not active then return end
    scrollAccum = scrollAccum + y
    applyZoom()
end

local function onMouseWheelModern(delta)
    if not active then return end
    scrollAccum = scrollAccum + delta
    applyZoom()
end

-- ─── Mouse wheel handlers (both names — whichever OpenMW calls, it works) ─────
local function onMouseWheel(...)
    if not active then return end

    local args = {...}
    local scrollValue = 0

    if #args == 2 then
        -- OpenMW ≤ 0.48: x, y
        scrollValue = args[2]
    elseif #args == 1 then
        -- OpenMW 0.49+: delta
        scrollValue = args[1]
    else
        return
    end

    scrollAccum = scrollAccum + scrollValue
end

-- ─── Frame handler ────────────────────────────────────────────────────────────
local function onFrame(dt)
    local inspectKeyDown = input.getBooleanActionValue('inspectItemAction')
    if inspectKeyDown and not inspectKeyWasDown then
        if active then
            endInspect()
        else
            if activeInspectMode == 'detailItem' then
                ui.showMessage('Another inspection mode is active')
            else
                local from = camera.getPosition()
                local yaw = camera.getYaw()
                local pitch = camera.getPitch()
                local item = findItemFromRay(from, yaw, pitch)
                if item then
                    activeInspectMode = 'inspectItem'  
                    beginInspect(item, from, yaw, pitch)
                else
                    ui.showMessage('No item to inspect here.')
                end
            end
        end
    end
    inspectKeyWasDown = inspectKeyDown

    if not active then return end

    local ok = pcall(function() return target.recordId end)
    if not ok then endInspect(); return end
    if input.isMouseButtonPressed(3) then endInspect(); return end

    if input.isMouseButtonPressed(1) then
        local mx = input.getMouseMoveX()
        local my = input.getMouseMoveY()

        if math.abs(mx) > 0.1 or math.abs(my) > 0.1 then
            orbitYaw = orbitYaw - mx * ROTATE_SPEED
            orbitPitch = orbitPitch + my * ROTATE_SPEED
        end
    else
        local my = input.getMouseMoveY()

        if math.abs(my) > 0.2 then
            if not target or not target.position then return end

            local globalUp = util.vector3(0, 0, 1)

            local moveDistance = my * 1.0 * 0.1
            local newCentre = orbitCentre + globalUp * moveDistance

            local objPos = target.position
            local objectBounds = getObjectBounds(target)

            local minZ = objectBounds.min.z
            local maxZ = objectBounds.max.z

            if newCentre.z < minZ or newCentre.z > maxZ then
                local clampedZ = math.max(minZ, math.min(maxZ, newCentre.z))
                orbitCentre = util.vector3(orbitCentre.x, orbitCentre.y, clampedZ)
            else
                orbitCentre = newCentre
            end
        end
    end

    if scrollAccum ~= 0 then
        applyZoom()
    end
    updateCamera()
end

-- ─── Unload ───────────────────────────────────────────────────────────────────
function onUnload()
    input.unregisterAction('inspectItemAction')
end

-- ─── Return table ─────────────────────────────────────────────────────────────
return {
    engineHandlers = {
        onFrame = onFrame,
        onMouseWheel = function(delta)
            if not active then return end
            if math.abs(delta) < 0.1 then
                return
            end
            scrollAccum = scrollAccum + delta
        end,
    },
    eventHandlers = {
        InspectIt_InspectConfirmed = function(data)
            if data and data.object then
                if isInventoryItem(data.object) then
                    local from  = camera.getPosition()
            local yaw   = camera.getYaw()
            local pitch = camera.getPitch()
            beginInspect(data.object, from, yaw, pitch)
        else
            ui.showMessage('That object cannot be picked up.')
        end
            end
        end,
        InspectIt_InspectDenied = function(data)
            ui.showMessage(data and data.reason or 'No item to inspect here.')
        end,
    },
}
