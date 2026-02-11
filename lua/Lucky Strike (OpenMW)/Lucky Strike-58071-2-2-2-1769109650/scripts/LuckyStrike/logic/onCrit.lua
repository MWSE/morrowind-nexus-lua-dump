local storage = require('openmw.storage')
local types = require("openmw.types")
local core = require("openmw.core")

local settingsOnCrit = storage.globalSection('SettingsLuckyStrike_onCrit')
local l10n = core.l10n("LuckyStrike")

local function showMessage(victim, attack)
    local player
    local msg
    if victim.type == types.Player then
        player = victim
        ---@diagnostic disable-next-line: missing-parameter
        msg = l10n("msg_critTaken")
    elseif attack.attacker.type == types.Player then
        player = attack.attacker
        ---@diagnostic disable-next-line: missing-parameter
        msg = l10n("msg_critDealt")
    end

    if player then
        player:sendEvent("ShowMessage", { message = msg })
    end
end

function OnCrit(victim, attack)
    if settingsOnCrit:get("playSound") then
        core.sound.playSound3d("critical damage", victim)
    end

    if settingsOnCrit:get("showMessage") then
        showMessage(victim, attack)
    end
end
