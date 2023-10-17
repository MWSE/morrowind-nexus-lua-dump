local config = require('MechanicsRemastered.config')

-- Level Up Overhaul

local levelupBaseAttributes = nil
local levelupAttributeSkills = nil
local levelupAttributeMultis = nil
local levelupAttrGMSTs = nil
local levelupInitialAttributes = nil

local function recordAttrMultiGMSTs()
    levelupAttrGMSTs = {
        tes3.gmst.iLevelUp01Mult,
        tes3.gmst.iLevelUp02Mult,
        tes3.gmst.iLevelUp03Mult,
        tes3.gmst.iLevelUp04Mult,
        tes3.gmst.iLevelUp05Mult,
        tes3.gmst.iLevelUp06Mult,
        tes3.gmst.iLevelUp07Mult,
        tes3.gmst.iLevelUp08Mult,
        tes3.gmst.iLevelUp09Mult,
        tes3.gmst.iLevelUp10Mult
    }
end

local function resetDefaultGMSTs()
    -- Reset the settings to defaults, in case something breaks badly!
    for ix, key in pairs(levelupAttrGMSTs) do
        local gmst = tes3.findGMST(key)
        gmst.value = gmst.defaultValue
    end
end

local function recordAttrMultiGMSTValues()
    levelupAttributeMultis = {
        tes3.findGMST(tes3.gmst.iLevelUp01Mult).value,
        tes3.findGMST(tes3.gmst.iLevelUp02Mult).value,
        tes3.findGMST(tes3.gmst.iLevelUp03Mult).value,
        tes3.findGMST(tes3.gmst.iLevelUp04Mult).value,
        tes3.findGMST(tes3.gmst.iLevelUp05Mult).value,
        tes3.findGMST(tes3.gmst.iLevelUp06Mult).value,
        tes3.findGMST(tes3.gmst.iLevelUp07Mult).value,
        tes3.findGMST(tes3.gmst.iLevelUp08Mult).value,
        tes3.findGMST(tes3.gmst.iLevelUp09Mult).value,
        tes3.findGMST(tes3.gmst.iLevelUp10Mult).value
    }
end

local function restoreAttrMultiGMSTs()
    tes3.findGMST(tes3.gmst.iLevelUp01Mult).value = levelupAttributeMultis[1]
    tes3.findGMST(tes3.gmst.iLevelUp02Mult).value = levelupAttributeMultis[2]
    tes3.findGMST(tes3.gmst.iLevelUp03Mult).value = levelupAttributeMultis[3]
    tes3.findGMST(tes3.gmst.iLevelUp04Mult).value = levelupAttributeMultis[4]
    tes3.findGMST(tes3.gmst.iLevelUp05Mult).value = levelupAttributeMultis[5]
    tes3.findGMST(tes3.gmst.iLevelUp06Mult).value = levelupAttributeMultis[6]
    tes3.findGMST(tes3.gmst.iLevelUp07Mult).value = levelupAttributeMultis[7]
    tes3.findGMST(tes3.gmst.iLevelUp08Mult).value = levelupAttributeMultis[8]
    tes3.findGMST(tes3.gmst.iLevelUp09Mult).value = levelupAttributeMultis[9]
    tes3.findGMST(tes3.gmst.iLevelUp10Mult).value = levelupAttributeMultis[10]
end

local function calculateAttrBonuses(skillUps)
    local bonus = 0
    local multiIx = skillUps

    -- If there were no skill increases, there is no bonus.
    if (multiIx < 1) then
        return bonus
    end

    -- If there have been more than 10 skill increases, limit to 10.
    if (multiIx > 10) then
        multiIx = 10
    end

    -- Retrieve the bonus from the recorded GMSTs.
    bonus = levelupAttributeMultis[multiIx]

    -- If there are more than 10 skill increases, recursively increase the bonus further.
    skillUps = skillUps - 10
    if (skillUps > 0) then
        bonus = bonus + calculateAttrBonuses(skillUps)
    end

    return bonus
end

local function setCustomAttrBonus(attrIx, bonus)
    -- Hijack the GMST and skill increases to assign attribute specific bonuses.
    local gmst = tes3.findGMST(levelupAttrGMSTs[attrIx])
    gmst.value = bonus
    tes3.mobilePlayer.levelupsPerAttribute[attrIx] = attrIx
end

local function calculateMaxAttrIncrease() 
    -- Calculates the maximum attribute increase prior to levelling up.
    local currentLevel = tes3.mobilePlayer.object.level
    local maxIncrease = (currentLevel) * tes3.findGMST(tes3.gmst.iLevelUp10Mult).value
    return maxIncrease
end

local function calculateAttrSkillSpend(bonus)
    local skillSpend = 0
    local bonusRemaining = bonus
    local x10Bonus = levelupAttributeMultis[10]

    -- While the bonus is greater than the max for a single level, bulk calculate through the levels.
    while (bonusRemaining >= x10Bonus) do
        skillSpend = skillSpend + 10
        bonusRemaining = bonusRemaining - x10Bonus
    end

    -- Once it's below the max, reverse order search (to spend the most skills possible for the bonus).
    if (bonusRemaining == levelupAttributeMultis[9]) then skillSpend = skillSpend + 9
    elseif (bonusRemaining == levelupAttributeMultis[8]) then skillSpend = skillSpend + 8
    elseif (bonusRemaining == levelupAttributeMultis[7]) then skillSpend = skillSpend + 7
    elseif (bonusRemaining == levelupAttributeMultis[6]) then skillSpend = skillSpend + 6
    elseif (bonusRemaining == levelupAttributeMultis[5]) then skillSpend = skillSpend + 5
    elseif (bonusRemaining == levelupAttributeMultis[4]) then skillSpend = skillSpend + 4
    elseif (bonusRemaining == levelupAttributeMultis[3]) then skillSpend = skillSpend + 3
    elseif (bonusRemaining == levelupAttributeMultis[2]) then skillSpend = skillSpend + 2
    elseif (bonusRemaining == levelupAttributeMultis[1]) then skillSpend = skillSpend + 1
    end

    return skillSpend
end

local function inferBaseAttributes()
    levelupInitialAttributes = {}

    -- Racial base attributes
    for ix, attr in pairs(tes3.mobilePlayer.object.race.baseAttributes) do
        if tes3.mobilePlayer.object.female then
            levelupInitialAttributes[ix] = attr.female
        else
            levelupInitialAttributes[ix] = attr.male
        end
    end

    -- Class base attribute bonus
    for ix, attr in pairs(tes3.mobilePlayer.object.class.attributes) do
        levelupInitialAttributes[attr + 1] = levelupInitialAttributes[attr + 1] + 10
    end

    -- Birthsign bonuses
    if tes3.mobilePlayer.birthsign then
        for _, spell in pairs(tes3.mobilePlayer.birthsign.spells) do
            if spell.castType == tes3.spellType.ability then
                for i = 1, spell:getActiveEffectCount() do
                    local effect = spell.effects[i]
                    if effect.id == tes3.effect.fortifyAttribute then
                        levelupInitialAttributes[effect.attribute + 1] = levelupInitialAttributes[effect.attribute + 1] + effect.max
                    end
                end
            end
        end
    end
end

--- @param e preLevelUpEventData
local function preLevelUpCallback(e)
    inferBaseAttributes()

    if (config.LevelupPersistSkills or config.LevelupUncappedBonus) then
        levelupBaseAttributes = {}
        levelupAttributeSkills = {}

        -- Record the pre-level up attribues to compare later.
        for ix, attr in pairs(tes3.mobilePlayer.attributes) do
            levelupBaseAttributes[ix] = attr.base
        end

        -- Record the pre-level up skill increases so they can be reapplied later.
        for ix, skill in pairs(tes3.mobilePlayer.levelupsPerAttribute) do
            levelupAttributeSkills[ix] = skill
        end

        -- Record current multipier GMSTs to restore later.
        recordAttrMultiGMSTValues()

        if (config.LevelupUncappedBonus) then
            -- Calculate custom attribute bonuses and override GMSTs.
            for ix, skill in pairs(tes3.mobilePlayer.levelupsPerAttribute) do
                local bonus = calculateAttrBonuses(skill)

                -- If there isn't a bonus, it can still be increased by 1.
                if (bonus == 0) then
                    bonus = 1
                end

                -- If the attributes aren't uncapped, it can only increase up to 100.
                if (tes3.hasCodePatchFeature(tes3.codePatchFeature.attributeUncap) == false) then
                    maxBonus = 100 - levelupBaseAttributes[ix]
                    if (maxBonus < bonus) then
                        bonus = maxBonus
                    end
                end

                -- Reduce the bonus to the maximum theoretical at that player level.
                local maxSkill = levelupInitialAttributes[ix] + calculateMaxAttrIncrease()
                local maxIncrease = maxSkill - levelupBaseAttributes[ix]
                -- The max increase is always at least 5.
                if (maxIncrease < levelupAttributeMultis[10]) then
                    maxIncrease = levelupAttributeMultis[10]
                end
                if (maxIncrease < bonus) then
                    bonus = maxIncrease
                end

                setCustomAttrBonus(ix, bonus)
            end
        end
    end
end

--- @param e levelUpEventData
local function levelUpCallback(e)
    if (config.LevelupPersistSkills or config.LevelupUncappedBonus) then

        if (config.LevelupPersistSkills) then
            -- Check to find which attributes were increased during level up.
            for ix, attr in pairs(tes3.mobilePlayer.attributes) do
                local preAttr = levelupBaseAttributes[ix]

                -- If this attribute was increased, reduce the saved skill ups for it.
                if (attr.base > preAttr) then
                    local attrBonus = attr.base - preAttr
                    local spend = calculateAttrSkillSpend(attrBonus)

                    levelupAttributeSkills[ix] = levelupAttributeSkills[ix] - spend
                    -- If there were less than 10 skill ups, they have also all been used.
                    if (levelupAttributeSkills[ix] < 0) then
                        levelupAttributeSkills[ix] = 0
                    end
                end

                -- Update the skill ups for the player.
                tes3.mobilePlayer.levelupsPerAttribute[ix] = levelupAttributeSkills[ix]
            end
        end

        if (config.LevelupUncappedBonus) then
            -- Restore multiplier GMSTs that were edited.
            restoreAttrMultiGMSTs()
        end
    end
end

--- @param e loadedEventData
local function loadedCallback(e)
    recordAttrMultiGMSTs()
    inferBaseAttributes()
end

--- @param e uiActivatedEventData
local function uiActivatedCallback(e)
    -- Modify the level up menu to make the bonus numbers visible when there are two digits.
    local menuList = e.element:findChild(tes3ui.registerID('MenuLevelUp_IconList'))
    for ix, el in pairs(menuList.children) do
        if (ix == 2 or ix == 5) then
            el.paddingRight = 10
            el.autoWidth = true
            el:getTopLevelMenu():updateLayout()
        end
    end
end

event.register(tes3.event.loaded, loadedCallback)
event.register(tes3.event.preLevelUp, preLevelUpCallback)
event.register(tes3.event.levelUp, levelUpCallback)
event.register(tes3.event.uiActivated, uiActivatedCallback, {filter = "MenuLevelUp"})
mwse.log(config.Name .. ' Level Up Module Initialised.')