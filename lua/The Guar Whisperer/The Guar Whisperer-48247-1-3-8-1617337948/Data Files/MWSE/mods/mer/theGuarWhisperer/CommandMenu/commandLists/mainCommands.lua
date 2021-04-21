local common = require("mer.theGuarWhisperer.common")
local animalController = require("mer.theGuarWhisperer.animalController")
local this = {}
this.getTitle = function(e)
    return string.format("Command %s", e.activeCompanion:getName())
end
this.commands = {

  --Priority 1: specific ref commands
  {
    --CHARM
    label = function(e)
        return string.format("Charm %s", e.targetData.reference.object.name)
    end,
    description = "Attempt to charm the target, increasing their disposition.",
    command = function(e)
        e.activeCompanion:moveToAction(e.targetData.reference, "charm")
    end,
    requirements = function(e)
        if not ( e.targetData and e.targetData.reference ) then return false end
        local targetObj = e.targetData.reference.baseObject or 
            e.targetData.reference.object

        return (
            targetObj and
            targetObj.objectType == tes3.objectType.npc and
            e.activeCompanion:hasSkillReqs("charm")
        )
    end
},
{ 
    --ATTACK
    label = function(e)
        return string.format("Attack %s", e.targetData.reference.object.name)
    end,
    description = "Attacks the selected target.",
    command = function(e)
        e.activeCompanion:setAttackPolicy("defend")
        e.activeCompanion:attack(e.targetData.reference)
    end,
    requirements = function(e)
        if not e.targetData.reference then
            return false
        end
        if not e.targetData.reference.mobile then
            return false
        end
        if e.targetData.reference.mobile.health.current < 1 then
            return false
        end
        for actor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
            if actor.reference == e.targetData.reference then
                return false
            end
        end
        if animalController.getAnimal(e.targetData.reference) then
            return false
        end
        if not e.activeCompanion:hasSkillReqs("attack") then
            return false
        end
        if e.activeCompanion.refData.attackPolicy == "passive" and not tes3.mobilePlayer.inCombat then
             return false
        end

        return true
    end
},

{
    --EAT
    label = function(e)
        return string.format("Eat %s", e.targetData.reference.object.name)
    end,
    description = "Eat the selected item or plant.",
    command = function(e)
        e.activeCompanion:moveToAction(e.targetData.reference, "eat")
    end,
    requirements = function(e)
        return (
            e.activeCompanion and
            e.activeCompanion.refData.carriedItems == nil and
            e.targetData.reference and
            e.activeCompanion:canEat(e.targetData.reference) and
            e.activeCompanion:hasSkillReqs("eat")
        )
    end
},
{
    --HARVEST
    label = function(e)
        return string.format("Harvest %s", e.targetData.reference.object.name)
    end,
    description = "Harvest the selected plant.",
    command = function(e)
        e.activeCompanion:moveToAction(e.targetData.reference, "harvest")
    end,
    requirements = function(e)
        return (
            e.activeCompanion:canHarvest(e.targetData.reference) and
            tes3.hasOwnershipAccess{ target = e.targetData.reference } and 
            e.activeCompanion:hasSkillReqs("fetch")
        )
    end
},
{
    --FETCH
    label = function(e)
        return string.format("Fetch %s", e.targetData.reference.object.name)
    end,
    description = "Bring the selected item back to the player.",
    command = function(e)
        e.activeCompanion:moveToAction(e.targetData.reference, "fetch")
    end,
    requirements = function(e)
        return (
            e.activeCompanion:canFetch(e.targetData.reference) and
            tes3.hasOwnershipAccess{ target = e.targetData.reference } and 
            e.activeCompanion:hasSkillReqs("fetch")
        )
    end
},
{
    --STEAL
    label = function(e)
        return string.format("Steal %s", e.targetData.reference.object.name)
    end,
    description = "Steal the selected item and bring it back to the player. Dont get caught!",
    command = function(e)
        e.activeCompanion:moveToAction(e.targetData.reference, "fetch")
    end,
    requirements = function(e)
        return (
            e.activeCompanion.refData.carriedItem == nil and
            e.activeCompanion:canFetch(e.targetData.reference) and
            not tes3.hasOwnershipAccess{ target = e.targetData.reference }
        )
    end,
    doSteal = true
},

    --priority 3: movement commands

    -- {
    --     --FOLLOW TARGET
    --     label = function(e)
    --         return string.format("Follow %s", animalController.getAnimal(e.targetData.reference).refData.name)
    --     end,
    --     description = "Start following the target guar.",
    --     command = function(e)
    --         tes3.messageBox("Following")
    --         e.activeCompanion:returnTo(e.targetData.reference)
    --     end,
    --     requirements = function(e)
    --         if e.targetData and e.targetData.reference then
    --             mwse.log(e.targetData.reference.object.id)
    --             local animal = animalController.getAnimal(e.targetData.reference)
    --             mwse.log(animal and animal.refData.name)
    --         end
            
    --         return (
    --             e.activeCompanion:hasSkillReqs("follow") and 
    --             e.targetData and
    --             e.targetData.reference and
    --             e.targetData.reference ~= e.activeCompanion.reference and
    --             animalController.getAnimal(e.targetData.reference)
    --         )
    --     end
    -- },
 

    --priority 4: close-up commands
    {
        --PET
        label = function(e)
            return "Pet"
        end,
        description = "Pet your guar to increase its happiness.",
        command = function(e)
            e.activeCompanion:pet()
        end,
        requirements = function(e)
            return e.inMenu
        end,
        delay = 1.5
    },
    {
        --FEED
        label = function(e)
            return "Feed"
        end,
        description = "Feed your guar something from your inventory.",
        command = function(e)
            e.activeCompanion:feed()
        end,
        requirements = function(e)
            return e.inMenu
        end,
        delay = 1.5
    },

   

    {
        --FOLLOW PLAYER
        label = function(e)
            return "Follow me"
        end,
        description = "Start following the player.",
        command = function(e)
            tes3.messageBox("Following")
            e.activeCompanion:returnTo()
        end,
        requirements = function(e)
            common.log:debug("Ai state: %s", e.activeCompanion:getAI() )
            return (
                ( e.targetData.intersection == nil or
                e.targetData.reference ) and 
                e.activeCompanion:getAI() ~= "following" and
                e.activeCompanion:hasSkillReqs("follow")-- and
                -- ( not (
                --     e.targetData and 
                --     e.targetData.reference and
                --     animalController.getAnimal(e.targetData.reference)
                -- ) or e.targetData.reference == e.activeCompanion.reference )
            )
        end
    },

    

    {
        --MOVE
        label = function(e)
            return "Move"
        end,
        description = "Move to the selected location.",
        command = function(e)
            tes3.messageBox("%s moving to location", e.activeCompanion.refData.name)
            e.activeCompanion:moveTo(e.targetData.intersection)
        end,
        requirements = function(e)
            return (
                e.targetData.intersection ~= nil and 
                not e.targetData.reference and
                e.activeCompanion:hasSkillReqs("follow")
            )
        end
    },
    

    {
        --WAIT
        label = function(e)
            return "Wait"
        end,
        description = "Wait here.",
        command = function(e)
            tes3.messageBox("Waiting")
            e.activeCompanion:wait()
        end,
        requirements = function(e)
            return (
                ( e.targetData.intersection == nil or
                e.targetData.reference ) and 
                e.activeCompanion:getAI() ~= "waiting"
            )
        end
    }, 

    {
        --WANDER
        label = function(e)
            return "Wander"
        end,
        description = "Wander around the area.",
        command = function(e)
            tes3.messageBox("Wandering")
            e.activeCompanion:wander()
        end,
        requirements = function(e)
            return (
                ( e.targetData.intersection == nil or
                e.targetData.reference ) and 
                e.activeCompanion:getAI() ~= "wandering"
            )
        end
    }, 


    {
        --Position on top of player to break collision
        label = function(e)
            return "Let me pass"
        end,
        description = "Positions the guar on top of the player, breaking collision and allowing you to move past it.",
        command = function(e)
            local ref = e.activeCompanion.reference
            timer.delayOneFrame(function()
                tes3.positionCell{
                    reference = ref,
                    position = tes3.player.position,
                    cell = tes3.player.cell
                }
            end)

        end,
        requirements = function(e)
            return e.inMenu 
        end,
        delay = 0.1,
    },

    --priority 5: uncommon movement commands


    --Pack commands

    -- {
    --     --SHARE
    --     label = function(e)
    --         return "Companion share"
    --     end,
    --     description = "Open your guar's inventory.",
    --     command = function(e)
    --         e.activeCompanion.refData.triggerDialog = true
    --         tes3.player:activate(e.activeCompanion.reference)
    --     end,
    --     requirements = function(e)
    --         return ( 
    --             e.inMenu and
    --             e.activeCompanion.reference.context and 
    --             e.activeCompanion.reference.context.companion == 1 and
    --             e.activeCompanion.refData.hasPack == true
    --         )
    --     end
    -- },
    --{
    --LANTERN ON
    --     label = function(e)
    --         return "Lantern on"
    --     end,
    --     description = "Turn on the equipped lantern.",
    --     command = function(e)
    --         e.activeCompanion:turnLanternOn()
    --         tes3.playSound{ reference = tes3.player, sound = "mer_tgw_alight", pitch = 1.0}
    --     end,
    --     requirements = function(e)
    --         local animal = e.activeCompanion
    --         return ( e.inMenu and animal.refData.hasPack == true and
    --             animal:getHeldItem(common.packItems.lantern) and
    --             animal.refData.lanternOn ~= true )
    --     end,
    --     delay = 0.1,
    -- },
    -- { 
    --     --LANTERN OFF
    --     label = function(e)
    --         return "Lantern off"
    --     end,
    --     description = "Turn off the equipped lantern.",
    --     command = function(e)
    --         e.activeCompanion:turnLanternOff()
    --         tes3.playSound{ reference = tes3.player, sound = "mer_tgw_alight", pitch = 1.0}
    --     end,
    --     requirements = function(e)
    --         local animal = e.activeCompanion
    --         return ( e.inMenu and animal.refData.hasPack == true and
    --             animal:getHeldItem(common.packItems.lantern) and
    --             animal.refData.lanternOn == true )
    --     end,
    --     delay = 0.1,
    -- },
    {
        --EQUIP PACK
        label = function(e)
            return "Equip pack"
        end,
        description = "Equip a backpack to enable companion share.",
        command = function(e)
            e.activeCompanion:equipPack()
        end,
        requirements = function(e)
            return e.inMenu and e.activeCompanion:canEquipPack()
        end,
        delay = 0.1,
    },
    {
        --UNEQUIP PACK
        label = function(e)
            return "Unequip pack"
        end,
        description = "Unequip the guar's backpack.",
        command = function(e)
            e.activeCompanion:unequipPack()
        end,
        requirements = function(e)
            return ( e.inMenu and e.activeCompanion.refData.hasPack == true )
        end,
        delay = 0.1,
    },
 
    -- {
    --     --- Pack command page
    --     label = function(e)
    --         return "Pack"
    --     end,
    --     description = "See pack commands.",
    --     command = function(e)
    --         e:changePage("pack", e.activeCompanion)
    --     end,
    --     requirements = function(e)
    --         return e.inMenu and e.activeCompanion.refData.hasPack
    --     end,
    --     keepAlive = true,
    -- },



    {
        --Pacify
        label = function(e)
            return "Pacify"
        end,
        description = "Stop your guar from engaging in combat.",
        command = function(e)
            e.activeCompanion:setAttackPolicy("passive")
            tes3.messageBox("%s will no longer engage in combat.", e.activeCompanion.refData.name)
        end,
        requirements = function(e)
            return ( e.inMenu and e.activeCompanion:getAttackPolicy(e) ~= "passive" )
        end
    },
    {
        --Defend
        label = function(e)
            return "Defend"
        end,
        description = "Your guar will defend you in combat.",
        command = function(e)
            e.activeCompanion:setAttackPolicy("defend")
            tes3.messageBox("%s will now defend you in battle.", e.activeCompanion.refData.name)
        end,
        requirements = function(e)
            return ( e.inMenu and e.activeCompanion:getAttackPolicy(e) ~= "defend" )
        end
    },
    -- {
    --     --COMBAT AI
    --     label = function(e)
    --         return "Combat AI"
    --     end,
    --     description = "See commands for setting combat behaviour.",
    --     command = function(e)
    --         e:changePage("combat", e.activeCompanion)
    --     end,
    --     requirements = function(e)
    --         return e.inMenu
    --     end,
    --     keepAlive = true,
    -- },

  
    --priority 2: move to location command

 




    --priority 6: uncommon up-close commands
    {
        --BREED
        label = function(e)
            return "Breed"
        end,
        description = "Breed with another guar to make a baby guar.",
        command = function(e)
            e.activeCompanion:breed()
        end,
        requirements = function(e)
            return (e.inMenu and
                e.activeCompanion:getCanConceive() )
        end,
        delay = 1.0,
    },
    {
        --RENAME
        label = function(e)
            return "Rename"
        end,
        description = "Rename your guar",
        command = function(e)
            e.activeCompanion:rename()
        end,
        requirements = function(e)
            return e.inMenu
        end,
        delay = 0.1,
    },
    {
        --GET STATUS
        label = function(e)
            return "Get status"
        end,
        description = "Check the health, happiness, trust and hunger of your guar.",
        command = function(e)
            e.activeCompanion:getStatusMenu()
        end,
        requirements = function(e)
            return e.inMenu
        end,
        delay = 0.1,
    },

    {
        --GO HOME
        label = function(e)
            return string.format("Go home (%s)", 
                tes3.getCell{ id = e.activeCompanion.refData.home.cell} )
        end,
        description = "Send your guar back to their home location.",
        command = function(e)
            e.activeCompanion:goHome()
        end,
        requirements = function(e)
            return ( 
                e.inMenu and
                e.activeCompanion:hasHome() and
                e.activeCompanion:hasSkillReqs("follow")
            )
        end,
        delay = 0.1,
    },

    {
        --TAKE ME HOME
        label = function(e)
            return string.format("Take me home (%s: %s)", 
                tes3.getCell{ id = e.activeCompanion.refData.home.cell},
                e.activeCompanion:getTravelTimeText()
            )
        end,
        description = "Ride your guar back to its home location.",
        command = function(e)
            e.activeCompanion:goHome{ takeMe = true }
        end,
        requirements = function(e)
            return ( 
                e.inMenu and
                e.activeCompanion:hasHome() and
                e.activeCompanion:hasSkillReqs("follow")
            )
        end,
        delay = 0.1,
    },

    {
        --SET HOME
        label = function(e)
            return string.format("Set home (%s)", e.activeCompanion.reference.cell )
        end,
        description = "Set the guar's current location as their home point.",
        command = function(e)
            e.activeCompanion:setHome(
                e.activeCompanion.reference.position,
                e.activeCompanion.reference.cell
            )
        end,
        requirements = function(e)
            return ( e.inMenu and e.activeCompanion:hasSkillReqs("follow") )
        end,
        delay = 0.1,
    },
    {
        --CANCEL
        label = function(e)
            return "Cancel"
        end,
        description = "Exit menu",
        command = function(e) 
            return true
        end,
        requirements = function(e) return true end
    },
}
return this