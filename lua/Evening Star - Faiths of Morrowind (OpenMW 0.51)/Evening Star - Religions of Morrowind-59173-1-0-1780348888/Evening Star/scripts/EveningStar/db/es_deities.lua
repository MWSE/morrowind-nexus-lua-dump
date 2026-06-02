ES = ES or {}
ES.DB = ES.DB or {}

require('scripts.EveningStar.db.es_actors')

ES.DB.pantheon = {
	tt = { 
		name = "Tribunal Temple",
		passiveGrowth = true,
		passiveDecay = false,
		crimePenalty = true,
		deities = {
			vivec = {
				id          = "vivec",
				name        = "Vivec",
				title       = "The Warrior-Poet",
				description = "Patron of Artists, Rogues",
				flavorText  = "Protect Morrowind and My holy city. Read and reflect upon poetry. Destroy my enemies. Defeat the Blight. Pray at the shrines of ALMSIVI. Complete pilgrimages. House Redoran is most deserving of my favor. Never openly defile the laws of Morrowind.",
				tooltipDesc = "Living god of the Tribunal Temple. Warrior-poet and defender of Vvardenfell, who walks the line between art and combat.",
				-- follower + devotee ability descriptions
				followerAbility = "Become a Follower to gain Warrior's Charge which reduces an enemy's max health on your first strike in combat based on your favor.",
				devoteeAbility  = "Become a Devotee to gain Poet's Charm which, during prayer allows you to activate a character to successfully charm them by increasing their disposition for 5 minutes. Costs 10% favor.",
				-- gifts
				gift_1 = "es_tt_vivec_g1",     -- +10 Luck, +5 Fortify Attack
				gift_2 = "warriors_charge",    -- next landed hit at combat start
				gift_2_alias = "Warrior's Charge",
				gift_3 = "poets_charm",        -- prayer spawns orb -> arms next NPC
				gift_3_alias = "Poet's Charm",

				-- passive favor regen (+0.1 per game hour while any of these match)
				passiveRegen = {
					races     = { "dark elf" },
					classes   = { "rogue", "agent", "thief", "bard" },
					factions  = { "house redoran", "tribunal temple" },
					equipment = { "wraithguard", "wraithguard_jury_rig" },
				},
		
				favorKills = {
					races            = { "imperial" },
					recordIdContains = { "_blighted", "blighted_", "dagoth_ur_1", "dagoth_ur_2" },
					recordIdSet      = ES.DB.actors.blighted,
				},
		
				-- taboo kills (-10 favor + reproach)
				tabooKills = {
					recordIdContains = { "ordinator", },
				},
		
				-- sacred locations (1.5x prayer favor bonus, cell name lowercased)
				favorLocations = {
					["vivec, library of vivec"] = true, -- need localized name, but could also just be anywhere in vivec
				},
				
				-- texture tint when no deity / fallback
				-- uiTint = { r = 1.0, g = 0.85, b = 0.3 },
			},
			almalexia = {
				id          = "almalexia",
				name        = "Almalexia",
				title       = "The Warden",
				description = "Patron of Healers, Teachers",
				races     = { "dark elf" },

				flavorText  = "Vanquish the threats facing Morrowind. Be generous to beggars and children. Travel with companions. Pray at the shrines of ALMSIVI. Healers and Priests are most deserving of my favor. Never openly defile the laws of Morrowind.",
				tooltipDesc = "Living god of the Tribunal Temple. Mother of Morrowind and defender of the holy city named after the divine goddess.",
				-- follower + devotee ability descriptions
				followerAbility = "Become a Follower to gain Healer's Gift which restores health every second to yourself and companions when you are not traveling alone.",
				devoteeAbility  = "Become a Devotee to gain Mother's Grace which revives you when falling below 10% health or receiving a fatal blow. Only once per day, costs 15% favor.",
				gift_1 = "es_tt_almalexia_g1", -- 10 sanctuary, +5 Endurance
				gift_2 = "healers_gift",       -- passive HoT on player + companions while traveling together
				gift_2_alias = "Healer's Gift",
				gift_3 = "mothers_grace",      -- once/day revive from below 10% hp or fatal blow
				gift_3_alias = "Mother's Grace",
				-- passive favor regen (+0.1 per game hour while any of these match)
				passiveRegen = {
					races     = { "dark elf" },
					classes   = { "healer", "priest", },
					factions  = { "tribunal temple" },
					equipment = { "trueflame", "hopesfire" },
					companions = true,
				},				
				favorKills = {
					races            = { "imperial" },
					recordIdContains = { "_blighted", "blighted_" },
					recordIdSet      = ES.DB.actors.blighted,
					factions		= { "sixth house", "imperial cult", "imperial" }
				},				
				-- taboo kills (-10 favor + reproach)
				tabooKills = {
					recordIdContains = { "ordinator", "dagoth_ur_1", "dagoth_ur_2" }, -- those belonging to "ordinator" class
					factions = { "hands of almalexia" }
				},								
			},
			sothasil = {
				id          = "sothasil",
				name        = "Sotha Sil",				
				title       = "The Magus",
				description = "Patron of Artificers, Wizards",
				races = { "dunmer" },
				flavorText  = "Uncover the secrets of the Dwemer. Create enchanted items. Master the skills of the Mage. Slay Daedra and the hostile rogue mages who plague Morrowind. Seek knowledge. Pray at the shrines of ALMSIVI. House Telvanni is most deserving of my favor. Never openly defile the laws of Morrowind.",
				tooltipDesc = "Living god of the Tribunal Temple. The reclusive Clockwork God and master artificer, who seeks to perfect the world through reason, magic, and the lost secrets of the Dwemer.",
				-- follower + devotee ability descriptions
				followerAbility = "Become a Follower to gain Mystic's Foresight which applies Insight while any of the three Detect spells is active. The magnitude of Insight is based on your current favor.",
				devoteeAbility  = "Become a Devotee to gain Wizard's Pondering which, during prayer allows you to instantly replenish your magicka and reflect all incoming spells for 60 seconds. Costs 10% favor.",
				gift_1 = "es_tt_sothasil_g1",  -- 0.1x max magicka, +5 int
				gift_2 = "es_tt_sothasil_g2",  -- casting detect spells also puts the insight magic effect on player for the duration, magnitude is based on favor
				gift_2_alias = "Mystic's Foresight",
				gift_3 = "sothas_reflection",  -- prayer applies 100% Reflect for 60s
				gift_3_alias = "Wizard's Pondering",
				passiveRegen = {
					races     = { "dark elf" },
					classes   = { "wizard", "mage", "sorcerer", "witchhunter" },
					factions  = { "house telvanni", "mages guild", },
					equipment = { "sunder", "keening" },
					companions = true,
				},
				favorKills = {
					creatureTypes      = { "daedra" }, -- any daedra (built-in creature type)
					hostileMageClasses = true,         -- hostile magic-specialization npcs (rogue mages)
				},
				-- killing a non-hostile npc displeases the all-seeing magus
				tabooKills = {
					senselessMurder = true,
				},
				-- passive favor while exploring dwemer ruins (needs sun's dusk cell info)
				favorCells = {
					isDwemer = true,
				},					
			},
		}
	},
--[[
Almsivi welcome any who would worship them into the fold, no matter their race or previous deities.
Divine favor is slow to build, but the Divines are merciful and their faithful are unlikely to fall out of favor, 
unless they overtly commit crimes or ignore their religious duties for a long period of time.
]]
	sh = {
		name = "Sixth House",
		passiveGrowth = true,
		passiveDecay = false,
		crimePenalty = false,
	}

--[[
Most Daedric Princes only accept the worship of those they deem worthy of their attention.
Gaining favor is not too challenging, as long as one is willing to commit unsavoury acts, but favor also diminishes faster. 
As a result, prayer alone is not enough to reach devotee status and Daedra worshippers must actively follow their tenets to build up favor. 
There is no such thing as paying lip service to a Daedric Prince!
]]
}
		
-- Decay: −0.5/hr after 12+ hours of inactivity (no passive regen condition met, no prayer) -> setting with 24 by default

ES.DB.deities = {}
for pantheonId, pantheon in pairs(ES.DB.pantheon) do
	if pantheon.deities then
		for deityId, deity in pairs(pantheon.deities) do
			deity.id = deity.id or deityId
			deity.pantheonId = pantheonId
			deity.pantheon = pantheon
			ES.DB.deities[deityId] = deity
		end
	end
end