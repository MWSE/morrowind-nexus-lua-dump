local world = require('openmw.world')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local types = require('openmw.types')
local core = require('openmw.core')
local storage = require('openmw.storage')

local lockpickSettings = storage.globalSection('SettingsSkyrimLockpicking')

local oldLockpick = nil
local lockpick = nil
local lock = nil
local lockCase = nil
local dir = 1
local lockOrProbe = nil

local overriding = false

local current_lockable = nil

local function spawnPick(data)
  if oldLockpick ~= nil then
    if oldLockpick.count > 0 then
      oldLockpick:remove()
      oldLockpick = nil
      return
    end
  end

  if lockpick == nil then return end
  if lockpick.count > 0 then
    lockpick:setScale(0.55)
    lockpick:teleport(data.cell,data.pos,data.rot)
  end
end

local function spawnLock(data)
  if lock == nil then
    lock = world.createObject("sl_lock")
    lock:teleport(data.cell,data.pos,data.rot)
    lock:setScale(0.4)
    lockCase = world.createObject("sl_lock_case")
    lockCase:teleport(data.cell,data.pos,data.rot)
    lockCase:setScale(0.4)
  end
end

local function rotateLock(data)
  if lock ~= nil then
    lock:teleport(lock.cell,lock.position,data.tf)
  end
end

local function shakeLockpick()
  if lockpick == nil then return end
  local pos = lockpick.position
  local shake = 0.3 * dir
  dir = -dir
  pos = pos + util.vector3(shake,shake,0)
  if lockpick.cell then
    lockpick:teleport(lockpick.cell,pos)
  end
end

local function removePick()
  if lockpick ~= nil then
    --lockpick:remove()
    if types.Item.itemData(lockpick).condition ~= 0 then
      lockpick:setScale(1)
      local autopicking = lockpickSettings:get('autopicking')
      lockpick:moveInto(world.players[1])
      --print("AUTOPICKING:",autopicking)
      if not autopicking then
        world.players[1]:sendEvent("SL_ReEquipLockpick",{obj=lockpick})
      end
    else
      lockpick:remove()
    end
    lockpick = nil
  end
  
  if lock ~= nil then
    lock:remove()
    lock = nil
  end
  
  if lockCase ~= nil then
    lockCase:remove()
    lockCase = nil
  end
  
  current_lockable = nil
  lockOrProbe = nil
end

local function lockTooComplex(actor,lockLevel,pickQuality)
  local security = types.NPC.stats.skills.security(actor).modified
  local agility = types.NPC.stats.attributes.agility(actor).modified
  local luck = types.NPC.stats.attributes.luck(actor).modified
  local fatigueCurrent = types.NPC.stats.dynamic.fatigue(actor).current
  local fatigueBase = types.NPC.stats.dynamic.fatigue(actor).base
  local fatigueModifier = 0.75 + (0.5 * fatigueCurrent/fatigueBase)
  security = security + (agility/5) + (luck/10)
  local chance = (security * pickQuality * fatigueModifier) - lockLevel
  if chance < 0 then
    return true
  else
    return false
  end
end

local function checkLockpicks(actor,type,lockLevel)
  local autopicking = lockpickSettings:get('autopicking')
  --print("AUTOPICK:",autopicking)
  if autopicking then
    local inventory = types.Actor.inventory(actor)
    if type == "Lock" then
      local bestLockpick = nil
      local allPicks = inventory:getAll(types.Lockpick)
      for _,pick in pairs(allPicks) do
        if bestLockpick == nil then
          bestLockpick = pick
        else
          if types.Lockpick.record(pick).quality > types.Lockpick.record(bestLockpick).quality then
            bestLockpick = pick
          end
        end
      end
      
      if bestLockpick == nil then
        actor:sendEvent("ShowMessage",{message="You have no lockpicks."})
        actor:sendEvent("SL_NoLockpicks")
        return false
      end
      
      local checkComplexity = lockpickSettings:get('lockTooComplex')
      if checkComplexity then
        if lockTooComplex(actor,lockLevel,types.Lockpick.record(bestLockpick).quality) then
          actor:sendEvent("ShowMessage",{message="Lock too complex."})
          return false
        end
      end
      
      if bestLockpick.count > 1 then
        bestLockpick = bestLockpick:split(1)
      end
      
      lockpick = bestLockpick
      --print("Set lockpick to:",bestLockpick.recordId)
      --print("Amount:",bestLockpick.count)
      return true
    elseif type == "Probe" then
      local bestProbe = nil
      local allProbes = inventory:getAll(types.Probe)
      for _,pick in pairs(allProbes) do
        if bestProbe == nil then
          bestProbe = pick
        else
          if types.Probe.record(pick).quality > types.Probe.record(bestProbe).quality then
            bestProbe = pick
          end
        end
      end
      
      if bestProbe == nil then
        actor:sendEvent("ShowMessage",{message="You have no probes."})
        actor:sendEvent("SL_NoLockpicks")
        return false
      end
      
      if bestProbe.count > 1 then
        bestProbe= bestProbe:split(1)
      end
      
      lockpick = bestProbe
      --print("Set probe to:",bestProbe.recordId)
      --print("Amount:",bestProbe.count)
      return true
      
      end
  else
    local weapon = types.Actor.getEquipment(actor,types.Actor.EQUIPMENT_SLOT.CarriedRight)
    if weapon == nil then
      actor:sendEvent("SL_NoLockpicks")
      return false
    end
    --print("Carrying:",weapon)
    if type == "Lock" then
      if weapon.type == types.Lockpick then
        local checkComplexity = lockpickSettings:get('lockTooComplex')
        if checkComplexity then
          if lockTooComplex(actor,lockLevel,types.Lockpick.record(weapon).quality) then
            actor:sendEvent("ShowMessage",{message="Lock too complex."})
            return false
          end
        end
        
        lockpick = weapon
        return true
      else
        return false
      end
    elseif type == "Probe" then
      if weapon.type == types.Probe then
        lockpick = weapon
        return true
      else
        return false
      end
    end
  end
end

local function trapCost(trap)
  --print(trap.id)
  local spell = core.magic.spells.records[trap.id]
  local mult = core.getGMST('fEffectCostMult')
  local y = 0
  for id,effect in ipairs(spell.effects) do
    local x = 0.5 * (math.max(1,effect.magnitudeMin) + math.max(1,effect.magnitudeMax))
    x = x * 0.1 * effect.effect.baseCost
    x = x + 0.05 * math.max(1,effect.area) * effect.effect.baseCost
    
    y = y + x * mult
    y = math.max(1,y)
    if effect.range == core.magic.RANGE.Target then
      x = x*1.5
    end
  end
  local cost = math.ceil(y)
  -- clamp it?
  cost = math.min(cost,100)
  --print("SPELL COST",cost)
  return cost
end

local function handleLock(object,actor)

  if actor.type ~= types.Player then return end
  
  if overriding then return end

  local isLocked = types.Lockable.isLocked(object)
  local lockLevel = types.Lockable.getLockLevel(object)
  local trapSpell = types.Lockable.getTrapSpell(object)
  --print("IS locked:",isLocked)
  --print("Lock level:",lockLevel)
  --print("Trap spell:",trapSpell)
  
  local lockEnabled = lockpickSettings:get('toggleLockpick')
  local probeEnabled = lockpickSettings:get('toggleProbe')
  
  if isLocked and lockEnabled then
    lockOrProbe = "Lock"
    if not checkLockpicks(actor,lockOrProbe,lockLevel) then return end
    actor:sendEvent("SL_StartLockpicking",{diff = lockLevel,quality=types.Lockpick.record(lockpick).quality,type=lockOrProbe})
    local crime = I.Crimes.commitCrime(actor,{type=4})
    current_lockable = object
    return false
  elseif trapSpell ~= nil and probeEnabled then
    lockOrProbe = "Probe"
    if not checkLockpicks(actor,lockOrProbe) then return end
    local diff = trapCost(trapSpell)
    actor:sendEvent("SL_StartLockpicking",{diff = diff,quality=types.Probe.record(lockpick).quality,type=lockOrProbe})
    local crime = I.Crimes.commitCrime(actor,{type=4})
    current_lockable = object
    return false
  end
end

local function lockpickDamaged()
  local damageAmount = lockpickSettings:get('damageAmount')
  local cond = types.Item.itemData(lockpick).condition
  if damageAmount > cond then damageAmount = cond end
  types.Item.itemData(lockpick).condition = cond - damageAmount
  if cond-damageAmount < 1 then
    --print("Lockpick broke")
    oldLockpick = lockpick
--    handleLock(current_lockable,world.players[1])
    checkLockpicks(world.players[1],lockOrProbe)
  end
end

local function lockpickSuccess()
  if lockOrProbe == "Lock" then
    types.Lockable.unlock(current_lockable)
  elseif lockOrProbe == "Probe" then
    types.Lockable.setTrapSpell(current_lockable,nil)
  end
  current_lockable = nil
end

local function updateOverride(data)
  overriding = data.override
end

I.Activation.addHandlerForType(types.Door,handleLock)
I.Activation.addHandlerForType(types.Container,handleLock)

return {
  eventHandlers = {
    SL_SpawnPick = spawnPick,
    SL_RemovePick = removePick,
    SL_SpawnLock = spawnLock,
    SL_RotateLock = rotateLock,
    SL_Shake = shakeLockpick,
    SL_LockpickSuccess = lockpickSuccess,
    SL_LockpickDamaged = lockpickDamaged,
    SL_UpdateOverrideStatus = updateOverride,
  },
}