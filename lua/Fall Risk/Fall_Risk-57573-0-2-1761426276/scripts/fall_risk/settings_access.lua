-- fall_risk/settings_access.lua — v0.5 (lecture directe storage)
local storage   = require('openmw.storage')
local config    = require('scripts.fall_risk.config')
local palettes  = require('scripts.fall_risk.palettes')

local GROUP = 'SettingsFallRisk'

local M = {}

-- Lecture directe depuis storage ou valeurs par défaut
function M.get(key)
  local okSec, sec = pcall(storage.playerSection, GROUP)
  if okSec and sec then
    local okVal, val = pcall(function() return sec:get(key) end)
    if okVal and val ~= nil then
      return val
    end
  end

  -- Valeurs par défaut
  if key == 'TextureSize'        then return config.DEFAULTS.textureSizeKey end
  if key == 'Palette'            then return config.DEFAULTS.paletteKey end
  if key == 'GateHoldNoLookDown' then return config.DEFAULTS.holdUsesGate end
  if key == 'LookDownThreshold'  then return config.DEFAULTS.lookDownDeg end
  return nil
end

function M.currentTexture()
  local key = M.get('TextureSize')
  local t = config.RING_TEXTURES[key] or config.RING_TEXTURES[config.DEFAULTS.textureSizeKey]
  return { key = key, path = t.path, size = t.size }
end

function M.currentPalette()
  local key = M.get('Palette')
  local p = palettes[key] or palettes[config.DEFAULTS.paletteKey]
  return { key = key, colors = p }
end

-- Si le maintien exige le regard vers le bas
function M.currentGateHold()
  return M.get('HoldRequireLookDown') and true or false
end

-- Seuil Z du regard vers le bas
function M.currentLookDownZ()
  local deg = M.get('HoldLookDownThreshold')
  return config.degToZThreshold(deg)
end

return M
