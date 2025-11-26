local self = require('openmw.self')
local types = require('openmw.types')
--local core = require('openmw.core')
--local nearby = require('openmw.nearby')
local postprocessing = require('openmw.postprocessing')
local shader = postprocessing.load('epo_detd_drunk')
local time = require('openmw_aux.time')

local drunkSpell
local factor = 0.02
local factor2 = 0.01

local stopFn = time.runRepeatedly(function() 

      if drunkSpell == 0 then
            shader:disable()
      elseif drunkSpell == 1 then
            shader:enable()
      end
      shader:setFloat('uSwipeAmount', factor)
      shader:setFloat('uOffsetStrength', factor2)

if types.Actor.activeSpells(self):isSpellActive('a_drunk_1') then
drunkSpell = 1
factor = 0.003
factor2 = -0.01
elseif types.Actor.activeSpells(self):isSpellActive('a_drunk_2') then
drunkSpell = 1
factor = 0.012
factor2 = 0.008   
elseif types.Actor.activeSpells(self):isSpellActive('a_drunk_3') then
      drunkSpell = 1
      factor = 0.019
      factor2 = 0.015   
elseif types.Actor.activeSpells(self):isSpellActive('a_drunk_3') then
      drunkSpell = 1
      factor = 0.023
      factor2 = 0.020   
elseif types.Actor.activeSpells(self):isSpellActive('a_drunk_4') then
      drunkSpell = 1
      factor = 0.035
      factor2 = 0.025  
elseif types.Actor.activeSpells(self):isSpellActive('a_knockout') then
      drunkSpell = 1
      factor = 0.05
      factor2 = 0.08
elseif types.Actor.activeSpells(self):isSpellActive('a_withdrawal_2') or types.Actor.activeSpells(self):isSpellActive('a_withdrawal_3')  then
      drunkSpell = 1
      factor = 0.001
      factor2 = -0.01
else
drunkSpell = 0
end
          end,1 * time.second)












   --return {
 -- engineHandlers = {
--    onActive = onActive,
 --        }
 --         }
