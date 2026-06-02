-- scripts/spellbook_unlock/player.lua

local core  = require('openmw.core')
local types = require('openmw.types')
local self_ = require('openmw.self')

local magic = core.magic

local TEMP_SPELL_NAME = '1_temp_spell_spellbook_unlock'

-- ---------------------------------------------------------------------------
-- Config toggles
-- ---------------------------------------------------------------------------

-- Exclude effects that have no description text.
local FILTER_NO_DESCRIPTION = true

-- Remove MODDED effects when a vanilla effect exists with the exact same
-- display name.
--
-- Example:
--   vanilla Bound Boots  -> kept
--   modded Bound Boots   -> skipped
--
-- Detection uses:
--   - exact er.name match
--   - core.magic.EFFECT_TYPE membership
local FILTER_DUPLICATE_MODDED_EFFECTS = true

-- Remove MODDED effects when a vanilla effect shares both the same icon path
-- and the same description text.
--
-- Catches re-implementations that were given a different internal ID and
-- possibly a different display name, but reuse the vanilla icon and
-- description verbatim.
--
-- Example:
--   vanilla FireDamage  (icon "icons/s/tx_s_fireball.dds", desc "Burns...")  -> kept
--   modded  MyFire      (same icon, same desc)                               -> skipped
--
-- Detection uses:
--   - exact er.icon match
--   - exact er.description match
--   - core.magic.EFFECT_TYPE membership (vanilla guard)
local FILTER_ICON_DESCRIPTION_CLONES = true

-- ---------------------------------------------------------------------------
-- NPC service detection
-- ---------------------------------------------------------------------------

local function npcOffersRelevantService(npc)
    if not npc or not types.NPC.objectIsInstance(npc) then
        return false
    end

    local ok, rec = pcall(function()
        return types.NPC.record(npc.recordId)
    end)

    if not ok or not rec then
        return false
    end

    local s = rec.servicesOffered

    if not s then
        return false
    end

    return s.Spellmaking or s.Enchanting
end

-- ---------------------------------------------------------------------------
-- Spell presence detection
-- ---------------------------------------------------------------------------

local function hasTempSpell(player)
    local spells = types.Actor.spells(player)

    for _, spell in pairs(spells) do
        if spell.name == TEMP_SPELL_NAME then
            return true
        end
    end

    return false
end

-- ---------------------------------------------------------------------------
-- Effect helpers
-- ---------------------------------------------------------------------------

local function buildVanillaEffectLookup()
    local lookup = {}

    for _, effectId in pairs(core.magic.EFFECT_TYPE) do
        lookup[effectId] = true
    end

    return lookup
end

local function buildDuplicateNameLookup()
    local byName = {}

    for _, er in pairs(magic.effects.records) do
        if er.name and er.name ~= '' then
            byName[er.name] = byName[er.name] or {}
            byName[er.name][#byName[er.name] + 1] = er
        end
    end

    return byName
end

-- Returns a set of "icon\0description" keys for every vanilla magic effect
-- that has both an icon and a description.  The NUL separator ensures that
-- no combination of icon/description strings can produce a false match.
local function buildVanillaIconDescLookup()
    local vanillaEffects = buildVanillaEffectLookup()
    local lookup = {}

    for _, er in pairs(magic.effects.records) do
        if vanillaEffects[er.id]
            and er.icon        and er.icon        ~= ''
            and er.description and er.description ~= ''
        then
            lookup[er.icon .. '\0' .. er.description] = true
        end
    end

    return lookup
end

-- ---------------------------------------------------------------------------
-- Effect list building
-- ---------------------------------------------------------------------------

local function buildEffects()
    local effects = {}

    local vanillaEffects    = buildVanillaEffectLookup()
    local duplicateNames    = buildDuplicateNameLookup()
    local vanillaIconDesc   = buildVanillaIconDescLookup()

    for _, er in pairs(magic.effects.records) do

        -- ---------------------------------------------------------------
        -- FILTER_NO_DESCRIPTION
        -- ---------------------------------------------------------------

        if (
            FILTER_NO_DESCRIPTION
            and (not er.description or er.description == '')
        ) then
            goto continue
        end

        -- ---------------------------------------------------------------
        -- FILTER_DUPLICATE_MODDED_EFFECTS
        -- ---------------------------------------------------------------

        if FILTER_DUPLICATE_MODDED_EFFECTS then
            local sameName = er.name and duplicateNames[er.name]

            -- Only process duplicate display names
            if sameName and #sameName > 1 then
                local isVanilla = vanillaEffects[er.id]

                -- Skip only the MODDED effect
                if not isVanilla then
                    goto continue
                end
            end
        end

        -- ---------------------------------------------------------------
        -- FILTER_ICON_DESCRIPTION_CLONES
        -- ---------------------------------------------------------------

        if FILTER_ICON_DESCRIPTION_CLONES then
            local isVanilla = vanillaEffects[er.id]

            -- Only check modded effects; vanilla effects are never skipped
            if not isVanilla
                and er.icon        and er.icon        ~= ''
                and er.description and er.description ~= ''
            then
                local key = er.icon .. '\0' .. er.description

                if vanillaIconDesc[key] then
                    goto continue
                end
            end
        end

        effects[#effects + 1] = {
            id           = er.id,
            magnitudeMin = er.hasMagnitude and 1 or 0,
            magnitudeMax = er.hasMagnitude and 1 or 0,
            duration     = er.hasDuration and 1 or 0,
            area         = 0,
        }

        ::continue::
    end

    return effects
end

-- ---------------------------------------------------------------------------
-- Inject / remove
-- ---------------------------------------------------------------------------

local function inject(player)
    if hasTempSpell(player) then
        return
    end

    local effects = buildEffects()

    if #effects == 0 then
        return
    end

    core.sendGlobalEvent('SBU_Inject', {
        player = player,
        effects = effects,
    })
end

local function remove(player)
    if not hasTempSpell(player) then
        return
    end

    core.sendGlobalEvent('SBU_Remove', {
        player = player,
    })
end

-- ---------------------------------------------------------------------------
-- UI mode handler
-- ---------------------------------------------------------------------------

local SERVICE_MODES = {
    SpellCreation = true,
    Enchanting    = true,
}

local function onUiModeChanged(data)
    local player = self_.object

    -- Entering dialogue
    if data.newMode == 'Dialogue' then
        if npcOffersRelevantService(data.arg) then
            inject(player)
        end

        return
    end

    -- Dialogue closed
    if data.oldMode == 'Dialogue' and not data.newMode then
        remove(player)
        return
    end

    -- Fallback cleanup
    if not data.newMode then
        remove(player)
    end
end

-- ---------------------------------------------------------------------------
return {
    eventHandlers = {
        UiModeChanged = onUiModeChanged,
    },
}