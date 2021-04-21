local mod = "Equipment Requirements (Necro Edit)"
local version = "1.3.1"

local config = require("EquipmentRequirements.config")
local data = require("EquipmentRequirements.data")

local armorPen, weaponPen
local fatigueTime = 0

-- Returns the skill requirement for an item.
local function getItemSkillInfo(item)
    local skillReq, skillInfo

    -- Look up the item in our data tables, depending on its type.
    -- Also look up the skill associated with this item type.
    if item.objectType == tes3.objectType.weapon then
        skillReq = data.weaponReqs[item.id:lower()]
        skillInfo = data.weaponTypeInfo[item.typeName]
    elseif item.objectType == tes3.objectType.armor then
        skillReq = data.armorReqs[item.id:lower()]
        skillInfo = data.armorClassInfo[item.weightClass]
    elseif item.objectType == tes3.objectType.ammunition then
        skillReq = data.ammunitionReqs[item.id:lower()]
        skillInfo = data.ammunitionTypeInfo[item.typeName]
    end

    -- Item is not in our data tables, so use a generic formula instead depending on type.
    if not skillReq then
        if item.isMelee then
            skillReq = ( ( ( item.chopMax + item.slashMax + item.thrustMax ) / 3 ) * 0.25 ) * ( ( item.speed * 2.15 ) * ( item.reach * 1.85 ) ) * 1.15
            skillReq = math.clamp(skillReq, 5, 100)
            skillInfo = data.weaponTypeInfo[item.typeName]

        -- Only true for bows, crossbows and thrown weapons, not for ammunition.
        elseif item.isRanged then
            skillReq = item.chopMax * 1.4
            skillReq = math.clamp(skillReq, 5, 100)
            skillInfo = data.weaponTypeInfo[item.typeName]

        elseif item.objectType == tes3.objectType.armor then
            skillReq = ( item.armorRating * 0.70 + ( item.enchantCapacity / 120 ) ) * 1.4
            skillReq = math.clamp(skillReq, 5, 100)
            skillInfo = data.armorClassInfo[item.weightClass]

        elseif item.objectType == tes3.objectType.ammunition then
            skillReq = item.chopMax * 1.4
            skillReq = math.clamp(skillReq, 5, 100)
            skillInfo = data.ammunitionTypeInfo[item.typeName]
        end
    end

    -- If the item is not a weapon, armor or ammunition, these will be nil.
    return skillReq, skillInfo
end

-- Adds our custom information to the item tooltip display.
local function reqTooltip(e)
    local skillReq, skillInfo = getItemSkillInfo(e.object)

    -- This is not an equipment item, so do nothing.
    if not skillReq then
        return
    end

    -- Create a block for our info text.
    local block = e.tooltip:createBlock()
    block.minWidth = 1
    block.maxWidth = 230
    block.autoWidth = true
    block.autoHeight = true
    block.paddingAllSides = 6

    local label = block:createLabel{
        text = string.format("Requires %s: %u", skillInfo.text, skillReq),
    }

    local color

    -- Make the text either red or green depending on the player's skill.
    if tes3.mobilePlayer[skillInfo.name].base < skillReq then
        color = tes3ui.getPalette("health_color")
    else
        color = tes3ui.getPalette("fatigue_color")
    end

    label.color = color
    label.wrapText = true
end

-- Prevents the player from equipping items with too high a skill requirement.
-- The equip event is only registered if alternate mode is off.
local function onEquip(e)

    -- It's not the player doing the equipping, so bail.
    if e.reference ~= tes3.player then
        return
    end

    local skillReq, skillInfo = getItemSkillInfo(e.item)

    -- Not an equipment item, so bail.
    if not skillReq then
        return
    end

    -- Player's skill is too low, so display a message and prevent equip.
    -- Using base instead of current to prevent the player from cheesing Fortify Skill.
    if tes3.mobilePlayer[skillInfo.name].base < skillReq then
        tes3.messageBox("Your %s skill is too low to equip %s.", skillInfo.text, e.item.name)
        return false
    end
end

-- Runs on load, when the player's skills increase, and when the player equips or unequips something.
-- Only runs when alternate mode is on.
local function updatePenalty()
    armorPen = 0
    weaponPen = 0

    -- Look through everything the player has equipped, one at a time.
    for itemStack in tes3.iterate(tes3.player.object.equipment) do
        local object = itemStack.object
        local skillReq, skillInfo = getItemSkillInfo(object)

        -- This is an equipment item, as opposed to clothing.
        if skillReq then

            -- Player's skill is too low, so increment penalty depending on item type.
            if tes3.mobilePlayer[skillInfo.name].base < skillReq then
                if object.objectType == tes3.objectType.weapon then
                    weaponPen = weaponPen + 1
                elseif object.objectType == tes3.objectType.ammunition then
                    weaponPen = weaponPen + 1
                elseif object.objectType == tes3.objectType.armor then
                    armorPen = armorPen + 1
                end
            end
        end
    end
end

-- Runs when a spell is cast, but only with alternate mode on.
local function onSpellCast(e)

    -- Either it's not the player casting the spell or there's currently no armor penalty.
    if e.caster ~= tes3.player or armorPen == 0 then
        return
    end

    -- Cap cast chance at 100 before reducing.
    if e.castChance > 100 then
        e.castChance = 100
    end

    -- Reduce chance to cast the spell depending on armor penalty.
    e.castChance = e.castChance - ( ( e.castChance / 20 ) * armorPen )
end

-- Runs every frame for each actor that's moving, but only with alternate mode on.
local function onCalcMoveSpeed(e)

    -- It's not the player moving, or there's currently no armor penalty.
    if e.reference ~= tes3.player or armorPen == 0 then
        return
    end

    -- Reduce movement speed depending on armor penalty.
    e.speed = e.speed - ( ( e.speed / 15 ) * armorPen )

    -- The fatigue penalty only applies when the player is running.
    -- If fatigue is <= 0 there's no point.
    -- fatigueTime is set to 1 every 0.1 second. This regulates how frequently fatigue is lost while running (otherwise it would depend on framerate).
    if not tes3.mobilePlayer.isRunning
    or tes3.mobilePlayer.fatigue.current <= 0
    or fatigueTime == 0 then
        return
    end

    -- Ensures this part won't happen again for another 0.1 second.
    fatigueTime = 0

    -- Determine how much fatigue is reduced depending on armor penalty.
    local newFatigue = tes3.mobilePlayer.fatigue.current - ( 6 * ( ( tes3.mobilePlayer.fatigue.base / 22525 ) * ( armorPen / 0.2 ) ) )

    -- Don't set fatigue below 0.
    if newFatigue < 0 then
        newFatigue = 0
    end

    tes3.mobilePlayer.fatigue.current = newFatigue
end

-- Runs every time any actor attacks with a weapon or fists, but only with alternate mode on.
local function onAttack(e)

    -- It's not the player attacking or there's currently no weapon penalty.
    -- If fatigue is <= 0 there's no point.
    if e.reference ~= tes3.player
    or weaponPen == 0
    or tes3.mobilePlayer.fatigue.current <= 0 then
        return
    end

    -- Fatigue is reduced by 1/6 max fatigue.
    local newFatigue = tes3.mobilePlayer.fatigue.current - ( tes3.mobilePlayer.fatigue.base / 6 )

    -- Don't set fatigue below 0.
    if newFatigue < 0 then
        newFatigue = 0
    end

    tes3.mobilePlayer.fatigue.current = newFatigue
end

-- Used to update the penalties when the player equips or unequips something, but only with alternate mode on.
local function updateStarter(e)

    -- It's not the player doing the equipping, so do nothing.
    if e.reference ~= tes3.player then
        return
    end

    updatePenalty()
end

-- Runs every 0.1 second with alternate mode on.
-- Used to regulate how often the armor fatigue penalty applies while running.
local function fatigueTimer()
    fatigueTime = 1
end

-- Runs each time the game is loaded, but only with alternate mode on.
local function onLoaded()
    updatePenalty()

    -- Start our 0.1 second timer for the fatigue penalty.
    timer.start{
        duration = 0.1,
        iterations = -1,
        callback = fatigueTimer,
    }
end

-- Runs when Morrowind first starts.
local function onInitialized()
    event.register("uiObjectTooltip", reqTooltip)

    -- These functions are only used with alternate mode on. No point in calling them otherwise.
    if config.alternateMode then
        event.register("spellCast", onSpellCast)
        event.register("calcMoveSpeed", onCalcMoveSpeed)
        event.register("attack", onAttack)

        event.register("equipped", updateStarter)
        event.register("unequipped", updateStarter)
        event.register("skillRaised", updatePenalty)
        event.register("loaded", onLoaded)

    -- This function only needs to be called with alternate mode off.
    else
        event.register("equip", onEquip)
    end

    mwse.log("[%s %s] initialized.", mod, version)
end

event.register("initialized", onInitialized)

-- Register the Mod Config Menu.
local function onModConfigReady()
    dofile("Data Files\\MWSE\\mods\\EquipmentRequirements\\mcm.lua")
end

event.register("modConfigReady", onModConfigReady)