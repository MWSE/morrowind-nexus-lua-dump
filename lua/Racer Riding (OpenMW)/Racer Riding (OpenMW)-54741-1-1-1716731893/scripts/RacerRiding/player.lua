local self = require("openmw.self")
local async = require("openmw.async")
local nearby = require("openmw.nearby")
local util = require("openmw.util")
local core = require("openmw.core")
local input = require("openmw.input")
local camera = require("openmw.camera")
local types = require("openmw.types")
local storage = require("openmw.storage")
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local trans = util.transform

---@class openmw.interfaces.interfaces
---@field RacerRiding RacerRiding.Interface

---@type openmw.core.GameObject?
local racer
local scale
local autoMove = false
local cameraMode
local inCombat

local diseaseTimer = 0
local showInterface = false
local yawCorrector = nil
local pitchCorrector = nil

I.Settings.registerPage {
  key = "RacerRidingPage",
  l10n = "RacerRiding",
  name = "Racer Riding",
}

I.Settings.registerGroup {
  key = "SettingsRacerRidingCamera",
  page = "RacerRidingPage",
  l10n = "RacerRiding",
  name = "Camera",
  permanentStorage = true,
  settings = {
    {
      key = "InvertX",
      renderer = "checkbox",
      name = "InvertX",
      default = false,
    },
    {
      key = "InvertY",
      renderer = "checkbox",
      name = "InvertY",
      default = false,
    },
  }
}

I.Settings.registerGroup {
  key = "SettingsRacerRidingGameplay",
  page = "RacerRidingPage",
  l10n = "RacerRiding",
  name = "Gameplay",
  permanentStorage = true,
  settings = {
    {
      key = "DiseaseContactInterval",
      renderer = "number",
      name = "DiseaseContactInterval",
      description = "DiseaseContactIntervalDescription",
      default = 1,
      argument = { min = 0 }
    },
  }
}

local cameraSettings = storage.playerSection("SettingsRacerRidingCamera")
local invertX, invertY
local function updateCameraSettings()
  invertX, invertY = cameraSettings:get('InvertX'), cameraSettings:get('InvertY')
end
updateCameraSettings()
cameraSettings:subscribe(async:callback(updateCameraSettings))

local gameplaySettings = storage.playerSection("SettingsRacerRidingGameplay")
local diseaseContactInterval
local function updateGameplaySettings()
  diseaseContactInterval = gameplaySettings:get('DiseaseContactInterval')
end
updateGameplaySettings()
gameplaySettings:subscribe(async:callback(updateGameplaySettings))


local function setControls(val)
  types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Fighting, val)
  types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Jumping, val)
  types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Magic, val)
  types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.VanityMode, val)
  types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.ViewMode, val)
  types.Player.setControlSwitch(self, types.Player.CONTROL_SWITCH.Controls, val)
end

local function createCorrector(correction)
  return {
    apply = function(corrector, angle, dt)
      local change = math.max(0.2, math.abs(correction)) * 6 * dt
      if correction < 0 then change = -change end

      if math.max(0.001, math.abs(change)) >= math.abs(correction) then
        return angle + correction, nil
      else
        correction = correction - change
        return angle + change, corrector
      end
    end
  }
end

local function startRiding(cliffRacer)
  racer = cliffRacer
  scale = self.scale

  racer:sendEvent("RacerRidingStart")
  core.sendGlobalEvent("RacerRidingStart", { racer = racer, player = self })
  setControls(false)
  cameraMode = camera.getMode()

  types.Actor.activeEffects(self):modify(1, "invisibility")
  types.Actor.activeEffects(self):modify(1, "levitate")
end

local function stopRiding()
  if racer then
    types.Actor.activeEffects(self):modify(-1, "invisibility")
    types.Actor.activeEffects(self):modify(-1, "levitate")

    racer:sendEvent("RacerRidingStop")
    local z, x = camera.getYaw(), camera.getPitch()
    core.sendGlobalEvent("RacerRidingStop", { racer = racer, player = self, scale = scale, position = camera.getPosition(), rotation = trans.rotateZ(z) * trans.rotateX(x) })
    racer = nil
    setControls(true)
    camera.setMode(cameraMode)
    camera.showCrosshair(true)

    diseaseTimer = 0
  end
end

local function startCombat(target)
  if racer then
    racer:sendEvent("StartAIPackage", { type = "Combat", target = target })
    inCombat = target
  end
end

local function stopCombat()
  if racer then
    racer:sendEvent("RemoveAIPackages", "Combat")
    if not yawCorrector then
      yawCorrector = createCorrector(util.normalizeAngle(camera:getYaw() - racer.rotation:getYaw()))
    end
    if not pitchCorrector then
      pitchCorrector = createCorrector(util.normalizeAngle(camera:getPitch() - racer.rotation:getPitch()))
    end
  end
  inCombat = nil
end

input.registerTriggerHandler("AutoMove", async:callback(function()
  if racer then
    autoMove = not autoMove
  end
end))

input.registerTriggerHandler("Jump", async:callback(function()
  if racer then
    stopRiding()
  end
end))

input.registerActionHandler("Use", async:callback(function (pressed)
  if racer then
    if I.UI.getMode() then
      return
    end
    camera.showCrosshair(pressed)
    if not pressed then
      local from = camera.getPosition()
      local to = trans.move(from) * trans.rotateZ(camera.getYaw()) * trans.rotateX(camera.getPitch()) * util.vector3(0, 10000, 0)
      local res = nearby.castRay(from, to, { collisionType = nearby.COLLISION_TYPE.Actor, ignore = racer })
      if res.hit and res.hitObject and not types.Actor.isDead(res.hitObject) then
        startCombat(res.hitObject)
      else
        stopCombat()
      end
    else
    end
  end
end))

input.registerTriggerHandler("Inventory", async:callback(function()
  if racer then
    if showInterface then I.UI.removeMode("Interface") else I.UI.addMode("Interface") end
    showInterface = not showInterface
  end
end))

input.registerActionHandler("TogglePOV", async:callback(function(value)
  if racer and not inCombat then
    if value then
      yawCorrector = nil
      pitchCorrector = nil
    else
      yawCorrector = createCorrector(util.normalizeAngle(camera:getYaw() - racer.rotation:getYaw()))
      pitchCorrector = createCorrector(util.normalizeAngle(camera:getPitch() - racer.rotation:getPitch()))
    end
  end
end))

local function diseaseContact(actor)
  -- Apply contact with each disease the cliff racer has
  for _, spell in pairs(types.Actor.spells(actor)) do
    if (spell.type == core.magic.SPELL_TYPE.Disease or spell.type == core.magic.SPELL_TYPE.Blight) and not types.Actor.spells(self)[spell.id] then
      local diseaseXferChance = core.getGMST("fDiseaseXferChance")

      local activeEffects = types.Actor.activeEffects(self)
      local disease = core.magic.spells.records[spell.id]
      local resistMag = activeEffects:getEffect(disease.type == core.magic.SPELL_TYPE.Disease and core.magic.EFFECT_TYPE.ResistCommonDisease or core.magic.EFFECT_TYPE.ResistBlightDisease).magnitude
      local weaknessMag = activeEffects:getEffect(disease.type == core.magic.SPELL_TYPE.Disease and core.magic.EFFECT_TYPE.WeaknessToCommonDisease or core.magic.EFFECT_TYPE.WeaknessToBlightDisease).magnitude
      local resist = 1.0 - (0.01 * (resistMag - weaknessMag))
      local x = math.floor(diseaseXferChance * 100 * resist)
      if math.random(0, 9999) < x then
        ui.showMessage(string.format(core.getGMST("sMagicContractDisease"), disease.name))
        types.Actor.spells(self):add(disease.id)
      end
    end
  end
end

local rideable = {
  ["cliff racer"] = true,
  ["cliff racer_blighted"] = true,
  ["cliff racer_diseased"] = true,
  ["racerridingjockeyracer"] = true,
}

return {
  engineHandlers = {
    onUpdate = function(dt)
      if racer then
        if I.UI.getMode() then
          return
        end

        if types.Actor.isDead(racer) then
          stopRiding()
          return
        end

        if camera.getMode() ~= camera.MODE.Static then
          camera.setMode(camera.MODE.Static, true)
          camera.setYaw(racer.rotation:getYaw())
          camera.setPitch(racer.rotation:getPitch())
          camera.showCrosshair(false)
        end

        if diseaseContactInterval > 0 then
          diseaseTimer = diseaseTimer + dt
          if diseaseTimer >= diseaseContactInterval then
            diseaseContact(racer)
            diseaseTimer = 0
          end
        end

        self.controls.yawChange = self.controls.yawChange * (invertX and -1 or 1)
        self.controls.pitchChange = self.controls.pitchChange * (invertY and -1 or 1)

        local position = I.RacerRiding.getCameraPosition(racer)
        camera.setStaticPosition(position)
        camera.setYaw(camera.getYaw() + self.controls.yawChange)
        camera.setPitch(camera.getPitch() + self.controls.pitchChange)

        local movement = input.getRangeActionValue("MoveForward") ~= 0 and 1 or input.getRangeActionValue("MoveBackward") ~= 0 and -1 or 0
        local sideMovement = input.getRangeActionValue("MoveRight") ~= 0 and 1 or input.getRangeActionValue("MoveLeft") ~= 0 and -1 or 0

        -- Disable auto move if the player manually moves again
        autoMove = autoMove and movement == 0
        movement = autoMove and 1 or movement

        local togglepov = input.getBooleanActionValue('TogglePOV')

        local yawChange = togglepov and 0 or self.controls.yawChange
        local pitchChange = togglepov and 0 or self.controls.pitchChange

        if yawCorrector then
          yawChange, yawCorrector = yawCorrector:apply(yawChange, dt)
        end

        if pitchCorrector then
          pitchChange, pitchCorrector = pitchCorrector:apply(pitchChange, dt)
        end

        racer:sendEvent("RacerRidingControl", { yawChange = yawChange, pitchChange = pitchChange, movement = movement, sideMovement = sideMovement, inCombat = inCombat, player = self })
        core.sendGlobalEvent("RacerRidingTeleport", { racer = racer, player = self })
      end
    end,
    onSave = function()
      return {
        racer = racer,
        cameraMode = cameraMode,
        scale = scale,
        autoMove = autoMove,
        inCombat = inCombat
      }
    end,
    onLoad = function(data)
      if not data then
        return
      end

      racer = data.racer
      cameraMode = data.cameraMode
      scale = data.scale
      autoMove = data.autoMove
      if racer then
        core.sendGlobalEvent("RacerRidingStart", { racer = racer, player = self })
        racer:sendEvent("RacerRidingStart")
        if data.inCombat then
          startCombat(data.inCombat)
        end
      end
    end,
  },
  eventHandlers = {
    RacerRidingTargetDead = function()
      stopCombat()
    end,
    RacerRidingActivated = function(data)
      if not racer and not types.Actor.isDead(data.racer) and I.RacerRiding.canRide(data.racer) then
        startRiding(data.racer)
      end
    end
  },
  interfaceName = "RacerRiding",
  ---@class RacerRiding.Interface
  interface = {
    version = 1,
    canRide = function(actor)
      return rideable[actor.recordId]
    end,
    getCameraPosition = function(actor)
      return trans.move(actor.position) * trans.rotateZ(camera:getYaw()) * trans.move(0, -105, 0) * trans.rotateX(camera.getPitch() * 0.25) * util.vector3(0, 0, 430)
    end,
    setRideable = function(recordId, v)
      rideable[recordId] = v or nil
    end
  },
}
