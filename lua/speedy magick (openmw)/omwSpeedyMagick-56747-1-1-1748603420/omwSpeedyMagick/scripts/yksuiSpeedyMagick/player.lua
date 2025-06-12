local I     = require('openmw.interfaces')
local anim  = require('openmw.animation')
local async = require('openmw.async')
local core  = require('openmw.core')
local input = require('openmw.input')
local self  = require('openmw.self')
local types = require('openmw.types')
local ui    = require('openmw.ui')
local isSoundPlaying = core.sound.isSoundPlaying
local stopSound3d    = core.sound.stopSound3d
local getSpeed    = types.Actor.stats.attributes.speed
local isaLockpick = types.Lockpick.objectIsInstance
local isaProbe    = types.Probe.objectIsInstance
local isaWeapon   = types.Weapon.objectIsInstance
local asaWeapon   = types.Weapon.record
local Actor = types.Actor


local state, readying, casting, reverting, rearming, finishing, idling
local prevStance = Actor.getStance(self) -- 0 weapon 1 magic 2
local countdown, speed, finished = 1, 1, true
local fxDown, fxUp


local weaponSound = {
   'shortblade' , -- ShortBladeOneHand
   'longblade'  , -- LongBladeOneHand
   'longblade'  , -- LongBladeTwoHand
   'blunt'      , -- BluntOneHand
   'blunt'      , -- BluntTwoClose
   'blunt'      , -- BluntTwoWide
   'spear'      , -- SpearTwoWide
   'blunt'      , -- AxeOneHand
   'blunt'      , -- AxeTwoHand
   'bow'        , -- MarksmanBow
   'crossbow'   , -- MarksmanCrossbow
   'blunt'      , -- MarksmanThrown
}

local function initRightHandSoundEffects()
   local fx
   if prevStance == 1 then
      local item = Actor.getEquipment(self, 16)
      if item then
         if isaWeapon(item) then
            fx = weaponSound[asaWeapon(item).type + 1]
            fx = fx and 'weapon ' .. fx
         elseif isaLockpick(item) then
            fx = 'lockpick'
         elseif isaProbe(item) then
            fx = 'probe'
         end
      end
   end
   if fx then
      fxDown = 'item ' .. fx .. ' down'
      fxUp   = 'item ' .. fx .. ' up'
   else
      fxDown = nil
      fxUp   = nil
   end
end

local function trigHandler(fallback)
   -- print("================================")
   if core.isWorldPaused() then elseif state == idling then
      speed = 2 / (1 + 2 ^ - (getSpeed(self).modified / 100))
      initRightHandSoundEffects()
      if Actor.getStance(self) == 2 then
         if prevStance == 2 then
            state = casting
            countdown = 1
         else
            state = readying
         end
      elseif prevStance == 2 then -- exit magic stance
      else -- no magic, or attacking, or staggered
         state = fallback or reverting
      end
   else
      finished = false
   end
end
local onQuickKey = async:callback(function() trigHandler(readying) end)
for i=1,9 do input.registerTriggerHandler('QuickKey'..i, onQuickKey) end
input.registerTriggerHandler('ToggleSpell' , async:callback(trigHandler))


local weaponGroup = {
   bowandarrow   = true,
   crossbow      = true,
   handtohand    = true,
   throwweapon   = true,
   weapononehand = true,
   weapontwohand = true,
   weapontwowide = true,
}

local function animHandler(group, key)
   -- print("---- " .. group .. ": " .. key)
   if state == idling then -- optimization
   elseif group == 'spellcast' then
      local fst, snd = string.match(key, "([^ ]+) ([^ ]+)")
      if fst == 'self' or
         fst == 'touch' or
         fst == 'target' then
         if snd == 'stop' then
            state = reverting -- attempt #2 for spells
         else -- self|touch|target start
            anim.setSpeed(self, group, speed)
         end
      elseif snd == 'start' then -- equip|unequip start
         anim.setSpeed(self, group, 4)
      elseif state == readying
         and key == 'equip stop'
         and not anim.getCompletion(self, group) then
         state = casting
         countdown = 2
      end
   elseif state == rearming then
      if key == 'equip start' then
         anim.setSpeed(self, group, 8)
      elseif key == 'equip stop' then
         state = finishing
      elseif key:sub(-4) == 'stop'
         and weaponGroup[group] then
         state = finishing -- triggered while attacking
         finished = false  -- to force ready magic
      end
   elseif state == readying
      and key == 'unequip start'
      and weaponGroup[group] then
      anim.setSpeed(self, group, 8)
   end
end
I.AnimationController.addTextKeyHandler('', animHandler)


readying = function()
   if fxDown and isSoundPlaying(fxDown, self) then
      stopSound3d(fxDown, self)
   end
end

casting = function()
   if countdown > 1 then
      countdown = countdown - 1
   else
      self.controls.use = 1
      state = reverting -- attempt #1 for items (instant use)
      finished = true
   end
end

reverting = function()
   if Actor.getStance(self) == prevStance then
      state = (prevStance == 1) and rearming or finishing
   else
      Actor.setStance(self, prevStance)
   end
end

rearming = function()
   if fxUp and isSoundPlaying(fxUp, self) then
      stopSound3d(fxUp, self)
   end
end

finishing = function()
   if finished then
      state = idling
   elseif Actor.getStance(self) == 2 then
      finished = true
      state = readying
   else
      Actor.setStance(self, 2)
   end
end

idling = function()
   prevStance = Actor.getStance(self)
end

local function printState()
   if prevState ~= state then
      prevState = state
      print("---- state:",
            state == readying  and 'readying'  or
            state == casting   and 'casting'   or
            state == reverting and 'reverting' or
            state == rearming  and 'rearming'  or
            state == finishing and 'finishing' or
            state == idling    and 'idling')
   end
end

state = idling
if prevStance == 2 then
   Actor.setStance(self, 0)
end
return {
   engineHandlers = {
      onFrame = function() -- onUpdate is too late for setting controls.use
         if core.isWorldPaused() then else
            -- printState()
            state()
         end
      end,
   },
}
