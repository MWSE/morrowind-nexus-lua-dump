I = require("openmw.interfaces")
async = require('openmw.async')
local time = require('openmw_aux.time')
local core = require("openmw.core")
local types = require('openmw.types')
local self = require('openmw.self')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local util = require('openmw.util')
local v2 = util.vector2
local skills = types.NPC.stats.skills
local attributes = types.Actor.stats.attributes
local activeSpells = types.Actor.activeSpells(self)
local activeSpellCount = -1
local handleAbilityBuffs

MOD_NAME = "AbiliesAreModifiers"
playerSection = storage.playerSection("Settings"..MOD_NAME)
--hasNCG = core.contentFiles.has("ncgdmw.omwscripts") or core.contentFiles.has("ncg.omwscripts")
--if hasNCG then
--	ui.showMessage("You are using AbilitiesAreModifiers with NCG(D). Good luck.")
--	print("You are using AbilitiesAreModifiers with NCG(D). Good luck.")
--end

local attrCache = {}
for name, _ in pairs(attributes) do
	attrCache[name] = attributes[name](self)
end

local skillCache = {}
for name, _ in pairs(skills) do
	skillCache[name] = skills[name](self)
end

local lastSkillMismatch = {}
local lastAttrMismatch = {}

local externalModifiers = {} -- { [modName] = { [stat] = amount } }
local externalModifierTotals = {} -- merged

local function i1(n)
	if n == math.floor(n) then
        return string.format("%d", n)
    else
        return string.format("%.1f", n)
    end
end

local function dbg(...)
	if S_DEBUG then
		print(...)
	end
end

local settingsTemplate = {
	key = "Settings" .. MOD_NAME,
	l10n = "none",
	name = "Settings",
	page = MOD_NAME,
	description = "",
	permanentStorage = true,
	settings = {
		{
			key = "ENABLED",
			name = "Enable",
			description = "Enable or disable the ability buff handling system\nUse before uninstalling",
			default = true,
			renderer = "checkbox",
		},
		{
			key = "DEBUG",
			name = "Debug Mode",
			description = "Print debug information to console",
			default = false,
			renderer = "checkbox",
		},
		{
			key = "WARNINGS",
			name = "Warn About Irregularities",
			description = "Show warnings when modifier values don't match expected ability buffs",
			default = true,
			renderer = "checkbox",
		},
		{
			key = "AUTOFIX",
			name = "Auto-Fix Modifier Mismatches",
			description = "Automatically compensate when modifier values don't match expected ability buffs",
			default = false,
			renderer = "checkbox",
		},
		{
			key = "RACIAL_BIRTHSIGN_ONLY",
			name = "Innate Abilities Only",
			description = "Only convert racial, birthsign, and whitelisted abilities to modifiers\nOther abilities (like sun's dusk buffs) remain as base stat changes",
			default = true,
			renderer = "checkbox",
		},
		{
			key = "SHOW_STATS",
			name = "Show Stat Breakdown in Tooltips",
			description = "Show base, modifier and damage values in attribute and skill tooltips\nRequires Stats Window Extender",
			default = true,
			renderer = "checkbox",
		},
		{
			key = "SHOW_SOURCES",
			name = "Show Modifier Sources in Tooltips",
			description = "Show where modifiers come from (abilities, items, buffs)\nRequires Stats Window Extender",
			default = true,
			renderer = "checkbox",
		},
	}
}

I.Settings.registerGroup(settingsTemplate)

I.Settings.registerPage {
	key = MOD_NAME,
	l10n = "none",
	name = MOD_NAME,
	description = ""
}

-- Cache settings into locals
local S_ENABLED = true
local S_DEBUG = false
local S_WARNINGS = true
local S_AUTOFIX = true
local S_RACIAL_BIRTHSIGN_ONLY = false
local S_SHOW_STATS = true
local S_SHOW_SOURCES = false

local function readAllSettings()
	for _, entry in pairs(settingsTemplate.settings) do
		local value = playerSection:get(entry.key)
		if value == nil then
			value = entry.default
		end
		_G["S_"..entry.key] = value
	end
	S_ENABLED = _G["S_ENABLED"]
	S_DEBUG = _G["S_DEBUG"]
	S_WARNINGS = _G["S_WARNINGS"]
	S_AUTOFIX = _G["S_AUTOFIX"]
	S_RACIAL_BIRTHSIGN_ONLY = _G["S_RACIAL_BIRTHSIGN_ONLY"]
	S_SHOW_STATS = _G["S_SHOW_STATS"]
	S_SHOW_SOURCES = _G["S_SHOW_SOURCES"]
end

readAllSettings()


playerSection:subscribe(async:callback(function(_, setting)
	local value = playerSection:get(setting)
	if value == nil then
		for _, entry in pairs(settingsTemplate.settings) do
			if entry.key == setting then
				value = entry.default
				break
			end
		end
	end
	_G["S_"..setting] = value
	S_ENABLED = _G["S_ENABLED"]
	S_DEBUG = _G["S_DEBUG"]
	S_WARNINGS = _G["S_WARNINGS"]
	S_AUTOFIX = _G["S_AUTOFIX"]
	S_RACIAL_BIRTHSIGN_ONLY = _G["S_RACIAL_BIRTHSIGN_ONLY"]
	S_SHOW_STATS = _G["S_SHOW_STATS"]
	S_SHOW_SOURCES = _G["S_SHOW_SOURCES"]
	activeSpellCount = -1
	lastSkillMismatch = {}
	lastAttrMismatch = {}
	
	if setting == "ENABLED" then
		if not S_ENABLED then
			undoAdjustments()
		else
			handleAbilityBuffs()
		end
	end
	if setting == "AUTOFIX" and S_AUTOFIX then
		handleAbilityBuffs()
	end
	if setting == "RACIAL_BIRTHSIGN_ONLY" then
		undoAdjustments()
		handleAbilityBuffs()
	end
end))

-- Relevance cache: spellId -> 0 (irrelevant), 1 (fortify), 2 (drain), 3 (both)
local spellRelevanceCache = {}

local racialBirthsignSpells = {
	["disenchanting_expertise_1"]   = true,
	["disenchanting_expertise_2"]   = true,
	["disenchanting_expertise_4"]   = true,
	["disenchanting_expertise_8"]   = true,
	["disenchanting_expertise_16"]  = true,
	["disenchanting_expertise_32"]  = true,
	["disenchanting_expertise_64"]  = true,
	["disenchanting_expertise_128"] = true,
	["roguelite_jack"]        = true, -- FortifySkill +8-9 on 10 misc skills (permanent)
	["roguelite_sneak"]       = true, -- FortifySkill Sneak +5 (permanent)
	--["roguelite_swift_feet"]  = true, -- FortifySkill Athletics +20, FortifyAttribute Speed +20 (ONLY OUT OF COMBAT) (removed during level up)
}

local ABILITY_TYPE = core.magic.SPELL_TYPE.Ability

-- filter all racial ability spells
for _, raceRecord in pairs(types.NPC.races.records) do
	if raceRecord.spells then
		for _, spell in pairs(raceRecord.spells) do
			local id = type(spell) == "string" and spell or spell.id
			local rec = core.magic.spells.records[id]
			if rec and rec.type == ABILITY_TYPE then
				racialBirthsignSpells[id] = true
			end
		end
	end
end

-- filter all birthsign ability spells
for _, bsRecord in pairs(types.Player.birthSigns.records) do
	if bsRecord.spells then
		for _, spell in pairs(bsRecord.spells) do
			local id = type(spell) == "string" and spell or spell.id
			local rec = core.magic.spells.records[id]
			if rec and rec.type == ABILITY_TYPE then
				racialBirthsignSpells[id] = true
			end
		end
	end
end

local function getSpellRelevance(spell)
	local id = spell.id
	local cached = spellRelevanceCache[id]
	if cached ~= nil then return cached end

	local source = core.magic.spells.records[id] or types.Potion.records[id]

	-- Enchanted item (equipped)
	if not source and spell.item then
		local enchantId = spell.item.type.record(spell.item).enchant or ""
		source = core.magic.enchantments.records[enchantId]
	end

	-- Scroll (item may already be consumed)
	if not source then
		local bookRecord = types.Book.records[id]
		if bookRecord then
			local enchantId = bookRecord.enchant or ""
			source = core.magic.enchantments.records[enchantId]
		end
	end

	local hasFortify, hasDrain = false, false
	if source then
		for _, eff in pairs(source.effects) do
			if eff.id == "fortifyattribute" or eff.id == "fortifyskill" then
				hasFortify = true
			elseif eff.id == "drainattribute" or eff.id == "drainskill" then
				hasDrain = true
			end
			if hasFortify and hasDrain then break end
		end
	else
		hasFortify, hasDrain = true, true
	end

	local result = (hasFortify and 1 or 0) + (hasDrain and 2 or 0)
	spellRelevanceCache[id] = result
	return result
end



local function warn(...)
	if S_WARNINGS then
		print(...)
	end
end

local function buildStatString(a)
	return i1(a.base).." + "..i1(a.modifier).." - "..i1(math.abs(a.damage))
end

local function view(t, depth)
	depth = depth or 0
	local depthStr = ""
	for i=1, depth do
		depthStr = depthStr.."   "
	end
	for a,b in pairs(t) do
		local formatted = tostring(b)
		if type(b) == "string" then
			formatted = '"'..b..'"'
		end
		if type(b) == "table" then
			formatted = "table"
		end
		print(depthStr..a.." = "..formatted)
		if type(b) == "table" then
			view(b, depth+1)
		end
	end

end

function undoAdjustments()
	dbg("Undoing adjustments...")
	
	for skill, adjustment in pairs(saveData.skillAdjustments or {}) do
		local stat = skillCache[skill]
		local baseBefore = stat.base
		local modifierBefore = stat.modifier
		stat.base = stat.base + adjustment
		stat.modifier = stat.modifier - adjustment
		dbg(skill..": "..baseBefore.."+"..modifierBefore.." -> "..stat.base.."+"..stat.modifier)
	end
	
	for attr, adjustment in pairs(saveData.attributeAdjustments or {}) do
		local stat = attrCache[attr]
		local baseBefore = stat.base
		local modifierBefore = stat.modifier
		stat.base = stat.base + adjustment
		stat.modifier = stat.modifier - adjustment
		dbg(attr..": "..baseBefore.."+"..modifierBefore.." -> "..stat.base.."+"..stat.modifier)
	end
	
	saveData.skillAdjustments = {}
	saveData.attributeAdjustments = {}
	lastSkillMismatch = {}
	lastAttrMismatch = {}
end

local lastDbgHash = 0

function handleAbilityBuffs()
	if not S_ENABLED then
		return
	end
	-- rebuild external modifier cache if dirty
	if not externalModifierTotals then
		externalModifierTotals = {}
		for _, modData in pairs(externalModifiers) do
			for stat, amount in pairs(modData) do
				externalModifierTotals[stat] = (externalModifierTotals[stat] or 0) + amount
			end
		end
	end
	local skillBuffs = {}
	local attributeBuffs = {}
	local skillOtherModifiers = {}
	local attributeOtherModifiers = {}
	local dbgStr  = S_DEBUG and "" or nil
	local dbgHash = S_DEBUG and 0  or nil
	
	for spellInstance, spellData in pairs(activeSpells) do
		if getSpellRelevance(spellData) % 2 == 0 then goto continueSpell end
		-- filter non-innate abilities
		local isAbility = spellData.affectsBaseValues
		if isAbility and S_RACIAL_BIRTHSIGN_ONLY and not racialBirthsignSpells[spellData.id] then
			isAbility = false
		end
		if isAbility then
			for effectIndex, effect in pairs(spellData.effects) do
				if effect.id == "fortifyattribute" then
					local attr = effect.affectedAttribute
					if attr and attr ~= "endurance" then
						attributeBuffs[attr] = (attributeBuffs[attr] or 0) + effect.magnitudeThisFrame
						if dbgStr then
							local line = spellData.id..": "..attr.." +"..effect.magnitudeThisFrame
							dbgStr = dbgStr.."\n"..line
							--for i = 1, #line do dbgHash = dbgHash + line:byte(i) end
							dbgHash = dbgHash
								+ #spellData.id * 1009
								+ attr:byte(1) * 37
								+ (attr:byte(2) or 0)
								+ math.floor(effect.magnitudeThisFrame)
						end
					end
				elseif effect.id == "fortifyskill" then
					local skill = effect.affectedSkill
					if skill then
						skillBuffs[skill] = (skillBuffs[skill] or 0) + effect.magnitudeThisFrame
						if dbgStr then
							local line = spellData.id..": "..skill.." +"..effect.magnitudeThisFrame
							dbgStr = dbgStr.."\n"..line
							--for i = 1, #line do dbgHash = dbgHash + line:byte(i) end
							dbgHash = dbgHash
								+ #spellData.id * 1009
								+ skill:byte(1) * 37
								+ (skill:byte(2) or 0)
								+ math.floor(effect.magnitudeThisFrame)
						end
					end
				end
			end
		elseif not spellData.affectsBaseValues then -- might be a non-innate ability
			for effectIndex, effect in pairs(spellData.effects) do
				if effect.id == "fortifyattribute" then
					local attr = effect.affectedAttribute
					if attr then
						attributeOtherModifiers[attr] = (attributeOtherModifiers[attr] or 0) + effect.magnitudeThisFrame
					end
				elseif effect.id == "fortifyskill" then
					local skill = effect.affectedSkill
					if skill then
						skillOtherModifiers[skill] = (skillOtherModifiers[skill] or 0) + effect.magnitudeThisFrame
					end
				end
			end
			
		end
		::continueSpell::
	end
	-- only print ability list when it changes
	if dbgStr and dbgHash ~= lastDbgHash then
		lastDbgHash = dbgHash
		print(dbgStr)
	end
	
	for skill in pairs(saveData.skillAdjustments) do
		skillBuffs[skill] = skillBuffs[skill] or 0
	end
	for attr in pairs(saveData.attributeAdjustments) do
		attributeBuffs[attr] = attributeBuffs[attr] or 0
	end
	
	
	for skill, buffMagnitude in pairs(skillBuffs) do
		local stat = skillCache[skill]
		local currentAdjustment = saveData.skillAdjustments[skill] or 0
		local neededAdjustment = buffMagnitude
		
		if currentAdjustment ~= neededAdjustment then
			local adjustmentDelta = neededAdjustment - currentAdjustment
			
			local baseBefore = stat.base
			local modifierBefore = stat.modifier
			
			stat.base = baseBefore - adjustmentDelta
			stat.modifier = modifierBefore + adjustmentDelta
			
			saveData.skillAdjustments[skill] = neededAdjustment
			
			dbg(skill..": "..baseBefore.."+"..modifierBefore.." -> "..stat.base.."+"..stat.modifier)
		end
		
		-- warnings and autofix:
		local finalAdjustment = saveData.skillAdjustments[skill] or 0
		local externalTotal = externalModifierTotals[skill] or 0
		local expectedModifier = math.max(0, finalAdjustment + (skillOtherModifiers[skill] or 0) + externalTotal)
		if expectedModifier > 0 and stat.modifier ~= expectedModifier then
			local shortfall = expectedModifier - stat.modifier
			local oldStr = buildStatString(skillCache[skill])
			if S_AUTOFIX then
				stat.modifier = stat.modifier + shortfall
				lastSkillMismatch[skill] = nil
				if S_WARNINGS then
					local newStr = buildStatString(skillCache[skill])
					warn("[AAM] Fixed "..skill.." mismatch: "..oldStr.." -> "..newStr)
					ui.showMessage("[AAM] Fixed "..skill.." mismatch: \n"..oldStr.." -> "..newStr)
				end
			elseif lastSkillMismatch[skill] ~= shortfall then
				lastSkillMismatch[skill] = shortfall
				if S_WARNINGS then
					warn("[AAM] "..skill.." mismatch: "..oldStr.." (expected modifier "..i1(expectedModifier)..")")
					ui.showMessage("[AAM] "..skill.." mismatch: \n"..oldStr.." (expected modifier "..i1(expectedModifier)..")")
				end
			end
		else
			lastSkillMismatch[skill] = nil
		end
	end
	
	for attr, buffMagnitude in pairs(attributeBuffs) do
		local stat = attrCache[attr]
		local currentAdjustment = saveData.attributeAdjustments[attr] or 0
		local neededAdjustment = buffMagnitude
		
		if currentAdjustment ~= neededAdjustment then
			local adjustmentDelta = neededAdjustment - currentAdjustment
			
			local baseBefore = stat.base
			local modifierBefore = stat.modifier
			
			stat.base = baseBefore - adjustmentDelta
			stat.modifier = modifierBefore + adjustmentDelta
			
			saveData.attributeAdjustments[attr] = neededAdjustment
			
			dbg(attr..": "..baseBefore.."+"..modifierBefore.." -> "..stat.base.."+"..stat.modifier)
		end
		
		-- warnings and autofix:
		local finalAdjustment = saveData.attributeAdjustments[attr] or 0
		local externalTotal = externalModifierTotals[attr] or 0
		local expectedModifier = math.max(0, finalAdjustment + (attributeOtherModifiers[attr] or 0) + externalTotal)
		if expectedModifier > 0 and stat.modifier ~= expectedModifier then
			local shortfall = expectedModifier - stat.modifier
			local oldStr = buildStatString(attrCache[attr])
			if S_AUTOFIX then
				stat.modifier = stat.modifier + shortfall
				lastAttrMismatch[attr] = nil
				if S_WARNINGS then
					local newStr = buildStatString(attrCache[attr])
					warn("[AAM] Fixed "..attr.." mismatch: "..oldStr.." -> "..newStr)
					ui.showMessage("[AAM] Fixed "..attr.." mismatch: \n"..oldStr.." -> "..newStr)
				end
			elseif lastAttrMismatch[attr] ~= shortfall then
				lastAttrMismatch[attr] = shortfall
				if S_WARNINGS then
					warn("[AAM] "..attr.." mismatch: "..oldStr.." (expected modifier "..i1(expectedModifier)..")")
					ui.showMessage("[AAM] "..attr.." mismatch: \n"..oldStr.." (expected modifier "..i1(expectedModifier)..")")
				end
			end
		else
			lastAttrMismatch[attr] = nil
		end
	end
end


local function getModifierSources(statType, statName)
	local field = statType == "attribute" and "affectedAttribute" or "affectedSkill"
	local fortifyId = statType == "attribute" and "fortifyattribute" or "fortifyskill"
	local drainId = statType == "attribute" and "drainattribute" or "drainskill"
	local sources = {
		fortify_abilities = 0, drain_abilities = 0,
		fortify_abilities_base = 0, drain_abilities_base = 0,
		fortify_items = 0, drain_items = 0,
		fortify_buffs = 0, drain_buffs = 0,
	}
	for s, spellData in pairs(activeSpells) do
		if getSpellRelevance(spellData) == 0 then goto continueSource end
		for _, effect in pairs(spellData.effects) do
			if effect[field] == statName then
				local category
				if spellData.affectsBaseValues then
					-- converted abilities show as modifiers, unconverted stay as base
					if S_RACIAL_BIRTHSIGN_ONLY and not racialBirthsignSpells[spellData.id] then
						category = "abilities_base"
					else
						category = "abilities"
					end
				elseif spellData.fromEquipment and not effect.duration then
					category = "items"
				else
					category = "buffs"
				end
				if effect.id == fortifyId and effect.magnitudeThisFrame ~= 0 then
					sources["fortify_"..category] = sources["fortify_"..category] + effect.magnitudeThisFrame
				elseif effect.id == drainId and effect.magnitudeThisFrame ~= 0 then
					sources["drain_"..category] = sources["drain_"..category] + effect.magnitudeThisFrame
				end
			end
		end
		::continueSource::
	end
	-- stuff other mods reported
	for modName, data in pairs(externalModifiers) do
		if data[statName] and data[statName] ~= 0 then
			sources["external_"..modName] = data[statName]
		end
	end
	return sources
end

local tooltipsInitialized = false
local function setupTooltips()
	if tooltipsInitialized then return end
	if not I.StatsWindow then return end
	if not S_SHOW_STATS then return end
	tooltipsInitialized = true

	local API = I.StatsWindow
	local BASE = API.Templates.BASE
	local STATS = API.Templates.STATS
	local C = API.Constants

	local function buildSourceLines(sources)
		local lines = {}
		local posHex = C.Colors.POSITIVE:asHex()
		local negHex = C.Colors.DAMAGED:asHex()
		local defHex = C.Colors.DEFAULT:asHex()
		local lightHex = C.Colors.DEFAULT_LIGHT:asHex()
		for _, entry in ipairs({
			-- converted abilities: modifier colors
			{ category = "abilities",      label = S_RACIAL_BIRTHSIGN_ONLY and "From innate abilities" or "From abilities" },
			-- unconverted abilities: neutral color (still base values)
			{ category = "abilities_base", label = "From other abilities", fortifyColor = defHex },
			{ category = "items",          label = "From items" },
			{ category = "buffs",          label = "From buffs" },
		}) do
			local fort = sources["fortify_"..entry.category] or 0
			local drain = sources["drain_"..entry.category] or 0
			if fort ~= 0 or drain ~= 0 then
				local text = ""..entry.label..":"
				if fort ~= 0 then
					text = text.." #"..(entry.fortifyColor or posHex).."+"..i1(fort)
				end
				if drain ~= 0 then
					text = text.." #"..negHex.."-"..i1(drain)
				end
				text = text.."#"..defHex
				table.insert(lines, {
					template = BASE.textNormal,
					props = {
						text = text,
						textSize = STATS.TEXT_SIZE,
					}
				})
			end
		end
		-- External modifier sources (from other mods)
		for key, amount in pairs(sources) do
			local modName = key:match("^external_(.+)$")
			if modName and amount ~= 0 then
				local color = amount > 0 and posHex or negHex
				local sign = amount > 0 and "+" or "-"
				local text = modName..": #"..color..sign..i1(math.abs(amount)).."#"..defHex
				table.insert(lines, {
					template = BASE.textNormal,
					props = {
						text = text,
						textSize = STATS.TEXT_SIZE,
					}
				})
			end
		end
		return lines
	end

	-- Attribute tooltips
	for name, _ in pairs(attributes) do
		API.modifyLine(name, {
			tooltip = function()
				local attrRecord = core.stats.Attribute.records[name]
				local stat = attrCache[name]

				local titleText = attrRecord.name
				if S_SHOW_STATS then
					local headerHex = C.Colors.DEFAULT_LIGHT:asHex()
					titleText = titleText .. "  #" .. C.Colors.DEFAULT:asHex() .. i1(stat.base)
					if stat.modifier ~= 0 then
						local modColor = stat.modifier > 0 and C.Colors.POSITIVE or C.Colors.DAMAGED
						local sign = stat.modifier > 0 and "+" or "-"
						titleText = titleText .. " #" .. modColor:asHex() .. sign .. " " .. i1(math.abs(stat.modifier))
					end
					if stat.damage ~= 0 then
						titleText = titleText .. " #" .. C.Colors.DAMAGED:asHex() .. "- " .. i1(stat.damage)
					end
					titleText = titleText .. "#" .. headerHex
				end

				local result = STATS.tooltip(4, ui.content {
					{
						name = 'tooltip',
						type = ui.TYPE.Flex,
						content = ui.content {
							{
								name = 'headerRow',
								type = ui.TYPE.Flex,
								props = { horizontal = true, arrange = ui.ALIGNMENT.Center },
								content = ui.content {
									{
										name = 'icon',
										props = { size = v2(32, 32) },
										content = ui.content {
											{
												name = 'bgr',
												type = ui.TYPE.Image,
												props = {
													relativeSize = v2(1, 1),
													resource = ui.texture { path = attrRecord.icon },
												}
											},
										}
									},
									BASE.padding(4),
									{
										name = 'titleFlex',
										type = ui.TYPE.Flex,
										content = ui.content {
											{
												name = 'title',
												template = BASE.textHeader,
												props = { text = titleText }
											},
										}
									},
								},
							},
							BASE.padding(4),
							{
								template = BASE.textParagraph,
								props = {
									size = v2(400, 0),
									text = attrRecord.description,
									autoSize = true,
								}
							},
						},
					},
				})

				if S_SHOW_SOURCES then
					local sources = getModifierSources("attribute", name)
					local sourceLines = buildSourceLines(sources)
					if #sourceLines > 0 then
						local content = result.content[1].content.tooltip.content
						content:add(BASE.padding(4))
						for _, line in ipairs(sourceLines) do
							content:add(line)
						end
					end
				end

				return result
			end,
		})
	end

	-- Skill tooltips: wrap the LineBuilder since skills aren't registered as named lines
	local originalSkillBuilder = API.LineBuilders.SKILL
	API.LineBuilders.SKILL = function(skillId)
		local line = originalSkillBuilder(skillId)
		if not S_SHOW_STATS then return line end

		local originalTooltip = line.tooltip
		line.tooltip = function()
			local base = originalTooltip()
			local titleFlex = base.content[1].content.tooltip.content.headerRow.content.titleFlex
			local titleEl = titleFlex.content.title

			local stat = skillCache[skillId]
			local headerHex = titleEl.props.textColor
					and titleEl.props.textColor:asHex()
					or (titleEl.template and titleEl.template.props and titleEl.template.props.textColor
					and titleEl.template.props.textColor:asHex())
					or "DFCAaF"

			local text = titleEl.props.text .. "  #" .. C.Colors.DEFAULT:asHex() .. i1(stat.base)
			if stat.modifier ~= 0 then
				local modColor = stat.modifier > 0 and C.Colors.POSITIVE or C.Colors.DAMAGED
				local sign = stat.modifier > 0 and "+" or "-"
				text = text .. " #" .. modColor:asHex() .. sign .. " " .. i1(math.abs(stat.modifier))
			end
			if stat.damage ~= 0 then
				text = text .. " #" .. C.Colors.DAMAGED:asHex() .. "- " .. i1(stat.damage)
			end
			text = text .. "#" .. headerHex

			titleEl.props.text = text

			if S_SHOW_SOURCES then
				local sources = getModifierSources("skill", skillId)
				local sourceLines = buildSourceLines(sources)
				if #sourceLines > 0 then
					local content = base.content[1].content.tooltip.content
					content:add(BASE.padding(4))
					for _, srcLine in ipairs(sourceLines) do
						content:add(srcLine)
					end
				end
			end

			return base
		end
		return line
	end
	
	-- delayed:
	async:newUnsavableSimulationTimer(1, function()
		if not I.SkillFramework then return end

		local origSkillTooltipBuilder = API.TooltipBuilders.SKILL
		API.TooltipBuilders.SKILL = function(params)
			local ok, result = pcall(origSkillTooltipBuilder, params)
			if not ok or not result then return result end
			if not S_SHOW_STATS or not params or not params.title then return result end

			-- find matching skill by title
			local sfRecords = I.SkillFramework.getSkillRecords()
			if not sfRecords then return result end
			local matchedId = nil
			for id, rec in pairs(sfRecords) do
				if rec and rec.name == params.title then
					matchedId = id
					break
				end
			end
			if not matchedId then return result end

			local stat = I.SkillFramework.getSkillStat(matchedId)
			if not stat or stat.base == nil then return result end

			-- add breakdown to title
			local modOk, modErr = pcall(function()
				local titleFlex = result.content[1].content.tooltip.content.headerRow.content.titleFlex
				local titleEl = titleFlex.content.title
				local headerHex = titleEl.props.textColor
					and titleEl.props.textColor:asHex()
					or (titleEl.template and titleEl.template.props and titleEl.template.props.textColor
					and titleEl.template.props.textColor:asHex())
					or "DFCAaF"

				local text = titleEl.props.text .. "  #" .. C.Colors.DEFAULT:asHex() .. i1(stat.base)
				if stat.modifier and stat.modifier ~= 0 then
					local modColor = stat.modifier > 0 and C.Colors.POSITIVE or C.Colors.DAMAGED
					local sign = stat.modifier > 0 and "+" or "-"
					text = text .. " #" .. modColor:asHex() .. sign .. " " .. i1(math.abs(stat.modifier))
				end
				text = text .. "#" .. headerHex
				titleEl.props.text = text
			end)
			if not modOk then
				print("ERROR: [AbiliesAreModifiers] Skill Framework modification failed for "..params.title..": "..tostring(modErr))
			end

			return result
		end
	end)
end


local function getActiveSpellCount()
	local count = 0
	for _, sp in pairs(activeSpells) do
		if sp.affectsBaseValues then
			count = count + 1
		end
	end
	return count
end


local function onFrame(dt)
	if I.PrettyStats and I.PrettyStats.disableAAM then return end
	handleAbilityBuffs()
end


local function onLoad(data)
	if not data then
		dbg("Initializing AbiliesAreModifiers...")
	end
	saveData = data or {}
	saveData.skillAdjustments = saveData.skillAdjustments or {}
	saveData.attributeAdjustments = saveData.attributeAdjustments or {}
	--dbg("AAM current:")
	--for a,b in pairs(attrCache) do
	--	dbg(a.." = "..(saveData.attributeAdjustments[a]or 0).." :: "..buildStatString(attrCache[a]))
	--end
	--dbg("-------")
	--handleAbilityBuffs()
	--activeSpellCount = getActiveSpellCount()
	setupTooltips()
	
	--if not hasNCG then
		--print("doesnt have ncg")
		stopTimerFn = time.runRepeatedly(onFrame, 1.5 * time.second, {
			type = time.SimulationTime,
			initialDelay = 0.1 * time.second
		})
	--else
	--	local ncgIndex, selfIndex
	--	for i, file in pairs(core.contentFiles.list) do
	--		local lower = file:lower()
	--		if lower == "ncgdmw.omwscripts" or lower == "ncg.omwscripts" then
	--			ncgIndex = i
	--		elseif lower == "abilitiesaremodifiers.omwscripts" then
	--			selfIndex = i
	--		end
	--	end
	--	if ncgIndex and selfIndex and ncgIndex < selfIndex then
	--		--f knows what the correct load order is
	--	else
	--		--f knows what the correct load order is
	--	end
	--end
end


local function onSave()
	return saveData
end

return {
	interfaceName = "AAM",
	interface = {
		version = 1,
		-- lets other mods read AAM's current base->modifier adjustments
		getAdjustments = function()
			if not S_ENABLED then return nil, nil end
			return saveData.attributeAdjustments, saveData.skillAdjustments
		end,
		-- lets other mods tell us about modifier changes they made
		-- modName: your mod's name
		-- data: flat table of { [statName] = amount }, positive = buff, negative = nerf
		-- call with {} or nil to clear
		reportExternalModifiers = function(modName, data)
			externalModifiers[modName] = data
			externalModifierTotals = nil
		end,
	},
	engineHandlers = {
		onInit = onLoad,
		onLoad = onLoad,
		onSave = onSave,
		--onFrame = hasNCG and onFrame or nil,
	}
}