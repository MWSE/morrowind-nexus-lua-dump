local config = require("Equipment and Items Requirements Overhaul.config")
local helpers = require("Equipment and Items Requirements Overhaul.helpers.formulasHelpers")

-- Load the configuration
local function getConfig()
    return mwse.loadConfig("Equipment_and_Items_Requirements_Overhaul_config", config)
end

local getMaxWeaponDamage = helpers.getMaxWeaponDamage
local getXword = helpers.getXword
local rFPN = helpers.rFPN

local formulas = {
    LongBladeOneHand = function(item)
        local Strength, Agility, Skill
        local kinds = { "broadsword", "saber", "longsword", "katana" }
        local enchantedLongSwordKinds = { "sword", "icicle", "spiderbite", "spirit-eater", "stormblade" }
        local itemKind = getXword(item.name:lower(), kinds)
        local itemEnchantedLongSwordKind = getXword(item.name:lower(), enchantedLongSwordKinds)
        --mwse.log("\n\n Kind of formula used %s maxDamage: %u", itemKind, getMaxWeaponDamage(item))
        if itemKind == "broadsword" then
            Strength = rFPN(math.ceil((20 + 2 * item.weight) + getConfig().Attributes.strength))
            Agility = rFPN(math.ceil((20 + 0.5 * item.weight) + getConfig().Attributes.agility))
            Skill = rFPN(5 + getConfig().Skills["Long Blade One Hand"].broadsword)
            return { Strength = Strength, Agility = Agility, ["Long Blade"] = Skill }
        elseif itemKind == "saber" then
            Strength = rFPN(math.ceil((30 + 0.5 * item.weight) + getConfig().Attributes.strength))
            Agility = rFPN(math.ceil((35 * (getMaxWeaponDamage(item) / item.weight)) + getConfig().Attributes.agility))
            Skill = rFPN(15 + getConfig().Skills["Long Blade One Hand"].saber)
            return { Strength = Strength, Agility = Agility, ["Long Blade"] = Skill }
        elseif itemKind == "longsword" or itemEnchantedLongSwordKind then
            Strength = rFPN(math.ceil((30 + item.weight) + getConfig().Attributes.strength))
            Agility = rFPN(math.ceil((40 + 15 * (getMaxWeaponDamage(item) / item.weight)) +
                getConfig().Attributes.agility))
            Skill = rFPN(15 + getConfig().Skills["Long Blade One Hand"].longsword)
            return { Strength = Strength, Agility = Agility, ["Long Blade"] = Skill }
        elseif itemKind == "katana" then
            Strength = rFPN(math.ceil((30 + item.weight) + getConfig().Attributes.strength))
            Agility = rFPN(math.ceil((20 + 2 * item.weight) + getConfig().Attributes.agility))
            Skill = rFPN(math.ceil(50 + 0.5 * item.weight) + getConfig().Skills["Long Blade One Hand"].katana)
            return { Strength = Strength, Agility = Agility, ["Long Blade"] = Skill }
        else
            Strength = rFPN(math.ceil((30 + item.weight) + getConfig().Attributes.strength))
            Agility = rFPN(math.ceil((20 + 2 * item.weight) + getConfig().Attributes.agility))
            Skill = rFPN(math.ceil(40 + 0.5 * item.weight) + getConfig().Skills["Long Blade One Hand"]
                ["other/artifact"])
            return { Strength = Strength, Agility = Agility, ["Long Blade"] = Skill }
        end
    end,

    LongBladeTwoClose = function(item)
        local Strength, Agility, Skill
        local kinds = { "claymore", "dai-katana" }
        local itemKind = getXword(item.name:lower(), kinds)
        local enchantedKind = { "scythe", "slayer" }
        local itemEnchantedKind = getXword(item.name:lower(), enchantedKind)
        if itemKind == "claymore" or itemEnchantedKind == "slayer" then
            Strength = rFPN(math.ceil((15 + 1.5 * item.weight) + getConfig().Attributes.strength))
            Agility = rFPN(math.ceil((30 + 30 * (getMaxWeaponDamage(item) / item.weight)) +
                getConfig().Attributes.agility))
            Skill = rFPN(45 + getConfig().Skills["Long Blade Two Close"].claymore)
            return { Strength = Strength, Agility = Agility, ["Long Blade"] = Skill }
        elseif itemKind == "dai-katana" or itemEnchantedKind == "scythe" then
            Strength = rFPN(math.ceil((15 + 1.5 * item.weight) + getConfig().Attributes.strength))
            Agility = rFPN(math.ceil((60 + item.weight) + getConfig().Attributes.agility))
            Skill = rFPN(50 + getConfig().Skills["Long Blade Two Close"]["dai-katana"])
            return { Strength = Strength, Agility = Agility, ["Long Blade"] = Skill }
        else
            Strength = rFPN(math.ceil((15 + 1.5 * item.weight) + getConfig().Attributes.strength))
            Agility = rFPN(math.ceil((30 + 30 * (getMaxWeaponDamage(item) / item.weight)) +
                getConfig().Attributes.agility))
            Skill = rFPN(65 + getConfig().Skills["Long Blade Two Close"]["other/artifact"])
            return { Strength = Strength, Agility = Agility, ["Long Blade"] = Skill }
        end
    end,

    MarksmanThrown = function(item)
        local Strength, Skill
        local kinds = { "dart", "knife", "star" }
        local itemKind = getXword(item.name:lower(), kinds)
        local enchantedKind = { "flying" }
        local itemEnchantedKind = getXword(item.name:lower(), enchantedKind)

        if itemKind == "dart" then
            Strength = rFPN(math.ceil(150 * item.weight + getConfig().Attributes.strength))
            Skill = rFPN(10 + getConfig().Skills["Marksman Thrown"].dart)
            return { Strength = Strength, Marksman = Skill }
        elseif itemKind == "knife" or itemEnchantedKind then
            Strength = rFPN(math.ceil(150 * item.weight + getConfig().Attributes.strength))
            Skill = rFPN(20 + getConfig().Skills["Marksman Thrown"].knife)
            return { Strength = Strength, Marksman = Skill }
        elseif itemKind == "star" then
            Strength = rFPN(math.ceil(150 * item.weight + getConfig().Attributes.strength))
            Skill = rFPN(35 + getConfig().Skills["Marksman Thrown"].star)
            return { Strength = Strength, Marksman = Skill }
        else
            -- Handling for any other thrown items not specified, if necessary
            Strength = rFPN(math.ceil(150 * item.weight + getConfig().Attributes.strength))
            Skill = rFPN(45 + getConfig().Skills["Marksman Thrown"]["other/artifact"]) -- Default skill value for unspecified items
            return { Strength = Strength, Marksman = Skill }
        end
    end,

    MarksmanBow = function(item)
        local Strength, Skill
        local kinds = { "short bow", "long bow", "longbow", "shortbow" } --bows enchanted use the regular bow/longbow words.
        local itemKind = getXword(item.name:lower(), kinds)

        if itemKind == "short bow" or itemKind == "shortbow" then
            Strength = rFPN(math.ceil((25 + 3 * item.weight) + getConfig().Attributes.strength))
            Skill = rFPN(math.ceil((20 + item.weight) + getConfig().Skills["Marksman Bow"]["short bow"]))
            return { Strength = Strength, Marksman = Skill }
        elseif itemKind == "long bow" or itemKind == "longbow" then
            Strength = rFPN(math.ceil((30 + 4 * item.weight) + getConfig().Attributes.strength))
            Skill = rFPN(math.ceil((42 + 2 * item.weight) + getConfig().Skills["Marksman Bow"]["long bow"]))
            return { Strength = Strength, Marksman = Skill }
        else
            Strength = rFPN(math.ceil((30 + 4 * item.weight) + getConfig().Attributes.strength))
            Skill = rFPN(math.ceil((52 + 2 * item.weight) + getConfig().Skills["Marksman Bow"]["other/artifact"]))
            return { Strength = Strength, Marksman = Skill }
        end
    end,

    MarksmanCrossbow = function(item)
        local Strength, Skill
        local kinds = { "crossbow" }
        local itemKind = getXword(item.name:lower(), kinds)

        -- Ensuring that values are never less than 0 and using configuration settings
        if itemKind == "crossbow" then
            Strength = rFPN(math.ceil((30 + 1.5 * item.weight) + getConfig().Attributes.strength))
            Skill = rFPN(math.ceil((35 + item.weight) + getConfig().Skills["Marksman Crossbow"].crossbow))
            return { Strength = Strength, Marksman = Skill }
        else
            -- Use a different skill key if there's a need to distinguish other types, like "other/artifact" if applicable
            Strength = rFPN(math.ceil((30 + 1.5 * item.weight) + getConfig().Attributes.strength))
            Skill = rFPN(math.ceil((35 + item.weight) + getConfig().Skills["Marksman Crossbow"]["other/artifact"]))
            return { Strength = Strength, Marksman = Skill }
        end
    end,

    BluntOneHand = function(item)
        local Strength, Endurance, Skill
        local kinds = { "club", "mace" }
        local itemKind = getXword(item.name:lower(), kinds)
        local enchantedMaces = { "ordinator", "icebreaker", "crown" }
        local itemEnchantedMaces = getXword(item.name:lower(), enchantedMaces)
        local enchantedClubs = { "teacher" }
        local itemEnchantedClubs = getXword(item.name:lower(), enchantedClubs)

        if itemKind == "club" or itemEnchantedClubs then
            Strength = rFPN(math.ceil((15 + item.weight) + getConfig().Attributes.strength))
            Endurance = rFPN(math.ceil((15 + item.weight) + getConfig().Attributes.endurance))
            Skill = rFPN(5 + getConfig().Skills["Blunt One Hand"].club)
            return { Strength = Strength, Endurance = Endurance, ["Blunt Weapon"] = Skill }
        elseif itemKind == "mace" or itemEnchantedMaces then
            Strength = rFPN(math.ceil((20 + 2 * item.weight) + getConfig().Attributes.strength))
            Endurance = rFPN(math.ceil((35 + 1.5 * item.weight) + getConfig().Attributes.endurance))
            Skill = rFPN(25 + getConfig().Skills["Blunt One Hand"].mace)
            return { Strength = Strength, Endurance = Endurance, ["Blunt Weapon"] = Skill }
        else
            Strength = rFPN(math.ceil((20 + 2 * item.weight) + getConfig().Attributes.strength))
            Endurance = rFPN(math.ceil((35 + 1.5 * item.weight) + getConfig().Attributes.endurance))
            Skill = rFPN(35 + getConfig().Skills["Blunt One Hand"]["other/artifact"])
            return { Strength = Strength, Endurance = Endurance, ["Blunt Weapon"] = Skill }
        end
    end,

    BluntTwoWide = function(item)
        local Strength, Endurance, Agility, Skill
        local kinds = { "staff" }
        local itemKind = getXword(item.name:lower(), kinds)
        local enchantedKinds = { "stick", "peacemaker" }
        local itemEnchantedKinds = getXword(item.name:lower(), enchantedKinds)
        if itemKind == "staff" or itemEnchantedKinds then
            Strength = rFPN(math.ceil((30 + item.weight) + getConfig().Attributes.strength))
            Endurance = rFPN(math.ceil((30 + item.weight) + getConfig().Attributes.endurance))
            Agility = rFPN(math.ceil((15 + 30 * (getMaxWeaponDamage(item) / item.weight)) +
                getConfig().Attributes.agility))
            Skill = rFPN(15 + getConfig().Skills["Blunt Two Wide"].staff)
            return { Strength = Strength, Endurance = Endurance, Agility = Agility, ["Blunt Weapon"] = Skill }
        else
            Strength = rFPN(math.ceil((30 + item.weight) + getConfig().Attributes.strength))
            Endurance = rFPN(math.ceil((30 + item.weight) + getConfig().Attributes.endurance))
            Agility = rFPN(math.ceil((15 + 30 * (getMaxWeaponDamage(item) / item.weight)) +
                getConfig().Attributes.agility))
            Skill = rFPN(25 + getConfig().Skills["Blunt Two Wide"]["other/artifact"])
            return { Strength = Strength, Endurance = Endurance, Agility = Agility, ["Blunt Weapon"] = Skill }
        end
    end,

    BluntTwoClose = function(item)
        local Strength, Endurance, Skill
        local kinds = { "hammer", "bell hammer", "war hammer", "warhammer" }
        local itemKind = getXword(item.name:lower(), kinds)
        local enchantedKinds = { "mauler" }
        local itemEnchantedKinds = getXword(item.name:lower(), enchantedKinds)

        if itemKind or itemEnchantedKinds then
            Strength = rFPN(math.ceil((30 + item.weight) + getConfig().Attributes.strength))
            Endurance = rFPN(math.ceil((30 + item.weight) + getConfig().Attributes.endurance))
            Skill = rFPN(45 + getConfig().Skills["Blunt Two Close"]["hammers - two hands - all"])
            return { Strength = Strength, Endurance = Endurance, ["Blunt Weapon"] = Skill }
        else
            Strength = rFPN(math.ceil((30 + item.weight) + getConfig().Attributes.strength))
            Endurance = rFPN(math.ceil((30 + item.weight) + getConfig().Attributes.endurance))
            Skill = rFPN(50 + getConfig().Skills["Blunt Two Close"]["other/artifact"])
            return { Strength = Strength, Endurance = Endurance, ["Blunt Weapon"] = Skill }
        end
    end,

    Arrow = function(item)
        local Strength, Skill
        local kinds = { "arrow" }
        local itemKind = getXword(item.name:lower(), kinds)
        local enchantedKinds = { "shaft" }
        local itemEnchantedKinds = getXword(item.name:lower(), enchantedKinds)
        if itemKind or itemEnchantedKinds then
            Strength = rFPN(math.min(math.ceil(130 * item.weight), 39) + getConfig().Attributes.strength)
            Skill = rFPN(math.ceil(10 + item.weight + getMaxWeaponDamage(item)) + getConfig().Skills.Arrow.arrow)
            return { Strength = Strength, Marksman = Skill }
        else -- Considering use of general or "other/artifact" for non-standard arrow names
            Strength = rFPN(math.min(math.ceil(130 * item.weight), 39) + getConfig().Attributes.strength)
            Skill = rFPN(math.ceil(10 + item.weight + getMaxWeaponDamage(item)) +
                getConfig().Skills.Arrow["other/artifact"])
            return { Strength = Strength, Marksman = Skill }
        end
    end,

    Bolt = function(item)
        local Strength, Skill
        local kinds = { "bolt" }
        local itemKind = getXword(item.name:lower(), kinds)
        if itemKind then
            Strength = rFPN(math.min(math.ceil(150 * item.weight), 23) + getConfig().Attributes.strength)
            Skill = rFPN(math.ceil(10 + item.weight + getMaxWeaponDamage(item)) + getConfig().Skills.Bolt.bolt)
            return { Strength = Strength, Marksman = Skill }
        else
            Strength = rFPN(math.min(math.ceil(150 * item.weight), 23) + getConfig().Attributes.strength)
            Skill = rFPN(math.ceil(10 + item.weight + getMaxWeaponDamage(item)) +
                getConfig().Skills.Bolt["other/artifact"])
            return { Strength = Strength, Marksman = Skill }
        end
    end,

    --generic magic weapons for #short_blades is dumb. They mix the sufix blade for both daggers and swords. This, if done at all, has to be done on a full name case by case basis, its easy to do but doesn't scale. Most enchanted items in this category will go to other/dagger/sword and that's gonna have to do.
    ShortBladeOneHand = function(item)
        local Speed, Agility, Skill
        local kinds = { "dagger", "tanto", "short sword", "shortsword", "wakizashi" }
        local itemKind = getXword(item.name:lower(), kinds)
        if itemKind == "dagger" then
            Speed = rFPN(math.ceil((15 + 3 * item.weight) + getConfig().Attributes.speed))
            Agility = rFPN(math.ceil((15 + item.weight + getMaxWeaponDamage(item)) + getConfig().Attributes.agility))
            Skill = rFPN(5 + getConfig().Skills["Short Blade One Hand"].dagger)
            return { Speed = Speed, Agility = Agility, ["Short Blade"] = Skill }
        elseif itemKind == "tanto" then
            Speed = rFPN(math.ceil((30 + 4 * item.weight) + getConfig().Attributes.speed))
            Agility = rFPN(math.ceil((30 + item.weight + getMaxWeaponDamage(item)) + getConfig().Attributes.agility))
            Skill = rFPN(15 + getConfig().Skills["Short Blade One Hand"].tanto)
            return { Speed = Speed, Agility = Agility, ["Short Blade"] = Skill }
        elseif itemKind == "short sword" or itemKind == "shortsword" then
            Speed = rFPN(math.ceil((30 + 2 * item.weight) + getConfig().Attributes.speed))
            Agility = rFPN(math.ceil((30 + item.weight + getMaxWeaponDamage(item)) + getConfig().Attributes.agility))
            Skill = rFPN(35 + getConfig().Skills["Short Blade One Hand"]["short sword"])
            return { Speed = Speed, Agility = Agility, ["Short Blade"] = Skill }
        elseif itemKind == "wakizashi" then
            Speed = rFPN(math.ceil((30 + 2 * item.weight) + getConfig().Attributes.speed))
            Agility = rFPN(math.ceil((30 + item.weight + getMaxWeaponDamage(item)) + getConfig().Attributes.agility))
            Skill = rFPN(math.ceil((50 + 1 * item.weight) + getConfig().Skills["Short Blade One Hand"].wakizashi))
            return { Speed = Speed, Agility = Agility, ["Short Blade"] = Skill }
        else
            Speed = rFPN(math.ceil((30 + 2.5 * item.weight) + getConfig().Attributes.speed))
            Agility = rFPN(math.ceil((30 + item.weight + getMaxWeaponDamage(item)) + getConfig().Attributes.agility))
            Skill = rFPN(55 + getConfig().Skills["Short Blade One Hand"]["other/artifact"])
            return { Speed = Speed, Agility = Agility, ["Short Blade"] = Skill }
        end
    end,

    SpearTwoWide = function(item)
        local Strength, Agility, Skill
        local kinds = { "spear", "halberd" }
        local itemKind = getXword(item.name:lower(), kinds)
        local enchantedKinds = { "cleaver", "skewer" }
        local itemEnchantedKinds = getXword(item.name:lower(), enchantedKinds)

        if itemKind == "spear" or itemEnchantedKinds == "skewer" then
            Strength = rFPN(math.ceil((20 + item.weight) + getConfig().Attributes.strength))
            Agility = rFPN(math.ceil((18 + 20 * (getMaxWeaponDamage(item) / item.weight)) +
                getConfig().Attributes.agility))
            Skill = rFPN(5 + getConfig().Skills["Spear Two Wide"].spear)
            return { Strength = Strength, Agility = Agility, ["Spear"] = Skill }
        elseif itemKind == "halberd" or itemEnchantedKinds == "cleaver" then
            Strength = rFPN(math.ceil((20 + 2 * item.weight) + getConfig().Attributes.strength))
            Agility = rFPN(math.ceil((20 + 20 * (getMaxWeaponDamage(item) / item.weight)) +
                getConfig().Attributes.agility))
            Skill = rFPN(40 + getConfig().Skills["Spear Two Wide"].halberd)
            return { Strength = Strength, Agility = Agility, ["Spear"] = Skill }
        else
            Strength = rFPN(math.ceil((20 + 2 * item.weight) + getConfig().Attributes.strength))
            Agility = rFPN(math.ceil((20 + 20 * (getMaxWeaponDamage(item) / item.weight)) +
                getConfig().Attributes.agility))
            Skill = rFPN(45 + getConfig().Skills["Spear Two Wide"]["other/artifact"])
            return { Strength = Strength, Agility = Agility, ["Spear"] = Skill }
        end
    end,

    AxeOneHand = function(item)
        local Strength, Endurance, Skill
        local kinds = { "war axe", "waraxe", "axe" } --enchanted uses axe word.
        local itemKind = getXword(item.name:lower(), kinds)
        if itemKind then
            Strength = rFPN(math.ceil((10 + 1 * item.weight) + getConfig().Attributes.strength))
            Endurance = rFPN(math.ceil((15 + 1.5 * item.weight) + getConfig().Attributes.endurance))
            Skill = rFPN(25 + getConfig().Skills["Axe One Hand"]["axes - one hands - all"])
            return { Strength = Strength, Endurance = Endurance, Axe = Skill }
        else
            Strength = rFPN(math.ceil((20 + 1 * item.weight) + getConfig().Attributes.strength))
            Endurance = rFPN(math.ceil((25 + 1.5 * item.weight) + getConfig().Attributes.endurance))
            Skill = rFPN(35 + getConfig().Skills["Axe One Hand"]["other/artifact"])
            return { Strength = Strength, Endurance = Endurance, Axe = Skill }
        end
    end,

    AxeTwoClose = function(item)
        local Strength, Endurance, Skill
        local kinds = { "pick", "battleaxe", "battle axe" }
        local itemKind = getXword(item.name:lower(), kinds)
        local enchantedKinds = { "rites" }
        local itemEnchantedKinds = getXword(item.name:lower(), enchantedKinds)
        if itemKind or itemEnchantedKinds then
            Strength = rFPN(math.ceil((30 + item.weight) + getConfig().Attributes.strength))
            Endurance = rFPN(math.ceil((30 + item.weight) + getConfig().Attributes.endurance))
            Skill = rFPN(55 + getConfig().Skills["Axe Two Close"]["axes - two hands - all"])
            return { Strength = Strength, Endurance = Endurance, Axe = Skill }
        else
            Strength = rFPN(math.ceil((30 + item.weight) + getConfig().Attributes.strength))
            Endurance = rFPN(math.ceil((30 + item.weight) + getConfig().Attributes.endurance))
            Skill = rFPN(65 + getConfig().Skills["Axe Two Close"]["other/artifact"])
            return { Strength = Strength, Endurance = Endurance, Axe = Skill }
        end
    end,

    lightArmor = function(item)
        local Agility, Skill
        Agility = rFPN(math.ceil((25 + 2 * item.armorRating) + getConfig().Attributes.agility))
        Skill = rFPN(math.ceil(93 / (1 + math.exp(-0.08 * (item.armorRating - 33))) + 10 +
            getConfig().ArmorSkills["Light Armor"]["light armor"]))
        return { Agility = Agility, ["Light Armor"] = Skill }
    end,

    mediumArmor = function(item)
        local Agility, Skill
        Agility = rFPN(math.ceil(1.5 * item.armorRating + getConfig().Attributes.agility))
        Skill = rFPN(math.ceil(93 / (1 + math.exp(-0.08 * (item.armorRating - 33))) +
            getConfig().ArmorSkills["Medium Armor"]["medium armor"]))
        return { Agility = Agility, ["Medium Armor"] = Skill }
    end,

    heavyArmor = function(item)
        local Strength, Skill
        Strength = rFPN(math.ceil((20 + 1.2 * item.armorRating) + getConfig().Attributes.strength))
        Skill = rFPN(math.ceil(93 / (1 + math.exp(-0.08 * (item.armorRating - 33))) +
            getConfig().ArmorSkills["Heavy Armor"]["heavy armor"]))
        return { Strength = Strength, ["Heavy Armor"] = Skill }
    end,

    -- Add other weapon types or categories with similar function structures
    clothing = function(item)
        local Personality
        Personality = rFPN(math.ceil(item.value / 10) + 10 + getConfig().Other.clothing)
        return { Personality = Personality }
    end,

    alchemy = function(item)
        local Endurance
        Endurance = rFPN(math.ceil(50 / (1 + math.exp(-0.02 * (item.value - 60))) + 7) + getConfig().Other.alchemy)
        return { Endurance = Endurance }
    end,

    book = function(item)
        local Intelligence
        Intelligence = rFPN(math.min(math.ceil(35 * (1 - math.exp(-0.1 * item.value))), 35) +
            getConfig().Other.book)
        return { Intelligence = Intelligence }
    end,

    lockpick = function(item)
        local Skill
        Skill = rFPN(math.ceil(item.value / 10 + 24) +
            getConfig().Other.lockpick)
        return { Security = Skill }
    end,

    probe = function(item)
        local Skill
        Skill = rFPN(math.ceil(item.value / 10 + 14) +
            getConfig().Other.probe)
        return { Security = Skill }
    end,

    apparatus = function(item)
        local Skill
        Skill = rFPN(math.ceil(item.value / 10 + 14) +
            getConfig().Other.apparatus)
        return { Alchemy = Skill }
    end,

    spell = function(item)
        local Intelligence
        Intelligence = rFPN(math.min(math.ceil(15 * (1 - math.exp(-0.1 * item.value))), 15) +
            getConfig().Other.spell)
        return { Intelligence = Intelligence }
    end,

    repairItem = function(item)
        local Skill
        Skill = rFPN(math.ceil(item.value / 10 + 14) +
            getConfig().Other.repairItem)
        return { Armorer = Skill }
    end,
}

return formulas
