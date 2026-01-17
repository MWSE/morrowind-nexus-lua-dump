-- Configuration
local config = require('MechanicsRemastered.config')

--- @param e modConfigReadyEventData
local function modConfigReadyCallback(e)
    -- Create and register template.
    local template = mwse.mcm.createTemplate({ name = 'Mechanics Remastered' })
    template:saveOnClose('MechanicsRemastered', config)
    template:register()

    -- ==================== COMBAT SETTINGS ====================
    local combatPage = template:createSideBarPage({ label = 'Combat' })
    combatPage.sidebar:createInfo({
        text = "Combat settings control the 'Always Hit' system which converts hit chance into damage scaling."
    })

    local combatCategory = combatPage:createCategory({ label = 'Combat Settings' })

    combatCategory:createOnOffButton({
        label = 'Enable Combat Overhaul',
        description = 'Master toggle for all combat changes. When disabled, all combat mechanics revert to vanilla behavior.',
        variable = mwse.mcm:createTableVariable({ id = 'CombatEnabled', table = config })
    })

    combatCategory:createOnOffButton({
        label = 'Always Hit',
        description = 'Attacks with >0% hit chance will always connect. Without this, vanilla hit/miss rolls are used.\n\nRequires Combat Overhaul to be enabled.',
        variable = mwse.mcm:createTableVariable({ id = 'CombatAlwaysHit', table = config })
    })

    combatCategory:createOnOffButton({
        label = 'Damage Scaling',
        description = 'Damage is scaled based on the original hit chance. A 40% hit chance attack deals 40% damage.\n\nRequires Combat Overhaul to be enabled.',
        variable = mwse.mcm:createTableVariable({ id = 'CombatDamageScaling', table = config })
    })

    combatCategory:createOnOffButton({
        label = 'Stun Scaling',
        description = 'Stun chance is scaled based on the original hit chance. Low hit chance attacks are less likely to stagger the target.\n\nRequires Combat Overhaul to be enabled.',
        variable = mwse.mcm:createTableVariable({ id = 'CombatStunScaling', table = config })
    })

    combatCategory:createOnOffButton({
        label = 'Attack Skill XP Scaling',
        description = 'Skill progress for attack skills (Blade, Blunt, etc.) is scaled based on hit chance. Glancing blows provide less experience.\n\nRequires Combat Overhaul to be enabled.',
        variable = mwse.mcm:createTableVariable({ id = 'CombatAttackXPScaling', table = config })
    })

    combatCategory:createOnOffButton({
        label = 'Defense Skill XP Scaling',
        description = 'Skill progress for armor skills is scaled based on the attacker\'s hit chance. Glancing blows provide less armor experience.\n\nRequires Combat Overhaul to be enabled.',
        variable = mwse.mcm:createTableVariable({ id = 'CombatDefenseXPScaling', table = config })
    })

    combatCategory:createOnOffButton({
        label = 'Enchantment Charge Scaling',
        description = 'On-strike enchantment charge cost is scaled inversely with hit chance. A 50% hit chance attack costs 2x the enchantment charge.\n\nRequires Combat Overhaul to be enabled.',
        variable = mwse.mcm:createTableVariable({ id = 'CombatEnchantScaling', table = config })
    })

    -- ==================== SPELLCAST SETTINGS ====================
    local spellcastPage = template:createSideBarPage({ label = 'Spellcasting' })
    spellcastPage.sidebar:createInfo({
        text = "Spellcasting settings control the 'Always Cast' system which converts cast chance into magicka cost scaling."
    })

    local spellcastCategory = spellcastPage:createCategory({ label = 'Spellcasting Settings' })

    spellcastCategory:createOnOffButton({
        label = 'Enable Spellcast Overhaul',
        description = 'Master toggle for all spellcasting changes. When disabled, all spellcasting mechanics revert to vanilla behavior.',
        variable = mwse.mcm:createTableVariable({ id = 'SpellcastEnabled', table = config })
    })

    spellcastCategory:createOnOffButton({
        label = 'Always Cast',
        description = 'Spells with >0% cast chance will always succeed. Without this, vanilla success/failure rolls are used.\n\nRequires Spellcast Overhaul to be enabled.',
        variable = mwse.mcm:createTableVariable({ id = 'SpellcastAlwaysCast', table = config })
    })

    spellcastCategory:createOnOffButton({
        label = 'Magicka Cost Scaling',
        description = 'Spell cost is scaled inversely with cast chance. A 50% cast chance spell costs 2x the magicka. The spell menu shows adjusted costs.\n\nRequires Spellcast Overhaul to be enabled.',
        variable = mwse.mcm:createTableVariable({ id = 'SpellcastCostScaling', table = config })
    })

    spellcastCategory:createOnOffButton({
        label = 'Cast Speed Scaling',
        description = 'Casting animation speed is scaled with cast chance. Difficult spells take longer to cast.\n\nRequires Spellcast Overhaul to be enabled.',
        variable = mwse.mcm:createTableVariable({ id = 'SpellcastSpeedScaling', table = config })
    })

    -- ==================== HEALTH REGEN SETTINGS ====================
    local healthRegenPage = template:createSideBarPage({ label = 'Health Regen' })
    healthRegenPage.sidebar:createInfo({
        text = "Health regeneration allows passive healing over time, similar to resting but without the need to sleep."
    })

    local healthRegenCategory = healthRegenPage:createCategory({ label = 'Health Regeneration Settings' })

    healthRegenCategory:createOnOffButton({
        label = 'Enable Health Regeneration',
        description = 'Master toggle for health regeneration. Enables passive health recovery based on Endurance.',
        variable = mwse.mcm:createTableVariable({ id = 'HealthRegenEnabled', table = config })
    })

    healthRegenCategory:createDecimalSlider({
        label = 'Regeneration Speed',
        description = 'Multiplier for health regeneration rate. Default 1.0 matches the resting rate (10% of Endurance per hour).',
        min = 0.01,
        max = 10,
        decimalPlaces = 2,
        variable = mwse.mcm:createTableVariable({ id = 'HealthRegenSpeed', table = config })
    })

    healthRegenCategory:createOnOffButton({
        label = 'NPC Health Regeneration',
        description = 'NPCs and creatures also regenerate health when out of combat.\n\nRequires Health Regeneration to be enabled.',
        variable = mwse.mcm:createTableVariable({ id = 'HealthRegenNPC', table = config })
    })

    healthRegenCategory:createOnOffButton({
        label = 'Out of Combat Only',
        description = 'Health only regenerates when not in combat. Disable to allow regeneration during combat.\n\nRequires Health Regeneration to be enabled.',
        variable = mwse.mcm:createTableVariable({ id = 'HealthRegenOutOfCombatOnly', table = config })
    })

    healthRegenCategory:createOnOffButton({
        label = 'Regenerate While Waiting',
        description = 'Health regenerates during waiting (T key). Applies the regeneration rate to the time spent waiting.\n\nRequires Health Regeneration to be enabled.',
        variable = mwse.mcm:createTableVariable({ id = 'HealthRegenWhileWaiting', table = config })
    })

    -- ==================== MAGICKA REGEN SETTINGS ====================
    local magickaRegenPage = template:createSideBarPage({ label = 'Magicka Regen' })
    magickaRegenPage.sidebar:createInfo({
        text = "Magicka regeneration allows passive mana recovery over time. Characters with Stunted Magicka (Atronach) cannot regenerate."
    })

    local magickaRegenCategory = magickaRegenPage:createCategory({ label = 'Magicka Regeneration Settings' })

    magickaRegenCategory:createOnOffButton({
        label = 'Enable Magicka Regeneration',
        description = 'Master toggle for magicka regeneration. Enables passive magicka recovery based on Intelligence.',
        variable = mwse.mcm:createTableVariable({ id = 'MagickaRegenEnabled', table = config })
    })

    magickaRegenCategory:createDecimalSlider({
        label = 'Regeneration Speed',
        description = 'Multiplier for magicka regeneration rate. Default 1.0 matches the resting rate (15% of Intelligence per hour).',
        min = 0.01,
        max = 10,
        decimalPlaces = 2,
        variable = mwse.mcm:createTableVariable({ id = 'MagickaRegenSpeed', table = config })
    })

    magickaRegenCategory:createOnOffButton({
        label = 'NPC Magicka Regeneration',
        description = 'NPCs and creatures also regenerate magicka passively.\n\nRequires Magicka Regeneration to be enabled.',
        variable = mwse.mcm:createTableVariable({ id = 'MagickaRegenNPC', table = config })
    })

    magickaRegenCategory:createOnOffButton({
        label = 'Regenerate While Waiting',
        description = 'Magicka regenerates during waiting (T key). Applies the regeneration rate to the time spent waiting.\n\nRequires Magicka Regeneration to be enabled.',
        variable = mwse.mcm:createTableVariable({ id = 'MagickaRegenWhileWaiting', table = config })
    })

    -- ==================== LEVEL UP SETTINGS ====================
    local levelUpPage = template:createSideBarPage({ label = 'Level Up' })
    levelUpPage.sidebar:createInfo({
        text = "Level up settings modify how attribute bonuses are calculated and persisted across levels."
    })

    local levelUpCategory = levelUpPage:createCategory({ label = 'Level Up Settings' })

    levelUpCategory:createOnOffButton({
        label = 'Uncapped Attribute Bonuses',
        description = 'Attribute bonuses can stack beyond +5. If you have 15 skill increases for an attribute, you get +5 plus the bonus for 5 more increases.\n\nCapped to the maximum theoretical for your level to prevent over-leveling.',
        variable = mwse.mcm:createTableVariable({ id = 'LevelupUncappedBonus', table = config })
    })

    levelUpCategory:createOnOffButton({
        label = 'Persist Skill Bonuses',
        description = 'Unused skill increases carry over to the next level. If you have 15 increases but only take +5, the remaining 10 count toward your next level up.',
        variable = mwse.mcm:createTableVariable({ id = 'LevelupPersistSkills', table = config })
    })

    levelUpCategory:createOnOffButton({
        label = 'State-Based Health',
        description = 'Retroactively calculates health as if you always chose the maximum Endurance bonus. Health increases optimally regardless of when you raised Endurance.',
        variable = mwse.mcm:createTableVariable({ id = 'HealthIncreaseEnabled', table = config })
    })

    -- ==================== FAST TRAVEL SETTINGS ====================
    local fastTravelPage = template:createSideBarPage({ label = 'Fast Travel' })
    fastTravelPage.sidebar:createInfo({
        text = "Fast travel allows instant travel to visited locations by clicking on the world map."
    })

    local fastTravelCategory = fastTravelPage:createCategory({ label = 'Fast Travel Settings' })

    fastTravelCategory:createOnOffButton({
        label = 'Enable Fast Travel',
        description = 'Master toggle for fast travel. Click a location on the world map to travel there instantly.',
        variable = mwse.mcm:createTableVariable({ id = 'FastTravelEnabled', table = config })
    })

    fastTravelCategory:createDecimalSlider({
        label = 'Travel Time Multiplier',
        description = 'Multiplier for how much game time passes during fast travel. Higher values mean more time passes.',
        min = 0.01,
        max = 10,
        decimalPlaces = 2,
        variable = mwse.mcm:createTableVariable({ id = 'FastTravelTimescale', table = config })
    })

    fastTravelCategory:createOnOffButton({
        label = 'Advance Time',
        description = 'Game time advances based on travel distance. Disable for instant travel with no time passing.\n\nRequires Fast Travel to be enabled.',
        variable = mwse.mcm:createTableVariable({ id = 'FastTravelAdvanceTime', table = config })
    })

    fastTravelCategory:createOnOffButton({
        label = 'Regenerate Stats During Travel',
        description = 'Health and magicka regenerate during fast travel based on time passed. Independent of passive regeneration settings.\n\nRequires Fast Travel to be enabled.',
        variable = mwse.mcm:createTableVariable({ id = 'FastTravelRegen', table = config })
    })

    local fastTravelRestrictions = fastTravelPage:createCategory({ label = 'Travel Restrictions' })

    fastTravelRestrictions:createOnOffButton({
        label = 'Allow Travel in Combat',
        description = 'Allows fast travel while in combat. By default, you must exit combat before traveling.',
        variable = mwse.mcm:createTableVariable({ id = 'FastTravelAllowInCombat', table = config })
    })

    fastTravelRestrictions:createOnOffButton({
        label = 'Allow Travel While Overencumbered',
        description = 'Allows fast travel while carrying too much weight. By default, you must reduce your load first.',
        variable = mwse.mcm:createTableVariable({ id = 'FastTravelAllowOverencumbered', table = config })
    })

    fastTravelRestrictions:createOnOffButton({
        label = 'Allow Travel From Interiors',
        description = 'Allows fast travel from inside buildings and dungeons. By default, you must be outdoors.',
        variable = mwse.mcm:createTableVariable({ id = 'FastTravelAllowFromInterior', table = config })
    })

    fastTravelRestrictions:createOnOffButton({
        label = 'Require Location Visited',
        description = 'Requires you to have visited a location before you can fast travel there. Disable to travel anywhere.',
        variable = mwse.mcm:createTableVariable({ id = 'FastTravelRequireVisited', table = config })
    })
end

event.register(tes3.event.modConfigReady, modConfigReadyCallback)
