--[[
CZ Fall Risk — OpenMW 0.49 (UI ring)
- Conteneur valide: ui.TYPE.Widget
- Image modulée via 'color'
- Aucune API non documentée
- K = maintenir pour afficher
- L = toggle (collant)
]]

local ui     = require('openmw.ui')
local util   = require('openmw.util')
local async  = require('openmw.async')
local core   = require('openmw.core')
local input  = require('openmw.input')
local camera = require('openmw.camera')
local nearby = require('openmw.nearby')
local self   = require('openmw.self')
local types  = require('openmw.types')

-----------------------------------------------------------------------
-- Config
-----------------------------------------------------------------------
local CFG = {
  -- PNG (fond transparent)
  texturePath    = 'textures/cz_ring_white_128.png',
  sizePx         = 128,
  insetPx        = 8,
  hudLayerName   = 'HUD',
  anchorCenter   = true,
  testForceOnce  = false,   -- on désactive le rouge forcé une frame
  lookDownThreshold = -0.15,  -- dir.z doit être < à ce seuil pour “regarder en bas”
  riskCurveGamma = 2.2,  -- >1 adoucit le passage au rouge (2.0–2.5 marche bien)

  keyHold        = input.KEY.K,  -- maintenir K => visible
  keyToggle      = input.KEY.L,  -- L => toggle

  -- Paramétrage danger (unités monde OpenMW)
  -- hSafe  : sous ce seuil ~0 risque
  -- hFatal : au-delà ~1 risque
  -- Les deux seuils sont rehaussés par l'Acrobatie (acroBoost par point)
  danger = {
    hSafeBase  = 192.0,
    hFatalBase = 1152.0,
    acroBoost  = 4.0,
    maxRayLen  = 50000.0,     -- portée max du ray (très large mais finie)
  },
}

-----------------------------------------------------------------------
-- Logging (tolérant suivant la build)
-----------------------------------------------------------------------
local PREFIX = '[CZ FR] '

local function logI(msg)
  if core and core.logInfo then core.logInfo(PREFIX .. msg) else print(PREFIX .. msg) end
end
local function logW(msg)
  if core and core.logWarning then core.logWarning(PREFIX .. msg) else print('WARN '..PREFIX .. msg) end
end
local function logE(msg)
  if core and core.logError then core.logError(PREFIX .. msg)
  elseif core and core.logWarning then core.logWarning('ERROR '..PREFIX .. msg)
  else print('ERROR '..PREFIX .. msg) end
end

-----------------------------------------------------------------------
-- State
-----------------------------------------------------------------------
local S = {
  root  = nil,   -- UiElement (Widget)
  image = nil,   -- UiElement (Image) -- (non utilisé mais conservé)

  holdDown = false,
  sticky   = false,
  kPrev    = false,
  lPrev    = false,

  testForced = false,

  -- Risque "réel"
  risk = nil,        -- 0..1 (nil = inconnu / pas encore calculé)
  confidence = 1.0,  -- 0..1

  -- Anti-log spam
  visiblePrev = nil,
}

local function isValid(el)
  return el ~= nil and el.update ~= nil
end

-----------------------------------------------------------------------
-- Couleur (risque 0..1)
-----------------------------------------------------------------------
local function ringColorForRisk(r)
  if r < 0 then r = 0 elseif r > 1 then r = 1 end
  -- Vert -> Jaune -> Rouge
  local g  = (r < 0.5) and 1 or (1 - (r - 0.5) * 2)
  local rc = (r < 0.5) and (r * 2) or 1
  local b  = 0.10
  return util.color.rgb(rc, g, b)
end

-----------------------------------------------------------------------
-- Template UI
-----------------------------------------------------------------------
local function buildLayout()
  local size  = CFG.sizePx
  local inner = size - CFG.insetPx * 2

  local props = {
    size = util.vector2(size, size),
  }
  if CFG.anchorCenter then
    props.relativePosition = util.vector2(0.5, 0.5)
    props.anchor = util.vector2(0.5, 0.5)
  end

  return {
    type = ui.TYPE.Widget,
    props = props,
    content = ui.content({
      {
        type = ui.TYPE.Image,
        props = {
          size = util.vector2(inner, inner),
          anchor = util.vector2(0.5, 0.5),
          relativePosition = util.vector2(0.5, 0.5),
          resource = ui.texture { path = CFG.texturePath },
          color = util.color.rgb(1, 1, 1),  -- modulé via applyRisk()/setRisk
        },
      },
    }),
  }
end

-----------------------------------------------------------------------
-- Application du risque (couleur + alpha)
-----------------------------------------------------------------------
local function applyRisk()
  if not isValid(S.root) or S.risk == nil then return end
  local c = ringColorForRisk(S.risk)                 -- rgb
  -- S.confidence est déjà un ratio [0..1]
  local a = math.max(0, math.min(1, S.confidence or 0))
  local l = S.root.layout
  local t = 1 - a      -- faible alpha => forte désaturation
  local r = c.r + (1 - c.r) * t
  local g = c.g + (1 - c.g) * t
  local b = c.b + (1 - c.b) * t
  l.content[1].props.color = util.color.rgba(r, g, b, a)
  S.root:update()
end

-----------------------------------------------------------------------
-- Création/ensure
-----------------------------------------------------------------------
local function ensureUi()
  if isValid(S.root) then return true end

  local ok, rootOrErr = pcall(function()
    local layout = buildLayout()
    layout.layer = CFG.hudLayerName
    layout.name  = 'cz_fall_risk_root'
    return ui.create(layout)
  end)

  if not ok or not rootOrErr then
    logE('Create UI a échoué: ' .. tostring(rootOrErr))
    return false
  end

  S.root = rootOrErr
  local layout = S.root.layout
  if not (layout and layout.content and layout.content[1]
      and layout.content[1].type == ui.TYPE.Image) then
    logE('Aucun enfant UI (image) trouvé')
    return false
  end

  if CFG.testForceOnce and not S.testForced then
    layout.content[1].props.color = util.color.rgb(1, 0, 0) -- rouge plein (validation teinte)
    S.root:update()
    S.testForced = true
    logW('TEST: ring forcé en ROUGE une fois (validation teinte).')
  else
    -- si un risque existe déjà, l’appliquer dès la création
    applyRisk()
  end

  logI('UI créée OK (root=Widget, image=Image).')
  return true
end

-----------------------------------------------------------------------
-- API interne
-----------------------------------------------------------------------
local function setVisible(v)
  if not ensureUi() then return end
  if S.visiblePrev ~= v then
    logI(('setVisible(%s) -> %s'):format(tostring(v), v and 'VISIBLE' or 'CACHE'))
    S.visiblePrev = v
  end
  S.root.layout.props.visible = v and true or false
  S.root:update()

  if v then
    if S.risk == nil then
      -- neutral: blanc semi-transparent en attendant le premier calcul
      local l = S.root.layout
      l.content[1].props.color = util.color.rgba(1, 1, 1, 0.35)
      S.root:update()
    else
      applyRisk()
    end
  end
end

-- Setter externe (clamp + anti-spam)
local function setRiskExternal(risk, confidence)
  local r = math.max(0, math.min(1, risk or 0))
  local conf = math.max(0, math.min(1, confidence or 1))
  if S.risk == r and S.confidence == conf then return end
  S.risk, S.confidence = r, conf
  applyRisk()
end

-----------------------------------------------------------------------
-- Calcul du risque (synchrone via castRay physique)
-----------------------------------------------------------------------
local warnedOnce = false
local function computeRisk(dt)
  -- 1) Caméra + direction
  local eyePos = camera.getPosition()
  local dir    = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
  if not (eyePos and dir) then
    if not warnedOnce then
      logW('computeRisk: camera.getPosition()/viewportToWorldVector indisponible.')
      warnedOnce = true
    end
    return nil
  end

  -- 2) Ne mesure que si on regarde vers le bas
  if dir.z >= -0.10 then
    return nil
  end

  -- 3) Rayon (to) + petit offset (from) pour éviter la capsule/caméra
  local maxLen = CFG.danger.maxRayLen
  local to = util.vector3(
    eyePos.x + dir.x * maxLen,
    eyePos.y + dir.y * maxLen,
    eyePos.z + dir.z * maxLen
  )
  local from = util.vector3(
    eyePos.x + dir.x * 8,
    eyePos.y + dir.y * 8,
    eyePos.z + dir.z * 8
  )

  -- 4) Masque de collision orienté "sol/monde" (ignorer l'eau)
  local CT = nearby.COLLISION_TYPE
  local mask = 0
  local function addFlag(name)
    -- pcall évite "Key not found: ..." et le cas userdata
    local ok, v = pcall(function() return CT[name] end)
    if ok and v then mask = util.bitOr(mask, v) end
  end

  addFlag('World')       -- géométrie statique
  addFlag('HeightMap')   -- terrain extérieur
  addFlag('Static')      -- si présent dans ta build
  -- NE PAS ajouter 'Water' (on ignore la surface de l'eau)

  -- fallback si rien n’a été ajouté
  do
    local ok, any = pcall(function() return CT['AnyPhysical'] end)
    if mask == 0 and ok and any then
      mask = any
    end
  end


  -- 5) Raycast physique synchrone
  local res = nearby.castRay(from, to, { ignore = self, collisionType = mask })

  -- 6) Filtre anti micro-hit (impact trop proche du départ)
  if res and res.hit and res.hitPos then
    local dx = res.hitPos.x - from.x
    local dy = res.hitPos.y - from.y
    local dz = res.hitPos.z - from.z
    local d2 = dx*dx + dy*dy + dz*dz
    if d2 < 0.5 * 0.5 then
      res = nil
    end
  end

  -- 7) Pas de hit exploitable -> ne rien changer ce tick
  if not (res and res.hit and res.hitPos) then
    return nil
  end

  -- 8) Si surface trop raide (mur/falaise), probe vertical vers le bas
  if res.normal and res.normal.z and res.normal.z < 0.35 then
    local probeUp = 16
    local probeDn = 4096
    local from2 = util.vector3(res.hitPos.x, res.hitPos.y, res.hitPos.z + probeUp)
    local to2   = util.vector3(from2.x, from2.y, from2.z - probeDn)
    local res2  = nearby.castRay(from2, to2, { ignore = self, collisionType = mask })
    if res2 and res2.hit and res2.hitPos then
      res = res2
    else
      return nil
    end
  end

  -- 9) Garde-fou : ne pas considérer un "sol" au-dessus des yeux
  if res.hitPos.z >= eyePos.z then
    return nil
  end

  -- 10) Hauteur de chute
  local groundZ = res.hitPos.z
  local eyeZ    = eyePos.z
  local fallH   = eyeZ - groundZ
  if fallH <= 0 then
    return 0.0, 1.0
  end
  if fallH > 30000 then
    return nil
  end

  -- 11) Stats réelles (valeurs "modified")
  local INT = types.Actor.stats.attributes.intelligence(self).modified
  local ACR = types.NPC  .stats.skills        .acrobatics   (self).modified
  if not (INT and ACR) then
    return nil
  end

  -- 12) Seuils modulés par l’acro
  local hSafe  = CFG.danger.hSafeBase  + CFG.danger.acroBoost * ACR
  local hFatal = CFG.danger.hFatalBase + CFG.danger.acroBoost * ACR
  if hFatal <= hSafe then hFatal = hSafe + 1 end

  -- 13) Risque linéaire 0..1
  local risk
  if      fallH <= hSafe  then risk = 0.0
  elseif  fallH >= hFatal then risk = 1.0
  else   risk = (fallH - hSafe) / (hFatal - hSafe)
  end

  -- Immunité vanilla acro ≥ 125
  if ACR >= 125 then
    risk = 0.0
  end

  -- 14) Confiance (alpha) plus sévère aux faibles stats
  local confRaw = (INT + ACR) / 150.0
  if confRaw < 0 then confRaw = 0 elseif confRaw > 1 then confRaw = 1 end
  local confidence = 0.15 + 0.85 * (confRaw * confRaw)

  return risk, confidence
end

-----------------------------------------------------------------------
-- Update (K/L)
-----------------------------------------------------------------------
local function onUpdate(dt)
  local kNow = input.isKeyPressed(CFG.keyHold)
  local lNow = input.isKeyPressed(CFG.keyToggle)

  -- maintenir K => visible tant que pressée
  S.holdDown = kNow

  -- L => toggle collant
  if lNow and not S.lPrev then
    S.sticky = not S.sticky
    logI('Toggle L -> sticky=' .. tostring(S.sticky))
  end

  S.kPrev = kNow
  S.lPrev = lNow

  local dir = camera.viewportToWorldVector(util.vector2(0.5, 0.5))
  local lookingDown = (dir and dir.z or 0) < CFG.lookDownThreshold

  local wantVisible = S.holdDown or S.sticky and lookingDown
  setVisible(wantVisible)
  if not wantVisible then
    return
  end
  -- Calcul "réel" seulement si l’anneau est visible
  if wantVisible then
    local r, conf = computeRisk(dt)
    if r ~= nil then
      setRiskExternal(r, conf)
    else
      -- rien de neuf ce tick -> réappliquer l'état courant si besoin
      applyRisk()
    end
  end
end

-----------------------------------------------------------------------
-- Sauvegarde/Chargement
-----------------------------------------------------------------------
return {
  engineHandlers = {
    onUpdate = onUpdate,
    onSave = function()
      return {
        sticky = S.sticky,
        testForced = S.testForced,
        hadUi = isValid(S.root),
        risk = S.risk,
        confidence = S.confidence,
      }
    end,
    onLoad = function(data)
      S.sticky     = data and data.sticky or false
      S.testForced = data and data.testForced or false
      S.risk       = data and data.risk
      S.confidence = data and data.confidence or 1.0
      if data and data.hadUi then ensureUi() end
    end,
  },
}
