local this = {}
local common = require("mer.theGuarWhisperer.common")
this.getTitle = function(e)
    return "Pack Commands"
end
this.commands = {
    {
        --SHARE
        label = function(e)
            return "Companion Share"
        end,
        description = "Open your guar's inventory.",
        command = function(e)
            e.activeCompanion.refData.triggerDialog = true
            tes3.player:activate(e.activeCompanion.reference)
        end,
        requirements = function(e)
            return ( 
                e.inMenu and
                e.activeCompanion.reference.context and 
                e.activeCompanion.reference.context.companion == 1 and
                e.activeCompanion.refData.hasPack == true
            )
        end
    },
    {
        --LANTERN ON
           label = function(e)
               return "Lantern On"
           end,
           description = "Turn on the equipped lantern.",
           command = function(e)
               e.activeCompanion:turnLanternOn()
           end,
           requirements = function(e)
               local animal = e.activeCompanion
               return ( e.inMenu and animal.refData.hasPack == true and
                   animal:getHeldItem(common.packItems.lantern) and
                   animal.refData.lanternOn ~= true )
           end
       },
       { 
           --LANTERN OFF
           label = function(e)
               return "Lantern Off"
           end,
           description = "Turn off the equipped lantern.",
           command = function(e)
               e.activeCompanion:turnLanternOff()
           end,
           requirements = function(e)
               local animal = e.activeCompanion
               return ( e.inMenu and animal.refData.hasPack == true and
                   animal:getHeldItem(common.packItems.lantern) and
                   animal.refData.lanternOn == true )
           end
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