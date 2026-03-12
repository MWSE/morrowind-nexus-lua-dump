local ui = require('openmw.ui')
local core = require('openmw.core')
local util = require('openmw.util')
local async = require('openmw.async')
local makeBorder = require('scripts.sch.continuo.UIfirmBorder')

local v2 = util.vector2

local M = {}

-- -------------------------
-- Small helpers
-- -------------------------

function M.clamp(x, a, b)
  if x < a then return a end
  if x > b then return b end
  return x
end

function M.dark(c, mult)
  return util.color.rgb(c.r * mult, c.g * mult, c.b * mult)
end

function M.mix(a, b, m)
  m = m or 0.5
  return util.color.rgb(
    a.r * m + b.r * (1 - m),
    a.g * m + b.g * (1 - m),
    a.b * m + b.b * (1 - m)
  )
end

-- -------------------------
-- Textures (cached)
-- -------------------------

local textureCache = {}
function M.tex(path)
  local t = textureCache[path]
  if not t then
    t = ui.texture { path = path }
    textureCache[path] = t
  end
  return t
end

-- -------------------------
-- GMST colors
-- -------------------------

function M.gmstColor(tag)
  local s = core.getGMST(tag)
  if not s then
    return util.color.rgb(1, 1, 1)
  end

  local r, g, b = s:match('(%d+)%D+(%d+)%D+(%d+)')
  if not r then
    return util.color.rgb(1, 1, 1)
  end

  return util.color.rgb(tonumber(r) / 255, tonumber(g) / 255, tonumber(b) / 255)
end

-- -------------------------
-- Theme pack
-- -------------------------

function M.theme(playerSection)
  local textSize = tonumber(playerSection and playerSection:get('FONT_SIZE')) or 18
  textSize = M.clamp(textSize, 12, 28)

  local widthMult = tonumber(playerSection and playerSection:get('WIDTH_MULT')) or 1.0
  widthMult = M.clamp(widthMult, 0.75, 1.5)

  local spacer = math.floor(6 * (textSize / 18))
  local winW = math.floor(520 * widthMult)
  local winH = math.floor(320 * (0.9 + (textSize / 90)))

  local text = M.gmstColor('fontColor_color_normal_over')
  local gold = M.gmstColor('fontColor_color_normal')
  local goldMix = M.mix(text, gold, 0.35)

  return {
    textSize = textSize,
    widthMult = widthMult,
    spacer = spacer,
    winW = winW,
    winH = winH,
    text = text,
    gold = gold,
    goldMix = goldMix,
  }
end

-- -------------------------
-- Root border template (tinted)
-- -------------------------

function M.tintedRootTemplate(borderThickness, borderSizePx, borderColor, bgColor)
  local bg = {
    type = ui.TYPE.Image,
    props = {
      resource = M.tex('white'),
      relativeSize = v2(1, 1),
      color = bgColor or util.color.rgb(0, 0, 0),
      alpha = ui._getMenuTransparency(),
    },
  }

  return makeBorder(borderThickness or 'thin', borderColor, borderSizePx or 4, bg).borders
end

-- -------------------------
-- UI nodes: text + button
-- -------------------------

function M.textNode(label, colors)
  return {
    type = ui.TYPE.Text,
    props = {
      relativePosition = v2(0.5, 0.5),
      anchor = v2(0.5, 0.5),
      text = tostring(label),
      textColor = colors.text,
      textShadow = true,
      textShadowColor = util.color.rgb(0, 0, 0),
      textSize = colors.textSize,
      textAlignH = ui.ALIGNMENT.Center,
      textAlignV = ui.ALIGNMENT.Center,
    }
  }
end

function M.button(windowRefFn, contentNode, size, onClick, highlightColor, colors)
  local bg = {
    name = 'background',
    type = ui.TYPE.Image,
    props = {
      relativeSize = v2(1, 1),
      resource = M.tex('white'),
      color = util.color.rgb(0, 0, 0),
      alpha = 0.75,
    },
  }

  local clickbox = {
    name = 'clickbox',
    type = ui.TYPE.Widget,
    props = {
      relativeSize = v2(1, 1),
      relativePosition = v2(0, 0),
      anchor = v2(0, 0),
    },
    userData = { focus = 0 },
  }

  local function apply(elem)
    local w = windowRefFn and windowRefFn() or nil
    if not w then return end

    local f = (elem and elem.userData and elem.userData.focus) or 0
    if f == 2 then
      bg.props.color = highlightColor or colors.gold
    elseif f == 1 then
      bg.props.color = M.dark(highlightColor or colors.gold, 0.7)
    else
      bg.props.color = util.color.rgb(0, 0, 0)
    end
    w:update()
  end

  clickbox.events = {
    focusGain = async:callback(function(_, e) e.userData.focus = 1; apply(e) end),
    focusLoss = async:callback(function(_, e) e.userData.focus = 0; apply(e) end),
    mousePress = async:callback(function(d, e)
      if d.button == 1 then e.userData.focus = 2; apply(e) end
    end),
    mouseRelease = async:callback(function(d, e)
      if d.button == 1 then
        e.userData.focus = 1
        apply(e)
        if onClick then onClick() end
      end
    end),
  }

  return {
    type = ui.TYPE.Widget,
    props = { size = size },
    content = ui.content({ bg, contentNode, clickbox }),
  }
end

return M