local modInfo = require("EquipmentRequirements.modInfo")
local config = require("EquipmentRequirements.config")
local data = require("EquipmentRequirements.data")

local armorPen, weaponPen
local fatigueTime = 0

-- Returns the ID of the base item for a player-created enchanted item (only works if Consistent Enchanting was in use
-- when the item was created).
local function getBaseItemID(itemData)
    local id

    if itemData then
        local luaData = itemData.data

        if luaData then
            id = luaData.ncceEnchantedFrom
        end
    end

    return id
end

local function getSkillReqFromTable(id, objectType)
    if objectType == tes3.objectType.weapon
    or objectType == tes3.objectType.ammunition then
        return data.weaponReqs[id]
    elseif objectType == tes3.objectType.armor then
        return data.armorReqs[id]
    end
end

local function getSkillId(item, objectType)
    if objectType == tes3.objectType.weapon
    or objectType == tes3.objectType.ammunition then
        return item.skillId
    elseif objectType == tes3.objectType.armor then
        return data.armorClassSkills[item.weightClass]
    end
end

-- Returns the skill requirement for an item.
local function getItemSkillInfo(item, itemData)
    local objectType = item.objectType

    if objectType ~= tes3.objectType.weapon
    and objectType ~= tes3.objectType.ammunition
    and objectType ~= tes3.objectType.armor then
        return nil, nil
    end

    local skillId = getSkillId(item, objectType)
    local skillReq = getSkillReqFromTable(item.id:lower(), objectType)

    if not skillReq then
        local baseItemID = getBaseItemID(itemData)

        if baseItemID then
            skillReq = getSkillReqFromTable(baseItemID, objectType)

            if skillReq then
                skillReq = skillReq + 5
                skillReq = math.clamp(skillReq, 5, 100)
            end
        end
    end

    -- Item is not in our data tables, so use a generic formula instead depending on type.
    if not skillReq then
        if item.isMelee then
            skillReq = ( ( (item.chopMax + item.slashMax + item.thrustMax) / 3 ) * 0.25 ) * ( (item.speed * 2.15) * (item.reach * 1.85) ) * 1.15
        elseif item.isRanged
        or objectType == tes3.objectType.ammunition then
            skillReq = item.chopMax * 1.4
        elseif objectType == tes3.objectType.armor then
            skillReq = ( item.armorRating * 0.70 + (item.enchantCapacity / 120) ) * 1.4
        end

        -- At this point there's guaranteed to be a skillReq.
        skillReq = math.clamp(skillReq, 5, 100)
        skillReq = math.ceil(skillReq)
    end

    if skillReq <= 5 then
        skillReq = -5000
    end

    return skillReq, skillId
end

-- Adds our custom information to the item tooltip display.
local function reqTooltip(e)
    local skillReq, skillId = getItemSkillInfo(e.object, e.itemData)

    if not skillReq then
        return
    end

    local block = e.tooltip:createBlock()
    block.minWidth = 1
    block.maxWidth = 230
    block.autoWidth = true
    block.autoHeight = true
    block.paddingAllSides = 6
    local label

    if skillReq > 0 then
        label = block:createLabel{
            text = string.format("Requires %s: %u", tes3.skillName[skillId], skillReq),
        }
    else
        label = block:createLabel{
            text = "No Requirement",
        }
    end

    local color

    -- Mobile skills are off by 1 from MWSE skills.
    local mobSkillId = skillId + 1

    -- Make the text either red or green depending on the player's skill.
    if tes3.mobilePlayer.skills[mobSkillId].base < skillReq then
        color = tes3ui.getPalette("health_color")
    else
        color = tes3ui.getPalette("fatigue_color")
    end

    label.color = color
    label.wrapText = true
end

-- Prevents the player from equipping items with too high a skill requirement with alternate mode off.
local function onEquip(e)
    if e.reference ~= tes3.player then
        return
    end

    local item = e.item
    local skillReq, skillId = getItemSkillInfo(item, e.itemData)

    if not skillReq then
        return
    end

    local mobSkillId = skillId + 1

    -- Player's skill is too low, so display a message and prevent equip. Using base instead of current to prevent the
    -- player from cheesing Fortify Skill.
    if tes3.mobilePlayer.skills[mobSkillId].base < skillReq then
        local rationalNames = include("RationalNames.interop")
        local displayName = ( rationalNames and rationalNames.common.getDisplayName(item.id:lower()) ) or item.name
        tes3.messageBox("Your %s skill is too low to equip %s.", tes3.skillName[skillId], displayName)
        return false
    end
end

-- Runs on load, when the player's skills increase, and when the player equips or unequips something.
local function updatePenalty()
    armorPen = 0
    weaponPen = 0

    -- Look through everything the player has equipped, one at a time.
    for itemStack in tes3.iterate(tes3.player.object.equipment) do
        local object = itemStack.object
        local itemData = (itemStack.variables and itemStack.variables[1]) or nil
        local skillReq, skillId = getItemSkillInfo(object, itemData)

        if skillReq then
            local mobSkillId = skillId + 1

            if tes3.mobilePlayer.skills[mobSkillId].base < skillReq then
                if object.objectType == tes3.objectType.weapon
                or object.objectType == tes3.objectType.ammunition then
                    weaponPen = weaponPen + 1
                elseif object.objectType == tes3.objectType.armor then
                    armorPen = armorPen + 1
                end
            end
        end
    end
end

local function onSpellCast(e)
    if e.caster ~= tes3.player or armorPen == 0 then
        return
    end

    -- Cap cast chance at 100 before reducing.
    e.castChance = math.min(e.castChance, 100)

    -- Reduce chance to cast the spell depending on armor penalty.
    e.castChance = e.castChance - ( ( e.castChance / 20 ) * armorPen )
end

local function setCurFatigue(value)
    tes3.setStatistic{
        reference = tes3.player,
        name = "fatigue",
        current = math.max(value, 0),
    }
end

local function onCalcMoveSpeed(e)
    if e.reference ~= tes3.player or armorPen == 0 then
        return
    end

    -- Reduce movement speed depending on armor penalty.
    e.speed = e.speed - ( ( e.speed / 15 ) * armorPen )

    -- The fatigue penalty only applies when the player is running. fatigueTime is set to 1 every 0.1 second. This
    -- regulates how frequently fatigue is lost while running (otherwise it would depend on framerate).
    if not tes3.mobilePlayer.isRunning
    or tes3.mobilePlayer.fatigue.current <= 0
    or fatigueTime == 0 then
        return
    end

    -- Ensures this part won't happen again for another 0.1 second.
    fatigueTime = 0

    -- Determine how much fatigue is reduced depending on armor penalty.
    local newFatigue = tes3.mobilePlayer.fatigue.current - ( 6 * ( ( tes3.mobilePlayer.fatigue.base / 22525 ) * ( armorPen / 0.2 ) ) )
    setCurFatigue(newFatigue)
end

local function onAttack(e)
    if e.reference ~= tes3.player
    or weaponPen == 0
    or tes3.mobilePlayer.fatigue.current <= 0 then
        return
    end

    -- Fatigue is reduced by 1/6 max fatigue.
    local newFatigue = tes3.mobilePlayer.fatigue.current - ( tes3.mobilePlayer.fatigue.base / 6 )
    setCurFatigue(newFatigue)
end

-- Used to update the penalties when the player equips or unequips something.
local function updateStarter(e)
    if e.reference ~= tes3.player then
        return
    end

    updatePenalty()
end

-- Runs every 0.1 second with alternate mode on. Used to regulate how often the armor fatigue penalty applies while
-- running.
local function fatigueTimer()
    fatigueTime = 1
end

local function onLoaded()
    updatePenalty()

    timer.start{
        duration = 0.1,
        iterations = -1,
        callback = fatigueTimer,
    }
end

local function onInitialized()
    event.register("uiObjectTooltip", reqTooltip)

    if config.alternateMode then
        event.register("spellCast", onSpellCast)
        event.register("calcMoveSpeed", onCalcMoveSpeed)
        event.register("attack", onAttack)

        event.register("equipped", updateStarter)
        event.register("unequipped", updateStarter)
        event.register("skillRaised", updatePenalty)
        event.register("loaded", onLoaded)
    else
        event.register("equip", onEquip)
    end

    mwse.log("[%s %s] initialized.", modInfo.mod, modInfo.version)
end

event.register("initialized", onInitialized)

local function onModConfigReady()
    dofile("EquipmentRequirements.mcm")
end

event.register("modConfigReady", onModConfigReady)