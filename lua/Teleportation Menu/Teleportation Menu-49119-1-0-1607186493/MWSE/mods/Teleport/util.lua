local util = {}
local sf = string.format
local ts = tostring
local DBG = 1

--------------------------------------------------------------------------------
-- Json stuff --
--------------------------------------------------------------------------------
function util.namePresent(jsondata, name)
  for index, value in ipairs(jsondata) do
    util.logf("current name: %s, name to match: %s", value.name, name)
    if(value.name == name) then return true end
  end
  util.logf("name %s is already present in the config file", name)
  return false
end

--------------------------------------------------------------------------------
-- UI Element stuff --
--------------------------------------------------------------------------------
-- used to kill/close a menu given a menu id
function util.kill(menuId)
  local menu = tes3ui.findMenu(menuId)
  if (menu) then
      tes3ui.leaveMenuMode()
      menu:destroyChildren()
      menu:destroy()
  end
end

-- wrapper for making new menu with set values
function util.makeMenu(mid)
  local menu = tes3ui.createMenu {id = mid, fixedFrame = true}
  menu.alpha = 1.0
  menu.paddingAllSides = 8
  menu.autoWidth = true
  menu.autoHeight = true
  return menu
end

-- wrapper for making new block with set values
function util.newBlock(m)
    --hlog("util.newBlock(m)")
    local b = m:createBlock{}
    b.widthProportional = 1.0 -- width is 100% parent width
    b.autoHeight = true
    b.autoWidth = true
    b.childAlignX = 0.0
    b.paddingAllSides = 2
    return b
end

-- wrapper for making new vertical scroll panes with set values
function util.newPane(parent, pid)
  local pane = parent:createVerticalScrollPane{id = pid or nil}
  pane.positionY = 8
  pane.minWidth = 250
  pane.minHeight = 300
  pane.autoWidth = true
  pane.autoHeight = true
  return pane
end

-- wrapper to create new button or selectable text, allows function registers
function util.makeClickable(data)
  clk = util.makeClickableHelper(data)
  local dc = data.color
  if (data.fun ~= nil) then clk:register(mc, data.fun) end
  if (dc ~= nil) then
    clk.color = dc
    clk.widget.idle = dc
    clk.widget.idleActive = dc
    clk.widget.idleDisabled = c.dis
    clk.widget.over = util.shift(dc, m.L2)
    clk.widget.overActive = util.shift(dc, m.L3)
    clk.widget.overDisabled = c.dis
    clk.widget.pressed = util.shift(dc, m.L4)
    clk.widget.pressedActive = util.shift(dc, m.L4)
  end
  if(data.same == true) then
    clk.color = c.def
    clk.widget.idle = c.def
    clk.widget.idleActive = c.def
    clk.widget.idleDisabled = c.def
    clk.widget.over = c.def
    clk.widget.overActive = c.def
    clk.widget.overDisabled = c.def
    clk.widget.pressed = c.def
    clk.widget.pressedActive = c.def
  end

  clk.borderAllSides = data.brd or 0
  clk.borderBottom = data.bb or 0
  clk.borderLeft = data.bl or 0
  clk.borderRight = data.br or 0
  clk.borderTop = data.bt or 0
  clk.paddingAllSides = data.pad or 0
  clk.paddingBottom = data.pb or 0
  clk.paddingLeft = data.pl or 0
  clk.paddingRight = data.pr or 0
  clk.paddingTop = data.pt or 0
  clk.widthProportional = data.wp or 1.0

  return clk
end

-- creates either a new button or selectable text for util.makeClickable
function util.makeClickableHelper(data)
  if (data.type == 'b') then return data.parent:createButton{id = data.id,  text = data.text}
  else return data.parent:createTextSelect{id = data.id,  text = data.text} end
end

--------------------------------------------------------------------------------
-- Color stuff --
--------------------------------------------------------------------------------
-- makes a color lighter or darker
function util.shift(color, mode)
  local r,g,b = color[1], color[2], color[3]
  local l1, l2, l3, l4 = 0.08, 0.12, 0.2, 0.3 -- adding to RGB = lighter
  local d1, d2, d3, d4 = -l1, -l2, -l3, -l4   -- subtracting from RGB = darker
  local diff = nil

  if (mode == m.L1) then diff = l1 end
  if (mode == m.L2) then diff = l2 end
  if (mode == m.L3) then diff = l3 end
  if (mode == m.L4) then diff = l4 end
  if (mode == m.D1) then diff = d1 end
  if (mode == m.D2) then diff = d2 end
  if (mode == m.D3) then diff = d3 end
  if (mode == m.D4) then diff = d4 end

  if ((r + diff) > 1.0) then r = 1.0 elseif ((r + diff) < 0.0) then r = 0.0 else r = r + diff end
  if ((g + diff) > 1.0) then g = 1.0 elseif ((g + diff) < 0.0) then g = 0.0 else g = g + diff end
  if ((b + diff) > 1.0) then b = 1.0 elseif ((b + diff) < 0.0) then b = 0.0 else b = b + diff end

  return {r,g,b}

end

-- converts regular RGB values to values between 0.0 & 1.0
function util.rgbFloat(r,g,b) return {(r/255),(g/255),(b/255)} end

--------------------------------------------------------------------------------
-- Misc. --
--------------------------------------------------------------------------------
function util.isNeg(num) if (num < 0) then return true else return false end end

function util.pval(num) if (num < 0) then return math.abs(num) else return num end end

--------------------------------------------------------------------------------
-- Logging --
--------------------------------------------------------------------------------
function util.log(m) if (DBG == 1) then mwse.log("[TEL]          %s", m) end end
function util.hlog(m) if (DBG == 1) then mwse.log("[TEL] ", m) end end
function util.vlog(m) if (DBG == 1) then tes3.messageBox({message = m}) end end
function util.logf(m,a,b,c,d,e,f) util.log(getMsg(m,a,b,c,d,e,f)) end
function util.hlogf(m,a,b,c,d,e,f) util.hlog(getMsg(m,a,b,c,d,e,f)) end
function util.vlogf(m,a,b,c,d,e,f) util.vlog(getMsg(m,a,b,c,d,e,f)) end

function getMsg(m,a,b,c,d,e,f)
    local logMsg = sf(m,a,b,c,d,e,f) or sf(m,a,b,c,d,e) or sf(m,a,b,c,d) or sf(m,a,b,c) or sf(m,a,b) or sf(m,a) or " "
    return logMsg
end

return util
