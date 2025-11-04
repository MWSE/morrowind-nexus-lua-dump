-- fall_risk/ui.lua — v0.2 (logs nettoyés)
local ui   = require('openmw.ui')
local util = require('openmw.util')

-- Logs désactivés
local function logI(_) end
local function logW(_) end
local function logE(_) end

local U = {
  _root = nil,
  _last = {
    path = nil, size = nil, inset = nil, layer = nil,
    safe = nil, danger = nil,
  },
  _risk = { r = nil, conf = 1.0 },
}

local function hasLayout(el) return el ~= nil and el.layout ~= nil end
local function canUpdate(el) return el ~= nil and el.update ~= nil end
local function isReady(el)   return hasLayout(el) and canUpdate(el) end
local function clamp01(x) return (x < 0 and 0) or (x > 1 and 1) or x end

local function lerp(a, b, t) return a + (b - a) * t end
local function mixColor(c1, c2, t)
  return util.color.rgba(
    lerp(c1.r, c2.r, t),
    lerp(c1.g, c2.g, t),
    lerp(c1.b, c2.b, t),
    1
  )
end

local function applyNeutral()
  if not isReady(U._root) then return end
  local l = U._root.layout
  if not (l and l.content and l.content[1]) then return end
  l.content[1].props.color = util.color.rgba(1, 1, 1, 0.35)
  U._root:update()
end

function U.ensureUi(path, size, insetPx, layerName)
  local L = U._last
  local same = isReady(U._root)
           and L.path == path and L.size == size
           and L.inset == insetPx and L.layer == layerName
  if same then
    return true
  end

  if isReady(U._root) and U._root.destroy then
    pcall(function() U._root:destroy() end)
  end
  U._root = nil

  local inner = size - (insetPx or 0) * 2
  local layout = {
    type = ui.TYPE.Widget,
    layer = layerName or 'HUD',
    name = 'fall_risk_root',
    props = {
      size = util.vector2(size, size),
      relativePosition = util.vector2(0.5, 0.5),
      anchor = util.vector2(0.5, 0.5),
    },
    content = ui.content({
      {
        type = ui.TYPE.Image,
        props = {
          size = util.vector2(inner, inner),
          anchor = util.vector2(0.5, 0.5),
          relativePosition = util.vector2(0.5, 0.5),
          resource = ui.texture{ path = path },
          color = util.color.rgba(1,1,1,0.35),
        },
      },
    }),
  }

  local ok, rootOrErr = pcall(ui.create, layout)
  if not ok or not rootOrErr then
    U._root = nil
    return false
  end

  U._root = rootOrErr
  if not isReady(U._root) then
    U._root = nil
    return false
  end

  U._last.path, U._last.size, U._last.inset, U._last.layer = path, size, insetPx, layerName

  if U._risk.r == nil then
    applyNeutral()
  else
    U.setRisk(U._risk.r, U._risk.conf or 1)
  end

  return true
end

function U.setPalette(colors)
  local s = colors and colors.safe
  local d = colors and colors.danger
  if s and d and (s ~= U._last.safe or d ~= U._last.danger) then
    U._last.safe, U._last.danger = s, d
    if U._risk.r ~= nil then
      U.setRisk(U._risk.r, U._risk.conf)
    else
      applyNeutral()
    end
  end
end

function U.setVisible(v)
  if not isReady(U._root) then return end
  local layout = U._root.layout
  if not layout or not layout.props then return end
  layout.props.visible = v and true or false
  if v and U._risk.r == nil then
    applyNeutral()
  end
  if canUpdate(U._root) then U._root:update() end
end

function U.setRisk(risk, confidence)
  if not isReady(U._root) then return end

  local r = clamp01(risk or 0)
  local a = clamp01(confidence or 1)
  U._risk.r, U._risk.conf = r, a

  local safe = U._last.safe or util.color.rgb(0,1,0)
  local dang = U._last.danger or util.color.rgb(1,0,0)

  local col = mixColor(safe, dang, r)

  local t   = 1 - a
  local rf  = col.r + (1 - col.r) * t
  local gf  = col.g + (1 - col.g) * t
  local bf  = col.b + (1 - col.b) * t

  local layout = U._root.layout
  if not (layout and layout.content and layout.content[1]) then return end
  layout.content[1].props.color = util.color.rgba(rf, gf, bf, a)
  U._root:update()
end

return U
