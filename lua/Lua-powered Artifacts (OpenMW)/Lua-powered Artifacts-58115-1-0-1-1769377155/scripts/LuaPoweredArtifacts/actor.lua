local I = require('openmw.interfaces')

require("scripts.LuaPoweredArtifacts.weapons.umbra.condition")
require("scripts.LuaPoweredArtifacts.weapons.umbra.logic")
require("scripts.LuaPoweredArtifacts.weapons.mehrunes razor.condition")
require("scripts.LuaPoweredArtifacts.weapons.mehrunes razor.logic")
require("scripts.LuaPoweredArtifacts.weapons.scourge.condition")
require("scripts.LuaPoweredArtifacts.weapons.scourge.logic")

local dispatch = {
    { cond = UmbraCond,   fn = DoSoultrap },
    { cond = RazorCond,   fn = DoInstakill },
    { cond = ScourgeCond, fn = DoBanish }
}

function ApplyEffect(attack)
    for _, rule in ipairs(dispatch) do
        if rule.cond(attack) then
            rule.fn(attack)
        end
    end
end

I.Combat.addOnHitHandler(ApplyEffect)
