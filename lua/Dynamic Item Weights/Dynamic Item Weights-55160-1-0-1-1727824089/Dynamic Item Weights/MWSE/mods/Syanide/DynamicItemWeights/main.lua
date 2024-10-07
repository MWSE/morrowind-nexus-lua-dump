local config = require("Syanide.DynamicItemWeights.config")

local soulgem = {
    "AB_Misc_SoulGemBlack",
    "Misc_SoulGem_Azura",
    "Misc_SoulGem_Common",
    "Misc_SoulGem_Grand",
    "Misc_SoulGem_Lesser",
    "Misc_SoulGem_Petty",
    "Misc_SoulGem_Greater",
}

local function weightChange(e)
    if config.enableWeapons then
        -- Change weights for weapons
        for weapon in tes3.iterateObjects(tes3.objectType.weapon) do
            if weapon then
                weapon.weight = weapon.weight / config.weaponDivision
            end
        end
    end

    if config.enableDarts then
        -- Change weights for darts
        for weapon in tes3.iterateObjects(tes3.objectType.weapon) do
            if weapon and string.find(weapon.id:lower(), "dart") then
                weapon.weight = 0.1
            end
        end
    end

    if config.enableThrowing then
        -- Change weights for throwing stars and darts
        for weapon in tes3.iterateObjects(tes3.objectType.weapon) do
            if weapon and (string.find(weapon.id:lower(), "throwing") or string.find(weapon.id:lower(), "star")) then
                weapon.weight = 0.1
            end
        end
    end

    if config.enableAmmunition then
        -- Change weights for ammunition
        for ammunition in tes3.iterateObjects(tes3.objectType.ammunition) do
            if ammunition then
                ammunition.weight = 0
            end
        end
    end

    if config.enableAlchemy then
        -- Change weights for alchemy items
        for alchemy in tes3.iterateObjects(tes3.objectType.alchemy) do
            if alchemy then
                alchemy.weight = 1
            end
        end
    end

    if config.enableApparatus then
        -- Change weights for apparatus
        for apparatus in tes3.iterateObjects(tes3.objectType.apparatus) do
            if apparatus then
                apparatus.weight = apparatus.weight / config.AppWeight
            end
        end
    end

    if config.enableClothing then
        -- Change weights for clothing
        for clothing in tes3.iterateObjects(tes3.objectType.clothing) do
            if clothing then
                if clothing.slot == tes3.clothingSlot.amulet then -- Set weight for amulets
                    clothing.weight = 0.1
                elseif clothing.slot == tes3.clothingSlot.shirt then -- Set weight for shirts
                    clothing.weight = 0.5
                elseif clothing.slot == tes3.clothingSlot.pants then -- Set weight for pants
                    clothing.weight = 0.5
                elseif clothing.slot == tes3.clothingSlot.ring then -- Set weight for rings
                    clothing.weight = 0
                elseif clothing.slot == tes3.clothingSlot.robe then -- Set weight for robes
                    clothing.weight = 1
                elseif clothing.slot == tes3.clothingSlot.shoes then -- Set weight for shoes
                    clothing.weight = 1
                elseif clothing.slot == tes3.clothingSlot.belt then -- Set weight for belt
                    clothing.weight = 0.1
                elseif clothing.slot == tes3.clothingSlot.skirt then -- Set weight for skirt
                    clothing.weight = 0.5
                elseif clothing.slot == tes3.clothingSlot.leftGlove or clothing.slot == tes3.clothingSlot.rightGlove then -- Set weight for gloves
                    clothing.weight = 0.1
                end
            end
        end
    end

    if config.enableIngredients then
        -- Change weights for lockpicks
        for ingredient in tes3.iterateObjects(tes3.objectType.ingredient) do
            if ingredient then
                ingredient.weight = 0.1
            end
        end
    end

    if config.enableLockpicks then
        -- Change weights for lockpicks
        for lockpick in tes3.iterateObjects(tes3.objectType.lockpick) do
            if lockpick then
                lockpick.weight = 0
            end
        end
    end

    if config.enableProbes then
        -- Change weights for probes
        for probe in tes3.iterateObjects(tes3.objectType.probe) do
            if probe then
                probe.weight = 0
            end
        end
    end

    if config.enableRepairItems then
        -- Change weights for repair items
        for repairItem in tes3.iterateObjects(tes3.objectType.repairItem) do
            if repairItem then
                repairItem.weight = 1
            end
        end
    end
    
    if config.enableBooks then
        -- Change weights for books
        for book in tes3.iterateObjects(tes3.objectType.book) do
            if book then -- Set weight for books
                if book.type == tes3.bookType.scroll then -- Set weight for scrolls
                    book.weight = 0.1
                else
                    book.weight = 0.5
                end
            end
        end
    end

    if config.enableKeys then
        -- Change weights for keys
        for miscItem in tes3.iterateObjects(tes3.objectType.miscItem) do
            if miscItem and string.find(miscItem.id:lower(), "key") then
                miscItem.weight = 0
            end
        end
    end

    if config.enableSoulGems then
        -- Change weights for soul gems
        for miscItem in tes3.iterateObjects(tes3.objectType.miscItem) do
            if miscItem then
                for _, gemId in ipairs(soulgem) do
                    if miscItem.id == gemId then
                        miscItem.weight = 0
                        break
                    end
                end
            end
        end
    end
end

mwse.log("[Dynamic Item Weights] Initialized!")

-- Register the event to apply weight changes when the game loads
event.register("initialized", weightChange)