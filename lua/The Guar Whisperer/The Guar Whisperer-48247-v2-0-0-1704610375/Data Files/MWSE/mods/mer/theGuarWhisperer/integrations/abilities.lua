local Ability = require("mer.theGuarWhisperer.abilities.Ability")
local Action = require("mer.theGuarWhisperer.abilities.Action")
local Harvest = require("mer.theGuarWhisperer.abilities.harvest")
local Fetch = require("mer.theGuarWhisperer.abilities.fetch")
local Rider = require("mer.theGuarWhisperer.components.Rider")
local Charm = require("mer.theGuarWhisperer.abilities.charm")
local common = require("mer.theGuarWhisperer.common")
local logger = common.createLogger("Abilities")

---@type GuarWhisperer.Ability.newParams[]
local abilities = {
    --Priority 1: specific ref commands
    --charm
    {
        id = "charm",
        label = function(e)
            return string.format("Charm %s", e.targetData.reference.object.name)
        end,
        description = "Attempt to charm the target, increasing their disposition.",
        command = function(e)
            local guar = e.activeCompanion
            local target = e.targetData.reference
            if guar.ai:attemptCommand(60, 90) then
                Action.moveToAction{
                    target = target,
                    guar = guar,
                    activationDistance = 200,
                    playGroup = "idle6",
                    actionDuration = 1,
                    afterAction = function(_)
                        Charm.charm(guar, target)
                        timer.start{
                            duration = 1.0,
                            callback = function()
                                if guar:isValid() then
                                    logger:debug("restorePreviousAI")
                                    guar.ai:restorePreviousAI()
                                end
                            end
                        }
                    end
                }
            end
        end,
        requirements = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            local target = e.targetData and e.targetData.reference
            if not target then return false end
            local inCombat = target.mobile
                and target.mobile.inCombat

            return  target.baseObject.objectType == tes3.objectType.npc
                and guar.needs:hasTrustLevel("Familiar")
                and not inCombat
        end,
    },

    --attack
    {
        id = "attack",
        label = function(e)
            return string.format("Attack %s", e.targetData.reference.object.name)
        end,
        description = "Attacks the selected target.",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            if guar.ai:attemptCommand(40, 80) then
                guar:setAttackPolicy("defend")
                guar.ai:attack(e.targetData.reference)
            end
        end,
        requirements = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            local targetMobile = e.targetData.reference
                and e.targetData.reference.mobile
            --Has target
            if not targetMobile then
                return false
            end
            --Target is alive
            if targetMobile.health.current < 1 then
                return false
            end
            --Target isn't friendly
            ---@param actor tes3mobileActor
            for actor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
                if actor.reference == e.targetData.reference then
                    return false
                end
            end
            --Target isn't another companion
            if e.activeCompanion.get(e.targetData.reference) then
                return false
            end
            --Has prerequisites for attack command
            if not guar.needs:hasTrustLevel("Wary")then
                return false
            end
            --Not passive
            if guar.refData.attackPolicy == "passive" and not tes3.mobilePlayer.inCombat then
                return false
            end
            return true
        end
    },

    --eat
    {
        id = "eat",
        label = function(e)
            return string.format("Eat %s", e.targetData.reference.object.name)
        end,
        description = "Eat the selected item or plant.",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            local target = e.targetData.reference
            if guar.ai:attemptCommand(10, 50) then
                Action.moveToAction{
                    target = target,
                    guar = guar,
                    activationDistance = 200,
                    playGroup = "idle6",
                    actionDuration = 1.0,
                    afterAction = function(_)
                        logger:debug("eatFromWorld")
                        guar.mouth:eatFromWorld(target)
                        timer.start{
                            duration = 1.0,
                            callback = function()
                                if guar:isValid() then
                                    logger:debug("restorePreviousAI")
                                    guar.ai:restorePreviousAI()
                                end
                            end
                        }
                    end
                }
            end
        end,
        requirements = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            return guar
                and (not guar.mouth:hasCarriedItems())
                and e.targetData.reference ~= nil
                and guar:canEat(e.targetData.reference)
                and guar.needs:hasTrustLevel("Wary")
        end,
        activationDistance = 300,
    },

    --harvest
    {
        id = "harvest",
        label = function(e)
            return string.format("Harvest %s", e.targetData.reference.object.name)
        end,
        description = "Harvest the selected plant.",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            local target = e.targetData.reference
            if not target then
                logger:error("Harvest command: No target")
                return
            end
            if guar.ai:attemptCommand(30, 70) then
                Action.moveToAction{
                    target = target,
                    guar = guar,
                    activationDistance = 400,
                    playGroup = "idle6",
                    actionDuration = 1.0,
                    afterAction = function(_)
                        logger:debug("harvest %s", target.id)
                        local success = guar.mouth:harvestItem(target, true)
                        if not success then
                            tes3.messageBox(guar:format("{Name} wasn't able to harvest anything."))
                        end
                        guar.stats:progressLevel(guar.animalType.lvl.fetchProgress)
                        timer.start{
                            duration = 1.0,
                            callback = function()
                                if guar:isValid() then
                                    logger:debug("returning")
                                    guar.ai:returnTo()
                                end
                            end
                        }
                    end
                }
            end
        end,
        requirements = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            local reference = e.targetData.reference
            return guar:isDead() ~= true
                and Harvest.canHarvest(reference)
                and tes3.hasOwnershipAccess { target = reference }
                and guar.needs:hasTrustLevel("Familiar")
        end,
        activationDistance = 400,
    },

    --fetch
    {
        id = "fetch",
        label = function(e)
            return string.format("Fetch %s", e.targetData.reference.object.name)
        end,
        description = "Bring the selected item back to the player.",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            local target = e.targetData.reference
            if guar.ai:attemptCommand(40, 80) then
                Fetch.fetch(guar, target)
            end
        end,
        requirements = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            local reference = e.targetData.reference
            return Fetch.canFetch(reference)
                and (not guar.mouth:hasCarriedItems())
                and tes3.hasOwnershipAccess { target = reference }
                and guar.needs:hasTrustLevel("Familiar")
        end,
        activationDistance = 100,
    },

    {
        id = "steal",
        label = function(e)
            return string.format("Steal %s", e.targetData.reference.object.name)
        end,
        description = "Steal the selected item and bring it back to the player. Dont get caught!",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            local target = e.targetData.reference
            if guar.ai:attemptCommand(50, 90) then
                Action.moveToAction{
                    target = target,
                    guar = guar,
                    activationDistance = 400,
                    playGroup = "idle6",
                    actionDuration = 1.0,
                    afterAction = function(_)
                        logger:debug("fetch")
                        guar.mouth:pickUpItem(target)
                        guar.stats:progressLevel(guar.animalType.lvl.fetchProgress)
                        timer.start{
                            duration = 1.0,
                            callback = function()
                                if guar:isValid() then
                                    logger:debug("returning")
                                    guar.ai:returnTo()
                                end
                            end
                        }
                    end
                }
            end
        end,
        requirements = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            local reference = e.targetData.reference
            return Fetch.canFetch(reference)
                and (not guar.mouth:hasCarriedItems())
                and (not tes3.hasOwnershipAccess { target = e.targetData.reference })
                and guar.needs:hasTrustLevel("Familiar")
        end,
        doSteal = true,
        activationDistance = 100,
    },

    --priority 4: close-up commands

    --pet
    {
        id = "pet",
        label = function()
            return "Pet"
        end,
        description = "Pet your guar to increase its happiness.",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            guar:pet()
        end,
        requirements = function(e)
            return e.inMenu
        end,
    },

    --feed
    {
        id = "feed",
        label = function()
            return "Feed"
        end,
        description = "Feed your guar something from your inventory.",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            guar.mouth:feed()
        end,
        requirements = function(e)
            return e.inMenu
        end,
    },
    {
        id = "follow",
        label = function()
            return "Follow me"
        end,
        description = "Start following the player.",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion

            if guar:isOverEncumbered() then
                tes3.messageBox(guar:format("{Name} is over-encumbered and cannot move."))
                guar.ai:wait()
                return
            end

            if guar.ai:attemptCommand(40, 70) then
                tes3.messageBox("Following")
                guar.ai:returnTo()
            end
        end,
        requirements = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            return (e.targetData.intersection == nil or e.targetData.reference)
                and guar.ai:getAI() ~= "following"
                and guar.needs:hasTrustLevel("Wary")
                and ( Rider.getRefBeingRidden() ~= e.activeCompanion.reference)
        end
    },
    {
        id = "move",
        label = function()
            return "Move"
        end,
        description = "Move to the selected location.",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion

            if guar:isOverEncumbered() then
                tes3.messageBox(guar:format("{Name} is over-encumbered and cannot move."))
                guar.ai:wait()
                return
            end

            if guar.ai:attemptCommand(40, 70) then
                tes3.messageBox(guar:format("{Name} moving to location"))
                guar.ai:moveTo(e.targetData.intersection)
            end
        end,
        requirements = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            return e.targetData.intersection ~= nil
                and (not e.targetData.reference)
                and guar.needs:hasTrustLevel("Wary")
        end
    },

    {
        id = "wait",
        label = function()
            return "Wait"
        end,
        description = "Wait here.",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            if guar.ai:attemptCommand(20, 60) then
                tes3.messageBox("Waiting")
                guar.ai:wait()
            end
        end,
        requirements = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            return --(e.targetData.intersection == nil or e.targetData.reference)
                --and
                guar.ai:getAI() ~= "waiting"
        end
    },

    {
        id = "wander",
        label = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            return "Wander"
        end,
        description = "Wander around the area.",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion

            if guar:isOverEncumbered() then
                tes3.messageBox(guar:format("{Name} is over-encumbered and cannot move."))
                guar.ai:wait()
                return
            end

            tes3.messageBox("Wandering")
            guar.ai:wander()
        end,
        requirements = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            return --(e.targetData.intersection == nil or e.targetData.reference)
                --and
                guar.ai:getAI() ~= "wandering"
        end
    },
    {
        id = "letMePass",
        --Position on top of player to break collision
        label = function()
            return "Let me pass"
        end,
        description = "Positions the guar on top of the player, breaking collision and allowing you to move past it.",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            timer.delayOneFrame(function()
                if not guar:isValid() then return end
                logger:debug("letMePass - disabling collision")
                tes3.positionCell {
                    reference = guar.reference,
                    position = tes3.player.position,
                    cell = tes3.player.cell
                }
                guar.mobile.mobToMobCollision = false
                timer.start{
                    duration = 1.0,
                    callback = function()
                        if guar:isValid() then
                            logger:debug("letMePass - enabling collision")
                            guar.mobile.mobToMobCollision = true
                        end
                    end
                }
            end)
        end,
        requirements = function(e)
            return e.inMenu
        end,
    },

    --priority 5: uncommon movement commands

    {
        id = "equipPack",
        label = function()
            return "Equip pack"
        end,
        description = "Equip a backpack to enable companion share.",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            guar.pack:equipPack()
        end,
        requirements = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            return e.inMenu and guar.pack:canEquipPack()

        end,
    },
    {
        id = "unequipPack",
        label = function()
            return "Unequip pack"
        end,
        description = "Unequip the guar's backpack.",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            guar.pack:unequipPack()
        end,
        requirements = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            return (e.inMenu and guar.pack:hasPack())
        end,
    },

    {
        id = "pacify",
        label = function()
            return "Pacify"
        end,
        description = "Stop your guar from engaging in combat.",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            guar:setAttackPolicy("passive")
            tes3.messageBox(guar:format("{Name} will no longer engage in combat."))
        end,
        requirements = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            return (e.inMenu and guar:getAttackPolicy() ~= "passive")
        end
    },
    {
        id = "defend",
        label = function()
            return "Defend"
        end,
        description = "Your guar will defend you in combat.",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            if guar.ai:attemptCommand(40, 60) then
                guar:setAttackPolicy("defend")
                tes3.messageBox(guar:format("{Name} will now defend you in battle."))
            end
        end,
        requirements = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            return (e.inMenu and guar:getAttackPolicy() ~= "defend")
        end
    },

    --priority 6: uncommon up-close commands
    {
        id = "breed",
        label = function(e)
            return "Breed"
        end,
        description = "Breed with another guar to make a baby guar.",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            if guar.ai:attemptCommand(80, 90) then
                local guar = e.activeCompanion
                guar.genetics:breed()
            end
        end,
        requirements = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            return e.inMenu
                and guar.genetics:getCanConceive()
        end,
    },
    {
        id = "rename",
        label = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            return "Rename"
        end,
        description = "Rename your guar",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            guar:rename()
        end,
        requirements = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            return e.inMenu
        end,
    },
    {
        id = "getStatus",
        label = function(e)
            return "Get status"
        end,
        description = "Check the health, happiness, trust and hunger of your guar.",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            guar:getStatusMenu()
        end,
        requirements = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            return e.inMenu
        end,
    },

    {
        id = "goHome",
        label = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            return string.format("Go home (%s)", tes3.getCell { id = guar.refData.home.cell })
        end,
        description = "Send your guar back to their home location.",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            if guar.ai:attemptCommand(50, 70) then
                guar:goHome()
            end
        end,
        requirements = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            return (
                e.inMenu and
                guar:getHome() and
                guar.needs:hasTrustLevel("Wary")
                and (not guar.rider:isRiding())
            )
        end,
    },

    {
        id = "takeMeHome",
        label = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            return string.format("Take me home (%s: %s)",
                tes3.getCell { id = guar.refData.home.cell },
                guar:getTravelTimeText()
            )
        end,
        description = "Ride your guar back to its home location.",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            if guar.ai:attemptCommand(50, 80) then
                guar:goHome { takeMe = true }
            end
        end,
        requirements = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            return e.inMenu
                and guar:getHome()
                and guar.needs:hasTrustLevel("Wary")
                and not guar.genetics:isBaby()
        end,
    },

    {
        id = "setHome",
        label = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            return string.format("Set home (%s)", guar.reference.cell)
        end,
        description = "Set the guar's current location as their home point.",
        command = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            guar:setHome(
                guar.reference.position,
                guar.reference.cell
            )
        end,
        requirements = function(e)
            ---@type GuarWhisperer.GuarCompanion
            local guar = e.activeCompanion
            return (e.inMenu and guar.needs:hasTrustLevel("Wary"))
        end,
    },
}

for _, data in ipairs(abilities) do
    Ability.register(data)
end

require("mer.theGuarWhisperer.abilities.ride")