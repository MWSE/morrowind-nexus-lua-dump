
local animalController = require("mer.theGuarWhisperer.animalController")
local common = require("mer.theGuarWhisperer.common")
return {
    --Priority 1: specific ref commands
    { 
        --ATTACK
        label = function()
            return string.format("Attack %s", common.targetData.reference.object.name)
        end,
        description = "Attacks the selected target.",
        command = function()
            common.activeCompanion:attack(common.targetData.reference)
        end,
        requirements = function()
            if not common.targetData.reference then
                return false
            end
            if not common.targetData.reference.mobile then
                return false
            end
            if common.targetData.reference.mobile.health.current < 1 then
                return false
            end
            for actor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
                if actor.reference == common.targetData.reference then
                    return false
                end
            end
            if animalController.getAnimal(common.targetData.reference) then
                return false
            end
            if not common.activeCompanion:hasSkillReqs("attack") then
                return false
            end
            if common.activeCompanion.refData.attackPolicy == "passive" then
                return false
            end

            return true
        end
    },
    {
        --CHARM
        label = function()
            return string.format("Charm %s", common.targetData.reference.object.name)
        end,
        description = "Attempt to charm the target, increasing their disposition.",
        command = function()
            common.activeCompanion:moveToAction(common.targetData.reference, "charm")
        end,
        requirements = function()
            if not ( common.targetData and common.targetData.reference ) then return false end
            local targetObj = common.targetData.reference.baseObject or 
                common.targetData.reference.object
    
            return (
                targetObj and
                targetObj.objectType == tes3.objectType.npc and
                common.activeCompanion:hasSkillReqs("charm")
            )
        end
    },

    {
        --EAT
        label = function()
            return string.format("Eat %s", common.targetData.reference.object.name)
        end,
        description = "Eat the selected item or plant.",
        command = function()
            common.activeCompanion:moveToAction(common.targetData.reference, "eat")
        end,
        requirements = function()
            return (
                common.activeCompanion and
                common.activeCompanion.refData.carriedItems == nil and
                common.targetData.reference and
                common.activeCompanion:canEat(common.targetData.reference) and
                common.activeCompanion:hasSkillReqs("eat")
            )
        end
    },
    {
        --HARVEST
        label = function()
            return string.format("Harvest %s", common.targetData.reference.object.name)
        end,
        description = "Harvest the selected plant.",
        command = function()
            common.activeCompanion:moveToAction(common.targetData.reference, "harvest")
        end,
        requirements = function()
            return (
                common.activeCompanion:canHarvest(common.targetData.reference) and
                tes3.hasOwnershipAccess{ target = common.targetData.reference } and 
                common.activeCompanion:hasSkillReqs("fetch")
            )
        end
    },
    {
        --FETCH
        label = function()
            return string.format("Fetch %s", common.targetData.reference.object.name)
        end,
        description = "Bring the selected item back to the player.",
        command = function()
            common.activeCompanion:moveToAction(common.targetData.reference, "fetch")
        end,
        requirements = function()
            return (
                common.activeCompanion:canFetch(common.targetData.reference) and
                tes3.hasOwnershipAccess{ target = common.targetData.reference } and 
                common.activeCompanion:hasSkillReqs("fetch")
            )
        end
    },
    {
        --STEAL
        label = function()
            return string.format("Steal %s", common.targetData.reference.object.name)
        end,
        description = "Steal the selected item and bring it back to the player. Dont get caught!",
        command = function()
            common.activeCompanion:moveToAction(common.targetData.reference, "fetch")
        end,
        requirements = function()
            return (
                common.activeCompanion.refData.carriedItem == nil and
                common.activeCompanion:canFetch(common.targetData.reference) and
                not tes3.hasOwnershipAccess{ target = common.targetData.reference }
            )
        end,
        doSteal = true
    },
    --priority 2: move to location command
    {
        --MOVE
        label = function()
            return "Move"
        end,
        description = "Move to the selected location.",
        command = function()
            tes3.messageBox("%s moving to location", common.activeCompanion.refData.name)
            common.activeCompanion:moveTo(common.targetData.intersection)
        end,
        requirements = function()
            return (
                common.targetData.intersection ~= nil and 
                not common.targetData.reference and
                common.activeCompanion:hasSkillReqs("follow")
            )
        end
    },
    --priority 3: movement commands

    -- {
    --     --FOLLOW TARGET
    --     label = function()
    --         return string.format("Follow %s", animalController.getAnimal(common.targetData.reference).refData.name)
    --     end,
    --     description = "Start following the target guar.",
    --     command = function()
    --         tes3.messageBox("Following")
    --         common.activeCompanion:returnTo(common.targetData.reference)
    --     end,
    --     requirements = function()
    --         if common.targetData and common.targetData.reference then
    --             mwse.log(common.targetData.reference.object.id)
    --             local animal = animalController.getAnimal(common.targetData.reference)
    --             mwse.log(animal and animal.refData.name)
    --         end
            
    --         return (
    --             common.activeCompanion:hasSkillReqs("follow") and 
    --             common.targetData and
    --             common.targetData.reference and
    --             common.targetData.reference ~= common.activeCompanion.reference and
    --             animalController.getAnimal(common.targetData.reference)
    --         )
    --     end
    -- },

    {
        --FOLLOW PLAYER
        label = function()
            return "Follow Me"
        end,
        description = "Start following the player.",
        command = function()
            tes3.messageBox("Following")
            common.activeCompanion:returnTo()
        end,
        requirements = function()
            common.log:debug("Ai state: %s", common.activeCompanion:getAI() )
            return (
                common.activeCompanion:getAI() ~= "following" and
                common.activeCompanion:hasSkillReqs("follow")-- and
                -- ( not (
                --     common.targetData and 
                --     common.targetData.reference and
                --     animalController.getAnimal(common.targetData.reference)
                -- ) or common.targetData.reference == common.activeCompanion.reference )
            )
        end
    },



    {
        --WAIT
        label = function()
            return "Wait"
        end,
        description = "Wait here.",
        command = function()
            tes3.messageBox("Waiting")
            common.activeCompanion:wait()
        end,
        requirements = function()
            return common.activeCompanion:getAI() ~= "waiting"
        end
    }, 

    --priority 4: close-up commands
    {
        --PET
        label = function()
            return "Pet"
        end,
        description = "Pet your guar to increase its happiness.",
        command = function()
            common.activeCompanion:pet()
        end,
        requirements = function(inMenu)
            return inMenu
        end
    },
    {
        --FEED
        label = function()
            return "Feed"
        end,
        description = "Feed your guar something from your inventory.",
        command = function()
            common.activeCompanion:feed()
        end,
        requirements = function(inMenu)
            return inMenu
        end
    },
    {
        --SHARE
        label = function()
            return "Companion Share"
        end,
        description = "Open your guar's inventory.",
        command = function()
            common.activeCompanion.refData.triggerDialog = true
            tes3.player:activate(common.activeCompanion.reference)
        end,
        requirements = function(inMenu)
            return ( 
                inMenu and
                common.activeCompanion.reference.context and 
                common.activeCompanion.reference.context.companion == 1 and
                common.activeCompanion.refData.hasPack == true
            )
        end
    },
    {
        --EQUIP PACK
        label = function()
            return "Equip pack"
        end,
        description = "Equip a backpack to enable companion share.",
        command = function()
            common.activeCompanion:equipPack()
        end,
        requirements = function(inMenu)
            return inMenu and common.activeCompanion:canEquipPack()
        end
    },
    {
        --UNEQUIP PACK
        label = function()
            return "Unequip pack"
        end,
        description = "Unequip the guar's backpack.",
        command = function()
            common.activeCompanion:unequipPack()
        end,
        requirements = function(inMenu)
            return ( inMenu and common.activeCompanion.refData.hasPack == true )
        end
    },
    {
     --LANTERN ON
        label = function()
            return "Lantern On"
        end,
        description = "Turn on the equipped lantern.",
        command = function()
            common.activeCompanion:turnLanternOn()
        end,
        requirements = function(inMenu)
            local animal = common.activeCompanion
            return ( inMenu and animal.refData.hasPack == true and
                animal:getHeldItem(common.packItems.lantern) and
                animal.refData.lanternOn ~= true )
        end
    },
    {
        --LANTERN OFF
        label = function()
            return "Lantern Off"
        end,
        description = "Turn off the equipped lantern.",
        command = function()
            common.activeCompanion:turnLanternOff()
        end,
        requirements = function(inMenu)
            local animal = common.activeCompanion
            return ( inMenu and animal.refData.hasPack == true and
                animal:getHeldItem(common.packItems.lantern) and
                animal.refData.lanternOn == true )
        end
    },

    --priority 5: uncommon movement commands
    {
        --WANDER
        label = function()
            return "Wander"
        end,
        description = "Wander around the area.",
        command = function()
            tes3.messageBox("Wandering")
            common.activeCompanion:wander()
        end,
        requirements = function()
            return (
                common.activeCompanion:getAI() ~= "wandering"
            )
        end
    }, 
    {
        --Pacify
        label = function()
            return "Pacify"
        end,
        description = "Stop your guar from engaging in combat.",
        command = function()
            common.activeCompanion:setAttackPolicy("passive")
            tes3.messageBox("%s will no longer engage in combat.", common.activeCompanion.refData.name)
        end,
        requirements = function(inMenu)
            return ( inMenu and common.activeCompanion:getAttackPolicy() ~= "passive" )
        end
    },
    {
        --Defend
        label = function()
            return "Defend"
        end,
        description = "Your guar will defend you in combat.",
        command = function()
            common.activeCompanion:setAttackPolicy("defend")
            tes3.messageBox("%s will now defend you in battle.", common.activeCompanion.refData.name)
        end,
        requirements = function(inMenu)
            return ( inMenu and common.activeCompanion:getAttackPolicy() ~= "defend" )
        end
    },
    --priority 6: uncommon up-close commands
    {
        --BREED
        label = function()
            return "Breed"
        end,
        description = "Breed with another guar to make a baby guar.",
        command = function()
            common.activeCompanion:breed()
        end,
        requirements = function(inMenu)
            return (inMenu and
                common.activeCompanion:getCanConceive() )
        end
    },
    {
        --RENAME
        label = function()
            return "Rename"
        end,
        description = "Rename your guar",
        command = function()
            common.activeCompanion:rename()
        end,
        requirements = function(inMenu)
            return inMenu
        end
    },
    {
        --GET STATUS
        label = function()
            return "Get Status"
        end,
        description = "Check the health, happiness, trust and hunger of your guar.",
        command = function()
            common.activeCompanion:getStatusMenu()
        end,
        requirements = function(inMenu)
            return inMenu
        end
    },
    {
        --GO HOME
        label = function()
            return string.format("Go home (%s)", 
                tes3.getCell{ id = common.activeCompanion.refData.home.cell} )
        end,
        description = "Send your guar back to their home location.",
        command = function()
            common.activeCompanion:goHome()
        end,
        requirements = function(inMenu)
            return ( 
                inMenu and
                common.activeCompanion:hasHome() and
                common.activeCompanion:hasSkillReqs("follow")
            )
        end
    },
    {
        --SET HOME
        label = function()
            return string.format("Set Home (%s)", common.activeCompanion.reference.cell )
        end,
        description = "Set the guar's current location as their home point.",
        command = function()
            common.activeCompanion:setHome(
                common.activeCompanion.reference.position,
                common.activeCompanion.reference.cell
            )
        end,
        requirements = function(inMenu)
            return ( inMenu and common.activeCompanion:hasSkillReqs("follow") )
        end
    },
    {
        --CANCEL
        label = function()
            return "Cancel"
        end,
        description = "Exit menu",
        command = function() 
            return true
        end,
        requirements = function() return true end
    },
}