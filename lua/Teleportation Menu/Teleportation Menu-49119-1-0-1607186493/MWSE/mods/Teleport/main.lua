local this = {main = {}, go = {}, add = {}, del = {}}
local util, id = require("Teleport.util"), require("Teleport.id") -- imports
local HKEY = 54 -- 54 = right shift
local sf, ts = string.format, tostring -- aliases
local log, logf, hlog, hlogf, vlog, vlogf = util.log, util.logf, util.hlog, util.hlogf, util.vlog, util.vlogf -- logging aliases


--------------------------------------------------------------------------------
-- Direct children of 'this' --
--------------------------------------------------------------------------------
function this.init()
  hlog("init")
  this.markNames = {}
end

function this.nameList()
  local cfg = mwse.loadConfig("places")
  this.markNames = {}
  for k, v in pairs(cfg) do table.insert(this.markNames, v.name) end
end

--------------------------------------------------------------------------------
-- Main Menu stuff --
--------------------------------------------------------------------------------
-- start main menu
function this.main.launch()
  if (tes3ui.findMenu(id.main.menu) ~= nil) then return end

  local menu = util.makeMenu(id.main.menu)
  local mainLbl = menu:createLabel{text = "Fast Travel"}
  mainLbl.paddingAllSides = 4
  mainLbl.borderBottom = 4

  local goBlock = util.newBlock(menu)
  local goMenuBtn = util.makeClickable{parent = goBlock, id = id.main.goBtn, text = "Go Somewhere", pad = 4, fun = this.main.onGo}

  local addBlock = util.newBlock(menu)
  local addMenuBtn = util.makeClickable{parent = addBlock, id = id.main.addMarkBtn, text = "Add New Mark", pad = 4, fun = this.main.onAdd}

  local delBlock = util.newBlock(menu)
  local delMenuBtn = util.makeClickable{parent = delBlock, id = id.main.delMarkBtn, text = "Delete Mark", pad = 4, fun = this.main.onDel}

  local exitBlock = util.newBlock(menu)
  local exitBtn = util.makeClickable{parent = exitBlock, id = id.main.exitBtn, text = "Exit", pad = 4, fun = this.main.onExit, color = c.red}

  menu:updateLayout()
  tes3ui.enterMenuMode(id.main.menu)
end

-- handler for pressing the exit/cancel button in the main menu
function this.main.onExit(e)
    hlog("main exit")
    util.kill(id.main.menu)
end

function this.main.onGo(e)
  hlog("go click")
  this.go.launch()
end

function this.main.onAdd(e)
  hlog("add click")
  this.add.launch()
end

function this.main.onDel(e)
  hlog("del click")
  this.del.launch()
end

--------------------------------------------------------------------------------
-- Go menu stuff --
--------------------------------------------------------------------------------
function this.go.launch()
  hlog("go - launch menu")
  this.nameList()
  local menu = util.makeMenu(id.go.menu)
  local goLbl = menu:createLabel{text = "Select where to go"}; goLbl.borderBottom = 5

  local scrollBlock = util.newBlock(menu)
  local pane = util.newPane(scrollBlock, id.go.scroll)
  this.go.makeList(pane)

  local backBlock = util.newBlock(menu)
  local backBtn = util.makeClickable{parent = backBlock, id = id.go.backBtn, text = "Back", pad = 4, fun = this.go.onBack}

  menu:updateLayout()
  tes3ui.enterMenuMode(id.go.menu)
end

function this.go.makeList(p)
  table.sort(this.markNames)
  for index, val in ipairs(this.markNames) do
    local tmpId = tes3ui.registerID("goBtn:" .. val)
    local tmpTxt = val
    local tmpBtn = util.makeClickable{parent = p, id = tmpId, text = tmpTxt, pad = 2, fun = this.go.move}
    tmpBtn.autoWidth = true
    tmpBtn.widthProportional = 1.0
  end
end

function this.go.move(e)
  local parent = ts(e.source)
  local name = parent:gsub("goBtn:", "")
  logf("this.go.move called by %s, with location name %s", parent, name)
  local loc = this.go.markMatch(name)
  if (loc ~= nil) then
    local xx, yy, zz = loc.x, loc.y, loc.z
    if (loc.xn == true) then xx = (xx * -1) end
    if (loc.yn == true) then yy = (yy * -1) end
    if (loc.zn == true) then zz = (zz * -1) end
    mwscript.positionCell{reference = tes3.player, cell = loc.cid, x = xx, y = yy, z = zz}
  end

  util.kill(id.go.menu)
  util.kill(id.main.menu)

end

function this.go.markMatch(cname)
  local cfg = mwse.loadConfig("places")
  for k, v in pairs(cfg) do
    if (v.name == cname) then return v end
  end
  return nil
end

function this.go.onBack(e)
  hlog("go exit")
  util.kill(id.go.menu)
end


--------------------------------------------------------------------------------
-- Del menu stuff --
--------------------------------------------------------------------------------
function this.del.launch()
  this.nameList()
  hlog("del - launch menu")
  local menu = util.makeMenu(id.del.menu)
  local delLbl = menu:createLabel{text = "Select a mark to delete"}; delLbl.borderBottom = 5

  local scrollBlock = util.newBlock(menu)
  local pane = util.newPane(scrollBlock, id.del.scroll)
  this.del.makeList(pane)

  local backBlock = util.newBlock(menu)
  local backBtn = util.makeClickable{parent = backBlock, id = id.del.backBtn, text = "Back", pad = 4, fun = this.del.onBack}

  menu:updateLayout()
  tes3ui.enterMenuMode(id.del.menu)
end

function this.del.onBack(e)
  hlog("del exit")
  util.kill(id.del.menu)
end

function this.del.makeList(p)
  table.sort(this.markNames)
  for index, val in ipairs(this.markNames) do
    local tmpId = tes3ui.registerID("delBtn:" .. val)
    local tmpTxt = val
    local tmpBtn = util.makeClickable{parent = p, id = tmpId, text = tmpTxt, pad = 2, fun = this.del.remove}
    tmpBtn.autoWidth = true
    tmpBtn.widthProportional = 1.0
  end
end


function this.del.remove(e)
  hlog("this del remove")
  local parent = ts(e.source)
  local name = parent:gsub("delBtn:", "")
  local cfg = mwse.loadConfig("places")
  local newTable = {}
  for key, place in pairs(cfg) do
    if (val.place ~= name) then table.insert(newTable, place) end
  end
  mwse.saveConfig("places", newTable)
  util.kill(id.del.menu)
end

--------------------------------------------------------------------------------
-- Add Menu Stuff --
--------------------------------------------------------------------------------
function this.add.launch()
  hlog("add - launch menu")
  local menu = util.makeMenu(id.add.menu)
  local addLbl = menu:createLabel{text = "Add a new mark"}; addLbl.borderBottom = 5

  local txtBlock = menu:createBlock{}; txtBlock.width = 300; txtBlock.autoHeight = true; txtBlock.childAlignX = 0.5
  local tb = txtBlock:createThinBorder{}; tb.width = 300; tb.height = 30; tb.childAlignX = 0.5; tb.childAlignY = 0.5
  local input = tb:createTextInput{ id = id.add.input }; input.text = "Location Name"; input.borderLeft = 5; input.borderRight = 5; input.widget.lengthLimit = 31; input.widget.eraseOnFirstKey = true
  input:register("keyEnter", this.add.onOk)

  local btnBlock = util.newBlock(menu)
  local okBtn = util.makeClickable{parent = btnBlock, type = 'b', id = id.add.okBtn, text = "Ok", pad = 8, fun = this.add.onOk}
  local backBtn = util.makeClickable{parent = btnBlock, type = 'b', id = id.add.backBtn, text = "Back", pad = 8, fun = this.add.onBack}

  menu:updateLayout()
  tes3ui.enterMenuMode(id.add.menu)
  tes3ui.acquireTextInput(input)
end

function this.add.onOk(e)
  local menu = tes3ui.findMenu(id.add.menu)
  if (menu) then
    local name = menu:findChild(id.add.input).text
    logf("Input text: %s", name)
    this.add.updateCfg(name)
    util.kill(id.add.menu)
  end
end

function this.add.updateCfg(newName)
  local cell = tes3.getPlayerCell()
  local pos = tes3.player.position
  local newPlace = { actsAsExt = cell.behavesAsExterior,
                     cid = cell.id, indoors = cell.isInterior,
                     name = newName, region = cell.region,
                     x = util.pval(pos.x), xn = util.isNeg(pos.x),
                     y = util.pval(pos.y), yn = util.isNeg(pos.y),
                     z = util.pval(pos.z), zn = util.isNeg(pos.z) }
  local cfg = mwse.loadConfig("places")
  if (not (util.namePresent(cfg, newName))) then table.insert(cfg, newPlace) end
  mwse.saveConfig("places", cfg)
end

function this.add.onBack(e)
  hlog("add exit")
  util.kill(id.add.menu)
end

--------------------------------------------------------------------------------
-- Start, keydown callback --
--------------------------------------------------------------------------------
function this.onKeyDown(e)
    log("menumode: %s", (ts(tes3ui.menuMode())))
    if (not tes3ui.menuMode()) then
        this.init()
        this.main.launch()
      end
end

event.register("initialized", this.init)
event.register("keyDown", this.onKeyDown, {filter = HKEY})
