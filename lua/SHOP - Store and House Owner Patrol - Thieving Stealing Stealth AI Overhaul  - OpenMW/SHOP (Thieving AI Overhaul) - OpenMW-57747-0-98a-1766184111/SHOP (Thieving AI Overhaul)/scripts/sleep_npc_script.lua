local nearby = require('openmw.nearby')
local AI = require('openmw.interfaces').AI
local self = require('openmw.self')
local types = require('openmw.types')
local time = require('openmw_aux.time')
local NPC = require('openmw.types').NPC
local core = require('openmw.core')
local anim = require('openmw.animation')

    local doOnce = 0
    local stopFn = time.runRepeatedly(function() 

      local FightValue = types.Actor.stats.ai.fight(self).base
      local StanceValue = types.Actor.getStance(self)
      local HealthValueB = types.Actor.stats.dynamic.health(self).base
      local HealthValueC = types.Actor.stats.dynamic.health(self).current
      local illegalSleepSpell = 1


      if types.Actor.activeSpells(self):isSpellActive('detd_sleep_spell') and StanceValue == 0 then
      types.Actor.stats.dynamic.fatigue(self).current = -45
      end

       if types.Actor.activeSpells(self):isSpellActive('detd_sleepspellenchat') and StanceValue == 0 then
      types.Actor.stats.dynamic.fatigue(self).current = -45
      end

    if doOnce == 0 and StanceValue == 0 and FightValue < 90 and types.Actor.activeSpells(self):isSpellActive('detd_sleep_spell') then
     illegalSleepSpell = 99
     doOnce = 1
     core.sendGlobalEvent("detdGlobalCheckSleep", illegalSleepSpell)
    end

        if doOnce == 0 and StanceValue == 0 and FightValue < 90 and types.Actor.activeSpells(self):isSpellActive('detd_sleepspellenchat')  then
     illegalSleepSpell = 99
     doOnce = 1
     core.sendGlobalEvent("detdGlobalCheckSleep", illegalSleepSpell)
    end

    if HealthValueB > HealthValueC and types.Actor.activeSpells(self):isSpellActive('detd_sleep_spell') then
      types.Actor.spells(self):remove('detd_sleep_spell')
      types.Actor.stats.dynamic.fatigue(self).current = 10
    end

        if HealthValueB > HealthValueC and types.Actor.activeSpells(self):isSpellActive('detd_sleepspellenchat')  then
      types.Actor.spells(self):remove('detd_sleepspellenchat')
      types.Actor.stats.dynamic.fatigue(self).current = 10
    end

    if doOnce == 1 and types.Actor.activeSpells(self):isSpellActive('detd_sleep_spell') ~= true and types.Actor.activeSpells(self):isSpellActive('detd_sleepspellenchat') ~= true  then
      doOnce = 0
    end




    
      end,
                                        1 * time.second)  -- print 'Test' every 5 seconds

                                        local TARGET_RECORD = "r_bc_musbox_sheo_a"    -- lower-case editor ID
local targetRef     -- will hold the reference (nil until found)

local function findTarget()
  for _, act in ipairs(nearby.activators) do  -- scan loaded activators once
    if act.recordId == TARGET_RECORD then
      targetRef = act
      break
    end
  end
end

findTarget()  -- first search happens immediately

-------------------------------------------------------------------------------------------------
-- per-second logic
-------------------------------------------------------------------------------------------------
local doOnce = 0

local async  = require('openmw.async')     -- add this near your other require-lines
local SLEEP_ID = 'detd_sleep_spell3'

local sleepTimerHandle   -- nil while no countdown is running
---------------------------------------------------------------

time.runRepeatedly(function()

    -- … your existing stance / fatigue checks …

  --  if not (targetRef and targetRef:isValid()) then
        findTarget()
  --  end

   if targetRef and anim.hasAnimation(targetRef)
   and anim.hasGroup(targetRef, 'musboxloop')       -- optional, but tidy
   and anim.isPlaying(targetRef, 'musboxloop') then

    -- the box is actually looping right now
    local dist = (self.position - targetRef.position):length()
    if dist < 500 
    then
     --   then
            -----------------------------------------------------------
            -- grant the spell
            -----------------------------------------------------------
            types.Actor.stats.dynamic.fatigue(self).current = -45

           else 

            -----------------------------------------------------------
            -- ② start 60-second one-shot timer to revoke it
            -----------------------------------------------------------
      --      sleepTimerHandle = async:newUnsavableSimulationTimer(5, function ()
                -------------------------------------------------------
                -- ③ timer fires → remove spell, allow re-arming
                -------------------------------------------------------
        --        if types.Actor.activeSpells(self):isSpellActive('detd_sleep_spell3') then
       --             spellList:remove(SLEEP_ID)
       --         end
       --         sleepTimerHandle = nil            -- reset latch
      --      end)
        end
    end
 
end, 1* time.second)