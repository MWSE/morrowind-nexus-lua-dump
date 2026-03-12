local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local storage = require('openmw.storage')
local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')

local Style = require('scripts.sch.continuo.UIfirmStyle')
local StarFragmentPicker = require('scripts.sch.continuo.UIfirmStarpicker')

local v2 = util.vector2
local M = {}

local playerSection = storage.playerSection('sch_contfirm')

local window, windowPos
local fragmentLabelText
local selectedFragments -- list of 3: { {uid,id,name}, ... }

-- ========= helpers =========

local function getHudSize()
  local hudId = ui.layers.indexOf('HUD')
  if hudId then
    local layer = ui.layers[hudId]
    if layer and layer.size then
      return layer.size
    end
  end
  return ui.screenSize()
end

local function buildRequiredCounts(fragments)
  local req = {}
  for _, f in ipairs(fragments or {}) do
    local id = (f and f.id) or nil
    if id then
      id = id:lower()
      req[id] = (req[id] or 0) + 1
    end
  end
  return req
end

local function playerHasRequiredCounts(fragments)
  if type(fragments) ~= 'table' or #fragments ~= 3 then return false end
  local inv = types.Actor.inventory(self.object or self)
  if not inv then return false end

  local req = buildRequiredCounts(fragments)
  for id, need in pairs(req) do
    local have = tonumber(inv:countOf(id)) or 0
    if have < need then return false end
  end
  return true
end

local function sendConsumeRequest(fragments)
  -- Global script will consume from actor inventory.
  -- We send counts, not uids, because inventory stacks can merge.
  local req = buildRequiredCounts(fragments)
  core.sendGlobalEvent('SCH_ContFirmConsumeStars', {
    actor = self.object or self,
    required = req,
  })
end

local function handoffToRoller(fragments)
  local ok, Roller = pcall(require, 'scripts.sch.continuo.SYSfirmAttunementRoll')
  if ok and Roller and Roller.roll then
    local result = Roller.roll(fragments)
    if result then
      core.sendGlobalEvent('SCH_ContFirmApplyRoll', {
        actor = self.object or self,
        roll = result,
      })
    end
  end
end

-- ========= selection API =========

function M.setSelectedFragments(list)
  if type(list) == 'table' and #list > 0 then
    selectedFragments = list
  else
    selectedFragments = nil
  end

  if fragmentLabelText then
    if selectedFragments and #selectedFragments == 3 then
      fragmentLabelText.props.text =
        ("CELESTIAL SHARDS:\n✓ %s\n✓ %s\n✓ %s"):format(
          selectedFragments[1].name,
          selectedFragments[2].name,
          selectedFragments[3].name
        )
    else
      fragmentLabelText.props.text = "CELESTIAL SHARDS: ✗ (choose 3)"
    end
  end

  if window then window:update() end
end

function M.getSelectedFragments()
  return selectedFragments
end

-- ========= window lifecycle =========

local function close()
  if window then
    window:destroy()
    window = nil
  end
end

function M.isOpen() return window ~= nil end
function M.close() close() end

-- ========= UI build =========

function M.open()
  if window then return end

  local t = Style.theme(playerSection)
  local borderColor = Style.dark(t.gold, 0.9)
  local rootTemplate = Style.tintedRootTemplate('thin', 4, borderColor)

  -- HUD-relative sizing (Noctery / StarPicker style)
  local hud = getHudSize()
  local marginX = math.floor(hud.x * 0.12)
  local marginY = math.floor(hud.y * 0.15)

  local winW = math.max(480, math.floor(hud.x * 0.25))  -- 1/4 width
  local winH = math.max(420, math.floor(hud.y * 0.33))  -- 1/3 height

  window = ui.create({
    type = ui.TYPE.Container,
    layer = 'Modal',
    name = 'starAttunementWindow',
    template = rootTemplate,
    props = {
      relativePosition = v2(0.5, 0.45),
      anchor = v2(0.5, 0.5),
      size = v2(winW, winH),
      position = windowPos or v2(0, 0),
    },
    content = ui.content {},
  })

  local function wref() return window end
  local function update() if window then window:update() end end

  local mainFlex = {
    type = ui.TYPE.Flex,
    props = { autoSize = true, arrange = ui.ALIGNMENT.Start, horizontal = false },
    content = ui.content {},
  }
  window.layout.content:add(mainFlex)

  -- Top bar (draggable)
  local topBarH = math.floor(t.textSize * 1.4)
  local topBar = { type = ui.TYPE.Widget, props = { size = v2(winW, topBarH) }, content = ui.content {} }
  mainFlex.content:add(topBar)

  local topBarBg = {
    type = ui.TYPE.Image,
    props = { resource = Style.tex('white'), alpha = 0.0, color = t.gold, relativeSize = v2(1, 1) },
  }
  topBar.content:add(topBarBg)

  topBar.events = {
    mousePress = async:callback(function(d, e)
      if d.button ~= 1 then return end
      e.userData = e.userData or {}
      e.userData.drag = true
      e.userData.start = d.position
      e.userData.win = window.layout.props.position or v2(0, 0)
      topBarBg.props.alpha = 0.20
      update()
    end),
    mouseRelease = async:callback(function(_, e)
      if e.userData then e.userData.drag = false end
      topBarBg.props.alpha = 0.10
      update()
    end),
    mouseMove = async:callback(function(d, e)
      if not e.userData or not e.userData.drag then return end
      local dx = d.position.x - e.userData.start.x
      local dy = d.position.y - e.userData.start.y
      local p = v2(e.userData.win.x + dx, e.userData.win.y + dy)
      windowPos = p
      window.layout.props.position = p
      update()
    end),
    focusGain = async:callback(function() topBarBg.props.alpha = 0.10; update() end),
    focusLoss = async:callback(function(_, e)
      if e.userData then e.userData.drag = false end
      topBarBg.props.alpha = 0.0
      update()
    end),
  }

  topBar.content:add({
    type = ui.TYPE.Text,
    props = {
      relativePosition = v2(0.5, 0.5),
      anchor = v2(0.5, 0.5),
      text = 'CELESTIAL HARMONIZATION',
      textColor = t.text,
      textShadow = true,
      textShadowColor = util.color.rgb(0, 0, 0),
      textSize = t.textSize,
      textAlignH = ui.ALIGNMENT.Center,
      textAlignV = ui.ALIGNMENT.Center,
    }
  })

  local closeBtn = Style.button(
    wref, Style.textNode('X', t), v2(topBarH, topBarH),
    close, util.color.rgb(0.7, 0.2, 0.2), t
  )
  closeBtn.props.relativePosition = v2(1, 0.5)
  closeBtn.props.anchor = v2(1, 0.5)
  closeBtn.props.position = v2(-t.spacer, 0)
  topBar.content:add(closeBtn)

  -- Content
  mainFlex.content:add({ props = { size = v2(1, 1) * t.spacer } })

  local content = {
    type = ui.TYPE.Widget,
    props = { size = v2(winW, winH - topBarH - t.spacer * 3) },
    content = ui.content {},
  }
  mainFlex.content:add(content)

  content.content:add({
    type = ui.TYPE.Text,
    props = {
      position = v2(t.spacer * 2, t.spacer),
      size = v2(winW - t.spacer * 4, math.floor(t.textSize * 3.0)),
      text = "ALIGN THE RECEPTACLE TO THE SKY.\nCHOOSE THREE SHARDS.\n",
      textColor = t.goldMix,
      textShadow = true,
      textShadowColor = util.color.rgb(0, 0, 0),
      textSize = t.textSize,
      multiline = true,
      wordWrap = true,
    }
  })

  -- CELESTIAL SHARDS button (now vertical list)
  fragmentLabelText = {
    type = ui.TYPE.Text,
    props = {
      relativePosition = v2(0.5, 0.5),
      anchor = v2(0.5, 0.5),
      text = "CELESTIAL SHARDS: ✗ (choose 3)",
      textColor = t.text,
      textShadow = true,
      textShadowColor = util.color.rgb(0, 0, 0),
      textSize = t.textSize,
      textAlignH = ui.ALIGNMENT.Center,
      textAlignV = ui.ALIGNMENT.Center,
      multiline = true,
      wordWrap = true,
    }
  }

  local fragmentBtnH = math.floor(winH * 0.5)
  local fragmentBtn = Style.button(
    wref,
    fragmentLabelText,
    v2(winW - t.spacer * 4, fragmentBtnH),
    function()
      StarFragmentPicker.open({
        onPick = function(list) M.setSelectedFragments(list) end,
        onCancel = function() end,
      })
    end,
    t.gold,
    t
  )
  fragmentBtn.props.position = v2(t.spacer * 2, math.floor(t.textSize * 3.6))
  content.content:add(fragmentBtn)

  -- Re-apply selection
  M.setSelectedFragments(selectedFragments)

  -- BEGIN ATTUNEMENT
  local bottomY = (winH - topBarH) - (t.spacer * 5) - topBarH
  local attuneBtn = Style.button(
    wref,
    Style.textNode('BEGIN ATTUNEMENT', t),
    v2(math.floor(t.textSize * 12), topBarH),
    function()
      if not selectedFragments or #selectedFragments ~= 3 then
        M.setSelectedFragments(selectedFragments)
        return
      end

      -- local validation (countOf is available locally)
      if not playerHasRequiredCounts(selectedFragments) then
        M.setSelectedFragments(selectedFragments)
        return
      end

      -- consume via GLOBAL script
      sendConsumeRequest(selectedFragments)

      -- close hub menu
      close()

      -- roller module
      handoffToRoller(selectedFragments)
    end,
    t.gold,
    t
  )
  attuneBtn.props.position = v2(t.spacer * 2, bottomY)
  content.content:add(attuneBtn)

  update()
end

return M