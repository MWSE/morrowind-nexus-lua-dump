-- Fucker Dodge Script

local ui = require('openmw.ui')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local async = require('openmw.async')
local core = require('openmw.core')
local storage = require('openmw.storage')
local I = require('openmw.interfaces')

-- Required Types
local Actor = types.Actor
local Armor = types.Armor
local attributes = types.Actor.stats.attributes
local dynamic = types.Actor.stats.dynamic


I.Settings.registerPage({
    key = 'SimpleDodging',
    l10n = 'SimpleDodging',
    name = 'Dodge',
    description = 'For Honor inspired dodging. By Xe',
})

-- Default Values
local enabled_default = true
local buffSpeed_default = 510         -- Default: 510
local buffDuration_default = 0.1         -- Default: 0.1 (Hidden from menu)
local fatigueCost_default = 2         -- Default: 2
local cooldownDuration_default = 0.6    -- Default: 0.6
local noBackwardsRunning_default = false

local enableAgilityBuff_default = false
local buffAgility_default = 30
local agilityBuffDuration_default = 0.5

local enableArmorPenalty_default = true
local heavyPenalty_default = 3         -- Default: 3 (representing 3%)
local mediumPenalty_default = 2        -- Default: 2 (representing 2%)

-- Runtime variables (will be updated from storage)
local enabled = enabled_default
local buffSpeed = buffSpeed_default
local buffDuration = buffDuration_default
local fatigueCost = fatigueCost_default
local cooldownDuration = cooldownDuration_default
local noBackwardsRunning = noBackwardsRunning_default
local enableAgilityBuff = enableAgilityBuff_default
local buffAgility = buffAgility_default
local agilityBuffDuration = agilityBuffDuration_default

local enableArmorPenalty = enableArmorPenalty_default
local heavyPenalty = heavyPenalty_default -- This will store the integer value (e.g., 3)
local mediumPenalty = mediumPenalty_default -- This will store the integer value (e.g., 2)

local mainSettingsGroupKey = 'Settings_SimpleDodging'
local optionalSettingsGroupKey = 'Settings_Optional_Features'

-- Settings groups
I.Settings.registerGroup({
    key = mainSettingsGroupKey,
    page = 'SimpleDodging',
    l10n = 'SimpleDodging',
    name = 'Dodge Settings', -- Main category including armor penalty
    permanentStorage = true,
    settings = {
        { key = 'enabled', default = enabled_default, renderer = 'checkbox', name = 'Enable Dodge Ability', description = 'Enable or disable the dodge ability' },
        { key = 'buffSpeed', default = buffSpeed_default, renderer = 'number', name = 'Speed Buff Amount', description = 'Amount of Speed modifier applied during dodge. Default: 510', argument = { integer = true, min = 1, max = 1000 } },
        { key = 'fatigueCost', default = fatigueCost_default, renderer = 'number', name = 'Dodge Fatigue Cost', description = 'Fatigue drained per dodge. Default: 2', argument = { min = 0, max = 100 } },
        { key = 'cooldownDuration', default = cooldownDuration_default, renderer = 'number', name = 'Dodge Cooldown', description = 'Time before dodge can be used again. Default: 0.6', argument = { min = 0.5, max = 10.0, step = 0.1 } },
        -- Merged Armor Penalty Settings:
        { key = 'enableArmorPenalty', default = enableArmorPenalty_default, renderer = 'checkbox', name = 'Enable Armor Penalty', description = 'Apply speed penalty. Default: Yes' },
        { key = 'heavyPenalty', default = heavyPenalty_default, renderer = 'number', name = 'Heavy Armor Penalty (%)', description = 'Speed buff penalty % per heavy armor piece equipped. Default: 3', argument = { integer = true, min = 0, max = 50 } }, -- Integer percentage
        { key = 'mediumPenalty', default = mediumPenalty_default, renderer = 'number', name = 'Medium Armor Penalty (%)', description = 'Speed buff penalty % per medium armor piece equipped. Default: 2', argument = { integer = true, min = 0, max = 50 } }, -- Integer percentage, updated description
    },
})

I.Settings.registerGroup({
    key = optionalSettingsGroupKey,
    page = 'SimpleDodging',
    l10n = 'SimpleDodging',
    name = 'Optional Features',
    permanentStorage = true,
    settings = {
        { key = 'noBackwardsRunning', default = noBackwardsRunning_default, renderer = 'checkbox', name = 'Disable Backwards Running', description = 'Prevents running while moving backwards' },
        { key = 'enableAgilityBuff', default = enableAgilityBuff_default, renderer = 'checkbox', name = 'Enable Optional Agility Buff', description = 'Default: No' },
        { key = 'buffAgility', default = buffAgility_default, renderer = 'number', name = 'Agility Buff Amount', description = 'Amount of Agility modifier applied during dodge', argument = { integer = true, min = 1, max = 500 } },
        { key = 'agilityBuffDuration', default = agilityBuffDuration_default, renderer = 'number', name = 'Agility Buff Duration', description = 'Duration of the Agility buff in seconds', argument = { min = 0.05, max = 1.0, step = 0.05 } },
    }
})

-- Storage and settings update
local mainSettingsGroup = storage.playerSection(mainSettingsGroupKey)
local optionalSettingsGroup = storage.playerSection(optionalSettingsGroupKey)

local function updateSettings()
    enabled = mainSettingsGroup:get('enabled')
    buffSpeed = mainSettingsGroup:get('buffSpeed')
    fatigueCost = mainSettingsGroup:get('fatigueCost')
    cooldownDuration = mainSettingsGroup:get('cooldownDuration')

    noBackwardsRunning = optionalSettingsGroup:get('noBackwardsRunning')
    enableAgilityBuff = optionalSettingsGroup:get('enableAgilityBuff')
    buffAgility = optionalSettingsGroup:get('buffAgility')
    agilityBuffDuration = optionalSettingsGroup:get('agilityBuffDuration')

    enableArmorPenalty = mainSettingsGroup:get('enableArmorPenalty')
    heavyPenalty = mainSettingsGroup:get('heavyPenalty') -- Gets integer value (e.g., 3)
    mediumPenalty = mainSettingsGroup:get('mediumPenalty') -- Gets integer value (e.g., 2)

    -- Update renderer arguments for dependent settings
    local agilitySettingsDisabled = not enableAgilityBuff
    I.Settings.updateRendererArgument(optionalSettingsGroupKey, 'buffAgility', { disabled = agilitySettingsDisabled })
    I.Settings.updateRendererArgument(optionalSettingsGroupKey, 'agilityBuffDuration', { disabled = agilitySettingsDisabled })

    local armorPenaltySettingsDisabled = not enableArmorPenalty
    I.Settings.updateRendererArgument(mainSettingsGroupKey, 'heavyPenalty', { disabled = armorPenaltySettingsDisabled })
    I.Settings.updateRendererArgument(mainSettingsGroupKey, 'mediumPenalty', { disabled = armorPenaltySettingsDisabled })
end

local function init()
    updateSettings()
end

mainSettingsGroup:subscribe(async:callback(updateSettings))
optionalSettingsGroup:subscribe(async:callback(updateSettings))

-- Helper functions
local function spdMod(modSign, modVal)
    if modVal == 0 then return end
    local currentMod = attributes.speed(self).modifier
    local newMod = currentMod + modSign * modVal
    attributes.speed(self).modifier = math.max(0, newMod) -- Ensure modifier doesn't go below zero
end

local function agiMod(modSign, modVal)
    if modVal == 0 then return end
    local currentMod = attributes.agility(self).modifier
    local newMod = currentMod + modSign * modVal
    attributes.agility(self).modifier = math.max(0, newMod) -- Ensure modifier doesn't go below zero
end

-- *** Uses weight-based thresholds, medium penalty only applies if weight >= 3 ***
local function getArmorPenaltyFactor()
    if not enableArmorPenalty then
        return 0 -- No penalty factor
    end

    local slots = Actor.getEquipment(self)
    local totalPenaltyPercent = 0 -- Accumulate percentage points
    local MINIMUM_MEDIUM_WEIGHT = 3 -- Define minimum weight for medium penalty application

    for slot, item in pairs(slots) do
        if item and Armor.objectIsInstance(item) then
            local r = Armor.record(item)
            if r then
                -- Weight thresholds are estimates for 'heavy'. Adjust if needed.
                local isHeavy = (r.type == Armor.TYPE.Cuirass and r.weight > 18) or
                                (r.type == Armor.TYPE.LGauntlet and r.weight > 3) or
                                (r.type == Armor.TYPE.RGauntlet and r.weight > 3) or
                                (r.type == Armor.TYPE.Helmet and r.weight > 3) or
                                (r.type == Armor.TYPE.LBracer and r.weight > 3) or
                                (r.type == Armor.TYPE.RBracer and r.weight > 3) or
                                (r.type == Armor.TYPE.LPauldron and r.weight > 6) or
                                (r.type == Armor.TYPE.RPauldron and r.weight > 6) or
                                (r.type == Armor.TYPE.Greaves and r.weight > 9) or
                                (r.type == Armor.TYPE.Shield and r.weight > 9) or
                                (r.type == Armor.TYPE.Boots and r.weight > 12)

                -- Light Armor Check (No Penalty if weight is same or lesser than specified)
                if r.type == Armor.TYPE.Boots and r.weight <= 8 then
                    -- No penalty
                elseif r.type == Armor.TYPE.Greaves and r.weight <= 7 then
                    -- No penalty
                elseif r.type == Armor.TYPE.LGauntlet and r.weight <= 3 then
                    -- No penalty
                elseif r.type == Armor.TYPE.RGauntlet and r.weight <= 3 then
                    -- No penalty
                elseif r.type == Armor.TYPE.Cuirass and r.weight <= 12 then
                    -- No penalty
                elseif r.type == Armor.TYPE.LPauldron and r.weight <= 3 then
                    -- No penalty
                elseif r.type == Armor.TYPE.RPauldron and r.weight <= 3 then
                    -- No penalty
                elseif isHeavy then
                    totalPenaltyPercent = totalPenaltyPercent + heavyPenalty -- Add integer % for heavy
                elseif r.weight >= MINIMUM_MEDIUM_WEIGHT then -- *** MODIFIED LINE: Apply medium penalty only if not heavy AND weight is >= minimum ***
                    totalPenaltyPercent = totalPenaltyPercent + mediumPenalty -- Add integer % for medium
                end
                -- Pieces classified as light (weight < 3 and not heavy) or clothing (weight < 3) add no penalty
            end
        end
    end
    -- Convert total percentage points to a decimal factor (e.g., 5% -> 0.05)
    -- Cap the penalty factor at 1.0 (100% reduction).
    return math.min(totalPenaltyPercent / 100, 1.0)
end

-- Save/load
local buffTotal = { speed = 0, agility = 0 } -- Tracks the *base* buff amount applied before penalty

local function onSave()
    return { buffTotal = buffTotal }
end

local function onLoad(data)
    if data and data.buffTotal then
        local savedBuffTotal = data.buffTotal
        if savedBuffTotal.speed > 0 then
            local penaltyFactor = getArmorPenaltyFactor() -- Recalculate penalty on load
            local penalizedSpeedToRemove = savedBuffTotal.speed * (1 - penaltyFactor)
            spdMod(-1, math.max(0, penalizedSpeedToRemove)) -- Ensure removing non-negative amount
        end
        if savedBuffTotal.agility > 0 then
            agiMod(-1, savedBuffTotal.agility)
        end
    end
     -- Always reset tracking on load
    buffTotal = { speed = 0, agility = 0 }
end

-- Dodge logic
local doBuff = true -- Cooldown flag

return {
    engineHandlers = {
        onActive = init,
        onSave = onSave,
        onLoad = onLoad,

        onInputAction = function(id)
            if not enabled or core.isWorldPaused() then return end

            if id == input.ACTION.Run then
                local currentStance = types.Actor.stance(self)
                if currentStance == types.Actor.STANCE.Weapon or currentStance == types.Actor.STANCE.Spell then
                    local cfat = dynamic.fatigue(self).current
                    if doBuff and cfat >= fatigueCost then
                        doBuff = false -- Start cooldown
                        dynamic.fatigue(self).current = cfat - fatigueCost

                        local baseSpeedBuff = buffSpeed
                        local baseAgilityBuff = enableAgilityBuff and buffAgility or 0
                        local armorPenaltyFactor = getArmorPenaltyFactor() -- Uses refined weight-based check now
                        local appliedSpeedBuff = math.max(0, baseSpeedBuff * (1 - armorPenaltyFactor))

                        -- Apply Speed Buff (penalized)
                        if appliedSpeedBuff > 0 then
                            spdMod(1, appliedSpeedBuff)
                            buffTotal.speed = buffTotal.speed + baseSpeedBuff
                            async:newUnsavableSimulationTimer(
                                buffDuration,
                                function()
                                    if buffTotal.speed >= baseSpeedBuff then
                                        spdMod(-1, appliedSpeedBuff)
                                        buffTotal.speed = buffTotal.speed - baseSpeedBuff
                                        if buffTotal.speed < 0 then buffTotal.speed = 0 end
                                    end
                                end
                            )
                        end

                        -- Apply Agility Buff (not penalized)
                        if enableAgilityBuff and baseAgilityBuff > 0 then
                            agiMod(1, baseAgilityBuff)
                            buffTotal.agility = buffTotal.agility + baseAgilityBuff
                            async:newUnsavableSimulationTimer(
                                agilityBuffDuration,
                                function()
                                    if buffTotal.agility >= baseAgilityBuff then
                                        agiMod(-1, baseAgilityBuff)
                                        buffTotal.agility = buffTotal.agility - baseAgilityBuff
                                        if buffTotal.agility < 0 then buffTotal.agility = 0 end
                                    end
                                end
                            )
                        end

                        -- Cooldown Timer
                        async:newUnsavableSimulationTimer(
                            cooldownDuration,
                            function()
                                doBuff = true
                            end
                        )
                    end
                end
            end
        end,

        onFrame = function()
            if core.isWorldPaused() or not noBackwardsRunning then return end
            if self.controls.run and self.controls.movement < 0 then
                self.controls.run = false
            end
        end,
    }
}