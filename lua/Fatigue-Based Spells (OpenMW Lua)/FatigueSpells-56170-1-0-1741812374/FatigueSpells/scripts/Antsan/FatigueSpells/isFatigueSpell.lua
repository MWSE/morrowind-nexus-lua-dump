local core = require("openmw.core")

return function(spell)
   if spell.type ~= core.magic.SPELL_TYPE.Spell then
      return 0
   end
   for _,effect in pairs(spell.effects) do
      if effect.range == core.magic.RANGE.Self then
         if effect.id == "drainfatigue" then
            return effect.magnitudeMax
         end
         if effect.id == "damagefatigue" then
            return effect.magnitudeMax * effect.duration
         end
      end
   end
   return 0
end
