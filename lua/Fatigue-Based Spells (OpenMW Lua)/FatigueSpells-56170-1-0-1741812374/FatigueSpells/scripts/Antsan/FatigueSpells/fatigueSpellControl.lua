local async = require('openmw.async')
local self = require("openmw.self")
local input = require("openmw.input")

local isFatigueSpell =
   require("scripts.Antsan.FatigueSpells.isFatigueSpell")

local fatigue = self.type.stats.dynamic.fatigue(self)

input.bindAction("Use",
                 async:callback(function(dt, use)
                       if self.type.getStance(self) == self.type.STANCE.Spell then
                          local spell = self.type.getSelectedSpell(self)
                          if spell then
                             local spellCost = isFatigueSpell(spell)
                             if spellCost then
                                return use and (fatigue.current >= spellCost)
                             end
                          end
                       end
                       return use
                                      end), {})

return {}
