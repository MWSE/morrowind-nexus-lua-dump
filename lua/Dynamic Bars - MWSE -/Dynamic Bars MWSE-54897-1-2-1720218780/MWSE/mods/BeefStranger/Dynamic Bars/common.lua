local common = {}

common.barUpdate = "bsDynamicBar"
common.hcDefault = "bshcDefaults"
common.vDefault = "bsVanillaDefault"
common.defaults = "bsDynamicBarRestore"
common.manualMove = "bshcManual"

function common.restoreDefaults()
    if tes3.mobilePlayer then
        event.trigger(common.defaults)
    end
end

common.info = {
    showHealth = {
        label = "Show Values on Health Bars",
        desc = "Show Current/Max Health on the Bar"
    },
    showMagicka = {
        label = "Show Values on Magicka Bars",
        desc = "Show Current/Max Magicka on the Bar"
    },
    showFatigue = {
        label = "Show Values on Fatigue Bars",
        desc = "Show Current/Max Fatigue on the Bar"
    },
    barPadding = {
        label = "Extra Padding to Bar Length",
        desc = "Extra Length added to Bars\nDefault: "
    },
    textPos = {
        label = "Position of Text",
        desc = "Position of the Values on Health/Magicka/Fatigue Bars\nDefault: "
    },
    widthCap = {
        label = "Max Width of Bars",
        desc = "Health/Magicka/Fatigue Stat Value at which The Bars Stop Growing\nDefault: "
    },
    hcAutoMove = {
        label = "hudCustomizer: Auto Move Equipped Icons",
        desc = "Have the Equipped Icons Behave in the Vanilla Way. Moving to the Edge of the Bars. Or disable it so it can be Manually Placed with hudCustomizer"
    }
}

return common