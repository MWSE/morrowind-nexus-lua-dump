local ui    = require("openmw.ui")
local util  = require("openmw.util")
local self  = require("openmw.self")
local types = require("openmw.types")
local core  = require("openmw.core")
local auxUi = require("openmw_aux.ui")
local time  = require("openmw_aux.time")

--------------------------------------------------
-- DISPLAY NAMES
--------------------------------------------------
local ATTR_NAMES = {}
local ATTR_KEYS  = {}
for _, rec in pairs(core.stats.Attribute.records) do
	ATTR_NAMES[rec.id] = rec.name
	ATTR_KEYS[#ATTR_KEYS + 1] = rec.id
end
table.sort(ATTR_KEYS)

local SKILL_NAMES = {}
local SKILL_KEYS  = {}
for _, rec in pairs(core.stats.Skill.records) do
	SKILL_NAMES[rec.id] = rec.name
	SKILL_KEYS[#SKILL_KEYS + 1] = rec.id
end
table.sort(SKILL_KEYS)

--------------------------------------------------
-- CACHED STAT OBJECTS
--------------------------------------------------
local ATTR_STAT = {}
for _, key in ipairs(ATTR_KEYS) do ATTR_STAT[key] = types.Actor.stats.attributes[key](self) end
local SKILL_STAT = {}
for _, key in ipairs(SKILL_KEYS) do SKILL_STAT[key] = types.NPC.stats.skills[key](self) end
local activeSpells = types.Actor.activeSpells(self)

--------------------------------------------------
-- TEXTURE CACHE
--------------------------------------------------
local textureCache = {}
local function getTexture(path)
	if not textureCache[path] then
		textureCache[path] = ui.texture { path = path }
	end
	return textureCache[path]
end

--------------------------------------------------
-- ACTIVE SPELL EFFECT FILTERS
--------------------------------------------------
-- Effect type constants for direct comparison
local FORTIFY_ATTR  = core.magic.EFFECT_TYPE.FortifyAttribute
local DRAIN_ATTR    = core.magic.EFFECT_TYPE.DrainAttribute
local FORTIFY_SKILL = core.magic.EFFECT_TYPE.FortifySkill
local DRAIN_SKILL   = core.magic.EFFECT_TYPE.DrainSkill

--------------------------------------------------
-- SPELL RELEVANCE CACHE
--------------------------------------------------
local RELEVANT_EFFECTS = {
	[FORTIFY_ATTR]  = true,
	[DRAIN_ATTR]    = true,
	[FORTIFY_SKILL] = true,
	[DRAIN_SKILL]   = true,
}
local spellRelevanceCache = {}

local function isSpellRelevant(spell)
	local id = spell.id
	local cached = spellRelevanceCache[id]
	if cached ~= nil then return cached end

	local source = core.magic.spells.records[id] or types.Potion.records[id]
	
	-- probably from an enchantment
	if not source and spell.item then
		local enchantId = spell.item.type.record(spell.item).enchant or ""
		source = core.magic.enchantments.records[enchantId]
	end
	
	-- probably from a scroll (item is gone already)
	if not source then
		local bookRecord = types.Book.records[spell.id]
		if bookRecord then
			local enchantId = bookRecord.enchant or ""
			source = core.magic.enchantments.records[enchantId]
		end
	end
	
	local relevant = false
	if source then
		for _, eff in pairs(source.effects) do
			if RELEVANT_EFFECTS[eff.id] then
				relevant = true
				break
			end
		end
	else
		relevant = true
		print("[PrettyStats] unknown source of spell", spell, spell.id)
	end

	spellRelevanceCache[id] = relevant
	return relevant
end

--------------------------------------------------
-- SPELL CONTRIBUTION SNAPSHOT
-- Iterates activeSpells and sums per-effect magnitudes.
-- Fortify: goes to base or modifier (depends on affectsBaseValues).
-- Drain:   always goes to damage.
-- Scanned when stats change with a timer as backup.
--------------------------------------------------
local ZERO_BUCKET = { mod = 0, base = 0, dmg = 0 }  -- shared read-only fallback
local contribA = { attributes = {}, skills = {} }
local contribB = { attributes = {}, skills = {} }
for _, key in ipairs(ATTR_KEYS) do
	contribA.attributes[key] = { mod = 0, base = 0, dmg = 0 }
	contribB.attributes[key] = { mod = 0, base = 0, dmg = 0 }
end
for _, key in ipairs(SKILL_KEYS) do
	contribA.skills[key] = { mod = 0, base = 0, dmg = 0 }
	contribB.skills[key] = { mod = 0, base = 0, dmg = 0 }
end
local currentSpellContrib  = contribA
local previousSpellContrib = contribB
local spellContribReady    = false
local spellTimerRunning    = false

local function computeSpellContributions()
	-- Swap: previous <-> current, then overwrite current
	currentSpellContrib, previousSpellContrib = previousSpellContrib, currentSpellContrib
	local contrib = currentSpellContrib

	-- Reset all buckets to zero
	for _, key in ipairs(ATTR_KEYS) do
		local b = contrib.attributes[key]
		b.mod, b.base, b.dmg = 0, 0, 0
	end
	for _, key in ipairs(SKILL_KEYS) do
		local b = contrib.skills[key]
		b.mod, b.base, b.dmg = 0, 0, 0
	end

	for _, spell in pairs(activeSpells) do
		if isSpellRelevant(spell) then
		local affectsBase = spell.affectsBaseValues
		for _, eff in pairs(spell.effects) do
			local id  = eff.id
			local mag = eff.magnitudeThisFrame

			if id == FORTIFY_ATTR then
				local bucket = contrib.attributes[eff.affectedAttribute or ""]
				if bucket then
					if affectsBase then bucket.base = bucket.base + mag
					else bucket.mod = bucket.mod + mag end
				end

			elseif id == DRAIN_ATTR then
				local bucket = contrib.attributes[eff.affectedAttribute or ""]
				if bucket then bucket.dmg = bucket.dmg + mag end

			elseif id == FORTIFY_SKILL then
				local bucket = contrib.skills[eff.affectedSkill or ""]
				if bucket then
					if affectsBase then bucket.base = bucket.base + mag
					else bucket.mod = bucket.mod + mag end
				end

			elseif id == DRAIN_SKILL then
				local bucket = contrib.skills[eff.affectedSkill or ""]
				if bucket then bucket.dmg = bucket.dmg + mag end
			end
		end
		end
	end
end

local stopSpellScanFn = nil

local function stopSpellTimer()
	spellTimerRunning = false
	spellContribReady = false
	if stopSpellScanFn then
		stopSpellScanFn()
		stopSpellScanFn = nil
	end
end

local function startSpellTimer()
	if spellTimerRunning then return end
	spellTimerRunning = true
	computeSpellContributions()
	spellContribReady = true
	stopSpellScanFn = time.runRepeatedly(computeSpellContributions,
		0.5 * time.second, { initialDelay = 0.5 * time.second })
end

_G.PS_syncSpellTimer = function()
	local needTimer = PS_ignoreActiveSpells or PS_spellTexture
	if needTimer and not spellTimerRunning then
		startSpellTimer()
	elseif not needTimer and spellTimerRunning then
		stopSpellTimer()
	end
end


--------------------------------------------------
-- VISUALS
--------------------------------------------------
local BG_BASE   = "textures/PrettyStats/popup_bg.dds"
local BG_MAGIC  = "textures/PrettyStats/popup_magic_bg.dds"
local BG_DAMAGE = "textures/PrettyStats/popup_damage_bg.dds"
local BG_SPELL  = "textures/PrettyStats/popup_spell_bg.dds"

--------------------------------------------------
-- COLORS
--------------------------------------------------
local COLOR_INCREASE = util.color.hex("B8E18C")  -- soft green
local COLOR_DECREASE = util.color.hex("F2665A")  -- soft red
local COLOR_NEUTRAL  = util.color.hex("999999")  -- grey
local COLOR_MIXED    = util.color.hex("F2CC4D")  -- amber/yellow

-- Per-column color: normal sign (base, modifier)
local function valColor(n)
	if n > 0 then return COLOR_INCREASE end
	if n < 0 then return COLOR_DECREASE end
	return COLOR_NEUTRAL
end

-- Per-column color: damage (inverted)
local function dmgColor(dmgDelta)
	if dmgDelta > 0 then return COLOR_DECREASE end  -- damage dealt
	if dmgDelta < 0 then return COLOR_INCREASE end  -- damage restored
	return COLOR_NEUTRAL
end

--------------------------------------------------
-- SHARED HELPERS
--------------------------------------------------
local function round(n)
	if n >= 0 then return math.floor(n + 0.5) end
	return math.ceil(n - 0.5)
end

local function netDelta(baseDelta, modDelta, dmgDelta)
	return baseDelta + modDelta - dmgDelta
end

-- Color for net delta (simple mode)
local function netColor(n)
	if n > 0 then return COLOR_INCREASE end
	if n < 0 then return COLOR_DECREASE end
	return COLOR_NEUTRAL
end

--------------------------------------------------
-- TEXT BUILDER
--------------------------------------------------
local function fmtVal(n)
	n = round(n)
	if n == 0 then return "0" end
	return (n > 0 and "+" or "") .. n
end

-- Damage is displayed sign-inverted: dealt damage shows negative, restored shows positive
local function fmtDmg(dmgDelta)
	local display = round(-dmgDelta)
	if display == 0 then return "0" end
	return (display > 0 and "+" or "") .. display
end

local function getPopupColor(baseDelta, modDelta, dmgDelta)
	local hasBenefit = baseDelta > 0 or modDelta > 0 or dmgDelta < 0
	local hasHarm    = baseDelta < 0 or modDelta < 0 or dmgDelta > 0
	if hasBenefit and hasHarm then return COLOR_MIXED end
	local net = baseDelta + modDelta - dmgDelta
	if net > 0 then return COLOR_INCREASE end
	if net < 0 then return COLOR_DECREASE end
	return COLOR_NEUTRAL
end

-- Pick background by most "dramatic" change present (currently the same textures)
local function getPopupBg(baseDelta, modDelta, dmgDelta)
	if dmgDelta ~= 0 then return BG_DAMAGE end
	if modDelta ~= 0 then return BG_MAGIC end
	return BG_BASE
end

--------------------------------------------------
-- STATE
--------------------------------------------------
local activeRows     = {}
local popupQueue     = {}
local survivorRows   = {}
local scrollOffset   = 0
local conveyorActive = false
local holdStartTime  = nil
local frameCounter   = 0

--------------------------------------------------
-- SNAPSHOT (ping-pong)
--------------------------------------------------
local NUM_ATTRS  = #ATTR_KEYS
local NUM_SKILLS = #SKILL_KEYS
local NUM_STATS  = NUM_ATTRS + NUM_SKILLS

local snapA = { attributes = {}, skills = {} }
local snapB = { attributes = {}, skills = {} }
for _, key in ipairs(ATTR_KEYS) do
	snapA.attributes[key] = { base = 0, modifier = 0, damage = 0 }
	snapB.attributes[key] = { base = 0, modifier = 0, damage = 0 }
end
for _, key in ipairs(SKILL_KEYS) do
	snapA.skills[key] = { base = 0, modifier = 0, damage = 0 }
	snapB.skills[key] = { base = 0, modifier = 0, damage = 0 }
end
local currentSnap = snapA
local lastSnap    = snapB

-- Fill both snapshots identically (used at init / onLoad)
local function snapshotAll()
	for _, key in ipairs(ATTR_KEYS) do
		local stat = ATTR_STAT[key]
		local a, b = currentSnap.attributes[key], lastSnap.attributes[key]
		a.base = stat.base;  a.modifier = stat.modifier;  a.damage = stat.damage
		b.base = stat.base;  b.modifier = stat.modifier;  b.damage = stat.damage
	end
	for _, key in ipairs(SKILL_KEYS) do
		local stat = SKILL_STAT[key]
		local a, b = currentSnap.skills[key], lastSnap.skills[key]
		a.base = stat.base;  a.modifier = stat.modifier;  a.damage = stat.damage
		b.base = stat.base;  b.modifier = stat.modifier;  b.damage = stat.damage
	end
end

--------------------------------------------------
-- QUEUE
--------------------------------------------------
local function isRowEmpty(row)
	if row.baseDelta == 0 and row.modDelta == 0 and row.dmgDelta == 0 then return true end
	if PS_displayMode == "Simple" and netDelta(row.baseDelta, row.modDelta, row.dmgDelta) == 0 then return true end
	return false
end

local function addToQueue(statKey, displayName, baseDelta, modDelta, dmgDelta, category, isSpellChange, currentValue)
	if baseDelta == 0 and modDelta == 0 and dmgDelta == 0 then return end

	local mergeId = isSpellChange and (statKey .. ":spell") or statKey

	local scanWindow = PS_scanFrames

	-- Try merge into active on-screen row
	for ri = 1, #activeRows do
		local row = activeRows[ri]
		if row.mergeId == mergeId and not row.fadingOut then
			row.baseDelta = row.baseDelta + baseDelta
			row.modDelta  = row.modDelta  + modDelta
			row.dmgDelta  = row.dmgDelta  + dmgDelta
			if currentValue then row.currentValue = currentValue end
			if isRowEmpty(row)
			   and (frameCounter - (row.birthFrame or 0)) <= PS_scanFrames then
				if row.element then auxUi.deepDestroy(row.element) end
				table.remove(activeRows, ri)
			else
				row.textColor    = getPopupColor(row.baseDelta, row.modDelta, row.dmgDelta)
				row.needsRebuild = true
				row.spawnTime    = core.getRealTime()
				row.mergedAt     = row.spawnTime
				row.fadingOut    = false
			end
			return
		end
	end

	-- Try merge into survivor row
	for ri = 1, #survivorRows do
		local row = survivorRows[ri]
		if row.mergeId == mergeId and not row.fadingOut then
			row.baseDelta = row.baseDelta + baseDelta
			row.modDelta  = row.modDelta  + modDelta
			row.dmgDelta  = row.dmgDelta  + dmgDelta
			if currentValue then row.currentValue = currentValue end
			if isRowEmpty(row)
			   and (frameCounter - (row.birthFrame or 0)) <= PS_scanFrames then
				if row.element then auxUi.deepDestroy(row.element) end
				table.remove(survivorRows, ri)
				for sj, s in ipairs(survivorRows) do
					s.targetY = -(sj + 1) * (PS_spacing * PS_uiScaleFactor)
				end
			else
				row.textColor    = getPopupColor(row.baseDelta, row.modDelta, row.dmgDelta)
				row.needsRebuild = true
				row.spawnTime    = core.getRealTime()
				row.mergedAt     = row.spawnTime
				row.fadingOut    = false
			end
			return
		end
	end

	-- Try merge into queued entry
	for i, d in ipairs(popupQueue) do
		if d.mergeId == mergeId then
			d.baseDelta = d.baseDelta + baseDelta
			d.modDelta  = d.modDelta  + modDelta
			d.dmgDelta  = d.dmgDelta  + dmgDelta
			if currentValue then d.currentValue = currentValue end
			d.mergedAt  = core.getRealTime()
			if isRowEmpty(d)
			   and (frameCounter - (d.birthFrame or 0)) <= PS_scanFrames then
				table.remove(popupQueue, i)
			end
			return
		end
	end

	-- New entry
	table.insert(popupQueue, {
		mergeId       = mergeId,
		statKey       = statKey,
		displayName   = displayName,
		baseDelta     = baseDelta,
		modDelta      = modDelta,
		dmgDelta      = dmgDelta,
		currentValue  = currentValue,
		category      = category,
		isSpellChange = isSpellChange or false,
		birthFrame    = frameCounter,
	})
end

--------------------------------------------------
-- STAT SCANNING (windowed across PS_scanFrames)
-- Frames 0..readDivisor-1: fill chunks into currentSnap
-- Final frame: spell compute (if needed) + diff + queue + swap
-- readDivisor = divisor normally, max(1, divisor-1) when filtering spells
--------------------------------------------------
local scanCursor = 0

local function scanStats()
	if not PS_enabled then return end
	local wantSpellCompute = PS_ignoreActiveSpells or PS_spellTexture
	local readDivisor = wantSpellCompute and math.max(1, PS_scanFrames - 1) or PS_scanFrames
	local isReadFrame = scanCursor < readDivisor
	local isDiffFrame = scanCursor == PS_scanFrames - 1

	-- READ: fill a chunk of stat values into currentSnap
	if isReadFrame then
		local chunkSize = math.ceil(NUM_STATS / readDivisor)
		local startIdx  = scanCursor * chunkSize + 1
		local endIdx    = math.min(startIdx + chunkSize - 1, NUM_STATS)

		for i = startIdx, endIdx do
			if i <= NUM_ATTRS then
				local key  = ATTR_KEYS[i]
				local stat = ATTR_STAT[key]
				local s    = currentSnap.attributes[key]
				s.base     = stat.base
				s.modifier = stat.modifier
				s.damage   = stat.damage
			else
				local key  = SKILL_KEYS[i - NUM_ATTRS]
				local stat = SKILL_STAT[key]
				local s    = currentSnap.skills[key]
				s.base     = stat.base
				s.modifier = stat.modifier
				s.damage   = stat.damage
			end
		end
	end

	-- DIFF + QUEUE: only on the final frame of the cycle
	if isDiffFrame then
		local filterSpells = false
		local splitSpells  = false
		if PS_ignoreActiveSpells then
			computeSpellContributions()
			filterSpells = spellContribReady
			spellContribReady = true
		elseif PS_spellTexture then
			computeSpellContributions()
			splitSpells = spellContribReady
			spellContribReady = true
		end

		-- Attributes
		if PS_showAttributes ~= false then
			for _, key in ipairs(ATTR_KEYS) do
				local old = lastSnap.attributes[key]
				local new = currentSnap.attributes[key]
				local baseDiff = new.base     - old.base
				local modDiff  = new.modifier - old.modifier
				local dmgDiff  = new.damage   - old.damage

				-- Current effective value for Simple display
				local stat   = ATTR_STAT[key]
				local curVal = round(stat.base + stat.modifier - stat.damage)

				if filterSpells then
					local cur  = currentSpellContrib.attributes[key] or ZERO_BUCKET
					local prev = previousSpellContrib.attributes[key] or ZERO_BUCKET
					baseDiff = baseDiff - (cur.base - prev.base)
					modDiff  = modDiff  - (cur.mod  - prev.mod)
					dmgDiff  = dmgDiff  - (cur.dmg  - prev.dmg)
					if baseDiff ~= 0 or modDiff ~= 0 or dmgDiff ~= 0 then
						addToQueue(key, ATTR_NAMES[key], baseDiff, modDiff, dmgDiff, "attribute", false, curVal)
					end
				elseif splitSpells then
					local cur  = currentSpellContrib.attributes[key] or ZERO_BUCKET
					local prev = previousSpellContrib.attributes[key] or ZERO_BUCKET
					local spBase = cur.base - prev.base
					local spMod  = cur.mod  - prev.mod
					local spDmg  = cur.dmg  - prev.dmg
					local natBase = baseDiff - spBase
					local natMod  = modDiff  - spMod
					local natDmg  = dmgDiff  - spDmg
					if natBase ~= 0 or natMod ~= 0 or natDmg ~= 0 then
						addToQueue(key, ATTR_NAMES[key], natBase, natMod, natDmg, "attribute", false, curVal)
					end
					if spBase ~= 0 or spMod ~= 0 or spDmg ~= 0 then
						addToQueue(key, ATTR_NAMES[key], spBase, spMod, spDmg, "attribute", true, curVal)
					end
				else
					if baseDiff ~= 0 or modDiff ~= 0 or dmgDiff ~= 0 then
						addToQueue(key, ATTR_NAMES[key], baseDiff, modDiff, dmgDiff, "attribute", false, curVal)
					end
				end
			end
		end

		-- Skills
		if PS_showSkills ~= false then
			for _, key in ipairs(SKILL_KEYS) do
				local old = lastSnap.skills[key]
				local new = currentSnap.skills[key]
				local baseDiff = new.base     - old.base
				local modDiff  = new.modifier - old.modifier
				local dmgDiff  = new.damage   - old.damage

				-- Current effective value for Simple display
				local stat   = SKILL_STAT[key]
				local curVal = round(stat.base + stat.modifier - stat.damage)

				if filterSpells then
					local cur  = currentSpellContrib.skills[key] or ZERO_BUCKET
					local prev = previousSpellContrib.skills[key] or ZERO_BUCKET
					baseDiff = baseDiff - (cur.base - prev.base)
					modDiff  = modDiff  - (cur.mod  - prev.mod)
					dmgDiff  = dmgDiff  - (cur.dmg  - prev.dmg)
					if baseDiff ~= 0 or modDiff ~= 0 or dmgDiff ~= 0 then
						addToQueue(key, SKILL_NAMES[key], baseDiff, modDiff, dmgDiff, "skill", false, curVal)
					end
				elseif splitSpells then
					local cur  = currentSpellContrib.skills[key] or ZERO_BUCKET
					local prev = previousSpellContrib.skills[key] or ZERO_BUCKET
					local spBase = cur.base - prev.base
					local spMod  = cur.mod  - prev.mod
					local spDmg  = cur.dmg  - prev.dmg
					local natBase = baseDiff - spBase
					local natMod  = modDiff  - spMod
					local natDmg  = dmgDiff  - spDmg
					if natBase ~= 0 or natMod ~= 0 or natDmg ~= 0 then
						addToQueue(key, SKILL_NAMES[key], natBase, natMod, natDmg, "skill", false, curVal)
					end
					if spBase ~= 0 or spMod ~= 0 or spDmg ~= 0 then
						addToQueue(key, SKILL_NAMES[key], spBase, spMod, spDmg, "skill", true, curVal)
					end
				else
					if baseDiff ~= 0 or modDiff ~= 0 or dmgDiff ~= 0 then
						addToQueue(key, SKILL_NAMES[key], baseDiff, modDiff, dmgDiff, "skill", false, curVal)
					end
				end
			end
		end

		-- Swap: lastSnap becomes the one we just filled
		currentSnap, lastSnap = lastSnap, currentSnap
	end

	scanCursor = (scanCursor + 1) % PS_scanFrames
end

--------------------------------------------------
-- SPAWN ROW
--------------------------------------------------
local function spawnRow(data, baseX, baseY, scale)
	local isRight  = PS_posX > 0.5
	local isSimple = PS_displayMode == "Simple"

	local color = getPopupColor(data.baseDelta, data.modDelta, data.dmgDelta)
	local bg    = getPopupBg(data.baseDelta, data.modDelta, data.dmgDelta)

	-- Skip zero rows
	if not PS_showZeroRows then
		if isSimple then
			if netDelta(data.baseDelta, data.modDelta, data.dmgDelta) == 0 then return nil end
		else
			if data.baseDelta == 0 and data.modDelta == 0 and data.dmgDelta == 0 then return nil end
		end
	end

	local contentItems = {
		{   -- tinted background
			name = "bg",
			type = ui.TYPE.Image,
			props = {
				resource     = getTexture(bg),
				relativeSize = util.vector2(1, 1),
				color        = util.color.rgba(color.r, color.g, color.b, 0.25),
				alpha        = PS_showBackground and 1 or 0,
			},
		},
	}

	-- spell overlay (untinted) -- only for spell-sourced changes
	if data.isSpellChange then
		contentItems[#contentItems + 1] = {
			type = ui.TYPE.Image,
			props = {
				resource     = getTexture(BG_SPELL),
				relativeSize = util.vector2(1, 1),
				alpha = PS_showBackground and 0.9 or 0,
			},
		}
	end

	if isSimple then
		-- Simple mode
		local net      = netDelta(data.baseDelta, data.modDelta, data.dmgDelta)
		local simColor = netColor(net)
		local text     = " " .. data.displayName .. " " .. fmtVal(net)
		if data.currentValue ~= nil then
			text = text .. " (" .. data.currentValue .. ")"
		end

		-- override bg tint with net-based color
		contentItems[1].props.color = util.color.rgba(simColor.r, simColor.g, simColor.b, 0.25)
		color = simColor

		contentItems[#contentItems + 1] = {
			name = "label",
			type = ui.TYPE.Text,
			props = {
				text             = text,
				textSize         = PS_fontScale,
				textColor        = simColor,
				textShadow       = true,
				position         = util.vector2(4, 0),
				relativePosition = util.vector2(0, 0.5),
				anchor           = util.vector2(0, 0.5),
			},
		}
	else
		-- Detailed mode
		local COL_BASE = 175
		local COL_MOD  = COL_BASE + 30
		local COL_DMG  = COL_MOD  + 30

		contentItems[#contentItems + 1] = {
			name = "name",
			type = ui.TYPE.Text,
			props = {
				text             = " " .. data.displayName,
				textSize         = PS_fontScale,
				textColor        = color,
				textShadow       = true,
				position         = util.vector2(4, 0),
				relativePosition = util.vector2(0, 0.5),
				anchor           = util.vector2(0, 0.5),
			},
		}
		contentItems[#contentItems + 1] = {
			name = "base",
			type = ui.TYPE.Text,
			props = {
				text             = fmtVal(data.baseDelta),
				textSize         = PS_fontScale,
				textColor        = valColor(data.baseDelta),
				textShadow       = true,
				position         = util.vector2(COL_BASE, 0),
				relativePosition = util.vector2(0, 0.5),
				anchor           = util.vector2(0.5, 0.5),
				textAlignH       = ui.ALIGNMENT.Start,
			},
		}
		contentItems[#contentItems + 1] = {
			name = "mod",
			type = ui.TYPE.Text,
			props = {
				text             = fmtVal(data.modDelta),
				textSize         = PS_fontScale,
				textColor        = valColor(data.modDelta),
				textShadow       = true,
				position         = util.vector2(COL_MOD, 0),
				relativePosition = util.vector2(0, 0.5),
				anchor           = util.vector2(0.5, 0.5),
				textAlignH       = ui.ALIGNMENT.Start,
			},
		}
		contentItems[#contentItems + 1] = {
			name = "dmg",
			type = ui.TYPE.Text,
			props = {
				text             = fmtDmg(data.dmgDelta),
				textSize         = PS_fontScale,
				textColor        = dmgColor(data.dmgDelta),
				textShadow       = true,
				position         = util.vector2(COL_DMG, 0),
				relativePosition = util.vector2(0, 0.5),
				anchor           = util.vector2(0.5, 0.5),
				textAlignH       = ui.ALIGNMENT.Start,
			},
		}
	end

	local contentElement = ui.create {
		type = ui.TYPE.Widget,
		props = {
			relativeSize = util.vector2(1, 1),
		},
		content = ui.content(contentItems),
	}

	-- Outer wrapper - position/alpha
	local slideStart = isRight and 300 or -300
	local element = ui.create {
		layer = "HUD",
		props = {
			relativePosition = util.vector2(baseX, baseY),
			anchor   = util.vector2(isRight and 1 or 0, 0),
			size     = util.vector2(350, 26),
			alpha    = 1.0,
			position = util.vector2(slideStart * scale, 0),
		},
		content = ui.content {
			contentElement,
		},
	}

	return {
		element        = element,
		contentElement = contentElement,
		mergeId        = data.mergeId,
		statKey        = data.statKey,
		displayName    = data.displayName,
		baseDelta      = data.baseDelta,
		modDelta       = data.modDelta,
		dmgDelta       = data.dmgDelta,
		currentValue   = data.currentValue,
		category       = data.category,
		isSpellChange  = data.isSpellChange or false,
		mergedAt       = data.mergedAt,
		birthFrame     = data.birthFrame or frameCounter,
		spawnTime      = core.getRealTime(),
		fadeInTime     = core.getRealTime(),
		textColor      = color,
		slideOffX      = slideStart,
		needsRebuild   = false,
		fadingOut      = false,
		lastAlpha      = 1.0,
		lastPosX       = slideStart * scale,
		lastSlotY      = 0,
		lastBaseX      = baseX,
		lastBaseY      = baseY,
	}
end

--------------------------------------------------
-- REBUILD ROW — hot-update content after merge
--------------------------------------------------
local function rebuildRow(row)
	if not (row.contentElement and row.contentElement.layout) then
		row.needsRebuild = false
		return
	end

	local content = row.contentElement.layout.content

	if PS_displayMode == "Simple" then
		local net      = netDelta(row.baseDelta, row.modDelta, row.dmgDelta)
		local simColor = netColor(net)
		local text     = " " .. row.displayName .. " " .. fmtVal(net)
		if row.currentValue ~= nil then
			text = text .. " (" .. row.currentValue .. ")"
		end

		row.textColor = simColor
		content["bg"].props.color          = util.color.rgba(simColor.r, simColor.g, simColor.b, 0.25)
		content["label"].props.text        = text
		content["label"].props.textColor   = simColor
	else
		local color = getPopupColor(row.baseDelta, row.modDelta, row.dmgDelta)
		row.textColor = color

		content["bg"].props.color        = util.color.rgba(color.r, color.g, color.b, 0.25)
		content["name"].props.textColor  = color
		content["base"].props.text       = fmtVal(row.baseDelta)
		content["base"].props.textColor  = valColor(row.baseDelta)
		content["mod"].props.text        = fmtVal(row.modDelta)
		content["mod"].props.textColor   = valColor(row.modDelta)
		content["dmg"].props.text        = fmtDmg(row.dmgDelta)
		content["dmg"].props.textColor   = dmgColor(row.dmgDelta)
	end

	row.contentElement:update()
	row.needsRebuild = false
end

--------------------------------------------------
-- POSITION HELPER
--------------------------------------------------
local function getBasePosition()
	local baseX = PS_posX
	local baseY = PS_posY
	return baseX, baseY
end

--------------------------------------------------
-- FLAT INIT (settings already loaded before require)
--------------------------------------------------
snapshotAll()
if PS_ignoreActiveSpells or PS_spellTexture then startSpellTimer() end

--------------------------------------------------
-- ENGINE
--------------------------------------------------
return {
	engineHandlers = {
		onLoad = function(data)
			snapshotAll()
			scanCursor = 0
			for _, r in ipairs(activeRows) do
				if r.element then auxUi.deepDestroy(r.element) end
			end
			for _, r in ipairs(survivorRows) do
				if r.element then auxUi.deepDestroy(r.element) end
			end
			activeRows     = {}
			survivorRows   = {}
			popupQueue     = {}
			scrollOffset   = 0
			conveyorActive = false
			holdStartTime  = nil
		end,

		onFrame = function(dt)
			if not PS_enabled then return end

			frameCounter = frameCounter + 1
			scanStats()

			local spacingScaled = PS_spacing * PS_uiScaleFactor

			local baseX, baseY = getBasePosition()
			local now          = core.getRealTime()
			local realDt       = core.getRealFrameDuration()

			-- Early-out
			if #activeRows == 0 and #popupQueue == 0 and #survivorRows == 0 then
				holdStartTime = nil
				return
			end

			------------------------------------------------
			-- FILL EMPTY SLOTS
			------------------------------------------------
			while #activeRows < PS_maxOnScreen and #popupQueue > 0 do
				local data = table.remove(popupQueue, 1)
				if PS_showZeroRows or data.baseDelta ~= 0 or data.modDelta ~= 0 or data.dmgDelta ~= 0 then
					local row = spawnRow(data, baseX, baseY, PS_uiScaleFactor)
					if row then
						table.insert(activeRows, row)
					end
				end
			end

			------------------------------------------------
			-- CONVEYOR LOGIC
			------------------------------------------------
			local screenFull = #activeRows >= PS_maxOnScreen
			local hasQueued  = #popupQueue > 0

			if screenFull and hasQueued and not holdStartTime then
				holdStartTime = now
			end

			if holdStartTime and hasQueued and (now - holdStartTime >= PS_holdtime) then
				conveyorActive = true
			end

			if not hasQueued and conveyorActive then
				conveyorActive = false
				holdStartTime  = nil
			end
		
			if conveyorActive then
				scrollOffset = scrollOffset + PS_conveyorSpeed * 7 * realDt

				if scrollOffset >= spacingScaled then
					scrollOffset = scrollOffset - spacingScaled

					if #activeRows > 0 then
						local ejected = table.remove(activeRows, 1)
						local age = now - (ejected.spawnTime or now)
						if ejected.toBeSurvivor then
							-- Still has lifetime and was updated: promote to survivor
							ejected.currentY = -scrollOffset - spacingScaled
							table.insert(survivorRows, 1, ejected)
							for si, s in ipairs(survivorRows) do
								s.targetY = -(si + 1) * spacingScaled
							end
						else
							if ejected.element then 
								auxUi.deepDestroy(ejected.element) 
							end
						end
					end

					if #popupQueue > 0 then
						local data = table.remove(popupQueue, 1)
						if PS_showZeroRows or data.baseDelta ~= 0 or data.modDelta ~= 0 or data.dmgDelta ~= 0 then
							local row = spawnRow(data, baseX, baseY, PS_uiScaleFactor)
							if row then
								table.insert(activeRows, row)
							end
						end
					end

					if #popupQueue == 0 then
						conveyorActive = false
						holdStartTime  = nil
						scrollOffset   = 0
					end
				end
			end

			------------------------------------------------
			-- IDLE FADE
			------------------------------------------------
			if not conveyorActive and #activeRows > 0 and #popupQueue == 0 then
				if not holdStartTime then
					holdStartTime = now
				end
			end

			------------------------------------------------
			-- RENDER ALL ROWS
			------------------------------------------------
			for i, row in ipairs(activeRows) do
				if row.needsRebuild then
					rebuildRow(row)
				end

				local slotY = (i - 1) * spacingScaled - scrollOffset

				if row.slideOffX ~= 0 then
					local decay = math.min(1, PS_slideSpeed * realDt)
					row.slideOffX = row.slideOffX * (1 - decay)
					if math.abs(row.slideOffX) < 1 then row.slideOffX = 0 end
				end

				local alpha = 1.0

				if conveyorActive then
					if row.fadingOut then
						-- Row was already fading when conveyor started; continue fade
						local age = now - (row.spawnTime or now)
						if age > PS_rowLifetime then
							alpha = 1.0 - ((age - PS_rowLifetime) / PS_fadeDuration)
						end
					elseif i == 1 then
						local age = now - (row.spawnTime or now)
						if (PS_forceConveyorEnd and not row.mergedAt or age >= PS_rowLifetime) and not row.toBeSurvivor then
							-- No merge-extended lifetime: fade as it scrolls off
							local fadeZone  = spacingScaled * 0.6
							local fadeStart = spacingScaled - fadeZone
							if scrollOffset > fadeStart then
								alpha = 1.0 - ((scrollOffset - fadeStart) / fadeZone)
							end
						else
							row.toBeSurvivor = true
						end
					end
				else
					if #popupQueue == 0 or row.fadingOut then
						local age = now - (row.spawnTime or now)
						if age > PS_rowLifetime then
							alpha = 1.0 - ((age - PS_rowLifetime) / PS_fadeDuration)
							row.fadingOut = true
						end
					end
				end

				alpha = math.max(0, math.min(1, alpha))

				-- Fade in
				if PS_fadeInDuration > 0 then
					local fadeInAge = now - (row.fadeInTime or now)
					if fadeInAge < PS_fadeInDuration then
						alpha = alpha * (fadeInAge / PS_fadeInDuration)
					end
				end

				local posX = row.slideOffX * PS_uiScaleFactor
				local needsWrapperUpdate = false

				if math.abs(alpha - row.lastAlpha) > 0.005 then
					needsWrapperUpdate = true
				end
				if math.abs(posX - row.lastPosX) >= 0.5 then
					needsWrapperUpdate = true
				end
				if math.abs(slotY - row.lastSlotY) >= 0.5 then
					needsWrapperUpdate = true
				end
				if baseX ~= row.lastBaseX or baseY ~= row.lastBaseY then
					needsWrapperUpdate = true
				end

				if needsWrapperUpdate and row.element and row.element.layout then
					row.element.layout.props.alpha            = alpha
					row.element.layout.props.relativePosition = util.vector2(baseX, baseY)
					row.element.layout.props.position         = util.vector2(posX, slotY)
					row.element:update()

					row.lastAlpha = alpha
					row.lastPosX  = posX
					row.lastSlotY = slotY
					row.lastBaseX = baseX
					row.lastBaseY = baseY
				end
			end

			------------------------------------------------
			-- RENDER SURVIVORS
			------------------------------------------------
			for i, row in ipairs(survivorRows) do
				if row.needsRebuild then
					rebuildRow(row)
				end

				-- Smooth interpolation toward target slot (only while conveyor runs)
				if conveyorActive then
					local diff = row.targetY - row.currentY
					if math.abs(diff) > 0.5 then
						local dir = diff > 0 and 1 or -1
						local step = PS_conveyorSpeed * 7 * realDt * dir
						if math.abs(step) > math.abs(diff) then
							row.currentY = row.targetY
						else
							row.currentY = row.currentY + step
						end
					else
						row.currentY = row.targetY
					end
				end

				-- Continue slide-in if still active
				if row.slideOffX ~= 0 then
					local decay = math.min(1, PS_slideSpeed * realDt)
					row.slideOffX = row.slideOffX * (1 - decay)
					if math.abs(row.slideOffX) < 1 then row.slideOffX = 0 end
				end

				-- Fade: full opacity while alive, then fade out
				local age = now - row.spawnTime
				local alpha = 1.0
				if age > PS_rowLifetime then
					alpha = 1.0 - ((age - PS_rowLifetime) / PS_fadeDuration)
					row.fadingOut = true
				end
				alpha = math.max(0, math.min(1, alpha))

				local posX = row.slideOffX * PS_uiScaleFactor

				if row.element and row.element.layout then
					row.element.layout.props.alpha            = alpha
					row.element.layout.props.relativePosition = util.vector2(baseX, baseY)
					row.element.layout.props.position         = util.vector2(posX, row.currentY)
					row.element:update()
				end
			end

			-- Remove expired survivors and collapse gaps
			local si = 1
			while si <= #survivorRows do
				local row = survivorRows[si]
				local age = now - row.spawnTime
				if age > PS_rowLifetime + PS_fadeDuration then
					if row.element then auxUi.deepDestroy(row.element) end
					table.remove(survivorRows, si)
					-- Recalculate targets so remaining survivors slide to fill gap
					for sj, s in ipairs(survivorRows) do
						s.targetY = -(sj + 1) * spacingScaled
					end
				else
					si = si + 1
				end
			end

			------------------------------------------------
			-- CLEANUP
			------------------------------------------------
			if not conveyorActive and holdStartTime and #popupQueue == 0 and #survivorRows == 0 then
				local allFaded = true
				for _, r in ipairs(activeRows) do
					if (now - (r.spawnTime or now)) <= PS_rowLifetime + PS_fadeDuration then
						allFaded = false
						break
					end
				end
				if allFaded then
					for _, r in ipairs(activeRows) do
						if r.element then auxUi.deepDestroy(r.element) end
					end
					activeRows    = {}
					scrollOffset  = 0
					holdStartTime = nil
				end
			end
		end,
	},
}