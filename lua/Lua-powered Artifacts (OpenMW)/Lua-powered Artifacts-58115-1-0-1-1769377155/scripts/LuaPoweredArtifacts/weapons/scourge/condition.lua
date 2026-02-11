local storage = require("openmw.storage")
local self = require("openmw.self")

require("scripts.LuaPoweredArtifacts.utils.consts")

local sectionScourge = storage.globalSection("SettingsLuaPoweredArtifacts_scourge")

function ScourgeCond(attack)
    if not sectionScourge:get("enabled") then
        return false
    end

    if not (attack.successful and attack.sourceType == "melee" and attack.weapon) then
        return false
    end

    return attack.weapon.recordId == "daedric_scourge_unique"
        and (SummonedDaedra[self.recordId] or self.type.records[self.recordId].type == 1)
end
