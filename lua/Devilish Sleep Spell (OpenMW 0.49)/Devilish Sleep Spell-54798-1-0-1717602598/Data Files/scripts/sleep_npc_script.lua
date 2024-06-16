local nearby = require('openmw.nearby')
local AI = require('openmw.interfaces').AI
local self = require('openmw.self')
local types = require('openmw.types')
local time = require('openmw_aux.time')
local NPC = require('openmw.types').NPC
local core = require('openmw.core')

    local doOnce = 0
    local stopFn = time.runRepeatedly(function() 

      local FightValue = types.Actor.stats.ai.fight(self).base
      local StanceValue = types.Actor.getStance(self)
      local HealthValueB = types.Actor.stats.dynamic.health(self).base
      local HealthValueC = types.Actor.stats.dynamic.health(self).current
      local illegalSleepSpell = 1
    
      if types.Actor.activeSpells(self):isSpellActive('detd_sleep_spell') then
      types.Actor.spells(self):add('detd_sleep_spell2')
      else types.Actor.spells(self):remove('detd_sleep_spell2')
      end

    if doOnce == 0 and StanceValue == 0 and FightValue < 90 and types.Actor.activeSpells(self):isSpellActive('detd_sleep_spell') then
     illegalSleepSpell = 99
     doOnce = 1
     core.sendGlobalEvent("detdGlobalCheckSleep", illegalSleepSpell)
    end

    if HealthValueB > HealthValueC or StanceValue ~= 0 then
      types.Actor.spells(self):remove('detd_sleep_spell2')
      types.Actor.spells(self):remove('detd_sleep_spell')  
    end

    if doOnce == 1 and types.Actor.activeSpells(self):isSpellActive('detd_sleep_spell') == false then
      doOnce = 0
    end
      end,
                                        1 * time.second)  -- print 'Test' every 5 seconds
