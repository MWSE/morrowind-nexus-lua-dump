local self    = require("openmw.self")
local types   = require("openmw.types")
local core    = require("openmw.core")
local storage = require("openmw.storage")
local async   = require("openmw.async")
local ui      = require("openmw.ui")
local util    = require("openmw.util")
local input   = require("openmw.input")
local nearby  = require("openmw.nearby")
local anim    = require("openmw.animation")
local I       = require("openmw.interfaces")
local time    = require("openmw_aux.time")

local shared     = require("scripts.tamer_shared")
local DEFAULTS   = shared.DEFAULTS
local MESSAGES   = shared.MESSAGES
local FOOD_HERBIVORE = shared.FOOD_HERBIVORE
local FOOD_CARNIVORE = shared.FOOD_CARNIVORE

local section = storage.playerSection("SettingsTamer")

local function get(key)
    local v = section:get(key)
    if v ~= nil then return v end
    return DEFAULTS[key]
end

local cachedSettings = {}

local function refreshCache()
    for k in pairs(DEFAULTS) do
        cachedSettings[k] = get(k)
    end
    core.sendGlobalEvent("Tamer_SettingsUpdated", cachedSettings)
end

section:subscribe(async:callback(refreshCache))

local function log(...)
    if cachedSettings.ENABLE_LOGS then print("[Tamer P]", ...) end
end

-- player-side cache of tamed creatures
local tamedCache = {}

-- player-assigned nicknames, keyed by creature id
local nicknames = {}

local function playerLevel()
    return types.Actor.stats.level(self).current or 1
end

local lastLevel = playerLevel()

-- loss watchdog

local lastCellName  = nil
local watchdogGen   = 0
local WATCHDOG_DELAY = 10 * time.second

local function declareLost(creature)
    local id = creature.id
    if not tamedCache[id] then return end
    tamedCache[id] = nil
    core.sendGlobalEvent("Tamer_LoseCreature", { creature = creature })
    log("Declared lost:", creature.recordId or "?")
end

-- true if this following creature is too far to keep
local function isTooFar(creature)
    if not creature or not creature:isValid() then return true end
    local limit = cachedSettings.LOSE_DISTANCE or DEFAULTS.LOSE_DISTANCE
    if not limit or limit <= 0 then return false end
    return (creature.position - self.position):length() > limit
end

local function scheduleWatchdog()
    watchdogGen = watchdogGen + 1
    local myGen = watchdogGen
    async:newUnsavableSimulationTimer(WATCHDOG_DELAY, function()
        if myGen ~= watchdogGen then return end

        for id, entry in pairs(tamedCache) do
            -- waiting creatures are exempt from the watchdog
            if not entry.waiting then
                local creature = entry.object
                if isTooFar(creature) then
                    declareLost(creature or { id = id, recordId = "?" })
                end
            end
        end
    end)
end

-- continuous distance check
local distTimer = 0
local DIST_INTERVAL = 1.0

local function distanceCheck()
    local limit = cachedSettings.LOSE_DISTANCE or DEFAULTS.LOSE_DISTANCE
    if not limit or limit <= 0 then return end
    for id, entry in pairs(tamedCache) do
        -- waiting creatures are exempt
        if not entry.waiting then
            local creature = entry.object
            if creature and creature:isValid() then
                local dist = (creature.position - self.position):length()
                if dist > limit then
                    declareLost(creature)
                end
            end
        end
    end
end

-- ENGINE HANDLERS

local function onUpdate(dt)
    local cellName = self.cell and self.cell.name or nil
    if cellName ~= lastCellName then
        lastCellName = cellName
        if next(tamedCache) then
            scheduleWatchdog()
        end
    end

    distTimer = distTimer + dt
    if distTimer >= DIST_INTERVAL then
        distTimer = 0
        if next(tamedCache) then
            distanceCheck()
        end
    end
end

-- rename popup

local renameElement = nil
local renameTargetId = nil
local renameText = ""

local function closeRenamePopup()
    if renameElement then
        renameElement:destroy()
        renameElement = nil
    end
    renameTargetId = nil
    renameText = ""
    if I.UI then
        I.UI.removeMode("Interface")
    end
end

local function commitRename()
    local id = renameTargetId
    local text = renameText
    if id then
        text = text:gsub("^%s*(.-)%s*$", "%1")   -- trim
        if text ~= "" then
            nicknames[id] = text
        else
            nicknames[id] = nil   -- empty name clears the nickname
        end
        if tamedCache[id] then
            tamedCache[id].nickname = nicknames[id]
        end
    end
    closeRenamePopup()
end

local function buildRenamePopup(defaultName)
    renameText = defaultName or ""

    local textField = {
        type = ui.TYPE.TextEdit,
        template = I.MWUI.templates.textEditLine,
        props = {
            size       = util.vector2(260, 28),
            text       = renameText,
            textColor  = util.color.rgb(0.92, 0.88, 0.78),
            textSize   = 18,
        },
        events = {
            textChanged = async:callback(function(newText)
                renameText = newText
            end),
        },
    }

    local function labelText(str, size, color)
        return {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {
                text       = str,
                textSize   = size,
                textColor  = color,
                textAlignH = ui.ALIGNMENT.Center,
            },
        }
    end

    local function button(str, onClick)
        return {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textNormal,
            props = {
                text       = str,
                textSize   = 18,
                textColor  = util.color.rgb(0.78, 0.66, 0.32),
            },
            events = {
                mouseClick = async:callback(onClick),
            },
        }
    end

    local rows = {
        { props = { size = util.vector2(0, 8) } },
        labelText("Name your new companion:", 17, util.color.rgb(0.78, 0.66, 0.32)),
        { props = { size = util.vector2(0, 8) } },
        textField,
        { props = { size = util.vector2(0, 12) } },
        {
            type = ui.TYPE.Flex,
            props = { horizontal = true, arrange = ui.ALIGNMENT.Center },
            content = ui.content {
                button("  OK  ", commitRename),
                { props = { size = util.vector2(24, 0) } },
                button("  Cancel  ", closeRenamePopup),
            },
        },
        { props = { size = util.vector2(0, 8) } },
    }

    renameElement = ui.create {
        layer = "Windows",
        template = I.MWUI.templates.boxSolid,
        props = {
            relativePosition = util.vector2(0.5, 0.5),
            anchor           = util.vector2(0.5, 0.5),
        },
        content = ui.content {
            {
                type = ui.TYPE.Flex,
                props = { arrange = ui.ALIGNMENT.Center },
                content = ui.content(rows),
            },
        },
    }
end

local function openRenamePopup(creatureId, defaultName)
    if renameElement then closeRenamePopup() end
    renameTargetId = creatureId
    if I.UI then
        I.UI.setMode("Interface", { windows = {} })
    end
    buildRenamePopup(defaultName)
end

-- order key
local function orderTargetedCreature()
    if not cachedSettings.MOD_ENABLED then return end
    if not cachedSettings.ALLOW_WAIT then return end
    if I.UI.getMode() ~= nil then return end
    if not I.SharedRay then return end

    local ray = I.SharedRay.get()
    local obj = ray and ray.hitObject
    if not obj or not obj:isValid() then return end
    if not types.Creature.objectIsInstance(obj) then return end
    if not tamedCache[obj.id] then return end

    obj:sendEvent("Tamer_ToggleWait", {})
end

-- play a left-arm + torso animation on the player
local function playAnimation(groupName)
    if not I.AnimationController then return end
    I.AnimationController.playBlendedAnimation(groupName, {
        startKey = "start",
        stopKey  = "stop",
        priority = {
            [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Scripted,
            [anim.BONE_GROUP.Torso]   = anim.PRIORITY.Scripted,
        },
        autoDisable = true,
        blendMask = anim.BLEND_MASK.LeftArm + anim.BLEND_MASK.Torso
                  + anim.BLEND_MASK.RightArm + anim.BLEND_MASK.LowerBody,
        speed = 1,
    })
end

local function playPetAnimation()
    playAnimation("petit")
end

-- pet key: heals a tamed creature the player is looking at
local PET_COOLDOWN = 2
local lastPetTime  = -math.huge

local function petTargetedCreature()
    if not cachedSettings.MOD_ENABLED then return false end
    if I.UI.getMode() ~= nil then return false end
    if not I.SharedRay then return false end

    local now = core.getSimulationTime()
    if now - lastPetTime < PET_COOLDOWN then return false end

    local ray = I.SharedRay.get()
    local obj = ray and ray.hitObject
    if not obj or not obj:isValid() then return false end
    if not types.Creature.objectIsInstance(obj) then return false end
    if not tamedCache[obj.id] then return false end

    lastPetTime = now
    playPetAnimation()
    obj:sendEvent("Tamer_PetCreature", {})
    return true
end


-- FOOD DROP DETECTION (peaceful taming)

local foodSnapshot = {}

local function buildFoodSnapshot()
    local snap = {}
    local inv  = types.Actor.inventory(self)
    if not inv then return snap end
    for _, item in ipairs(inv:getAll()) do
        local rid = string.lower(item.recordId)
        if FOOD_HERBIVORE[rid] or FOOD_CARNIVORE[rid] then
            snap[rid] = (snap[rid] or 0) + item.count
        end
    end
    return snap
end

-- find the nearest matching world item near the player and notify the global
local function notifyFoodDrop(recordId)
    local best, bestDist
    for _, item in ipairs(nearby.items) do
        if string.lower(item.recordId) == recordId
           and item:isValid() and item.cell ~= nil and item.count > 0 then
            local dist = (item.position - self.position):length()
            if not bestDist or dist < bestDist then
                best, bestDist = item, dist
            end
        end
    end
    if best then
        core.sendGlobalEvent("Tamer_FoodDropped", {
            food   = best,
            player = self.object,
        })
        log("Food dropped:", recordId)
    end
end

-- diff the current food inventory against the snapshot
local function checkDroppedFood()
    if not cachedSettings.MOD_ENABLED then return end
    local current = buildFoodSnapshot()
    for rid, prevCount in pairs(foodSnapshot) do
        local nowCount = current[rid] or 0
        if nowCount < prevCount then
            notifyFoodDrop(rid)
        end
    end
    foodSnapshot = current
end


local function onInit()
    refreshCache()
    lastLevel    = playerLevel()
    lastCellName = self.cell and self.cell.name or nil
    foodSnapshot = buildFoodSnapshot()
end

local function onLoad(d)
    refreshCache()
    lastLevel    = playerLevel()
    lastCellName = nil
    watchdogGen  = watchdogGen + 1
    tamedCache   = {}
    nicknames    = (d and d.nicknames) or {}
    foodSnapshot = buildFoodSnapshot()
    if renameElement then closeRenamePopup() end
end

local function onSave()
    return { nicknames = nicknames }
end

-- detect a finished level-up: the LevelUp UI mode closing
local function onUiModeChanged(data)
    if data.oldMode == "LevelUp" then
        local lvl = playerLevel()
        if lvl > lastLevel then
            lastLevel = lvl
            core.sendGlobalEvent("Tamer_PlayerLevelUp", { level = lvl })
            log("Player levelled up to", lvl)
        end
    end

    -- inventory opened: snapshot food so we can diff on close
    if data.oldMode == nil and data.newMode == "Interface" then
        foodSnapshot = buildFoodSnapshot()
    end
    -- inventory closed: anything missing was dropped into the world
    if data.oldMode == "Interface" and data.newMode == nil then
        async:newUnsavableSimulationTimer(0.1, checkDroppedFood)
    end
end

-- EVENT HANDLERS

-- resolve the display name for a creature: nickname if set, else the fallback
local function displayName(creatureId, fallback)
    if creatureId and nicknames[creatureId] then
        return nicknames[creatureId]
    end
    return fallback or "Your creature"
end

local function onShowMessage(d)
    if not d then return end
    if d.message then
        ui.showMessage(d.message)
        return
    end
    -- petting uses two names: the nickname you gave it, then its record name
    if d.key == "petted" then
        local nick    = displayName(d.creatureId, d.name)
        local recName = d.name or "It"
        ui.showMessage(string.format(MESSAGES.petted, nick, recName))
        return
    end
    if d.key and MESSAGES[d.key] then
        local name = displayName(d.creatureId, d.name)
        ui.showMessage(string.format(MESSAGES[d.key], name))
        if (d.key == "died" or d.key == "lost") and d.creatureId then
            nicknames[d.creatureId] = nil
        end
    end
end

-- a tamed creature reports its current state (on tame / activate / level-up)
local function onReportState(d)
    if not d or not d.creature then return end
    local id = d.creature.id
    tamedCache[id] = {
        object    = d.creature,
        waiting   = d.waiting or false,
        level     = d.level or 1,
        minDamage = d.minDamage,
        maxDamage = d.maxDamage,
        nickname  = nicknames[id],
    }
    -- on a fresh tame, optionally open the rename popup
    if d.justTamed and cachedSettings.RENAME_ON_TAME then
        local rec = types.Creature.record(d.creature)
        local defaultName = nicknames[id] or (rec and rec.name) or d.creature.recordId
        openRenamePopup(id, defaultName)
    end
end

-- a tamed creature is gone (died or turned hostile)
local function onCreatureGone(d)
    if d and d.creatureId then
        local id = d.creatureId
        tamedCache[id] = nil
        if renameTargetId == id then
            closeRenamePopup()
        end
    end
end

local function onInputAction(id)
    local swap = cachedSettings.SWAP_ACTIONS
    local actKey = swap and input.ACTION.Run or input.ACTION.Activate
    local petKey = swap and input.ACTION.Activate or input.ACTION.Run

    if id == actKey then
        if not cachedSettings.MOD_ENABLED then return end
        if not cachedSettings.ALLOW_WAIT then return end
        if I.UI.getMode() ~= nil then return end
        if not I.SharedRay then return end

        local ray = I.SharedRay.get()
        local obj = ray and ray.hitObject

        -- looking at a tamed creature: toggle its wait/follow order
        if obj and obj:isValid() and types.Creature.objectIsInstance(obj) and tamedCache[obj.id] then
            orderTargetedCreature()
        end
    elseif id == petKey then
        petTargetedCreature()
    end
end

-- result of a wait/follow order
local function onOrderResult(d)
    if not d then return end
    if d.creatureId and tamedCache[d.creatureId] then
        tamedCache[d.creatureId].waiting = d.waiting
    end
    local name = displayName(d.creatureId, d.name)
    if d.waiting then
        playAnimation("wait")
        ui.showMessage(string.format(MESSAGES.wait, name))
    else
        playAnimation("followme")
        ui.showMessage(string.format(MESSAGES.rejoin, name))
    end
end

-- I.Tamer interface (used by tamer_tooltip.lua)
local function isTamed(obj)
    return obj ~= nil and tamedCache[obj.id] ~= nil
end

local function getInfo(obj)
    if not obj or not obj:isValid() then return nil end
    local entry = tamedCache[obj.id]
    if not entry then return nil end

    local rec     = types.Creature.record(obj)
    local recName = (rec and rec.name) or obj.recordId
    local name    = nicknames[obj.id] or recName

    local hp  = types.Actor.stats.dynamic.health(obj)
    local mp  = types.Actor.stats.dynamic.magicka(obj)
    local fat = types.Actor.stats.dynamic.fatigue(obj)

    return {
        name       = name,
        level      = entry.level or 1,
        waiting    = entry.waiting or false,
        health     = math.floor(hp.current  + 0.5),
        maxHealth  = math.floor(hp.base     + hp.modifier  + 0.5),
        magicka    = math.floor(mp.current  + 0.5),
        maxMagicka = math.floor(mp.base     + mp.modifier  + 0.5),
        fatigue    = math.floor(fat.current + 0.5),
        maxFatigue = math.floor(fat.base    + fat.modifier + 0.5),
        minDamage  = entry.minDamage,
        maxDamage  = entry.maxDamage,
    }
end

refreshCache()

return {
    interfaceName = "Tamer",
    interface = {
        version        = 1,
        isTamed        = isTamed,
        getInfo        = getInfo,
        tooltipEnabled = function() return cachedSettings.TOOLTIP_ENABLED end,
        allowWait      = function() return cachedSettings.ALLOW_WAIT end,
        modEnabled     = function() return cachedSettings.MOD_ENABLED end,
        swapActions    = function() return cachedSettings.SWAP_ACTIONS end,
    },
    engineHandlers = {
        onInit          = onInit,
        onLoad          = onLoad,
        onSave          = onSave,
        onUpdate        = onUpdate,
        onInputAction       = onInputAction,
    },
    eventHandlers = {
        UiModeChanged       = onUiModeChanged,
        Tamer_ShowMessage   = onShowMessage,
        Tamer_ReportState   = onReportState,
        Tamer_CreatureGone  = onCreatureGone,
        Tamer_OrderResult   = onOrderResult,
    },
}