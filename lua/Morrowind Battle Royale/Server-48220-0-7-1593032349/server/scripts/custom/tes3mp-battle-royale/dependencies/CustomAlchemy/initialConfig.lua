local keyOrder = {
    "importESPs", "cmdRank", "progressSkill", "disableQuickKeys", "potionEffectTreshold", "maximumIngredientCount",
    "menu", "fail", "success", "burden", "container",
}
local default = {
    importESPs = false,
    cmdRank = 2,
    progressSkill = false,
    disableQuickKeys = false,
    ["menu"] = {
        ["apparatusButtons"] = { "Brew", "Add ingredient", "Cancel" },
        ["nameLabel"] = "Name your potions:"
    },
    ["fail"] = {
        ["sound"] = "fx/item/potionFAIL.wav",
        ["messageAttempt"] = "You failed to brew anything!",
        ["messageTooMany"] = "Too many ingredients!",
        ["messageUseless"] = "This potion is useless!",
        ["messageMortarRequired"] = "You can't brew potions without a mortar!",
    },
    ["success"] = {
        ["sound"] = "fx/item/potion.wav",
        ["message1"] = "You have sucessfully brewed a potion!",
        ["message"] = "You have sucessfully brewed %s potions!"
    },
    ["burden"] = {
        ["name"] = "Weight of ingredients"
    },
    ["container"] = {
        ["baseId"] = "dead rat",
        ["refId"] = "alchemy_apparatus",
        ["name"] = "Alchemy Apparatuses",
        ["type"] = "creature",
        ["packetType"] = "spawn",
        ["location"] = {
            ["posX"] = 0,
            ["posY"] = 0,
            ["posZ"] = 0,
            ["rotX"] = 0,
            ["rotY"] = 0,
            ["rotZ"] = 0
        }
    },
    ["potionEffectTreshold"] = 2,
    ["maximumIngredientCount"] = 4,
}

return { default = default, keyOrder = keyOrder}