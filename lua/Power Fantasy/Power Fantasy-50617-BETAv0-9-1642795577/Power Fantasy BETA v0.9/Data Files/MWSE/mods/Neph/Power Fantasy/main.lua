dofile("Neph.Power Fantasy.config")
local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
local common = require("Neph.Power Fantasy.common")
local dunmerPowerPlayer, dunmerPowerNPC


--[[ MAGICKA EXPANDED STUFF ]]--

if framework == nil then
	local function warning()
		tes3.messageBox("Magicka Expanded framework is not installed! You will need to install it to use Power Fantasy.")
	end
	event.register("initialized", warning)
	event.register("loaded", warning)
	return
end

tes3.claimSpellEffectId("summonAncestorGuardianPlayer", 430)
tes3.claimSpellEffectId("summonAncestorGuardianNPC", 431)

local function addspellEffects()
	framework.effects.conjuration.createBasicSummoningEffect{
		id = tes3.effect.summonAncestorGuardianPlayer,
		name = "Summon Ancestor Guardian",
		description = "",
		baseCost = 0,
		creatureId = "_neph_crea_pAncGuard",
		icon = "s\\tx_s_smmn_anctlght.tga"
	}

	framework.effects.conjuration.createBasicSummoningEffect{
		id = tes3.effect.summonAncestorGuardianNPC,
		name = "Summon Ancestor Guardian",
		description = "",
		baseCost = 0,
		creatureId = "_neph_crea_npcAncGuard",
		icon = "s\\tx_s_smmn_anctlght.tga"
	}
end
event.register("magicEffectsResolved", addspellEffects)

local function createSpells(e)
	dunmerPowerPlayer = framework.spells.createBasicSpell{
		id = "_neph_race_de_pwAncGuardP",
		name = "Ancestor Guardian",
		effect = tes3.effect.summonAncestorGuardianPlayer,
		duration = 30
	}
	dunmerPowerPlayer.castType = 5
	
	dunmerPowerNPC = framework.spells.createBasicSpell{
		id = "_neph_race_de_pwAncGuardNPC",
		name = "Ancestor Guardian",
		effect = tes3.effect.summonAncestorGuardianNPC,
		duration = 30
	}
	dunmerPowerNPC.castType = 5
end
event.register("MagickaExpanded:Register", createSpells)


--[[ SETUP ]]--

local p, pMob

local function dataInit(e)

	local item
	local ref = e.reference
	local obj = ref.object
	local id = obj.id
	p = tes3.player -- mobileActivated is faster than loaded...
	pMob = tes3.mobilePlayer
	
	-- Initialize NPCs
	------------------
	if obj.objectType == tes3.objectType.npc and obj.health > 0 and not ref.disabled then
		if not ref.data.neph or not ref.data.neph[99] then
		
			ref.data.neph = {
				-- COMBAT-related
				[0] = nil,		-- Helmet
				[1] = nil,		-- Cuirass
				[2] = nil,		-- Left Pauldron
				[3] = nil,		-- Right Pauldron
				[4] = nil,		-- Greaves
				[5] = nil,		-- Boots
				[6] = nil,		-- Left Gauntlet
				[7] = nil,		-- Right Gauntlet
				[8] = nil,		-- Shield
				[9] = nil,		-- Left Bracer
				[10] = nil,		-- Right Bracer
				[11] = nil,		-- Weapon
				[12] = 0,		-- Long Blade Combo Marker
				[13] = 0,		-- Blunt Weapon Combo Marker
				[14] = 0,		-- Axe Combo Marker
				[15] = 0,		-- Marksman Combo Marker
				[16] = 0,		-- Short Blade Combo Marker
				[17] = 0,		-- Invisibility damage bonus marker
				[18] = 0,		-- Short Blade initial crit chance
				[19] = 0,		-- Light Armor 90 marker
				[20] = 0,		-- Jump/dash attack timer
				[21] = 0,		-- Sprint attack timer
				[22] = 0,		-- Medium Armor 50 timer
				[23] = 0,		-- Heavy Armor 90 timer
				[24] = 0,		-- Marksman 30 attack speed
				-- MAGIC-related
				[30] = 0,		-- Damage Health Lacerate timer
				[31] = 0,		-- Frost Chill timer
				[32] = 0,		-- Poison Weakening Timer
				[33] = 0,		-- Alteration 90 cloak timer
				-- Races & Birthsigns-related
				[50] = nil,		-- birthsign power ID
				[51] = nil, 	-- racial power ID
				[52] = 0,		-- Serpent Poison Weakness Timer
				[53] = 0,		-- Imperial allies buff timer
				[54] = 0,		-- Shadow Dark Shroud Aura timer
				[55] = 0,		-- 1s regen timer
				[56] = 0,		-- characters eligible for 1s timer
				[57] = 0,		-- Steed SPD timer
				-- major gameplay features
				[92] = 0,		-- potion limit timer
				[93] = 0,		-- after-jump attack marker
				[95] = 0,		-- knock out limit timer
				[96] = 0,		-- Knockdown timer
				[97] = 0,		-- armor weightclass sum (used for dashing)
				[98] = 0,		-- dash marker
				[99] = nil		-- NPC birthsign
			}
			
			-- Armor
			for slot in pairs(common.armorArray) do
				item = tes3.getEquippedItem{
					actor = ref,
					objectType = tes3.objectType.armor,
					slot = slot
				}
				if item then
					ref.data.neph[slot] = item.object.weightClass
				else
					ref.data.neph[slot] = -1
				end
				if ref.data.neph[slot] > 0 then
					ref.data.neph[97] = ref.data.neph[97] + ref.data.neph[slot]
				end
			end
			
			-- Weapon
			item = tes3.getEquippedItem{
				actor = ref,
				objectType = tes3.objectType.weapon
			}
			if item then
				ref.data.neph[11] = item.object.type
			else
				ref.data.neph[11] = -1
			end
			
			-- remove blacklisted spells
			for spell in pairs(obj.spells.iterator) do
				for toRemove in pairs(common.spellBlacklist) do
					if obj.spells:contains(tes3.getObject(toRemove)) then
						obj.spells:remove(tes3.getObject(toRemove))
					end
				end
			end
			
			if common.rbs then
			
				-- Dark Elf Power for NPCs
				if obj.race.id:lower() == "dark elf" then
					obj.spells:add(dunmerPowerNPC)
					ref.data.neph[51] = "_neph_race_de_pwAncGuardNPC"
				else
					-- Other racial powers
					for name, power in pairs(common.racePowers) do
						if obj.race.id:lower() == name then
							ref.data.neph[51] = power
							break
						end
					end
				end
				
				-- Imperial Coin on NPCs
				if p.object.race.id:lower() == "imperial" then
					local goldStack = obj.inventory:findItemStack(tes3.getObject("Gold_001"))
					if not goldStack or goldStack.count < math.ceil(5 + p.object.level/2) then
						tes3.addItem{
							reference = ref,
							item = "Gold_001",
							count = math.ceil(5 + p.object.level/2)
						}
					end
				end
				
				-- NPC Birthsigns
				local c = obj.class.id
				
				for bs, props in pairs(common.npcData) do
					for class in pairs(props[1]) do
						if c == class then
							for bsAbility in pairs(props[2]) do
								obj.spells:add(tes3.getObject(bsAbility))
							end
							ref.data.neph[50] = props[3]
							ref.data.neph[99] = bs
							break
						end
					end
				end
				
				-- characters eligible for 1 second timer
				if obj.race.id:lower() == "argonian" or obj.race.id:lower() == "redguard" or obj.race.id:lower() == "nord"
				or ref.data.neph[99] == "Lord" or ref.data.neph[99] == "Warrior" then
					ref.data.neph[56] = 1
				end
			else -- no races and birthsigns module
				ref.data.neph[99] = "none"
			end
			--mwse.log("refActivated NPC: %s, Birthsign: %s", ref, ref.data.neph[99])
		end
	end

	-- Initialize Creatures
	-----------------------
	if obj.objectType == tes3.objectType.creature and obj.health > 0 and not ref.disabled then
		if not ref.data.neph or not ref.data.neph[99] then
		
			ref.data.neph = {
				-- COMBAT-related
				[11] = nil,		-- Weapon
				[12] = 0,		-- Long Blade Combo Marker
				[13] = 0,		-- Blunt Weapon Combo Marker
				[14] = 0,		-- Axe Combo Marker
				[15] = 0,		-- Marksman Combo Marker
				[16] = 0,		-- Short Blade Combo Marker
				[17] = 0,		-- Invisibility damage bonus marker
				[18] = 0,		-- Short Blade initial crit chance
				[24] = 0,		-- Marksman 30 attack speed
				-- MAGIC-related
				[30] = 0,		-- Damage Health Lacerate timer
				[31] = 0,		-- Frost Chill timer
				[32] = 0,		-- Poison Weakening Timer
				[33] = 0,		-- Alteration 90 cloak timer
				-- Races & Birthsigns-related
				[52] = 0,		-- Serpent Poison Weakness timer
				[53] = 0,		-- Imperial ally buff
				-- Creature perks
				[69] = 0,		-- Creature armor base value
				[70] = 0,		-- Bonewalkers and Draugar (Heal once when on low health)
				[71] = 0,		-- Ascended Sleeper Aura timer
				[72] = false,	-- lesser Dagoths
				[73] = false,	-- higher Tenacity
				[74] = false,	-- Godly crit chance
				[75] = false,	-- Skeletal creatures
				[76] = false,	-- additional critical attack chance
				[78] = false,	-- Frost on hit
				[79] = false,	-- Knockdown on hit
				[80] = false,	-- Weaken on hit
				[81] = false,	-- Bleeding on hit
				[82] = false,	-- Poison on hit
				[83] = false,	-- additional critical spell chance
				[84] = false,	-- Ascended Sleepers
				[85] = false,	-- Trample creatures
				-- major gameplay features
				[92] = 0,		-- potion limit timer (apparently some creatures use potions, too)
				[93] = 0,		-- jump attack marker, just here to avoid errors
				[95] = 0,		-- knock out limit timer
				[96] = 0,		-- Knockdown timer
				[97] = 0,		-- Armor weightclass sum (always 0 for creatures)
				[98] = 0,		-- Dash Marker
				[99] = "none"	-- just to make scripting a bit more convenient (don't have to check for objectType everytime...)
			}

			-- Weapon
			item = tes3.getEquippedItem{
				actor = ref,
				objectType = tes3.objectType.weapon
			}
			if item then
				ref.data.neph[11] = item.object.type
			else
				ref.data.neph[11] = -3
			end
			
			if common.config.creaPerks then
			
				-- Creature Spells
				------------------
				if string.find(id, "hunger") then
					if tes3.isModActive("MDMD - Creatures Add-On.ESP") then
						obj.spells:remove(tes3.getObject("mdmd_hungerspell"))
					end
					if obj.spells:contains(tes3.getObject("paralysis")) then
						obj.spells:remove(tes3.getObject("paralysis"))
					end
					obj.spells:add(tes3.getObject("_neph_crea_hunger_Absorb"))
				end
				
				for crea, spellTable in pairs(common.creaSpells) do
					if string.find(id:lower(), crea) then
						for spell in pairs(spellTable) do
							obj.spells:add(tes3.getObject(spell))
						end
						break
					end
				end
							
				-- Creature Perks and Armor (kinda convoluted, but it works :P)
				---------------------------
				
				-- Undead self-healers
				if string.find(id, "draugr") or string.find(id, "bonewalker") then
					ref.data.neph[70] = 1
				end
				
				-- Lesser Tenacity
				if string.find(id:lower(), "dagoth") and not string.find(id, "dagoth_ur") then
					ref.data.neph[69] = 20
					ref.data.neph[72] = true
				end
				
				-- Higher Tenacity
				for crea in pairs(common.tenaciousCreatures) do
					if string.find(id:lower(), crea) then
						ref.data.neph[69] = 25
						ref.data.neph[73] = true
						break
					end
				end
				
				-- Godly crit chance
				if string.find(id, "dagoth_ur") or id == "vivec_god" or string.find(id:lower(), "almalexia") or string.find(id, "hircine") then
					ref.data.neph[74] = true
				end
				
				-- Skeletons
				for crea in pairs(common.skeletonCreatures) do
					if string.find(id, crea) then
						ref.data.neph[69] = 15
						ref.data.neph[75] = true
						break
					end
				end
				
				-- Extra critical attack chance
				if string.find(id, "dreugh") or id == "slaughterfish_hr_sfavd" or string.find(id, "golden saint") then
					ref.data.neph[76] = true
					ref.data.neph[69] = 25
				end
				
				-- Other creature perks...
				for index, group in pairs(common.creaLists) do
					for crea in pairs(group) do
						if string.find(id, crea) then
							ref.data.neph[index] = true
						end
					end
				end
				
				-- Other armor distribution...
				for crea, armor in pairs(common.creaArmor) do
					if string.find(id, crea) then
						ref.data.neph[69] = armor
						break
					end
				end
				
				-- pseudo-armor rating calculation
				if ref.data.neph[69] > 0 then
					ref.data.neph[69] = math.min(ref.data.neph[69] + 9 * ref.data.neph[69] * ref.mobile.endurance.base/100 * obj.level/35, 250)
				end
			end
		end
	end
	
	-- Initialize Player
	--------------------	
	if not p.data.neph or not p.data.neph[99] then
	
		p.data.neph = {
			-- COMBAT-related
			[0] = nil,		-- Helmet
			[1] = nil,		-- Cuirass
			[2] = nil,		-- Left Pauldron
			[3] = nil,		-- Right Pauldron
			[4] = nil,		-- Greaves
			[5] = nil,		-- Boots
			[6] = nil,		-- Left Hand
			[7] = nil,		-- Right Hand
			[8] = nil,		-- Shield
			[9] = nil,		-- Left Bracer
			[10] = nil,		-- Right Bracer
			[11] = nil,		-- Weapon
			[12] = 0,		-- Long Blade Combo Marker
			[13] = 0,		-- Blunt Weapon Combo Marker
			[14] = 0,		-- Axe Combo Marker
			[15] = 0,		-- Marksman Combo Marker
			[16] = 0,		-- Short Blade Combo Marker
			[17] = 0,		-- Invisibility damage bonus marker
			[18] = 0,		-- Short Blade initial crit chance
			[19] = 0,		-- Light Armor 90 marker
			[20] = 0,		-- Jump/Dash attack timer
			[21] = 0,		-- Sprint attack timer
			[22] = 0,		-- Medium Armor 60 timer
			[23] = 0,		-- Heavy Armor 90 timer
			[24] = 0,		-- Marksman 30 attack speed
			[25] = 0,		-- Block 90 timer (player-only)
			[26] = 0, 		-- Sneak 90 Invis Timer
			-- MAGIC-related
			[30] = 0,		-- Damage Health Lacerate timer
			[31] = 0,		-- Frost Chill timer
			[32] = 0,		-- Poison Weakening Timer
			[33] = 0,		-- Alteration 90 cloak timer
			-- Races & Birthsigns-related
			[50] = nil,		-- birthsign power ID
			[51] = nil, 	-- race power ID
			[52] = 0,		-- Serpent Poison Weakness Timer
			[53] = 0,		-- Imperial allies buff timer
			[54] = 0,		-- Shadow Dark Shroud Aura timer
			[55] = 0,		-- 1 second regen timer
			[56] = 0,		-- characters eligible for 1 second timer
			[57] = 0,		-- Steed SPD timer
			[58] = 0,		-- Khajiit Skooma stuff
			-- major gameplay features
			[91] = 0,		-- Sneak detection marker
			[92] = 0,		-- potion limit timer
			[93] = 0,		-- after-jump attack marker
			[94] = 0, 		-- pseudo-active block marker
			[95] = 0,		-- knockout limit timer
			[96] = 0,		-- Knockdown timer
			[97] = 0,		-- Armor weightclass sum (used for dashing)
			[98] = 0,		-- Dash marker
			[99] = nil		-- Birthsign
		}
		
		-- Armor
		for slot in pairs(common.armorArray) do
			item = tes3.getEquippedItem{
				actor = p,
				objectType = tes3.objectType.armor,
				slot = slot
			}
			if item then
				p.data.neph[slot] = item.object.weightClass
			else
				p.data.neph[slot] = -1
			end
			if p.data.neph[slot] > 0 then
				p.data.neph[97] = p.data.neph[97] + p.data.neph[slot]
			end
		end
		
		-- Weapon
		item = tes3.getEquippedItem{
			actor = p,
			objectType = tes3.objectType.weapon
		}
		if item then
			p.data.neph[11] = item.object.type
		else
			p.data.neph[11] = -1
		end
		
		if common.rbs then
		
			-- Birthsign Stuff
			for bsName, bsEffect in pairs(common.bsPowers) do
				if pMob:isAffectedByObject(tes3.getObject(bsEffect[2])) then
					p.data.neph[99] = bsName
					break
				end
			end
			
			-- Powers
			if p.object.race.id:lower() == "dark elf" then
				if not p.object.spells:contains(tes3.getObject("_neph_race_de_pwAncGuardP")) then
					p.object.spells:add(tes3.getObject("_neph_race_de_pwAncGuardP"))
				end
				p.data.neph[51] = "_neph_race_de_pwAncGuardP"
			else
				for name, power in pairs(common.racePowers) do
					if p.object.race.id:lower() == name then
						p.data.neph[51] = power
						break
					end
				end
			end
			for name, power in pairs(common.bsPowers) do
				if p.data.neph[99] == name then
					p.data.neph[50] = power[1]
					break
				end
			end
			
			-- Thief pickpocket GMST
			if p.data.neph[99] == "Thief" then
				tes3.findGMST("fPickPocketMod").value = 0.5
			else
				tes3.findGMST("fPickPocketMod").value = 0.3
			end
			
			-- Modified repair items
			for id, prop in pairs(common.armo_items) do
				if pMob.armorer.base >= 60 then
					tes3.getObject(id).maxCondition = prop[1]
				else
					tes3.getObject(id).maxCondition = 0.5*prop[1]
				end
				tes3.getObject(id).modified = true
			end
			if p.object.race.id:lower() == "orc" then
				local armorerFac
				if common.skills and pMob.armorer.base >= 90 then
					armorerFac = 2
				else
					armorerFac = 1
				end
				for id, prop in pairs(common.armo_items) do
					tes3.getObject(id).quality = prop[2] * armorerFac
					tes3.getObject(id).modified = true
				end
			end
			
			-- characters eligible for 1 second timer
			if p.object.race.id:lower() == "argonian" or p.object.race.id:lower() == "redguard" or p.object.race.id:lower() == "nord"
			or p.data.neph[99] == "Lord" or p.data.neph[99] == "Warrior" then
				p.data.neph[56] = 1
			end
		else
			p.data.neph[99] = "none"
		end
		--tes3.messageBox("[Player Birthsign]: %s", p.data.neph[99])
	end
end
event.register("mobileActivated", dataInit)


-- mobActivated otherwise doesn't seem to trigger on summons...
local function summonInit(e)
	for i = 1, #e.source.effects do
		if common.rbs then
			for j = 430, 431 do
				if e.source.effects[i].id == j then
					timer.start{duration = 0.1, callback = function()
						event.unregister("mobileActivated", dataInit)
						event.register("mobileActivated", dataInit)
					end}
				end
			end
		end
		for effect in pairs(common.summonID) do
			if e.source.effects[i].id == effect then
				timer.start{duration = 0.1, callback = function()
					event.unregister("mobileActivated", dataInit)
					event.register("mobileActivated", dataInit)
				end}
			end
		end
	end
end
event.register("spellCasted", summonInit)


local function onEquip(e)
	if e.item.objectType ~= tes3.objectType.armor and e.item.objectType ~= tes3.objectType.clothing and e.item.objectType ~= tes3.objectType.weapon then return end
	
	local item
	local ref = e.reference
	
	ref.data.neph[97] = 0
	if ref.object.objectType == tes3.objectType.npc then
		for slot in pairs(common.armorArray) do
			item = tes3.getEquippedItem{
				actor = ref,
				objectType = tes3.objectType.armor,
				slot = slot
			}
			if item then
				ref.data.neph[slot] = item.object.weightClass
			else
				ref.data.neph[slot] = -1
			end
			if slot ~= 8 then
				if ref.data.neph[slot] > 0 then
					ref.data.neph[97] = ref.data.neph[97] + ref.data.neph[slot]
				end
			end
		end
		item = tes3.getEquippedItem{
			actor = ref,
			objectType = tes3.objectType.weapon
		}
		if item then
			ref.data.neph[11] = item.object.type
		else
			ref.data.neph[11] = -1
		end
	end
	--if ref.data.neph[11] >= 0 then mwse.log("onEquip: %s, has Weapon", ref) else mwse.log("onEquip: %s, no Weapon", ref) end
end
event.register("equipped", onEquip)
event.register("unequipped", onEquip)


local function initialized()

	if tes3.isModActive("Power Fantasy - Core.ESP") then
	
		if tes3.isModActive("Power Fantasy - Skills.ESP") then
			print("[Power Fantasy - Skills] active.")
			common.skills = true
			
			-- New magic school distribution and icons
			for id, props in pairs(common.magicSchool) do
				if props[1] then
					tes3.getMagicEffect(id).school = props[1]
				end
				tes3.getMagicEffect(id).icon = props[2]
			end
			tes3.findGMST("fUnarmoredBase2").value = 0
		else
			print("[Power Fantasy - Skills] inactive.")
		end
		
		if tes3.isModActive("Power Fantasy - Races and Birthsigns.ESP") then
			print("[Power Fantasy - Races and Birthsigns] active.")
			tes3.getObject("ahaz").race.abilities:add(dunmerPowerPlayer) -- any other way to give spell to an entire race?
			
			-- reverting BTB change to poison :P
			tes3.getMagicEffect(27).allowSpellmaking = true
			tes3.getMagicEffect(27).allowEnchanting = true
			common.rbs = true
		else
			print("[Power Fantasy - Races and Birthsigns] inactive.")
		end
	
		dofile("Neph.Power Fantasy.damage")
		dofile("Neph.Power Fantasy.combat")
		dofile("Neph.Power Fantasy.magic")
		dofile("Neph.Power Fantasy.misc")
							
		-- GMSTs
		for gmst, value in pairs(common.GMST) do
			tes3.findGMST(gmst).value = value
		end
		
		tes3.findGMST("fKnockDownMult").value = 0.01*common.config.knockdownVars
		tes3.findGMST("iKnockDownOddsBase").value = common.config.knockdownVars
		tes3.findGMST("iKnockDownOddsMult").value = common.config.knockdownVars
		
		-- effect descriptions
		for id, desc in pairs(common.magicDesc) do
			tes3.getMagicEffect(id).description = desc
		end
		
		-- Mandatory MCP features
		if not (tes3.hasCodePatchFeature(18)
		and tes3.hasCodePatchFeature(40)
		and tes3.hasCodePatchFeature(44)
		and tes3.hasCodePatchFeature(86)
		and tes3.hasCodePatchFeature(142)) then
			tes3.messageBox("Power Fantasy Warning: Please activate mandatory Morrowind Code Patch features! See the readme or Nexus description for details.")
		end
		
		-- Check Magicka Expanded lore-friendly pack
		if lfs.fileexists("Data Files/MWSE/mods/OperatorJack/MagickaExpanded-LoreFriendlyPack/main.lua") then
			common.MEexists = true
		end
		
		print("[Power Fantasy] initialized.")
			
	else
		event.unregister("mobileActivated", dataInit)
		event.unregister("equipped", onEquip)
		event.unregister("unequipped", onEquip)
		event.unregister("spellCasted", summonInit)
		
		tes3.messageBox("Power Fantasy Warning: Core.ESP inactive! Functions have been unregistered.")
	end
end
event.register("initialized", initialized)