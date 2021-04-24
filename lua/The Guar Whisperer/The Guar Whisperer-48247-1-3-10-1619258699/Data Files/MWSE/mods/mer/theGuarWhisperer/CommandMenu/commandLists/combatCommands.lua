
--local animalController = require("mer.theGuarWhisperer.animalController")
--local common = require("mer.theGuarWhisperer.common")
local this = {}
this.getTitle = function(e)
    return string.format(
        "AI Policies"
    )
end
this.commands = {

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

    --POTION POLICIES
    {
        --Use all
        label = function(e)
            return "Use All Potions"
        end,
        description = "Your guar will drink whatever potions it wants in combat.",
        command = function(e)
            e.activeCompanion:setPotionPolicy("all")
            tes3.messageBox("%s will now drink any potions in %s inventory.", 
            e.activeCompanion.refData.name, e.activeCompanion:getHisHer() )
        end,
        requirements = function(e)
            return ( e.inMenu and e.activeCompanion:getPotionPolicy(e) ~= "all" )
        end
    },

    {
        --Use none
        label = function(e)
            return "Don't use Potions"
        end,
        description = "Your guar will never drink potions.",
        command = function(e)
            e.activeCompanion:setPotionPolicy("none")
            tes3.messageBox("%s will no longer drink potions in %s inventory.", 
            e.activeCompanion.refData.name, e.activeCompanion:getHisHer() )
        end,
        requirements = function(e)
            return ( e.inMenu and e.activeCompanion:getPotionPolicy(e) ~= "none" )
        end
    },

    {
        --Heath only
        label = function(e)
            return "Use Health Potions"
        end,
        description = "Your guar will drink health potions in its inventory when its health is low.",
        command = function(e)
            e.activeCompanion:setPotionPolicy("healthOnly")
            tes3.messageBox("%s will now drink health potions when necessary.", 
            e.activeCompanion.refData.name)
        end,
        requirements = function(e)
            return ( e.inMenu and e.activeCompanion:getPotionPolicy(e) ~= "healthOnly" )
        end
    },


    {
        --Back
        label = function(e)
            return "Back"
        end,
        description = "Return to main command list",
        command = function(e) 
            e:changePage("main", e.activeCompanion)
        end,
        requirements = function(e) return true end,
        keepAlive = true,
    },
}
return this