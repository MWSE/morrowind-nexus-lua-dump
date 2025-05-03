local types = require('openmw.types')
local self = require('openmw.self')
local version_check = require("scripts.TamrielData.utils.version_check")
local magic_passwall = require("scripts.TamrielData.player_magic_passwall")

-- Run a perpetual check for any active spells which need a TD override

local checkFrequency = 0.5 -- No need to check for magic that often
local checkCounter = 0.0

local function checkForAnyActiveSpells(timeSinceLastCheck)
    checkCounter = checkCounter + timeSinceLastCheck
    if checkCounter < checkFrequency then
        return
    end
    checkCounter = 0
    for _, spell in pairs(types.Actor.activeSpells(self)) do
        if spell.id == "t_com_mys_uni_passwall" then
            if version_check.isFeatureEnabled("miscSpells") then
                if magic_passwall then
                    types.Actor.activeSpells(self):remove(spell.activeSpellId)
                    magic_passwall.onCastPasswall()
                end
            end
        end
    end
end

return {
    engineHandlers = {
        onUpdate = checkForAnyActiveSpells
    }
}