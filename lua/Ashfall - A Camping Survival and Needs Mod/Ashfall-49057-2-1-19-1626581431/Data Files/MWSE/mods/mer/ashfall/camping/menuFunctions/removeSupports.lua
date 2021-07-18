local common = require ("mer.ashfall.common.common")
return {
    text = "Remove Supports",
    showRequirements = function(campfire)
        return campfire.data.dynamicConfig
            and campfire.data.dynamicConfig.supports == "dynamic"
            and campfire.data.hasSupports
    end,
    enableRequirements = function(campfire)
        return campfire.data.utensil == nil
    end,
    tooltipDisabled = { 
        text = "Utensil must be removed first."
    },
    callback = function(campfire)
        mwscript.addItem{
            reference = tes3.player, 
            item = common.staticConfigs.objectIds.firewood,
            count = 3
        }
        campfire.data.hasSupports = false
        tes3.playSound{ reference = tes3.player, sound = "Item Misc Up"  }
        tes3.messageBox(tes3.findGMST(tes3.gmst.sNotifyMessage61).value, 3, tes3.getObject(common.staticConfigs.objectIds.firewood).name)
        --event.trigger("Ashfall:Campfire_Update_Visuals", { campfire = campfire, all = true})
    end
}