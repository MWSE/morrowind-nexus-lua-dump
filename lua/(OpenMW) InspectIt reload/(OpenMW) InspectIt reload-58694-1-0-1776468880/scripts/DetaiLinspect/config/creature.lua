local types = require('openmw.types')
local util = require('openmw.util')

return {
    [types.Creature] = {
        title = 'Creature',
        color = util.color.rgb(0.8, 0.2, 0.2),
        showType = true,
        uniqueDescriptions = {
			['vivec_god'] = {
				'Vivec',
				'Living god of the Tribunal, poet, warrior, and ruler of Vvardenfell.',
				'Faction: Tribunal Temple',
				'Location: Vivec City, Palace of Vivec',
				'Role: Final arbiter of the Nerevarine prophecy. Grants divine intervention and blessings. Central to the main quest and Temple doctrine.',
				'Notes: Immortal deity. His actions and decisions shape the fate of Morrowind. The city of Vivec is named after him.'
			},            
			['dagoth_ur_1'] = {
				'Dagoth Ur',
				'Immortal leader of the Sixth House.',
				'Faction: Sixth House',
				'Location: Red Mountain',
				'Role: Primary antagonist of the main quest.',
				'Notes: Source of the Blight. Immortal until final battle.'
			},
			['dagoth_ur_2'] = {
				'Dagoth Ur',
				'Immortal leader of the Sixth House.',
				'Faction: Sixth House',
				'Location: Red Mountain',
				'Role: Primary antagonist of the main quest.',
				'Notes: Source of the Blight. Immortal until final battle.'
			},			
			['yagrum bagarn'] = {
				'Yagrum Bagarn',
				'is the last known living Dwemer living in the Corprusarium under Tel Fyr.',
				'In the distant past, he was a Master Crafter in the service of the chief Tonal Architect, Lord Kagrenac.',
				'He survived the disappearance of the Dwarves and has been searching for his people since.',
				'However, when he returned to Red Mountain, he contracted the Corprus disease.',
				'He eventually crossed paths with Divayth Fyr, who restored him to his senses and made several attempts to cure his affliction.',
				'None of them succeeded but Yagrum Bagarn continues to have faith that Divayth Fyr will discover a cure.'
			},			
			['alit'] = {
				'Alit',
				'Large reptilian predator',
				'Type: Animal',
				'Location: Ashlands, West Gash',
				'Description: Agile, pack-hunting reptile. Attacks with claws and bite.',
				'Notes: Skin is valuable.'
			},
			['alit_diseased'] = {
				'Alit',
				'Large reptilian predator',
				'Type: Animal',
				'Location: Ashlands, West Gash',
				'Description: Agile, pack-hunting reptile. Attacks with claws and bite.',
				"Notes: This one doesn't look good."
			},
			['alit_blighted'] = {
				'Alit',
				'Large reptilian predator',
				'Type: Animal',
				'Location: Ashlands, West Gash',
				'Description: Agile, pack-hunting reptile. Attacks with claws and bite.',
				'Notes: This one looks terrible, covered with pestilence.'
			},			
			['guar'] = {
				'Guar',
				'Domesticated herd animal',
				'Type: Animal (Domestic)',
				'Location: Near settlements, farms',
				'Description: Common pack animal of Dunmer. Used for transport and meat.',
				'Notes: Non-hostile unless provoked.'
			},
			['kagouti'] = {
				'Kagouti',
				'Large herbivore with tusks',
				'Type: Animal',
				'Location: Grazelands, Molag Amur',
				'Description: Massive grazing animal. Defends itself with tusks.',
				'Notes: Rarely attacks unless threatened.'
			},
			['kagouti_mating'] = {
				'Kagouti',
				'Large herbivore with tusks',
				'Type: Animal',
				'Location: Grazelands, Molag Amur',
				'Description: Massive grazing animal. Defends itself with tusks.',
				'Notes: This one looks agressive.'
			},			
			['kagouti_diseased'] = {
				'Kagouti',
				'Large herbivore with tusks',
				'Type: Animal',
				'Location: Grazelands, Molag Amur',
				'Description: Massive grazing animal. Defends itself with tusks.',
				"Notes: This one doesn't look good."
			},			
			['kagouti_blighted'] = {
				'Kagouti',
				'Large herbivore with tusks',
				'Type: Animal',
				'Location: Grazelands, Molag Amur',
				'Description: Massive grazing animal. Defends itself with tusks.',
				'Notes: This one looks terrible, covered with pestilence.'
			},
			['nix-hound'] = {
				'Nix-Hound',
				'Aggressive canine predator',
				'Type: Animal',
				'Location: Everywhere except high mountains',
				'Description: Fast, pack-hunting predator. Bites and claws.',
				'Notes: Common in rural areas.'
			},
			['nix-hound blighted'] = {
				'Nix-Hound',
				'Aggressive canine predator',
				'Type: Animal',
				'Location: Everywhere except high mountains',
				'Description: Fast, pack-hunting predator. Bites and claws.',
				'Notes: This one looks terrible, covered with pestilence.'
			},			
			['slaughterfish'] = {
				'Slaughterfish',
				'Aquatic predator',
				'Type: Aquatic',
				'Location: Rivers, lakes, canals',
				'Description: Sharp-toothed fish. Attacks swimmers.',
				'Notes: Found in most water bodies. Swims in schools.'
			},
			['slaughterfish_hr_sfavd'] = {
				'Slaughterfish',
				'Aquatic predator',
				'Type: Aquatic',
				'Location: Rivers, lakes, canals',
				'Description: Sharp-toothed fish. Attacks swimmers.',
				'Notes: Very big and old fish with blue fins.'
			},
			['Slaughterfish_Small'] = {
				'Slaughterfish',
				'Aquatic predator',
				'Type: Aquatic',
				'Location: Rivers, lakes, canals',
				'Description: Sharp‑toothed fish. Attacks swimmers.',
				'Notes: Found in most water bodies. Swims in schools.'
			},			
			['shalk'] = {
				'Shalk',
				'Giant insect',
				'Type: Insect',
				'Location: Grazelands, Ashlands',
				'Description: Armored insect. Attacks with mandibles.',
				'Notes: Produces valuable resin.'
			},
			['shalk_diseased'] = {
				'Shalk',
				'Giant insect',
				'Type: Insect',
				'Location: Grazelands, Ashlands',
				'Description: Armored insect. Attacks with mandibles.',
				"Notes: This one doesn't look good."
			},
			['shalk_diseased_hram'] = {
				'Shalk',
				'Giant insect',
				'Type: Insect',
				'Location: Grazelands, Ashlands',
				'Description: Armored insect. Attacks with mandibles.',
				"Notes: This one doesn't look good."
			},			
			['shalk_blighted'] = {
				'Shalk',
				'Giant insect',
				'Type: Insect',
				'Location: Grazelands, Ashlands',
				'Description: Armored insect. Attacks with mandibles.',
				'Notes: This one looks terrible, covered with pestilence.'
			},			
			['daedroth'] = {
				'Daedroth',
				'Lesser Daedra',
				'Type: Daedra',
				'Location: Daedric ruins, Oblivion portals',
				'Description: Reptilian Daedra. Attacks with claws and poison.',
				'Notes: Immune to normal weapons. Summoned by mages.'
			},
			['golden saint'] = {
				'Golden Saint',
				'Aedric Daedra of Sheogorath',
				'Type: Daedra (High)',
				'Location: Shivering Isles (via portals)',
				'Description: Majestic warrior.'
			},
			['winged twilight'] = {
				'Winged Twilight',
				'Daedric servant of Azura',
				'Type: Daedra',
				"Location: Azura's Shrine, Daedric sites",
				'Description: Humanoid with wings. Casts spells.',
				"Notes: Defends Azura's shrines."
			},

			['skeleton'] = {
				'Skeleton',
				'Type: Undead',
				'Location: Tombs, ruins',
				'Description: Undead warrior. Attacks with weapons.',
				'Notes: Immune to poison and disease.'
			},
			['skeleton_weak'] = {
				'Skeleton',
				'Type: Undead',
				'Location: Tombs, ruins',
				'Description: Undead warrior. Attacks with weapons.',
				'Notes: Immune to poison and disease.'
			},			
			['skeleton_Vemynal'] = {
				'Skeleton',
				'Type: Undead',
				'Location: Tombs, ruins',
				'Description: Undead warrior. Attacks with weapons.',
				'Notes: Immune to poison and disease.'
			},			
			['skeleton hero dead'] = {
				'Skeleton',
				'Type: Undead',
				'Location: Tombs, ruins',
				'Description: Undead warrior. Attacks with weapons.',
				'Notes: Immune to poison and disease.'
			},			
			['dead_skeleton'] = {
				'Skeleton',
				'Type: Undead',
				'Location: Tombs, ruins',
				'Description: Undead warrior. Attacks with weapons.',
				'Notes: Immune to poison and disease.'
			},			
			['skeleton entrance'] = {
				'Skeleton',
				'Type: Undead',
				'Location: Tombs, ruins',
				'Description: Undead warrior. Attacks with weapons.',
				'Notes: Immune to poison and disease.'
			},			
			['skeleton archer'] = {
				'Skeleton',
				'Type: Undead',
				'Location: Tombs, ruins',
				'Description: Undead warrior. Attacks with weapons.',
				'Notes: Immune to poison and disease.'
			},			
			['skeleton champion'] = {
				'Skeleton',
				'Type: Undead',
				'Location: Tombs, ruins',
				'Description: Undead warrior. Attacks with weapons.',
				'Notes: Immune to poison and disease.'
			},				
			['skeleton champ_sandas00'] = {
				'Skeleton',
				'Type: Undead',
				'Location: Tombs, ruins',
				'Description: Undead warrior. Attacks with weapons.',
				'Notes: Immune to poison and disease.'
			},				
			['skeleton champ_sandas10'] = {
				'Skeleton',
				'Type: Undead',
				'Location: Tombs, ruins',
				'Description: Undead warrior. Attacks with weapons.',
				'Notes: Immune to poison and disease.'
			},				
			['skeleton_aldredaynia'] = {
				'Skeleton',
				'Type: Undead',
				'Location: Tombs, ruins',
				'Description: Undead warrior. Attacks with weapons.',
				'Notes: Immune to poison and disease.'
			},		
			['skeleton warrior'] = {
				'Skeleton',
				'Type: Undead',
				'Location: Tombs, ruins',
				'Description: Undead warrior. Attacks with weapons.',
				'Notes: Immune to poison and disease.'
			},	
			['worm lord'] = {
				'Skeleton',
				'Type: Undead',
				'Location: Tombs, ruins',
				'Description: Undead warrior. Attacks with weapons.',
				'Notes: Immune to poison and disease.'
			},	
			['bonewalker'] = {
				'Rotting corpse',
				'Type: Undead',
				'Location: Crypts, battlefields',
				'Description: Slow, disease-ridden undead.',
				'Notes: Spreads diseases.'
			},
			['bonewalker_weak'] = {
				'Rotting corpse',
				'Type: Undead',
				'Location: Crypts, battlefields',
				'Description: Slow, disease-ridden undead.',
				'Notes: Spreads diseases.'
			},			
			['Bonewalker_Greater'] = {
				'Rotting corpse',
				'Type: Undead',
				'Location: Crypts, battlefields',
				'Description: Slow, disease-ridden undead.',
				'Notes: Spreads diseases.'
			},			
			['BM_wolf_grey_lvl_1'] = {
				'Wolf',
				'Pack predator of Solstheim',
				'Type: Animal',
				'Location: Tundra, forests of Solstheim',
				'Description: Packs of 2–5. Bites with sharp teeth.',
				'Notes: More aggressive than mainland wolves.'
			},
			['BM_wolf_grey'] = {
				'Wolf',
				'Pack predator of Solstheim',
				'Type: Animal',
				'Location: Tundra, forests of Solstheim',
				'Description: Packs of 2–5. Bites with sharp teeth.',
				'Notes: More aggressive than mainland wolves.'
			},			
			['BM_wolf_hroldar'] = {
				'Wolf',
				'Pack predator of Solstheim',
				'Type: Animal',
				'Location: Tundra, forests of Solstheim',
				'Description: Packs of 2–5. Bites with sharp teeth.',
				'Notes: More aggressive than mainland wolves.'
			},			
			['BM_wolf_caenlorn1'] = {
				'Wolf',
				'Pack predator of Solstheim',
				'Type: Animal',
				'Location: Tundra, forests of Solstheim',
				'Description: Packs of 2–5. Bites with sharp teeth.',
				'Notes: More aggressive than mainland wolves.'
			},			
			['BM_wolf_caenlorn2'] = {
				'Wolf',
				'Pack predator of Solstheim',
				'Type: Animal',
				'Location: Tundra, forests of Solstheim',
				'Description: Packs of 2–5. Bites with sharp teeth.',
				'Notes: More aggressive than mainland wolves.'
			},			
			['BM_wolf_caenlorn3'] = {
				'Wolf',
				'Pack predator of Solstheim',
				'Type: Animal',
				'Location: Tundra, forests of Solstheim',
				'Description: Packs of 2–5. Bites with sharp teeth.',
				'Notes: More aggressive than mainland wolves.'
			},			
			['BM_bear_snow_unique'] = {
				'Snow Bear',
				'Large predator of the north',
				'Type: Animal',
				'Location: Solstheim highlands',
				'Description: Massive, white bear. Claws and bites.',
				'Notes: One of the strongest animals in Tamriel.'
			},
			['BM_bear_SPR_UNIQUE'] = {
				'Snow Bear',
				'Large predator of the north',
				'Type: Animal',
				'Location: Solstheim highlands',
				'Description: Massive, white bear. Claws and bites.',
				'Notes: One of the strongest animals in Tamriel.'
			},			
			['BM_bear_be_UNIQUE'] = {
				'Snow Bear',
				'Large predator of the north',
				'Type: Animal',
				'Location: Solstheim highlands',
				'Description: Massive, white bear. Claws and bites.',
				'Notes: One of the strongest animals in Tamriel.'
			},			
			['creature_werewolf_01'] = {
				'Werewolf',
				'Lycanthrope',
				'Type: Lycanthrope',
				'Location: Solstheim (Bloodmoon)',
				'Description: Humanoid wolf. Extremely fast and strong.',
				'Notes: Transforms at night during Bloodmoon.'
			},
			['atronach_frost'] = {
				'Frost Atronach',
				'Elemental Daedra',
				'Type: Daedra (Elemental)',
				'Location: Cold regions, summoned',
				'Description: Construct of ice and magic.',
				'Notes: Resists frost, absorbs shock.'
			},
			['ancestor_ghost'] = {
				'Ancestor Ghost',
				'Spirit of the Dunmer dead',
				'Type: Undead (Ghost)',
				'Location: Tombs, ancestral shrines',
				'Description: Ethereal spirit. Attacks with chilling touch.',
				'Notes: Can only be harmed by magic, silver, or enchanted weapons.'
			},
			['ash_ghoul'] = {
				'Ash Ghoul',
				'Corrupted servant of Dagoth Ur',
				'Faction: Sixth House',
				'Location: Red Mountain, ash wastes',
				'Description: Twisted undead. Attacks with claws and disease.',
				'Notes: Spreads Blight. Stronger than Ash Slaves.'
			},
			['ash_slave'] = {
				'Ash Slave',
				'Mind‑controlled servant of the Sixth House',
				'Faction: Sixth House',
				'Location: Near Dagoth strongholds',
				'Description: Former Dunmer, now a husk. Attacks with crude weapons.',
				'Notes: No will of their own. Often found in groups.'
			},
			['ash_vampire'] = {
				'Ash Vampire',
				'Elite servant of Dagoth Ur',
				'Faction: Sixth House',
				'Location: Deep within Dagoth strongholds',
				'Description: Powerful undead. Drains life force.',
				'Notes: Extremely dangerous. Immune to normal weapons.'
			},
			['clannfear'] = {
				'Clannfear',
				'Reptilian Daedra',
				'Type: Daedra',
				'Location: Oblivion portals, Daedric ruins',
				'Description: Bipedal reptile. Fast and aggressive.',
				'Notes: Summoned by powerful mages.'
			},
			['cliff racer'] = {
				'Cliff Racer',
				'Flying predator of Vvardenfell',
				'Type: Bird',
				'Location: Mountains, cliffs across Vvardenfell',
				'Description: Large, aggressive bird. Dives to attack.',
				'Notes: Hated by travelers. Attacks in flocks.'
			},
			['corprus_stalker'] = {
				'Corprus Stalker',
				'Mutated creature of the Corprus disease',
				'Type: Aberration',
				'Location: Corprusarium, Red Mountain',
				'Description: Twisted, powerful being. Resistant to magic.',
				'Notes: Yagrum Bagarn studies them. Highly aggressive.'
			},
			['dreugh'] = {
				'Dreugh',
				'Aquatic humanoid',
				'Type: Aquatic',
				'Location: Coastal areas, rivers',
				'Description: Crab‑like humanoid. Attacks with claws.',
				'Notes: Skin is valuable. Can come ashore.'
			},
			['dremora'] = {
				'Dremora',
				'Daedric warrior',
				'Type: Daedra (High)',
				'Location: Daedric sites, summoned',
				'Description: Armored humanoid. Skilled with weapons and magic.',
				'Notes: Proud and intelligent. Loyal to their princes.'
			},
			['kwama forager'] = {
				'Kwama Forager',
				'Worker caste of Kwama colonies',
				'Type: Insect',
				'Location: Kwama mines',
				'Description: Small insectoid. Defends the colony.',
				'Notes: Non‑hostile unless provoked.'
			},
			['kwama warrior'] = {
				'Kwama Warrior',
				'Soldier caste of Kwama colonies',
				'Type: Insect',
				'Location: Kwama mines',
				'Description: Heavily armored insect. Attacks with mandibles.',
				'Notes: Guards the Queen and tunnels.'
			},
			['kwama worker'] = {
				'Kwama Worker',
				'Labor caste of Kwama colonies',
				'Type: Insect',
				'Location: Kwama mines',
				'Description: Small insectoid. Focuses on mining and tunneling.',
				'Notes: Non‑hostile.'
			},
			['mudcrab'] = {
				'Mudcrab',
				'Small crustacean',
				'Type: Crustacean',
				'Location: Coastlines, swamps',
				'Description: Small crab. Often hides in plain sight.',
				'Notes: Usually non‑hostile, but attacks if threatened.'
			},
			['scamp'] = {
				'Scamp',
				'Lesser Daedra',
				'Type: Daedra',
				'Location: Oblivion portals, summoned',
				'Description: Imp‑like creature. Harasses with minor magic.',
				'Notes: Weak but annoying. Often summoned.'
			},
			['BM_spriggan'] = {
				'Spriggan',
				'Nature spirit',
				'Type: Elemental',
				'Location: Forests, sacred groves',
				'Description: Tree‑like being. Regenerates health.',
				'Notes: Must be killed three times to stay dead.'
			},
			['centurion_steam'] = {
				'Steam Centurion',
				'Dwemer construct',
				'Type: Construct',
				'Location: Dwemer ruins',
				'Description: Steam-powered automaton. Attacks with steam blasts and melee.',
				'Notes: Immune to poison and disease. Part of Dwemer defenses.'
			},
			['atronach_flame'] = {
				'Flame Atronach',
				'Elemental Daedra',
				'Type: Daedra (Elemental)',
				'Location: Warm regions, summoned',
				'Description: Construct of fire and magic.',
				'Notes: Resists fire, absorbs frost.'
			},
			['atronach_storm'] = {
				'Storm Atronach',
				'Elemental Daedra',
				'Type: Daedra (Elemental)',
				'Location: High elevations, summoned',
				'Description: Construct of lightning and magic.',
				'Notes: Absorbs shock, resists electricity.'
			},
			['BM_horker'] = {
				'Horker',
				'Marine mammal',
				'Type: Aquatic',
				'Location: Coasts of Solstheim',
				'Description: Tusked sea creature. Usually avoids conflict.',
				'Notes: Hunted for tusks and meat.'
			},
			['ancestor_guardian_fgdd'] = {
				'Ancestor Guardian',
				'Protector spirit of Dunmer ancestors',
				'Type: Undead (Ghost)',
				'Location: Ancient tombs, ancestral shrines',
				'Description: Powerful spectral guardian. Attacks with magical blasts.',
				'Notes: Stronger than regular Ancestor Ghosts. Defends sacred places.'
			},
			['ascended_sleeper'] = {
				'Ascended Sleeper',
				'Twisted creation of Dagoth Ur\'s magic',
				'Faction: Sixth House',
				'Location: Deep within Red Mountain',
				'Description: Half‑human, half‑beast abomination. Highly intelligent and aggressive.',
				'Notes: One of the most dangerous servants of Dagoth Ur.'
			},
				['ash_zombie'] = {
				'Ash Zombie',
				'Mindless servant of the Sixth House',
				'Faction: Sixth House',
				'Location: Near Dagoth strongholds, ash wastes',
				'Description: Former Dunmer, now a shambling corpse. Attacks with crude weapons.',
				'Notes: Weaker than Ash Slaves but often found in large groups.'
			},
			['netch_bull'] = {
				'Bull Netch',
				'Large floating creature',
				'Type: Airborne',
				'Location: Swamps, lowlands of Vvardenfell',
				'Description: Gas‑filled creature. Drifts slowly. Attacks with electric shock.',
				'Notes: Produces valuable Netch Leather.'
			},
			['netch_betty'] = {
				'Betty Netch',
				'Female Bull Netch',
				'Type: Airborne',
				'Location: Swamps, lowlands of Vvardenfell',
				'Description: Larger and more aggressive than males. Attacks with electric shock.',
				'Notes: Rarely found alone.'
			},
			['Netch_Giant_UNIQUE'] = {
				'Giant Bull Netch',
				'Massive floating creature',
				'Type: Airborne',
				'Location: Remote swamps of Vvardenfell',
				'Description: Enormous Netch. Extremely dangerous.',
				'Notes: Very rare. Produces the finest Netch Leather.'
			},
			['kwama queen_gnisis'] = {
				'Kwama Queen',
				'Matriarch of Kwama colonies',
				'Type: Insect (Queen)',
				'Location: Deepest levels of Kwama mines',
				'Description: Massive, immobile insect. Produces eggs for the colony.',
				'Notes: Heavily guarded by Warriors. Killing her collapses the mine.'
			},
			['scrib'] = {
				'Scrib',
				'Larval form of Kwama',
				'Type: Insect',
				'Location: Kwama mines, near food sources',
				'Description: Small, worm‑like creature. Non‑hostile unless provoked.',
				'Notes: Often farmed for food.'
			},
			['rat'] = {
				'Cave Rat',
				'Small rodent',
				'Type: Rodent',
				'Location: Caves, ruins, sewers',
				'Description: Tiny scavenger. Usually flees from danger.',
				'Notes: Can carry diseases.'
			},
			['rat_cave_fgt'] = {
				'Game Rat',
				'Trained fighting rodent',
				'Type: Rodent (Trained)',
				'Location: Betting pits, arenas',
				'Description: Aggressive rat. Fights in tournaments.',
				'Notes: Used for gambling.'
			},
			['rat_telvanni_unique'] = {
				'Telvanni Sewer Rat',
				'Mutated rodent',
				'Type: Rodent',
				'Location: Telvanni tower sewers',
				'Description: Large, aggressive rat. Often diseased.',
				'Notes: Larger and tougher than normal rats.'
			},
			['centurion_projectile'] = {
				'Centurion Archer',
				'Dwemer ranged automaton',
				'Type: Construct',
				'Location: Dwemer ruins',
				'Description: Steam-powered archer. Fires enchanted bolts.',
				'Notes: Part of Dwemer defense systems.'
			},
			['centurion_sphere'] = {
				'Centurion Sphere',
				'Dwemer rolling automaton',
				'Type: Construct',
				'Location: Dwemer ruins',
				'Description: Spherical construct. Rolls to crush enemies.',
				'Notes: Immune to poison. Can self‑repair.'
			},
			['centurion_spider'] = {
				'Centurion Spider',
				'Dwemer spider automaton',
				'Type: Construct',
				'Location: Dwemer ruins',
				'Description: Eight-legged construct. Attacks with claws and magic.',
				'Notes: Climbs walls. Very durable.'
			},
			['dwarven ghost'] = {
				'Dwarven Spectre',
				'Ghost of a Dwemer',
				'Type: Undead (Spectre)',
				'Location: Deep Dwemer ruins',
				'Description: Ethereal remnant of a Dwemer mage.',
				'Notes: Casts powerful magic. Immune to normal weapons.'
			},
			['dreugh_koal'] = {
				'Dreugh Warlord',
				'Elite aquatic humanoid',
				'Type: Aquatic',
				'Location: Coastal caves, deep waters',
				'Description: Larger, armored Dreugh. Commands lesser Dreugh.',
				'Notes: Extremely tough. Wears Dreugh armor.'
			},
			['goblin_grunt'] = {
				'Goblin',
				'Vile humanoid',
				'Type: Humanoid',
				'Location: Ruins, caves',
				'Description: Short, green humanoid. Uses crude weapons.',
				'Notes: Some are mages. Often accompanied by Durzogs.'
			},
			['durzog_wild'] = {
				'Durzog',
				'Goblin\'s beast',
				'Type: Beast',
				'Location: Goblin camps',
				'Description: Hairless, dog‑like creature. Attacks in packs.',
				'Notes: Trained by Goblins as guard animals.'
			},
			['BM_ice_troll'] = {
				'Grahl',
				'Arctic predator',
				'Type: Beast',
				'Location: Solstheim (Bloodmoon)',
				'Description: Massive, tusked beast. Attacks with claws and tusks.',
				'Notes: Native to Solstheim. Feared by the Skaal.'
			},
			['BM_riekling'] = {
				'Riekling',
				'Blue mountain goblin',
				'Type: Humanoid (Feral)',
				'Location: Mountains of Solstheim',
				'Description: Small, blue humanoid. Uses primitive weapons.',
				'Notes: Travels in tribes. Hostile to all outsiders.'
			},
			['BM_riekling_boarmaster'] = {
				'Riekling Raider',
				'Tribal warrior of the Rieklings',
				'Type: Humanoid (Feral)',
				'Location: Riekling camps on Solstheim',
				'Description: More skilled Riekling. Uses better weapons.',
				'Notes: Leads hunting parties.'
			},
			['fabricant_hulking_C'] = {
				'Hulking Fabricant',
				'Construct of Sotha Sil',
				'Type: Construct (Magical)',
				'Location: Clockwork City (Tribunal)',
				'Description: Twisted, living machine. Attacks with crushing blows.',
				'Notes: Created by Sotha Sil. Immune to many spells.'
			},
			['fabricant_machine_1'] = {
				'Verminous Fabricant',
				'Corrupted construct',
				'Type: Construct (Magical)',
				'Location: Corrupted areas of Clockwork City',
				'Description: Diseased machine. Spreads corruption.',
				'Notes: Highly infectious.'
			},
			['BM_frost_boar'] = {
				'Tusked Bristleback',
				'Wild boar of Vvardenfell',
				'Type: Beast',
				'Location: Forests, Grazelands',
				'Description: Agressive boar. Attacks with tusks.',
				'Notes: Skin is valuable.'
			},			
			['bonelord'] = {
				'Bone Lord',
				'Powerful undead necromancer',
				'Type: Undead (Lich)',
				'Location: Ancient tombs, necromancer lairs',
				'Description: Skeletal mage. Casts powerful necromantic spells.',
				'Notes: Can raise dead. Immune to poison and disease.'
			},
			['hunger'] = {
				'Hunger',
				'Daedric parasite',
				'Type: Daedra (Parasite)',
				'Location: Oblivion, summoned',
				'Description: Floating mouth. Drains life force.',
				'Notes: Summoned by necromancers. Extremely dangerous.'
			},
			['ogrim'] = {
				'Ogrim',
				'Giant humanoid',
				'Type: Giant (Humanoid)',
				'Location: Remote mountains, ruins',
				'Description: Massive brute. Attacks with fists and rocks.',
				'Notes: Strong but slow. Rarely found.'
			},
			['ogrim titan'] = {
				'Ogrim Titan',
				'Ancient giant',
				'Type: Giant (Ancient)',
				'Location: Deepest ruins, sacred sites',
				'Description: Enormous Ogrim. Nearly unstoppable.',
				'Notes: Legendary creature. Possibly a deity or demigod.'
			}			
        }
    }
}