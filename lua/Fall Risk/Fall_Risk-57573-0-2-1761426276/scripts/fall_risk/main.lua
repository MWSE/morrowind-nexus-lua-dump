-- Fall Risk — main.lua (v0.5, version unifiée storage-only)
local uiMod   = require('scripts.fall_risk.ui')
local sets    = require('scripts.fall_risk.settings_access')
local config  = require('scripts.fall_risk.config')

local util    = require('openmw.util')
local input   = require('openmw.input')
local camera  = require('openmw.camera')
local nearby  = require('openmw.nearby')
local types   = require('openmw.types')
local self    = require('openmw.self')

local LOGP = '[FallRisk/Main] '

local S = {
  sticky = false,
  prevToggle = false,
}

------------------------------------------------------------
-- Calcul du risque de chute
------------------------------------------------------------
local function computeRisk()
  local eyePos = camera.getPosition()
  local dir    = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
  if not (eyePos and dir) then return nil end

  local selfPos = self and self.position
  if not selfPos then return nil end

  local to  = eyePos + dir * (config.DEFAULTS.maxRayLen or 8000)
  local res = nearby.castRay(eyePos, to, { ignore = self })
  if not (res and res.hit and res.hitPos) then return nil end

  local feetZ   = selfPos.z
  local groundZ = res.hitPos.z
  local fallH   = math.max(0, feetZ - groundZ)

  local ATH, ACR, INT = 0, 0, 0
  if types.NPC and types.NPC.stats then
    local ok1, v1 = pcall(function() return types.NPC.stats.skills.athletics(self).modified end)
    if ok1 then ATH = v1 end
    local ok2, v2 = pcall(function() return types.NPC.stats.skills.acrobatics(self).modified end)
    if ok2 then ACR = v2 end
    local ok3, v3 = pcall(function() return types.NPC.stats.attributes.intelligence(self).modified end)
    if ok3 then INT = v3 end
  end

  local hSafe  = 100 + ACR * 2 + ATH * 0.5
  local hFatal = hSafe + 600

  local risk = (fallH <= hSafe) and 0 or (fallH >= hFatal) and 1 or (fallH - hSafe) / (hFatal - hSafe)
  local gamma = config.DEFAULTS.riskCurveGamma
  if gamma and gamma > 0 then risk = risk ^ (1 / gamma) end

  local confRaw = (INT + ACR) / 150.0
  local confidence = 0.15 + 0.85 * math.min(1, math.max(0, confRaw)) ^ 2

  return { risk = risk, conf = confidence }
end

------------------------------------------------------------
-- Logique HUD (touches + regard)
------------------------------------------------------------
local function visibleWanted()
  local hold = input.getBooleanActionValue('FR_Hold')

  local dir2     = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
  local forwardZ = (dir2 and dir2.z) or 0

  -- HOLD
  if hold then
    if sets.currentGateHold() then
      local gateZH = sets.currentLookDownZ()
      return forwardZ < gateZH
    else
      return true
    end
  end

end



------------------------------------------------------------
-- Tick principal
------------------------------------------------------------
local function onUpdate(dt)

  local want = visibleWanted()
  uiMod.setVisible(want)
  if not want then return end

    -- Relecture dynamique et application des settings
  local tex = sets.currentTexture()
  local pal = sets.currentPalette()
  uiMod.ensureUi(
    tex.path,
    tex.size,
    config.DEFAULTS.insetPx,
    config.DEFAULTS.hudLayerName
  )
  if pal.colors then uiMod.setPalette(pal.colors) end

  local result = computeRisk()
  if result then uiMod.setRisk(result.risk or 0, result.conf or 1) end
end

------------------------------------------------------------
-- Retour principal (handlers)
------------------------------------------------------------
return {
  engineHandlers = {

    onLoad = function(data)
      S.sticky = data and data.sticky or false
    end,

    onUpdate = onUpdate,

    onSave = function()
      return { sticky = S.sticky }
    end,
  }
}
