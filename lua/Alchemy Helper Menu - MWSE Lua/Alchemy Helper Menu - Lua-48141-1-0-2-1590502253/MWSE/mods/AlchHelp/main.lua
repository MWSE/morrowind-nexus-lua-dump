local this = {}
d = require("AlchHelp.data")

function this.init()
  hlog("this.init()")
  this.availFx = {}
  this.availFxItems = {}
  this.curIngr = {}
  this.id = {}
  this.id.avail = {}
  this.id.full = {}
  this.id.ingr = {}
  this.id.main = {}
  this.id.mw = {}
  this.type = {}

  this.attr = d.attrib
  this.effects = d.effects
  this.id.avail.backBtn = tes3ui.registerID("af:AM_Back")
  this.id.avail.menu = tes3ui.registerID("af:AvailableMenu")
  this.id.avail.vScroll = tes3ui.registerID("af:AM_ScrollPane")
  this.id.full.backBtn = tes3ui.registerID("af:FM_Cancel")
  this.id.full.menu = tes3ui.registerID("af:FullFXMenu")
  this.id.full.vScroll = tes3ui.registerID("af:FM_ScrollPane")
  this.id.ingr.backBtn = tes3ui.registerID("af:IM_Back")
  this.id.ingr.menu =  tes3ui.registerID("af:IngredMenu")
  this.id.ingr.vScroll = tes3ui.registerID("af:IM_ScrollPane")
  this.id.main.availBtn = tes3ui.registerID("af:MM_Avail")
  this.id.main.exitBtn = tes3ui.registerID("af:MM_Cancel")
  this.id.main.filterBtn = tes3ui.registerID("af:MM_Filter")
  this.id.main.ingrBtn = tes3ui.registerID("af:MM_Ingred")
  this.id.main.menu = tes3ui.registerID("af:MainMenu")
  this.id.mw.alchMenu = "MenuAlchemy"
  this.type.ingr = 1380404809

  -- make ids for each effects selectable text
  for index, vals in ipairs(this.effects) do
      local tmpStr = ts(vals.name) .. "Fx" .. ts(vals.id)
      if (vals.atr ~= nil) then tmpStr = tmpStr .. "Atr" .. ts(vals.atr) end
      if (vals.skl ~= nil) then tmpStr = tmpStr .. "Skl" .. ts(vals.skl) end
      tmpStr = string.gsub(tmpStr, "%s+", "")
      vals.txtId = tes3ui.registerID("af:FM_txt" .. tmpStr)
  end

  -- misc
  dnl = "\n"
  mc = "mouseClick"
  nl = "\n"

  c = {}
  c.black = rgbFloat(0,0,0)
  c.dis = rgbFloat(102,102,102)
  c.red = rgbFloat(171, 0, 0)
  c.white = rgbFloat(255,255,255)
  c.def = rgbFloat(202,165,96)

  f = {}
  f.allSame = 'a'


  m = {}
  m.L1 = "L1"
  m.L2 = "L2"
  m.L3 = "L3"
  m.L4 = "L4"
  m.D1 = "D1"
  m.D2 = "D2"
  m.D3 = "D3"
  m.D4 = "D4"

  s = {}
  s.allFx = "All Effects"
  s.avFx = "Available Effects"
  s.back = "Back"
  s.can = "Cancel"
  s.curIngr = "Current Ingredients"
  s.ex = "Exit"
  s.header = "Alchemy Helper"

  t = {}
  t.btn = 'b'
  t.txt = 't'


end


---------------------
-- Main Menu stuff --
---------------------
function this.createWindow() -- Create window and layout. Called by onCommand.
  hlog("this.createWindow()")

  if (tes3ui.findMenu(this.id.main.menu) ~= nil) then return end
  this.initIngrList()
  -- this.initAvailList()
  -- this.makeAvailStrings()

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



function this.mainCancelBtnPress(e) -- Cancel button callback.
    hlog("this.mainCancelBtnPress(e)")
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
function this.openFullFXMenu(e)
  hlog("this.openFullFXMenu(e)")
  if (tes3ui.findMenu(this.id.full.menu) ~= nil) then return end

  local ffxMenu = makeMenu(this.id.full.menu)
  local scrollBlock = ffxMenu:createBlock{}
  scrollBlock.autoWidth = true
  scrollBlock.autoHeight = true
  scrollBlock.paddingAllSides = 8

  local pane = newPane(scrollBlock, this.id.full.vScroll)
  makeFullFXList(pane)

  local btnBlock = newBlock(ffxMenu)
  local btnBack = makeClickable{parent = btnBlock, id = this.id.full.backBtn, text = s.back, pad = 8, fun = this.fullCancelBtnPress, color = c.red}

  ffxMenu:updateLayout()
  tes3ui.enterMenuMode(this.id.full.menu)
end

function this.fullCancelBtnPress(e) -- Cancel button callback.
  hlog("this.fullCancelBtnPress(e)")
  local ffxMenu = tes3ui.findMenu(this.id.full.menu)
  if (ffxMenu) then
      tes3ui.leaveMenuMode()
      ffxMenu:destroyChildren()
      ffxMenu:destroy()
  end
end

function this.fullSelectFx(e)
  hlog("this.fullSelectFx(e)")
  local ffxMenu = tes3ui.findMenu(this.id.full.menu)
  log("data: " .. ts(e.source))
end

function makeFullFXList(p)
    hlog("makeFullFXList(parent)")
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
function this.openAvailFXMenu(e)
  hlog("this.openAvailFXMenu(e)")
  if (tes3ui.findMenu(this.id.avail.menu) ~= nil) then return end

  local avMenu = makeMenu(this.id.avail.menu)
  local scrollBlock = avMenu:createBlock{}
  scrollBlock.autoWidth = true
  scrollBlock.autoHeight = true
  scrollBlock.paddingAllSides = 8

  local pane = newPane(scrollBlock, this.id.avail.vScroll)
  makeAvailList(pane)

  local btnBlock = newBlock(avMenu)
  local btnBack = makeClickable{parent = btnBlock, id = this.id.avail.backBtn, text = s.back, pad = 8, fun = this.availBackBtnPress, color = c.red}

  avMenu:updateLayout()
  pane.widget:contentsChanged()
  tes3ui.enterMenuMode(this.id.avail.menu)
end

function makeAvailList(p)
  hlog("makeAvailList(p)")
  for i,v in pairs(this.availFxItems) do
    local tmpId = tes3ui.registerID("af:AM_txt" .. ts(i))
    local txt = v
    local tmpTxt = makeClickable{parent = p, id = tmpId, text = txt, same = true, pad = 2}
    tmpTxt.autoWidth = true
    tmpTxt.widthProportional = 1.0
  end
end

function this.availBackBtnPress(e)
  hlog("this.availBackBtnPress(e)")
  local avMenu = tes3ui.findMenu(this.id.avail.menu)
  if (avMenu) then
      tes3ui.leaveMenuMode()
      avMenu:destroyChildren()
      avMenu:destroy()
  end
end


-------------------------------
-- List Initialization stuff --
-------------------------------
function this.initIngrList()
  hlog("this.initIngrList()")
  local inven = tes3.player.object.inventory
  for _, v in pairs(inven) do
      if (v.object.objectType == this.type.ingr) then
        table.insert(this.curIngr, v)
      end
  end
  this.initAvailList()
end

function this.makeAvailStrings()
  log("this.makeAvailStrings()")
  local tkeys = {}
  for k in pairs(this.availFx) do table.insert(tkeys, k) end
  table.sort(tkeys)
  for _, k in ipairs(tkeys) do
    local tmpStr = ts(k)
    for _, v in ipairs(this.availFx[k]) do
      tmpStr = tmpStr .. "\n\t- " .. ts(v)
    end
    table.insert(this.availFxItems, tmpStr)
  end
end

function this.initAvailList()
  local i = this.curIngr
  for index, val in ipairs(i) do
    local tmpFx = mkFxList(val.object.effects, val.object.effectAttributeIds, val.effectsSkillIds)
    iname = val.object.name
    for index2, val2 in ipairs(tmpFx) do
      if (val2 ~= "xx") then
        local fxp = fxIsPresent(this.availFx, (ts(val2)))
        fxid = ts(val2)
        if (not fxp) then --add
          this.availFx[fxid] = {iname}
          --table.insert(this.availFx, new)
        else
          table.insert(this.availFx[fxid], iname)
        end
      end
    end
  end
  this.makeAvailStrings()
end

function fxIsPresent(list, name)
  for i, v in pairs(list) do
    if (name == (ts(i))) then return true end
  end
  return false
end

function mkFxList(fxId, attribId, skillId)
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


----------------------------
-- Ingredients Menu stuff --
----------------------------
function this.openIngrMenu(e)
  hlog("this.openIngrMenu(e)")
  if (tes3ui.findMenu(this.id.ingr.menu) ~= nil) then return end

  --log("ingredients: ")
  for _,v in pairs(this.curIngr) do
    local fx = fxList(v.object.effects,v.object.effectAttributeIds, v.effectsSkillIds)
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

function this.ingrBackBtnPress(e)
  hlog("this.ingrBackBtnPress(e)")
  local ingrMenu = tes3ui.findMenu(this.id.ingr.menu)
  if (ingrMenu) then
    tes3ui.leaveMenuMode()
    ingrMenu:destroyChildren()
    ingrMenu:destroy()
  end
end

function makeIngrList(p)
  hlog("makeIngrList(parent)")
  for _,v in pairs(this.curIngr) do
    local tmpId = tes3ui.registerID("af:txt" .. ts(v.object.id))
    local txt = v.object.name
    local tmpTxt = makeClickable{parent = p, id = tmpId, text = txt, same = true, pad = 2}
    tmpTxt.autoWidth = true
    tmpTxt.widthProportional = 1.0
  end
end

function fxList(fxId, attribId, skillId)
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

-------------------------
-- General/misc. stuff --
-------------------------
function newBlock(m)
    hlog("newBlock(m)")
    local b = m:createBlock{}
    b.widthProportional = 1.0 -- width is 100% parent width
    b.autoHeight = true
    b.autoWidth = true
    b.childAlignX = 0.0
    b.paddingAllSides = 2
    return b
end

function makerHelper(data)
  if (data.type == t.btn) then return data.parent:createButton{id = data.id,  text = data.text}
  else return data.parent:createTextSelect{id = data.id,  text = data.text} end
end

function makeClickable(data)
  clk = makerHelper(data)
  local dc = data.color
  if (data.fun ~= nil) then clk:register(mc, data.fun) end
  if (dc ~= nil) then
    clk.color = dc; clk.widget.idle = dc; clk.widget.idleActive = dc; clk.widget.idleDisabled = c.dis; clk.widget.over = shift(dc, m.L2)
    clk.widget.overActive = shift(dc, m.L3); clk.widget.overDisabled = c.dis; clk.widget.pressed = shift(dc, m.L4); clk.widget.pressedActive = shift(dc, m.L4)
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

function rgbFloat(r,g,b) return {(r/255),(g/255),(b/255)} end

function shift(color, mode)
  local r,g,b = color[1], color[2], color[3]
  local l1, l2, l3, l4 = 0.08, 0.12, 0.2, 0.3
  local d1, d2, d3, d4 = -l1, -l2, -l3, -l4
  local diff = nil

  if (mode == m.L1) then diff = l1 end
  if (mode == m.L2) then diff = l2 end
  if (mode == m.L3) then diff = l3 end
  if (mode == m.L4) then diff = l4 end
  if (mode == m.D1) then diff = d1 end
  if (mode == m.D2) then diff = d2 end
  if (mode == m.D3) then diff = d3 end
  if (mode == m.D4) then diff = d4 end

  --log("original rgb: " .. ts(r) .. ", " .. ts(g) .. ", " .. ts(b) .. ". mode = " .. ts(mode))

  if ((r + diff) > 1.0) then r = 1.0 elseif ((r + diff) < 0.0) then r = 0.0 else r = r + diff end
  if ((g + diff) > 1.0) then g = 1.0 elseif ((g + diff) < 0.0) then g = 0.0 else g = g + diff end
  if ((b + diff) > 1.0) then b = 1.0 elseif ((b + diff) < 0.0) then b = 0.0 else b = b + diff end

  --log("changed rgb: " .. ts(r) .. ", " .. ts(g) .. ", " .. ts(b) .. ". mode = " .. ts(mode))
  return {r,g,b}

end

function makeMenu(mid)
  local menu = tes3ui.createMenu {id = mid, fixedFrame = true}
  menu.alpha = 1.0
  menu.paddingAllSides = 8
  menu.autoWidth = true
  menu.autoHeight = true
  return menu
end

function newPane(parent, pid)
  local pane = parent:createVerticalScrollPane{id = pid or nil}
  pane.positionY = 8
  pane.minWidth = 250
  pane.minHeight = 300
  pane.autoWidth = true
  pane.autoHeight = true
  return pane
end

function log(msg) mwse.log("[AF]          " .. msg) end

function hlog(msg) mwse.log("[AF] " ..  msg) end

function ts(val) return tostring(val) end








-----------------------------
-- Start, keydown callback --
-----------------------------
function this.onCommand(e)
    hlog("this.onCommand(e)")
    log("menumode: " .. (ts(tes3ui.menuMode())))
    if (tes3ui.menuMode()) then
      this.init()
      this.createWindow()
    end
end

function this.onPotionBrewed(e)
  hlog("this.onPotionBrewed(e)")
  if (tes3.menuMode()) then
    --this.initIngrList()


  end
end


event.register("initialized", this.init)
event.register("keyDown", this.onCommand, {filter = 54})
event.register("potionBrewed", this.onPotionBrewed)
