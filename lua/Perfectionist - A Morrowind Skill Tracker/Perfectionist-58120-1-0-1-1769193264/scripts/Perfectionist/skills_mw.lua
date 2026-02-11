local self = require('openmw.self')

-- id, name, attribute (governing attribute)
local skills = {
    -- COMBAT (Strength, Endurance, Agility, Speed)
    { id = "block", name = "Block", attribute = "agility" },
    { id = "armorer", name = "Armorer", attribute = "strength" },
    { id = "mediumarmor", name = "Medium Armor", attribute = "endurance" },
    { id = "heavyarmor", name = "Heavy Armor", attribute = "endurance" },
    { id = "bluntweapon", name = "Blunt Weapon", attribute = "strength" },
    { id = "longblade", name = "Long Blade", attribute = "strength" },
    { id = "axe", name = "Axe", attribute = "strength" },
    { id = "spear", name = "Spear", attribute = "endurance" },
    { id = "athletics", name = "Athletics", attribute = "speed" },

    -- MAGIC (Intelligence, Willpower, Personality)
    { id = "destruction", name = "Destruction", attribute = "willpower" },
    { id = "alteration", name = "Alteration", attribute = "willpower" },
    { id = "illusion", name = "Illusion", attribute = "personality" },
    { id = "conjuration", name = "Conjuration", attribute = "intelligence" },
    { id = "mysticism", name = "Mysticism", attribute = "willpower" },
    { id = "restoration", name = "Restoration", attribute = "willpower" },
    { id = "enchant", name = "Enchant", attribute = "intelligence" },
    { id = "alchemy", name = "Alchemy", attribute = "intelligence" },
    { id = "unarmored", name = "Unarmored", attribute = "speed" },

    -- STEALTH (Agility, Speed, Personality, Intelligence)
    { id = "security", name = "Security", attribute = "intelligence" },
    { id = "sneak", name = "Sneak", attribute = "agility" },
    { id = "acrobatics", name = "Acrobatics", attribute = "strength" },
    { id = "lightarmor", name = "Light Armor", attribute = "agility" },
    { id = "shortblade", name = "Short Blade", attribute = "speed" },
    { id = "marksman", name = "Marksman", attribute = "agility" },
    { id = "mercantile", name = "Mercantile", attribute = "personality" },
    { id = "speechcraft", name = "Speechcraft", attribute = "personality" },
    { id = "handtohand", name = "Hand-to-Hand", attribute = "speed" }
}

-- Displayed Name
local attributesDisplay = {
    strength = "Strength",
    intelligence = "Intelligence",
    willpower = "Willpower",
    agility = "Agility",
    speed = "Speed",
    endurance = "Endurance",
    personality = "Personality",
    luck = "Luck"
}

-- =============================================================================
-- SENDS DATA
-- =============================================================================
local hasSent = false

return {
    engineHandlers = {
        onUpdate = function(dt)
            if not hasSent then
                print("[Perfectionist] Sending skill data...")
                self:sendEvent("Perfectionist_RegisterData", { skills = skills, attributes = attributesDisplay })
                print("[Perfectionist] Data sent successfully!")
                hasSent = true
            end
        end
    }
}