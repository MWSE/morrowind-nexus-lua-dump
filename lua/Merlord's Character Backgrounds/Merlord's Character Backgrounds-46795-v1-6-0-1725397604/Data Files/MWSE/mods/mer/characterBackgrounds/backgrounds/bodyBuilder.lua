local interop = require("mer.characterBackgrounds.interop")
local common = require("mer.characterBackgrounds.common")
local logger = common.createLogger("BodyBuilder")

local checkChest
local background = interop.addBackground{
    id = "bodyBuilder",
    name = "Bodybuilder",
    description = (
        "You have an incredible body. When you show it off, people can't help but swoon. " ..
        "When you are not wearing a shirt, robe or chestpiece, you gain +10 to Personality. " ..
        "Unfortunately, your body is the most interesting thing about you, and when not " ..
        "mesmerized by your good looks, people quickly realize how boring you are. " ..
        "When wearing a shirt, robe or chest piece, you suffer a -10 penalty to Personality. "
    ),
    defaultData = {
        buffed = false,
        debuffed = false,
    },
    onLoad = checkChest
}
if not background then return end


local function isWearingShirt()
    local chestpieces = {
        { objectType = tes3.objectType.clothing, slot = tes3.clothingSlot.shirt },
        { objectType = tes3.objectType.clothing, slot = tes3.clothingSlot.robe },
        { objectType = tes3.objectType.armor, slot = tes3.armorSlot.cuirass },
    }
    for _, chestpiece in ipairs(chestpieces) do
        if tes3.getEquippedItem{
            actor = tes3.player,
            objectType = chestpiece.objectType,
            slot = chestpiece.slot
        } then
            return true
        end
    end
    return false
end


checkChest = function()
    --Shirtless
    if not isWearingShirt() then
        logger:debug("Shirtless")
        --add buff
        if not background.data.buffed then
            logger:debug("- Adding buff")
            background.data.buffed = true
            tes3.modStatistic({
                reference = tes3.player,
                attribute = tes3.attribute.personality,
                value = 10
            })
        end
        --remove debuff
        if background.data.debuffed then
            logger:debug("- Removing debuff")
            background.data.debuffed = false
            tes3.modStatistic({
                reference = tes3.player,
                attribute = tes3.attribute.personality,
                value = 10
            })
        end
    --wearing shirt
    else
        logger:debug("Wearing shirt")
        --add debuff
        if not background.data.debuffed then
            logger:debug("- Adding debuff")
            background.data.debuffed = true
            tes3.modStatistic({
                reference = tes3.player,
                attribute = tes3.attribute.personality,
                value = -10
            })
        end
        --remove buff
        if background.data.buffed then
            logger:debug("- Removing buff")
            background.data.buffed = false
            tes3.modStatistic({
                reference = tes3.player,
                attribute = tes3.attribute.personality,
                value = -10
            })
        end
    end
end

---@param item tes3clothing|tes3armor
local function onEquipUnequip(item)
    if not background:isActive() then return end
    local isShirt = item.objectType == tes3.objectType.clothing
        and item.slot == tes3.clothingSlot.shirt
    local isCuirass = item.objectType == tes3.objectType.armor
        and item.slot == tes3.armorSlot.cuirass
    if isShirt or isCuirass then
        timer.frame.delayOneFrame(checkChest)
    end
end

event.register("equip", function(e)
    onEquipUnequip(e.item)
end)


event.register("unequipped", function(e)
    onEquipUnequip(e.item)
end)

