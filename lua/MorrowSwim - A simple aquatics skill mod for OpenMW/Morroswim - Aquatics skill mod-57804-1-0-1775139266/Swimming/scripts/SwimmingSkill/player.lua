local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local ui = require('openmw.ui')
local API = I.SkillFramework

local l10n = core.l10n('Swimming')
local input = require('openmw.input')
local async = require('openmw.async')
ambient = require('openmw.ambient')
local util = require('openmw.util')
local v2 = util.vector2
local storage = require('openmw.storage')
local auxUi = require('openmw_aux.ui')
local debug = require('openmw.debug')
playerActiveEffects = types.Player.activeEffects(self)
playerSpells = types.Actor.spells(self)
require('scripts.SwimmingSkill.settings')
local breathUiSection = storage.playerSection('SettingsPlayer' .. MODNAME .. 'Breath Bar UI')
local skillId = 'swimming_skill'
local checkTimer = 0
local CHECK_INTERVAL = 1.0
local fSwimHeightScale = core.getGMST("fSwimHeightScale")
local isUnderwater
noseLevel = nil

local hasSoundAddon = core.contentFiles.has("BetterSwimmingSounds.omwaddon") or core.contentFiles.has("BetterSwimmingSounds.esp")
local lastSoundTime = 0
lastSoundVariation = 1

local lastSwimPos = nil
local depthUnderwater = 0         -- updated per-frame minus nose level
local SWIM_EXP_PER_UNIT = 0.0004  -- exp gained per unit of distance swum
-- for diving exp, find this line: `local expScaled = (0.09 + (depthUnderwater ^ 0.64) * 0.009) * CHECK_INTERVAL * XP_RATE_MULT`

local drownPulseTimer = 0
breathElement = nil
local needsStuckModifierCheck = false
local whiteTex = ui.texture { path = 'white' }
local needsFirstRender = true

local _raw_print = print

local function print(...)
	if DEBUG_MESSAGES then
		_raw_print(...)
	end
end



local function getColorFromGameSettings(gmst)
	local result = core.getGMST(gmst)
	if not result then
		return util.color.rgb(1, 1, 1)
	end
	local rgb = {}
	for color in string.gmatch(result, '(%d+)') do
		table.insert(rgb, tonumber(color))
	end
	if #rgb ~= 3 then
		print("Unexpected color triplet size = " .. #rgb .. " ; using white")
		return util.color.rgb(1, 1, 1)
	end
	return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end

local textColor = getColorFromGameSettings("FontColor_color_normal")
local canDash = true

-- Cached stat object lookup tables (avoids repeated API calls per frame)
local stats = {
    speed   = types.Actor.stats.attributes.speed(self),
    fatigue = types.Actor.stats.dynamic.fatigue(self),
	health = types.Actor.stats.dynamic.health(self),
    combat  = {
        axe = types.NPC.stats.skills.axe(self),
        bluntweapon = types.NPC.stats.skills.bluntweapon(self),
        longblade = types.NPC.stats.skills.longblade(self),
        shortblade = types.NPC.stats.skills.shortblade(self),
        spear = types.NPC.stats.skills.spear(self),
        marksman = types.NPC.stats.skills.marksman(self),
        handtohand = types.NPC.stats.skills.handtohand(self),
    },
}

-- Stable table exposed via I.SwimmingSkill — consumers can cache the reference
local modifiers = {
	-- attribute
	speed = 0,
	-- skills
	axe = 0,
	bluntweapon = 0,
	longblade = 0,
	shortblade = 0,
	spear = 0,
	marksman = 0,
	handtohand = 0,
}

local skillStat
local hasApi = false

if API then
	hasApi = true
	API.registerSkill(skillId, {
		name = l10n('skill_swimming_name'),
		description = l10n('skill_swimming_desc'),
		icon = { fgr = "icons/swimming/swim.dds" },
		attribute = "endurance",
		specialization = API.SPECIALIZATION.Combat,
		skillGain = {
			[1] = 0.15,
		},
		startLevel = 5,
		maxLevel = 100,
		statsWindowProps = {
			subsection = API.STATS_WINDOW_SUBSECTIONS.Movement
		}
	})
	
	API.registerRaceModifier(skillId, 'argonian', 25)
	API.registerRaceModifier(skillId, 'khajiit', 10)
	API.registerRaceModifier(skillId, 'nord', -5)
	API.registerRaceModifier(skillId, 'orc', -5)
	
	-- SKILL BOOKS
	API.registerSkillBook('bk_bm_aevar', skillId)               -- scroll
	API.registerSkillBook('tr_la1_grotto_1_journal_2', skillId) -- scroll
	API.registerSkillBook('t_bk_traditionalsloadtaletr', skillId)
	API.registerSkillBook('t_bk_caverndoortr', skillId)
	API.registerSkillBook('t_bk_argonianaccountpc_v4', skillId) -- seemingly dublicates of the series?
	API.registerSkillBook('t_bk_oldfjorithecoveshotn', skillId)
	
	skillStat = API.getSkillStat(skillId)
else
	ui.showMessage("[MorroSwim] Skill Framework not installed or wrong load order")
	skillStat = {base = 15, modifier = 0, modified = 15, progress = 0}
	API = {
		skillUsed = function(skillId, data) 
			local gain = data and data.skillGain or 0
			
			skillStat.progress = skillStat.progress + gain / math.max(1, skillStat.base)
			if skillStat.progress >= 1 then
				skillStat.base = skillStat.base + 1
				skillStat.progress = 0
				ambient.playSound("skillraise")
				ui.showMessage("Swimming increased to "..tonumber(skillStat.base))
			end
			skillStat.modified = skillStat.base + skillStat.modifier
		end,
	}
end

local function getCombatModifier()
    local swimmingSkill = skillStat.modified
    
    if swimmingSkill >= 100 then
        return 20
    elseif swimmingSkill >= 90 then
        return 15
    elseif swimmingSkill >= 80 then
        return 10
    elseif swimmingSkill >= 60 then
        return 5
    elseif swimmingSkill >= 50 then
        return 0
    elseif swimmingSkill >= 30 then
        return -5
    elseif swimmingSkill >= 15 then
        return -10
    else
        return -15
    end
end

function getMaxBreathDuration()
    local swimmingSkill = skillStat.modified
    return BREATH_DURATION_BASE + (BREATH_DURATION_PER_LEVEL * swimmingSkill)
end

local function getDashParameters()
    local swimmingSkill = skillStat.modified
    
    local dashSpeed = DASH_SPEED_BASE + (DASH_SPEED_PER_LEVEL * swimmingSkill)
    local fatigueCost = DASH_FATIGUE_BASE + (DASH_FATIGUE_PER_LEVEL * swimmingSkill)
    local duration = DASH_DURATION_BASE + (DASH_DURATION_PER_LEVEL * swimmingSkill)
    
    fatigueCost = math.max(15, fatigueCost)
    
    return dashSpeed, fatigueCost, duration
end

local function applySpeedBonus()
    local bonus = 0
    if SPEED_BONUS_ENABLED then
        bonus = math.floor(skillStat.modified * SPEED_BONUS_MULT)
    end
    
    if saveData.currentSpeedBonus > 0 then
        stats.speed.modifier = math.max(0, stats.speed.modifier - saveData.currentSpeedBonus)
    end
    
    stats.speed.modifier = stats.speed.modifier + bonus
    saveData.currentSpeedBonus = bonus
    modifiers.speed = bonus
    
    print("SWIMMING SKILL MOD: Applied +" .. bonus .. " Speed bonus")
end

local function removeSpeedBonus()
    if saveData.currentSpeedBonus > 0 then
        stats.speed.modifier = stats.speed.modifier - saveData.currentSpeedBonus
        print("SWIMMING SKILL MOD: Removed +" .. saveData.currentSpeedBonus .. " Speed bonus")
        saveData.currentSpeedBonus = 0
        modifiers.speed = 0
    end
end

local function notifyAAM()
    local AAM = I.AAM
    if not AAM or not AAM.reportExternalModifiers then return end
    
    local report = {}
    if saveData.currentCombatModifier > 0 then
        for name, _ in pairs(stats.combat) do
            report[name] = saveData.currentCombatModifier
        end
    end
    report["speed"] = saveData.currentSpeedBonus + saveData.dashTotal
    AAM.reportExternalModifiers("Swimming", report)
end

local function applyCombatModifier()
    -- Remove old modifier first
    if saveData.currentCombatModifier > 0 then
        for _, skill in pairs(stats.combat) do
            skill.modifier = skill.modifier - saveData.currentCombatModifier
        end
    elseif saveData.currentCombatModifier < 0 then
        for _, skill in pairs(stats.combat) do
            skill.damage = skill.damage + saveData.currentCombatModifier -- subtracts since negative
        end
    end
    
    -- Apply new value only if enabled
    local newValue = 0
    if COMBAT_MOD_ENABLED then
        newValue = getCombatModifier()
    end
    saveData.currentCombatModifier = newValue
    if newValue > 0 then
        for _, skill in pairs(stats.combat) do
            skill.modifier = skill.modifier + newValue
        end
    elseif newValue < 0 then
        for _, skill in pairs(stats.combat) do
            skill.damage = skill.damage - newValue -- adds abs value since newValue is negative
        end
    end
    
    for name, _ in pairs(stats.combat) do
        modifiers[name] = newValue
    end
    notifyAAM()
    print(string.format("SWIMMING SKILL MOD: Combat effectiveness %+d", newValue))
end

local function removeCombatModifier()
    if saveData.currentCombatModifier > 0 then
        for _, skill in pairs(stats.combat) do
            skill.modifier = skill.modifier - saveData.currentCombatModifier
        end
        print(string.format("SWIMMING SKILL MOD: Removed combat bonus (+%d)", saveData.currentCombatModifier))
    elseif saveData.currentCombatModifier < 0 then
        for _, skill in pairs(stats.combat) do
            skill.damage = skill.damage + saveData.currentCombatModifier -- subtracts since negative
        end
        print(string.format("SWIMMING SKILL MOD: Removed combat penalty (%d damage)", saveData.currentCombatModifier))
    end
    saveData.currentCombatModifier = 0
    for name, _ in pairs(stats.combat) do
        modifiers[name] = 0
    end
    notifyAAM()
end

function createBreathUI()
    if breathElement then breathElement:destroy() end
    local MWUI = I.MWUI
    if not cachedBoxTemplate then
        cachedBoxTemplate = auxUi.deepLayoutCopy(MWUI.templates.boxSolidThick)
        -- content[1] is the solid background, content[2..n-1] are border pieces, content[n] is the slot
        cachedBoxTemplate.content[1].props.alpha = BREATH_UI_BG_ALPHA / 100
        for i = 2, #cachedBoxTemplate.content - 1 do
            cachedBoxTemplate.content[i].props.alpha = BREATH_UI_BORDER_ALPHA / 100
        end
    end
    if not cachedBarBorders then
        cachedBarBorders = auxUi.deepLayoutCopy(MWUI.templates.borders)
        for i = 1, #cachedBarBorders.content - 1 do
            cachedBarBorders.content[i].props.alpha = BREATH_UI_BAR_BORDER_ALPHA / 100
        end
    end
    breathElement = ui.create({
        type = ui.TYPE.Container,
        layer = BREATH_UI_LOCK and "HUD" or "Modal",
        template = cachedBoxTemplate,
        props = {
            relativePosition = v2(0.5, 0),
            anchor = v2(0.5, 0),
            position = v2(BREATH_UI_X_OFFSET, BREATH_UI_Y_OFFSET),
        },
        userData = {
            windowStartPosition = v2(BREATH_UI_X_OFFSET, BREATH_UI_Y_OFFSET),
        },
        content = ui.content {
            {
                name = 'inner',
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                    size = v2(BREATH_UI_WIDTH + 20, 42 + BREATH_UI_BAR_THICKNESS),
                    autoSize = false,
                },
                content = ui.content {
                    {
                        { props = { size = v2(1, 1) * 2 } },
                        type = ui.TYPE.Text,
                        template = MWUI.templates.textNormal,
                        props = {
                            text = core.getGMST('sBreath') or "Breath",
                            textColor = textColor,
                            textSize = math.max(1,BREATH_UI_TEXT_SIZE),
                            textAlignH = ui.ALIGNMENT.Center,
							alpha = BREATH_UI_TEXT_SIZE == 0 and 0 or 1,
                        },
                    },
                    { props = { size = v2(1, 1) * 2 } },
                    {
                        name = 'barOuter',
                        type = ui.TYPE.Widget,
                        template = cachedBarBorders,
                        props = {
                            size = v2(BREATH_UI_WIDTH, BREATH_UI_BAR_THICKNESS),
                        },
                        content = ui.content {
                            {
                                name = 'fill',
                                type = ui.TYPE.Image,
                                props = {
                                    resource = whiteTex,
                                    color = BREATH_UI_COLOR,
                                    relativeSize = v2(1, 1),
                                },
                            },
                        },
                    },
                },
            },
        },
    })
	breathElement.layout.events = {
		mousePress = async:callback(function(data, elem)
			if data.button == 1 then
				elem.userData.isDragging = true
				elem.userData.dragStartPosition = data.position
				elem.userData.windowStartPosition = breathElement.layout.props.position or v2(BREATH_UI_X_OFFSET, BREATH_UI_Y_OFFSET)
				BREATH_UI_PREVIEW_TIMER = 3
			end
			breathElement:update()
		end),
		mouseRelease = async:callback(function(data, elem)
			if elem.userData and elem.userData.isDragging then
				elem.userData.isDragging = false
				local pos = breathElement.layout.props.position
				-- Clamp offset so bar stays within HUD layer bounds
				local layerId = ui.layers.indexOf("Modal")
				local hudSize = ui.layers[layerId].size
				local halfWidth = hudSize.x * 0.5
				pos = v2(
					math.max(-halfWidth, math.min(pos.x, halfWidth)),
					math.max(0, math.min(pos.y, hudSize.y - 50))
				)
				breathElement.layout.props.position = pos
				breathUiSection:set("BREATH_UI_X_OFFSET", math.floor(pos.x))
				breathUiSection:set("BREATH_UI_Y_OFFSET", math.floor(pos.y))
				BREATH_UI_PREVIEW_TIMER = 3 -- suppress preview rebuild from settings subscription
			end
			breathElement:update()
		end),
		mouseMove = async:callback(function(data, elem)
			if elem.userData and elem.userData.isDragging then
				local delta = data.position - elem.userData.dragStartPosition
				breathElement.layout.props.position = elem.userData.windowStartPosition + delta
				breathElement:update()
				BREATH_UI_PREVIEW_TIMER = 3 -- suppress preview rebuild from settings subscription
			end
		end),
	}
end

function updateBreathUI(ratio, dt)
    if not breathElement or not breathElement.layout then return end
    local fill = breathElement.layout.content.inner.content.barOuter.content.fill
    if ratio <= 0 then
        if BREATH_UI_DROWN_PULSE then
            drownPulseTimer = drownPulseTimer + dt
            local alpha = 0.3 + 0.7 * math.abs(math.sin(drownPulseTimer * BREATH_UI_PULSE_SPEED))
            fill.props.alpha = alpha
        else
            fill.props.alpha = 1
        end
        fill.props.relativeSize = v2(1, 1)
        fill.props.color = BREATH_UI_DROWN_COLOR
    else
        drownPulseTimer = 0
        fill.props.relativeSize = v2(math.min(1, ratio), 1)
        fill.props.color = BREATH_UI_COLOR
        fill.props.alpha = 1
    end
    breathElement:update()
end

local function destroyBreathUI()
    if breathElement then
        breathElement:destroy()
        breathElement = nil
    end
end

if input.triggers["MenuMouseWheelUp"] then
	input.registerTriggerHandler("MenuMouseWheelUp", async:callback(function()
		if not breathElement or not breathElement.layout.userData or not breathElement.layout.userData.isDragging then return end
		if input.isShiftPressed() then
			local newBgAlpha = math.min(100, math.max(0, BREATH_UI_BG_ALPHA + 10))
			local newBorderAlpha = math.min(100, math.max(0, BREATH_UI_BORDER_ALPHA + 10))
			if cachedBoxTemplate then
				cachedBoxTemplate.content[1].props.alpha = newBgAlpha / 100
				for i = 2, #cachedBoxTemplate.content - 1 do
					cachedBoxTemplate.content[i].props.alpha = newBorderAlpha / 100
				end
			end
			breathUiSection:set("BREATH_UI_BG_ALPHA", newBgAlpha)
			breathUiSection:set("BREATH_UI_BORDER_ALPHA", newBorderAlpha)
		else
			local newWidth = math.max(20, BREATH_UI_WIDTH + 5)
			breathElement.layout.content.inner.props.size = v2(newWidth + 20, 42 + BREATH_UI_BAR_THICKNESS)
			breathElement.layout.content.inner.content.barOuter.props.size = v2(newWidth, BREATH_UI_BAR_THICKNESS)
			breathUiSection:set("BREATH_UI_WIDTH", newWidth)
		end
		breathElement:update()
	end))
end
if input.triggers["MenuMouseWheelDown"] then
	input.registerTriggerHandler("MenuMouseWheelDown", async:callback(function()
		if not breathElement or not breathElement.layout.userData or not breathElement.layout.userData.isDragging then return end
		if input.isShiftPressed() then
			local newBgAlpha = math.min(100, math.max(0, BREATH_UI_BG_ALPHA - 10))
			local newBorderAlpha = math.min(100, math.max(0, BREATH_UI_BORDER_ALPHA - 10))
			if cachedBoxTemplate then
				cachedBoxTemplate.content[1].props.alpha = newBgAlpha / 100
				for i = 2, #cachedBoxTemplate.content - 1 do
					cachedBoxTemplate.content[i].props.alpha = newBorderAlpha / 100
				end
			end
			breathUiSection:set("BREATH_UI_BG_ALPHA", newBgAlpha)
			breathUiSection:set("BREATH_UI_BORDER_ALPHA", newBorderAlpha)
		else
			local newWidth = math.max(20, BREATH_UI_WIDTH - 5)
			breathElement.layout.content.inner.props.size = v2(newWidth + 20, 42 + BREATH_UI_BAR_THICKNESS)
			breathElement.layout.content.inner.content.barOuter.props.size = v2(newWidth, BREATH_UI_BAR_THICKNESS)
			breathUiSection:set("BREATH_UI_WIDTH", newWidth)
		end
		breathElement:update()
	end))
end

local function tryDash()
	if not DASH_ENABLED or not types.Actor.isSwimming(self) or not canDash then return end
	local currentFatigue = stats.fatigue.current

	local dashSpeed, fatigueCost, duration = getDashParameters()

	if currentFatigue >= fatigueCost then
		-- Block dash if drowning (no breath left)
		local maxBreath = getMaxBreathDuration()
		if saveData.underwaterTime >= maxBreath then
			ui.showMessage("Can't dash while drowning")
			return
		end

		local expScaled = 0.45 * XP_RATE_MULT
		print("dash +"..math.floor(expScaled*100)/100 .."xp")
		saveData.swimExpAccum = saveData.swimExpAccum + expScaled

		canDash = false
		if not debug.isGodMode() then
			stats.fatigue.current = math.max(0, currentFatigue - fatigueCost)
		end
		stats.speed.modifier = math.max(0, stats.speed.modifier + dashSpeed)
		saveData.dashTotal = saveData.dashTotal + dashSpeed
		modifiers.speed = saveData.currentSpeedBonus + saveData.dashTotal
		notifyAAM()
		if SWIMMING_SFX_VOLUME > 0 then
			local swimmingSkill = skillStat.modified

			if isUnderwater then
				ambient.playSoundFile("sound/Swimming/218272__alienxxx__swish6 - Copy.wav", {
					volume = 1.1*SWIMMING_SFX_VOLUME / 100,
					--pitch = 0.7--(0.95 + pitchBonus + 0.1 * math.random())
				})
			
			else
				ambient.playSoundFile("sound/Swimming/218272__alienxxx__swish6 - Copy.wav", {
					volume = 0.85*SWIMMING_SFX_VOLUME / 100,
					pitch = 1.6--(0.95 + pitchBonus + 0.1 * math.random())
				})
				ambient.playSoundFile("sound/Swimming/218273__alienxxx__swish5 - Copy.wav", {
					volume = 0.55*SWIMMING_SFX_VOLUME / 100,
					pitch = 1.7--(0.95 + pitchBonus + 0.1 * math.random())
				})
			end
			
		end

		print(string.format("SWIMMING SKILL MOD: DASH! +%.0f speed for %.2fs (%.0f fatigue)",
			dashSpeed, duration, fatigueCost))

		-- Dashing underwater uses some breath
		if saveData.waterBreathingActive and DASH_BREATH_COST > 0 then
			saveData.underwaterTime = math.min(maxBreath, saveData.underwaterTime + DASH_BREATH_COST)
			updateBreathUI(1 - (saveData.underwaterTime / maxBreath), 0)
		end

		async:newUnsavableSimulationTimer(
			duration,
			function()
				stats.speed.modifier = math.max(0, stats.speed.modifier - saveData.dashTotal)
				saveData.dashTotal = 0
				modifiers.speed = saveData.currentSpeedBonus
				notifyAAM()
				canDash = true
			end
		)
	else
		ui.showMessage(string.format("Not enough fatigue for dash (need %.0f)", fatigueCost))
	end
end

-- Dash keybind action
input.registerAction({
	key = "swimmingSkillDashTrigger",
	type = input.ACTION_TYPE.Boolean,
	l10n = "none",
	name = "",
	description = "",
	defaultValue = false,
})
input.registerActionHandler('swimmingSkillDashTrigger', async:callback(function(down)
	if not down then return end
	if I.UI.getMode() or core.isWorldPaused() then return end
	if not ENABLE_DASH_KEYBINDING then return end
	tryDash()
end))

local function onInputAction(action)
	if action == input.ACTION.Jump and DASH_ON_JUMP then
		tryDash()
	end
end

local function hasExternalWaterBreathing()
	local mag = playerActiveEffects:getEffect("waterbreathing").magnitude
	if saveData.waterBreathingActive then
		return mag >= 2
	else
		return mag >= 1
	end
end

local function grantWaterBreathing()
	if saveData.waterBreathingActive then return end
	if USE_MODIFY_EFFECT then
		playerActiveEffects:modify(1, "waterbreathing")
	else
		playerSpells:add('swimmingskill_waterbreathing')
	end
	saveData.waterBreathingActive = true
end

local function revokeWaterBreathing()
	if not saveData.waterBreathingActive then return end
	if USE_MODIFY_EFFECT then
		playerActiveEffects:modify(-1, "waterbreathing")
	else
		playerSpells:remove('swimmingskill_waterbreathing')
	end
	saveData.waterBreathingActive = false
end

local function verifyWaterBreathingMagnitude(knownModifyOffset)
	-- Sum waterbreathing magnitudes from all active spells (the "real" sources)
	local expectedMagnitude = (knownModifyOffset or 0)
	local spells = types.Actor.activeSpells(self)
	for _, spellData in pairs(spells) do
		--print(spellData)
		for _, effect in pairs(spellData.effects) do
			if effect.id == 'waterbreathing' then
				expectedMagnitude = expectedMagnitude + (effect.magnitudeThisFrame or 1)
			end
		end
	end
	--print("expected = ", expectedMagnitude)
	local actualMagnitude = playerActiveEffects:getEffect("waterbreathing").magnitude or 0
	--print("actual = ", actualMagnitude)
	local difference = actualMagnitude - expectedMagnitude

	if math.abs(difference) > 0.01 then
		print(string.format(
			"SWIMMING SKILL MOD: Water breathing magnitude mismatch — expected %.2f from spells, got %.2f (stuck offset: %+.2f). Fixing.",
			expectedMagnitude, actualMagnitude, difference))
		playerActiveEffects:modify(-difference, "waterbreathing")
		ui.showMessage(string.format("Swimming Skill: Fixed stuck water breathing effect (%+.1f)", -difference))
	else
		print("SWIMMING SKILL MOD: Water breathing magnitude verified OK")
	end
end

local function cleanupStuckModifiers()
    -- Scan active spells for fortifyskill effects on our combat skills
    local expectedModifiers = {}
    for name, _ in pairs(stats.combat) do
        expectedModifiers[name] = 0
    end
	
	local hasAAM = storage.playerSection("SettingsAbiliesAreModifiers"):get("ENABLED") and (I.AAM or core.contentFiles.has("AbilitiesAreModifiers.omwscripts"))
	
    local spells = types.Actor.activeSpells(self)
    for _, spellData in pairs(spells) do
        for _, effect in pairs(spellData.effects) do
            if effect.id == 'fortifyskill' and effect.affectedSkill then
                if expectedModifiers[effect.affectedSkill] ~= nil
				and (not spellData.affectsBaseValues or hasAAM) then
                    expectedModifiers[effect.affectedSkill] = expectedModifiers[effect.affectedSkill] + (effect.magnitudeThisFrame or 0)
                end
            end
        end
    end

    -- Find the highest multiple-of-5 bonus that is stuck on ALL combat skills.
    local minUnexplained = math.huge
    for name, stat in pairs(stats.combat) do
        local expected = expectedModifiers[name] or 0
        minUnexplained = math.min(minUnexplained, stat.modifier - expected)
    end

    -- Round down to the nearest multiple of 5
    local stuckValue = math.floor(minUnexplained / 5) * 5

    if stuckValue > 0 then
        print(string.format("SWIMMING SKILL MOD: Detected stuck modifier of +%.0f on all combat skills from v1 bug, removing", stuckValue))
        for name, stat in pairs(stats.combat) do
            stat.modifier = stat.modifier - stuckValue
			stat.damage = math.max(0, stat.damage - stuckValue)
        end
        ui.showMessage(string.format("Swimming Skill: Cleaned up stuck +%d combat modifier from old version", stuckValue))
    end
    needsStuckModifierCheck = false
end

local function onUpdate(dt)
	local realDt = core.getRealFrameDuration()

	-- Settings UI preview: temporarily show the breath bar when UI settings change
	if BREATH_UI_PREVIEW_TIMER then
		if BREATH_UI_PREVIEW_TIMER - realDt > 0 then
			-- Suppress destroy+recreate while dragging — scroll handlers already updated in-place
			if breathElement and breathElement.layout.userData and breathElement.layout.userData.isDragging then
				BREATH_UI_PREVIEW_TIMER = 3
			else
				BREATH_UI_PREVIEW_TIMER = BREATH_UI_PREVIEW_TIMER - realDt
				if not breathElement then 
					createBreathUI()
				end
				if BREATH_UI_PREVIEW_DROWN then
					updateBreathUI(0, realDt)
				else
					updateBreathUI(1 - (saveData.underwaterTime / getMaxBreathDuration()), realDt)
				end
			end
		else
			BREATH_UI_PREVIEW_TIMER = nil
			BREATH_UI_PREVIEW_DROWN = nil
			needsFirstRender = true
			destroyBreathUI()
		end
	end

	if dt == 0 and not needsFirstRender then return end

    -- Cache nose level once (race/gender never change)
    if not noseLevel then
        local npcRecord = types.NPC.record(self)
        if npcRecord then
            local raceRecord = types.NPC.races.record(npcRecord.race)
            if npcRecord.isMale then
                noseLevel = raceRecord.height.male * NOSE_HEIGHT_MULT/fSwimHeightScale
            else
                noseLevel = raceRecord.height.female * NOSE_HEIGHT_MULT/fSwimHeightScale
            end
        else
            noseLevel = NOSE_HEIGHT_MULT/fSwimHeightScale
        end
    end

    -- Cache depth below water once per frame (nose-level-aware)
    local cellWaterLevel = self.cell.waterLevel or -99999999
    depthUnderwater = cellWaterLevel - noseLevel - self.position.z
	local hasExternal = hasExternalWaterBreathing()
    local maxBreath = getMaxBreathDuration()
    -- Throttled: skill gain and swim stat modifiers
    checkTimer = checkTimer + dt
	local isSwimming = types.Actor.isSwimming(self)
    if checkTimer >= CHECK_INTERVAL then
        checkTimer = 0
        if isSwimming then
            -- Distance-based exp
            local currentPos = self.position
            if lastSwimPos then
               local dist = (currentPos - lastSwimPos):length()
				if dist > 0 and dist < 2000 then
					--dist = dist * (10+stats.speed.modified) /200
					--local expScaled = (0.03 + dist * SWIM_EXP_PER_UNIT) * XP_RATE_MULT
					local expScaled = 0.7 * XP_RATE_MULT
					print("swim +"..math.floor(expScaled*100)/100 .."xp")
					saveData.swimExpAccum = saveData.swimExpAccum + expScaled
				end
            end
            lastSwimPos = currentPos

            -- Passive diving exp while deep underwater
            if depthUnderwater >= 25 then
				local expScaled = (0.09 + (depthUnderwater ^ 0.64) * 0.009) * CHECK_INTERVAL * XP_RATE_MULT
				if hasExternal then
					expScaled = expScaled / 3
				end
				if saveData.underwaterTime >= maxBreath then
					expScaled = expScaled / 2
				end
				print("dive +"..math.floor(expScaled*100)/100 .."xp")
                saveData.swimExpAccum = saveData.swimExpAccum + expScaled
            end

            -- Flush accumulated exp in one call
            if saveData.swimExpAccum >= 0.3 then
                API.skillUsed(skillId, { skillGain = saveData.swimExpAccum, useType = 1, scale = nil })
				
                saveData.swimExpAccum = 0
            end

            if not saveData.wasSwimming then
                applySpeedBonus()
                applyCombatModifier()
                saveData.wasSwimming = true
            end
        else
            if saveData.wasSwimming then
                -- Flush any leftover exp before leaving swim state
                if saveData.swimExpAccum > 0 then
                    API.skillUsed(skillId, { skillGain = saveData.swimExpAccum, useType = 0, scale = nil })
                    saveData.swimExpAccum = 0
                end
                removeSpeedBonus()
                removeCombatModifier()
                saveData.wasSwimming = false
            end
            lastSwimPos = nil
        end
    end
	needsFirstRender = false
	if not isSwimming and not saveData.waterBreathingActive and not breathElement then
		return
	end
    -- Per-frame: underwater water breathing
    isUnderwater = depthUnderwater > 0
	if not isSwimming then
		-- Left water: remove and recharge breath
		revokeWaterBreathing()
		if saveData.underwaterTime > 0 then
			local rechargeRate = maxBreath / BREATH_RECHARGE_DURATION
			saveData.underwaterTime = math.max(0, saveData.underwaterTime - rechargeRate * dt)
			if saveData.underwaterTime <= 0 then
				saveData.underwaterTime = 0
				destroyBreathUI()
			else
				updateBreathUI(1 - (saveData.underwaterTime / maxBreath), dt)
			end
		end
		return
	end
	
	if hasSoundAddon and math.max(math.abs(self.controls.movement), math.abs(self.controls.sideMovement)) > 0.01 and SWIMMING_SFX_VOLUME > 0 then
		local now = core.getRealTime()
		local soundTimeBonus = saveData.dashTotal > 0 and 0.2 or 0.5
		if now > lastSoundTime + soundTimeBonus then
			local swimmingSkill = skillStat.modified
			local pitchBonus = (swimmingSkill / 100.0) * 0.3
			if isUnderwater then
				lastSoundTime = now + math.random() * 0.2
				if lastSoundVariation%2==0 then
					ambient.playSoundFile("sound/Swimming/218273__alienxxx__swish5.wav", {
						volume = 0.85 * SWIMMING_SFX_VOLUME / 100,
						--pitch = (0.95 + pitchBonus + 0.1 * math.random())
					})
				else
					ambient.playSoundFile("sound/Swimming/218272__alienxxx__swish6.wav", {
						volume = 0.85 * SWIMMING_SFX_VOLUME / 100,
						pitch = 0.7--(0.95 + pitchBonus + 0.1 * math.random())
					})
				end
			else
				lastSoundTime = now
				if lastSoundVariation%2==0 then
					ambient.playSoundFile("sound/Swimming/swimLEFT.wav", {
						volume = 0.7 * SWIMMING_SFX_VOLUME / 100,
						--pitch = (0.95 + pitchBonus + 0.1 * math.random())
					})
				else
					ambient.playSoundFile("sound/Swimming/swimRIGHT.wav", {
						volume = 0.7 * SWIMMING_SFX_VOLUME / 100,
						--pitch = (0.95 + pitchBonus + 0.1 * math.random())
					})
				end
			end
			lastSoundVariation = lastSoundVariation + 1
		end
	end
	
	
	-- Swimming: defer to external water breathing if present
	if hasExternal then
		revokeWaterBreathing()
		-- Slowly recharge breath even underwater if external source handles it
		if saveData.underwaterTime > 0 then
			local rechargeRate = maxBreath / BREATH_RECHARGE_DURATION
			saveData.underwaterTime = math.max(0, saveData.underwaterTime - rechargeRate * dt)
			if saveData.underwaterTime <= 0 then
				saveData.underwaterTime = 0
				destroyBreathUI()
			else
				updateBreathUI(1 - (saveData.underwaterTime / maxBreath), dt)
			end
		end
		return
	end
	-- Grant buff immediately while swimming with breath remaining
	if saveData.underwaterTime < maxBreath then
		grantWaterBreathing()
	end

	-- Only consume breath when actually underwater
	if isUnderwater then
		saveData.underwaterTime = math.min(saveData.underwaterTime + dt, maxBreath)
		if not breathElement then
			createBreathUI()
		end

		if saveData.underwaterTime >= maxBreath then
			-- Drowning: remove effect
			revokeWaterBreathing()
			if not debug.isGodMode() then
				stats.health.current = stats.health.current - stats.health.base * (DROWN_DAMAGE_PERCENT / 100) * dt
			end
			updateBreathUI(0, dt)
		else
			updateBreathUI(1 - (saveData.underwaterTime / maxBreath), dt)
		end
	else
		-- Swimming on surface: recharge breath
		if saveData.underwaterTime > 0 then
			local rechargeRate = maxBreath / BREATH_RECHARGE_DURATION
			saveData.underwaterTime = math.max(0, saveData.underwaterTime - rechargeRate * dt)
			if saveData.underwaterTime <= 0 then
				saveData.underwaterTime = 0
				destroyBreathUI()
			else
				updateBreathUI(1 - (saveData.underwaterTime / maxBreath), dt)
			end
		end
	end
end

-- Console: "lua swim 50" to set level
local function onConsoleCommand(mode, command)
    local cmd = command:gsub("^%s*[Ll][Uu][Aa]%s+", "")
    local prefix, arg = cmd:match("^(%S+)%s*(%S*)")
    if not prefix or prefix:lower() ~= "swim" then return end
    local level = tonumber(arg)
    if level then
        skillStat.base = math.max(0, math.floor(level))
		if not hasApi then
			API.skillUsed()
		end
        ui.showMessage("Swimming skill set to " .. level)
        if saveData.wasSwimming then 
			applySpeedBonus()
			applyCombatModifier() 
		end
    else
        ui.showMessage(string.format("Swimming skill: base=%d modified=%d", skillStat.base, skillStat.modified))
    end
end

local function onLoad(data)
	saveData = data or {}
	if not hasApi then
		skillStat = saveData.skillStat or skillStat
	else
		local prev = saveData.skillStat and saveData.skillStat.base or 0
		saveData.skillStat = {
			base     = math.max(skillStat.base, prev),
			modifier = 0,
			modified = math.max(skillStat.base, prev),
			progress = skillStat.progress or 0,
		}
	end
	if saveData.wasSwimming == nil then saveData.wasSwimming = false end
	saveData.currentSpeedBonus = saveData.currentSpeedBonus or 0
	saveData.currentCombatModifier = saveData.currentCombatModifier or 0
	saveData.dashTotal = saveData.dashTotal or 0
	saveData.underwaterTime = saveData.underwaterTime or 0
	saveData.swimExpAccum = saveData.swimExpAccum or 0

	-- Verify waterbreathing magnitude (before cleanup)
	if VERIFY_WATERBREATHING then
		local modOwnOffset = (saveData.waterBreathingActive and saveData.useModifyEffect) and 1 or 0
		verifyWaterBreathingMagnitude(modOwnOffset)
	end

	-- Clean up water breathing only if the method changed since last save
	if saveData.waterBreathingActive and saveData.useModifyEffect ~= USE_MODIFY_EFFECT then
		if saveData.useModifyEffect then
			playerActiveEffects:modify(-1, "waterbreathing")
		else
			playerSpells:remove('swimmingskill_waterbreathing')
		end
		saveData.waterBreathingActive = false
	end
	saveData.useModifyEffect = USE_MODIFY_EFFECT

	if saveData.dashTotal > 0 then
		stats.speed.modifier = math.max(0, stats.speed.modifier - saveData.dashTotal)
		saveData.dashTotal = 0
	end

	if saveData.currentCombatModifier ~= 0 then
		removeCombatModifier()
	end

	-- Schedule stuck modifier cleanup for saves coming from v1
	if not saveData.version or saveData.version < 2 then
		cleanupStuckModifiers()
		print("SWIMMING SKILL MOD: v1 save detected, will check for stuck combat modifiers")
	end
	saveData.version = 2
end

return {
    interfaceName = 'SwimmingSkill',
    interface = {
        version = 1,
        modifiers = modifiers, -- stable table - values updated in-place
    },
    engineHandlers = {
        onUpdate = onUpdate,
        onInputAction = onInputAction,
        onConsoleCommand = onConsoleCommand,
        onSave = function()
            return saveData
        end,
        onLoad = onLoad,
        onInit = onLoad,
    }
}