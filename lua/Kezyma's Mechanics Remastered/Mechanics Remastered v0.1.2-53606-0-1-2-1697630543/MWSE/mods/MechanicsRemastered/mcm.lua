-- Configuration
local config = require('MechanicsRemastered.config')

--- @param e modConfigReadyEventData
local function modConfigReadyCallback(e)
    -- Create and register template.
    local template = mwse.mcm.createTemplate({ name = 'Mechanics Remastered' })
    template:saveOnClose('MechanicsRemastered', config)
    template:register()

    local preferences = template:createSideBarPage({ label = 'Settings' })
    local toggles = preferences:createCategory({ label = 'Features' })

    toggles:createOnOffButton({
        label = 'Always Hit',
        description = 'This setting converts the hit chance of weapons into a damage modifier. As long as the hit chance of an attack is >0, the attack will hit. However, the damage of the attack is proportional to the original hit chance. \ne.g. An attack with a 40% chance of hitting will hit 100% of the time, but deal 40% of the damage.\n\nOn-strike enchantment costs are also scaled based on the hit chance.\ne.g. An on-strike enchant with a 50% hit chance will cost 2x the amount of charge for each hit.',
        variable = mwse.mcm:createTableVariable({ id = 'CombatEnabled', table = config })
    })

    toggles:createOnOffButton({
        label = 'Always Cast',
        description = 'This setting converts the cast chance of a spell into a magicka cost modifier. As long as the cast chance of a spell is >0, the spell will cast. However, the cost of the spell is increased proportional to the original cast chance. \ne.g. An spell with a 50% chance of casting will cast 100% of the time, but cost 2x the magicka.\n\nThe time taken to cast the spell will also scale with the original cast chance, so low chance spells take longer.',
        variable = mwse.mcm:createTableVariable({ id = 'SpellcastEnabled', table = config })
    })

    toggles:createOnOffButton({
        label = 'Health Regeneration',
        description = 'This setting enables passive health regeneration. Outside of combat, health will regenerate at the same rate as when resting (10% of Endurance per hour).',
        variable = mwse.mcm:createTableVariable({ id = 'HealthRegenEnabled', table = config })
    })

    toggles:createDecimalSlider({
        label = 'Health Regeneration Speed',
        description = 'This setting controls the speed of health regeneration. The default resting speed is 1.',
        min = 0.01,
        max = 10,
        defaultSetting = 1.0,
        variable = mwse.mcm:createTableVariable({ id = 'HealthRegenSpeed', table = config })
    })

    toggles:createOnOffButton({
        label = 'Magicka Regeneration',
        description = 'This setting enables passive magicka regeneration. Magicka will regenerate at the same rate as when resting (15% of Intelligence per hour).',
        variable = mwse.mcm:createTableVariable({ id = 'MagickaRegenEnabled', table = config })
    })

    toggles:createDecimalSlider({
        label = 'Magicka Regeneration Speed',
        description = 'This setting controls the speed of magicka regeneration. The default resting speed is 1.',
        min = 0.01,
        max = 10,
        defaultSetting = 1.0,
        variable = mwse.mcm:createTableVariable({ id = 'MagickaRegenSpeed', table = config })
    })

    toggles:createOnOffButton({
        label = 'Uncapped Attribute Bonuses',
        description = 'This setting allows attribute bonuses while leveling up to stack. \ne.g. If you have leveled up 15 skills for an attribute, you will get the bonus for 10 skill increases as normal, as well as the bonus for 5 skill increases.\n\nThis is capped to the maximum theoretical skill increases for your current level to prevent over-leveling attributes beyond the base game limits. \ne.g. If you took a +5 bonus to Strength on reaching level 2, the highest bonus you could receive at level 3 is also +5. If you did not take a +5 bonus to Strength at level 2, the highest bonus you could receive at level 3 is +10.',
        variable = mwse.mcm:createTableVariable({ id = 'LevelupUncappedBonus', table = config })
    })

    toggles:createOnOffButton({
        label = 'Persist Skill Increase Bonuses',
        description = 'This setting persists skill increases towards attribute bonuses across levels. \ne.g. If you have 10 skill increases in Strength skills, but you did not pick Strength as an attribute to increase that level, those 10 skill increases will count towards the bonus next level. If instead, you have 15 skill increases for Strength, but only got a +5 bonus, the remaining 5 skill increases that did not count towards that bonus will be carried over to the next level.',
        variable = mwse.mcm:createTableVariable({ id = 'LevelupPersistSkills', table = config })
    })

    toggles:createOnOffButton({
        label = 'State-Based Health Increase',
        description = 'This setting enables a retroactive health calculation that assumes you chose the maximum possible Endurance bonus on each level up.',
        variable = mwse.mcm:createTableVariable({ id = 'HealthIncreaseEnabled', table = config })
    })

    toggles:createOnOffButton({
        label = 'Fast Travel',
        description = 'This setting enables fast travel. While not in an interior, not in combat and not over-encumbered, clicking a marker on the world map will give the option to teleport to that location if it has been visited before.',
        variable = mwse.mcm:createTableVariable({ id = 'FastTravelEnabled', table = config })
    })

    toggles:createDecimalSlider({
        label = 'Fast Travel Timescale',
        description = 'This setting controls travel time of fast travel. The default travel speed is 1.',
        min = 0.01,
        max = 10,
        defaultSetting = 1.0,
        variable = mwse.mcm:createTableVariable({ id = 'FastTravelTimescale', table = config })
    })
end

event.register(tes3.event.modConfigReady, modConfigReadyCallback)