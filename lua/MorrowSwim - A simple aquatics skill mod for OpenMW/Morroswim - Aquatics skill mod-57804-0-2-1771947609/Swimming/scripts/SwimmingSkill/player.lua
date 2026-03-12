local core = require('openmw.core')
local types = require('openmw.types')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local API = I.SkillFramework
local l10n = core.l10n('Swimming')
local input = require('openmw.input')
local async = require('openmw.async')
local ui = require('openmw.ui')
local ambient = require('openmw.ambient')
local util = require('openmw.util')
local v2 = util.vector2
local storage = require('openmw.storage')
local playerActiveEffects = types.Player.activeEffects(self)
local playerSpells = types.Actor.spells(self)
local skillId = 'swimming_skill'
local checkTimer = 0
local CHECK_INTERVAL = 1.0
local fSwimHeightScale = core.getGMST("fSwimHeightScale")

-- Dash parameters that scale linearly per skill level
local dashSpeedPerLevel = 12        -- Speed bonus per skill level (1200 total at 100)
local dashSpeedBase = 300           -- Base speed at skill level 0
local dashFatigueCostBase = 40      -- Fatigue cost at skill level 0
local dashFatigueCostPerLevel = -0.25 -- Fatigue reduction per level (-25 total at 100)
local dashDurationBase = 0.5        -- Duration at skill level 0
local dashDurationPerLevel = 0.005  -- Duration increase per level (+0.5s total at 100)
local dashSfxVolume = 1.0

-- Water breathing parameters
local waterBreathDurationBase = 8           -- Duration at skill level 0 (seconds)
local waterBreathDurationPerLevel = 0.45    -- Duration increase per level (+45s at 100)
local dashBreathCost = 1.5                  -- Seconds of breath consumed per dash

local noseLevel = nil
local wasSwimming = false
local waterBreathingActive = false
local underwaterTime = 0           -- seconds spent underwater (0 = full breath)
local drownPulseTimer = 0
local breathElement = nil
local breathRechargeDuration = 3   -- seconds to refill a fully depleted bar
local needsStuckModifierCheck = false
local whiteTex = ui.texture { path = 'white' }

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

local barColor = util.color.hex("2e9594") --getColorFromGameSettings("FontColor_color_active")
local textColor = getColorFromGameSettings("FontColor_color_normal")
local currentSpeedBonus = 0
local currentCombatModifier = 0
local dashTotal = 0
local canDash = true

-- Cached stat object lookup tables (avoids repeated API calls per frame)
local stats = {
    speed   = types.Actor.stats.attributes.speed(self),
    fatigue = types.Actor.stats.dynamic.fatigue(self),
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

local function getCombatModifier()
    local skillStat = API.getSkillStat(skillId)
    if not skillStat then return -15 end
    
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

local function getMaxBreathDuration()
    local skillStat = API.getSkillStat(skillId)
    local swimmingSkill = skillStat and skillStat.modified or 0
    return waterBreathDurationBase + (waterBreathDurationPerLevel * swimmingSkill)
end

local function getDashParameters()
    local skillStat = API.getSkillStat(skillId)
    if not skillStat then return dashSpeedBase, dashFatigueCostBase, dashDurationBase end
    
    local swimmingSkill = skillStat.modified
    
    local dashSpeed = dashSpeedBase + (dashSpeedPerLevel * swimmingSkill)
    local fatigueCost = dashFatigueCostBase + (dashFatigueCostPerLevel * swimmingSkill)
    local duration = dashDurationBase + (dashDurationPerLevel * swimmingSkill)
    
    fatigueCost = math.max(15, fatigueCost)
    
    return dashSpeed, fatigueCost, duration
end

local function applySpeedBonus()
    local skillStat = API.getSkillStat(skillId)
    local bonus = skillStat and skillStat.modified or 0
    
    if currentSpeedBonus > 0 then
        stats.speed.modifier = stats.speed.modifier - currentSpeedBonus
    end
    
    stats.speed.modifier = stats.speed.modifier + bonus
    currentSpeedBonus = bonus
    
    print("SWIMMING SKILL MOD: Applied +" .. bonus .. " Speed bonus")
end

local function removeSpeedBonus()
    if currentSpeedBonus > 0 then
        stats.speed.modifier = stats.speed.modifier - currentSpeedBonus
        print("SWIMMING SKILL MOD: Removed +" .. currentSpeedBonus .. " Speed bonus")
        currentSpeedBonus = 0
    end
end

local function notifyAAM()
    local AAM = I.AAM
    if not AAM or not AAM.reportExternalModifiers then return end
    
    local report = {}
    if currentCombatModifier > 0 then
        for name, _ in pairs(stats.combat) do
            report[name] = currentCombatModifier
        end
    end
    if currentSpeedBonus > 0 then
        report["speed"] = currentSpeedBonus
    end
    AAM.reportExternalModifiers("Swimming", report)
end

local function applyCombatModifier()
    local newValue = getCombatModifier()
    
    -- Remove old modifier first
    if currentCombatModifier > 0 then
        for _, skill in pairs(stats.combat) do
            skill.modifier = skill.modifier - currentCombatModifier
        end
    elseif currentCombatModifier < 0 then
        for _, skill in pairs(stats.combat) do
            skill.damage = skill.damage + currentCombatModifier -- subtracts since negative
        end
    end
    
    -- Apply new value
    currentCombatModifier = newValue
    if newValue > 0 then
        for _, skill in pairs(stats.combat) do
            skill.modifier = skill.modifier + newValue
        end
    elseif newValue < 0 then
        for _, skill in pairs(stats.combat) do
            skill.damage = skill.damage - newValue -- adds abs value since newValue is negative
        end
    end
    
    notifyAAM()
    print(string.format("SWIMMING SKILL MOD: Combat effectiveness %+d", newValue))
end

local function removeCombatModifier()
    if currentCombatModifier > 0 then
        for _, skill in pairs(stats.combat) do
            skill.modifier = skill.modifier - currentCombatModifier
        end
        print(string.format("SWIMMING SKILL MOD: Removed combat bonus (+%d)", currentCombatModifier))
    elseif currentCombatModifier < 0 then
        for _, skill in pairs(stats.combat) do
            skill.damage = skill.damage + currentCombatModifier -- subtracts since negative
        end
        print(string.format("SWIMMING SKILL MOD: Removed combat penalty (%d damage)", currentCombatModifier))
    end
    currentCombatModifier = 0
    notifyAAM()
end

local function createBreathUI()
    if breathElement then breathElement:destroy() end
    local MWUI = I.MWUI
    breathElement = ui.create({
        type = ui.TYPE.Container,
        layer = 'HUD',
        template = MWUI.templates.boxSolidThick,
        props = {
            relativePosition = v2(0.5, 0),
            anchor = v2(0.5, 0),
            position = v2(0, 36),
        },
        content = ui.content {
            {
                name = 'inner',
                type = ui.TYPE.Flex,
                props = {
                    horizontal = false,
                    align = ui.ALIGNMENT.Center,
                    arrange = ui.ALIGNMENT.Center,
                    size = v2(200, 50),
                    autoSize = false
                },
                content = ui.content {
                    {
                        { props = { size = v2(1, 1) * 2 } },
                        type = ui.TYPE.Text,
                        template = MWUI.templates.textNormal,
                        props = {
                            text = core.getGMST('sBreath') or "Breath",
                            textColor = textColor,
                            textAlignH = ui.ALIGNMENT.Center,
                        },
                    },
                    { props = { size = v2(1, 1) * 2 } },
                    {
                        name = 'barOuter',
                        type = ui.TYPE.Widget,
                        template = MWUI.templates.borders,
                        props = {
                            size = v2(180, 8),
                        },
                        content = ui.content {
                            {
                                name = 'fill',
                                type = ui.TYPE.Image,
                                props = {
                                    resource = whiteTex,
                                    color = barColor,
                                    relativeSize = v2(1, 1),
                                },
                            },
                        },
                    },
                },
            },
        },
    })
end

local drownColor = util.color.hex("8b0000")

local function updateBreathUI(ratio, dt)
    if not breathElement or not breathElement.layout then return end
    local fill = breathElement.layout.content.inner.content.barOuter.content.fill
    if ratio <= 0 then
        drownPulseTimer = drownPulseTimer + dt
        local alpha = 0.3 + 0.7 * math.abs(math.sin(drownPulseTimer * 4))
        fill.props.relativeSize = v2(1, 1)
        fill.props.color = drownColor
        fill.props.alpha = alpha
    else
        drownPulseTimer = 0
        fill.props.relativeSize = v2(math.min(1, ratio), 1)
        fill.props.color = barColor
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

local function onInputAction(action)
    if action == input.ACTION.Jump then
        if types.Actor.isSwimming(self) and canDash then
            local currentFatigue = stats.fatigue.current
            
            local dashSpeed, fatigueCost, duration = getDashParameters()
            
            if currentFatigue >= fatigueCost then
                -- Block dash if drowning (no breath left)
                local maxBreath = getMaxBreathDuration()
                if underwaterTime >= maxBreath then
                    ui.showMessage("Can't dash while drowning")
                    return
                end

                canDash = false
                
                stats.fatigue.current = math.max(0, currentFatigue - fatigueCost)
                
                stats.speed.modifier = math.max(0, stats.speed.modifier + dashSpeed)
                dashTotal = dashTotal + dashSpeed
                
                if dashSfxVolume > 0 then
                    local skillStat = API.getSkillStat(skillId)
                    local swimmingSkill = skillStat and skillStat.modified or 5
                    local pitchBonus = (swimmingSkill / 100.0) * 0.3
                    
                    ambient.playSound("footwaterleft", {
                        volume = 0.6 * dashSfxVolume,
                        pitch = (0.95 + pitchBonus + 0.1 * math.random())
                    })
                    ambient.playSound("footwaterright", {
                        volume = 0.6 * dashSfxVolume,
                        pitch = (0.95 + pitchBonus + 0.1 * math.random())
                    })
                end
                
                print(string.format("SWIMMING SKILL MOD: DASH! +%.0f speed for %.2fs (%.0f fatigue)",
                    dashSpeed, duration, fatigueCost))
                
                -- Dashing underwater uses some breath
                if waterBreathingActive then
                    underwaterTime = math.min(maxBreath, underwaterTime + dashBreathCost)
                    updateBreathUI(1 - (underwaterTime / maxBreath), 0)
                end
                
                async:newUnsavableSimulationTimer(
                    duration,
                    function()
                        stats.speed.modifier = math.max(0, stats.speed.modifier - dashTotal)
                        dashTotal = 0
                        canDash = true
                    end
                )
            else
                ui.showMessage(string.format("Not enough fatigue for dash (need %.0f)", fatigueCost))
            end
        end
    end
end

local function hasExternalWaterBreathing()
	local mag = playerActiveEffects:getEffect("waterbreathing").magnitude
	if waterBreathingActive then
		return mag >= 2
	else
		return mag >= 1
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
	if dt == 0 then return end
    -- Cache nose level once (race/gender never change)
    if not noseLevel then
        local npcRecord = types.NPC.record(self)
        if npcRecord then
            local raceRecord = types.NPC.races.record(npcRecord.race)
            if npcRecord.isMale then
                noseLevel = raceRecord.height.male * 147.5*0.9/fSwimHeightScale
            else
                noseLevel = raceRecord.height.female * 147.5*0.9/fSwimHeightScale
            end
        else
            noseLevel = 147.5*0.9/fSwimHeightScale
        end
    end

    -- Throttled: skill gain and swim stat modifiers
    checkTimer = checkTimer + dt
	local isSwimming = types.Actor.isSwimming(self)
    if checkTimer >= CHECK_INTERVAL then
        checkTimer = 0
        if isSwimming then
            API.skillUsed(skillId, { useType = 1 })
            if not wasSwimming then
                applySpeedBonus()
                applyCombatModifier()
                wasSwimming = true
            end
        else
            if wasSwimming then
                removeSpeedBonus()
                removeCombatModifier()
                wasSwimming = false
            end
        end
    end
	if not isSwimming and not waterBreathingActive and not breathElement then
		return
	end
    -- Per-frame: underwater water breathing
    local cellWaterLevel = self.cell.waterLevel or -99999999
    local isUnderwater = (cellWaterLevel - noseLevel) > self.position.z
    local maxBreath = getMaxBreathDuration()

    if isUnderwater then
        if hasExternalWaterBreathing() then
            -- External source handles it; remove our spell
            if waterBreathingActive then
                playerSpells:remove('swimmingskill_waterbreathing')
                waterBreathingActive = false
            end
            -- Slowly recharge breath
            if underwaterTime > 0 then
                local rechargeRate = maxBreath / breathRechargeDuration
                underwaterTime = math.max(0, underwaterTime - rechargeRate * dt)
                if underwaterTime <= 0 then
                    underwaterTime = 0
                    destroyBreathUI()
                else
                    updateBreathUI(1 - (underwaterTime / maxBreath), dt)
                end
            end
        else
            -- Grant our water breathing spell if not yet active
            if not waterBreathingActive then
                playerSpells:add('swimmingskill_waterbreathing')
                waterBreathingActive = true
            end

            underwaterTime = math.min(underwaterTime + dt, maxBreath)

            if not breathElement then
                createBreathUI()
            end

            if underwaterTime >= maxBreath then
                -- Drowning: remove spell, updateBreathUI handles the pulse
                if waterBreathingActive then
                    playerSpells:remove('swimmingskill_waterbreathing')
                    waterBreathingActive = false
                end
                updateBreathUI(0, dt)
            else
                updateBreathUI(1 - (underwaterTime / maxBreath), dt)
            end
        end
    else
        -- Surfaced: remove spell
        if waterBreathingActive then
            playerSpells:remove('swimmingskill_waterbreathing')
            waterBreathingActive = false
            print("SWIMMING SKILL MOD: Water breathing removed (surfaced)")
        end

        -- Recharge: tick underwaterTime back toward 0
        if underwaterTime > 0 then
            local rechargeRate = maxBreath / breathRechargeDuration
            underwaterTime = math.max(0, underwaterTime - rechargeRate * dt)

            if underwaterTime <= 0 then
                underwaterTime = 0
                destroyBreathUI()
            else
                updateBreathUI(1 - (underwaterTime / maxBreath), dt)
            end
        end
    end
end

-- Console: "lua swim 50" to set level
local function onConsoleCommand(mode, command)
    local cmd = command:gsub("^%s*[Ll][Uu][Aa]%s+", "")
    local prefix, arg = cmd:match("^(%S+)%s*(%S*)")
    if not prefix or prefix:lower() ~= "swim" then return end
    local s = API.getSkillStat(skillId)
    if not s then return end
    local level = tonumber(arg)
    if level then
        s.base = math.max(0, math.floor(level))
        ui.showMessage("Swimming skill set to " .. level)
        if wasSwimming then applySpeedBonus(); applyCombatModifier() end
    else
        ui.showMessage(string.format("Swimming skill: base=%d modified=%d", s.base, s.modified))
    end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onInputAction = onInputAction,
        onConsoleCommand = onConsoleCommand,
        onSave = function()
            return {
                wasSwimming = wasSwimming,
                currentSpeedBonus = currentSpeedBonus,
                currentCombatModifier = currentCombatModifier,
                dashTotal = dashTotal,
                waterBreathingActive = waterBreathingActive,
                underwaterTime = underwaterTime,
                version = 2
            }
        end,
        onLoad = function(data)
            if data then
                wasSwimming = data.wasSwimming or false
                currentSpeedBonus = data.currentSpeedBonus or 0
                currentCombatModifier = data.currentCombatModifier or 0
                dashTotal = data.dashTotal or 0
                waterBreathingActive = data.waterBreathingActive or false
                underwaterTime = data.underwaterTime or 0
                
                if dashTotal > 0 then
                    stats.speed.modifier = math.max(0, stats.speed.modifier - dashTotal)
                    dashTotal = 0
                end
				
                if currentCombatModifier ~= 0 then
                    removeCombatModifier()
                end

                -- Schedule stuck modifier cleanup for saves coming from v1
                if not data.version or data.version < 2 then
                    cleanupStuckModifiers()
                    print("SWIMMING SKILL MOD: v1 save detected, will check for stuck combat modifiers")
                end
            end
        end,
    }
}