local this = {}
hotKey = 54 -- Right Shift
d = require("AlchHelp.data")

function this.init()
  hlog("this.init()")
  this.currentFx = {}
  this.currentFxItems = {}
  this.id = {}
  this.id.current = {}
  this.id.full = {}
  this.id.ingr = {}
  this.id.main = {}
  this.id.mw = {}
  this.playerIngredients = {}
  this.type = {}

  this.attributes = d.attrib
  this.effects = d.effects
  this.id.current.backBtn = tes3ui.registerID(d.pfx .. "AM_Back")
  this.id.current.menu = tes3ui.registerID(d.pfx .. "AvailableMenu")
  this.id.current.vScroll = tes3ui.registerID(d.pfx .. "AM_ScrollPane")
  this.id.full.backBtn = tes3ui.registerID(d.pfx .. "FM_Cancel")
  this.id.full.menu = tes3ui.registerID(d.pfx .. "FullFXMenu")
  this.id.full.vScroll = tes3ui.registerID(d.pfx .. "FM_ScrollPane")
  this.id.ingr.backBtn = tes3ui.registerID(d.pfx .. "IM_Back")
  this.id.ingr.menu =  tes3ui.registerID(d.pfx .. "IngredMenu")
  this.id.ingr.vScroll = tes3ui.registerID(d.pfx .. "IM_ScrollPane")
  this.id.main.availBtn = tes3ui.registerID(d.pfx .. "MM_Avail")
  this.id.main.exitBtn = tes3ui.registerID(d.pfx .. "MM_Cancel")
  this.id.main.filterBtn = tes3ui.registerID(d.pfx .. "MM_Filter")
  this.id.main.ingrBtn = tes3ui.registerID(d.pfx .. "MM_Ingred")
  this.id.main.menu = tes3ui.registerID(d.pfx .. "MainMenu")
  this.id.mw.alchMenu = tes3ui.registerID("MenuAlchemy")
  this.type.ingr = 1380404809

  -- make ids for each effects selectable text
  for index, vals in ipairs(this.effects) do
      local tmpStr = ts(vals.name) .. "Fx" .. ts(vals.id)
      if (vals.atr ~= nil) then tmpStr = tmpStr .. "Atr" .. ts(vals.atr) end
      if (vals.skl ~= nil) then tmpStr = tmpStr .. "Skl" .. ts(vals.skl) end
      tmpStr = string.gsub(tmpStr, "%s+", "")
      vals.txtId = tes3ui.registerID(d.pfx .. "FM_txt" .. tmpStr)
  end

  -- misc
  dnl = "\n"
  mc = "mouseClick"
  nl = "\n"

  -- color
  c = {}
  c.black = rgbFloat(0,0,0)
  c.def = rgbFloat(202,165,96) -- default morrowind menu text color
  c.dis = rgbFloat(102,102,102)
  c.red = rgbFloat(171, 0, 0)
  c.white = rgbFloat(255,255,255)

  f = {}
  f.allSame = 'a'

  -- mode of color change & intensity
  m = {}
  m.L1 = "L1"
  m.L2 = "L2"
  m.L3 = "L3"
  m.L4 = "L4"
  m.D1 = "D1"
  m.D2 = "D2"
  m.D3 = "D3"
  m.D4 = "D4"

  -- strings
  s = {}
  s.allFx = "All Effects"
  s.avFx = "Available Effects"
  s.back = "Back"
  s.can = "Cancel"
  s.curIngr = "Current Ingredients"
  s.ex = "Exit"
  s.header = "Alchemy Helper"

  -- types
  t = {}
  t.btn = 'b'
  t.txt = 't'
end

---------------------
-- Main Menu stuff --
---------------------
-- start main menu
function this.createWindow()
  if (tes3ui.findMenu(this.id.main.menu) ~= nil) then return end
  this.initIngrList()

  local menu = makeMenu(this.id.main.menu)
  local mainLbl = menu:createLabel{text = s.header}
  mainLbl.borderBottom = 5

  local b1 = newBlock(menu)
  local txtOpenAvail = makeClickable{parent = b1, id = this.id.main.availBtn, text = s.avFx, pad = 4, fun = this.openAvailFXMenu}
  local b2 = newBlock(menu)
  local txtOpenIngr = makeClickable{parent = b2, id = this.id.main.ingrBtn, text = s.curIngr, pad = 4, fun = this.openIngrMenu}
  local b3 = newBlock(menu)
  local txtOpenFullFx = makeClickable{parent = b3, id = this.id.main.filterBtn, text = s.allFx, pad = 4, fun = this.openFullFXMenu}
  local b4 = newBlock(menu)
  local txtCancel = makeClickable{parent = b4, id = this.id.main.exitBtn, text = s.ex, pad = 4, fun = this.mainCancelBtnPress, color = c.red}

  menu:updateLayout()
  tes3ui.enterMenuMode(this.id.main.menu)
end

-- handler for pressing the exit/cancel button in the main menu
function this.mainCancelBtnPress(e)
    local menu = tes3ui.findMenu(this.id.main.menu)
    if (menu) then
        tes3ui.leaveMenuMode()
        menu:destroyChildren()
        menu:destroy()
    end
end

------------------------
-- Full Fx Menu stuff --
------------------------
-- shows a list of all magical effects
function this.openFullFXMenu(e)
  if (tes3ui.findMenu(this.id.full.menu) ~= nil) then return end

  local ffxMenu = makeMenu(this.id.full.menu)
  local scrollBlock = ffxMenu:createBlock{}
  scrollBlock.autoWidth = true
  scrollBlock.autoHeight = true
  scrollBlock.paddingAllSides = 8

  local pane = newPane(scrollBlock, this.id.full.vScroll)
  makeFullFXList(pane)

  local btnBlock = newBlock(ffxMenu)
  local btnBack = makeClickable{parent = btnBlock, id = this.id.full.backBtn, text = s.back, pad = 8, fun = this.fullFXBackBtnPress, color = c.red}

  ffxMenu:updateLayout()
  tes3ui.enterMenuMode(this.id.full.menu)
end

-- handler for pressing the back button in the full list of magical effects
function this.fullFXBackBtnPress(e)
  local ffxMenu = tes3ui.findMenu(this.id.full.menu)
  if (ffxMenu) then
      tes3ui.leaveMenuMode()
      ffxMenu:destroyChildren()
      ffxMenu:destroy()
  end
end

-- for debug purposes
function this.fullSelectFx(e)
  local ffxMenu = tes3ui.findMenu(this.id.full.menu)
  --log("data: " .. ts(e.source))
end

-- creates text ui elements for the magical effects menu
function makeFullFXList(p)
    for index, val in ipairs(this.effects) do
        local tmpId = val.txtId
        local tmpTxt = val.name
        local tmpBtn = makeClickable{parent = p, id = tmpId, text = tmpTxt, same = true, pad = 2}
        tmpBtn.autoWidth = true
        tmpBtn.widthProportional = 1.0
        tmpBtn:register(mc, this.fullSelectFx)
    end
end

-----------------------------
-- Available FX Menu stuff --
-----------------------------
-- open available fx menu
function this.openAvailFXMenu(e)
  if (tes3ui.findMenu(this.id.current.menu) ~= nil) then return end

  local avMenu = makeMenu(this.id.current.menu)
  local scrollBlock = avMenu:createBlock{}
  scrollBlock.autoWidth = true
  scrollBlock.autoHeight = true
  scrollBlock.paddingAllSides = 8

  local pane = newPane(scrollBlock, this.id.current.vScroll)
  makeAvailList(pane)

  local btnBlock = newBlock(avMenu)
  local btnBack = makeClickable{parent = btnBlock, id = this.id.current.backBtn, text = s.back, pad = 8, fun = this.availBackBtnPress, color = c.red}

  avMenu:updateLayout()
  pane.widget:contentsChanged()
  tes3ui.enterMenuMode(this.id.current.menu)
end

-- finds number of ingredients per effect's string based on - being used as a bullet point 
function getIngrCount(str)
  local _, count = string.gsub(str, " %- ", "")
  return count
end


-- creates text ui elements for the available effects menu
function makeAvailList(p)
  for i,v in pairs(this.currentFxItems) do
    local ingrNum = getIngrCount(v)
    if (ingrNum > 1) then
      local tmpId = tes3ui.registerID(d.pfx .. "AM_txt" .. ts(i))
      local txt = v
      local tmpTxt = makeClickable{parent = p, id = tmpId, text = txt, same = true, pad = 4, brd = 2}
      tmpTxt.autoWidth = true
      tmpTxt.widthProportional = 1.0
    end
  end
end

-- handler for pressing the back button in the available effects menu
function this.availBackBtnPress(e)
  local avMenu = tes3ui.findMenu(this.id.current.menu)
  if (avMenu) then
      tes3ui.leaveMenuMode()
      avMenu:destroyChildren()
      avMenu:destroy()
  end
end

-- find proper effect name.
-- effects that modify a skill or attribute have the same effect id but different skill or attribute ids
-- ex: damage luck & damage personality have the same exact effect id which is atually damage attribute
function findFxName(id, attrib, skill)
  for index, data in ipairs(this.effects) do
    if (data.id == id) then
      if (data.atr ~= nil) then
        if (data.atr == attrib) then
          return data.name
        end
      elseif (data.skill ~= nil) then
        if (data.skill == skill) then
          return data.name
        end
      else
        return data.name
      end
    end
  end
  return "xx"
end

----------------------------
-- Ingredients Menu stuff --
----------------------------
-- open ingredient menu
function this.openIngrMenu(e)
  if (tes3ui.findMenu(this.id.ingr.menu) ~= nil) then return end

  for _,v in pairs(this.playerIngredients) do
    local fx = debugFXList(v.object.effects,v.object.effectAttributeIds, v.effectsSkillIds)
  end

  local ingrMenu = makeMenu(this.id.ingr.menu)
  local scrollBlock = ingrMenu:createBlock{}
  scrollBlock.autoWidth = true
  scrollBlock.autoHeight = true
  scrollBlock.paddingAllSides = 8

  local pane = newPane(scrollBlock, this.id.ingr.vScroll)
  makeIngrList(pane)

  local btnBlock = newBlock(ingrMenu)
  local btnBack = makeClickable{parent = btnBlock, id = this.id.ingr.backBtn, text = s.back, pad = 8, fun = this.ingrBackBtnPress, color = c.red}

  ingrMenu:updateLayout()
  pane.widget:contentsChanged()
  tes3ui.enterMenuMode(this.id.ingr.menu)
end

-- handler for back button press in ingredient menu
function this.ingrBackBtnPress(e)
  --hlog("this.ingrBackBtnPress(e)")
  local ingrMenu = tes3ui.findMenu(this.id.ingr.menu)
  if (ingrMenu) then
    tes3ui.leaveMenuMode()
    ingrMenu:destroyChildren()
    ingrMenu:destroy()
  end
end

-- make the text ui elements for the ingredient menu
function makeIngrList(p)
  for _,v in pairs(this.playerIngredients) do
    local tmpId = tes3ui.registerID(d.pfx .. "txt" .. ts(v.object.id))
    local txt = v.object.name
    local tmpTxt = makeClickable{parent = p, id = tmpId, text = txt, same = true, pad = 2}
    tmpTxt.autoWidth = true
    tmpTxt.widthProportional = 1.0
  end
end

-- used for debug/testing purposes
function debugFXList(fxId, attribId, skillId)
  local namelist = ""
  for index,data in ipairs(fxId) do
    local skill = nil
    if (skillId ~= nil) then skill = skillId[index] end
    local attrib = nil
    if (attribId ~= nil) then attrib = attribId[index] end
    namelist = namelist .. " | " .. findFxName(data, attrib , skill)
  end
  namelist = namelist .. " |"
  return namelist
end

-------------------------
-- General/misc. stuff --
-------------------------
-- wrapper for making new menu with set values
function makeMenu(mid)
  local menu = tes3ui.createMenu {id = mid, fixedFrame = true}
  menu.alpha = 1.0
  menu.paddingAllSides = 8
  menu.autoWidth = true
  menu.autoHeight = true
  return menu
end

-- wrapper for making new block with set values
function newBlock(m)
    --hlog("newBlock(m)")
    local b = m:createBlock{}
    b.widthProportional = 1.0 -- width is 100% parent width
    b.autoHeight = true
    b.autoWidth = true
    b.childAlignX = 0.0
    b.paddingAllSides = 2
    return b
end

-- wrapper to create new button or selectable text, allows function registers
function makeClickable(data)
  clk = makeClickableHelper(data)
  local dc = data.color
  if (data.fun ~= nil) then clk:register(mc, data.fun) end
  if (dc ~= nil) then
    clk.color = dc; clk.widget.idle = dc; clk.widget.idleActive = dc; clk.widget.idleDisabled = c.dis
    clk.widget.over = shift(dc, m.L2); clk.widget.overActive = shift(dc, m.L3); clk.widget.overDisabled = c.dis
    clk.widget.pressed = shift(dc, m.L4); clk.widget.pressedActive = shift(dc, m.L4)
  end
  if(data.same == true) then
    clk.color = c.def; clk.widget.idle = c.def; clk.widget.idleActive = c.def; clk.widget.idleDisabled = c.def; clk.widget.over = c.def
    clk.widget.overActive = c.def; clk.widget.overDisabled = c.def; clk.widget.pressed = c.def; clk.widget.pressedActive = c.def
  end
  clk.paddingAllSides = data.pad or 0; clk.paddingTop = data.pt or 0; clk.paddingBottom = data.pb or 0; clk.paddingLeft = data.pl or 0; clk.paddingRight = data.pr or 0
  clk.borderAllSides = data.brd or 0; clk.borderTop = data.bt or 0; clk.borderBottom = data.bb or 0; clk.borderLeft = data.bl or 0; clk.borderRight = data.br or 0
  clk.widthProportional = data.wp or 1.0

  return clk
end

-- creates either a new button or selectable text for makeClickable
function makeClickableHelper(data)
  if (data.type == t.btn) then return data.parent:createButton{id = data.id,  text = data.text}
  else return data.parent:createTextSelect{id = data.id,  text = data.text} end
end

-- makes a color lighter or darker
function shift(color, mode)
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
function rgbFloat(r,g,b) return {(r/255),(g/255),(b/255)} end

-- wrapper for making new vertical scroll panes with set values
function newPane(parent, pid)
  local pane = parent:createVerticalScrollPane{id = pid or nil}
  pane.positionY = 8
  pane.minWidth = 250
  pane.minHeight = 300
  pane.autoWidth = true
  pane.autoHeight = true
  return pane
end

-- regular log for mod
function log(msg) mwse.log("[AF]          " .. msg) end

-- header log
function hlog(msg) mwse.log("[AF] " ..  msg) end

-- tostring wrapper
function ts(val) return tostring(val) end

-------------------------------
-- List Initialization stuff --
-------------------------------
function this.initIngrList()
  local inven = tes3.player.object.inventory
  for _, v in pairs(inven) do
      if (v.object.objectType == this.type.ingr) then
        table.insert(this.playerIngredients, v)
      end
  end
  this.initAvailList()
end

-- take available effects & ingredients and make into strings to put into menu
function this.makeAvailStrings()
  local tkeys = {}
  for k in pairs(this.currentFx) do table.insert(tkeys, k) end
  table.sort(tkeys)
  for _, k in ipairs(tkeys) do
    local tmpStr = "[" .. ts(k) .. "]"
    for _, v in ipairs(this.currentFx[k]) do
      tmpStr = tmpStr .. "\n\t    - " .. ts(v)
    end
    table.insert(this.currentFxItems, tmpStr)
  end
end

-- make list/table of each available effect and cooresponding ingredients based on player inventory
function this.initAvailList()
  for index, val in ipairs(this.playerIngredients) do
    local tmpFx = makeIngredientFXList(val.object.effects, val.object.effectAttributeIds, val.effectsSkillIds)
    iname = val.object.name
    for index2, val2 in ipairs(tmpFx) do
      if (val2 ~= "xx") then
        local fxp = fxIsPresent(this.currentFx, (ts(val2)))
        fxid = ts(val2)
        if (not fxp) then this.currentFx[fxid] = {iname} -- make new fx entry
        else table.insert(this.currentFx[fxid], iname) end -- update fx entry by adding ingredient name
      end
    end
  end
  this.makeAvailStrings()
end

-- make list of available effects for an ingredient
function makeIngredientFXList(fxId, attribId, skillId)
  local namelist = {}
  for index,data in ipairs(fxId) do
    local skill = nil
    if (skillId ~= nil) then skill = skillId[index] end
    local attrib = nil
    if (attribId ~= nil) then attrib = attribId[index] end
    table.insert(namelist, (findFxName(data, attrib , skill)))
  end
  return namelist
end

-- checks if an effect is already present in table
function fxIsPresent(list, name)
  for i, v in pairs(list) do
    if (name == (ts(i))) then return true end
  end
  return false
end

-----------------------------
-- Start, keydown callback --
-----------------------------
function this.onCommand(e)
    log("menumode: " .. (ts(tes3ui.menuMode())))
    if (tes3ui.menuMode()) then
      local top = tes3ui.getMenuOnTop()
      log("top menu: " .. ts(top.id))
      if (top.id == this.id.mw.alchMenu) then
        this.init()
        this.createWindow()
      end
    end
end

event.register("initialized", this.init)
event.register("keyDown", this.onCommand, {filter = hotKey})
