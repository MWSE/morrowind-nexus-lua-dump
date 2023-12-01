local core = require('openmw.core')
local world = require('openmw.world')
local types = require('openmw.types')
local async = require('openmw.async')
local I = require('openmw.interfaces')

local PERFUME_ID_SET = {
   ['potion_t_bug_musk_01'] = true,
}


for i = 1, 6 do
   PERFUME_ID_SET[('t_com_subst_perfume_%02d'):format(i)] = true
end

local function maxEffectDuration(rec)
   local duration = 0
   for _, effect in ipairs(rec.effects) do
      if effect.duration > duration then
         duration = effect.duration
      end
   end
   return duration
end

local function hasVampirism(player)
   return types.Actor.activeEffects(player):getEffect('vampirism') ~= nil
end

local function setVampirism(player, active)
   if not hasVampirism(player) then return end
   types.Actor.activeEffects(player):set(active and 1 or 0, 'vampirism')
   local globals = world.mwscript.getGlobalVariables(player)
   globals.pcvampire = active and 1 or 0
end

local actorPefumes = {}

local perfumeRanOut = async:registerTimerCallback('perfumeRanOut', function(player)
   local count = (actorPefumes[player.id] or 0) - 1
   if count <= 0 then
      setVampirism(player, true)
      actorPefumes[player.id] = nil
   end
end)

I.ItemUsage.addHandlerForType(types.Potion, function(potion, actor)
   if actor.type ~= types.Player then return end
   if not PERFUME_ID_SET[potion.recordId] then return end
   if not hasVampirism(actor) then return end

   actorPefumes[actor.id] = (actorPefumes[actor.id] or 0) + 1
   setVampirism(actor, false)
   local potionRecord = types.Potion.record(potion)
   local duration = maxEffectDuration(potionRecord)
   async:newGameTimer(duration * core.getGameTimeScale(), perfumeRanOut, actor)
end)

return {
   interfaceName = 'urm_PerfumedVampires',
   interface = {
      version = 1,
      registerPerfume = function(id)
         PERFUME_ID_SET[id] = true
      end,
      isPerfumed = function(actor)
         return (actorPefumes[actor.id] or 0) > 0
      end,
      isVampire = function(actor)
         return hasVampirism(actor)
      end,
   },
}
