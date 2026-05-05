local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local ambient = require("openmw.ambient")
local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local v2 = util.vector2
local activeEffects = types.Actor.activeEffects(self)

local currentUiMode = nil
local delayedSounds = {}

-- new spells to add before jc: purify_gem ; curse_gem ; transmute_gem_gr ; transmute_gem_l
-- purify gem should level alteration and restoration
-- curse gem should level alteration and conjuration
-- fade - invulnerability, can't attack
-- banish undead // unholy creature put into statis where they can't attack or be attacked (bind undead?)
-- rewind
-- bound pickaxe
-- bound woodcutting axe

local transmuteMap = {
	["t_ingmine_oreiron_01"] = "t_ingmine_oresilver_01",
	["t_ingmine_oresilver_01"] = "t_ingmine_oregold_01",
	["t_ingmine_oregold_01"] = "t_ingmine_oreiron_01",
}

local transmuteGemMap = {
	["ingred_ruby_01"] = "t_ingmine_sapphire_01",
	["t_ingmine_sapphire_01"] = "ingred_emerald_01",
	["ingred_emerald_01"] = "t_ingmine_amethyst_01",
	["t_ingmine_amethyst_01"] = "ingred_ruby_01",
}

local transmuteTimer = nil
local skipSkillUse = false
local pendingLearnedMessage = nil

-- fortify spell definitions
local fortifySpellDefs = {
	{
		skillId = "bardcraft",
		spellId = "fortify_bc",
		effectId = "us_fortifybc",
		books = { "r_bc_songbook_int" },
		inventoryLearn = false,
		tooltip = "Teaches the spell Fortify Bardcraft.",
		learnedMessage = "You have learned the spell Fortify Bardcraft.",
		learnedSoundFile = "sound/tr/fx/tr_misc_lute.wav",
		soundDelay = 1,
	},
	{
		skillId = "SunsDusk_Cooking",
		spellId = "fortify_sd_cooking",
		effectId = "us_fortifycooking",
		books = { "sd_book_3_cook_1" },
		tooltip = "Teaches the spell Fortify Cooking.",
		learnedMessage = "You have learned the spell Fortify Cooking.",
		learnedSound = "skillraise",
	},
	{
		skillId = "mining_skill",
		spellId = "fortify_pwn_mining",
		effectId = "us_fortifymining",
		books = { "bookskill_armorer1" },
		tooltip = "Teaches the spell Fortify Mining.",
		learnedMessage = "You have learned the spell Fortify Mining.",
		learnedSound = "skillraise",
	},
	{
		skillId = "swimming_skill",
		spellId = "fortify_pwn_aquatics",
		effectId = "us_fortifyaquatics",
		books = {
			"bk_bm_aevar",
			"tr_la1_grotto_1_journal_2",
			"t_bk_traditionalsloadtaletr",
			"t_bk_caverndoortr",
			"t_bk_argonianaccountpc_v4",
			"t_bk_oldfjorithecoveshotn",
		},
		tooltip = "Teaches the spell Fortify Aquatics.",
		learnedMessage = "You have learned the spell Fortify Aquatics.",
		learnedSound = "skillraise",
	},
}

-- book recordId -> fortify def
local bookToFortifyDef = {}
for _, def in ipairs(fortifySpellDefs) do
	if def.enabled then
		for _, bookId in ipairs(def.books) do
			bookToFortifyDef[bookId:lower()] = def
--			print(bookId:lower())
		end
	end
end

local bookTooltips = nil

-- alteration cast handler
I.SkillProgression.addSkillUsedHandler(function(skillId, params)
	if not skipSkillUse and skillId == "alteration" then
		local spell = types.Player.getSelectedSpell(self)
		if spell then
			if spell.id == "transmute_ore_gr" then
				transmuteTimer = core.getRealTime() + 0.05
			end
			if spell.id == "transmute_ore_l" then
				core.sendGlobalEvent("TransmuteOre_transmute_l", {
					player = self,
				})
			end
		end
	end
end)

local function playerKnowsSpell(spellId)
	for _, spell in pairs(types.Player.spells(self)) do
		if spell.id == spellId then return true end
	end
	return false
end

local function teachFortifySpell(def)
	if playerKnowsSpell(def.spellId) then return end
	types.Player.spells(self):add(def.spellId)
	pendingLearnedMessage = def.learnedMessage
	if def.soundDelay then
		table.insert(delayedSounds, {scheduledTime = core.getRealTime() + def.soundDelay, def = def})
	else
		if def.learnedSoundFile then
			ambient.playSoundFile(def.learnedSoundFile)
		else
			ambient.playSound(def.learnedSound or "skillraise")
		end
	end
end

-- teaches spells from books
function UiModeChanged(data)
	currentUiMode = data.newMode
--	print(data.newMode, data.arg)
	-- transmute ore
	if currentUiMode == "Book" and data.arg and data.arg.recordId == "t_bk_reality&otherfalsehoodspc" then
		if not playerKnowsSpell("transmute_ore_gr") then
			types.Player.spells(self):add("transmute_ore_gr")
			pendingLearnedMessage = "You have learned the spell Transmute Ore."
			ambient.playSound("skillraise")
		end
		return
	end
	
	-- fortify custom skill books
	if currentUiMode ~= "Book" and currentUiMode ~= "Scroll" or not data.arg then return end
	
	local def = bookToFortifyDef[data.arg.recordId:lower()]
--	print(data.arg.recordId:lower(), def)
	if not def then return end
	
	teachFortifySpell(def)
end

local function onFrame(dt)
	-- pending messages
	if pendingLearnedMessage then
		ui.showMessage(pendingLearnedMessage)
		pendingLearnedMessage = nil
	end
	-- delayed sounds
	for i, task in pairs(delayedSounds) do
		if task.scheduledTime>core.getRealTime() then
			if task.def.learnedSoundFile then
				ambient.playSoundFile(task.def.learnedSoundFile)
			else
				ambient.playSound(task.def.learnedSound or "skillraise")
			end
			delayedSounds[i] = nil
		end
	end
	-- greater transmute ore raycast
	if transmuteTimer and core.getRealTime() > transmuteTimer then
		transmuteTimer = nil
		
		local ray = I.SharedRay.get()
		if not ray.hit or not ray.hitObject then return end
		if not types.Item.objectIsInstance(ray.hitObject) then return end
		
		local recordId = ray.hitObject.recordId
		local newId = transmuteMap[recordId]
		if not newId then return end
		
		local successChance = 1
		if ray.hitObject.count > 1 then
			local neededSkill = 15 + ray.hitObject.count * 10
			local mySkill = types.Player.stats.skills.alteration(self).modified
			successChance = mySkill / neededSkill -- 31 pct at 5 ores and 20 skill
		end
		local success = successChance > math.random()
		if not success then
			ui.showMessage("You failed to transmute "..ray.hitObject.count.." ores.")
			ambient.playSound("spell failure alteration")
			return
		end
		skipSkillUse = true
		I.SkillProgression.skillUsed("alteration", { skillGain = ray.hitObject.count * 2, useType = I.SkillProgression.SKILL_USE_TYPES.Spellcast_Success, scale = nil })
		skipSkillUse = false
		core.sendGlobalEvent("TransmuteOre_transmute_gr", {
			player = self,
			target = ray.hitObject,
			newRecordId = newId,
		})
		ambient.playSoundFile("sound/transmute_ore.wav")
	end
end

-- delayed registration for SkillFramework, Magic Window and Inventory Extender APIs
async:newUnsavableSimulationTimer(0.5, function()
	-- retries because other mods register skills with unknown delays
	if I.SkillFramework then
		local MAX_ATTEMPTS = 10
		local pending = #fortifySpellDefs
		
		-- main register loop
		local function tryRegister(def, attempt)
			local lookupId = def.skillId:lower()
			-- skill not available yet
			if not I.SkillFramework.getSkillRecord(lookupId) then
				if attempt >= MAX_ATTEMPTS then
					-- report missing skills after all skills were checked 10 times
					pending = pending - 1
					if pending == 0 then
						local unavailableSkills = {}
						for _, d in ipairs(fortifySpellDefs) do
							if not d.enabled then unavailableSkills[#unavailableSkills + 1] = d.skillId:lower() end
						end
						if #unavailableSkills > 0 then
							print("[Utility Spells] Gave up waiting for skills: " .. table.concat(unavailableSkills, ", ")
								.. " (" .. MAX_ATTEMPTS .. " attempts). Registered skills at this time:")
							for id in pairs(I.SkillFramework.getSkillRecords()) do
								print("  - " .. id)
							end
						end
					end
				else
					async:newUnsavableSimulationTimer(1.0, function()
						tryRegister(def, attempt + 1)
					end)
				end
			else -- found skill
				-- enable book learning
				def.enabled = true
				for _, bookId in ipairs(def.books) do
					bookToFortifyDef[bookId:lower()] = def
				end
				if bookTooltips then
					for _, bookId in ipairs(def.books) do
						bookTooltips[bookId:lower()] = {
							tooltip = def.tooltip,
							spellId = def.spellId,
						}
					end
				end
				
				-- register skill modifier based on the active effect id
				I.SkillFramework.registerDynamicModifier(lookupId, "us_fortify", function()
					return activeEffects:getEffect(def.effectId).magnitude
				end)
				pending = pending - 1
			end
		end
		
		for _, def in ipairs(fortifySpellDefs) do
			tryRegister(def, 1)
		end
	end
	
	-- magic window API
	local configPlayer = require('scripts.MagicWindowExtender.config.player')
	local API = require('openmw.interfaces').MagicWindow
	local Spells = API.Spells
	local C = API.Constants
	
	-- magic window extender custom effects
	Spells.registerEffect{
		id = "transmute_ore_effect",
		icon = "icons/s/tx_s_slowfall.dds",
		name = "Transmute Iron, Silver Ore, or Gold Ore",
		school = "alteration",
		hasDuration = false,
		hasMagnitude = false,
		isAppliedOnce = true,
		magnitudeType = C.Magic.MagnitudeDisplayType.Touch,
	}
	
	Spells.registerSpell{
		id = "transmute_ore_gr",
		effects = {
			{
				id = "transmute_ore_effect",
				effect = Spells.getCustomEffect("transmute_ore_effect"),
				magnitudeMin = 0,
				magnitudeMax = 0,
				area = 0,
				duration = 0,
				range = core.magic.RANGE.Touch,
			}
		}
	}
	
	-- lesser transmute ore
	local ok, err = pcall(function()
		Spells.registerEffect{
			id = "transmute_ore_effect_l",
			icon = "icons/s/tx_s_slowfall.dds",
			name = "Transmute Iron or Silver Ore",
			school = "alteration",
			hasDuration = false,
			hasMagnitude = false,
			isAppliedOnce = true,
			magnitudeType = C.Magic.MagnitudeDisplayType.Touch,
		}
		
		Spells.registerSpell{
			id = "transmute_ore_l",
			effects = {
				{
					id = "transmute_ore_effect_l",
					effect = Spells.getCustomEffect("transmute_ore_effect_l"),
					magnitudeMin = 0,
					magnitudeMax = 0,
					area = 0,
					duration = 0,
					range = core.magic.RANGE.Self,
				}
			}
		}
	end)
	
	if not ok then
		print("Failed to register spells with Magic Window Extender: " .. tostring(err))
	end
	
	-- inventory extender tooltip
	if not I.InventoryExtender then
		print("InventoryExtender not found - tooltip integration disabled")
		return
	end
	
	local BASE = I.InventoryExtender.Templates.BASE
	local constants = I.InventoryExtender.Constants
	
	local COLORS = {
		LABEL = (constants and constants.Colors and constants.Colors.DISABLED) or util.color.rgb(0.6, 0.6, 0.6),
		MAGIC = util.color.rgb(0.7, 0.5, 0.9),
		KNOWN = util.color.rgb(0.5, 0.9, 0.5),
		UNREAD = util.color.rgb(0.8, 0.3, 0.3),
	}
	
	-- book recordId -> { tooltip, spellId }
	bookTooltips = {
		["t_bk_reality&otherfalsehoodspc"] = {
			tooltip = "Teaches the spell Greater Transmute Ore.",
			spellId = "transmute_ore_gr",
		},
	}
	I.InventoryExtender.registerTooltipModifier("UtilitySpells_Books", function(item, layout)
		local entry = bookTooltips[item.recordId:lower()]
		if not entry then return layout end
	
		local ok, content = pcall(function()
			return layout.content[1].content[1].content
		end)
		if not ok or not content then return layout end
	
		content:add(BASE.intervalV(8))
		content:add({ template = I.MWUI.templates.horizontalLine, props = { size = v2(200, 2) } })
		content:add(BASE.intervalV(4))
	
		-- teaches x spell
		content:add({
			template = BASE.textNormal,
			props = {
				text = entry.tooltip,
				textColor = COLORS.MAGIC,
				multiline = true,
				textAlignH = ui.ALIGNMENT.Center,
			},
		})
		
		content:add(BASE.intervalV(2))
	
		-- known / unread indicator
		local known = playerKnowsSpell(entry.spellId)
		content:add({
			template = BASE.textNormal,
			props = {
				text = known and "Known" or "Unread",
				textColor = known and COLORS.KNOWN or COLORS.UNREAD,
				multiline = true,
				textAlignH = ui.ALIGNMENT.Center,
			},
		})
		return layout
	end)

end)

-- pet scrib
function scribActivated(scrib)
	if not I.TRSpells then return end
	saveData.pettedScribs =saveData.pettedScribs + 1
	if saveData.pettedScribs >= 5 and not playerKnowsSpell("us_summon_scrib") then
		types.Player.spells(self):add("us_summon_scrib")
		pendingLearnedMessage = "You have learned how to Summon Scrib."
		ambient.playSound("skillraise")			
	end	
end

local function onLoad(data)
	saveData = data or {}
	saveData.pettedScribs = saveData.pettedScribs or 0
end

local function onSave(data)
	return saveData
end

return {
	engineHandlers = {
		onFrame = onFrame,
		onLoad = onLoad,
		onInit = onLoad,
		onSave = onSave
	},
	eventHandlers = {
		UiModeChanged = UiModeChanged,
		US_scribActivated = scribActivated,		
	}
}