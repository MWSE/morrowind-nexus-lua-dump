-- fall_risk/config.lua — v0.2 (strict-necessaire)
local M = {}

-- IDs des actions
M.BIND = {
  Hold   = 'FR_Hold',
  Toggle = 'FR_Toggle',
}

-- Textures disponibles (mappées par Settings.TextureSize)
M.RING_TEXTURES = {
  ring64  = { path = 'textures/fall_risk_ring_white_64.png',  size = 64  },
  ring128 = { path = 'textures/fall_risk_ring_white_128.png', size = 128 },
}

-- Valeurs par défaut utilisées au boot et en fallback
M.DEFAULTS = {
  textureSizeKey = 'ring128',  -- 'ring64' | 'ring128'
  paletteKey     = 'default',  -- 'default' | 'alt'
  hudLayerName   = 'HUD',
  insetPx        = 8,
  riskCurveGamma = 2.2,
  maxRayLen      = 8000,

  -- Logique d’affichage
  holdUsesGate   = true,  -- en maintien, exige regard vers le bas si true
  lookDownDeg    = -10,   -- degrés (négatif = regarder vers le bas)
}

-- seuil dir.z à partir d’un angle en degrés (négatif vers le bas)
function M.degToZThreshold(deg)
  return math.sin(math.rad(deg or -10))
end

return M
