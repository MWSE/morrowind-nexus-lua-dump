local self = require("openmw.self")
local I = require("openmw.interfaces")

require("scripts.LuckyStrike.utils.omw_utils")
require("scripts.LuckyStrike.utils.consts")
require("scripts.LuckyStrike.logic.chance")
require("scripts.LuckyStrike.logic.damage")
require("scripts.LuckyStrike.logic.onCrit")

local function tryCrit(attack)
    if not attack.successful then return end

    if math.random() >= GetCritChance(self, attack.attacker) then return end

    Log("Successful critical hit!")

    local dmgModified = ModifyAttack(attack)
    if dmgModified then OnCrit(self, attack) end
end

I.Combat.addOnHitHandler(tryCrit)
