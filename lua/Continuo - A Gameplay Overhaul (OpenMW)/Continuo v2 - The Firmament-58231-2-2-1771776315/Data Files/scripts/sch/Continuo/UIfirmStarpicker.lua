local ui = require('openmw.ui')
local util = require('openmw.util')
local async = require('openmw.async')
local storage = require('openmw.storage')
local self = require('openmw.self')
local types = require('openmw.types')

local Style = require('scripts.sch.continuo.UIfirmStyle')
local v2 = util.vector2

local M = {}

local playerSection = storage.playerSection('sch_contfirm')

local window, windowPos

-- ======================================================
-- PREFIX: all CELESTIAL SHARDS must start with this
-- ======================================================
local PREFIX = 'sch_contfirm_mi_star'

-- ======================================================
-- HUD size helper (Noctery-style)
-- ======================================================
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

-- ======================================================
-- Inventory scan (NO GROUPING, NO DOUBLE COUNTING)
-- Returns list of instances:
--   { {uid=1,id='...',name='...'}, {uid=2,...}, ... }
-- ======================================================
local function listStarFragmentInstances()
  local playerObj = self.object or self
  local inv = types.Actor.inventory(playerObj)
  if not inv then return {} end

  -- 1) discover unique matching record IDs from a SINGLE category
  local uniqueIds = {}
  local miscItems = inv:getAll(types.Miscellaneous) or {}

  for _, item in ipairs(miscItems) do
    local rid = (item.recordId or (item.record and item.record.id) or ''):lower()
    if rid:find(PREFIX, 1, true) == 1 then
      uniqueIds[rid] = true
    end
  end

  -- 2) expand using authoritative countOf()
  local out = {}
  local uid = 0

  for rid in pairs(uniqueIds) do
    local n = inv:countOf(rid) or 0
    if n > 0 then
      local rec = types.Miscellaneous.record(rid)
      local name = (rec and rec.name) or rid

      for _ = 1, n do
        uid = uid + 1
        out[#out + 1] = { uid = uid, id = rid, name = name }
      end
    end
  end

  table.sort(out, function(a, b)
    local an = (a.name or ''):lower()
    local bn = (b.name or ''):lower()
    if an ~= bn then return an < bn end
    return a.uid < b.uid
  end)

  return out
end

local function close()
  if window then
    window:destroy()
    window = nil
  end
end

-- ======================================================
-- Public API
-- ======================================================
function M.open(opts)
  if window then return end
  opts = opts or {}

  local t = Style.theme(playerSection)
  local borderColor = Style.dark(t.gold, 0.9)
  local rootTemplate = Style.tintedRootTemplate('thin', 4, borderColor)

  -- =========================
  -- Window sizing (HUD-based)
  -- =========================
  local hud = getHudSize()
  local marginX = math.floor(hud.x * 0.06)
  local marginY = math.floor(hud.y * 0.08)

  local winW = math.max(520, math.floor(hud.x * 0.50))
  local winH = math.max(600, math.floor(hud.y - marginY))

  local topBarH = math.floor(t.textSize * 1.4)

  window = ui.create({
    type = ui.TYPE.Container,
    layer = 'Modal',
    name = 'firmStarFragmentPicker',
    template = rootTemplate,
    props = {
      relativePosition = v2(0.5, 0.5),
      anchor = v2(0.5, 0.5),
      size = v2(winW, winH),
      position = windowPos or v2(0, 0),
    },
    content = ui.content {},
  })

  local function wref() return window end
  local function update() if window then window:update() end end

  -- Selection state (must be 3)
  local selectedOrder = {}   -- array in pick order
  local selectedByUid = {}   -- uid -> true

  local function selectedCount()
    return #selectedOrder
  end

  local function isSelected(uid)
    return selectedByUid[uid] == true
  end

  local function deselect(uid)
    if not selectedByUid[uid] then return end
    selectedByUid[uid] = nil
    for i = #selectedOrder, 1, -1 do
      if selectedOrder[i].uid == uid then
        table.remove(selectedOrder, i)
        break
      end
    end
  end

  local function select(entry)
    if selectedByUid[entry.uid] then return end
    if #selectedOrder >= 3 then
      return
    end
    selectedByUid[entry.uid] = true
    selectedOrder[#selectedOrder + 1] = entry
  end

  local mainFlex = {
    type = ui.TYPE.Flex,
    props = { autoSize = true, arrange = ui.ALIGNMENT.Start, horizontal = false },
    content = ui.content {},
  }
  window.layout.content:add(mainFlex)

  -- =========================
  -- Top bar (draggable)
  -- =========================
  local topBar = {
    type = ui.TYPE.Widget,
    props = { size = v2(winW, topBarH) },
    content = ui.content {},
  }
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
      text = 'CHOOSE 3 CELESTIAL SHARDS',
      textColor = t.text,
      textShadow = true,
      textShadowColor = util.color.rgb(0, 0, 0),
      textSize = t.textSize,
      textAlignH = ui.ALIGNMENT.Center,
      textAlignV = ui.ALIGNMENT.Center,
    }
  })

  local xBtn = Style.button(
    wref,
    Style.textNode('X', t),
    v2(topBarH, topBarH),
    function()
      close()
      if opts.onCancel then opts.onCancel() end
    end,
    util.color.rgb(0.7, 0.2, 0.2),
    t
  )
  xBtn.props.relativePosition = v2(1, 0.5)
  xBtn.props.anchor = v2(1, 0.5)
  xBtn.props.position = v2(-t.spacer, 0)
  topBar.content:add(xBtn)

  -- =========================
  -- Content area
  -- =========================
  mainFlex.content:add({ props = { size = v2(1, 1) * t.spacer } })

  local bottomRowH = topBarH
  local contentH = winH - topBarH - bottomRowH - (t.spacer * 4)
  if contentH < math.floor(t.textSize * 6) then
    contentH = math.floor(t.textSize * 6)
  end

  local content = {
    type = ui.TYPE.Widget,
    props = { size = v2(winW, contentH) },
    content = ui.content {},
  }
  mainFlex.content:add(content)

  -- =========================
  -- Bottom row (status + OK)
  -- =========================
  local bottomRow = {
    type = ui.TYPE.Widget,
    props = { size = v2(winW, topBarH) },
    content = ui.content {},
  }
  mainFlex.content:add(bottomRow)

  local statusText = {
    type = ui.TYPE.Text,
    props = {
      position = v2(t.spacer * 2, 0),
      size = v2(winW - t.spacer * 2, topBarH),
      text = 'SELECTED: 0 / 3',
      textColor = t.goldMix,
      textShadow = true,
      textShadowColor = util.color.rgb(0, 0, 0),
      textSize = t.textSize,
      textAlignH = ui.ALIGNMENT.Start,
      textAlignV = ui.ALIGNMENT.Center,
    }
  }
  bottomRow.content:add(statusText)

  local okBtnText = {
    type = ui.TYPE.Text,
    props = {
      relativePosition = v2(0.5, 0.5),
      anchor = v2(0.5, 0.5),
      text = 'OK (0/3)',
      textColor = t.text,
      textShadow = true,
      textShadowColor = util.color.rgb(0, 0, 0),
      textSize = t.textSize,
      textAlignH = ui.ALIGNMENT.Center,
      textAlignV = ui.ALIGNMENT.Center,
    }
  }

  local function refreshBottom()
    local n = selectedCount()
    statusText.props.text = ("SELECTED: %d / 3"):format(n)
    okBtnText.props.text = (n == 3) and 'OK' or ("OK (%d/3)"):format(n)
    if window then window:update() end
  end

  local okW = math.floor(t.textSize * 8.0)
  local okBtn = Style.button(
    wref,
    okBtnText,
    v2(okW, topBarH),
    function()
      if selectedCount() ~= 3 then
        refreshBottom()
        return
      end
      local picked = { selectedOrder[1], selectedOrder[2], selectedOrder[3] }
      close()
      if opts.onPick then opts.onPick(picked) end
    end,
    t.gold,
    t
  )
  okBtn.props.position = v2(winW - t.spacer * 2 - okW, 0)
  bottomRow.content:add(okBtn)

  -- =========================
  -- Build list + pagination
  -- =========================
  local fragments = listStarFragmentInstances()

  if #fragments == 0 then
    content.content:add({
      type = ui.TYPE.Text,
      props = {
        position = v2(t.spacer * 2, t.spacer),
        size = v2(winW - t.spacer * 4, contentH),
        text = "NO CELESTIAL SHARDS FOUND.",
        textColor = t.goldMix,
        textShadow = true,
        textShadowColor = util.color.rgb(0, 0, 0),
        textSize = t.textSize,
        multiline = true,
        wordWrap = true,
      }
    })
    refreshBottom()
    update()
    return
  end

  -- Option B: compute PER_PAGE from available height
  local rowH = math.floor(t.textSize * 1.6)
  local rowGap = math.floor(t.spacer / 2)
  local pagerH = rowH + (t.spacer * 2) -- pager row + padding
  local usableH = contentH - pagerH - t.spacer
  local PER_PAGE = math.max(6, math.floor(usableH / (rowH + rowGap)))

  local page = 1
  local maxPage = math.max(1, math.ceil(#fragments / PER_PAGE))

  local function buildPage()
    content.content = ui.content {}

    local y = t.spacer

    local start = (page - 1) * PER_PAGE + 1
    local stop = math.min(#fragments, start + PER_PAGE - 1)

    for i = start, stop do
      local e = fragments[i]
      local mark = isSelected(e.uid) and '✓ ' or ''
      local label = mark .. e.name

      local row = Style.button(
        wref,
        Style.textNode(label, t),
        v2(winW - t.spacer * 4, rowH),
        function()
          if isSelected(e.uid) then
            deselect(e.uid)
          else
            select(e)
          end
          buildPage()
          refreshBottom()
        end,
        t.gold,
        t
      )

      row.props.position = v2(t.spacer * 2, y)
      content.content:add(row)
      y = y + rowH + rowGap
    end

    -- Pager
    local pagerY = contentH - (t.spacer * 2) - rowH
    local btnW = math.floor(t.textSize * 2.2)

    local function setPage(p)
      page = math.max(1, math.min(maxPage, p))
      buildPage()
      refreshBottom()
    end

    local prev = Style.button(wref, Style.textNode('<', t), v2(btnW, rowH), function() setPage(page - 1) end, nil, t)
    prev.props.position = v2(t.spacer * 2, pagerY)
    content.content:add(prev)

    content.content:add({
      type = ui.TYPE.Text,
      props = {
        position = v2(t.spacer * 2 + btnW + t.spacer, pagerY),
        size = v2(winW - t.spacer * 6 - btnW * 2, rowH),
        text = ("PAGE %d / %d"):format(page, maxPage),
        textColor = t.text,
        textShadow = true,
        textShadowColor = util.color.rgb(0, 0, 0),
        textSize = t.textSize,
        textAlignH = ui.ALIGNMENT.Center,
        textAlignV = ui.ALIGNMENT.Center,
      }
    })

    local next = Style.button(wref, Style.textNode('>', t), v2(btnW, rowH), function() setPage(page + 1) end, nil, t)
    next.props.position = v2(winW - t.spacer * 2 - btnW, pagerY)
    content.content:add(next)
  end

  buildPage()
  refreshBottom()
  update()
end

function M.close()
  close()
end

function M.isOpen()
  return window ~= nil
end

return M