local core = require('openmw.core')
local time = require('openmw_aux.time')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local I = require('openmw.interfaces')

local API = require('openmw.interfaces').MagicWindow

-- If MWE is not active, print a Warning and return.
if not API then
    print("[Greater Intervention]: Magic Window Extender API not found. Enable this mod to have proper spell tooltips.")
    return {}
end

-- Enable experimental standard Intervention destination display based on discovered markers.
local ENABLE_STANDARD_INTERVENTION_ENHANCE = true

-- Update frequency, in seconds, of closest markers
local UPDATE_FREQUENCY = 5

-- Map standard Intervention Spell IDs to the specific Marker IDs they filter for.
local STANDARD_SPELL_MAP = {
    ["almsivi intervention"] = "templemarker",
    ["divine intervention"] = "divinemarker"
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

-- Record possible destination of standard Intervention spell
local function showStandardInterventionDestination(data)
    local closest = findClosest(data.markerList)

    if closest and data.markerType == "templemarker" then currentTempleMarker = closest.label .. "?"
    elseif not closest and data.markerType == "templemarker" then currentTempleMarker = "Unknown" end
    if closest and data.markerType == "divinemarker" then currentDivineMarker = closest.label .. "?"
    elseif not closest and data.markerType == "divinemarker" then currentDivineMarker = "Unknown" end
end

if ENABLE_STANDARD_INTERVENTION_ENHANCE then
    time.runRepeatedly(function()
        for spellId, markerType in pairs(STANDARD_SPELL_MAP) do
            core.sendGlobalEvent('requestMarkerDataMWE', { type = markerType })
        end
    end, UPDATE_FREQUENCY * time.second)
end

local handlers = {}
local isMenuOpen = false

-- Only define onUpdate if enhanced standard Intervention processing is true
if ENABLE_STANDARD_INTERVENTION_ENHANCE then
    handlers.onUpdate = function(dt)
        -- Check if the Player Interface is currently active
        local isCurrentlyActive = I.UI.getMode()

        -- Trigger only on the frame the menu opens
        if isCurrentlyActive == "Interface" and not isMenuOpen then
        
            -- Update standard Intervention spell tooltips with latest closest markers
            if currentTempleMarker then
                Spells.registerEffect{
                    id = "almsivi_intervention_enhanced",
                    icon = "icons/s/B_Tx_S_Alm_Intervt.dds",
                    name = "Almsivi Intervention to " .. currentTempleMarker,
                    school = "mysticism",
                    hasDuration = false,
                    hasMagnitude = false,
                    isAppliedOnce = true,
                    magnitudeType = C.Magic.MagnitudeDisplayType.NONE,
                }
                
                Spells.registerSpell{
                    id = "almsivi intervention",
                    effects = {
                        {
                            id = "almsivi_intervention_enhanced",
                            effect = Spells.getCustomEffect("almsivi_intervention_enhanced"),
                            magnitudeMin = 0,
                            magnitudeMax = 0,
                            area = 0,
                            duration = 0,
                            range = core.magic.RANGE.Self,
                        }
                    },
                }
            end
            if currentDivineMarker then
                Spells.registerEffect{
                    id = "divine_intervention_enhanced",
                    icon = "icons/s/B_Tx_S_Divine_Intervt.dds",
                    name = "Divine Intervention to " .. currentDivineMarker,
                    school = "mysticism",
                    hasDuration = false,
                    hasMagnitude = false,
                    isAppliedOnce = true,
                    magnitudeType = C.Magic.MagnitudeDisplayType.NONE,
                }
                
                Spells.registerSpell{
                    id = "divine intervention",
                    effects = {
                        {
                            id = "divine_intervention_enhanced",
                            effect = Spells.getCustomEffect("divine_intervention_enhanced"),
                            magnitudeMin = 0,
                            magnitudeMax = 0,
                            area = 0,
                            duration = 0,
                            range = core.magic.RANGE.Self,
                        }
                    },
                }
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