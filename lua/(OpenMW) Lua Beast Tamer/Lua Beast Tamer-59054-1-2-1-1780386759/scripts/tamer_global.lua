local world = require("openmw.world")
local types = require("openmw.types")
local core  = require("openmw.core")

local shared   = require("scripts.tamer_shared")
local data     = require("scripts.tamer_data")
local DEFAULTS = shared.DEFAULTS
local MESSAGES = shared.MESSAGES

local DIET           = shared.DIET
local DEFAULT_DIET   = shared.DEFAULT_DIET
local CREATURE_DIET  = shared.CREATURE_DIET
local FOOD_HERBIVORE = shared.FOOD_HERBIVORE
local FOOD_CARNIVORE = shared.FOOD_CARNIVORE

local CREATURE_SCRIPT = "scripts/tamer_creature.lua"

-- category of a food item: DIET.HERBIVORE | DIET.CARNIVORE | "both" | nil
local function foodCategory(recordId)
    local rid = string.lower(recordId)
    local h = FOOD_HERBIVORE[rid]
    local c = FOOD_CARNIVORE[rid]
    if h and c then return "both" end
    if h then return DIET.HERBIVORE end
    if c then return DIET.CARNIVORE end
    return nil
end

-- diet of a creature, falling back to DEFAULT_DIET when unlisted/invalid
local function dietOf(recordId)
    local d = CREATURE_DIET[string.lower(recordId)]
    if d == DIET.HERBIVORE or d == DIET.CARNIVORE or d == DIET.OMNIVORE then
        return d
    end
    return DEFAULT_DIET
end

local function canEat(diet, category)
    if not category then return false end
    if diet == DIET.OMNIVORE then return true end
    if category == "both"     then return true end
    return diet == category
end

local cachedSettings = {}
for k, v in pairs(DEFAULTS) do cachedSettings[k] = v end

local roster      = {}
local tamedCount  = 0
-- creatures declared lost while in an inactive cell
local pendingHostile = {}

local function log(...)
    if cachedSettings.ENABLE_LOGS then print("[Tamer G]", ...) end
end

local function getPlayer()
    return world.players[1]
end

local function getPlayerLevel()
    local player = getPlayer()
    if not player then return 1 end
    return types.Actor.stats.level(player).current or 1
end

local function msgToPlayer(text)
    for _, player in ipairs(world.players) do
        player:sendEvent("Tamer_ShowMessage", { message = text })
    end
end

-- send a keyed message
local function msgKeyToPlayer(key, creatureId, fallbackName)
    for _, player in ipairs(world.players) do
        player:sendEvent("Tamer_ShowMessage", {
            key        = key,
            creatureId = creatureId,
            name       = fallbackName,
        })
    end
end

local function isTameable(actor)
    if not types.Creature.objectIsInstance(actor) then return false end
    return shared.TAMEABLE_CREATURES[actor.recordId:lower()] == true
end

-- true when the tamed-creature roster is at capacity
local function rosterFull()
    return tamedCount >= cachedSettings.MAX_TAMED
end

-- tell every active tameable creature whether the roster is full
local function broadcastRosterFull()
    local full = rosterFull()
    for _, actor in ipairs(world.activeActors) do
        if actor:hasScript(CREATURE_SCRIPT) then
            actor:sendEvent("Tamer_RosterFull", { full = full })
        end
    end
end

-- ENGINE HANDLERS

local function onActorActive(actor)
    if not types.Creature.objectIsInstance(actor) then return end

    local id = actor.id

    -- a creature declared lost while inactive: flip it hostile now
    if pendingHostile[id] then
        pendingHostile[id] = nil
        if actor:hasScript(CREATURE_SCRIPT) then
            actor:sendEvent("Tamer_BecomeHostile", {})
        end
        return
    end

    -- attach the script to tameable creatures (so onHit can fire)
    if isTameable(actor) or roster[id] then
        if not actor:hasScript(CREATURE_SCRIPT) and not types.Actor.isDead(actor) then
            actor:addScript(CREATURE_SCRIPT)
        end
        if actor:hasScript(CREATURE_SCRIPT) then
            actor:sendEvent("Tamer_SettingsUpdated", cachedSettings)
            actor:sendEvent("Tamer_RosterFull", { full = rosterFull() })
        end
    end
end

local function onSave()
    return {
        roster         = roster,
        tamedCount     = tamedCount,
        pendingHostile = pendingHostile,
    }
end

local function onLoad(d)
    roster         = {}
    tamedCount     = 0
    pendingHostile = {}
    if not d then return end
    if d.roster then
        for k, v in pairs(d.roster) do roster[k] = v end
    end
    tamedCount = d.tamedCount or 0
    if d.pendingHostile then
        for k, v in pairs(d.pendingHostile) do pendingHostile[k] = v end
    end
    log("Loaded, tamedCount=", tamedCount)
end

-- EVENT HANDLERS

local function onSettingsUpdated(s)
    cachedSettings = s
    for _, actor in ipairs(world.activeActors) do
        if actor:hasScript(CREATURE_SCRIPT) then
            actor:sendEvent("Tamer_SettingsUpdated", cachedSettings)
        end
    end
    -- MAX_TAMED may have changed
    broadcastRosterFull()
end

-- creature knockout window elapsed: decide whether it gets tamed
local function onRequestTame(d)
    local creature = d and d.creature
    if not creature or not creature:isValid() then return end
    if types.Actor.isDead(creature) then return end

    if tamedCount >= cachedSettings.MAX_TAMED then
        creature:sendEvent("Tamer_TameRejected", {})
        if cachedSettings.FULL_MESSAGE then
            msgToPlayer(MESSAGES.full)
        end
        return
    end

    roster[creature.id] = true
    tamedCount = tamedCount + 1

    creature:sendEvent("Tamer_DoTame", { player = getPlayer() })

    local rec  = types.Creature.record(creature)
    local name = (rec and rec.name) or creature.recordId
    msgKeyToPlayer("tamed", creature.id, name)
    broadcastRosterFull()
    log("Tamed", creature.recordId, "count=", tamedCount)
end

-- PEACEFUL TAMING

-- success-chance roll based on player stats and the creature's level
local function rollPeacefulTame(creature, player)
    local R = data.PEACEFUL_ROLL

    local playerLevel = 1
    local personality, willpower, luck = 0, 0, 0
    if player and player:isValid() then
        playerLevel = types.Actor.stats.level(player).current or 1
        personality = types.Actor.stats.attributes.personality(player).modified or 0
        willpower   = types.Actor.stats.attributes.willpower(player).modified or 0
        luck        = types.Actor.stats.attributes.luck(player).modified or 0
    end

    local creatureLevel = types.Actor.stats.level(creature).current or 1

    local chance = R.BASE
        + playerLevel   * R.LEVEL_WEIGHT
        + personality   * R.PERSONALITY_WEIGHT
        + willpower     * R.WILLPOWER_WEIGHT
        + luck          * R.LUCK_WEIGHT
        - creatureLevel * R.CREATURE_LEVEL_WEIGHT

    if chance < R.MIN_CHANCE then chance = R.MIN_CHANCE end
    if chance > R.MAX_CHANCE then chance = R.MAX_CHANCE end

    log("Peaceful roll: chance=", chance,
        "(pLvl", playerLevel, "per", personality,
        "wil", willpower, "luck", luck, "cLvl", creatureLevel, ")")

    return (math.random() * 100) <= chance
end

-- player dropped a food item
local function onFoodDropped(d)
    if not cachedSettings.MOD_ENABLED then return end

    local food   = d and d.food
    if not food or not food:isValid() then return end
    if food.cell == nil or food.count <= 0 then return end

    -- which diet(s) this food belongs to
    local category = foodCategory(food.recordId)
    if not category then return end   -- not a listed food item

    local foodPos = food.position

    for _, actor in ipairs(world.activeActors) do
        if types.Creature.objectIsInstance(actor)
           and not roster[actor.id]
           and not types.Actor.isDead(actor)
           and isTameable(actor) then
            local fight = types.Actor.stats.ai.fight(actor).modified or 0
            if fight <= data.PEACEFUL_FIGHT_MAX then
                local offset = actor.position - foodPos
                if offset:length() <= data.PEACEFUL_DETECT_DIST
                   and math.abs(offset.z) <= data.PEACEFUL_HEIGHT_GAP then
                    if not actor:hasScript(CREATURE_SCRIPT) then
                        actor:addScript(CREATURE_SCRIPT)
                        actor:sendEvent("Tamer_SettingsUpdated", cachedSettings)
                        actor:sendEvent("Tamer_RosterFull", { full = rosterFull() })
                    end
                    actor:sendEvent("Tamer_LureToFood", {
                        food    = food,
                        foodPos = foodPos,
                    })
                end
            end
        end
    end
end

-- a creature reached the dropped food: eats one unit, then rolls to be tamed
local function onRequestPeacefulTame(d)
    local creature = d and d.creature
    local food     = d and d.food
    if not creature or not creature:isValid() then return end
    if types.Actor.isDead(creature) then return end

    -- food must still exist
    if not food or not food:isValid()
       or food.cell == nil or food.count <= 0 then
        creature:sendEvent("Tamer_PeacefulTameFailed", {})
        return
    end

    local rec  = types.Creature.record(creature)
    local name = (rec and rec.name) or creature.recordId

    -- the creature walked all the way here, now check whether its diet actually allows this food. if not, it sniffs and refuses
    local category = foodCategory(food.recordId)
    local diet     = dietOf(creature.recordId)
    if not canEat(diet, category) then
        creature:sendEvent("Tamer_PeacefulTameFailed", {})
        msgKeyToPlayer("food_refused", creature.id, name)
        log("Refused food (wrong diet)", creature.recordId)
        return
    end

    -- the creature eats one item off the (possibly stacked) food
    core.sound.playSound3d("Item Ingredient Up", creature)
    food:remove(1)

    -- roster full: the creature still ate the food, but cannot be tamed
    if tamedCount >= cachedSettings.MAX_TAMED then
        creature:sendEvent("Tamer_PeacefulTameFailed", {})
        msgKeyToPlayer("peace_full", creature.id, name)
        log("Peaceful feed, roster full", creature.recordId)
        return
    end

    local player = getPlayer()
    if rollPeacefulTame(creature, player) then
        roster[creature.id] = true
        tamedCount = tamedCount + 1
        creature:sendEvent("Tamer_DoTame", { player = player })
        msgKeyToPlayer("tamed", creature.id, name)
        broadcastRosterFull()
        log("Peacefully tamed", creature.recordId, "count=", tamedCount)
    else
        creature:sendEvent("Tamer_PeacefulTameFailed", {})
        msgKeyToPlayer("tame_fail", creature.id, name)
        log("Peaceful tame failed", creature.recordId)
    end
end

-- player levelled up: tell every active tamed creature to rescale
local function onPlayerLevelUp(d)
    local level = (d and d.level) or getPlayerLevel()
    for _, actor in ipairs(world.activeActors) do
        if roster[actor.id] and actor:hasScript(CREATURE_SCRIPT) then
            actor:sendEvent("Tamer_LevelUp", { level = level })
        end
    end
end

-- player watchdog reported a creature failed to keep up
local function onLoseCreature(d)
    local creature = d and d.creature
    if not creature then return end
    local id = creature.id

    if roster[id] then
        roster[id] = nil
        tamedCount = math.max(0, tamedCount - 1)
    end

    local name = creature.recordId
    if creature:isValid() then
        local rec = types.Creature.record(creature)
        name = (rec and rec.name) or name
    end
    msgKeyToPlayer("lost", id, name)

    -- flip hostile now if active, otherwise queue it for next activation
    local active = false
    for _, actor in ipairs(world.activeActors) do
        if actor.id == id then active = true break end
    end
    if active and creature:isValid() and creature:hasScript(CREATURE_SCRIPT) then
        creature:sendEvent("Tamer_BecomeHostile", {})
    else
        pendingHostile[id] = true
    end
    broadcastRosterFull()
    log("Lost", name)
end

-- a tamed creature died
local function onCreatureDied(d)
    local creature = d and d.creature
    if not creature then return end
    local id = creature.id
    if not roster[id] then return end

    roster[id] = nil
    tamedCount = math.max(0, tamedCount - 1)
    pendingHostile[id] = nil

    local name = creature.recordId
    if creature:isValid() then
        local rec = types.Creature.record(creature)
        name = (rec and rec.name) or name
    end
    msgKeyToPlayer("died", id, name)

    if creature:isValid() and creature:hasScript(CREATURE_SCRIPT) then
        creature:removeScript(CREATURE_SCRIPT)
    end
    broadcastRosterFull()
    log("Died", name, "count=", tamedCount)
end

-- non-tamed creature went inactive: drop its script
local function onCreatureScriptCleanup(d)
    local creature = d and d.creature
    if not creature or not creature:isValid() then return end
    if roster[creature.id] then return end   -- still tamed, keep the script
    if creature:hasScript(CREATURE_SCRIPT) then
        creature:removeScript(CREATURE_SCRIPT)
    end
end

-- a tamed creature asks whether its Combat target is a fellow roster member
local function onQueryTamed(d)
    local creature = d and d.creature
    local target   = d and d.target
    if not creature or not creature:isValid() then return end
    if not target or not target:isValid() then return end
    if roster[target.id] then
        creature:sendEvent("Tamer_DropCombatTarget", { target = target })
    end
end

-- a tameable creature was knocked out
local function onBroadcastSuppress(d)
    if not d or not d.victim or not d.duration then return end
    core.sendGlobalEvent("Tamer_SuppressBroadcast", {
        victim   = d.victim,
        duration = d.duration,
    })
end

return {
    engineHandlers = {
        onActorActive = onActorActive,
        onSave        = onSave,
        onLoad        = onLoad,
    },
    eventHandlers = {
        Tamer_SettingsUpdated      = onSettingsUpdated,
        Tamer_RequestTame          = onRequestTame,
        Tamer_FoodDropped          = onFoodDropped,
        Tamer_RequestPeacefulTame  = onRequestPeacefulTame,
        Tamer_PlayerLevelUp        = onPlayerLevelUp,
        Tamer_LoseCreature         = onLoseCreature,
        Tamer_CreatureDied         = onCreatureDied,
        Tamer_CreatureScriptCleanup = onCreatureScriptCleanup,
        Tamer_QueryTamed           = onQueryTamed,
        Tamer_BroadcastSuppress    = onBroadcastSuppress,
    },
}