local storage = require('openmw.storage')
local omw_self = require("openmw.self")
local types = require("openmw.types")
local core = require("openmw.core")
local ui = require("openmw.ui")

require("scripts.TrulyConstantEffects.utils")

---@class PlayerState
---@field spellEffectCounts table
---@field enchEffectCounts table
PlayerState = {}

---PlayerState constructor
---@return PlayerState
function PlayerState:new()
    local public = {}
    public.spellEffectCounts = CountEffects().spellEffectCounts
    public.enchEffectCounts = CountEffects().enchEffectCounts

    local private = {}
    private.l10n = core.l10n("TrulyConstantEffects")

    ---Checks if state is up to date
    ---
    ---If it's not, updates the state
    ---@return boolean
    function public:isUpToDate()
        local currentEffectCounts = CountEffects()
        if (not TablesAreSame(public.spellEffectCounts, currentEffectCounts.spellEffectCounts) or
                not TablesAreSame(public.enchEffectCounts, currentEffectCounts.enchEffectCounts)) then
            public.spellEffectCounts = currentEffectCounts.spellEffectCounts
            public.enchEffectCounts = currentEffectCounts.enchEffectCounts
            return false
        end
        return true
    end

    ---Returns difference of effect count excluding 0s
    ---
    ---\>0 means there is too many effects, <0 is opposite
    ---@return table
    function private:getEffectDifference()
        local difference = {}
        -- check enchant keys
        for spellId, count in pairs(public.enchEffectCounts) do
            -- enchant is present, spell is not
            if public.spellEffectCounts[spellId] == nil then
                difference[spellId] = count
                -- skip if values are same
            elseif count ~= public.spellEffectCounts[spellId] then
                difference[spellId] = count - public.spellEffectCounts[spellId]
            end
        end
        -- check spell keys
        for spellId, count in pairs(public.spellEffectCounts) do
            -- spell is present, enchant is not
            if public.enchEffectCounts[spellId] == nil then
                difference[spellId] = -count
            end
        end
        return difference
    end

    ---Adds or removes spell, depending on the private:getEffectDifference()
    function public:updateSpells()
        local settings = storage.playerSection("SettingsTrulyConstantEffects")
        for spellId, count in pairs(private:getEffectDifference()) do
            if count < 0 then
                if settings:get("showMessages") then ui.showMessage(private.l10n("removeSpell_message")) end
                -- remove count spells
                for _ = count + 1, 0 do
                    for _, spellParams in pairs(types.Actor.activeSpells(omw_self)) do
                        if spellParams.id == "tce_" .. spellId then
                            types.Actor.activeSpells(omw_self):remove(spellParams.activeSpellId)
                        end
                    end
                end
            elseif count > 0 and (
                    (spellId == "invisibility" and settings:get("reapplyInvis"))
                    or (spellId ~= "invisibility" and settings:get("reapplySummons"))
                ) then
                if settings:get("showMessages") then ui.showMessage(private.l10n("addSpell_message")) end
                -- add count spells
                for _ = 0, count - 1 do
                    types.Actor.activeSpells(omw_self):add({
                        id = "tce_" .. spellId,
                        effects = { 0 },
                        stackable = true
                    })
                end
            end
        end
    end

    setmetatable(public, self)
    self.__index = self
    return public
end
