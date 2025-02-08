--- @type {[number] : any}
local categories = {
    [tes3.objectType.armor] = {
        text = "Armor",
        layer = tes3.activeBodyPartLayer.armor,
        types = tes3.armorSlot,
        blockedSlots = { ["shield"] = true }
    },
    [tes3.objectType.clothing] = {
        text = "Clothing",
        layer = tes3.activeBodyPartLayer.clothing,
        types = tes3.clothingSlot,
        blockedSlots = { ["amulet"] = true, ["belt"] = true, ["ring"] = true }
    }
}


local this = {}
this.categories = categories
return this
