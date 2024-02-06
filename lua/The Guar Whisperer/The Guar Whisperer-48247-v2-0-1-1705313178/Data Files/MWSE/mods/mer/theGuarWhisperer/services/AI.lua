--[[

    This script handles nice-to-haves such as auto-teleporting and position fixing

]]
local GuarCompanion = require("mer.theGuarWhisperer.GuarCompanion")
local common = require("mer.theGuarWhisperer.common")
local logger = common.createLogger("AI")

local RUN_STATES = {
    --["following"] = true,
    ["moving"] = true,
}

event.register("simulate", function()
    GuarCompanion.referenceManager:iterateReferences(function(_, guar)
        if guar.reference.mobile and RUN_STATES[guar.ai:getAI()] then
            if not guar.rider:isRiding() then
                guar.reference.mobile.isRunning = true
            end
        end
    end)
end)

--Teleport to player when going back outside
---@param e cellChangedEventData
event.register("cellChanged", function(e)
    if not e.cell.isInterior then
        timer.delayOneFrame(function()
            local guars = GuarCompanion.getAll()
            logger:debug("Cell changed to exterior, teleporting %s distance companions", #guars)
            for _, guar in ipairs(GuarCompanion.getAll()) do
                local isFollowing = guar.ai:getAI() == "following"
                    and not guar.rider:isRiding()

                local doTeleport = isFollowing
                    and not guar:isDead()
                    and guar:distanceFrom(tes3.player) > common.config.mcm.teleportDistance

                if doTeleport then
                    logger:debug("Cell change teleport")
                    if e.previousCell.isInterior then
                        --If transitioning from inside, teleport in front of player
                        guar.ai:teleportToPlayer(500)
                    else
                        --If transitioning from outside, trigger regular close distance teleport
                        guar.ai:closeTheDistanceTeleport()
                    end
                else
                    logger:debug("Not teleporting %s. distance: %s, ai: %s, isDead: %s",
                        guar:getName(),
                        guar:distanceFrom(tes3.player),
                        guar.ai:getAI(),
                        guar:isDead())
                end
            end
        end)
    end
end)

local ACTION = {
    undecided = 0,
    melee = 1,
    ranged = 2,
    h2h = 3,
    touchSpell = 4,
    targetSpell = 5,
    summonSpell = 6,
    flee = 7,
    selfSpell = 8,
    useItem = 9,
    useEnchant = 1,
}

local ACTION_CONFIG = {
    [ACTION.undecided]  = { allowed = true, description =  '"Undecided"' },
    [ACTION.melee]  = { allowed = true, description =  '"Attack Melee"' },
    [ACTION.ranged]  = { allowed = true, description =  '"Attack Ranged"' },
    [ACTION.h2h]  = { allowed = true, description =  '"Attack H2H"' },
    [ACTION.touchSpell]  = { allowed = false, description =  '"Use On-touch Spell"' },
    [ACTION.targetSpell]  = { allowed = false, description =  '"Use On-target Spell"' },
    [ACTION.summonSpell]  = { allowed = false, description =  '"Use Summon Spell"' },
    [ACTION.flee]  = { allowed = true, description =  '"Flee"' },
    [ACTION.selfSpell]  = { allowed = false, description =  '"Use Self Spell"' },
    [ACTION.useItem]  = { allowed = false, description =  '"Use Item"' },
    [ACTION.useEnchant]  = { allowed = false, description =  '"Use Enchantment"' },
}


---@param e determineActionEventData
event.register("determinedAction", function(e)
    local guar = GuarCompanion.get(e.session.mobile.reference)
    if guar then
        if guar.lantern:isOn() then
            guar.lantern:turnLanternOff()
        end

        local action = ACTION_CONFIG[e.session.selectedAction]
        if not action then
            logger:debug("No action found for %s", e.session.selectedAction)
            return
        end
        logger:debug("Current action: %d: %s", e.session.selectedAction, action.description)

        --Block actions that might cause issues
        if not action.allowed then
            logger:debug("%s blocking action %s - not allowed", guar:getName(), action.description)
            e.session.selectedAction = ACTION.undecided
        end

        --Flee if in combat while passive
        if e.session.selectedAction ~= 0 and guar:getAttackPolicy() == "passive" then
            logger:debug("%s is passive, Blocking action %s and fleeing", guar:getName(), action.description)
            e.session.selectedAction = ACTION.flee
        end
        local target = e.session.mobile.actionData.target

        --Prevent attacking the player
        if target then
            local targetingCompanion = GuarCompanion.get(target.reference)
            local targetingPlayer = target.reference == tes3.player
            if targetingCompanion or targetingPlayer then
                logger:debug("Target is %s, blocking action %s", target.reference, action.description)
                e.session.selectedAction = ACTION.undecided
                timer.delayOneFrame(function()
                    if not guar:isValid() then return end
                    guar.reference.mobile:stopCombat(true)
                end)
            end
        end

        --Stop combat if too far away
        local targetTooFar = target and target.position:distance(tes3.player.position) > 2000

        ---@type mwseSafeObjectHandle
        local safeTarget = tes3.makeSafeObjectHandle(target)
        if targetTooFar then
            logger:debug("Enemy too far away from player, returning to player")
            timer.delayOneFrame(function()
                if not guar:isValid() then return end
                if not ( safeTarget and safeTarget:valid()) then return end
                if target then -- and target.actionData.aiBehaviorState == tes3.aiBehaviorState.flee then
                    logger:warn("target aiBehaviorState is %d = %s", target.actionData.aiBehaviorState, table.find(tes3.aiBehaviorState, target.actionData.aiBehaviorState))
                    logger:debug("Stopping target combat")
                    target:stopCombat(true)
                end
                logger:debug("Stopping %s combat", guar:getName())
                guar.reference.mobile:stopCombat(true)
                guar.ai:wait()
                --wait to disengage, then follow
                timer.delayOneFrame(function()
                    if not guar:isValid() then return end
                    guar.ai:teleportToPlayer(100)
                    guar.ai:follow()
                end)
            end)
        end
    end
end)


---@param e spellCastEventData
event.register("spellCast", function(e)
    logger:trace("%s %s", e.source.name, e.caster.object.name )
end)

event.register("menuExit", function()
    GuarCompanion.referenceManager:iterateReferences(function(_, guar)
        guar.pack:setSwitch()
    end)
end)


---@param e equipEventData
event.register("equip", function(e)
    local guar = GuarCompanion.get(e.reference)
    if guar then
        logger:debug("no guar, don't equip anything please")
        return false
    end
end)

event.register("loaded", function()
    timer.start{
        duration = 5,
        iterations = -1,
        type = timer.simulate,
        callback = function()
            GuarCompanion.referenceManager:iterateReferences(function(_, guar)
                guar.aiFixer:fixSoundBug()
            end)
        end
    }
end)

---@param e attackHitEventData
event.register("attackHit", function(e)
    --progress level when guar attacks
    local guar = GuarCompanion.get(e.mobile.reference)
    if guar then
        guar.stats:progressLevel(guar.animalType.lvl.attackProgress)
    end
end)