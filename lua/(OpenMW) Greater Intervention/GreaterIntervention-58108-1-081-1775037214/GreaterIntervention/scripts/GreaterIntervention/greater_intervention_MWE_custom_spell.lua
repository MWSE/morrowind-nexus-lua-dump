local core = require('openmw.core')
local time = require('openmw_aux.time')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local storage   = require('openmw.storage')
local types = require('openmw.types')

local API = require('openmw.interfaces').MagicWindow

-- Get config from settings
local config = storage.playerSection('GreaterInterventionSettings')

-- If MWE is not active, print a Warning and return.
if not API then
    print("[Greater Intervention]: Magic Window Extender API not found. Enable this mod to have proper spell tooltips.")
    return {}
end

-- Map standard Intervention Spell IDs to the specific Marker IDs they filter for.
local STANDARD_SPELL_MAP = {
    ["almsivi intervention"] = "templemarker",
    ["divine intervention"] = "divinemarker"
}

-- Map every core spell effect magnitude type to the MWE one
local MagType = {
    NONE = 1,
    TIMES_INT = 2,
    FEET = 3,
    LEVEL = 4,
    PERCENTAGE = 5,
    POINTS = 6,
}
local effectMagTypes = {
    -- NONE (1): Effects with no numerical magnitude shown
    ["almsiviintervention"] = MagType.NONE, ["divineintervention"] = MagType.NONE,
    ["mark"] = MagType.NONE, ["recall"] = MagType.NONE,
    ["waterwalking"] = MagType.NONE, ["waterbreathing"] = MagType.NONE,
    ["soul_trap"] = MagType.NONE, ["paralyze"] = MagType.NONE, ["silence"] = MagType.NONE,
    ["curecommonpithdisease"] = MagType.NONE, ["cureblightdisease"] = MagType.NONE,
    ["cureparalyzation"] = MagType.NONE, ["curepoison"] = MagType.NONE,
    ["bound_dagger"] = MagType.NONE, ["bound_longsword"] = MagType.NONE,
    ["bound_mace"] = MagType.NONE, ["bound_battle_axe"] = MagType.NONE,
    ["bound_spear"] = MagType.NONE, ["bound_longbow"] = MagType.NONE,
    ["bound_cuirass"] = MagType.NONE, ["bound_helm"] = MagType.NONE,
    ["bound_boots"] = MagType.NONE, ["bound_shield"] = MagType.NONE,
    ["bound_gloves"] = MagType.NONE, ["corprus"] = MagType.NONE,

    -- FEET (3): Distance-based effects
    ["detect_animal"] = MagType.FEET, ["detect_enchantment"] = MagType.FEET, ["detect_key"] = MagType.FEET,
    ["telekinesis"] = MagType.FEET,

    -- LEVEL (4): Effects by level
    ["command_creature"] = MagType.LEVEL, ["command_humanoid"] = MagType.LEVEL,
    ["calm_creature"] = MagType.LEVEL, ["calm_humanoid"] = MagType.LEVEL,
    ["frenzy_creature"] = MagType.LEVEL, ["frenzy_humanoid"] = MagType.LEVEL,
    ["demoralize_creature"] = MagType.LEVEL, ["demoralize_humanoid"] = MagType.LEVEL,
    ["rally_creature"] = MagType.LEVEL, ["rally_humanoid"] = MagType.LEVEL,

    -- PERCENTAGE (5): Standard chance or resistance modifiers
    ["resist_fire"] = MagType.PERCENTAGE, ["resist_frost"] = MagType.PERCENTAGE,
    ["resist_shock"] = MagType.PERCENTAGE, ["resist_magicka"] = MagType.PERCENTAGE,
    ["resist_common_disease"] = MagType.PERCENTAGE, ["resist_blight_disease"] = MagType.PERCENTAGE,
    ["resist_paralysis"] = MagType.PERCENTAGE, ["resist_poison"] = MagType.PERCENTAGE,
    ["resist_normal_weapons"] = MagType.PERCENTAGE,
    ["weakness_to_fire"] = MagType.PERCENTAGE, ["weakness_to_frost"] = MagType.PERCENTAGE,
    ["weakness_to_shock"] = MagType.PERCENTAGE, ["weakness_to_magicka"] = MagType.PERCENTAGE,
    ["weakness_to_common_disease"] = MagType.PERCENTAGE, ["weakness_to_blight_disease"] = MagType.PERCENTAGE,
    ["weakness_to_corprus"] = MagType.PERCENTAGE, ["weakness_to_poison"] = MagType.PERCENTAGE,
    ["weakness_to_normal_weapons"] = MagType.PERCENTAGE,
    ["reflect"] = MagType.PERCENTAGE, ["spell_absorption"] = MagType.PERCENTAGE,
    ["chameleon"] = MagType.PERCENTAGE, ["dispel"] = MagType.PERCENTAGE,
    ["blind"] = MagType.PERCENTAGE, ["sound"] = MagType.PERCENTAGE, ["invisibility"] = MagType.PERCENTAGE,

    -- POINTS (6): Standard "pts" display (Default)
    ["open"] = MagType.POINTS, ["lock"] = MagType.POINTS, ["turn_undead"] = MagType.POINTS,
    ["fire_damage"] = MagType.POINTS, ["frost_damage"] = MagType.POINTS, ["light"] = MagType.POINTS, ["night_eye"] = MagType.POINTS,
    ["shock_damage"] = MagType.POINTS, ["poison"] = MagType.POINTS, ["sanctuary"] = MagType.POINTS,
    ["restore_health"] = MagType.POINTS, ["restore_magicka"] = MagType.POINTS, ["restore_fatigue"] = MagType.POINTS,
    ["drain_health"] = MagType.POINTS, ["drain_magicka"] = MagType.POINTS, ["drain_fatigue"] = MagType.POINTS,
    ["damage_health"] = MagType.POINTS, ["damage_magicka"] = MagType.POINTS, ["damage_fatigue"] = MagType.POINTS,
    ["absorb_health"] = MagType.POINTS, ["absorb_magicka"] = MagType.POINTS, ["absorb_fatigue"] = MagType.POINTS,
    ["levitate"] = MagType.POINTS, ["slow_fall"] = MagType.POINTS, ["jump"] = MagType.POINTS, ["swift_swim"] = MagType.POINTS,
    ["burden"] = MagType.POINTS, ["feather"] = MagType.POINTS, ["shield"] = MagType.POINTS,
    ["fire_shield"] = MagType.POINTS, ["frost_shield"] = MagType.POINTS, ["lightning_shield"] = MagType.POINTS,
}

local Spells = API.Spells
local C = API.Constants

-- Effect definitions are based on openmw.core.MagicEffect structure (relevant fields only)
-- These are:
-- id (string)
-- icon (string, path in vfs)
-- name (string, localized name)
-- school (string, skill ID)
-- hasDuration (bool)
-- hasMagnitude (bool)
-- isAppliedOnce (bool)
-- And MWE specific:
-- magnitudeType (API.Constants.Magic.MagnitudeDisplayType)
Spells.registerEffect{
    id = "greater_almsivi_intervention",
    icon = "icons/s/B_Tx_S_Alm_Intervt.dds",
    name = "Greater Almsivi Intervention",
    school = "mysticism",
    hasDuration = false,
    hasMagnitude = false,
    isAppliedOnce = true,
    magnitudeType = C.Magic.MagnitudeDisplayType.NONE,
}

Spells.registerSpell{
    id = "almsivi intervention greater",
    effects = {
        {
            id = "greater_almsivi_intervention",
            effect = Spells.getCustomEffect("greater_almsivi_intervention"),
            magnitudeMin = 0,
            magnitudeMax = 0,
            area = 0,
            duration = 0,
            range = core.magic.RANGE.Self,
        }
    },
}

Spells.registerEffect{
    id = "greater_divine_intervention",
    icon = "icons/s/B_Tx_S_Divine_Intervt.dds",
    name = "Greater Divine Intervention",
    school = "mysticism",
    hasDuration = false,
    hasMagnitude = false,
    isAppliedOnce = true,
    magnitudeType = C.Magic.MagnitudeDisplayType.NONE,
}

Spells.registerSpell{
    id = "divine intervention greater",
    effects = {
        {
            id = "greater_divine_intervention",
            effect = Spells.getCustomEffect("greater_divine_intervention"),
            magnitudeMin = 0,
            magnitudeMax = 0,
            area = 0,
            duration = 0,
            range = core.magic.RANGE.Self,
        }
    },
}

-- Chebyshev Distance Helper
local function getChebyshevDistance(playerPos, markerX, markerY)
    return math.max(math.abs(playerPos.x - markerX), math.abs(playerPos.y - markerY))
end

-- Get player's position in the exterior world
local function getExteriorPlayerPos(playerPos)
    local cell = self.cell

    -- If in exterior cell, just return player's position
    if cell.isExterior then return self.position end

    -- Player is in interior cell. Attempt to find closest exit to exterior cell
    for _, door in ipairs(nearby.doors) do
        if types.Door.isTeleport(door) then
            local destCell = types.Door.destCell(door)

            -- Check if door teleports to an exterior cell
            if destCell.isExterior then
                return types.Door.destPosition(door) -- This is the exterior world position
            end
        end
    end
    return nil
end

-- Find closest Marker to player
local function findClosest(markerList)
    if not markerList or #markerList == 0 then return nil end

    local playerPos = getExteriorPlayerPos(self.position)
    if not playerPos then return nil end

    local closest = nil
    local minDistance = math.huge

    for _, marker in ipairs(markerList) do
        local dist = getChebyshevDistance(playerPos, marker.x, marker.y)
        if dist < minDistance then
            minDistance = dist
            closest = marker
        end
    end
    return closest
end

-- Track current closest Markers
local currentTempleMarker = nil
local currentDivineMarker = nil
local recentTempleMarker = nil
local recentDivineMarker = nil

-- Record possible destination of standard Intervention spell
local function showStandardInterventionDestination(data)
    local closest = findClosest(data.markerList)

    if closest and data.markerType == "templemarker" then currentTempleMarker = closest.label .. "?"
    elseif not closest and data.markerType == "templemarker" then currentTempleMarker = "Unknown" end
    if closest and data.markerType == "divinemarker" then currentDivineMarker = closest.label .. "?"
    elseif not closest and data.markerType == "divinemarker" then currentDivineMarker = "Unknown" end
end

-- Timer that updates closest marker
if config:get('EnableStandardInterventionEnhanceMWE') then
    time.runRepeatedly(function()
        for spellId, markerType in pairs(STANDARD_SPELL_MAP) do
            core.sendGlobalEvent('requestMarkerDataMWE', { type = markerType })
        end
    end, config:get('UpdateFrequency') * time.second)
end

local handlers = {}
local isMenuOpen = false

-- Only define onUpdate if enhanced standard Intervention processing is true
if config:get('EnableStandardInterventionEnhanceMWE') then
    handlers.onUpdate = function(dt)
        -- Check if the Player Interface is currently active
        local isCurrentlyActive = I.UI.getMode()

        -- Trigger only on the frame the menu opens and if the markers are present and updated
        if isCurrentlyActive == "Interface" and not isMenuOpen and
           (currentTempleMarker or currentDivineMarker) and
           ((currentTempleMarker ~= recentTempleMarker) or (currentDivineMarker ~= recentDivineMarker)) then

            local effectConfigs = {
                ["almsiviintervention"] = {
                    marker = currentTempleMarker,
                    baseName = "Almsivi Intervention",
                },
                ["divineintervention"] = {
                    marker = currentDivineMarker,
                    baseName = "Divine Intervention",
                }
            }

            -- Remember this set of markers so we don't update again for the same
            recentTempleMarker = currentTempleMarker
            recentDivineMarker = currentDivineMarker

            local playerSpells = types.Actor.spells(self)

            for _, spell in ipairs(playerSpells) do
                -- Check if the spell contains an intervention effect
                local containsIntervention = false
                for _, effect in ipairs(spell.effects) do
                    local id = effect.id:lower()
                    if effectConfigs[id] and effectConfigs[id].marker then
                        containsIntervention = true
                        break
                    end
                end

                -- Process only the flagged spells
                if containsIntervention then
                    local spellEffects = {}

                    for _, effect in ipairs(spell.effects) do
                        local id = effect.id:lower()
                        local config = effectConfigs[id]
                        local customEffectName = (id .. "_custom")
                        local coreEffect = core.magic.effects.records[effect.id]

                        if config and config.marker then
                            -- Register the intervention effect with dynamic name
                            Spells.registerEffect({
                                id = customEffectName,
                                name = string.format("%s to %s", config.baseName, config.marker),
                                icon = coreEffect.icon,
                                school = coreEffect.school,
                                hasDuration = coreEffect.hasDuration,
                                hasMagnitude = coreEffect.hasMagnitude,
                                isAppliedOnce = coreEffect.isAppliedOnce,
                                magnitudeType = C.Magic.MagnitudeDisplayType.NONE,
                            })
                        else
                            -- Register the non-intervention effect
                            Spells.registerEffect({
                                id = customEffectName,
                                name = coreEffect.name,
                                icon = coreEffect.icon,
                                school = coreEffect.school,
                                hasDuration = coreEffect.hasDuration,
                                hasMagnitude = coreEffect.hasMagnitude,
                                isAppliedOnce = coreEffect.isAppliedOnce,
                                magnitudeType = effectMagTypes[id] or MagType.POINTS
                            })
                        end

                        -- Link the effect to the spell
                        table.insert(spellEffects, {
                            id = customEffectName,
                            effect = Spells.getCustomEffect(customEffectName),
                            magnitudeMin = effect.magnitudeMin,
                            magnitudeMax = effect.magnitudeMax,
                            area = effect.area,
                            duration = effect.duration,
                            range = effect.range,
                        })
                    end

                    -- Finalize the MWE tooltip override
                    Spells.registerSpell({
                        id = spell.id,
                        effects = spellEffects
                    })
                end
            end

            isMenuOpen = true -- Set state to prevent re-triggering every frame

        -- Reset the state when the menu is closed
        elseif isCurrentlyActive ~= "Interface" and isMenuOpen then
            isMenuOpen = false
        end
    end
end

return {
    eventHandlers = {
        -- Receive Marker data from Global script for standard Intervention spell processing.
        receiveMarkerDataMWE = showStandardInterventionDestination
    },
    engineHandlers = handlers
}