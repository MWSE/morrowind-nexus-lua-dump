local self  = require("openmw.self")
local types = require("openmw.types")
local core  = require("openmw.core")
local async = require("openmw.async")
local I     = require("openmw.interfaces")
local AI    = I.AI

local shared   = require("scripts.tamer_shared")
local data     = require("scripts.tamer_data")
local DEFAULTS = shared.DEFAULTS

local cachedSettings = {}
for k, v in pairs(DEFAULTS) do cachedSettings[k] = v end

-- the three dynamic stats that get boosted
local DYNAMIC_STATS = { "health", "magicka", "fatigue" }

local PEACEFUL_FIGHT = 10    -- a tamed creature's fight value
local ESCAPED_FIGHT  = 100   -- fight value once it breaks free

-- runtime state
local tamed       = false
local waiting     = false
local knockedOut  = false
local player      = nil
local rosterFull  = false

-- level-scaling state
local origAttr          = nil
local origDyn           = nil
local creatureBaseLevel = nil
local tamerLevel        = nil   -- displayed level (creatureBaseLevel + playerLevel - 1)

local hitHandlerRegistered = false

local function log(...)
    if cachedSettings.ENABLE_LOGS then
        print("[Tamer C]", self.object.recordId, ...)
    end
end

-- HELPERS

local function getName()
    local rec = types.Creature.record(self.object)
    return (rec and rec.name) or self.object.recordId
end

local function getPlayerLevel()
    if player and player:isValid() then
        return types.Actor.stats.level(player).current
    end
    return 1
end

-- LEVEL SCALING

local function recomputeStats(fillFull)
    if not tamed or not origAttr or not origDyn then return end

    local playerLevel  = getPlayerLevel()
    local levelsGained = math.max(0, playerLevel - 1)
    local mult = 1 + (cachedSettings.STAT_GAIN_PERCENT / 100) * levelsGained

    local preFrac = {}
    for _, name in ipairs(DYNAMIC_STATS) do
        local stat = types.Actor.stats.dynamic[name](self)
        local maxv = (stat.base or 0) + (stat.modifier or 0)
        preFrac[name] = (maxv > 0) and math.max(0, stat.current / maxv) or 1
        if preFrac[name] > 1 then preFrac[name] = 1 end
    end

    -- boost attributes from the pristine snapshot
    for _, attr in ipairs(data.BOOST_ATTRIBUTES) do
        local stat = types.Actor.stats.attributes[attr](self)
        if stat and origAttr[attr] then
            stat.base = math.floor(origAttr[attr] * mult + 0.5)
        end
    end

    for _, name in ipairs(DYNAMIC_STATS) do
        local stat   = types.Actor.stats.dynamic[name](self)
        local target = math.floor((origDyn[name] or 0) * mult + 0.5)
        stat.base = target
        local maxv = target + (stat.modifier or 0)
        if fillFull then
            stat.current = maxv
        else
            stat.current = math.min(maxv,
                                    math.floor(maxv * preFrac[name] + 0.5))
        end
    end

    tamerLevel = (creatureBaseLevel or 1) + levelsGained
    types.Actor.stats.level(self).current = tamerLevel

    log("Stats recomputed, levelsGained=", levelsGained, "level=", tamerLevel)
end

-- the current level-scaling multiplier
local function currentMult()
    local levelsGained = math.max(0, getPlayerLevel() - 1)
    return 1 + (cachedSettings.STAT_GAIN_PERCENT / 100) * levelsGained
end

local function baseAttackRange()
    local rec = types.Creature.record(self.object)
    local atk = rec and rec.attack
    if not atk or #atk < 2 then return nil, nil end
    local lo, hi
    for i = 1, #atk - 1, 2 do
        local amin = atk[i]     or 0
        local amax = atk[i + 1] or 0
        if not lo or amin < lo then lo = amin end
        if not hi or amax > hi then hi = amax end
    end
    return lo, hi
end

-- tell the player script our current state so its caches stay fresh
local function reportState(justTamed)
    if not tamed then return end
    if not player or not player:isValid() then return end

    local lo, hi = baseAttackRange()
    local mult   = currentMult()
    player:sendEvent("Tamer_ReportState", {
        creature  = self.object,
        waiting   = waiting,
        level     = tamerLevel or 1,
        justTamed = justTamed or false,
        -- boosted display values
        minDamage = lo and (lo * mult) or nil,
        maxDamage = hi and (hi * mult) or nil,
    })
end

-- tell the damage global our current outgoing-damage multiplier, so the damage scripts on victims scale our hits
local function reportDamageMult()
    if not tamed then
        core.sendGlobalEvent("Tamer_ClearDamageMult", { creatureId = self.object.id })
        return
    end
    core.sendGlobalEvent("Tamer_SetDamageMult", {
        creature = self.object,
        mult     = currentMult(),
    })
end

local function startFollow()
    if not player or not player:isValid() then return end
    AI.removePackages("Wander")
    AI.startPackage({
        type        = "Follow",
        target      = player,
        isRepeat    = false,
        cancelOther = true,
    })
end

local function startWait()
    AI.removePackages("Follow")
    AI.startPackage({
        type     = "Wander",
        distance = 0,
        duration = 0,
        isRepeat = true,
    })
end

-- COMBAT SUPPRESSION

local function suppressTamedCombat()
    if not tamed then return end
    -- dead creature: its script is being torn down
    if types.Actor.isDead(self.object) then return end
    AI.filterPackages(function(p)
        if p.type ~= "Combat" then return true end
        local tgt = p.target
        if not tgt or not tgt:isValid() then return true end
        if types.Player.objectIsInstance(tgt) then
            return false   -- never fight the player
        end
        -- target is non-hostile (e.g. calmed): drop combat directly
        if types.Actor.objectIsInstance(tgt) then
            local f = types.Actor.stats.ai.fight(tgt)
            if f and (f.modified or 0) <= data.PEACEFUL_FIGHT_MAX then
                return false
            end
        end
        -- ask the global whether this target is a roster member
        core.sendGlobalEvent("Tamer_QueryTamed", {
            creature = self.object,
            target   = tgt,
        })
        return true        -- the global resolves it via Tamer_DropCombatTarget
    end)
    async:newUnsavableSimulationTimer(0.5, suppressTamedCombat)
end

-- global confirmed a Combat target is a fellow tamed creature
local function onDropCombatTarget(d)
    if not tamed then return end
    local victim = d and d.target
    if not victim then return end
    AI.filterPackages(function(p)
        if p.type ~= "Combat" then return true end
        return not (p.target and p.target == victim)
    end)
end

-- KNOCKOUT

local function suppressKnockoutCombat()
    if not knockedOut then return end
    if types.Actor.isDead(self.object) then return end
    AI.filterPackages(function(p) return p.type ~= "Combat" end)
    async:newUnsavableSimulationTimer(0.2, suppressKnockoutCombat)
end

local savedFatigue = nil

local function startKnockout()
    if knockedOut then return end
    knockedOut = true

    -- save from the lethal blow
    local health = types.Actor.stats.dynamic.health(self)
    health.current = 100000

    -- drain fatigue so the creature visibly goes down
    local fatigue = types.Actor.stats.dynamic.fatigue(self)
    savedFatigue = fatigue.current
    fatigue.current = -300

    suppressKnockoutCombat()

    -- announce the knockout to the player
    if player and player:isValid() then
        player:sendEvent("Tamer_ShowMessage", {
            key        = "knockout",
            creatureId = self.object.id,
            name       = getName(),
        })
    end

    -- tell nearby actors to stop attacking the downed creature
    core.sendGlobalEvent("Tamer_BroadcastSuppress", {
        victim   = self.object,
        duration = cachedSettings.KNOCKOUT_DURATION,
    })

    -- pull health down to 1 next frame
    async:newUnsavableSimulationTimer(0, function()
        if not knockedOut then return end
        local hs = types.Actor.stats.dynamic.health(self)
        hs.current = 1
    end)

    -- after the window: if still down and alive, request taming
    async:newUnsavableSimulationTimer(cachedSettings.KNOCKOUT_DURATION, function()
        if not knockedOut then return end
        if types.Actor.isDead(self.object) then return end
        core.sendGlobalEvent("Tamer_RequestTame", { creature = self.object })
    end)

    log("Knocked out")
end

-- if the roster is not full but becomes full while mid-knockout
local function recoverHostile()
    knockedOut = false
    core.sendGlobalEvent("Tamer_KnockoutEnded", { creature = self.object })

    local health = types.Actor.stats.dynamic.health(self)
    local maxHp  = health.base + health.modifier
    health.current = math.max(1, math.floor(maxHp * 0.1))

    local fatigue    = types.Actor.stats.dynamic.fatigue(self)
    local maxFatigue = fatigue.base + fatigue.modifier
    fatigue.current  = savedFatigue or (maxFatigue * 0.5)
    savedFatigue     = nil

    self.type.setStance(self, 0)
end

-- COMBAT HANDLER

local function estimateFinalDamage(attack)
    local rawDmg = (attack.damage and attack.damage.health) or 0
    if rawDmg <= 0 then return 0 end
    local sim = { damage = { health = rawDmg }, attacker = attack.attacker }
    I.Combat.adjustDamageForDifficulty(sim, self.object)
    return sim.damage.health or rawDmg
end

local function handleOnHit(attack)
    if not cachedSettings.MOD_ENABLED then return end

    -- already tamed: ignore all hits, no re-knockout
    if tamed then return end

    -- while down: a clean hit is a finishing blow
    if knockedOut then
        if attack.successful then
            knockedOut   = false
            savedFatigue = nil
            core.sendGlobalEvent("Tamer_KnockoutEnded", { creature = self.object })
            local hs = types.Actor.stats.dynamic.health(self)
            hs.current = 0
        end
        return
    end

    if not cachedSettings.KNOCKOUT_ENABLED then return end

    if not attack.attacker or not attack.attacker:isValid() then return end
    -- only the player can knock out / tame
    if not types.Player.objectIsInstance(attack.attacker) then return end
    -- melee only
    if attack.sourceType ~= I.Combat.ATTACK_SOURCE_TYPES.Melee then return end

    -- not eligible to begin with
    if not shared.TAMEABLE_CREATURES[self.object.recordId:lower()] then return end

    local estDmg = estimateFinalDamage(attack)
    if not attack.successful and estDmg <= 0 then return end

    -- blunt-only gate
    if cachedSettings.BLUNT_ONLY then
        if not attack.weapon or not attack.weapon:isValid() then return end
        local rec = types.Weapon.record(attack.weapon)
        if not rec or not data.BLUNT_TYPES[rec.type] then return end
    end

    -- only act on what would be a lethal blow
    if estDmg <= 0 then return end
    local health = types.Actor.stats.dynamic.health(self)
    local buffer = (health.current <= 2) and 5.0 or 1.0
    if health.current - (estDmg * buffer) > 0 then return end

    -- roster full: don't knock out
    if rosterFull then
        if cachedSettings.FULL_MESSAGE and types.Player.objectIsInstance(attack.attacker) then
            attack.attacker:sendEvent("Tamer_ShowMessage", {
                message = shared.MESSAGES.full,
            })
        end
        return
    end

    player = attack.attacker
    startKnockout()
end

-- PEACEFUL TAMING

local PEACE_TICK           = 0.3   -- arrival poll interval
local PEACE_ARRIVE_DIST    = 70    -- close enough to the food to eat it
local PEACE_TRAVEL_TIMEOUT = 20    -- give up walking after this many seconds

-- peaceLure: nil | { food, foodPos, phase, elapsed }
-- phase: 'walking' | 'eat_wait'
local peaceLure        = nil
local peaceTickRunning = false
local peaceTick

local function clearPeaceLure()
    if peaceLure then
        AI.removePackages("Travel")
        peaceLure = nil
    end
    peaceTickRunning = false
end

local function peaceBlocked()
    local pkg = AI.getActivePackage(self.object)
    local t   = pkg and pkg.type
    return t == "Combat"
end

peaceTick = function()
    if not peaceLure then
        peaceTickRunning = false
        return
    end
    if types.Actor.isDead(self.object) or tamed or knockedOut then
        clearPeaceLure()
        return
    end
    if peaceBlocked() then
        clearPeaceLure()
        return
    end

    peaceLure.elapsed = (peaceLure.elapsed or 0) + PEACE_TICK

    local dist       = (self.position - peaceLure.foodPos):length()
    local pkg        = AI.getActivePackage(self.object)
    local travelDone = not pkg or pkg.type ~= "Travel"

    -- still walking and within the time budget: keep polling
    if dist > PEACE_ARRIVE_DIST
       and not travelDone
       and peaceLure.elapsed < PEACE_TRAVEL_TIMEOUT then
        async:newUnsavableSimulationTimer(PEACE_TICK, peaceTick)
        return
    end

    AI.removePackages("Travel")

    local food = peaceLure.food
    if dist <= PEACE_ARRIVE_DIST
       and food and food:isValid() and food.cell and food.count > 0 then
        -- reached the food: hand off to the global for the eat + dice roll
        peaceLure.phase  = "eat_wait"
        peaceTickRunning = false
        core.sendGlobalEvent("Tamer_RequestPeacefulTame", {
            creature = self.object,
            food     = food,
        })
    else
        -- couldn't reach it, or it's gone: drop back to wandering
        clearPeaceLure()
    end
end

-- global sent this creature after dropped food
local function onLureToFood(d)
    if not cachedSettings.MOD_ENABLED then return end
    if tamed or knockedOut   then return end
    if types.Actor.isDead(self.object)     then return end
    if peaceLure                           then return end   -- one attempt at a time
    if peaceBlocked()                      then return end
    if not d or not d.food or not d.food:isValid() then return end
    if not d.foodPos                       then return end

    peaceLure = {
        food    = d.food,
        foodPos = d.foodPos,
        phase   = "walking",
        elapsed = 0,
    }

    AI.startPackage({
        type         = "Travel",
        destPosition = d.foodPos,
        cancelOther  = false,
    })

    if not peaceTickRunning then
        peaceTickRunning = true
        async:newUnsavableSimulationTimer(PEACE_TICK, peaceTick)
    end
    log("Lured to food")
end

-- global rolled the dice and the creature was not tamed
local function onPeacefulTameFailed()
    clearPeaceLure()
    log("Peaceful tame failed")
end

-- ENGINE HANDLERS

local function onActive()
    if not hitHandlerRegistered then
        hitHandlerRegistered = true
        I.Combat.addOnHitHandler(handleOnHit)
    end
    if tamed then
        recomputeStats()
        types.Actor.stats.ai.fight(self).base = PEACEFUL_FIGHT
        self.type.setStance(self, 0)
        if waiting then startWait() else startFollow() end
        suppressTamedCombat()
        reportState()
        reportDamageMult()
        self.object:sendEvent("Tamer_Tamed", {})
    end
end

local function onInactive()
    clearPeaceLure()
    -- non-tamed creatures don't need a persistent script
    if not tamed then
        core.sendGlobalEvent("Tamer_CreatureScriptCleanup", { creature = self.object })
    end
end

local function onSave()
    return {
        tamed             = tamed,
        waiting           = waiting,
        player            = player,
        origAttr          = origAttr,
        origDyn           = origDyn,
        creatureBaseLevel = creatureBaseLevel,
        tamerLevel        = tamerLevel,
    }
end

local function onLoad(d)
    if not d then return end
    tamed             = d.tamed or false
    waiting           = d.waiting or false
    player            = d.player
    origAttr          = d.origAttr
    origDyn           = d.origDyn
    creatureBaseLevel = d.creatureBaseLevel
    tamerLevel        = d.tamerLevel

    if tamed then
        recomputeStats()
        types.Actor.stats.ai.fight(self).base = PEACEFUL_FIGHT
        if waiting then startWait() else startFollow() end
        suppressTamedCombat()
        reportState()
        reportDamageMult()
    end
end

-- EVENT HANDLERS

local function onSettingsUpdated(s)
    for k in pairs(cachedSettings) do
        if s[k] ~= nil then cachedSettings[k] = s[k] end
    end
    -- a STAT_GAIN_PERCENT change re-derives everything from the snapshot
    if tamed then recomputeStats() end
end

-- global pushes whether the tamed-creature roster is at capacity
local function onRosterFull(d)
    rosterFull = d and d.full or false
end

-- global approved the tame
local function onDoTame(d)
    if tamed then return end
    clearPeaceLure()
    knockedOut = false
    tamed      = true
    waiting    = false
    if d and d.player and d.player:isValid() then
        player = d.player
    end

    -- restore the creature to a healthy state
    local health = types.Actor.stats.dynamic.health(self)
    health.current = health.base + health.modifier

    local fatigue = types.Actor.stats.dynamic.fatigue(self)
    fatigue.current = fatigue.base + fatigue.modifier
    savedFatigue = nil

    -- peaceful towards the player
    types.Actor.stats.ai.fight(self).base = PEACEFUL_FIGHT
    self.type.setStance(self, 0)

    origAttr = {}
    for _, attr in ipairs(data.BOOST_ATTRIBUTES) do
        origAttr[attr] = types.Actor.stats.attributes[attr](self).base
    end
    origDyn = {}
    for _, name in ipairs(DYNAMIC_STATS) do
        origDyn[name] = types.Actor.stats.dynamic[name](self).base
    end
    creatureBaseLevel = types.Actor.stats.level(self).current or 1

    -- scale to player level and fill all dynamic stats to their boosted max
    recomputeStats(true)

    startFollow()
    suppressTamedCombat()
    reportState(true)
    reportDamageMult()
    -- tell other creature-behaviour mods (e.g. Devilishly Peaceful Wildlife) to stop forcing this creature hostile while it is tamed
    self.object:sendEvent("Tamer_Tamed", {})
    log("Tamed")
end

-- global rejected the tame (roster full)
local function onTameRejected()
    recoverHostile()
    log("Tame rejected (full)")
end

-- player levelled up
local function onLevelUp()
    if not tamed then return end
    recomputeStats()
    reportState()
    reportDamageMult()
end

-- player ordered wait / follow toggle
local function onToggleWait()
    if not tamed then return end
    if not cachedSettings.ALLOW_WAIT then return end

    waiting = not waiting
    if waiting then
        startWait()
    else
        startFollow()
    end
    if player and player:isValid() then
        player:sendEvent("Tamer_OrderResult", {
            creatureId = self.object.id,
            name       = getName(),
            waiting    = waiting,
        })
    end
end

-- player petted this creature: heal a small amount and report back
local HEAL_MIN = 3
local HEAL_MAX = 5

local function onPetCreature()
    if not tamed then return end
    if types.Actor.isDead(self.object) then return end

    local health = types.Actor.stats.dynamic.health(self)
    local maxHp  = health.base + health.modifier
    local healed = math.random(HEAL_MIN, HEAL_MAX)
    health.current = math.min(maxHp, health.current + healed)

    if player and player:isValid() then
        player:sendEvent("Tamer_ShowMessage", {
            key        = "petted",
            creatureId = self.object.id,
            name       = getName(),
        })
    end
    log("Petted, healed", healed)
end

-- global declared this creature lost
local function onBecomeHostile()
    tamed      = false
    waiting    = false
    knockedOut = false

    types.Actor.stats.ai.fight(self).base = ESCAPED_FIGHT
    AI.removePackages("Follow")
    AI.startPackage({
        type     = "Wander",
        distance = 256,
        duration = 10800,
        isRepeat = true,
    })
    if player and player:isValid() then
        AI.startPackage({ type = "Combat", target = player })
        player:sendEvent("Tamer_CreatureGone", { creatureId = self.object.id })
    end
    core.sendGlobalEvent("Tamer_CreatureScriptCleanup", { creature = self.object })
    core.sendGlobalEvent("Tamer_ClearDamageMult", { creatureId = self.object.id })
    -- no longer tamed: other creature-behaviour mods may resume normal control
    self.object:sendEvent("Tamer_Untamed", {})
    log("Turned hostile (lost)")
end

local function onCreatureDied()
    if tamed then
        if player and player:isValid() then
            player:sendEvent("Tamer_CreatureGone", { creatureId = self.object.id })
        end
        core.sendGlobalEvent("Tamer_CreatureDied", { creature = self.object })
        core.sendGlobalEvent("Tamer_ClearDamageMult", { creatureId = self.object.id })
    end
    -- clear state so any timer
    tamed      = false
    knockedOut = false
    clearPeaceLure()
end

return {
    engineHandlers = {
        onActive   = onActive,
        onInactive = onInactive,
        onSave     = onSave,
        onLoad     = onLoad,
    },
    eventHandlers = {
        Tamer_SettingsUpdated   = onSettingsUpdated,
        Tamer_RosterFull        = onRosterFull,
        Tamer_DoTame            = onDoTame,
        Tamer_TameRejected      = onTameRejected,
        Tamer_LevelUp           = onLevelUp,
        Tamer_ToggleWait        = onToggleWait,
        Tamer_PetCreature       = onPetCreature,
        Tamer_BecomeHostile     = onBecomeHostile,
        Tamer_DropCombatTarget  = onDropCombatTarget,
        Tamer_LureToFood        = onLureToFood,
        Tamer_PeacefulTameFailed = onPeacefulTameFailed,
        Died                    = onCreatureDied,
    },
}