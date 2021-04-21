local common = require("celediel.MoreAttentiveGuards.common")
local config = require("celediel.MoreAttentiveGuards.config").getConfig()

local this = {}

-- {{{ helper functions

local function log(...) if config.debug then common.log(...) end end

local function isFriendlyActor(actor)
    for friend in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
        if actor.object.id == friend.object.id or actor.object.baseObject.id == friend.object.baseObject.id then
            return true
        end
    end
    return false
end

local function doChecks(attacker, target)
    if not config.combatEnable then return false end

    -- if player initiates combat or combat is not against player, do nothing
    if attacker == tes3.mobilePlayer or target ~= tes3.mobilePlayer then return false end

    -- inCombat is true after player has taken combat actions or after combat
    -- has gone on awhile, but hopefully the guards will already be attacking by
    -- then. Should be fine in cities, but will prevent players from provoking
    -- NPCs in the wilderness and leading them into town.
    if tes3.mobilePlayer.inCombat and attacker.object.objectType == tes3.objectType.npc then
        log("Player is in combat, not sure who started it, so not helping.")
        return false
    end

    -- first try baseObject, else try object.baseObject, else settle on object
    local obj = attacker.baseObject and attacker.baseObject or
                    (attacker.object.baseObject and attacker.object.baseObject or attacker.object)
    if config.ignored[string.lower(obj.id)] or config.ignored[string.lower(obj.sourceMod)] then
        log("Ignored NPC or creature detected, not helping.")
        return false
    end

    if isFriendlyActor(attacker) then
        log("Friendly actor, not helping.")
        return false
    end

    if tes3.mobilePlayer.bounty and tes3.mobilePlayer.bounty > 0 then
        log("Player is wanted, ignoring combat.")
        return false
    end

    -- ? Guards don't know who started it if the player is being attacked with their weapon out ?
    -- seems to fix weird issue when sneak attacking NPCs in town, guards would kill NPC,
    -- then player would get murder bounty, so guards would come after player
    if tes3.mobilePlayer.weaponReady and attacker.object.objectType == tes3.objectType.npc then
        log("NPC Fight, not sure who started it, not helping.")
        return false
    end

    if attacker.object.isGuard then
        log("Guards don't fight guards!")
        return false
    end

    -- everything was good
    return true
end

local function alertGuards(aggressor, cell)
    log("Checking for guards in cell %s to bring justice to %s", cell.name or cell.id, aggressor.object.name)
    local playerPos = tes3.mobilePlayer.position

    for npc in cell:iterateReferences(tes3.objectType.npc) do
        local distance = playerPos:distance(npc.position)
        if not npc.disabled and npc.object.isGuard and npc.mobile and distance <= config.combatDistance then
            log("Alerting %s, %s units away, to the combat!", npc.object.name, distance)

            if config.combatDialogue then
                local response = common.guardDialogue(npc.object.name,
                                                      table.choice(common.dialogues[config.language].join_combat),
                                                      aggressor)
                log(response)
            end

            npc.mobile:startCombat(aggressor)
        end
    end
end

-- }}}

-- {{{ returned event functions

this.onCombatStarted = function(e)
    if not doChecks(e.actor, e.target) then return end

    for _, cell in pairs(tes3.getActiveCells()) do alertGuards(e.actor, cell) end
end

-- this will stop guards from attacking ignored actors ever
this.onCombatStart = function(e)
    -- first try baseObject, else try object.baseObject, else settle on object
    local target = e.target.object.baseObject and e.target.object.baseObject or
                       (e.target.baseObject and e.target.baseObject or e.target.object)
    local attacker = e.actor.object.baseObject and e.actor.object.baseObject or
                         (e.actor.baseObject and e.actor.baseObject or e.actor.object)

    if (config.ignored[string.lower(target.id)] or config.ignored[string.lower(target.sourceMod)]) and attacker.isGuard then
        log("Combat started against %s by a guard, %s... stopping...", e.target.object.name, e.actor.object.name)
        return false
    end
end

-- }}}

return this

-- vim:fdm=marker
