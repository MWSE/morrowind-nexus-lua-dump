local I = require('openmw.interfaces')
local core = require('openmw.core')
local types = require("openmw.types")

local hthHealthPer = core.getGMST('fHandtoHandHealthPer')

I.Combat.addOnHitHandler(function(attack)
   local function GetH2HSkill(npc)
      return npc.type.stats.skills.handtohand(npc).modified
   end


   if attack.attacker and not attack.weapon and not attack.damage.health then
      if attack.attacker.type == types.Creature then return true end

      local h2hSkill = GetH2HSkill(attack.attacker)
      local damagePerc = math.min(h2hSkill / 100, 1)

      attack.damage.health = attack.damage.fatigue * hthHealthPer * damagePerc
   end
end)
