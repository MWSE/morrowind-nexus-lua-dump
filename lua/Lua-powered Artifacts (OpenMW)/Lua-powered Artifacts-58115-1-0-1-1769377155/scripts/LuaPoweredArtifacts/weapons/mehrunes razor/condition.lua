local storage = require("openmw.storage")
local self = require("openmw.self")

require("scripts.LuaPoweredArtifacts.utils.instakill")

local sectionRazor = storage.globalSection("SettingsLuaPoweredArtifacts_razor")
local blacklisted = InInstakillBlacklist(self)

function RazorCond(attack)
    if not sectionRazor:get("enabled") then
        return false
    end

    if not (attack.successful and attack.sourceType == "melee" and attack.weapon) then
        return false
    end

    return attack.weapon.recordId == "mehrunes'_razor_unique"
        and not blacklisted
end
