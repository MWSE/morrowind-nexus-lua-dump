local self   = require("openmw.self")
local types  = require("openmw.types")
local nearby = require("openmw.nearby")
local core   = require("openmw.core")
local async  = require("openmw.async")
local anim   = require("openmw.animation")
local util   = require("openmw.util")
local time   = require("openmw_aux.time")
local I      = require("openmw.interfaces")
local AI     = I.AI

local shared                = require("scripts.tshared")
local KHAJIIT_RACE          = shared.KHAJIIT_RACE
local THIEF_FACTIONS        = shared.THIEF_FACTIONS
local THIEF_CLASSES         = shared.THIEF_CLASSES
local FACTION_IMMUNITY      = shared.FACTION_IMMUNITY
local GOLD_IDS              = shared.GOLD_IDS
local STEALABLE_MISC        = shared.STEALABLE_MISC
local STEALABLE_INGREDIENTS = shared.STEALABLE_INGREDIENTS
local STEALABLE_CLOTHING    = shared.STEALABLE_CLOTHING
local DEFAULTS              = shared.DEFAULTS
local STEAL_MESSAGES        = shared.STEAL_MESSAGES
local RETALIATION_LINES     = shared.RETALIATION_LINES
local RETALIATION_LINES_KHAJIIT = shared.RETALIATION_LINES_KHAJIIT
local APOLOGY_LINES         = shared.APOLOGY_LINES
local APOLOGY_LINES_KHAJIIT = shared.APOLOGY_LINES_KHAJIIT
local TAUNT_LINES           = shared.TAUNT_LINES
local TAUNT_LINES_KHAJIIT   = shared.TAUNT_LINES_KHAJIIT

local cachedSettings = {
    MOD_ENABLED     = DEFAULTS.MOD_ENABLED,
    STEAL_RADIUS    = DEFAULTS.STEAL_RADIUS,
    STEAL_CHANCE    = DEFAULTS.STEAL_CHANCE,
    MIN_GOLD        = DEFAULTS.MIN_GOLD,
    MAX_GOLD        = DEFAULTS.MAX_GOLD,
    AGILITY_MIN     = DEFAULTS.AGILITY_MIN,
    SNEAK_MIN       = DEFAULTS.SNEAK_MIN,
    SCAN_INTERVAL   = DEFAULTS.SCAN_INTERVAL,
    USE_DISPOSITION = DEFAULTS.USE_DISPOSITION,
    MAX_DISPOSITION = DEFAULTS.MAX_DISPOSITION,
    PLAY_SOUND      = DEFAULTS.PLAY_SOUND,
    SHOW_MESSAGE    = DEFAULTS.SHOW_MESSAGE,
    STEAL_ITEMS     = DEFAULTS.STEAL_ITEMS,
    RETALIATION_ENABLED = DEFAULTS.RETALIATION_ENABLED,
    RETALIATION_WINDOW  = DEFAULTS.RETALIATION_WINDOW,
    RETALIATION_RADIUS  = DEFAULTS.RETALIATION_RADIUS,
    RETALIATION_STANDOFF = DEFAULTS.RETALIATION_STANDOFF,
    RETALIATION_LEVEL_DIFF = DEFAULTS.RETALIATION_LEVEL_DIFF,
}

local activated     = false
local scanTimer     = 0
local thiefFaction  = nil
local thiefByClass  = false
local npcIsKhajiit  = false

-- Retaliation state
-- Phase nil        = inactive
-- Phase "watch"    = waiting for player to draw weapon (RETALIATION_WINDOW seconds)
-- Phase "standoff" = thief drew weapon, waiting before attack (RETALIATION_STANDOFF seconds)
local retaliationPhase    = nil
local retaliationTimer    = 0
local retaliationPlayer   = nil
local retaliationRadius   = nil
local retaliationChoice   = nil   -- what was stolen, for return on apology
local retaliationStartHP  = nil   -- thief HP when standoff started, for attack detection
local retaliationScanAcc  = 0     -- 1s tick for stance/distance/timer
local retaliationHPAcc    = 0     -- 0.1s tick for fast hit reaction during standoff

-- tracking (rotate to face player during standoff, DetailDevil logic)
local trackTimer = nil

local function angleDifference(a, b)
    local diff = b - a
    return math.atan2(math.sin(diff), math.cos(diff))
end

local function stopTracking()
    if trackTimer then
        trackTimer()
        trackTimer = nil
    end
    self.controls.yawChange = 0
end

local function startTracking(player)
    if trackTimer then return end

    trackTimer = time.runRepeatedly(function()
        if not self:isValid() or types.Actor.isDead(self) then
            stopTracking()
            return
        end
        if not player or not player:isValid() or types.Actor.isDead(player) then
            stopTracking()
            return
        end
        if self.cell ~= player.cell then
            stopTracking()
            return
        end

        local toPlayer = player.position - self.position
        local distance = toPlayer:length()
        if distance <= 1 then
            self.controls.yawChange = 0
            return
        end

        local targetYaw  = math.atan2(toPlayer.x, toPlayer.y)
        local currentYaw = self.rotation:getYaw()
        self.controls.yawChange = angleDifference(currentYaw, targetYaw) / 6
    end, 0.03 * time.second)
end

local function randomMessage()
    return STEAL_MESSAGES[math.random(#STEAL_MESSAGES)]
end

local function getFactionRank(actor, factionId)
    local ok, rank = pcall(types.NPC.getFactionRank, actor, factionId)
    if not ok then return 0 end
    return rank
end

local function isFactionProtected(player, faction)
    local immunity = FACTION_IMMUNITY[faction]
    if not immunity then return false end
    for immuneFactionId, _ in pairs(immunity) do
        if getFactionRank(player, immuneFactionId) > 0 then return true end
    end
    return false
end

local function isDispositionTooHigh(player)
    if not cachedSettings.USE_DISPOSITION then return false end
    return types.NPC.getDisposition(self.object, player) > cachedSettings.MAX_DISPOSITION
end

local function isVulnerable(player)
    local agility = types.Actor.stats.attributes.agility(player).modified
    local sneak   = types.NPC.stats.skills.sneak(player).modified
    if agility >= cachedSettings.AGILITY_MIN or sneak >= cachedSettings.SNEAK_MIN then return false end
    return true
end

local function buildStealPool(player)
    local pool = {}
    local inv  = types.Actor.inventory(player)

    local equippedCount = {}
    local eqTable = types.Actor.getEquipment(player)
    if eqTable then
        for _, item in pairs(eqTable) do
            if item and item:isValid() then
                local rid = string.lower(item.recordId)
                equippedCount[rid] = (equippedCount[rid] or 0) + 1
            end
        end
    end

    local inventoryCount = {}
    local items = inv:getAll()
    for _, item in ipairs(items) do
        local rid = string.lower(item.recordId)
        inventoryCount[rid] = (inventoryCount[rid] or 0) + item.count
    end

    for _, item in ipairs(items) do
        local rid = string.lower(item.recordId)

        if GOLD_IDS[rid] and item.count > 0 then
            local amount = math.min(
                math.random(cachedSettings.MIN_GOLD, cachedSettings.MAX_GOLD),
                item.count
            )
            pool[#pool + 1] = { kind = "gold", amount = amount }

        elseif cachedSettings.STEAL_ITEMS then

            if STEALABLE_MISC[rid] and item.count > 0 then
                pool[#pool + 1] = { kind = "item", recordId = rid }

            elseif STEALABLE_INGREDIENTS[rid] and item.count > 0 then
                pool[#pool + 1] = { kind = "item", recordId = rid }

            elseif STEALABLE_CLOTHING[rid] and item.count > 0 then
                local worn  = equippedCount[rid] or 0
                local inInv = inventoryCount[rid] or 0
                local free  = inInv - worn
                if free > 0 then
                    pool[#pool + 1] = { kind = "item", recordId = rid }
                end
            end
        end
    end

    return pool
end

local function getRetaliationLine()
    local lines = npcIsKhajiit and RETALIATION_LINES_KHAJIIT or RETALIATION_LINES
    return lines[math.random(#lines)]
end

local function getApologyLine()
    local lines = npcIsKhajiit and APOLOGY_LINES_KHAJIIT or APOLOGY_LINES
    return lines[math.random(#lines)]
end

local function getTauntLine()
    local lines = npcIsKhajiit and TAUNT_LINES_KHAJIIT or TAUNT_LINES
    return lines[math.random(#lines)]
end

local function sendTaunt()
    if not retaliationPlayer or not retaliationPlayer:isValid() then return end
    core.sendGlobalEvent("PickpocketShowMessage", {
        player  = retaliationPlayer,
        message = getTauntLine(),
    })
end

local APOLOGY_ANIM_DURATION = 2.0

local function playApologyAnimation()
    if types.Actor.isDead(self.object) then return end
    self:enableAI(false)
    I.AnimationController.playBlendedAnimation("give02", {
        startKey = "start",
        stopKey  = "stop",
        priority = anim.PRIORITY.Scripted,
        speed    = 1,
    })
    async:newUnsavableSimulationTimer(APOLOGY_ANIM_DURATION, function()
        if self:isActive() and not types.Actor.isDead(self.object) then
            self:enableAI(true)
        end
    end)
end

-- skipUnignore=true means: don't tell detd_ to resume weapon reactions
-- used by the apology path so the scared thief stays passive afterwards
local function clearRetaliation(skipUnignore)
    local wasStandoff = retaliationPhase == "standoff"
    local wasActive   = retaliationPhase ~= nil
    retaliationPhase   = nil
    retaliationTimer   = 0
    retaliationPlayer  = nil
    retaliationRadius  = nil
    retaliationChoice  = nil
    retaliationStartHP = nil
    retaliationHPAcc   = 0
    if wasStandoff then
        stopTracking()
        if not types.Actor.isDead(self) then
            self:enableAI(true)
            types.Actor.setStance(self, types.Actor.STANCE.Nothing)
        end
    end
    if wasActive and not skipUnignore then
        self.object:sendEvent("detd_SetIgnoreWeaponReaction", false)
    end
end

local function startRetaliation(player, choice)
    if not cachedSettings.RETALIATION_ENABLED then return end
    local stance = types.Actor.getStance(player)
    if stance == 1 or stance == 2 then return end
    retaliationPhase  = "watch"
    retaliationTimer  = cachedSettings.RETALIATION_WINDOW
    retaliationPlayer = player
    retaliationRadius = cachedSettings.RETALIATION_RADIUS
    retaliationChoice = choice
    -- suppress detd_npc_sheatheweapon if installed
    self.object:sendEvent("detd_SetIgnoreWeaponReaction", true)
end

local function trySteal(player)
    if math.random() > cachedSettings.STEAL_CHANCE then return end

    local pool = buildStealPool(player)
    if #pool == 0 then return end

    local choice  = pool[math.random(#pool)]
    local message = cachedSettings.SHOW_MESSAGE and randomMessage() or nil

    core.sendGlobalEvent("PickpocketDoSteal", {
        player    = player,
        npc       = self.object,
        choice    = choice,
        message   = message,
        playSound = cachedSettings.PLAY_SOUND,
    })

    startRetaliation(player, choice)
end

local function onActive()
    local rec = types.NPC.record(self.object)
    local race = rec and rec.race or ""
    npcIsKhajiit = KHAJIIT_RACE[race:lower()] or false
    thiefFaction = nil
    for factionId, _ in pairs(THIEF_FACTIONS) do
        if getFactionRank(self.object, factionId) > 0 then
            thiefFaction = factionId
            break
        end
    end
    local classId = rec and rec.class or nil
    thiefByClass = (not thiefFaction) and (classId and THIEF_CLASSES[classId:lower()] or false) or false

    activated = false
    scanTimer = 0
    clearRetaliation(true)
    retaliationScanAcc = 0
end

local function onInactive()
    stopTracking()
    if retaliationPhase == "standoff" and not types.Actor.isDead(self) then
        self:enableAI(true)
        types.Actor.setStance(self, types.Actor.STANCE.Nothing)
    end
    retaliationPhase   = nil
    retaliationTimer   = 0
    retaliationPlayer  = nil
    retaliationRadius  = nil
    retaliationChoice  = nil
    retaliationStartHP = nil
    retaliationScanAcc = 0
    retaliationHPAcc   = 0
    core.sendGlobalEvent("TP_RequestRemoval", self.object)
end

local function onUpdate(dt)
    if not cachedSettings.MOD_ENABLED then return end

    if retaliationPhase then
        -- fast HP-drop check during standoff so the thief reacts quickly to hits
        if retaliationPhase == "standoff" then
            retaliationHPAcc = retaliationHPAcc + dt
            if retaliationHPAcc >= 0.1 then
                retaliationHPAcc = 0
                if retaliationPlayer and retaliationPlayer:isValid()
                   and not types.Actor.isDead(self)
                   and retaliationStartHP then
                    local currentHP = types.Actor.stats.dynamic.health(self).current
                    if currentHP < retaliationStartHP then
                        -- player attacks during standoff, drop everything and fight
                        local target = retaliationPlayer
                        stopTracking()
                        self:enableAI(true)
                        AI.startPackage({ type = "Combat", target = target })
                        retaliationPhase   = nil
                        retaliationTimer   = 0
                        retaliationPlayer  = nil
                        retaliationRadius  = nil
                        retaliationChoice  = nil
                        retaliationStartHP = nil
                        retaliationHPAcc   = 0
                        self.object:sendEvent("detd_SetIgnoreWeaponReaction", false)
                    end
                end
            end
        end

        if retaliationPhase then
            retaliationScanAcc = retaliationScanAcc + dt
            if retaliationScanAcc >= 1 then
                retaliationScanAcc = retaliationScanAcc - 1

                if not retaliationPlayer or not retaliationPlayer:isValid()
                   or types.Actor.isDead(self)
                   or types.Actor.isDead(retaliationPlayer) then
                    clearRetaliation()

                elseif retaliationPhase == "watch" then
                    retaliationTimer = retaliationTimer - 1
                    if retaliationTimer < 0 then
                        clearRetaliation()
                    else
                        local dist = (retaliationPlayer.position - self.position):length()
                        if dist > retaliationRadius then
                            clearRetaliation()
                        else
                            local stance = types.Actor.getStance(retaliationPlayer)
                            if stance == 1 or stance == 2 then
                                local thiefLevel  = types.Actor.stats.level(self.object).current
                                local playerLevel = types.Actor.stats.level(retaliationPlayer).current
                                if playerLevel - thiefLevel >= cachedSettings.RETALIATION_LEVEL_DIFF then
                                    -- thief is outleveled: apologize, return loot, back off
                                    local line = getApologyLine()
                                    core.sendGlobalEvent("PickpocketShowMessage", {
                                        player  = retaliationPlayer,
                                        message = line,
                                    })
                                    playApologyAnimation()
                                    if retaliationChoice then
                                        core.sendGlobalEvent("PickpocketReturn", {
                                            player = retaliationPlayer,
                                            npc    = self.object,
                                            choice = retaliationChoice,
                                        })
                                    end
                                    -- scared thief: keep detd_ suppressed so they don't redraw later
                                    clearRetaliation(true)
                                else
                                    -- player drew weapon: thief warns, starts standoff
                                    local line = getRetaliationLine()
                                    core.sendGlobalEvent("PickpocketShowMessage", {
                                        player  = retaliationPlayer,
                                        message = line,
                                    })
                                    self:enableAI(false)
                                    types.Actor.setStance(self, types.Actor.STANCE.Weapon)
                                    retaliationStartHP = types.Actor.stats.dynamic.health(self).current
                                    retaliationHPAcc   = 0
                                    retaliationPhase   = "standoff"
                                    retaliationTimer   = cachedSettings.RETALIATION_STANDOFF
                                    startTracking(retaliationPlayer)
                                end
                            end
                        end
                    end

                elseif retaliationPhase == "standoff" then
                    local dist = (retaliationPlayer.position - self.position):length()
                    if dist > retaliationRadius * 1.5 then
                        -- player escaped: thief taunts and calms down
                        sendTaunt()
                        clearRetaliation()
                    else
                        local stance = types.Actor.getStance(retaliationPlayer)
                        if stance ~= 1 and stance ~= 2 then
                            -- player sheathed: thief taunts and calms down
                            sendTaunt()
                            clearRetaliation()
                        else
                            retaliationTimer = retaliationTimer - 1
                            if retaliationTimer < 0 then
                                -- standoff expired, player didn't sheathe: attack
                                local target = retaliationPlayer
                                stopTracking()
                                self:enableAI(true)
                                AI.startPackage({ type = "Combat", target = target })
                                retaliationPhase   = nil
                                retaliationTimer   = 0
                                retaliationPlayer  = nil
                                retaliationRadius  = nil
                                retaliationChoice  = nil
                                retaliationStartHP = nil
                                self.object:sendEvent("detd_SetIgnoreWeaponReaction", false)
                            end
                        end
                    end
                end
            end
        end
    end

    if activated then return end
    scanTimer = scanTimer + dt
    if scanTimer < cachedSettings.SCAN_INTERVAL then return end
    scanTimer = 0
    if types.Actor.isDead(self) then activated = true return end
    local stance = types.Actor.getStance(self)
    if stance == 1 or stance == 2 then return end
    local activePkg = AI.getActivePackage()
    if activePkg and activePkg.type == "Follow" then
        return
    end
    local player = nil
    for _, actor in ipairs(nearby.actors) do
        if types.Player.objectIsInstance(actor) then
            player = actor
            break
        end
    end
    if not player then return end
    if isDispositionTooHigh(player) then return end
    if thiefFaction then
        if isFactionProtected(player, thiefFaction) then activated = true return end
    elseif not thiefByClass then
        activated = true return
    end
    if not isVulnerable(player) then activated = true return end
    if (player.position - self.position):length() > cachedSettings.STEAL_RADIUS then return end
    activated = true
    trySteal(player)
end

local function onSettingsUpdated(data)
    cachedSettings = data
end

return {
    engineHandlers = {
        onActive   = onActive,
        onInactive = onInactive,
        onUpdate   = onUpdate,
    },
    eventHandlers = {
        TP_SettingsUpdated = onSettingsUpdated,
    },
}