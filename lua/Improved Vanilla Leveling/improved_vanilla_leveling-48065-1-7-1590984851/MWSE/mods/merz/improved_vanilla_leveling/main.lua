local mod = '[Improved Vanilla Leveling]'
local version = '1.7'
local data_version = '1.1'

local function OutOfDate()
    local msg = 'MWSE is out of date! Update to use this mod.'
    tes3.messageBox(mod .. '\n' .. msg)
    mwse.log(mod .. ' '.. msg)
end

if mwse.buildDate == nil or mwse.buildDate < 20200530 then
    event.register('initialized', OutOfDate)
    return
end

local config = require('merz.improved_vanilla_leveling.config')
require('merz.improved_vanilla_leveling.mcm')
local save_data, attributes, ratio, is_capped, has_tooltip, iLevelUp10Mult, start_base_health, start_base_end
local chargen_complete = false

local function UpdateGMSTCache()
    -- Update cached GMST values in case they've changed. (compatiblity with other lua mods)
    iLevelUp10Mult = tes3.findGMST(tes3.gmst.iLevelUp10Mult).value
    ratio = iLevelUp10Mult / 10 -- Represents the amount of attribute progress per skillup.
end

local function UpdateHealth()
    if config.retroactive_health then
        -- Calculate health as though we took the maximum endurance increases as early as possible.
        -- In a vanilla game, this is 5 endurance per level.
        -- This function should be called when endurance increases and at level up.
        UpdateGMSTCache()
        local fLevelUpHealthEndMult = tes3.findGMST(tes3.gmst.fLevelUpHealthEndMult).value
        local mp = tes3.mobilePlayer
        local health = start_base_health
        local end_delta = (mp.endurance.base - start_base_end)
        local level_end = start_base_end
        for _ = 1, mp.object.level - 1 do
            if end_delta > 0 then
                if end_delta > iLevelUp10Mult then
                    level_end = level_end + iLevelUp10Mult
                    end_delta = end_delta - iLevelUp10Mult
                else
                    level_end = mp.endurance.base
                    end_delta = 0
                end
            end
            health = health + level_end * fLevelUpHealthEndMult
        end
        health = math.round(health * 10) / 10 -- Round to the nearest 0.1
        local health_increase = health - mp.health.base
        tes3.setStatistic({ reference = mp, name = 'health', base = health })
        tes3.modStatistic({ reference = mp, name = 'health', current = health_increase })
    end
end

local function CalcBaseStats()
    local mp = tes3.mobilePlayer
    local start_base_str
    -- Check race starting strength and endurance
    local race_attr = mp.object.race.baseAttributes
    if mp.object.female then
        start_base_end = race_attr[tes3.attribute.endurance + 1].female
        start_base_str = race_attr[tes3.attribute.strength + 1].female
    else
        start_base_end = race_attr[tes3.attribute.endurance + 1].male
        start_base_str = race_attr[tes3.attribute.strength + 1].male
    end
    -- Check class favored attributes.
    local class_attr = mp.object.class.attributes
    if class_attr[1] == tes3.attribute.endurance or class_attr[2] == tes3.attribute.endurance then
        start_base_end = start_base_end + 10
    end
    if class_attr[1] == tes3.attribute.strength or class_attr[2] == tes3.attribute.strength then
        start_base_str = start_base_str + 10
    end
    start_base_health = (start_base_end + start_base_str) / 2
    -- Does birthsign exist? Handle alternate start mods that break chargen.
    if mp.birthsign then
        -- Check birthsign for endurance. Not included in vanilla initial health calculation.
        local current = mp.birthsign.spells.iterator.head
        while current ~= nil do
            local spell = current.nodeData
            if spell.castType == tes3.spellType.ability then
                for i = 1, spell:getActiveEffectCount() do
                    local effect = spell.effects[i]
                    if effect.id == tes3.effect.fortifyAttribute and effect.attribute == tes3.attribute.endurance then
                        start_base_end = start_base_end + effect.max
                    end
                end
            end
            current = current.nextNode
        end
    else
        mwse.log(mod .. ' Warning: no birthsign found.')
    end
end

local function AddSaveData()
    if save_data == nil then
        local mp = tes3.mobilePlayer
        tes3.player.data.merz_improved_vanilla_leveling = {}
        save_data = tes3.player.data.merz_improved_vanilla_leveling
        save_data.version = data_version
        save_data.attribute_caps = {}
        save_data.lpa_cache = {}
        save_data.skillup_count = {}
        save_data.attribute_count = {}
        for i = 1, #mp.attributes do
            save_data.attribute_caps[i] = 0
            save_data.lpa_cache[i] = mp.levelupsPerAttribute[i]
            save_data.skillup_count[i] = mp.levelupsPerAttribute[i]
            save_data.attribute_count[i] = 0
        end
    elseif save_data.version == nil then
        -- Convert old characters to the new cap format.
        local mp = tes3.mobilePlayer
        save_data.version = data_version
        for i = 1, #save_data.attribute_caps do
            save_data.attribute_caps[i] = save_data.attribute_caps[i] - mp.attributes[i].base
        end
    end
end

-- Check for character generation to be complete, then turn this off.
local function OnSimulate()
    if tes3.findGlobal('CharGenState').value == -1 then
        event.unregister('simulate', OnSimulate)
        AddSaveData()
        CalcBaseStats()
        UpdateHealth()
        chargen_complete = true
    end
end

local function OnLoaded(e)
    save_data = tes3.player.data.merz_improved_vanilla_leveling
    if e.newGame then
        chargen_complete = false
        event.register('simulate', OnSimulate)
    else
        AddSaveData()
        CalcBaseStats()
        UpdateHealth()
        chargen_complete = true
    end
end

local function CleanupCounts(i)
    -- Reduce counts if possible, effectively removing anything already 'paid' for.
    -- This should be called after either of the counts has been manipulated.
    UpdateGMSTCache()
    while save_data.skillup_count[i] >= 10 and save_data.attribute_count[i] >= iLevelUp10Mult do
        save_data.skillup_count[i] = save_data.skillup_count[i] - 10
        save_data.attribute_count[i] = save_data.attribute_count[i] - iLevelUp10Mult
    end
end

local function HasAssociatedSkill(attribute)
    for _, skillId in pairs(tes3.skill) do
        if tes3.getSkill(skillId).attribute == attribute then
            return true
        end
    end
    return false
end

local function UpdateLpa(i)
    -- Update the levelupsPerAttribute tracked by the game. This affects what shows up in the MCP tooltip and what's
    -- used for attribute multipliers at level up time.
    -- We keep track of the true progress via skillup_count and attribute_count. Set levelupsPerAttribute to the
    -- largest integer that doesn't exceed true progress. Since the game can't handle negative values properly, set it
    -- to zero if less than zero.
    if HasAssociatedSkill(i - 1) then
        local mp = tes3.mobilePlayer
        if is_capped and mp.attributes[i].base == 100 then
            mp.levelupsPerAttribute[i] = 0
        else
            UpdateGMSTCache()
            local used = math.ceil(save_data.attribute_count[i] / ratio)
            mp.levelupsPerAttribute[i] = math.max(0, save_data.skillup_count[i] - used)
        end
        save_data.lpa_cache[i] = mp.levelupsPerAttribute[i]
    end
end

local function CheckForAttributeIncrease(i)
    -- Check to see if we've accumulated enough skill ups to raise a given attribute.
    UpdateGMSTCache()
    local mp = tes3.mobilePlayer
    if save_data.attribute_count[i] < iLevelUp10Mult then
        local attribute_inc = math.floor(save_data.skillup_count[i] * ratio) - save_data.attribute_count[i]
        if attribute_inc >= 1 and save_data.attribute_caps[i] > 0 then
            if save_data.attribute_caps[i] < attribute_inc then
                attribute_inc = save_data.attribute_caps[i]
            end
            save_data.attribute_count[i] = save_data.attribute_count[i] + attribute_inc
            save_data.attribute_caps[i] = save_data.attribute_caps[i] - attribute_inc
            CleanupCounts(i)
            local attribute = i - 1
            tes3.modStatistic({ reference = mp, attribute = attribute, value = attribute_inc })
            if attribute == tes3.attribute.endurance then
                UpdateHealth()
            end
            local name = tes3.getAttributeName(attribute)
            name = name:gsub('^(%l)', string.upper)
            tes3.messageBox('Your %s attribute increased to %d.', name, mp.attributes[i].base)
        end
    end
end

local function UpdateCaps()
    -- Check for an over cap situation and redistribute the excess.
    if is_capped then
        UpdateGMSTCache()
        local mp = tes3.mobilePlayer
        local excess_cap = 0
        for i = 1, #mp.attributes do
            local max = mp.attributes[i].base + save_data.attribute_caps[i]
            if max > 100 then
                excess_cap = excess_cap + (max - 100)
                save_data.attribute_caps[i] = 100 - mp.attributes[i].base
            end
        end
        -- Add the extra cap as evenly as possible to the attributes with the highest outstanding progress.
        -- Only consider attributes with an associated skill (everything but luck by default).
        local int_min = -2147483648 -- 32-bit INT_MIN, this should be more than small enough for our purposes.
        while excess_cap > 0 do
            local max = int_min
            local max_index = 0
            for i = 1, #save_data.attribute_caps do
                if save_data.attribute_caps[i] + mp.attributes[i].base < 100 then
                    local outstanding = save_data.skillup_count[i] - 
                        math.ceil((save_data.attribute_count[i] + save_data.attribute_caps[i]) / ratio)
                    if outstanding > max and HasAssociatedSkill(i - 1) then
                        max = outstanding
                        max_index = i
                    end
                end
            end
            if max > int_min then
                save_data.attribute_caps[max_index] = save_data.attribute_caps[max_index] + 1
                excess_cap = excess_cap - 1
            else
                -- All caps at max.
                excess_cap = 0
            end
        end
    end
end

local function OnSkillRaised(e)
    -- UpdateCaps() is necessary because something else might have raised an attribute without us knowing about it,
    -- e.g. quest reward, other mod, etc.
    UpdateCaps()
    local mp = tes3.mobilePlayer
    local i = tes3.getSkill(e.skill).attribute + 1
    -- How many levelups were added for this attribute? Might be more than 1 if GMSTs are modified.
    local levelup_inc = mp.levelupsPerAttribute[i] - save_data.lpa_cache[i]
    save_data.skillup_count[i] = save_data.skillup_count[i] + levelup_inc
    CleanupCounts(i)
    CheckForAttributeIncrease(i)
    UpdateLpa(i)
end

local function CheckForLpaIncrease()
    -- This function is necessary because other mods will change levelupsPerAttribute without raising any events
    -- e.g., anything using Skills Module, Ashfall, etc.
    -- Update levelupsPerAttribute to the correct value, but don't raise any attributes. That will only happen after
    -- level up or when raising a skill that shares the same governing attribute.
    local mp = tes3.mobilePlayer
    for i = 1, #mp.levelupsPerAttribute do
        local increase = mp.levelupsPerAttribute[i] - save_data.lpa_cache[i]
        if increase > 0 then
            save_data.skillup_count[i] = save_data.skillup_count[i] + increase
            CleanupCounts(i)
            UpdateLpa(i)
        end
    end
end

local function OnSave()
    -- Make sure that we've captured any changes to levelupsPerAttribute before saving.
    CheckForLpaIncrease()
end

local function OnPreLevelUp()
    -- Save current attributes so that we can determine what the player selects when leveling up.
    -- Using this event is a better solution than trying to keep a copy in saved_data, since we can't always detect
    -- when they are changed.
    attributes = {}
    local mp = tes3.mobilePlayer
    for i = 1, #mp.attributes do
        attributes[i] = mp.attributes[i].base
    end
    -- Capture any changes to levelupsPerAttribute so that they are correctly reflected in level up multipliers.
    CheckForLpaIncrease()
end

local function OnLevelUp()
    UpdateGMSTCache()
    -- Check to see which attributes have increased.
    local mp = tes3.mobilePlayer
    local excess_cap = 0
    for i = 1, #mp.attributes do
        local delta = mp.attributes[i].base - attributes[i]
        if delta > 0 then
            save_data.attribute_count[i] = save_data.attribute_count[i] + delta
            CleanupCounts(i)
            local attribute = i - 1
            -- Only adjust cap if this attribute has an associated skill. This excludes Luck by default.
            if HasAssociatedSkill(attribute) then
                save_data.attribute_caps[i] = save_data.attribute_caps[i] + iLevelUp10Mult - delta
            end
        end
    end
    -- Check for over cap and redistribute any excess.
    UpdateCaps()
    -- Check for any skillups due to excess cap increases.
    for i = 1, #mp.attributes do
        CheckForAttributeIncrease(i)
        UpdateLpa(i)
    end
    UpdateHealth()
end

local function OnMenuStatLevelTooltip(e)
    e.source:forwardEvent(e)
    if not config.levelup_tooltip or not chargen_complete then
        return
    end
    local tooltip = tes3ui.findHelpLayerMenu(tes3ui.registerID('HelpMenu'))
    local layout = tooltip.children[1].children[1]
    local children = layout.children
    children[2].borderBottom = 6
    -- Hide the MCP tooltip attributes
    if has_tooltip then
        for i = 3, #children do -- first attribute starts at index 3
            children[i].visible = false
        end
    end
    -- UpdateCaps() is necessary because something else might have raised an attribute without us knowing about it,
    -- e.g. quest reward, other mod, etc.
    UpdateCaps()
    -- Capture any changes to levelupsPerAttribute so that they are correctly reflected in the tooltip.
    CheckForLpaIncrease()
    local mp = tes3.mobilePlayer
    for i = 1, #mp.attributes do
        local attribute_block = layout:createBlock({})
        attribute_block.flowDirection = 'left_to_right'
        attribute_block.autoHeight = true
        attribute_block.autoWidth = true
        attribute_block.widthProportional = 1.0
        attribute_block.childAlignX = -1
        local attribute = tes3.attributeName[i - 1]:gsub('^(%l)', string.upper)
        local cap = save_data.attribute_caps[i] + mp.attributes[i].base
        attribute = attribute .. string.format(': (%d/%d)', mp.attributes[i].base, cap)
        attribute_block:createLabel({text = attribute})
        local level_ups = 0
        if HasAssociatedSkill(i - 1) then
            local used = math.round(10 * save_data.attribute_count[i] / ratio) / 10 -- round to nearest 0.1
            level_ups = save_data.skillup_count[i] - used
        end
        attribute_block:createLabel({text = string.format('%01.1f', level_ups)})
    end
end

local function OnMenuStatActivated(e)
    local MenuStat_level_layout = e.element:findChild(tes3ui.registerID('MenuStat_level_layout'))
    local MenuStat_level = MenuStat_level_layout:findChild(tes3ui.registerID('MenuStat_level'))
    -- Add the updated tooltip to the number indicating the current level.
    MenuStat_level:register('help', OnMenuStatLevelTooltip)
    -- Find the "Level" label and add the updated tooltip to it.
    for _, child in pairs(MenuStat_level_layout.children) do
        if child.text == 'Level' then
            child:register('help', OnMenuStatLevelTooltip)
            break
        end
    end
end

local function OnInitialized()
    -- Check for for whether we're susceptible to the skill increase gmst bug.
    -- We are if any of the affected GMSTs have a value other than 1 and the patch hasn't been applied.
    local iLevelupMajorMultAttribute = tes3.findGMST(tes3.gmst.iLevelupMajorMultAttribute).value
    local iLevelupMinorMultAttribute = tes3.findGMST(tes3.gmst.iLevelupMinorMultAttribute).value
    local iLevelupMajorMult = tes3.findGMST(tes3.gmst.iLevelupMajorMult).value
    local iLevelupMinorMult = tes3.findGMST(tes3.gmst.iLevelupMinorMult).value
    local gmst_fix = include('merz.skill_increase_gmst_fix.interop')
    if (iLevelupMajorMultAttribute ~= 1 or iLevelupMinorMultAttribute ~= 1 or iLevelupMajorMult ~= 1 or
     iLevelupMinorMult ~= 1) and (gmst_fix == nil or not gmst_fix.is_patched) then
        local msg = 'Mod disabled. One or more of the iLevelup* GMSTs has a value other than 1 and "Skill Increase GMST Fix" has not been applied.'
        tes3.messageBox(mod .. '\n' .. msg)
        mwse.log(mod .. ' ' .. msg)
    else
        UpdateGMSTCache()
        is_capped = not tes3.hasCodePatchFeature(108) -- Check for uncapped attributes patch.
        has_tooltip = tes3.hasCodePatchFeature(275) -- Check for levelup tooltip patch.
        event.register('uiActivated', OnMenuStatActivated, { filter = 'MenuStat' })
        event.register('loaded', OnLoaded)
        event.register('skillRaised', OnSkillRaised)
        event.register('preLevelUp', OnPreLevelUp)
        event.register('levelUp', OnLevelUp)
        event.register('onSave', OnSave)
        mwse.log(mod .. ' Initialized Version ' .. version)
    end
end
event.register('initialized', OnInitialized)