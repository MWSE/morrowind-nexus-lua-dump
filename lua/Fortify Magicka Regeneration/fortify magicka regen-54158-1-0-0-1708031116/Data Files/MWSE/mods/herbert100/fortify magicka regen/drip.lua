-- here we do the drip support
local interop = include("mer.drip")
-- dont add drip support if drip isn't installed
if not interop then return end

interop.registerModifier{
    id = "fortifyMagickaRegen",
    prefix = "Regenerative",
    value = 50,
    valueMulti = 1.25,
    castType = tes3.enchantmentType.constant,
    effects = {
        {
            id = tes3.effect.fortifyMagickaRegen,
            rangeType = tes3.effectRange.self,
            min = 10,
            max = 20,
        },
    },
    validObjectTypes = {
        [tes3.objectType.armor] = true,
        [tes3.objectType.clothing] = true,
    }, 
}

interop.registerModifier{
    id = "fortifyMagickaRegen",
    prefix = "Very Regenerative",
    value = 70,
    valueMulti = 1.55,
    castType = tes3.enchantmentType.constant,
    effects = {
        {
            id = tes3.effect.fortifyMagickaRegen,
            rangeType = tes3.effectRange.self,
            min = 35,
            max = 45,
        },
    },
    validObjectTypes = {
        [tes3.objectType.clothing] = true,
    },
    validClothingSlots={
        [tes3.clothingSlot.amulet] = true,
        [tes3.clothingSlot.leftGlove] = true,
        [tes3.clothingSlot.rightGlove] = true,
        [tes3.clothingSlot.ring] = true,
        [tes3.clothingSlot] = true,
    }
}
interop.registerModifier{
    id = "fortifyMagickaRegen",
    prefix = "Highly Regenerative",
    value = 100,
    valueMulti = 1.8,
    castType = tes3.enchantmentType.constant,
    effects = {
        {
            id = tes3.effect.fortifyMagickaRegen,
            rangeType = tes3.effectRange.self,
            min = 50,
            max = 75,
        },
    },
    validObjectTypes = { [tes3.objectType.clothing] = true, },
    validClothingSlots={ [tes3.clothingSlot.robe] = true, }
}

