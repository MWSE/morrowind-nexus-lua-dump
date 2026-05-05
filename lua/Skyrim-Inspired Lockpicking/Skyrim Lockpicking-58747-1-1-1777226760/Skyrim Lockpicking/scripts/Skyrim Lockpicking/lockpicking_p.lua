local core = require('openmw.core')
local self = require('openmw.self')
local camera = require('openmw.camera')
local util = require('openmw.util')
local types = require('openmw.types')
local ui = require('openmw.ui')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local async = require('openmw.async')
local ambient = require('openmw.ambient')
local storage = require('openmw.storage')

I.Settings.registerPage({
    key = 'SkyrimLockpicking',
    l10n = 'SkyrimLockpicking',
    name = 'Skyrim-Style Lockpicking',
    description = "",
})

input.registerAction{
  key = "SkyrimLockpickingOverrideButton",
  l10n = "OverrideLockpicking",
  name = "",
  description = "",
  defaultValue = false,
}

local overriding = false

input.registerActionHandler("SkyrimLockpickingOverrideButton",async:callback(
function(key)
   --print(key)
   if overriding ~= key then
    core.sendGlobalEvent("SL_UpdateOverrideStatus",{override=key})
    overriding = key
   end
end))

local lockpickSettings = storage.globalSection('SettingsSkyrimLockpicking')

local v2 = util.vector2
local screenSize = ui.layers[ui.layers.indexOf("Windows")].size
local overlay_element = nil
local LOCKPICKING = false
local TURNING = false
local pickQuality = nil
local lockDiff = nil
local placedLock = false
local shakeTimer = 0
local timeToBreak = nil
local lastAngle = nil
local lastSound = nil
local lockType = nil

-- in radians
local baseTurnSpeed = 1.0471975512 * 1.7
local lockAngle = 0

local overlay = {
  type = ui.TYPE.Widget,
  layer = "Windows",
  props = {
    relativeSize = v2(1,1),
  },
}

local function deleteLockpicking()
  if overlay_element then
    overlay_element:destroy()
    overlay_element = nil
    LOCKPICKING = false
    TURNING = false
    placedLock = false
    shakeTimer = 0
    lockAngle = 0
    pickQuality = nil
    lockDiff = nil
    lockType = nil
    if ambient.isSoundFilePlaying(lastSound) then
      ambient.stopSoundFile(lastSound)
    end
  end
    core.sendGlobalEvent("SL_RemovePick")
end
local function uiChange(data)
  if data.oldMode == 'Interface' then
    deleteLockpicking()
  end
end

local function removeUi()
  deleteLockpicking()
  async:newUnsavableSimulationTimer(0.25,
  function()
    I.UI.removeMode(I.UI.MODE.Interface)
  end
  )
end

local sweetAngle = nil

local function getLockpickAngles(diff)
  --print("Difficulty:",diff)
  local security = types.NPC.stats.skills.security(self).modified
  local agility = types.NPC.stats.attributes.agility(self).modified
  local luck = types.NPC.stats.attributes.luck(self).modified
  local fatigueCurrent = types.NPC.stats.dynamic.fatigue(self).current
  local fatigueBase = types.NPC.stats.dynamic.fatigue(self).base
  local fatigueModifier = 0.75 + (0.5 * fatigueCurrent/fatigueBase)
  security = security + (agility/5) + (luck/10)
  security = security * fatigueModifier
  --print("Player security:",security)
  
  local norm = (diff - 1)/99
  local oldDiff = 1 + 4 * norm
  
  local sweetspot = 60 * (2^(-oldDiff)) * (0.82 + 0.6 * (security/100))
  local partialspot = (24-4*oldDiff) * (0.75 + 1.5 * (security/100))
  local sMult = lockpickSettings:get('SweetspotMultiplier')
  local pMult = lockpickSettings:get('PartialSpotMultiplier')
  sweetspot = sweetspot * sMult
  partialspot = partialspot * pMult
  --print("Sweetspot angle :",sweetspot)
  --print("Partial spot angle: ",partialspot)
  sweetspot = math.rad(sweetspot)
  partialspot = math.rad(partialspot)
  return sweetspot,partialspot
end

local function initAngle()
  local point = math.random() * math.pi
  --print("Center of sweetspot:",point)
  sweetAngle = point
end

local function checkAngle(angle)
  
  if angle == nil then return 0 end

  local maxTurn = math.pi/2
  local turn = 0
  
  --print("Current angle:",angle)
  --print("Sweetspot angle:",sweetAngle)
  local sweetspot,partialspot = getLockpickAngles(lockDiff)
  local distance = math.abs(angle-sweetAngle)
  --print("Distance from sweetspot:",distance)
  if distance <= sweetspot/2 then
    --print("Lockpick is within the sweetspot")
    turn = maxTurn
  elseif distance <= sweetspot/2 + partialspot then
    --print("Lockpick is within the partialspot")
    --Calculate how much it can turn
    local excess = distance - (sweetspot/2)
    local t = 1 - (excess / partialspot)
    --print("Can turn:",maxTurn*t)
    turn = maxTurn*t
  else
    --print("Lockpick is out of any spot")
  end
  return turn
end

local function getTimeToBreak(diff,quality)
  local baseTime = 2.0 - (diff - 1) * ( (2.0 - 0.25) / 99 )
  local security = types.NPC.stats.skills.security(self).modified
  local levelMult = 1.0 + (security / 100) * 0.5
  local mult = lockpickSettings:get('ttbMultiplier')
  return baseTime * levelMult * quality * mult
end

local function lockpickPosition(mousePos)
  local cameraPos = camera.getPosition()
  local lookVec = camera.viewportToWorldVector(util.vector2(0.5,0.5)):normalize()
  local startPos = cameraPos + lookVec * 20
  local offsetPos = cameraPos + lookVec * 13
  
  local right = lookVec:cross(util.vector3(0,0,1)):normalize()
  local up = right:cross(lookVec):normalize()
  local radius = 3

  local mouseDir = mousePos - v2(screenSize.x*0.5,screenSize.y*0.5)
  local camDir = (right*mouseDir.x+up*-mouseDir.y):normalize()
  local angle = math.atan2(camDir:dot(up),camDir:dot(right))
  
  if lastAngle ~= nil then
    if angle >= math.pi or angle <= 0 then
      angle = lastAngle
    end
  end
  lastAngle = angle
  
  local offset = right * math.cos(angle) * radius + up * math.sin(angle) * radius
  
  local spawnPos = offsetPos + offset
  local forward = util.vector3(0,1,0)
  local toCenter = (startPos - spawnPos):normalize()
  local axis = forward:cross(toCenter)
  local dot = forward:dot(toCenter)
  if dot > 1 then
    dot = 1
  elseif dot < -1 then
      dot = -1
  end
  local pickAngle = math.acos(dot)
  local rotation = util.transform.rotate(pickAngle,axis)
  rotation = rotation * util.transform.rotateY(angle - math.pi)
  local transform = util.transform.move(spawnPos) * rotation --util.transform.rotate(pickAngle,axis)
  
  return {pos=spawnPos,rot=transform,angle=angle}
end

local function getTransform(angle)
  local transform = self.rotation * util.transform.rotateZ(math.pi/2)
  if angle ~= nil then
    transform = transform * util.transform.rotateX(angle)
  end
  return transform
end

local function lockPosition()
  local cameraPos = camera.getPosition()
  local lookVec = camera.viewportToWorldVector(util.vector2(0.5,0.5)):normalize()
  local startPos = cameraPos + lookVec * 20
  local transform = getTransform()
  return {pos=startPos,rot=transform}
end

local function initLockpicking(mousePos)
  if not TURNING then
    local lockpick = lockpickPosition(mousePos)
    core.sendGlobalEvent('SL_SpawnPick',{cell=self.cell.name,pos=lockpick.pos,rot=lockpick.rot})
    
    if lastSound == nil or not ambient.isSoundFilePlaying(lastSound) then
       local str = "s"..math.random(1,4)
      str = "Sound/lockpicking/"..str..".wav"
      ambient.playSoundFile(str,{volume = 0.5})
      lastSound = str
    end
  end
  
  if not placedLock then
    local lock = lockPosition()
    core.sendGlobalEvent('SL_SpawnLock',{cell=self.cell.name,pos=lock.pos,rot=lock.rot})
    placedLock = true
  end
end

local function mouseMove(mouse)
  initLockpicking(mouse.position)
end

local function keyPress(key)
  if overlay_element == nil then return end
  if key == 1 then TURNING = true else TURNING = false end
end

local function startLockpicking(data)
  initAngle()
  pickQuality = data.quality
  lockType = data.type
  local mult = lockpickSettings:get('DifficultyMultiplier')
  lockDiff = data.diff * mult
  timeToBreak = getTimeToBreak(data.diff,data.quality)
  --print("Time to break:",timeToBreak)
  I.UI.addMode(I.UI.MODE.Interface,{windows={}})
  overlay_element = ui.create(overlay)
  LOCKPICKING = true
  initLockpicking(v2(0,0))
end

local function lockpickSuccess()
  --print("LOCKPICK SUCCESS")
  ambient.playSoundFile("Sound/Fx/trans/chain_pul2.wav")
  core.sendGlobalEvent('Unpause', 'ui')
  core.sendGlobalEvent('SL_LockpickSuccess')
  
  local skillGain = 2
  local useType = I.SkillProgression.SKILL_USE_TYPES.Security_PickLock
  
  --print("lock type:",lockType)
  if lockType == "Probe" then
    skillGain = 3
    useType = I.SkillProgression.SKILL_USE_TYPES.Security_DisarmTrap
  end
  
  local scaling = lockpickSettings:get('scaledXpGain')
  local moreXp = lockpickSettings:get('scaledXpGainMult')
  --print(scaling)
  if scaling then
    local security = types.NPC.stats.skills.security(self).modified
    local dif = lockDiff - security
    if dif > 0 then
      --print("Hrader lock, adding:",dif*0.25)
      skillGain = skillGain + (dif * 0.25)
    end
    skillGain = skillGain * moreXp
  end
  
  --print("Skill gain:",skillGain)
  
  I.SkillProgression.skillUsed("security", {skillGain=skillGain,useType=useType})
  
--  deleteLockpicking()
--  async:newUnsavableSimulationTimer(0.5,
--  function()
--    I.UI.removeMode(I.UI.MODE.Interface)
--  end
--  )
  removeUi()
end

overlay.events = {
    mouseMove = async:callback(mouseMove),
}

local delta = nil

local function onUpdate()
  if not LOCKPICKING then return end
  if TURNING then
    --print("TURNING:",TURNING)
    local maxTurn = checkAngle(lastAngle)
    --print("MAX TURN:",maxTurn)
    if delta ~= nil then
      local dt = core.getRealTime() - delta
      lockAngle = lockAngle + baseTurnSpeed*dt
      --print("LOCK ANGLE:",lockAngle)
      if lockAngle >= math.pi/2 then
        --print("UNLOCKED")
        lockpickSuccess()
      elseif lockAngle > maxTurn then
        core.sendGlobalEvent("SL_Shake")
        shakeTimer = shakeTimer + dt
        --print("SHAKING")
        if not ambient.isSoundFilePlaying("Sound/lockpicking/rattle1.wav") then
          ambient.playSoundFile("Sound/lockpicking/rattle1.wav",{volume = 0.5})
        end
        --print("Shake timer:",shakeTimer)
        if shakeTimer > timeToBreak then
          ui.showMessage("Lockpick damaged")
          core.sendGlobalEvent("SL_LockpickDamaged")
          ambient.stopSoundFile("Sound/lockpicking/rattle1.wav")
          ambient.playSoundFile("Sound/Fx/trans/contnr_lokd.wav")
          shakeTimer = 0
        end
      end
      lockAngle = math.min(lockAngle,maxTurn)
      core.sendGlobalEvent("SL_RotateLock",{tf=getTransform(lockAngle)})
      --print("LOCK ANGLE:",lockAngle)
    end
  else
    ambient.stopSoundFile("Sound/lockpicking/rattle1.wav")
    if lockAngle > 0 then
      if delta ~= nil then
        local dt = core.getRealTime() - delta
        lockAngle = lockAngle - baseTurnSpeed*dt
        lockAngle = math.max(0,lockAngle)
        core.sendGlobalEvent("SL_RotateLock",{tf=getTransform(lockAngle)})
      end
    end
  end
  
  delta = core.getRealTime()
end

local function noLockpicks()
  core.sendGlobalEvent('Unpause', 'ui')
  removeUi()
end
input.registerActionHandler("MoveRight",async:callback(keyPress))

local function reEquip(data)
  local eq = types.Actor.getEquipment(self)
  eq[types.Actor.EQUIPMENT_SLOT.CarriedRight]=data.obj
  types.Actor.setEquipment(self,eq)
end

return {
  eventHandlers = {
    UiModeChanged = uiChange,
    SL_StartLockpicking = startLockpicking,
    SL_NoLockpicks = noLockpicks,
    SL_ReEquipLockpick = reEquip,
  },
  engineHandlers = {
    onKeyRelease = keyRelease,
    onUpdate = onUpdate,
  }
}