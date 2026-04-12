local ui = require('openmw.ui')
local core = require('openmw.core')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local self = require('openmw.self')
local ambient = require('openmw.ambient')

local harmless = {name="harmless",severity = 0.1,events = {}}
local minor = {name="minor",severity = 0.2,events = {}}
local medium = {name="medium",severity = 0.45,events = {}}
local major = {name="major",severity = 0.65,events = {}}
local disaster = {name="disastrous",severity = 0.80,events = {}}
local whatHaveYouDone = {name="WHAT HAVE YOU DONE",severity = 1,events = {}}

local failureTable = {
  harmless,minor,medium,major,disaster
}

--local function test(msg)
--  ui.showMessage(msg)
--end
--
--for k,v in pairs(failureTable) do
--  local name = v.name
--  table.insert(v.events,{func=function() test(name) end})
--end

--To each of failure functions are passed:
  -- ingredients - {item,count} where item is the gameobject and count is the amount to remove if ritual succeeds
  -- souls
  -- circle
local function spawnScrib(data)
  core.sendGlobalEvent('R_Outcome_Spawn',{id='scrib',cell=data.circle.cell.name,pos=data.circle.position})
  core.sendGlobalEvent('PlaySound3d',{file="Sound/Fx/magic/conjH.wav",position=data.circle})
end

local function playSoundEffect()
  local effects = {}
  --how exciting
  local id = math.random(1,#core.sound.records)
  ambient.playSound(core.sound.records[id].id)
  ui.showMessage('You heard something...')
end

local function loseGoldMinor()
  local gold = types.Actor.inventory(self):find('gold_001')
  if gold ~= nil then
    local rand = math.random(1,500)
    self:sendEvent('ShowMessage',{message="Your purse feels lighter..."})
    ambient.playSoundFile('Sound/Fx/item/money.wav')
    core.sendGlobalEvent('R_RemoveWithVfx',
    {
      object = gold,
      count = rand,
      vfx = "meshes/e/magic_hit_dst.nif",
      sound = "Sound/Fx/magic/destH.wav",
    })
  end
end

local function loseGoldMedium()
  local gold = types.Actor.inventory(self):find('gold_001')
  if gold ~= nil then
    local rand = math.random(1,1500)
    self:sendEvent('ShowMessage',{message="Your purse feels lighter..."})
    ambient.playSoundFile('Sound/Fx/item/money.wav')
    core.sendGlobalEvent('R_RemoveWithVfx',
    {
      object = gold,
      count = rand,
      vfx = "meshes/e/magic_hit_dst.nif",
      sound = "Sound/Fx/magic/destH.wav",
    })
  end
end

local function removeSoul(data)
  if data.souls ~= nil and #data.souls ~= 0 then
    local rand = math.random(1,#data.souls)
    local obj = data.souls[rand]
    local count = math.random(1,obj.count)
--    print("removing:",obj,count)
    core.sendGlobalEvent('R_RemoveWithVfx',
      {
        object = obj,
        count = count,
        vfx = "meshes/e/magic_hit_dst.nif",
        sound = "Sound/Fx/magic/destH.wav",
      })
    ui.showMessage('Soul gem has been destroyed!')
  end
end

local function removeIngred(data)
  if data.ingredients ~= nil and #data.ingredients ~= 0 then
    local rand = math.random(1,#data.ingredients)
    local obj = data.ingredients[rand].item
    local count = math.random(1,obj.count)
    core.sendGlobalEvent('R_RemoveWithVfx',
      {
        object = obj,
        count = count,
        vfx = "meshes/e/magic_hit_dst.nif",
        sound = "Sound/Fx/magic/destH.wav",
      })
    ui.showMessage('Ritual ingredient has been destroyed!')
  end
end

local function removeMultipleIngred(data)
  if data.ingredients ~= nil and #data.ingredients ~= 0 then
    local amount = math.random(1,#data.ingredients)
    local removed = 0
    for _,object in pairs(data.ingredients) do
      local obj = object.item
      local count = math.random(1,obj.count)
      core.sendGlobalEvent('R_RemoveWithVfx',
      {
        object = obj,
        count = count,
        vfx = "meshes/e/magic_hit_dst.nif",
        sound = "Sound/Fx/magic/destH.wav",
      })
    ui.showMessage('Multiple ritual ingredient have been destroyed!')
    end
  end
end

local function knockDown()
  types.NPC.stats.dynamic.fatigue(self).current = -20
  ambient.playSoundFile('Sound/Fx/magic/destH.wav')
end

local function damageHealth(max)
  local stat = types.NPC.stats.dynamic.health(self).base
  local damage = math.random(1,stat*max)
--  print("Current health:",stat)
--  print("Damage taken: ",stat-damage)
  types.NPC.stats.dynamic.health(self).current = types.NPC.stats.dynamic.health(self).current-damage
  ambient.playSoundFile('Sound/Fx/magic/destH.wav')
--  print(damage)
end

local function damageFatigue(max)
  local stat = types.NPC.stats.dynamic.fatigue(self).base
  local damage = math.random(1,stat*max)
  types.NPC.stats.dynamic.fatigue(self).current = types.NPC.stats.dynamic.fatigue(self).current-damage
  ambient.playSoundFile('Sound/Fx/magic/destH.wav')
end

local function damageMagicka(max)
  local stat = types.NPC.stats.dynamic.magicka(self).base
  local damage = math.random(1,stat*max)
  types.NPC.stats.dynamic.magicka(self).current = types.NPC.stats.dynamic.magicka(self).current-damage
  ambient.playSoundFile('Sound/Fx/magic/destH.wav')
end

local function soulBreaksFree(data)
  if data.souls ~= nil and #data.souls ~= 0 then
    local rand = math.random(1,#data.souls)
    local obj = data.souls[rand]
    local name = types.Item.itemData(obj).soul
    core.sendGlobalEvent('R_Outcome_Spawn',{id=name,cell=data.circle.cell.name,pos=data.circle.position,hostile=true,target=self})
    core.sendGlobalEvent('PlaySound3d',{file="Sound/Fx/magic/conjH.wav",position=data.circle})
    core.sendGlobalEvent('R_RemoveWithVfx',
      {
        object = obj,
        count = 0,
        vfx = "meshes/e/magic_hit_dst.nif",
        sound = "Sound/Fx/magic/destH.wav",
      })
    ui.showMessage('A soul has broken free from the soulgem!')
  end
end

local function allSoulsBreakFree(data)
  if data.souls ~= nil and #data.souls ~= 0 then
    for _,obj in pairs(data.souls) do
      local name = types.Item.itemData(obj).soul
      core.sendGlobalEvent('R_Outcome_Spawn',{id=name,cell=data.circle.cell.name,pos=data.circle.position,hostile=true,target=self})
      core.sendGlobalEvent('PlaySound3d',{file="Sound/Fx/magic/conjH.wav",position=data.circle})
      core.sendGlobalEvent('R_RemoveWithVfx',
        {
          object = obj,
          count = 0,
          vfx = "meshes/e/magic_hit_dst.nif",
          sound = "Sound/Fx/magic/destH.wav",
        })
      ui.showMessage('All of the souls have broken free!')
    end
  end
end

local function daedraAttack(data)
  local possibleSpawns = {'atronach_flame','atronach_frost','atronach_storm','clannfear','daedroth','dremora','dremora_lord','golden saint','hunger','ogrim','winged twilight','scamp'}
  local amount = math.random(3,10)
    for i=1,amount do
      local rand = math.random(1,#possibleSpawns)
      local id = possibleSpawns[rand]
      core.sendGlobalEvent('R_Outcome_Spawn',{id=id,cell=data.circle.cell.name,pos=data.circle.position,hostile=true,target=self})
      core.sendGlobalEvent('PlaySound3d',{file="Sound/Fx/magic/conjH.wav",position=data.circle})
      core.sendGlobalEvent('R_RemoveWithVfx',
        {
          object = obj,
          count = 0,
          vfx = "meshes/e/magic_hit_dst.nif",
          sound = "Sound/Fx/magic/destH.wav",
        })
      ui.showMessage('Hostile daedra emerge from the rift!')
    end
end

local function drainRandomStat()
  local rand = math.random(1,8)
  types.Actor.activeSpells(self):add({id='r_ritual_drain_stat',effects={rand}})
  self:sendEvent('AddVfx',{model='meshes/e/magic_hit_dst.nif'})
  ambient.playSoundFile('Sound/Fx/magic/destH.wav')
end

local function damageRandomStat()
  local rand = math.random(1,8)
  types.Actor.activeSpells(self):add({id='r_ritual_damage_stat',effects={rand}})
  self:sendEvent('AddVfx',{model='meshes/e/magic_hit_dst.nif'})
  ambient.playSoundFile('Sound/Fx/magic/destH.wav')
  ui.showMessage('You feel weaker...')
end

-- too unpredictable
--local function randomHostileCreature(data)
--  local rand = math.random(1,#types.LevelledCreature.records)
--  local id = types.LevelledCreature.records[rand].id
--  print(id)
--  core.sendGlobalEvent('R_Outcome_Spawn',{id=id,cell=data.circle.cell.name,pos=data.circle.position,hostile=true,target=self})
--      core.sendGlobalEvent('PlaySound3d',{file="Sound/Fx/magic/conjH.wav",position=data.circle})
--      core.sendGlobalEvent('R_RemoveWithVfx',
--        {
--          object = obj,
--          count = 0,
--          vfx = "meshes/e/magic_hit_dst.nif",
--          sound = "Sound/Fx/magic/destH.wav",
--        })
--end

-- explode the circle (damage things around. items too? idk) - disaster
-- damage the armor/weapon?

table.insert(minor.events,{func=function() damageHealth(0.15) end})
table.insert(minor.events,{func=function() damageMagicka(0.15) end})
table.insert(minor.events,{func=function() damageFatigue(0.15) end})

table.insert(medium.events,{func=function() damageHealth(0.4) end})
table.insert(medium.events,{func=function() damageMagicka(0.4) end})
table.insert(medium.events,{func=function() damageFatigue(0.4) end})

table.insert(major.events,{func=function() damageHealth(0.7) end})
table.insert(major.events,{func=function() damageMagicka(0.7) end})
table.insert(major.events,{func=function() damageFatigue(0.7) end})

table.insert(harmless.events,{func=spawnScrib})
table.insert(harmless.events,{func=playSoundEffect})
table.insert(minor.events,{func=loseGoldMinor})
table.insert(minor.events,{func=knockDown})
table.insert(minor.events,{func=drainRandomStat})
table.insert(medium.events,{func=removeIngred})
table.insert(medium.events,{func=removeSoul})
table.insert(medium.events,{func=loseGoldMedium})
table.insert(major.events,{func=damageRandomStat})
table.insert(major.events,{func=removeMultipleIngred})
table.insert(major.events,{func=soulBreaksFree})
--table.insert(major.events,{func=randomHostileCreature})
table.insert(disaster.events,{func=allSoulsBreakFree})
table.insert(disaster.events,{func=daedraAttack})

return failureTable