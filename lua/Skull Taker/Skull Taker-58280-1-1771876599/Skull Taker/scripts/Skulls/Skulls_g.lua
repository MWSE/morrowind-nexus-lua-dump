local I = require('openmw.interfaces')
local types = require('openmw.types')
local core = require('openmw.core')
local world = require('openmw.world')
local storage = require('openmw.storage')

local Skulls = {
  argonian = "T_Com_SkullArgonian_02",
  khajiit = "T_Com_SkullKhajiit_02",
  orc = "T_Com_SkullOrc_02",
  default = "misc_skull00"
}



--- TODO: store corpses by race/gender to not bloat the save
local function removeHead(data)
  local object = data.object
  local actor = data.actor
  if object.type == types.NPC and types.Actor.isDeathFinished(object) then
    local name = types.NPC.record(object).name
    if name == "Headless corpse" then return end
    local deadNpc = types.NPC.record(object.recordId)
    
    local bodyStorage = storage.globalSection('SK_BodyStorage')
    local id = deadNpc.race..tostring(deadNpc.isMale)
    
    local newId = nil
    
    local storageResult = bodyStorage:get(id)
    if storageResult ~= nil then
      newId = storageResult
    else
      local npcTemplate = types.NPC.record('skulls_template_npc')
      local npcTable = {
        name="Headless corpse",
        template=npcTemplate,
        head="meshes/notAhelmet.nif",
        race=deadNpc.race,
        isMale=deadNpc.isMale,
        hair=""
        }
      local npcDraft = types.NPC.createRecordDraft(npcTable)
      local newNpc = world.createRecord(npcDraft)
      newId = newNpc.id
      bodyStorage:set(id,newId)
    end
    
    local oldInventory = types.Actor.inventory(object):getAll()
    local equippedItems = types.Actor.getEquipment(object)
    -- So you can see what have you done
    equippedItems[types.Actor.EQUIPMENT_SLOT.Helmet] = nil
    
    
    local replacementNpc = world.createObject(newId)
    replacementNpc:teleport(object.cell.name,object.position,object.rotation)
    local skull = Skulls[deadNpc.race] or Skulls.default
    if types.Miscellaneous.record(skull) == nil then
      skull = Skulls.default
    end
    world.createObject(skull):moveInto(replacementNpc)
    for _,item in pairs(oldInventory) do
      item:moveInto(types.Actor.inventory(replacementNpc))
    end
    replacementNpc:sendEvent('SK_Equip',{inv=equippedItems})
    object:remove()
  end
end

local function onSave()
  local data = storage.globalSection('SK_BodyStorage'):asTable()
  return data
end

local function onLoad(savedData)
  local data = storage.globalSection('SK_BodyStorage')
  data:reset(savedData)
end

return {
  eventHandlers = {
    SK_RaycastSuccess = removeHead,
  },
  engineHandlers = {
    onSave = onSave,
    onLoad = onLoad,
  }
}