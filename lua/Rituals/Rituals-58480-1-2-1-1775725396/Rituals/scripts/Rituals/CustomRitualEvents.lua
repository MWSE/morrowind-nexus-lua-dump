local core = require('openmw.core')
local I = require('openmw.interfaces')
local types = require('openmw.types')
local storage = require('openmw.storage')
local world = require('openmw.world')
local util = require('openmw.util')

local summonStorage = storage.globalSection('RitualSummon')
summonStorage:setLifeTime(storage.LIFE_TIME.Temporary)

local activeSummon = nil

local function repairGear(data)
  types.Item.itemData(data.item).condition = data.condition
end

local function spawn(data)
  local object = world.createObject(data.id,1)
  if data.hostile then
    object:sendEvent('StartAIPackage',{type='Combat',target=data.target})
  end
  object:teleport(data.cell,data.pos)
  world.vfx.spawn('meshes/e/magic_summon.nif',data.pos)
end

local function spawnItem(data)
  local item = world.createObject(data.id,data.count)
  item:teleport(data.cell,data.pos)
end

local function spawnVendor(data)
  local vendor = world.createObject('r_dremora_vendor',1)
   local rituals = data.rituals
  for _,ritual in ipairs(rituals) do
    local id = "sc_"..ritual
    if types.Book.records[id] ~= nil then
      world.createObject(id,1):moveInto(vendor)
    end
  end
  
  vendor:teleport(data.cell,data.pos)
  vendor:addScript('scripts/Rituals/DremoraVendor.lua')
  world.vfx.spawn('meshes/e/magic_summon.nif',data.pos,{scale = 3})
end

local function removeVendor(data)
  world.vfx.spawn('meshes/e/magic_summon.nif',data.actor.position,{scale = 3})
  core.sound.playSoundFile3d('Sound/Fx/magic/conjH.wav',data.actor)
  data.actor:remove()
end

local function removeSummon(data) 
  if data.actor:hasScript("scripts/Rituals/summon/summon.lua") then
    data.actor:removeScript("scripts/Rituals/summon/summon.lua")
  end
  if data.clean then
--    print("Cleaning")
    activeSummon = nil
    summonStorage:set('SummonData',nil)
    world.players[1]:sendEvent('R_RemoveCategory',{category=data.category})
  else
--    print("normal remove")
    world.vfx.spawn('meshes/e/magic_summon.nif',data.actor.position)
    core.sound.playSoundFile3d('Sound/Fx/magic/conjH.wav',data.actor)
    data.actor:remove()
  end
end

local function summonSpawn(data)
--  print(data.creature)
  local creature = world.createObject(data.creature,1)
  local summonData = {
    gId = creature.id,
    id = creature.recordId,
    mode = "stay",
  }
  summonStorage:set('SummonData',summonData)
  
  creature:addScript("scripts/Rituals/summon/summon.lua")
  creature:teleport(data.circle.cell.name,data.circle.position)
  world.vfx.spawn('meshes/e/magic_summon.nif',data.circle.position,{})
  core.sound.playSoundFile3d('Sound/Fx/magic/conjH.wav',data.circle)
end

local function onLoad(save)
  save = save or {}
  local summons = save.summons or {}
  activeSummon = save.activeSummon or nil
  summonStorage:set('SummonData',summons)
end

local function onSave()
  return {summons=summonStorage:getCopy('SummonData'),activeSummon=activeSummon}
end

local function teleportToPlayer(data)
  if types.Actor.isDead(data.actor) then return end
  local player = world.players[1]
  data.actor:teleport(player.cell,player.position + util.vector3(50,0,0),{onGround=true})
end

local function setActiveSummon(data)
  activeSummon = data.actor
--  print("Active summon:",data.actor)
end

local function applyRest(data)
  if activeSummon then
    activeSummon:sendEvent('R_RestSummon',{duration=data.duration})
  end
end

local function recoverSummon(data)
  local player = world.players[1]
  activeSummon:teleport(data.circle.cell,data.circle.position)
  world.vfx.spawn('meshes/e/magic_summon.nif',data.circle.position,{})
  core.sound.playSoundFile3d('Sound/Fx/magic/conjH.wav',data.circle)
end

return {
  eventHandlers = {
    R_RitualRepairGear = repairGear,
    R_Outcome_Spawn = spawn,
    R_SpawnItem = spawnItem,
    R_Spawn_DremoraVendor = spawnVendor,
    R_RemoveVendor = removeVendor,
    R_Summon_Spawn = summonSpawn,
    R_Summon_Remove = removeSummon,
    R_TeleportToPlayer = teleportToPlayer,
    R_Active_Summon = setActiveSummon,
    R_ApplySummonRest = applyRest,
    R_RecoverSummon = recoverSummon,
  },
  engineHandlers = {
    onLoad = onLoad,
    onSave = onSave,
  }
}