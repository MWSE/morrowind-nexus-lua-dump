-- Per-NPC script – attach to the creature that can be Wabbajacked
local self  = require('openmw.self')
local types = require('openmw.types')
local time  = require('openmw_aux.time')
local core  = require('openmw.core')
local anim  = require('openmw.animation')
local AI    = require('openmw.interfaces').AI

local wasTransformed, doOnce = false, false

---------------------------------------------------------------------
-- Helper tables – ONE source of truth for slots and item lists
---------------------------------------------------------------------
local ITEM_LISTS = require('scripts.detd_randomItemLists')   -- << move all those long tables into their own file
--[[
  ITEM_LISTS = {
      helmet       = { slot = types.Actor.EQUIPMENT_SLOT.Helmet,       ids = {...} },
      robe         = { slot = types.Actor.EQUIPMENT_SLOT.Robe,         ids = {...} },
      boots        = { slot = types.Actor.EQUIPMENT_SLOT.Boots,        ids = {...} },
      cuirass      = { slot = types.Actor.EQUIPMENT_SLOT.Cuirass,      ids = {...} },
      greaves      = { slot = types.Actor.EQUIPMENT_SLOT.Greaves,      ids = {...} },
      lGauntlet    = { slot = types.Actor.EQUIPMENT_SLOT.LeftGauntlet, ids = {...} },
      rGauntlet    = { slot = types.Actor.EQUIPMENT_SLOT.RightGauntlet,ids = {...} },
      lPauldron    = { slot = types.Actor.EQUIPMENT_SLOT.LeftPauldron, ids = {...} },
      rPauldron    = { slot = types.Actor.EQUIPMENT_SLOT.RightPauldron,ids = {...} },
      pants        = { slot = types.Actor.EQUIPMENT_SLOT.Pants,        ids = {...} },
      shirt        = { slot = types.Actor.EQUIPMENT_SLOT.Shirt,        ids = {...} },
      skirt        = { slot = types.Actor.EQUIPMENT_SLOT.Skirt,        ids = {...} },
  }
]]
---------------------------------------------------------------------

local function disableSelf()
  core.sendGlobalEvent('detd_DisableActor', { obj2 = self })
end

---------------------------------------------------------------------
-- MAIN update loop – checked every 0.1 s
---------------------------------------------------------------------
time.runRepeatedly(function ()
  -- after a transformation the corpse should vanish once the animation stops
  if wasTransformed and types.Actor.isDeathFinished(self) then
    disableSelf()
  end

  local active = types.Actor.activeSpells(self):isSpellActive('T_Dae_UNI_Wabbajack')
  if active and not doOnce then


local WEIGHTED_OPTIONS = {
    -- high-probability picks
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,         -- option 1  (×10)
    2,2,2,2,               -- option 2  (×7)
    3,3,3,3,3,           -- option 3  (×9)
    5,5,5,5,5,5,5,5,             -- option 5  (×8)
    7,7,7,               -- option 7  (×7)
    8,8,8,8,8,8,  
    4,4,4,4,4,4,4,4,4, -- option 8  (×5)


    -- very re
    6                            -- option 6  (×1)
}

    local option = WEIGHTED_OPTIONS[math.random(#WEIGHTED_OPTIONS)]
    print(option)

    if option == 1 then               ---------------- Transformation
      core.sendGlobalEvent('detd_WabbaEvent',          { obj = self })
      core.sendGlobalEvent('detd_SmallifyActorWabba',  { obj2 = self })
      types.Actor.stats.dynamic.health(self).current  = 0
      types.Actor.stats.dynamic.fatigue(self).current = 0
      types.Actor.spells(self):add('detd_wabbakillinvis')
      types.Actor.setEquipment(self, {})
      wasTransformed = true

    elseif option == 2 then           ---------------- Invisibility
      types.Actor.activeSpells(self):add{ id='invisibility', effects={0} }

    elseif option == 3 then           ---------------- Paralysis
      types.Actor.activeSpells(self):add{ id='Paralysis', effects={0} }

    elseif option == 4 then                -- Dance + Calm (random animation)
    types.Actor.stats.ai.fight(self).base = 0
    -- pick one of three “show-off” idles
   -- local dances = { 'xanim_dancingwabba', 'bellydance', 'twistdance', 'SalsaDancing4', 'NorthernSoulSpin', 'bellydance', 'bellydance',}
   --  local dances = { 'SwingDancing3' }
   local dances = { 'NorthernSoulSpin'}
    local animId = dances[math.random(#dances)]
    anim.playBlended(self, animId, { priority = anim.PRIORITY.Scripted })

    elseif option == 5 then           ---------------- *** RANDOM GEAR ***
      
      -- build a table of replacement IDs only for the slots this NPC actually wears
      local replacements = {}
      for key, t in pairs(ITEM_LISTS) do
        if types.Actor.getEquipment(self, t.slot) then
          local list = t.ids
          replacements[key] = list[math.random(#list)]
        end
      end
      if next(replacements) then
        core.sendGlobalEvent('detd_wabbahat', { obj3 = self, items = replacements })
      end

    elseif option == 6 then           ---------------- Spawn Clone
      core.sendGlobalEvent('detd_SpawnClone', { obj = self, chance = 0.20 })

    elseif option == 7 then          -- *** free slot for future shenanigans ***
      core.sendGlobalEvent('detd_ModifyDisposition', { npc = self, amount = 100 })
      AI.removePackages('Combat')
      types.Actor.stats.ai.alarm(self).base = 0
    elseif option == 8 then              -- Gradual shrink (new!)
    -- put the NPC into the global shrink queue
     local s = self.scale
      core.sendGlobalEvent('detd_rememberBaseline',   { obj = self })
        --  a) Unter 0,30  →  GROW
        if s < 0.30 then
            core.sendGlobalEvent('detd_StartGradualGrow', { obj = self })
            core.sendGlobalEvent('detd_WabbaReset',  { obj = self })

        --  b) Über 1,20  →  NORMALIZE
        elseif s > 1.20 then
            core.sendGlobalEvent('detd_StartGradualNormalize', { obj = self })
            core.sendGlobalEvent('detd_WabbaReset',  { obj = self })

        --  c) Zwischen 0,90 – 1,10  →  50 % Shrink  /  50 % Enlarge
        elseif s >= 0.90 and s <= 1.10 then
            if math.random() < 0.95 then
                core.sendGlobalEvent('detd_StartGradualShrink',  { obj = self })
                core.sendGlobalEvent('detd_WabbaWeak',   { obj = self })
            else
                core.sendGlobalEvent('detd_StartGradualEnlarge', { obj = self })
                core.sendGlobalEvent('detd_WabbaStrong', { obj = self })
            end
        --  d) alle Zwischen­bereiche (0,30-0,90  bzw. 1,10-1,20) bleiben ohne Effekt
        end
    end
    
    doOnce = true
  elseif not active then
    doOnce = false
  end
end, 0.1 * time.second)

---------------------------------------------------------------------
-- EVENT: after the server script has added new items, equip them
---------------------------------------------------------------------
local function detd_WabbaInventoryComplete(data)
  local equipment = types.Actor.getEquipment(self)
  for key, id in pairs(data) do
    local slot = ITEM_LISTS[key].slot
    if slot then equipment[slot] = id end
  end
  types.Actor.setEquipment(self, equipment)
end


return {
  eventHandlers = {
    detd_WabbaInventoryComplete = detd_WabbaInventoryComplete,
  }
}
