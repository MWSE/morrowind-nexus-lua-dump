local core                      = require('openmw.core')
local store                     = require('openmw.storage')
local types                     = require('openmw.types')
local util                      = require 'openmw.util'
local world                     = require('openmw.world')
local T                         = require("openmw.types")
local I                         = require('openmw.interfaces')

local CreateWeaponDraft = types.Weapon.createRecordDraft
local CreateArmorDraft = types.Armor.createRecordDraft

local EnchantRecords = core.magic.enchantments.records

local function record(object)
  return object.type.records[object.recordId]
end

local function itemData(item)
  assert(types.Item.objectIsInstance(item))
  return item.type.itemData(item)
end

local function getId(thing)
  local idType, recordId = type(thing)

  if idType == 'string' then
    recordId = thing
  else
    local dataType = thing.__type.name

    if dataType == 'ESM::Weapon' then
      recordId = thing.id
    elseif dataType == 'MWLua::GObject' then
      recordId = thing.recordId
    else
      error('Wtf is this: ' .. thing.__type.name)
    end
  end

  return recordId
end

local function preserveDurabilityAndCharge(oldObj, newObj, healthMod)
  local oldRec, newRec = record(oldObj), record(newObj)
  local oldData, newData = itemData(oldObj), itemData(newObj)

  assert(oldRec and newRec and oldData and newData)
  
  local newCond = oldData.condition
  local oldHealth = oldRec.health - healthMod
  if oldHealth <= newCond then
    newCond = newRec.health
  end
  newData.condition = newCond

  if not oldRec.enchant or not newRec.enchant then return end

  local oldEnc, newEnc = EnchantRecords[oldRec.enchant], EnchantRecords[newRec.enchant]

  local oldMax, newMax = oldEnc and oldEnc.charge or 0, newEnc and newEnc.charge or 0

  if newMax <= 0 then
    return
  end

  local oldCharge = oldData.enchantmentCharge
  local src = oldCharge and oldCharge or oldMax

  if src > newMax then
    src = newMax
  elseif src < 0 then
    src = 0
  end

  newData.enchantmentCharge = util.round(src)
end

local function requestAddItem(actor, newObj, oldObj, damage)
  assert(newObj and newObj:isValid())

  doDurabilityAndCharge(oldObj, newObj, damage)

  actor:sendEvent('FUJI_addItem',{actor = actor, new = newObj,old = oldObj})
end

local function resetCondition(oldItem, newItem)
  
end

local function getOrCreateObject(actor, recordOrId)
  local inv = actor.type.inventory(actor)
  local recordId = getId(recordOrId)
  local obj = inv:find(recordId)
  if obj then return obj end

  local newObj = world.createObject(recordId, 1)
  newObj:moveInto(inv)

  return newObj
end

function doRepair(data)
  local actor, smith, item, damage, repair, tool, toolMult, gold, price = data.actor, data.smith, data.item, data.damage, data.repair, data.tool, data.toolMult, data.gold, data.price
  
  local selfRepair = 1
  
  local record
  local newValue
  local draft
  local newObj
  
  local id
  
  if damage > 0 then
    record = item.type.record(item)
    
    newValue = ((record.health - damage) / record.health) * record.value
    
    draft = {
      template = record,
      health = record.health - damage,
      value = newValue
    }
    
    if item.type == T.Weapon then
      draft = CreateWeaponDraft(draft)
    elseif item.type == T.Armor then
      draft = CreateArmorDraft(draft)
    else
      print("This should not happen")
      return
    end
    
    id = world.createRecord(draft).id
    
    newObj = getOrCreateObject(actor, id)
    preserveDurabilityAndCharge(item, newObj, damage)
  else
    newObj = item
  end
  
  core.sendGlobalEvent('ModifyItemCondition', { actor = actor, item = newObj, amount = repair })
  
  if newObj ~= item then
    item:remove(1)
  end
    
  if data.tool then
    local toolUses = itemData(tool).condition
    local toolDamage = math.ceil(damage / toolMult)
    
    itemData(tool).condition = toolUses - toolDamage
  
    if itemData(tool).condition <= 0 then 
      tool:remove(1)
    end
    if itemData(tool).condition > 0 then
      actor:sendEvent('FUJI_destroyUI',{})
      actor:sendEvent('FUJI_createUI',{actor = actor, tool = tool})
    else
      actor:sendEvent('FUJI_destroyUI',{})
    end
  else
    gold:remove(price)
    world.createObject("gold_001", price):moveInto(smith)
  
    actor:sendEvent('FUJI_destroyUI',{})
    actor:sendEvent('FUJI_createUI',{})
  end
end

function handleActivateHammer(object, actor)
  actor:sendEvent('FUJI_createUI',{actor = actor, tool = object})
end

local function init() 
    I.ItemUsage.addHandlerForType(T.Repair, handleActivateHammer)
end

return {
  engineHandlers = {
    onInit = init,
    onLoad = init,
  },
  eventHandlers = {
    FUJI_getSettings = getSettings,
    FUJI_doRepair = doRepair,
    FUJI_RemoveObject = function(object)
      assert(object and object:isValid())
      object:remove(1)
    end
  },
}