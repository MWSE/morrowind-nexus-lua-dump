local types = require('openmw.types')
local util = require('openmw.util')

return {
    [types.Potion] = {
        title = 'Potion',
        color = util.color.rgb(0.6, 0.5, 1.0),
        showEffect = true,
        showValue = true,
        uniqueDescriptions = {
			['potion_skooma_01'] = {
				'Skooma',
				'Illicit elven distillate derived from moon sugar. Highly addictive', 
				'substance that provides temporary boosts to stamina and aggression.',
				'Effects: Restore Fatigue +50 pts, Fortify Speed +15 pts for 60 sec,', 
				'Fortify Strength +10 pts for 60 sec',
				'Alchemy Ingredients: Moon Sugar, Crimson Nirnroot, Nightshade',
				'Notes: Illegal in most provinces. Prolonged use leads to severe', 
				'addiction and health deterioration.'
			},
			['potion_local_brew_01'] = {
				'Mazte',
				'Traditional Dunmer fermented drink, often called "Dunmeri beer". Made', 
				'from local grains and spices, with a distinct smoky flavor.',
				'Effects: Restore Fatigue +25 pts, Drain Agility −5 pts for 30 sec,', 
				'Drain Intelligence −5 pts for 30 sec',
				'Weight: 0.5, Value: 10',
				'Alchemy Ingredients: Ash Yams, Scathecraw, Salt Piles (fermented)',
				'Notes: Common social drink in Dunmer households and taverns. Mildly', 
				'intoxicating. Not considered a true potion, but has minor alchemical', 
				'properties.'
			},
			['Potion_Cyro_Whiskey_01'] = {
				'Cyro Whiskey',
				'Premium distilled spirit from the Cyro region. Known for its smooth,', 
				'warming properties.',
				'Effects: Restore Fatigue +20 pts, Fortify Endurance +5 pts for 30 sec',
				'Alchemy Ingredients: Barley Malt, Mountain Water, Winter Wheat',
				'Notes: Popular among nobility. Often served in fine establishments.'
			},

			['potion_comberry_wine_01'] = {
				'Comberry Wine',
				'Rich, dark wine made from ripe comberry fruits. Possesses mild', 
				'restorative properties.',
				'Effects: Restore Health +25 pts, Fortify Personality +5 pts for 30 sec',
				'Alchemy Ingredients: Comberries, Sweet Honey, Aged Vinegar',
				'Notes: Commonly found in taverns and inns. Served during celebrations.'
			},

			['potion_cyro_brandy_01'] = {
				'Cyro Brandy',
				'Aged spirit distilled in the Cyro mountains. Known for its warming', 
				'effect and restorative qualities.',
				'Effects: Restore Health +15 pts, Fortify Endurance +10 pts for 45 sec',
				'Alchemy Ingredients: Cyro Grapes, Mountain Herbs, Pure Water',
				'Notes: Considered a luxury item. Often used for toasting.'
			},

			['potion_comberry_brandy_01'] = {
				'Comberry Brandy',
				'Unique blend of comberry essence and fine brandy. Combines health', 
				'and stamina restoration.',
				'Effects: Restore Health +20 pts, Restore Fatigue +20 pts',
				'Alchemy Ingredients: Comberries, Brandy Base, Honey',
				'Notes: Rare concoction. Prized for its dual restorative properties.'
			},

			['Potion_Local_Brew_01'] = {
				'Local Mead',
				'Traditional honey-based alcoholic beverage. Mildly restorative.',
				'Effects: Restore Fatigue +15 pts, Fortify Health +10 pts for 30 sec',
				'Alchemy Ingredients: Wild Honey, Water, Fermented Grains',
				'Notes: Common in rural areas. Often homemade.'
			},

			['potion_local_liquor_01'] = {
				'Dunmer Distillate',
				'Strong spirit distilled from local ingredients. Provides temporary', 
				'stamina boost.',
				'Effects: Restore Fatigue +30 pts, Drain Intelligence −5 pts', 
				'for 60 sec',
				'Alchemy Ingredients: Ash Yams, Scathecraw, Fermented Grains',
				'Notes: Popular in Dunmer settlements. Known for its potency.'
			},

			['potion_t_bug_musk_01'] = {
				'Bug Musk Extract',
				'Concentrated essence derived from local insects. Used for',
'				attracting or repelling creatures.',
				'Effects: Attract/Repel Creatures for 60 sec',
				'Alchemy Ingredients: Giant Bug Parts, Musk Glands, Fermented Honey',
				'Notes: Primarily used by hunters and trappers.'
			},

			['p_burden_s'] = {
				'Burden Potion (Weak)',
				"Reduces the characters carrying capacity temporarily.",
				'Effects: Reduce Carry Weight −20% for 60 sec',
				'Alchemy Ingredients: Snowberries, Imp Stool, Mudcrab Chitin',
				'Notes: Often used in traps or as a prank.'
			},

			['p_fire_shield_s'] = {
				'Fire Shield Potion (Weak)',
				'Creates a basic fiery barrier around the caster, absorbing minor', 
				'fire damage.',
				'Effects: Absorb Fire Damage +15 pts for 60 sec',
				'Alchemy Ingredients: Fire Salts, Crimson Nirnroot, Volcanic Ash',
				'Notes: Basic defensive potion, useful against low-level fire', 
				'attacks.'
			},

			['p_fortify_endurance_s'] = {
				'Fortify Endurance Potion (Weak)',
				"Temporarily boosts the drinkers stamina and physical endurance.",
				'Effects: Fortify Endurance +10 pts for 60 sec',
				'Alchemy Ingredients: Bear Claws, Wheat, Cabbage',
				'Notes: Commonly used by warriors before combat.'
			},

			['p_fortify_personality_s'] = {
				'Fortify Personality Potion (Weak)',
				'Enhances charisma and social skills temporarily.',
				'Effects: Fortify Personality +10 pts for 60 sec',
				'Alchemy Ingredients: Butterfly Wings, Honeycomb, Lavender',
				'Notes: Popular among diplomats and merchants.'
			},

			['p_fortify_speed_s'] = {
				'Fortify Speed Potion (Weak)',
				'Increases movement speed for a short duration.',
				'Effects: Fortify Speed +15% for 60 sec',
				'Alchemy Ingredients: Sprint Extract, Swiftness Root, Hare Meat',
				'Notes: Useful for escaping or catching up to targets.'
			},

			['p_fortify_strength_s'] = {
				'Fortify Strength Potion (Weak)',
				'Boosts physical strength, increasing melee damage.',
				'Effects: Fortify Strength +10 pts for 60 sec',
				'Alchemy Ingredients: Bear Claws, Mammoth Tusk, Stalhrim',
				'Notes: Favored by warriors and fighters.'
			},

			['p_fortify_health_s'] = {
				'Fortify Health Potion (Weak)',
				'Increases maximum health temporarily.',
				'Effects: Fortify Health +15 pts for 60 sec',
				'Alchemy Ingredients: Heart of Aelter, Crimson Nirnroot,', 
				'Bear Heart',
				'Notes: Provides temporary health boost in combat.'
			},

			['p_invisibility_s'] = {
				'Invisibility Potion (Weak)',
				'Makes the drinker partially invisible for a short time.',
				'Effects: Invisibility for 30 sec',
				'Alchemy Ingredients: Nightshade, Shadowscale, Void Salts',
				'Notes: Useful for stealth missions and evading enemies.'
			},

			['p_light_s'] = {
				'Light Potion (Weak)',
				'Creates a small light source around the drinker.',
				'Effects: Light Radius +5 ft for 60 sec',
				'Alchemy Ingredients: Glow Dust, Moonstone, Fire Salts',
				'Notes: Basic illumination potion for dark areas.'
			},

			['p_lightning_shield_s'] = {
				'Lightning Shield Potion (Weak)',
				'Generates an electrical barrier that damages nearby enemies.',
				'Effects: Absorb Shock Damage +15 pts, Damage Enemies on Touch', 
				'for 60 sec',
				'Alchemy Ingredients: Shock Salts, Storm Atronach Horn, Lightning',
				'Bug Parts',
				'Notes: Defensive potion with offensive capabilities.'
			},

			['p_night-eye_s'] = {
				'Night-Eye Potion (Weak)',
				'Enhances vision in low-light conditions.',
				'Effects: Night Vision +30% for 60 sec',
				"Alchemy Ingredients: Cat's Eye, Night Eye Flower, Moonstone Dust",
				'Notes: Essential for night missions.'
			},

			['p_paralyze_s'] = {
				'Paralyze Potion (Weak)',
				'Temporarily immobilizes enemies who come into contact.',
				'Effects: Paralyze Targets for 10 sec on Touch',
				'Alchemy Ingredients: Spider Venom, Ataxia Root, Paralysis Mushroom',
				'Notes: Offensive potion for disabling enemies.'
			},

			['p_reflection_s'] = {
				'Reflection Potion (Weak)',
				'Causes incoming spells to rebound back to the caster.',
				'Effects: Spell Reflection Chance +20% for 60 sec',
				'Alchemy Ingredients: Diamond Dust, Moonstone, Crystal Marrow',
				'Notes: Advanced defensive potion against magic attacks.'
			},

			['p_fire_resistance_s'] = {
				'Fire Resistance Potion (Weak)',
				'Provides temporary resistance to fire-based damage.',
				'Effects: Fire Resistance +20% for 60 sec',
				'Alchemy Ingredients: Fire Salts, Dragon Heart, Volcanic Ash',
				'Notes: Essential for fire-heavy environments.'
			},

			['p_magicka_resistance_s'] = {
				'Magicka Resistance Potion (Weak)',
				'Reduces damage from magical attacks.',
				'Effects: Magicka Resistance +15% for 60 sec',
				'Alchemy Ingredients: Ebony Dust, Void Salts, Soul Gem Shards',
				'Notes: Useful against spellcasters.'
			},

			['p_poison_resistance_s'] = {
				'Poison Resistance Potion (Weak)',
				'Provides temporary immunity to poison effects.',
				'Effects: Poison Resistance +20% for 60 sec',
				'Alchemy Ingredients: Poison Ivy, Viper Tongue, Deathbell',
				'Notes: Vital for poison-heavy dungeons.'
			},

			['p_shock_resistance_s'] = {
				'Shock Resistance Potion (Weak)',
				'Reduces damage from electrical attacks.',
				'Effects: Shock Resistance +20% for 60 sec',
				'Alchemy Ingredients: Lightning Bug Parts, Storm Atronach Horn,', 
				'Shock Salts',
				'Notes: Effective against electrical enemies.'
			},

			['p_restore_agility_s'] = {
				'Restore Agility Potion (Weak)',
				'Restores agility points and improves reflexes.',
				'Effects: Restore Agility +10 pts for 60 sec',
				'Alchemy Ingredients: Deer Tongue, Swiftness Root, Hare Meat',
				'Notes: Beneficial for archers and acrobats.'
			},

			['p_restore_endurance_s'] = {
				'Restore Endurance Potion (Weak)',
				'Refills endurance reserves.',
				'Effects: Restore Endurance +15 pts for 60 sec',
				'Alchemy Ingredients: Bear Claws, Wheat, Cabbage',
				'Notes: Commonly used during long journeys.'
			},

			['p_restore_intelligence_s'] = {
				'Restore Intelligence Potion (Weak)',
				'Restores intelligence points and enhances magical abilities.',
				'Effects: Restore Intelligence +10 pts for 60 sec',
				'Alchemy Ingredients: Nightshade, Snowberries, Grand Soul Gem',
				'Notes: Valuable for spellcasters.'
			},

			['p_restore_luck_s'] = {
				'Restore Luck Potion (Weak)',
				'Temporarily boosts luck, improving chances in games and quests.',
				'Effects: Restore Luck +10 pts for 60 sec',
				'Alchemy Ingredients: Four Leaf Clover, Gold Dust, Diamond Shards',
				'Notes: Popular among gamblers and adventurers.'
			},

			['p_restore_personality_s'] = {
				'Restore Personality Potion (Weak)',
				'Restores personality points and enhances social skills.',
				'Effects: Restore Personality +10 pts for 60 sec',
				'Alchemy Ingredients: Butterfly Wings, Honeycomb, Lavender',
				'Notes: Useful for negotiations and diplomacy.'
			},

			['p_restore_speed_s'] = {
				'Restore Speed Potion (Weak)',
				'Increases movement speed temporarily.',
				'Effects: Restore Speed +15% for 60 sec',
				'Alchemy Ingredients: Sprint Extract, Swiftness Root, Hare Meat',
				'Notes: Ideal for escaping or chasing.'
			},

			['p_restore_strength_s'] = {
				'Restore Strength Potion (Weak)',
				'Restores strength points and enhances melee damage.',
				'Effects: Restore Strength +10 pts for 60 sec',
				'Alchemy Ingredients: Bear Claws, Mammoth Tusk, Stalhrim',
				'Notes: Essential for warriors and melee combatants.'
			},

			['p_restore_willpower_s'] = {
				'Restore Willpower Potion (Weak)',
				'Restores willpower points and enhances magical resistance.',
				'Effects: Restore Willpower +10 pts for 60 sec',
				'Alchemy Ingredients: Dragon Heart, Ebony Dust, Void Salts',
				'Notes: Beneficial for spellcasters and magic users.'
			},

			['p_restore_fatigue_s'] = {
				'Restore Fatigue Potion (Weak)',
				'Refills fatigue reserves, allowing more actions.',
				'Effects: Restore Fatigue +25 pts for 60 sec',
				'Alchemy Ingredients: Wheat, Cabbage, Honey',
				'Notes: Commonly used during extended combat.'
			},

			['p_silence_s'] = {
				'Silence Potion (Weak)',
				'Prevents casting of spells for a short duration.',
				'Effects: Silence for 30 sec',
				'Alchemy Ingredients: Spider Silk, Nightshade, Void Salts',
				'Notes: Used to disable enemy spellcasters.'
			},

			['p_spell_absorption_s'] = {
				'Spell Absorption Potion (Weak)',
				'Allows absorption of incoming spells into magicka.',
				'Effects: Spell Absorption Chance +20% for 60 sec',
				'Alchemy Ingredients: Soul Gems, Moonstone, Crystal Marrow',
				'Notes: Advanced defensive potion against magic.'
			},

			['p_levitation_s'] = {
				'Levitation Potion (Weak)',
				'Enables temporary flight and bypassing obstacles.',
				'Effects: Levitation for 60 sec',
				'Alchemy Ingredients: Feather, Moonstone, Cloud Dust',
				'Notes: Useful for exploration and escape.'
			},

			['p_fortify_fatigue_s'] = {
				'Fortify Fatigue Potion (Weak)',
				'Increases maximum fatigue temporarily.',
				'Effects: Fortify Fatigue +15 pts for 60 sec',
				'Alchemy Ingredients: Wheat, Honey, Cabbage',
				'Notes: Enhances stamina reserves in combat.'
			},

			['p_burden_c'] = {
				'Burden Potion (Common)',
				'Reduces carrying capacity significantly.',
				'Effects: Reduce Carry Weight −30% for 90 sec',
				'Alchemy Ingredients: Imp Stool, Mudcrab Chitin, Snowberries',
				'Notes: More potent version of the weak variant.'
			},

			['p_burden_b'] = {
				'Burden Potion (Better)',
				'Severely reduces carrying capacity.',
				'Effects: Reduce Carry Weight −40% for 120 sec',
				'Alchemy Ingredients: Giant Mudcrab Chitin, Imp Stool, Poison Ivy',
				'Notes: Stronger version for more advanced effects.'
			},

			['p_burden_q'] = {
				'Burden Potion (Superior)',
				'Drastically reduces carrying capacity.',
				'Effects: Reduce Carry Weight −50% for 150 sec',
				'Alchemy Ingredients: Giant Mudcrab Chitin, Poison Ivy, Deathbell',
				'Notes: Highest potency version.'
			},

			['p_burden_e'] = {
				'Burden Potion (Expert)',
				'Nearly incapacitates carrying ability.',
				'Effects: Reduce Carry Weight −60% for 180 sec',
				'Alchemy Ingredients: Giant Mudcrab Chitin, Deathbell, Poison Ivy',
				'Notes: Expert-level potion for maximum effect.'
			},

			['p_drain_agility_q'] = {
				'Drain Agility Potion (Superior)',
				"Temporarily reduces target's agility, impairing reflexes", 
				"and movement.",
				'Effects: Drain Agility −15 pts for 120 sec',
				'Alchemy Ingredients: Spider Venom, Ataxia Root,', 
				'Paralysis Mushroom',
				'Notes: Offensive potion for disabling enemies.'
			},

			['p_drain_endurance_q'] = {
				'Drain Endurance Potion (Superior)',
				"Drains target's endurance, causing fatigue.",
				'Effects: Drain Endurance −15 pts for 120 sec',
				'Alchemy Ingredients: Vampire Dust, Bloodroot, Deathbell',
				'Notes: Effective against warriors and fighters.'
			},

			['p_drain_intelligence_q'] = {
				'Drain Intelligence Potion (Superior)',
				"Reduces target's intelligence, impairing spellcasting.",
				'Effects: Drain Intelligence −15 pts for 120 sec',
				'Alchemy Ingredients: Nightshade, Void Salts, Spider Silk',
				'Notes: Counter-magic potion.'
			},

			['p_drain_luck_q'] = {
				'Drain Luck Potion (Superior)',
				"Temporarily reduces target's luck, decreasing favorable outcomes.",
				'Effects: Drain Luck −15 pts for 120 sec',
				'Alchemy Ingredients: Broken Four Leaf Clover, Spider Eyes, Deathbell',
				'Notes: Used to disadvantage opponents.'
			},

			['p_drain_magicka_q'] = {
				'Drain Magicka Potion (Superior)',
				"Drains target's magicka reserves.",
				'Effects: Drain Magicka −25 pts for 120 sec',
				'Alchemy Ingredients: Soul Gems, Void Salts, Ebony Dust',
				'Notes: Powerful against spellcasters.'
			},

			['p_drain_personality_q'] = {
				'Drain Personality Potion (Superior)',
				"Reduces target's charisma and social skills.",
				'Effects: Drain Personality −15 pts for 120 sec',
				'Alchemy Ingredients: Spider Venom, Nightshade, Poison Ivy',
				'Notes: Useful in negotiations.'
			},

			['p_drain_speed_q'] = {
				'Drain Speed Potion (Superior)',
				"Slows down target's movement.",
				'Effects: Drain Speed −20% for 120 sec',
				'Alchemy Ingredients: Ataxia Root, Spider Venom, Paralysis Mushroom',
				'Notes: Effective for trapping enemies.'
			},

			['p_drain_strength_q'] = {
				'Drain Strength Potion (Superior)',
				"Weakens target's physical strength.",
				'Effects: Drain Strength −15 pts for 120 sec',
				'Alchemy Ingredients: Vampire Dust, Bloodroot, Deathbell',
				'Notes: Diminishes melee effectiveness.'
			},

			['p_drain_willpower_q'] = {
				'Drain Willpower Potion (Superior)',
				"Reduces target's willpower, weakening magical resistance.",
				'Effects: Drain Willpower −15 pts for 120 sec',
				'Alchemy Ingredients: Void Salts, Soul Gems, Ebony Dust',
				'Notes: Enhances susceptibility to magic.'
			},

			['p_feather_c'] = {
				'Feather Potion (Common)',
				'Increases carrying capacity temporarily.',
				'Effects: Increase Carry Weight +20% for 90 sec',
				'Alchemy Ingredients: Feather, Honeycomb, Lavender',
				'Notes: Basic weight reduction potion.'
			},

			['p_feather_b'] = {
				'Feather Potion (Better)',
				'Significantly increases carrying capacity.',
				'Effects: Increase Carry Weight +30% for 120 sec',
				'Alchemy Ingredients: Giant Eagle Feather, Honeycomb, Lavender',
				'Notes: Improved weight reduction.'
			},

			['p_feather_e'] = {
				'Feather Potion (Excellent)',
				'Greatly increases carrying capacity, allowing to carry', 
				'heavier loads.',
				'Effects: Increase Carry Weight +40% for 150 sec',
				'Alchemy Ingredients: Giant Eagle Feather, Honeycomb, Lavender,', 
				'Moonstone',
				'Notes: Advanced weight reduction potion for heavy loads.'
			},

			['p_feather_q'] = {
				'Feather Potion (Superior)',
				'Drastically increases carrying capacity to near-limitless levels.',
				'Effects: Increase Carry Weight +50% for 180 sec',
				'Alchemy Ingredients: Giant Eagle Feather, Dragon Bone, Honeycomb',
				'Notes: Expert-level potion for extreme weight reduction.'
			},

			['p_fire_shield_c'] = {
				'Fire Shield Potion (Common)',
				'Provides moderate protection against fire damage.',
				'Effects: Absorb Fire Damage +25 pts for 90 sec',
				'Alchemy Ingredients: Fire Salts, Crimson Nirnroot, Volcanic Ash',
				'Notes: Basic defensive potion against fire.'
			},

			['p_fire_shield_b'] = {
				'Fire Shield Potion (Better)',
				'Enhanced protection against fire-based attacks.',
				'Effects: Absorb Fire Damage +35 pts for 120 sec',
				'Alchemy Ingredients: Fire Salts, Dragon Heart, Volcanic Ash',
				'Notes: Improved fire resistance.'
			},

			['p_fire_shield_e'] = {
				'Fire Shield Potion (Excellent)',
				'Strong protection against fire damage.',
				'Effects: Absorb Fire Damage +45 pts for 150 sec',
				'Alchemy Ingredients: Fire Salts, Dragon Heart, Volcanic Ash, Ruby',
				'Notes: Advanced fire resistance potion.'
			},

			['p_fire_shield_q'] = {
				'Fire Shield Potion (Superior)',
				'Near-complete protection against fire attacks.',
				'Effects: Absorb Fire Damage +55 pts for 180 sec',
				'Alchemy Ingredients: Fire Salts, Dragon Heart, Ruby, Volcanic Ash',
				'Notes: Expert-level fire resistance.'
			},

			['p_fortify_agility_c'] = {
				'Fortify Agility Potion (Common)',
				'Moderately boosts agility and reflexes.',
				'Effects: Fortify Agility +15 pts for 90 sec',
				'Alchemy Ingredients: Deer Tongue, Swiftness Root, Hare Meat',
				'Notes: Basic agility enhancement.'
			},

			['p_fortify_agility_b'] = {
				'Fortify Agility Potion (Better)',
				'Significantly enhances agility.',
				'Effects: Fortify Agility +20 pts for 120 sec',
				'Alchemy Ingredients: Deer Tongue, Swiftness Root, Hare Meat,', 
				'Diamond Dust',
				'Notes: Improved agility boost.'
			},

			['p_fortify_agility_q'] = {
				'Fortify Agility Potion (Superior)',
				'Drastically increases agility and reflexes.',
				'Effects: Fortify Agility +25 pts for 150 sec',
				'Alchemy Ingredients: Deer Tongue, Swiftness Root, Diamond Dust,', 
				'Hare Meat',
				'Notes: Expert-level agility enhancement.'
			},

			['p_fortify_agility_e'] = {
				'Fortify Agility Potion (Excellent)',
				'Maximum boost to agility and reflexes.',
				'Effects: Fortify Agility +30 pts for 180 sec',
				'Alchemy Ingredients: Deer Tongue, Swiftness Root, Diamond Dust,', 
				'Hare Meat, Moonstone',
				'Notes: Peak agility enhancement.'
			},

			['p_fortify_endurance_c'] = {
				'Fortify Endurance Potion (Common)',
				'Moderately boosts stamina and physical endurance.',
				'Effects: Fortify Endurance +15 pts for 90 sec',
				'Alchemy Ingredients: Bear Claws, Wheat, Cabbage',
				'Notes: Basic stamina enhancement.'
			},

			['p_fortify_endurance_b'] = {
				'Fortify Endurance Potion (Better)',
				'Significantly enhances stamina and physical endurance.',
				'Effects: Fortify Endurance +20 pts for 120 sec',
				'Alchemy Ingredients: Bear Claws, Mammoth Tusk, Wheat, Cabbage',
				'Notes: Improved stamina boost for extended combat.'
			},

			['p_fortify_endurance_q'] = {
				'Fortify Endurance Potion (Superior)',
				'Drastically increases stamina reserves.',
				'Effects: Fortify Endurance +25 pts for 150 sec',
				'Alchemy Ingredients: Bear Claws, Mammoth Tusk, Stalhrim, Wheat',
				'Notes: Expert-level stamina enhancement.'
			},

			['p_fortify_endurance_e'] = {
				'Fortify Endurance Potion (Excellent)',
				'Maximum boost to stamina and physical endurance.',
				'Effects: Fortify Endurance +30 pts for 180 sec',
				'Alchemy Ingredients: Bear Claws, Mammoth Tusk, Stalhrim,', 
				'Diamond Dust',
				'Notes: Peak stamina enhancement for prolonged battles.'
			},

			['p_fortify_fatigue_c'] = {
				'Fortify Fatigue Potion (Common)',
				'Moderately increases maximum fatigue.',
				'Effects: Fortify Fatigue +20 pts for 90 sec',
				'Alchemy Ingredients: Wheat, Honey, Cabbage',
				'Notes: Basic fatigue enhancement.'
			},

			['p_fortify_fatigue_b'] = {
				'Fortify Fatigue Potion (Better)',
				'Significantly boosts fatigue reserves.',
				'Effects: Fortify Fatigue +25 pts for 120 sec',
				'Alchemy Ingredients: Wheat, Honey, Cabbage, Bear Heart',
				'Notes: Improved fatigue capacity.'
			},

			['p_fortify_fatigue_e'] = {
				'Fortify Fatigue Potion (Excellent)',
				'Drastically increases maximum fatigue.',
				'Effects: Fortify Fatigue +30 pts for 150 sec',
				'Alchemy Ingredients: Wheat, Honey, Bear Heart, Mammoth Tusk',
				'Notes: Advanced fatigue enhancement.'
			},

			['p_fortify_fatigue_q'] = {
				'Fortify Fatigue Potion (Superior)',
				'Maximum boost to fatigue reserves.',
				'Effects: Fortify Fatigue +35 pts for 180 sec',
				'Alchemy Ingredients: Wheat, Honey, Bear Heart, Mammoth Tusk,', 
				'Stalhrim',
				'Notes: Expert-level fatigue enhancement.'
			},

			['p_fortify_health_c'] = {
				'Fortify Health Potion (Common)',
				'Moderately increases maximum health.',
				'Effects: Fortify Health +20 pts for 90 sec',
				'Alchemy Ingredients: Heart of Aelter, Crimson Nirnroot,', 
				'Bear Heart',
				'Notes: Basic health enhancement.'
			},

			['p_fortify_health_e'] = {
				'Fortify Health Potion (Excellent)',
				'Significantly boosts maximum health.',
				'Effects: Fortify Health +30 pts for 150 sec',
				'Alchemy Ingredients: Heart of Aelter, Crimson Nirnroot,', 
				'Bear Heart, Ruby',
				'Notes: Advanced health enhancement.'
			},

			['p_fortify_health_q'] = {
				'Fortify Health Potion (Superior)',
				'Maximum boost to maximum health.',
				'Effects: Fortify Health +35 pts for 180 sec',
				'Alchemy Ingredients: Heart of Aelter, Crimson Nirnroot, Bear Heart,', 
				'Ruby, Diamond Dust',
				'Notes: Expert-level health enhancement.'
			},

			['p_fortify_intelligence_c'] = {
				'Fortify Intelligence Potion (Common)',
				'Moderately enhances magical abilities.',
				'Effects: Fortify Intelligence +15 pts for 90 sec',
				'Alchemy Ingredients: Nightshade, Snowberries, Grand Soul Gem',
				'Notes: Basic magic enhancement.'
			},

			['p_fortify_intelligence_b'] = {
				'Fortify Intelligence Potion (Better)',
				'Significantly boosts magical abilities and spellcasting power.',
				'Effects: Fortify Intelligence +20 pts for 120 sec',
				'Alchemy Ingredients: Nightshade, Snowberries, Grand Soul Gem,', 
				'Moonstone',
				'Notes: Improved magic enhancement for spellcasters.'
			},

			['p_fortify_intelligence_e'] = {
				'Fortify Intelligence Potion (Excellent)',
				'Drastically enhances magical abilities and spell penetration.',
				'Effects: Fortify Intelligence +25 pts for 150 sec',
				'Alchemy Ingredients: Nightshade, Snowberries, Grand Soul Gem,', 
				'Moonstone, Diamond Dust',
				'Notes: Advanced magic enhancement potion.'
			},

			['p_fortify_intelligence_q'] = {
				'Fortify Intelligence Potion (Superior)',
				'Maximum boost to magical abilities and spell power.',
				'Effects: Fortify Intelligence +30 pts for 180 sec',
				'Alchemy Ingredients: Nightshade, Snowberries, Grand Soul Gem,', 
				'Diamond Dust, Ruby',
				'Notes: Expert-level magic enhancement.'
			},

			['p_fortify_luck_c'] = {
				'Fortify Luck Potion (Common)',
				'Moderately enhances luck and favorable outcomes.',
				'Effects: Fortify Luck +15 pts for 90 sec',
				'Alchemy Ingredients: Four Leaf Clover, Gold Dust, Diamond Shards',
				'Notes: Basic luck enhancement potion.'
			},

			['p_fortify_luck_b'] = {
				'Fortify Luck Potion (Better)',
				'Significantly boosts luck in games and quests.',
				'Effects: Fortify Luck +20 pts for 120 sec',
				'Alchemy Ingredients: Four Leaf Clover, Gold Dust, Diamond Shards,', 
				'Ruby',
				'Notes: Improved luck enhancement.'
			},

			['p_fortify_luck_q'] = {
				'Fortify Luck Potion (Superior)',
				'Drastically increases luck and favorable chances.',
				'Effects: Fortify Luck +25 pts for 150 sec',
				'Alchemy Ingredients: Four Leaf Clover, Gold Dust, Diamond Shards,', 
				'Ruby, Moonstone',
				'Notes: Expert-level luck enhancement.'
			},

			['p_fortify_luck_e'] = {
				'Fortify Luck Potion (Excellent)',
				'Maximum boost to luck and fortune.',
				'Effects: Fortify Luck +30 pts for 180 sec',
				'Alchemy Ingredients: Four Leaf Clover, Gold Dust, Diamond Shards,', 
				'Ruby, Moonstone, Dragon Heart',
				'Notes: Peak luck enhancement potion.'
			},

			['p_fortify_magicka_c'] = {
				'Fortify Magicka Potion (Common)',
				'Moderately increases maximum magicka.',
				'Effects: Fortify Magicka +20 pts for 90 sec',
				'Alchemy Ingredients: Soul Gems, Void Salts, Ebony Dust',
				'Notes: Basic magicka enhancement.'
			},

			['p_fortify_magicka_e'] = {
				'Fortify Magicka Potion (Excellent)',
				'Significantly boosts maximum magicka reserves.',
				'Effects: Fortify Magicka +30 pts for 150 sec',
				'Alchemy Ingredients: Soul Gems, Void Salts, Ebony Dust, Ruby',
				'Notes: Advanced magicka enhancement.'
			},

			['p_fortify_magicka_q'] = {
				'Fortify Magicka Potion (Superior)',
				'Maximum boost to magicka capacity.',
				'Effects: Fortify Magicka +35 pts for 180 sec',
				'Alchemy Ingredients: Soul Gems, Void Salts, Ebony Dust, Ruby,', 
				'Diamond Dust',
				'Notes: Expert-level magicka enhancement.'
			},

			['p_fortify_magicka_b'] = {
				'Fortify Magicka Potion (Better)',
				'Enhanced increase to maximum magicka.',
				'Effects: Fortify Magicka +25 pts for 120 sec',
				'Alchemy Ingredients: Soul Gems, Void Salts, Ebony Dust, Moonstone',
				'Notes: Improved magicka enhancement.'
			},

			['p_fortify_personality_c'] = {
				'Fortify Personality Potion (Common)',
				'Moderately enhances charisma and social skills.',
				'Effects: Fortify Personality +15 pts for 90 sec',
				'Alchemy Ingredients: Butterfly Wings, Honeycomb, Lavender',
				'Notes: Basic social enhancement potion.'
			},

			['p_fortify_personality_e'] = {
				'Fortify Personality Potion (Excellent)',
				'Significantly boosts charisma and persuasion abilities.',
				'Effects: Fortify Personality +25 pts for 150 sec',
				'Alchemy Ingredients: Butterfly Wings, Honeycomb, Lavender,', 
				'Diamond Dust',
				'Notes: Advanced social enhancement.'
			},

			['p_fortify_personality_b'] = {
				'Fortify Personality Potion (Better)',
				'Enhanced increase to charisma and social prowess.',
				'Effects: Fortify Personality +20 pts for 120 sec',
				'Alchemy Ingredients: Butterfly Wings, Honeycomb, Lavender,', 
				'Moonstone',
				'Notes: Improved social enhancement.'
			},

			['p_fortify_personality_q'] = {
				'Fortify Personality Potion (Superior)',
				'Maximum boost to charisma and persuasion.',
				'Effects: Fortify Personality +30 pts for 180 sec',
				'Alchemy Ingredients: Butterfly Wings, Honeycomb, Lavender,', 
				'Diamond Dust, Ruby',
				'Notes: Expert-level social enhancement.'
			},

			['p_fortify_speed_c'] = {
				'Fortify Speed Potion (Common)',
				'Moderately increases movement speed.',
				'Effects: Fortify Speed +15% for 90 sec',
				'Alchemy Ingredients: Sprint Extract, Swiftness Root, Hare Meat',
				'Notes: Basic speed enhancement.'
			},

			['p_fortify_speed_b'] = {
				'Fortify Speed Potion (Better)',
				'Significantly boosts movement speed.',
				'Effects: Fortify Speed +20% for 120 sec',
				'Alchemy Ingredients: Sprint Extract, Swiftness Root, Hare Meat,', 
				'Diamond Dust',
				'Notes: Improved speed enhancement.'
			},

			['p_fortify_speed_q'] = {
				'Fortify Speed Potion (Superior)',
				'Drastically increases movement speed.',
				'Effects: Fortify Speed +25% for 150 sec',
				'Alchemy Ingredients: Sprint Extract, Swiftness Root, Hare Meat,', 
				'Diamond Dust, Ruby',
				'Notes: Expert-level speed enhancement.'
			},

			['p_fortify_speed_e'] = {
				'Fortify Speed Potion (Excellent)',
				'Maximum boost to movement speed.',
				'Effects: Fortify Speed +30% for 180 sec',
				'Alchemy Ingredients: Sprint Extract, Swiftness Root, Hare Meat,', 
				'Diamond Dust, Ruby, Moonstone',
				'Notes: Peak speed enhancement potion.'
			},

			['p_fortify_strength_c'] = {
				'Fortify Strength Potion (Common)',
				'Moderately enhances physical strength.',
				'Effects: Fortify Strength +15 pts for 90 sec',
				'Alchemy Ingredients: Bear Claws, Mammoth Tusk, Stalhrim',
				'Notes: Basic strength enhancement.'
			},

			['p_fortify_strength_b'] = {
				'Fortify Strength Potion (Better)',
				'Significantly boosts physical strength.',
				'Effects: Fortify Strength +20 pts for 120 sec',
				'Alchemy Ingredients: Bear Claws, Mammoth Tusk, Stalhrim,', 
				'Diamond Dust',
				'Notes: Improved strength enhancement.'
			},

			['p_fortify_strength_e'] = {
				'Fortify Strength Potion (Excellent)',
				'Drastically increases physical strength.',
				'Effects: Fortify Strength +25 pts for 150 sec',
				'Alchemy Ingredients: Bear Claws, Mammoth Tusk, Stalhrim,', 
				'Diamond Dust, Ruby',
				'Notes: Advanced strength enhancement.'
			},

			['p_fortify_strength_q'] = {
				'Fortify Strength Potion (Superior)',
				'Maximum boost to physical strength, increasing melee damage', 
				'significantly.',
				'Effects: Fortify Strength +30 pts for 180 sec',
				'Alchemy Ingredients: Bear Claws, Mammoth Tusk, Stalhrim,', 
				'Diamond Dust, Ruby, Dragon Bone',
				'Notes: Expert-level strength enhancement for warriors.'
			},

			['p_fortify_willpower_c'] = {
				'Fortify Willpower Potion (Common)',
				'Moderately enhances magical resistance and mental fortitude.',
				'Effects: Fortify Willpower +15 pts for 90 sec',
				'Alchemy Ingredients: Dragon Heart, Ebony Dust, Void Salts',
				'Notes: Basic mental enhancement potion.'
			},

			['p_fortify_willpower_b'] = {
				'Fortify Willpower Potion (Better)',
				'Significantly boosts magical resistance and mental defenses.',
				'Effects: Fortify Willpower +20 pts for 120 sec',
				'Alchemy Ingredients: Dragon Heart, Ebony Dust, Void Salts,', 
				'Moonstone',
				'Notes: Improved mental enhancement.'
			},

			['p_fortify_willpower_q'] = {
				'Fortify Willpower Potion (Superior)',
				'Drastically increases magical resistance and mental fortitude.',
				'Effects: Fortify Willpower +25 pts for 150 sec',
				'Alchemy Ingredients: Dragon Heart, Ebony Dust, Void Salts,', 
				'Diamond Dust, Ruby',
				'Notes: Expert-level mental enhancement.'
			},

			['p_fortify_willpower_e'] = {
				'Fortify Willpower Potion (Excellent)',
				'Maximum boost to magical resistance and mental defenses.',
				'Effects: Fortify Willpower +30 pts for 180 sec',
				'Alchemy Ingredients: Dragon Heart, Ebony Dust, Void Salts,', 
				'Diamond Dust, Ruby, Moonstone',
				'Notes: Peak mental enhancement potion.'
			},

			['p_frost_shield_c'] = {
				'Frost Shield Potion (Common)',
				'Provides moderate protection against frost damage.',
				'Effects: Absorb Frost Damage +25 pts for 90 sec',
				'Alchemy Ingredients: Ice Wraith Dust, Snowberries, Frost Salts',
				'Notes: Basic defense against cold.'
			},

			['p_frost_shield_b'] = {
				'Frost Shield Potion (Better)',
				'Enhanced protection against frost-based attacks.',
				'Effects: Absorb Frost Damage +35 pts for 120 sec',
				'Alchemy Ingredients: Ice Wraith Dust, Snowberries, Frost Salts,', 
				'Diamond Dust',
				'Notes: Improved cold resistance.'
			},

			['p_frost_shield_e'] = {
				'Frost Shield Potion (Excellent)',
				'Strong protection against frost damage.',
				'Effects: Absorb Frost Damage +45 pts for 150 sec',
				'Alchemy Ingredients: Ice Wraith Dust, Snowberries, Frost Salts,', 
				'Diamond Dust, Ruby',
				'Notes: Advanced cold resistance potion.'
			},

			['p_frost_shield_q'] = {
				'Frost Shield Potion (Superior)',
				'Near-complete protection against frost attacks.',
				'Effects: Absorb Frost Damage +55 pts for 180 sec',
				'Alchemy Ingredients: Ice Wraith Dust, Snowberries, Frost Salts,', 
				'Diamond Dust, Ruby, Moonstone',
				'Notes: Expert-level cold resistance.'
			},

			['p_invisibility_c'] = {
				'Invisibility Potion (Common)',
				'Makes the drinker partially invisible for a short duration.',
				'Effects: Invisibility for 45 sec',
				'Alchemy Ingredients: Nightshade, Shadowscale, Void Salts',
				'Notes: Basic stealth potion.'
			},

			['p_invisibility_b'] = {
				'Invisibility Potion (Better)',
				'Provides longer invisibility effect.',
				'Effects: Invisibility for 60 sec',
				'Alchemy Ingredients: Nightshade, Shadowscale, Void Salts,', 
				'Moonstone',
				'Notes: Improved stealth potion.'
			},

			['p_invisibility_q'] = {
				'Invisibility Potion (Superior)',
				'Extended invisibility effect for stealth missions.',
				'Effects: Invisibility for 90 sec',
				'Alchemy Ingredients: Nightshade, Shadowscale, Void Salts, Moonstone,', 
				'Diamond Dust',
				'Notes: Expert-level stealth potion.'
			},

			['p_invisibility_e'] = {
				'Invisibility Potion (Excellent)',
				'Maximum duration invisibility effect.',
				'Effects: Invisibility for 120 sec',
				'Alchemy Ingredients: Nightshade, Shadowscale, Void Salts, Moonstone,', 
				'Diamond Dust, Ruby',
				'Notes: Peak stealth enhancement.'
			},

			['p_jump_c'] = {
				'Jump Potion (Common)',
				'Increases jump height temporarily.',
				'Effects: Increase Jump Height +25% for 90 sec',
				'Alchemy Ingredients: Deer Tongue, Swiftness Root, Hare Meat',
				'Notes: Basic jumping enhancement.'
			},

			['p_jump_b'] = {
				'Jump Potion (Better)',
				'Significantly boosts jump height.',
				'Effects: Increase Jump Height +50% for 120 sec',
				'Alchemy Ingredients: Deer Tongue, Swiftness Root, Hare Meat,', 
				'Diamond Dust',
				'Notes: Improved jumping potion.'
			},

			['p_jump_e'] = {
				'Jump Potion (Excellent)',
				'Drastically increases jump height.',
				'Effects: Increase Jump Height +75% for 150 sec',
				'Alchemy Ingredients: Deer Tongue, Swiftness Root, Hare Meat,', 
				'Diamond Dust, Ruby',
				'Notes: Advanced jumping enhancement.'
			},

			['p_jump_s'] = {
				'Jump Potion (Weak)',
				'Minor increase to jump height.',
				'Effects: Increase Jump Height +15% for 60 sec',
				'Alchemy Ingredients: Deer Tongue, Swiftness Root',
				'Notes: Basic jump boost.'
			},

			['p_jump_q'] = {
				'Jump Potion (Superior)',
				'Maximum boost to jump height.',
				'Effects: Increase Jump Height +100% for 180 sec',
				'Alchemy Ingredients: Deer Tongue, Swiftness Root, Hare Meat,', 
				'Diamond Dust, Ruby, Moonstone',
				'Notes: Expert-level jumping potion.'
			},

			['p_levitation_c'] = {
				'Levitation Potion (Common)',
				'Enables basic levitation for short duration.',
				'Effects: Levitation for 60 sec',
				'Alchemy Ingredients: Feather, Moonstone, Cloud Dust',
				'Notes: Basic flight potion.'
			},

			['p_levitation_b'] = {
				'Levitation Potion (Better)',
				'Extended levitation effect.',
				'Effects: Levitation for 90 sec',
				'Alchemy Ingredients: Feather, Moonstone, Cloud Dust, Diamond Dust',
				'Notes: Improved flight potion.'
			},

			['P_Levitation_Q'] = {
				'Levitation Potion (Superior)',
				'Long-lasting levitation effect.',
				'Effects: Levitation for 150 sec',
				'Alchemy Ingredients: Feather, Moonstone, Cloud Dust, Diamond Dust,', 
				'Ruby',
				'Notes: Expert-level flight potion.'
			},

			['p_levitation_e'] = {
				'Levitation Potion (Excellent)',
				'Maximum duration levitation effect.',
				'Effects: Levitation for 180 sec',
				'Alchemy Ingredients: Feather, Moonstone, Cloud Dust, Diamond Dust,', 
				'Ruby, Moonstone',
				'Notes: Peak flight enhancement.'
			},

			['p_light_c'] = {
				'Light Potion (Common)',
				'Creates a small light source.',
				'Effects: Light Radius +5 ft for 90 sec',
				'Alchemy Ingredients: Glow Dust, Moonstone, Fire Salts',
				'Notes: Basic illumination.'
			},

			['p_light_b'] = {
				'Light Potion (Better)',
				'Enhanced light source.',
				'Effects: Light Radius +10 ft for 120 sec',
				'Alchemy Ingredients: Glow Dust, Moonstone, Fire Salts, Diamond Dust',
				'Notes: Improved illumination.'
			},

			['p_light_e'] = {
				'Light Potion (Excellent)',
				'Strong light source for dark environments.',
				'Effects: Light Radius +15 ft for 150 sec',
				'Alchemy Ingredients: Glow Dust, Moonstone, Fire Salts, Diamond Dust,', 
				'Ruby',
				'Notes: Advanced illumination potion.'
			},

			['p_light_q'] = {
				'Light Potion (Superior)',
				'Intense light source for extended periods.',
				'Effects: Light Radius +20 ft for 180 sec',
				'Alchemy Ingredients: Glow Dust, Moonstone, Fire Salts, Diamond Dust,', 
				'Ruby, Moonstone',
				'Notes: Expert-level illumination.'
			},

			['p_lightning_shield_c'] = {
				'Lightning Shield Potion (Common)',
				'Generates a basic electrical barrier.',
				'Effects: Absorb Shock Damage +25 pts for 90 sec',
				'Alchemy Ingredients: Shock Salts, Storm Atronach Horn, Lightning', 
				'Bug Parts',
				'Notes: Basic electrical defense.'
			},

			['p_lightning_shield_e'] = {
				'Lightning Shield Potion (Excellent)',
				'Strong electrical barrier with damage reflection.',
				'Effects: Absorb Shock Damage +45 pts for 150 sec',
				'Alchemy Ingredients: Shock Salts, Storm Atronach Horn, Lightning', 
				'Bug Parts, Diamond Dust',
				'Notes: Advanced electrical defense.'
			},

			['p_lightning_shield_q'] = {
				'Lightning Shield Potion (Superior)',
				'Powerful electrical barrier with damage reflection.',
				'Effects: Absorb Shock Damage +55 pts for 180 sec',
				'Alchemy Ingredients: Shock Salts, Storm Atronach Horn, Lightning', 
				'Bug Parts, Diamond Dust, Ruby',
				'Notes: Expert-level electrical defense.'
			},

			['p_lightning_shield_b'] = {
				'Lightning Shield Potion (Better)',
				'Enhanced electrical barrier.',
				'Effects: Absorb Shock Damage +35 pts for 120 sec',
				'Alchemy Ingredients: Shock Salts, Storm Atronach Horn, Lightning', 
				'Bug Parts, Moonstone',
				'Notes: Improved electrical defense.'
			},

			['p_night-eye_c'] = {
				'Night-Eye Potion (Common)',
				'Basic night vision enhancement.',
				'Effects: Night Vision +25% for 90 sec',
				"Alchemy Ingredients: Cat's Eye, Night Eye Flower, Moonstone Dust",
				'Notes: Basic low-light vision.'
			},

			['p_night-eye_b'] = {
				'Night-Eye Potion (Better)',
				'Enhanced night vision.',
				'Effects: Night Vision +50% for 120 sec',
				"Alchemy Ingredients: Cat's Eye, Night Eye Flower, Moonstone Dust,", 
				"Diamond Dust",
				'Notes: Improved low-light vision.'
			},

			['p_night-eye_q'] = {
				'Night-Eye Potion (Superior)',
				'Powerful night vision enhancement.',
				'Effects: Night Vision +75% for 150 sec',
				"Alchemy Ingredients: Cat's Eye, Night Eye Flower, Moonstone Dust,", 
				"Diamond Dust, Ruby",
				'Notes: Expert-level low-light vision.'
			},

			['p_night-eye_e'] = {
				'Night-Eye Potion (Excellent)',
				'Maximum night vision enhancement.',
				'Effects: Night Vision +100% for 180 sec',
				"Alchemy Ingredients: Cat's Eye, Night Eye Flower, Moonstone Dust,", 
				"Diamond Dust, Ruby, Moonstone",
				'Notes: Peak low-light vision potion.'
			},

			['p_paralyze_c'] = {
				'Paralyze Potion (Common)',
				'Temporarily immobilizes targets on contact.',
				'Effects: Paralyze Targets for 15 sec on Touch',
				'Alchemy Ingredients: Spider Venom, Ataxia Root, Paralysis Mushroom',
				'Notes: Basic disabling potion.'
			},

			['p_paralyze_b'] = {
				'Paralyze Potion (Better)',
				'Enhanced immobilization effect on contact.',
				'Effects: Paralyze Targets for 20 sec on Touch',
				'Alchemy Ingredients: Spider Venom, Ataxia Root, Paralysis Mushroom,', 
				'Void Salts',
				'Notes: Improved disabling potion.'
			},

			['p_paralyze_e'] = {
				'Paralyze Potion (Excellent)',
				'Significantly prolonged immobilization effect.',
				'Effects: Paralyze Targets for 25 sec on Touch',
				'Alchemy Ingredients: Spider Venom, Ataxia Root, Paralysis Mushroom,', 
				'Void Salts, Diamond Dust',
				'Notes: Advanced disabling potion.'
			},

			['p_paralyze_q'] = {
				'Paralyze Potion (Superior)',
				'Maximum duration immobilization effect.',
				'Effects: Paralyze Targets for 30 sec on Touch',
				'Alchemy Ingredients: Spider Venom, Ataxia Root, Paralysis Mushroom,', 
				'Void Salts, Diamond Dust, Ruby',
				'Notes: Expert-level disabling potion.'
			},

			['p_reflection_c'] = {
				'Reflection Potion (Common)',
				'Basic spell reflection chance.',
				'Effects: Spell Reflection Chance +20% for 90 sec',
				'Alchemy Ingredients: Diamond Dust, Moonstone, Crystal Marrow',
				'Notes: Basic magical defense.'
			},

			['p_reflection_b'] = {
				'Reflection Potion (Better)',
				'Enhanced spell reflection chance.',
				'Effects: Spell Reflection Chance +30% for 120 sec',
				'Alchemy Ingredients: Diamond Dust, Moonstone, Crystal Marrow,', 
				'Void Salts',
				'Notes: Improved magical defense.'
			},

			['p_reflection_q'] = {
				'Reflection Potion (Superior)',
				'Powerful spell reflection chance.',
				'Effects: Spell Reflection Chance +40% for 150 sec',
				'Alchemy Ingredients: Diamond Dust, Moonstone, Crystal Marrow,', 
				'Void Salts, Ruby',
				'Notes: Expert-level magical defense.'
			},

			['p_reflection_e'] = {
				'Reflection Potion (Excellent)',
				'Maximum spell reflection chance.',
				'Effects: Spell Reflection Chance +50% for 180 sec',
				'Alchemy Ingredients: Diamond Dust, Moonstone, Crystal Marrow,', 
				'Void Salts, Ruby, Moonstone',
				'Notes: Peak magical defense potion.'
			},

			['p_disease_resistance_c'] = {
				'Disease Resistance Potion (Common)',
				'Basic protection against diseases.',
				'Effects: Disease Resistance +20% for 90 sec',
				'Alchemy Ingredients: Snowberries, Crimson Nirnroot, Bear Claws',
				'Notes: Basic disease prevention.'
			},

			['p_disease_resistance_s'] = {
				'Disease Resistance Potion (Weak)',
				'Minor protection against diseases.',
				'Effects: Disease Resistance +10% for 60 sec',
				'Alchemy Ingredients: Snowberries, Crimson Nirnroot',
				'Notes: Basic disease prevention.'
			},

			['p_disease_resistance_b'] = {
				'Disease Resistance Potion (Better)',
				'Enhanced disease protection.',
				'Effects: Disease Resistance +30% for 120 sec',
				'Alchemy Ingredients: Snowberries, Crimson Nirnroot, Bear Claws,', 
				'Diamond Dust',
				'Notes: Improved disease prevention.'
			},

			['p_disease_resistance_q'] = {
				'Disease Resistance Potion (Superior)',
				'Powerful disease protection.',
				'Effects: Disease Resistance +40% for 150 sec',
				'Alchemy Ingredients: Snowberries, Crimson Nirnroot, Bear Claws,', 
				'Diamond Dust, Ruby',
				'Notes: Expert-level disease prevention.'
			},

			['p_disease_resistance_e'] = {
				'Disease Resistance Potion (Excellent)',
				'Maximum protection against diseases and plagues.',
				'Effects: Disease Resistance +50% for 180 sec',
				'Alchemy Ingredients: Snowberries, Crimson Nirnroot, Bear Claws,', 
				'Diamond Dust, Ruby, Moonstone',
				'Notes: Peak disease prevention potion.'
			},

			['p_fire_resistance_c'] = {
				'Fire Resistance Potion (Common)',
				'Basic protection against fire damage.',
				'Effects: Fire Resistance +20% for 90 sec',
				'Alchemy Ingredients: Fire Salts, Dragon Heart, Volcanic Ash',
				'Notes: Entry-level fire resistance.'
			},

			['p_fire_resistance_b'] = {
				'Fire Resistance Potion (Better)',
				'Enhanced protection against fire-based attacks.',
				'Effects: Fire Resistance +30% for 120 sec',
				'Alchemy Ingredients: Fire Salts, Dragon Heart, Volcanic Ash,', 
				'Diamond Dust',
				'Notes: Improved fire resistance.'
			},

			['p_fire_resistance_q'] = {
				'Fire Resistance Potion (Superior)',
				'Powerful protection against fire damage.',
				'Effects: Fire Resistance +40% for 150 sec',
				'Alchemy Ingredients: Fire Salts, Dragon Heart, Volcanic Ash,', 
				'Diamond Dust, Ruby',
				'Notes: Expert-level fire resistance.'
			},

			['p_fire_resistance_e'] = {
				'Fire Resistance Potion (Excellent)',
				'Near-complete protection against fire attacks.',
				'Effects: Fire Resistance +50% for 180 sec',
				'Alchemy Ingredients: Fire Salts, Dragon Heart, Volcanic Ash,', 
				'Diamond Dust, Ruby, Moonstone',
				'Notes: Peak fire resistance potion.'
			},

			['p_frost_resistance_c'] = {
				'Frost Resistance Potion (Common)',
				'Basic protection against frost damage.',
				'Effects: Frost Resistance +20% for 90 sec',
				'Alchemy Ingredients: Ice Wraith Dust, Snowberries, Frost Salts',
				'Notes: Entry-level cold resistance.'
			},

			['p_frost_resistance_b'] = {
				'Frost Resistance Potion (Better)',
				'Enhanced protection against frost-based attacks.',
				'Effects: Frost Resistance +30% for 120 sec',
				'Alchemy Ingredients: Ice Wraith Dust, Snowberries, Frost Salts,', 
				'Diamond Dust',
				'Notes: Improved cold resistance.'
			},

			['p_frost_resistance_e'] = {
				'Frost Resistance Potion (Excellent)',
				'Powerful protection against frost damage.',
				'Effects: Frost Resistance +40% for 150 sec',
				'Alchemy Ingredients: Ice Wraith Dust, Snowberries, Frost Salts,', 
				'Diamond Dust, Ruby',
				'Notes: Advanced cold resistance potion.'
			},

			['p_frost_resistance_q'] = {
				'Frost Resistance Potion (Superior)',
				'Near-complete protection against frost attacks.',
				'Effects: Frost Resistance +50% for 180 sec',
				'Alchemy Ingredients: Ice Wraith Dust, Snowberries, Frost Salts,', 
				'Diamond Dust, Ruby, Moonstone',
				'Notes: Expert-level cold resistance.'
			},

			['p_magicka_resistance_c'] = {
				'Magicka Resistance Potion (Common)',
				'Basic protection against magical damage.',
				'Effects: Magicka Resistance +20% for 90 sec',
				'Alchemy Ingredients: Ebony Dust, Void Salts, Soul Gem Shards',
				'Notes: Entry-level magical defense.'
			},

			['p_magicka_resistance_b'] = {
				'Magicka Resistance Potion (Better)',
				'Enhanced protection against magic.',
				'Effects: Magicka Resistance +30% for 120 sec',
				'Alchemy Ingredients: Ebony Dust, Void Salts, Soul Gem Shards,', 
				'Diamond Dust',
				'Notes: Improved magical defense.'
			},

			['p_magicka_resistance_q'] = {
				'Magicka Resistance Potion (Superior)',
				'Powerful protection against magical attacks.',
				'Effects: Magicka Resistance +40% for 150 sec',
				'Alchemy Ingredients: Ebony Dust, Void Salts, Soul Gem Shards,', 
				'Diamond Dust, Ruby',
				'Notes: Expert-level magical defense.'
			},

			['p_magicka_resistance_e'] = {
				'Magicka Resistance Potion (Excellent)',
				'Near-complete protection against magic.',
				'Effects: Magicka Resistance +50% for 180 sec',
				'Alchemy Ingredients: Ebony Dust, Void Salts, Soul Gem Shards,', 
				'Diamond Dust, Ruby, Moonstone',
				'Notes: Peak magical defense potion.'
			},

			['p_poison_resistance_c'] = {
				'Poison Resistance Potion (Common)',
				'Basic protection against poison effects.',
				'Effects: Poison Resistance +20% for 90 sec',
				'Alchemy Ingredients: Poison Ivy, Viper Tongue, Deathbell',
				'Notes: Entry-level poison defense.'
			},

			['p_poison_resistance_b'] = {
				'Poison Resistance Potion (Better)',
				'Enhanced protection against poisons.',
				'Effects: Poison Resistance +30% for 120 sec',
				'Alchemy Ingredients: Poison Ivy, Viper Tongue, Deathbell,', 
				'Diamond Dust',
				'Notes: Improved poison resistance.'
			},

			['p_poison_resistance_e'] = {
				'Poison Resistance Potion (Excellent)',
				'Powerful protection against poison damage.',
				'Effects: Poison Resistance +40% for 150 sec',
				'Alchemy Ingredients: Poison Ivy, Viper Tongue, Deathbell,', 
				'Diamond Dust, Ruby',
				'Notes: Advanced poison defense potion.'
			},

			['p_poison_resistance_q'] = {
				'Poison Resistance Potion (Superior)',
				'Near-complete protection against poisons.',
				'Effects: Poison Resistance +50% for 180 sec',
				'Alchemy Ingredients: Poison Ivy, Viper Tongue, Deathbell,', 
				'Diamond Dust, Ruby, Moonstone',
				'Notes: Expert-level poison resistance.'
			},

			['p_shock_resistance_c'] = {
				'Shock Resistance Potion (Common)',
				'Basic protection against electrical damage.',
				'Effects: Shock Resistance +20% for 90 sec',
				'Alchemy Ingredients: Shock Salts, Storm Atronach Horn, Lightning', 
				'Bug Parts',
				'Notes: Entry-level electrical defense.'
			},

			['p_shock_resistance_b'] = {
				'Shock Resistance Potion (Better)',
				'Enhanced protection against electrical attacks.',
				'Effects: Shock Resistance +30% for 120 sec',
				'Alchemy Ingredients: Shock Salts, Storm Atronach Horn, Lightning', 
				'Bug Parts, Diamond Dust',
				'Notes: Improved electrical defense.'
			},

			['p_shock_resistance_e'] = {
				'Shock Resistance Potion (Excellent)',
				'Powerful protection against electrical damage.',
				'Effects: Shock Resistance +40% for 150 sec',
				'Alchemy Ingredients: Shock Salts, Storm Atronach Horn, Lightning', 
				'Bug Parts, Diamond Dust, Ruby',
				'Notes: Advanced electrical defense potion.'
			},

			['p_shock_resistance_q'] = {
				'Shock Resistance Potion (Superior)',
				'Near-complete protection against electrical attacks.',
				'Effects: Shock Resistance +50% for 180 sec',
				'Alchemy Ingredients: Shock Salts, Storm Atronach Horn, Lightning Bug', 
				'Parts, Diamond Dust, Ruby, Moonstone',
				'Notes: Expert-level electrical resistance.'
			},

			['p_restore_agility_c'] = {
				'Restore Agility Potion (Common)',
				'Restores agility points and improves reflexes.',
				'Effects: Restore Agility +15 pts for 90 sec',
				'Alchemy Ingredients: Deer Tongue, Swiftness Root, Hare Meat',
				'Notes: Basic agility restoration.'
			},

			['p_restore_agility_b'] = {
				'Restore Agility Potion (Better)',
				'Enhanced agility restoration.',
				'Effects: Restore Agility +20 pts for 120 sec',
				'Alchemy Ingredients: Deer Tongue, Swiftness Root, Hare Meat, Diamond Dust',
				'Notes: Improved agility recovery.'
			},

			['p_restore_agility_e'] = {
				'Restore Agility Potion (Excellent)',
				'Significantly restores agility points.',
				'Effects: Restore Agility +25 pts for 150 sec',
				'Alchemy Ingredients: Deer Tongue, Swiftness Root, Hare Meat,', 
				'Diamond Dust, Ruby',
				'Notes: Advanced agility restoration.'
			},

			['p_restore_agility_q'] = {
				'Restore Agility Potion (Superior)',
				'Maximum agility restoration.',
				'Effects: Restore Agility +30 pts for 180 sec',
				'Alchemy Ingredients: Deer Tongue, Swiftness Root, Hare Meat,', 
				'Diamond Dust, Ruby, Moonstone',
				'Notes: Expert-level agility recovery.'
			},

			['p_restore_endurance_c'] = {
				'Restore Endurance Potion (Common)',
				'Restores endurance points.',
				'Effects: Restore Endurance +15 pts for 90 sec',
				'Alchemy Ingredients: Bear Claws, Wheat, Cabbage',
				'Notes: Basic stamina recovery.'
			},

			['p_restore_endurance_b'] = {
				'Restore Endurance Potion (Better)',
				'Enhanced endurance restoration.',
				'Effects: Restore Endurance +20 pts for 120 sec',
				'Alchemy Ingredients: Bear Claws, Wheat, Cabbage, Mammoth Tusk',
				'Notes: Improved stamina recovery.'
			},

			['p_restore_endurance_e'] = {
				'Restore Endurance Potion (Excellent)',
				'Significantly restores endurance.',
				'Effects: Restore Endurance +25 pts for 150 sec',
				'Alchemy Ingredients: Bear Claws, Wheat, Cabbage, Mammoth Tusk,', 
				'Stalhrim',
				'Notes: Advanced stamina recovery.'
			},

			['p_restore_endurance_q'] = {
				'Restore Endurance Potion (Superior)',
				'Maximum endurance restoration.',
				'Effects: Restore Endurance +30 pts for 180 sec',
				'Alchemy Ingredients: Bear Claws, Wheat, Cabbage, Mammoth Tusk,', 
				'Stalhrim, Diamond Dust',
				'Notes: Expert-level stamina recovery.'
			},

			['p_restore_health_c'] = {
				'Restore Health Potion (Common)',
				'Restores health points.',
				'Effects: Restore Health +20 pts for 90 sec',
				'Alchemy Ingredients: Heart of Aelter, Crimson Nirnroot, Bear Heart',
				'Notes: Basic health restoration.'
			},

			['p_restore_health_b'] = {
				'Restore Health Potion (Better)',
				'Enhanced health restoration.',
				'Effects: Restore Health +25 pts for 120 sec',
				'Alchemy Ingredients: Heart of Aelter, Crimson Nirnroot, Bear Heart,', 
				'Diamond Dust',
				'Notes: Improved health recovery.'
			},

			['p_restore_health_e'] = {
				'Restore Health Potion (Excellent)',
				'Significantly restores health.',
				'Effects: Restore Health +30 pts for 150 sec',
				'Alchemy Ingredients: Heart of Aelter, Crimson Nirnroot, Bear Heart,', 
				'Diamond Dust, Ruby',
				'Notes: Advanced health recovery.'
			},

			['p_restore_health_q'] = {
				'Restore Health Potion (Superior)',
				'Maximum health restoration.',
				'Effects: Restore Health +35 pts for 180 sec',
				'Alchemy Ingredients: Heart of Aelter, Crimson Nirnroot, Bear Heart,', 
				'Diamond Dust, Ruby, Moonstone',
				'Notes: Expert-level health recovery.'
			},

			['p_restore_intelligence_c'] = {
				'Restore Intelligence Potion (Common)',
				'Restores intelligence points and enhances magical abilities.',
				'Effects: Restore Intelligence +15 pts for 90 sec',
				'Alchemy Ingredients: Nightshade, Snowberries, Grand Soul Gem',
				'Notes: Basic intelligence recovery.'
			},

			['p_restore_intelligence_b'] = {
				'Restore Intelligence Potion (Better)',
				'Enhanced intelligence restoration.',
				'Effects: Restore Intelligence +20 pts for 120 sec',
				'Alchemy Ingredients: Nightshade, Snowberries, Grand Soul Gem,', 
				'Moonstone',
				'Notes: Improved magical ability recovery.'
			},

			['p_restore_intelligence_e'] = {
				'Restore Intelligence Potion (Excellent)',
				'Significantly restores intelligence.',
				'Effects: Restore Intelligence +25 pts for 150 sec',
				'Alchemy Ingredients: Nightshade, Snowberries, Grand Soul Gem,', 
				'Moonstone, Diamond Dust',
				'Notes: Advanced magical enhancement.'
			},

			['p_restore_intelligence_q'] = {
				'Restore Intelligence Potion (Superior)',
				'Maximum intelligence restoration.',
				'Effects: Restore Intelligence +30 pts for 180 sec',
				'Alchemy Ingredients: Nightshade, Snowberries, Grand Soul Gem,', 
				'Moonstone, Diamond Dust, Ruby',
				'Notes: Expert-level magical enhancement.'
			},

			['p_restore_luck_c'] = {
				'Restore Luck Potion (Common)',
				'Restores luck points and improves chances.',
				'Effects: Restore Luck +15 pts for 90 sec',
				'Alchemy Ingredients: Four Leaf Clover, Gold Dust, Diamond Shards',
				'Notes: Basic luck recovery.'
			},

			['p_restore_luck_b'] = {
				'Restore Luck Potion (Better)',
				'Enhanced luck restoration.',
				'Effects: Restore Luck +20 pts for 120 sec',
				'Alchemy Ingredients: Four Leaf Clover, Gold Dust, Diamond Shards,', 
				'Ruby',
				'Notes: Improved fortune enhancement.'
			},

			['p_restore_luck_e'] = {
				'Restore Luck Potion (Excellent)',
				'Significantly restores luck.',
				'Effects: Restore Luck +25 pts for 150 sec',
				'Alchemy Ingredients: Four Leaf Clover, Gold Dust, Diamond Shards,', 
				'Ruby, Moonstone',
				'Notes: Advanced luck recovery.'
			},

			['p_restore_luck_q'] = {
				'Restore Luck Potion (Superior)',
				'Maximum luck restoration.',
				'Effects: Restore Luck +30 pts for 180 sec',
				'Alchemy Ingredients: Four Leaf Clover, Gold Dust, Diamond Shards,', 
				'Ruby, Moonstone, Dragon Heart',
				'Notes: Expert-level fortune enhancement.'
			},

			['p_restore_personality_c'] = {
				'Restore Personality Potion (Common)',
				'Restores personality points and enhances social skills.',
				'Effects: Restore Personality +15 pts for 90 sec',
				'Alchemy Ingredients: Butterfly Wings, Honeycomb, Lavender',
				'Notes: Basic social recovery.'
			},

			['p_restore_personality_b'] = {
				'Restore Personality Potion (Better)',
				'Enhanced personality restoration.',
				'Effects: Restore Personality +20 pts for 120 sec',
				'Alchemy Ingredients: Butterfly Wings, Honeycomb, Lavender,', 
				'Diamond Dust',
				'Notes: Improved social enhancement.'
			},

			['p_restore_personality_e'] = {
				'Restore Personality Potion (Excellent)',
				'Significantly restores personality.',
				'Effects: Restore Personality +25 pts for 150 sec',
				'Alchemy Ingredients: Butterfly Wings, Honeycomb, Lavender,', 
				'Diamond Dust, Ruby',
				'Notes: Advanced social recovery.'
			},

			['p_restore_personality_q'] = {
				'Restore Personality Potion (Superior)',
				'Maximum personality restoration.',
				'Effects: Restore Personality +30 pts for 180 sec',
				'Alchemy Ingredients: Butterfly Wings, Honeycomb, Lavender,', 
				'Diamond Dust, Ruby, Moonstone',
				'Notes: Expert-level social enhancement.'
			},

			['p_restore_speed_c'] = {
				'Restore Speed Potion (Common)',
				'Restores speed points and improves movement.',
				'Effects: Restore Speed +15% for 90 sec',
				'Alchemy Ingredients: Sprint Extract, Swiftness Root, Hare Meat',
				'Notes: Basic speed recovery.'
			},

			['p_restore_speed_b'] = {
				'Restore Speed Potion (Better)',
				'Enhanced speed restoration.',
				'Effects: Restore Speed +20% for 120 sec',
				'Alchemy Ingredients: Sprint Extract, Swiftness Root, Hare Meat,', 
				'Diamond Dust',
				'Notes: Improved movement enhancement.'
			},

			['p_restore_speed_e'] = {
				'Restore Speed Potion (Excellent)',
				'Significantly restores speed.',
				'Effects: Restore Speed +25% for 150 sec',
				'Alchemy Ingredients: Sprint Extract, Swiftness Root, Hare Meat,', 
				'Diamond Dust, Ruby',
				'Notes: Advanced movement recovery.'
			},

			['p_restore_speed_q'] = {
				'Restore Speed Potion (Superior)',
				'Maximum speed restoration.',
				'Effects: Restore Speed +30% for 180 sec',
				'Alchemy Ingredients: Sprint Extract, Swiftness Root, Hare Meat,', 
				'Diamond Dust, Ruby, Moonstone',
				'Notes: Expert-level movement enhancement.'
			},

			['p_restore_strength_c'] = {
				'Restore Strength Potion (Common)',
				'Restores strength points and enhances melee damage.',
				'Effects: Restore Strength +15 pts for 90 sec',
				'Alchemy Ingredients: Bear Claws, Mammoth Tusk, Stalhrim',
				'Notes: Basic strength recovery.'
			},

			['p_restore_strength_b'] = {
				'Restore Strength Potion (Better)',
				'Enhanced strength restoration.',
				'Effects: Restore Strength +20 pts for 120 sec',
				'Alchemy Ingredients: Bear Claws, Mammoth Tusk, Stalhrim,', 
				'Diamond Dust',
				'Notes: Improved melee enhancement.'
			},

			['p_restore_strength_e'] = {
				'Restore Strength Potion (Excellent)',
				'Significantly restores strength.',
				'Effects: Restore Strength +25 pts for 150 sec',
				'Alchemy Ingredients: Bear Claws, Mammoth Tusk, Stalhrim, Diamond Dust, Ruby',
				'Notes: Advanced strength recovery.'
			},

			['p_restore_strength_q'] = {
				'Restore Strength Potion (Superior)',
				'Maximum strength restoration.',
				'Effects: Restore Strength +30 pts for 180 sec',
				'Alchemy Ingredients: Bear Claws, Mammoth Tusk, Stalhrim, Diamond Dust, Ruby, Moonstone',
				'Notes: Expert-level melee enhancement.'
			},

			['p_restore_willpower_c'] = {
				'Restore Willpower Potion (Common)',
				'Restores willpower points and enhances magical resistance.',
				'Effects: Restore Willpower +15 pts for 90 sec',
				'Alchemy Ingredients: Dragon Heart, Ebony Dust, Void Salts',
				'Notes: Basic magical resistance recovery.'
			},

			['p_restore_willpower_b'] = {
				'Restore Willpower Potion (Better)',
				'Enhanced willpower restoration.',
				'Effects: Restore Willpower +20 pts for 120 sec',
				'Alchemy Ingredients: Dragon Heart, Ebony Dust, Void Salts, Moonstone',
				'Notes: Improved magical defense.'
			},

			['p_restore_willpower_e'] = {
				'Restore Willpower Potion (Excellent)',
				'Significantly restores willpower.',
				'Effects: Restore Willpower +25 pts for 150 sec',
				'Alchemy Ingredients: Dragon Heart, Ebony Dust, Void Salts, Moonstone, Diamond Dust',
				'Notes: Advanced magical resistance.'
			},

			['p_restore_willpower_q'] = {
				'Restore Willpower Potion (Superior)',
				'Maximum willpower restoration, enhancing magical resistance significantly.',
				'Effects: Restore Willpower +30 pts for 180 sec',
				'Alchemy Ingredients: Dragon Heart, Ebony Dust, Void Salts, Moonstone, Diamond Dust, Ruby',
				'Notes: Expert-level magical defense potion.'
			},

			['p_restore_willpower_e'] = {
				'Restore Willpower Potion (Excellent)',
				'Significantly restores willpower, enhancing mental endurance.',
				'Effects: Restore Willpower +45 pts for 120 sec',
				'Alchemy Ingredients: Dragon Heart, Ebony Dust, Void Salts, Moonstone, Diamond Dust',
				'Notes: Advanced willpower restoration.'
			},

			['p_chameleon_c'] = {
				'Chameleon Potion (Common)',
				'Reduces visibility to enemies, basic invisibility effect.',
				'Effects: Chameleon +20% for 60 sec',
				'Alchemy Ingredients: Chaurus Eggs, Spider Silk, Nightshade',
				'Notes: Basic stealth enhancement.'
			},

			['p_chameleon_b'] = {
				'Chameleon Potion (Better)',
				'Improved invisibility effect.',
				'Effects: Chameleon +30% for 90 sec',
				'Alchemy Ingredients: Chaurus Eggs, Spider Silk, Nightshade, Diamond Dust',
				'Notes: Improved stealth.'
			},

			['p_chameleon_s'] = {
				'Chameleon Potion (Super)',
				'Enhanced stealth with moderate duration.',
				'Effects: Chameleon +35% for 100 sec',
				'Alchemy Ingredients: Chaurus Eggs, Spider Silk, Nightshade, Diamond Dust, Ruby',
				'Notes: Strong stealth effect.'
			},

			['p_chameleon_q'] = {
				'Chameleon Potion (Superior)',
				'Maximum invisibility effect for extended duration.',
				'Effects: Chameleon +45% for 150 sec',
				'Alchemy Ingredients: Chaurus Eggs, Spider Silk, Nightshade, Diamond Dust, Ruby, Moonstone',
				'Notes: Expert-level stealth.'
			},

			['p_chameleon_e'] = {
				'Chameleon Potion (Excellent)',
				'Near-invisible state with long duration.',
				'Effects: Chameleon +40% for 130 sec',
				'Alchemy Ingredients: Chaurus Eggs, Spider Silk, Nightshade, Diamond Dust, Ruby, Void Salts',
				'Notes: Advanced stealth with balance of power and duration.'
			},

			['p_silence_c'] = {
				'Silence Potion (Common)',
				'Prevents casting spells for a short time.',
				'Effects: Silence for 60 sec',
				'Alchemy Ingredients: Frost Salts, Ataxia Root, Spider Venom',
				'Notes: Basic spell inhibition.'
			},

			['p_silence_b'] = {
				'Silence Potion (Better)',
				'Extended spell inhibition.',
				'Effects: Silence for 90 sec',
				'Alchemy Ingredients: Frost Salts, Ataxia Root, Spider Venom, Diamond Dust',
				'Notes: Improved spell inhibition.'
			},

			['p_silence_q'] = {
				'Silence Potion (Superior)',
				'Maximum spell inhibition duration.',
				'Effects: Silence for 150 sec',
				'Alchemy Ingredients: Frost Salts, Ataxia Root, Spider Venom, Diamond Dust, Ruby, Moonstone',
				'Notes: Expert-level spell inhibition.'
			},

			['p_silence_e'] = {
				'Silence Potion (Excellent)',
				'Significantly extended spell inhibition.',
				'Effects: Silence for 120 sec',
				'Alchemy Ingredients: Frost Salts, Ataxia Root, Spider Venom, Diamond Dust, Ruby',
				'Notes: Advanced spell inhibition.'
			},

			['p_spell_absorption_c'] = {
				'Spell Absorption Potion (Common)',
				'Absorbs a portion of incoming spell damage.',
				'Effects: Spell Absorption +20% for 60 sec',
				'Alchemy Ingredients: Void Salts, Ebony Dust, Soul Gem Shards',
				'Notes: Basic magical defense.'
			},

			['p_spell_absorption_b'] = {
				'Spell Absorption Potion (Better)',
				'Enhanced magical defense.',
				'Effects: Spell Absorption +30% for 90 sec',
				'Alchemy Ingredients: Void Salts, Ebony Dust, Soul Gem Shards, Diamond Dust',
				'Notes: Improved magical defense.'
			},

			['p_spell_absorption_q'] = {
				'Spell Absorption Potion (Superior)',
				'Maximum magical defense against spells.',
				'Effects: Spell Absorption +45% for 150 sec',
				'Alchemy Ingredients: Void Salts, Ebony Dust, Soul Gem Shards, Diamond Dust, Ruby, Moonstone',
				'Notes: Expert-level magical defense.'
			},

			['p_spell_absorption_e'] = {
				'Spell Absorption Potion (Excellent)',
				'Advanced magical absorption.',
				'Effects: Spell Absorption +40% for 120 sec',
				'Alchemy Ingredients: Void Salts, Ebony Dust, Soul Gem Shards, Diamond Dust, Ruby',
				'Notes: Advanced magical absorption with balance of power and duration.'
			},

			['p_swift_swim_c'] = {
				'Swift Swim Potion (Common)',
				'Increases swimming speed slightly.',
				'Effects: Swim Speed +20% for 60 sec',
				'Alchemy Ingredients: Fish Scales, Water Hyacinth, Pearl',
				'Notes: Basic swimming enhancement.'
			},

			['p_swift_swim_b'] = {
				'Swift Swim Potion (Better)',
				'Enhanced swimming speed.',
				'Effects: Swim Speed +30% for 90 sec',
				'Alchemy Ingredients: Fish Scales, Water Hyacinth, Pearl, Diamond Dust',
				'Notes: Improved swimming speed.'
			},

			['p_swift_swim_q'] = {
				'Swift Swim Potion (Superior)',
				'Maximum swimming speed boost.',
				'Effects: Swim Speed +45% for 150 sec',
				'Alchemy Ingredients: Fish Scales, Water Hyacinth, Pearl, Diamond Dust, Ruby, Moonstone',
				'Notes: Expert-level swimming speed.'
			},

			['p_swift_swim_e'] = {
				'Swift Swim Potion (Excellent)',
				'Significantly increased swimming speed.',
				'Effects: Swim Speed +40% for 120 sec',
				'Alchemy Ingredients: Fish Scales, Water Hyacinth, Pearl, Diamond Dust, Ruby',
				'Notes: Advanced swimming speed with balance of power and duration.'
			},

			['p_restore_health_b'] = {
				'Restore Health Potion (Better)',
				'Moderate health restoration.',
				'Effects: Restore Health +30 pts for 90 sec',
				'Alchemy Ingredients: Garlic, Wheat, Luna Moth Wing',
				'Notes: Improved health regeneration.'
			},

			['p_restore_health_q'] = {
				'Restore Health Potion (Superior)',
				'Maximum health restoration.',
				'Effects: Restore Health +50 pts for 150 sec',
				'Alchemy Ingredients: Garlic, Wheat, Luna Moth Wing, Diamond Dust, Ruby, Moonstone',
				'Notes: Expert-level health regeneration.'
			},

			['p_restore_health_e'] = {
				'Restore Health Potion (Excellent)',
				'Significant health restoration.',
				'Effects: Restore Health +45 pts for 120 sec',
				'Alchemy Ingredients: Garlic, Wheat, Luna Moth Wing, Diamond Dust, Ruby',
				'Notes: Advanced health regeneration with balance of power and duration.'
			},

			['potion_ancient_brandy'] = {
				'Ancient Brandy',
				'Restores health and slightly boosts stamina.',
				'Effects: Restore Health +25 pts, Stamina +10 pts for 90 sec',
				'Alchemy Ingredients: Aged Spirits, Honey, Spice Berries',
				'Notes: Vintage restorative drink.'
			},

			['p_almsivi_intervention_s'] = {
				'Almsivi Intervention Potion (Super)',
				'Teleports to nearest Almsivi shrine instantly.',
				'Effects: Immediate teleport to Almsivi shrine',
				'Alchemy Ingredients: Ebony Dust, Void Salts, Soul Gem Shards, Divine Essence',
				'Notes: Emergency teleportation.'
			},

			['p_detect_creatures_s'] = {
				'Detect Creatures Potion (Super)',
				'Reveals nearby creatures on the map, highlighting their positions.',
				'Effects: Detect Creatures for 120 sec',
				'Alchemy Ingredients: Eye of Newt, Bat Wing, Spider Eye, Moonstone',
				'Notes: Enhanced detection abilities.'
			},

			['p_cure_common_s'] = {
				'Cure Common Disease Potion (Super)',
				'Cures basic diseases and infections.',
				'Effects: Remove Common Diseases',
				'Alchemy Ingredients: Snowberries, Crimson Nirnroot, Bear Claws',
				'Notes: Basic disease cure.'
			},

			['p_cure_blight_s'] = {
				'Cure Blight Potion (Super)',
				'Removes blight and plant-based diseases.',
				'Effects: Remove Blight Diseases',
				'Alchemy Ingredients: Poison Ivy, Deathbell, Crimson Nirnroot',
				'Notes: Specialized disease cure.'
			},

			['p_cure_paralyzation_s'] = {
				'Cure Paralyzation Potion (Super)',
				'Removes paralysis effects and restores movement.',
				'Effects: Remove Paralysis',
				'Alchemy Ingredients: Ataxia Root, Spider Venom, Nightshade',
				'Notes: Emergency cure for paralysis.'
			},

			['p_cure_poison_s'] = {
				'Cure Poison Potion (Super)',
				'Neutralizes poison and its effects.',
				'Effects: Remove Poison',
				'Alchemy Ingredients: Poison Ivy, Viper Tongue, Deathbell',
				'Notes: Poison antidote.'
			},

			['p_detect_key_s'] = {
				'Detect Key Potion (Super)',
				'Highlights nearby keys and lockpicks.',
				'Effects: Detect Keys for 90 sec',
				'Alchemy Ingredients: Moonstone, Crystal Marrow, Diamond Dust',
				'Notes: Lockpicking aid.'
			},

			['p_dispel_s'] = {
				'Dispel Potion (Super)',
				'Removes magical effects and enchantments.',
				'Effects: Remove Magical Effects',
				'Alchemy Ingredients: Void Salts, Ebony Dust, Soul Gem Shards',
				'Notes: Magic removal.'
			},

			['p_fortify_agility_s'] = {
				'Fortify Agility Potion (Super)',
				'Boosts agility and reflexes.',
				'Effects: Fortify Agility +35 pts for 120 sec',
				'Alchemy Ingredients: Deer Tongue, Swiftness Root, Hare Meat, Diamond Dust',
				'Notes: Enhanced agility boost.'
			},

			['p_fortify_intelligence_s'] = {
				'Fortify Intelligence Potion (Super)',
				'Increases magical power and intelligence.',
				'Effects: Fortify Intelligence +35 pts for 120 sec',
				'Alchemy Ingredients: Nightshade, Snowberries, Grand Soul Gem, Moonstone',
				'Notes: Enhanced magical abilities.'
			},

			['p_fortify_luck_s'] = {
				'Fortify Luck Potion (Super)',
				'Boosts luck and chance-based effects.',
				'Effects: Fortify Luck +35 pts for 120 sec',
				'Alchemy Ingredients: Four Leaf Clover, Gold Dust, Diamond Shards, Ruby',
				'Notes: Enhanced luck boost.'
			},

			['p_fortify_willpower_s'] = {
				'Fortify Willpower Potion (Super)',
				'Increases mental fortitude and resistance.',
				'Effects: Fortify Willpower +35 pts for 120 sec',
				'Alchemy Ingredients: Dragon Heart, Ebony Dust, Void Salts, Diamond Dust',
				'Notes: Enhanced mental defense.'
			},

			['p_fortify_health_b'] = {
				'Fortify Health Potion (Better)',
				'Increases maximum health temporarily.',
				'Effects: Fortify Health +25 pts for 120 sec',
				'Alchemy Ingredients: Heart of Aelter, Bear Heart, Crimson Nirnroot',
				'Notes: Improved health boost.'
			},

			['p_fortify_magicka_s'] = {
				'Fortify Magicka Potion (Super)',
				'Increases maximum magicka temporarily, enhancing spellcasting capabilities.',
				'Effects: Fortify Magicka +40 pts for 120 sec',
				'Alchemy Ingredients: Grand Soul Gem, Moonstone, Void Salts, Diamond Dust',
				'Notes: Enhanced magical energy boost.'
			},

			['p_mark_s'] = {
				'Mark Potion (Super)',
				'Creates a magical marker for recalling later.',
				'Effects: Set Mark Location',
				'Alchemy Ingredients: Moonstone, Crystal Marrow, Soul Gem Shards',
				'Notes: Teleportation aid.'
			},

			['p_frost_resistance_s'] = {
				'Frost Resistance Potion (Super)',
				'Provides strong resistance against frost damage.',
				'Effects: Frost Resistance +40% for 120 sec',
				'Alchemy Ingredients: Ice Wraith Dust, Snowberries, Frost Salts, Diamond Dust',
				'Notes: Advanced cold defense.'
			},

			['p_slowfall_s'] = {
				'Slowfall Potion (Super)',
				'Reduces fall damage and slows descent.',
				'Effects: Slow Fall for 120 sec',
				'Alchemy Ingredients: Feather, Moonstone, Cloud Dust, Diamond Dust',
				'Notes: Enhanced fall protection.'
			},

			['p_telekinesis_s'] = {
				'Telekinesis Potion (Super)',
				'Allows levitating and moving objects with magic.',
				'Effects: Telekinesis for 90 sec',
				'Alchemy Ingredients: Moonstone, Crystal Marrow, Soul Gem Shards',
				'Notes: Object manipulation aid.'
			},

			['p_water_breathing_s'] = {
				'Water Breathing Potion (Super)',
				'Enables extended underwater breathing.',
				'Effects: Water Breathing for 120 sec',
				'Alchemy Ingredients: Fish Scales, Water Hyacinth, Pearl, Moonstone',
				'Notes: Advanced underwater capability.'
			},

			['p_water_walking_s'] = {
				'Water Walking Potion (Super)',
				'Allows walking on water surfaces.',
				'Effects: Water Walking for 120 sec',
				'Alchemy Ingredients: Water Hyacinth, Moonstone, Crystal Marrow, Diamond Dust',
				'Notes: Enhanced water walking.'
			},

			['p_vintagecomberrybrandy1'] = {
				'Vintage Comberry Brandy',
				'Restores health and stamina with moderate effects.',
				'Effects: Restore Health +30 pts, Restore Stamina +20 pts for 90 sec',
				'Alchemy Ingredients: Comberries, Aged Spirits, Honey',
				'Notes: Premium restorative drink.'
			},

			['p_frost_shield_s'] = {
				'Frost Shield Potion (Super)',
				'Provides strong protection against frost damage.',
				'Effects: Absorb Frost Damage +45 pts for 120 sec',
				'Alchemy Ingredients: Ice Wraith Dust, Snowberries, Frost Salts, Diamond Dust',
				'Notes: Advanced cold resistance.'
			},

			['p_restore_magicka_s'] = {
				'Restore Magicka Potion (Super)',
				'Restores magicka points rapidly.',
				'Effects: Restore Magicka +40 pts for 90 sec',
				'Alchemy Ingredients: Grand Soul Gem, Moonstone, Void Salts',
				'Notes: Enhanced magical energy recovery.'
			},

			['p_fortify_attack_e'] = {
				'Fortify Attack Potion (Excellent)',
				'Significantly boosts melee and ranged attack power.',
				'Effects: Fortify Attack +45 pts for 150 sec',
				'Alchemy Ingredients: Bear Claws, Mammoth Tusk, Stalhrim, Diamond Dust, Ruby',
				'Notes: Advanced combat enhancement.'
			},

			['p_cure_common_unique'] = {
				'Cure Common Disease Potion (Unique)',
				'Potently cures all common diseases.',
				'Effects: Remove All Common Diseases',
				'Alchemy Ingredients: Snowberries, Crimson Nirnroot, Bear Claws, Diamond Dust',
				'Notes: Powerful disease cure.'
			},

			['p_restore_health_s'] = {
				'Restore Health Potion (Super)',
				'Rapidly restores health points with enhanced effects.',
				'Effects: Restore Health +40 pts for 120 sec',
				'Alchemy Ingredients: Heart of Aelter, Bear Heart, Crimson Nirnroot, Diamond Dust',
				'Notes: Powerful health regeneration.'
			},

			['p_detect_enchantment_s'] = {
				'Detect Enchantment Potion (Super)',
				'Reveals enchantments on items and objects.',
				'Effects: Detect Enchantments for 90 sec',
				'Alchemy Ingredients: Grand Soul Gem, Crystal Marrow, Moonstone',
				'Notes: Enchantment detection aid.'
			},

			['p_quarrablood_UNIQUE'] = {
				'Quarra Blood Potion (Unique)',
				'Provides unique combat enhancements.',
				'Effects: Fortify Attack +30%, Fortify Health +20 pts for 120 sec',
				'Alchemy Ingredients: Quarra Blood, Dragon Heart, Ebony Dust',
				'Notes: Rare combat potion.'
			},

			['p_sinyaramen_UNIQUE'] = {
				'Sinyaramen Potion (Unique)',
				'Restores health and stamina with special effects.',
				'Effects: Restore Health +50 pts, Restore Stamina +30 pts, Fortify Health +15 pts for 150 sec',
				'Alchemy Ingredients: Sinyar Root, Bear Heart, Mammoth Tusk',
				'Notes: Potent restorative effects.'
			},

			['p_heroism_s'] = {
				'Heroism Potion (Super)',
				'Boosts all combat-related attributes.',
				'Effects: Fortify Attack +35%, Fortify Health +30 pts, Fortify Stamina +20 pts for 120 sec',
				'Alchemy Ingredients: Dragon Heart, Bear Claws, Mammoth Tusk, Diamond Dust',
				'Notes: Comprehensive combat enhancement.'
			},

			['p_lovepotion_unique'] = {
				'Love Potion (Unique)',
				"Affects target's disposition and affection.",
				'Effects: Increase Disposition +50 pts for 120 sec',
				'Alchemy Ingredients: Moonstone, Lavender, Honeycomb',
				'Notes: Social enhancement potion.'
			},

			['p_recall_s'] = {
				'Recall Potion (Super)',
				'Teleports to previously marked location.',
				'Effects: Teleport to Marked Location',
				'Alchemy Ingredients: Moonstone, Crystal Marrow, Soul Gem Shards',
				'Notes: Instant teleportation.'
			},

			['pyroil_tar_unique'] = {
				'Pyroil Tar Potion (Unique)',
				'Provides fire resistance and damage boost.',
				'Effects: Fire Resistance +40%, Fortify Fire Damage +20% for 120 sec',
				'Alchemy Ingredients: Fire Salts, Dragon Heart, Volcanic Ash',
				'Notes: Fire-based combat enhancement.'
			},

			['p_dwemer_lubricant00'] = {
				'Dwemer Lubricant Potion',
				'Enhances mechanical and lockpicking abilities.',
				'Effects: Fortify Lockpicking +25 pts for 90 sec',
				'Alchemy Ingredients: Dwemer Scrap, Oil, Crystal Marrow',
				'Notes: Mechanical enhancement.'
			},

			['verminous_fabricant_elixir'] = {
				'Verminous Fabricant Elixir',
				'Provides unique transformation effects.',
				'Effects: Transform into Vermin Form for 120 sec',
				'Alchemy Ingredients: Spider Venom, Rat Tail, Vermin Essence',
				'Notes: Special transformation potion.'
			},

			['hulking_fabricant_elixir'] = {
				'Hulking Fabricant Elixir',
				'Enhances physical strength and size.',
				'Effects: Fortify Strength +50 pts, Increase Size +25% for 120 sec',
				'Alchemy Ingredients: Bear Claws, Mammoth Tusk, Stalhrim',
				'Notes: Physical enhancement potion.'
			},


			['p_Imperfect_Elixir'] = {
				'Imperfect Elixir',
				'Provides unpredictable effects with mixed outcomes.',
				'Effects: Random Positive/Negative Effects for 90 sec',
				'Alchemy Ingredients: Void Salts, Moonstone Shard, Crystal Marrow, Random Rare Ingredient',
				'Notes: Unreliable but potentially powerful potion.'
			},

			['potion_nord_mead'] = {
				'Nord Mead Potion',
				'Traditional Nord brew offering combat benefits.',
				'Effects: Fortify Health +20 pts, Fortify Stamina +20 pts for 120 sec',
				'Alchemy Ingredients: Mead, Bear Claws, Snowberries',
				'Notes: Cultural combat elixir.'
			}
        }
    }
}