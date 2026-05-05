local I     = require('openmw.interfaces')
local anim  = require('openmw.animation')
local async = require('openmw.async')
local core  = require('openmw.core')
local input = require('openmw.input')
local self  = require('openmw.self')
local types = require('openmw.types')
local isWorldPaused  = core.isWorldPaused
local isSoundPlaying = core.sound.isSoundPlaying
local stopSound3d    = core.sound.stopSound3d
local getCompletion = anim.getCompletion
local setAnimSpeed  = anim.setSpeed
local getSpeed     = types.Actor.stats.attributes.speed
local getEquipment = types.Actor.getEquipment
local getStance    = types.Actor.getStance
local setStance    = types.Actor.setStance
local Lockpick     = types.Lockpick
local Probe        = types.Probe
local Weapon       = types.Weapon
local weaponRecord = types.Weapon.record


local state, readying, casting, reverting, rearming, finishing, idling
local prevStance = getStance(self) -- 0 weapon 1 magic 2
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
      local item = getEquipment(self, 16)
      if item then
         local type = item.type
         if type == Weapon then
            fx = weaponSound[weaponRecord(item).type + 1]
            fx = fx and 'weapon ' .. fx
         elseif type == Lockpick then
            fx = 'lockpick'
         elseif type == Probe then
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
   if isWorldPaused() then elseif state == idling then
      speed = 2 / (1 + 2 ^ - (getSpeed(self).modified / 100))
      initRightHandSoundEffects()
      if getStance(self) == 2 then
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
   -- print(string.format("-- %-16s %-16s %s", group, key, getCompletion(self, group)))
   if state == idling then -- optimization
   elseif group == 'spellcast' then
      local fst, snd = string.match(key, "([^ ]+) ([^ ]+)")
      if fst == 'self' or
         fst == 'touch' or
         fst == 'target' then
         if snd == 'stop' then
            state = reverting -- attempt #2 for spells
         else -- self|touch|target start
            setAnimSpeed(self, group, speed)
         end
      elseif snd == 'start' then -- equip|unequip start
         setAnimSpeed(self, group, 4)
      elseif state == readying
         and key == 'equip stop'
         and getCompletion(self, group) == 1 then
         state = casting
         countdown = 2
      end
   elseif state == rearming then
      if key == 'equip start' then
         setAnimSpeed(self, group, 8)
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
      setAnimSpeed(self, group, 8)
   end
end
I.AnimationController.addTextKeyHandler('', animHandler)


local function printState()
   if prevState ~= state then
      prevState  = state
      print("---------- " ..
            (state == readying  and ' readying' or
             state == casting   and '  casting' or
             state == reverting and 'reverting' or
             state == rearming  and ' rearming' or
             state == finishing and 'finishing' or
             state == idling    and '   idling'))
   end
end

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
   if getStance(self) == prevStance then
      state = prevStance == 1 and rearming or finishing
   else
      setStance(self, prevStance)
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
   elseif getStance(self) == 2 then
      finished = true
      state = readying
   else
      setStance(self, 2)
   end
end

idling = function()
   prevStance = getStance(self)
end

state = idling
if prevStance == 2 then setStance(self, 0) end
return {
   engineHandlers = {
      onFrame = function() -- onUpdate is too late for setting controls.use
         if isWorldPaused() then else
            -- printState()
            state()
         end
      end,
   },
}
