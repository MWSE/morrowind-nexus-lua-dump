local core = require('openmw.core')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local types = require('openmw.types')
local world = require('openmw.world')
local storage = require('openmw.storage')

local ritualStorage = storage.globalSection('RitualsModGlobal')
ritualStorage:setLifeTime(storage.LIFE_TIME.Temporary)

local teleporters = ritualStorage:getCopy('Teleporters') or {}

for k,v in pairs(teleporters) do print(k,v) end

local function addTeleporter(id,name,pos,cell)
  teleporters[id] = {pos=pos,name=name,cell=cell}
  ritualStorage:set('Teleporters',teleporters)
end

local function removeTeleporter(id)
  teleporters[id] = nil
  ritualStorage:set('Teleporters',teleporters)
end

local function ritualHandler(object,actor,options)
  local id = object.recordId
  if id == "r_ritual_circle" then
    actor:sendEvent('R_BookOpen',{object=object})
  elseif id == "r_ritual_circle_teleporter" then
    actor:sendEvent('R_TeleporterActivated',{object=object})
  end
end

local function drawRune(object,actor,options)
  if object.recordId == "r_chalk" then
    actor:sendEvent('R_RitualCircleCreation',{cell=actor.cell.name,position=actor.position})
  end
end

local function learnRitual(object,actor,options)
  if string.sub(object.recordId,1,5) == "sc_r_" then
    local id = string.sub(object.recordId,4)
    local name = types.Book.record(object).name
    actor:sendEvent('R_LearnRitual',{id=id})
  end
  return true
end

local function createRitualCircle(data)
  local ritual_circle = world.createObject("r_ritual_circle",1)
  ritual_circle:teleport(data.cell,data.position)
end

local function removeRitualCircle(data)
  if data.object.recordId == 'r_ritual_circle_teleporter' then
    removeTeleporter(data.object.id)
  end
  data.object:remove()
end

local function removeWithVfx(data)
  world.vfx.spawn(data.vfx,data.object.position,{scale=0.6})
  core.sound.playSoundFile3d(data.sound,data.object)
  if data.count == 0 then
    data.object:remove()
  else
    data.object:remove(data.count)
  end
end

local function createTeleporter(data)
  local obj = data.circle
  world.vfx.spawn('meshes/e/magic_area_alt.nif',obj.position,{scale=10})
  core.sound.playSoundFile3d('Sound/Fx/magic/altrH.wav',obj)
  local teleporter = world.createObject('r_ritual_circle_teleporter',1)
  teleporter:teleport(obj.cell,obj.position)
  obj:remove()
  addTeleporter(teleporter.id,data.name,obj.position,obj.cell.name)
end

local function teleportPlayer(data)
  data.actor:teleport(data.cell,data.pos)
  core.sound.playSoundFile3d('sound/Fx/magic/mystH.wav',data.actor)
end

local function npcHandler(object,actor)
  if object.type.record(object).class == 'enchanter service' then
    if not types.Actor.isDead(object) then
      local count = types.Actor.inventory(object):countOf('r_chalk')
      if count == 0 then
        world.createObject('r_chalk',1):moveInto(object)
      end
    end
  end
end

I.ItemUsage.addHandlerForType(types.Miscellaneous,drawRune)
I.ItemUsage.addHandlerForType(types.Book,learnRitual)
I.Activation.addHandlerForType(types.Activator,ritualHandler)
I.Activation.addHandlerForType(types.NPC,npcHandler)

local function onLoad(save)
  save = save or {}
  teleporters = save.teleporters or {}
  ritualStorage:set('Teleporters',teleporters)
end

local function onSave()
  return {teleporters=teleporters}
end

return {
  eventHandlers = {
    R_CreateRitualCircle = createRitualCircle,
    R_RemoveRitualCircle = removeRitualCircle,
    R_RemoveWithVfx = removeWithVfx,
    R_Create_Teleporter = createTeleporter,
    R_Teleport = teleportPlayer,
  },
  engineHandlers = {
    onLoad = onLoad,
    onSave = onSave,
  }
}