---@diagnostic disable: duplicate-set-field, duplicate-doc-field
local id = require("BeefStranger.UI Tweaks.ID")
---@class bs_UITweaks_Common
local bs = {
    UpdateBarter = "bsUpdateBarter",
    keyStillDown = "bsKeyStillDown"
}
---@return bsUITweaksPData playerData
function bs.initData()
    local data = tes3.player.data
    ---@class bsUITweaksPData
    data.UITweaks = data.UITweaks or {}
    data.UITweaks.lookedAt = data.UITweaks.lookedAt or {}
    return tes3.player.data.UITweaks
end

function bs.findText(element, string)
    for _, child in pairs(element.children) do
        local childText = child.text or ""
        if childText:lower():find(string:lower(), 1, true) then
            return child
        else
            if #child.children > 0 then
                local found = child:findText(string)
                if found then
                    return found
                end
            end
        end
    end
    return nil
end

---===================================
---===========tes3uiElement===========
---===================================

-------------------
---createPinButton
-------------------

---@class bs_tes3ui.createPinButton.params
---@field property string|nil? The Name of the Pinned Property (Defaults to "Menu_Pinned")

---Create a Pin/Unpin Button that toggles a Pinned Boolean Property
---@param params bs_tes3ui.createPinButton.params?
function tes3uiElement:bs_createPinButton(params)
  params = params or {}
  assert(type(params) == "table", "Invalid parameters provided.")
  local topLevel = self:getTopLevelMenu()
  local title = topLevel:findChild("PartDragMenu_title_tint")

  if not title then
    error("PartDragMenu_title_tint not found. This should be used on a dragFrame Menu.")
  end

  local property = params.property or "Menu_Pinned"

  ---Default to false
  topLevel:setPropertyBool(property, false)

  local button = title:createBlock({id = "Pin"})
  button.width = 16
  button.height = 16
  button.absolutePosAlignX = 0.99
  button.absolutePosAlignY = 0.50

  local pin = button:createNif({ id = "Pin_Button", path = "menu_rightbuttonup.NIF" })

  local unpin = button:createNif({ id = "Unpin_Button", path = "menu_rightbuttondown.NIF" })
  unpin.visible = false

  --- @param e tes3uiEventData
  local function onPinClick(e)
    e.source.visible = false
    unpin.visible = true
    topLevel:setPropertyBool(property, true)
  end

  --- @param e tes3uiEventData
  local function onUnpinClick(e)
    e.source.visible = false
    pin.visible = true
    topLevel:setPropertyBool(property, false)
  end

  pin:registerAfter(tes3.uiEvent.mouseClick, onPinClick)
  unpin:registerAfter(tes3.uiEvent.mouseClick, onUnpinClick)

  return button
end



---@class bs_tes3ui.drag.params
---@field id string|number
---@field modal boolean?
---@field loadable boolean?
---@field pinnable boolean?

---comments
---@param params bs_tes3ui.drag.params
function tes3ui.bs_createDragFixedFrame(params)
  params = params or {}
  params.id = params.id or "UNNAMED DRAGMENU"
  params.modal = params.modal or false
  params.loadable = (params.loadable == nil and true) or params.loadable
  params.pinnable = params.pinnable or false

  local menu = tes3ui.createMenu({ id = params.id, fixedFrame = true, modal = params.modal, loadable = params.loadable })
  menu.children[2]:destroy()
  menu.absolutePosAlignX = nil
  menu.absolutePosAlignY = nil
  menu.minHeight = 50
  menu.minWidth = 100
  menu.flowDirection = tes3.flowDirection.topToBottom

  menu.text = "BOOP"

  local block = menu:createBlock { id = "Body" }
  block:bs_autoSize(true)
  block.flowDirection = tes3.flowDirection.topToBottom

  local header = block:createRect({ id = "PartDragMenu_title_tint" })
  header.alpha = 0
  header.autoHeight = true
  header.childAlignY = 0.5
  header.widthProportional = 1

  local left = header:createNif({ id = "PartDragMenu_left_title_block", path = "menu_head_block.NIF" })
  left.heightProportional = 1
  left.widthProportional = 1

  local label = header:createLabel({ id = "PartDragMenu_title", text = menu.text })
  -- label:bs_autoSize(true)
  label.borderRight = 10
  label.borderLeft = 10
  label.borderBottom = 4

  local right = header:createNif({ id = "PartDragMenu_left_title_block", path = "menu_head_block.NIF" })
  right.widthProportional = 1
  right.heightProportional = 1

  if params.pinnable then
      header:bs_createPinButton()
  end

  local main = block:createBlock({ id = "Main Block" })
  menu:setPropertyProperty("shunt_children", "Main Block")
  main.widthProportional = 1
  main.heightProportional = 1
  main:bs_autoSize(true)
  main.borderAllSides = 4
  main.flowDirection = tes3.flowDirection.topToBottom

  ---I dont understand, chatGPT did, and it works
  local windowOffsetX, windowOffsetY = 0, 0

  local screenWidth, screenHeight = tes3ui.getViewportSize()

  header:register(tes3.uiEvent.mouseDown, function(e)
      tes3ui.captureMouseDrag(true)
      windowOffsetX = e.data0 - menu.positionX
      windowOffsetY = e.data1 - menu.positionY
  end)

  header:register(tes3.uiEvent.mouseStillPressed, function(e)
      menu.positionX = math.clamp((e.data0 - windowOffsetX), -(screenWidth / 2) + 2, (screenWidth / 2) - menu.width - 2)
      menu.positionY = math.clamp((e.data1 - windowOffsetY), (screenHeight / 2) - 2, -(screenHeight / 2) + menu.height + 2)
      menu:updateLayout()
  end)

  header:register(tes3.uiEvent.mouseRelease, function(e)
      tes3ui.captureMouseDrag(false)
  end)

  menu:registerAfter(tes3.uiEvent.preUpdate, function (e)
     label.text = e.source.text
  end)

  return menu
end
-------------------
---savePos
-------------------

---@class bs_tes3ui.savePos.params
---@field id string|number? The id to save position under (Default: menu.name)
---@field pinProperty string|nil? The Name of the Pinned Property if it exists (Default: "Menu_Pinned")

---An alternate to saveMenuPosition as it doesn't work on menu creation
---@param params bs_tes3ui.savePos.params?
function tes3uiElement:bs_savePos(params)
  local menu = self:getTopLevelMenu()
  params = params or {}
  params.id = params.id or menu.name
  params.pinProperty = params.pinProperty or "Menu_Pinned"
  -- pinProperty = pinProperty or "Menu_Pinned"
  local data = tes3.player.data
  data.bsMenuSave = data.bsMenuSave or {}
  local save = data.bsMenuSave
  local pinned = menu:getPropertyBool(params.pinProperty)

  save[params.id] = {menu.positionX, menu.positionY,  menu.width,  menu.height, pinned }
end
-------------------
---loadPos
-------------------

---@class bs_tes3ui.loadPos.params
---@field id string|number? The id to save position under (Default: menu.name)
---@field pinProperty string|nil? The Name of the Pinned Property if it exists (Default: "Menu_Pinned")

---An alternate to loadMenuPosition as it doesn't work on menu creation
---@param params bs_tes3ui.loadPos.params?
function tes3uiElement:bs_loadPos(params)
  -- pinProperty = pinProperty or "Menu_Pinned"
  local menu = self:getTopLevelMenu()
  params = params or {}
  params.id = params.id or menu.name
  params.pinProperty = params.pinProperty or "Menu_Pinned"
  if tes3.player.data.bsMenuSave then
    local save = tes3.player.data.bsMenuSave[params.id]
    if save then
      local x, y, w, h, p = table.unpack(save)
      menu.positionX = x
      menu.positionY = y
      menu.width = w
      menu.height = h
      if p then
        menu:setPropertyBool(params.pinProperty, p)
        menu:findChild("Pin").children[1].visible = false
        menu:findChild("Pin").children[2].visible = true
      end
    end
  end
end
-------------------
---holdClick
-------------------

---@class bs_tes3ui.holdClick.params
---@field triggerClick boolean? *Default `false`*: If `true` will trigger source mouseClick event
---@field playSound boolean? *Default `false`*: If `true` will play the tes3.worldController.menuClickSound sound
---@field skipFirstClick boolean? *Default `false`*: If `true` will skip first mouseClick trigger. Useful if interacting with mouse buttons
---@field startInterval number? *Default `0.5`*
---@field minInterval number? *Default `0.08`*
---@field accelerate boolean? *Default `true`*
---@field acceleration number? *Default `0.90`*. `1` if `accelerate` = `false`. Lower is faster
---@field keyControl boolean? *Default `false`*. If `true` registers a keyDown event for then skipFirstClick param. Unregisters on Element Destruction
---@field callback fun(e: tes3uiEventData)? *Optional* For if you want something to happen in the mouseStillPressed Event

---Registers a mouseStillPressed event that behaves similiarly to vanilla, where holding a button causes it to ramp up speed to a set limit
---@param params bs_tes3ui.holdClick.params
function tes3uiElement:bs_holdClick(params)
  params = params or {}
  params.keyControl = params.keyControl or false
  params.triggerClick = params.triggerClick or false
  params.skipFirstClick = (params.skipFirstClick == nil and true) or params.skipFirstClick
  params.startInterval = params.startInterval or 0.5
  params.minInterval = params.minInterval or 0.08
  params.playSound = params.playSound or false
  params.accelerate = params.accelerate or (params.accelerate == nil and true)
  params.acceleration = (params.accelerate and (params.acceleration or 0.90)) or 1

  local startTime = os.clock()
  local clickInterval = params.startInterval -- Initial interval (in seconds).
  local minInterval = params.minInterval     -- Minimum interval for maximum speed.
  local accelerationFactor = params.acceleration
  local currentInterval = clickInterval
  local firstClick = true

  if params.keyControl then
    local function keyDown()
      currentInterval = params.startInterval
      firstClick = true
    end
    event.register(tes3.event.keyDown, keyDown)

    self:registerAfter(tes3.uiEvent.destroy, function(e) event.unregister(tes3.event.keyDown, keyDown) end)
  end

  self:registerAfter(tes3.uiEvent.mouseDown, function(e)
    currentInterval = params.startInterval
    firstClick = true
  end)

  local function stillPressed(e)
    if os.clock() - startTime >= currentInterval then
      currentInterval = math.max(currentInterval * accelerationFactor, minInterval)
      startTime = os.clock()
      if params.triggerClick then
        if (params.skipFirstClick and not firstClick) or not params.skipFirstClick then
          self:triggerEvent(tes3.uiEvent.mouseClick)
        end
      end

      if (params.skipFirstClick and not firstClick) or not params.skipFirstClick then
        if params.playSound then tes3.playSound({ sound = tes3.worldController.menuClickSound }) end
      end

      if params.callback then params.callback(e) end
      firstClick = false
    end
  end
  self:registerAfter(tes3.uiEvent.mouseStillPressed, stillPressed)
end
-------------------
---hotkey
-------------------

---Add config.keybind.enable to your config to toggle functionality 
---@class bs_tes3ui.hotkey.params
---@field keyCode tes3.scanCode?
---@field isShiftDown boolean?
---@field isAltDown boolean?
---@field isControlDown boolean?
---configPath if you want to toggle keybinds off with a setting. Make sure to add `config.keybind.enable` to your config 
---
---Tip
-------
---Adding `configPath = "YourConfigName"` to your mwseKeyCombo lets you do button:bs_hotkey(config.buttonKeybind)
---@field configPath string? 


---comments
---@param params bs_tes3ui.hotkey.params
function tes3uiElement:bs_hotkey(params)
  params.keyCode = params.keyCode
  params.isShiftDown = params.isShiftDown or false
  params.isAltDown = params.isAltDown or false
  params.isControlDown = params.isControlDown or false
  local combo = { keyCode = params.keyCode, isShiftDown = params.isShiftDown, isAltDown = params.isAltDown, isControlDown = params.isControlDown }

  local cfg = (params.configPath and mwse.loadConfig(params.configPath)) or nil ---@type bsUITweaks.cfg|nil
  ---@param e keyDownEventData
  local function hotkey(e)
    if cfg and cfg.keybind and cfg.keybind.enable == false then return end ---Extra checks

    if tes3.isKeyEqual({ actual = e, expected = combo }) then
      self:bs_click({})
    end
  end
  event.register(tes3.event.keyDown, hotkey)

  self:registerBefore(tes3.uiEvent.destroy, function(e)
    event.unregister(tes3.event.keyDown, hotkey)
  end)
end
-------------------
---createClose
-------------------

---@class bs_tes3ui.createClose.param
---@field id string|number? Default: "Button_Close"
---@field text string? Default: "Cancel" `tes3.gmst.sCancel`
---@field leave boolean? Default: false. If true button will also leaveMenuMode

---Creates a `Close Button`. Registers the `mouseClick` event to destroy its topLevelMenu and optionally leaveMenuMode
---@param params bs_tes3ui.createClose.param
function tes3uiElement:bs_createClose(params)
  params = params or {}
  params.id = params.id or "Button_Close"
  params.text = params.text or tes3.findGMST(tes3.gmst.sCancel).value
  params.leave = params.leave or false

  local button = self:createButton({ id = params.id, text = params.text })

  button:registerAfter(tes3.uiEvent.mouseClick, function(e)
    e.source:getTopLevelMenu():destroy()
    if params.leave then tes3ui.leaveMenuMode() end
  end)

  return button
end
-------------------
---click
-------------------

---@class bs_tes3ui.click.params
---@field playSound boolean? `Default: true` Whether or not to play the menuClickSound
---@field sound string|tes3sound? *Optional*. Play a specific sound

---Triggers the mouseClick Event
---@param params bs_tes3ui.click.params?
function tes3uiElement:bs_click(params)
  params = params or {}
  -- debug.log(params.playSound)
  params.playSound = params.playSound or (params.playSound == nil and true)
  -- debug.log(params.playSound)
  if params.playSound then
      if params.sound then
          tes3.playSound({sound = params.sound})
      else
          tes3.playSound({sound = tes3.worldController.menuClickSound})
      end
  end
  self:triggerEvent(tes3.uiEvent.mouseClick)
end
-------------------
---autoSize
-------------------

---Quickly set autoHeight and autoWidth
---@param bool boolean true/false
function tes3uiElement:bs_autoSize(bool) self.autoHeight = bool self.autoWidth = bool end
-------------------
---scrollAutoSize
-------------------

---Makes autoWidth/Height Function with scroll lists. Disables width/heightProportional
function tes3uiElement:scrollAutoSize()
  self.heightProportional = nil
  self.widthProportional = nil
  self.autoWidth = true
  self.children[1].autoWidth = true
  self.children[1].children[1].autoWidth = true
  self.autoHeight = true
  self.children[1].autoHeight = true
  self.children[1].children[1].autoHeight = true
end
-------------------
---scrollAutoHeight
-------------------

---Makes autoHeight Function with scroll lists. Disables width/heightProportional
function tes3uiElement:bs_scrollAutoHeight()
  self.heightProportional = nil
  self.autoHeight = true
  self.children[1].autoHeight = true
  self.children[1].children[1].autoHeight = true
end
-------------------
---scrollAutoWidth
-------------------

---Makes autoWidth Function with scroll lists. Disables widthProportional
function tes3uiElement:bs_scrollAutoWidth()
  self.widthProportional = nil
  self.autoWidth = true
  self:findChild("PartScrollPane_outer_frame").autoWidth = true
  self:findChild("PartScrollPane_pane").autoWidth = true
end
-------------------
---Update
-------------------

---Updates the topLevelMenu
function tes3uiElement:bs_Update() self:getTopLevelMenu():updateLayout() end
-------------------
---isOnTop
-------------------

---Returns if menu is onTop, auto calls getTopLevelMenu()
---@return boolean isOnTop
function tes3uiElement:bs_isOnTop() return tes3ui.getMenuOnTop() == self:getTopLevelMenu() end
-------------------
---mouseDown
-------------------

---Triggers the mouseDown Event
function tes3uiElement:bs_mouseDown() self:triggerEvent(tes3.uiEvent.mouseDown) end
-------------------
---scrollChanged
-------------------

---Triggers the PartScrollBar_changed Event
function tes3uiElement:bs_scrollChanged() self:triggerEvent(tes3.uiEvent.partScrollBarChanged) end
-------------------
---triggerHold
-------------------

---Trigger mouseStillPressed
function tes3uiElement:bs_triggerHold() self:triggerEvent(tes3.uiEvent.mouseStillPressed) end
-------------------
---setObj
-------------------

---@class bs_tes3ui.setObj.params
---@field id string|number? *Optional* `Default: 'topLevelMenu.name'_Object`
---@field object tes3object

---@param params bs_tes3ui.setObj.params
function tes3uiElement:bs_setObj(params)
  params = params or {}
  params.id = params.id or self:getTopLevelMenu().name.."_Object"
  self:setPropertyObject(params.id, params.object)
end
-------------------
---setItemData
-------------------

---@class bs_tes3ui.setData.params
---@field id string|number? *Optional* `Default: 'topLevelMenu.name'_extra`
---@field data tes3itemData

---@param params bs_tes3ui.setData.params
function tes3uiElement:bs_setItemData(params)
  params = params or {}
  params.id = params.id or self:getTopLevelMenu().name.."_extra"
  self:setPropertyObject(params.id, params.data)
end
-------------------
---getObj
-------------------

---Returns Object of supplied propertyId. `Default ID: "'Menu.name'_Object"
---@param id string|number?
---@return tes3alchemy|tes3apparatus|tes3armor|tes3book|tes3clothing|tes3ingredient|tes3light|tes3lockpick|tes3misc|tes3probe|tes3repairTool|tes3spell|tes3weapon
function tes3uiElement:bs_getObj(id)
  id = id or self:getTopLevelMenu().name.."_Object"
  return self:getPropertyObject(id)
end
-------------------
---getItemData
-------------------

---Returns itemData of supplied propertyId. `Default ID: "'Menu.name'_extra"
---@param id string|number?
---@return tes3itemData itemData
function tes3uiElement:bs_getItemData(id)
  id = id or self:getTopLevelMenu().name.."_extra"
  return self:getPropertyObject(id, "tes3itemData")
end

-------------------
---Rename
-------------------

---Renames this element. The Elements ID changes as a result.
---@param name string The new name for this element.
function tes3uiElement:bs_Rename(name)
  self:setPropertyProperty("name", name)
end
-------------------
---findLastChild
-------------------

---Finds a child element matching the id argument. Searches children recursively. Returns the LAST child element with a matching id, or nil if no match found.
---@param id string|number The Name/ID of the child
---@return tes3uiElement|nil result The last found child or nil if none found
function tes3uiElement:bs_findLastChild(id)
  local regId = id
  local found = nil
  if type(id) == "string" then
      regId = tes3ui.registerID(id)
  end
  for child in table.traverse(self.children) do ---@param child tes3uiElement
      if regId == child.id then
          found = child
      end
  end
  return found
end

---===================================
---===========tes3uiElement===========
---===================================

---@class bs_tes3ui.notify.params
---@field id string|number? Default: `"bs_Notify"` helpLayerMenu ID
---@field text string? Default: `"No Notification Text Set"`
---@field success boolean? Default: `true` Determines Color
---@field successColor number[]? Default: `Green` An array of 3 numbers with values ranging from 0.0 to 1.0
---@field failureColor number[]? Default: `Red` An array of 3 numbers with values ranging from 0.0 to 1.0

---@param params bs_tes3ui.notify.params?
function bs.notify(params)
  params = params or {}
  params.id = params.id or "bs_Notify"
  params.text = params.text or "No Notification Text Set"
  params.success = params.success or false
  params.successColor = params.successColor or bs.rgb.bsPrettyGreen
  params.failureColor = params.failureColor or bs.rgb.bsNiceRed
  
  local notify = tes3ui.findHelpLayerMenu(params.id)
  if notify then
      notify:destroy()
  end

  local function menuTimer(t)
      local menu = tes3ui.findHelpLayerMenu(params.id)
      if menu then
          local msg = menu:findChild("msg")
          menu.positionY = menu.positionY + 1.5
          msg.alpha = msg.alpha - 0.03
          menu:updateLayout()
          if msg.alpha <= 0 then
              menu:destroy()
          end
      end
  end


  notify = tes3ui.createHelpLayerMenu({ id = params.id })
  notify.absolutePosAlignX = nil
  notify.absolutePosAlignY = nil
  notify.positionX = tes3.getCursorPosition().x - (notify.width / 2)
  notify.positionY = tes3.getCursorPosition().y + 30
  notify.children[2].contentPath = nil
  notify.alpha = 0
  local message = notify:createLabel({ id = "msg", text = params.text })
  message.color = params.success and params.successColor or params.failureColor

  local fadeTimer = timer.start({
      iterations = 50,
      duration = 0.03,
      callback = menuTimer,
      type = timer.real
  })
  notify:register(tes3.uiEvent.destroy, function()
      fadeTimer:cancel()
  end)
end

local prop = require("BeefStranger.UI Tweaks.property").embed

---@class bs_EmbededServices.updateList.params
---@field list tes3uiElement
---@field objProp string|number?
---@field propPrefix string
---@field dataProp string|number?
---@field costProp string|number?
---@field defaultState tes3.uiState
---@field service tes3.merchantService

---@param e bs_EmbededServices.updateList.params
function bs.updateList(e)
  local actor = tes3ui.getServiceActor()
  local willTrade = tes3.checkMerchantOffersService({ reference = actor, service = e.service })
  local title = e.list.parent:findChild(id.embed.title)
  for _, child in ipairs(e.list:getContentElement().children) do
      local spellObj = child:bs_getObj(prop[e.propPrefix.."_obj"])
      local itemData = child:bs_getItemData(prop[e.propPrefix.."_data"])
      local cost = tes3.calculatePrice({ merchant = actor, object = spellObj, itemData = (itemData and itemData) or nil })
      child:setPropertyInt(prop[e.propPrefix.."_cost"], cost)

      child:findChild(id.embed.price).text = cost .. "зол"
      local button = child:findChild(id.embed.button)
      if not willTrade or cost > tes3.getPlayerGold() then
          if not willTrade then title.color = bs.rgb.bsNiceRed end
          button.widget.state = tes3.uiState.disabled
          button.disabled = true
      else
          title.color = bs.rgb.headerColor
          button.widget.state = e.defaultState
          button.disabled = false
      end
  end
end


---@param npc tes3mobileNPC
---@param basePrice number
---@param buying boolean
function bs.barterOffer(npc, basePrice, buying)
  if npc.actorType == tes3.actorType.creature then return basePrice end

  local mercantileFix = tes3.hasCodePatchFeature(tes3.codePatchFeature.mercantileFix)
  local termMod = (mercantileFix and 0.25) or 0.50
  local clampedDisposition = math.clamp(math.floor(npc.object.disposition), 0, 100)

  local a = math.min(tes3.mobilePlayer.mercantile.current, 100)
  local b = math.min(0.1 * tes3.mobilePlayer.luck.current, 10)
  local c = math.min(0.2 * tes3.mobilePlayer.personality.current, 10)
  local d = math.min(npc.mercantile.current, 100)
  local e = math.min(0.1 * npc.luck.current, 10)
  local f = math.min(0.2 * npc.personality.current, 10)

  local pcTerm = (clampedDisposition - 50 + a + b + c) * tes3.mobilePlayer:getFatigueTerm()
  local npcTerm = (d + e + f) * npc:getFatigueTerm()
  local buyTerm = 0.01 * (100 - termMod * (pcTerm - npcTerm))
  local sellTerm = 0.01 * (50 - termMod * (npcTerm - pcTerm))

  local x
  local offerPrice

  if buying then x = buyTerm end

  if not buying then
      x = (mercantileFix and sellTerm) or math.min(buyTerm, sellTerm)
  end
  -- if not buying then x = math.min(buyTerm, sellTerm) end ---Vanilla

  if x < 1 then offerPrice = math.floor(x * basePrice) end
  if x >= 1 then offerPrice = basePrice + math.floor((x - 1) * basePrice) end
  offerPrice = math.max(1, offerPrice)
  return offerPrice
end


---@param id tes3.gmst
function bs.GMST(id)
  return tes3.findGMST(id).value
end

function bs.inspect(table)
  local inspect = require("inspect").inspect
  mwse.log("%s", inspect(table))
end

---@param colorATable mwseColorATable
---@return number[] rgb
---@return number alpha
function bs.color(colorATable)
  return { colorATable.r, colorATable.g, colorATable.b }, colorATable.a
end

---@param color number[]
---@param alpha number
---@return mwseColorATable
function bs.colorTable(color, alpha)
    return {r = color[1], g = color[2], b = color[3], a = alpha}
end

function bs.click()
    tes3.worldController.menuClickSound:play()
end

-- bs.menuClick = tes3.worldController.menuClickSound:play()

function bs.interpolateRGB(color1, color2, factor)
    local r = color1[1] + (color2[1] - color1[1]) * factor
    local g = color1[2] + (color2[2] - color1[2]) * factor
    local b = color1[3] + (color2[3] - color1[3]) * factor
    return { r, g, b }
end

function bs.keybind(keybind) return tes3.worldController.inputController:isKeyDown(keybind.keyCode) end

---@param scanCode tes3.scanCode
function bs.isKeyDown(scanCode) return tes3.worldController.inputController:isKeyDown(scanCode) end

bs.menus = {
  Alchemy = "MenuAlchemy",
  Attributes = "MenuAttributes",
  AttributesList = "MenuAttributesList",
  Audio = "MenuAudio",
  Barter = "MenuBarter",
  BirthSign = "MenuBirthSign",
  Book = "MenuBook",
  ChooseClass = "MenuChooseClass",
  ClassChoice = "MenuClassChoice",
  ClassMessage = "MenuClassMessage",
  Console = "MenuConsole",
  Contents = "MenuContents",
  CreateClass = "MenuCreateClass",
  Ctrls = "MenuCtrls",
  Dialog = "MenuDialog",
  Enchantment = "MenuEnchantment",
  Input = "MenuInput",
  InputSave = "MenuInputSave",
  Inventory = "MenuInventory",
  InventorySelect = "MenuInventorySelect",
  Journal = "MenuJournal",
  LevelUp = "MenuLevelUp",
  Load = "MenuLoad",
  Loading = "MenuLoading",
  Magic = "MenuMagic",
  MagicSelect = "MenuMagicSelect",
  Map = "MenuMap",
  MapNoteEdit = "MenuMapNoteEdit",
  Message = "MenuMessage",
  Multi = "MenuMulti",
  Name = "MenuName",
  Notify1 = "MenuNotify1",
  Notify2 = "MenuNotify2",
  Notify3 = "MenuNotify3",
  Options = "MenuOptions",
  Persuasion = "MenuPersuasion",
  Prefs = "MenuPrefs",
  Quantity = "MenuQuantity",
  Quick = "MenuQuick",
  RaceSex = "MenuRaceSex",
  Repair = "MenuRepair",
  RestWait = "MenuRestWait",
  Save = "MenuSave",
  Scroll = "MenuScroll",
  ServiceRepair = "MenuServiceRepair",
  ServiceSpells = "MenuServiceSpells",
  ServiceTraining = "MenuServiceTraining",
  ServiceTravel = "MenuServiceTravel",
  SetValues = "MenuSetValues",
  Skills = "MenuSkills",
  SkillsList = "MenuSkillsList",
  Specialization = "MenuSpecialization",
  Spellmaking = "MenuSpellmaking",
  Stat = "MenuStat",
  StatReview = "MenuStatReview",
  SwimFillBar = "MenuSwimFillBar",
  TimePass = "MenuTimePass",
  Topic = "MenuTopic",
  Video = "MenuVideo",
  MCM = "MWSE:ModConfigMenu",
}


bs.rgb = {
  bsPrettyBlue = { 0.235, 0.616, 0.949 },
  bsNiceRed = { 0.941, 0.38, 0.38 },
  bsPrettyGreen = { 0.38, 0.941, 0.525 },
  bsLightGrey = { 0.839, 0.839, 0.839 },
  bsRoyalPurple = { 0.714, 0.039, 0.902 },
  activeColor = { 0.37647062540054, 0.43921571969986, 0.79215693473816 },
  activeOverColor = { 0.6235294342041, 0.66274511814117, 0.87450987100601 },
  activePressedColor = { 0.87450987100601, 0.88627457618713, 0.95686280727386 },
  answerColor = { 0.58823531866074, 0.19607844948769, 0.11764706671238 },
  answerOverColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
  answerPressedColor = { 0.95294123888016, 0.92941182851791, 0.8666667342186 },
  backgroundColor = { 0, 0, 0 },
  bigAnswerColor = { 0.58823531866074, 0.19607844948769, 0.11764706671238 },
  bigAnswerOverColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
  bigAnswerPressedColor = { 0.95294123888016, 0.92941182851791, 0.086274512112141 },
  bigHeaderColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
  bigLinkColor = { 0.43921571969986, 0.49411767721176, 0.8117647767067 },
  bigLinkOverColor = { 0.56078433990479, 0.60784316062927, 0.85490202903748 },
  bigLinkPressedColor = { 0.68627452850342, 0.72156864404678, 0.89411771297455 },
  bigNormalColor = { 0.79215693473816, 0.64705884456635, 0.37647062540054 },
  bigNormalOverColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
  bigNormalPressedColor = { 0.95294123888016, 0.92941182851791, 0.8666667342186 },
  bigNotifyColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
  blackColor = { 0, 0, 0 },
  countColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
  disabledColor = { 0.70196080207825, 0.65882354974747, 0.52941179275513 },
  disabledOverColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
  disabledPressedColor = { 0.95294123888016, 0.92941182851791, 0.8666667342186 },
  fatigueColor = { 0, 0.58823531866074, 0.23529413342476 },
  focusColor = { 0.3137255012989, 0.3137255012989, 0.3137255012989 },
  headerColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
  healthColor = { 0.78431379795074, 0.23529413342476, 0.11764706671238 },
  healthNpcColor = { 1, 0.7294117808342, 0 },
  journalFinishedQuestColor = { 0.23529413342476, 0.23529413342476, 0.23529413342476 },
  journalFinishedQuestOverColor = { 0.39215689897537, 0.39215689897537, 0.39215689897537 },
  journalFinishedQuestPressedColor = { 0.86274516582489, 0.86274516582489, 0.86274516582489 },
  journalLinkColor = { 0.14509804546833, 0.19215688109398, 0.43921571969986 },
  journalLinkOverColor = { 0.22745099663734, 0.30196079611778, 0.68627452850342 },
  journalLinkPressedColor = { 0.43921571969986, 0.49411767721176, 0.8117647767067 },
  journalTopicColor = { 0, 0, 0 },
  journalTopicOverColor = { 0.22745099663734, 0.30196079611778, 0.68627452850342 },
  journalTopicPressedColor = { 0.43921571969986, 0.49411767721176, 0.8117647767067 },
  linkColor = { 0.43921571969986, 0.49411767721176, 0.8117647767067 },
  linkOverColor = { 0.56078433990479, 0.60784316062927, 0.85490202903748 },
  linkPressedColor = { 0.68627452850342, 0.72156864404678, 0.89411771297455 },
  magicColor = { 0.20784315466881, 0.27058824896812, 0.6235294342041 },
  magicFillColor = { 0.78431379795074, 0.23529413342476, 0.11764706671238 },
  miscColor = { 0, 0.80392163991928, 0.80392163991928 },
  negativeColor = { 0.78431379795074, 0.23529413342476, 0.11764706671238 },
  normalColor = { 0.79215693473816, 0.64705884456635, 0.37647062540054 },
  normalOverColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
  normalPressedColor = { 0.95294123888016, 0.92941182851791, 0.8666667342186 },
  notifyColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
  positiveColor = { 0.87450987100601, 0.78823536634445, 0.6235294342041 },
  weaponFillColor = { 0.78431379795074, 0.23529413342476, 0.11764706671238 },
  whiteColor = { 1, 1, 1 }
}

bs.textures = {
  amulet_heartfire = "Textures\\amulet_heartfire.tga",
  compass = "Textures\\compass.tga",
  cursor_drop = "Textures\\cursor_drop.tga",
  cursor_drop_ground = "Textures\\cursor_drop_ground.tga",
  detect_animal_icon = "Textures\\detect_animal_icon.tga",
  detect_enchantment_icon = "Textures\\detect_enchantment_icon.tga",
  detect_key_icon = "Textures\\detect_key_icon.tga",
  door_icon = "Textures\\door_icon.tga",
  ["enviro 01"] = "Textures\\enviro 01.tga",
  mapfowtexture = "Textures\\mapfowtexture.tga",
  menu_bar_blue = "Textures\\menu_bar_blue.tga",
  menu_bar_gray = "Textures\\menu_bar_gray.tga",
  menu_bar_green = "Textures\\menu_bar_green.tga",
  menu_bar_red = "Textures\\menu_bar_red.tga",
  menu_bar_yellow = "Textures\\menu_bar_yellow.tga",
  menu_button_frame_bottom = "Textures\\menu_button_frame_bottom.tga",
  menu_button_frame_bottom_left_corner = "Textures\\menu_button_frame_bottom_left_corner.tga",
  menu_button_frame_bottom_right_corner = "Textures\\menu_button_frame_bottom_right_corner.tga",
  menu_button_frame_left = "Textures\\menu_button_frame_left.tga",
  menu_button_frame_right = "Textures\\menu_button_frame_right.tga",
  menu_button_frame_top = "Textures\\menu_button_frame_top.tga",
  menu_button_frame_top_left_corner = "Textures\\menu_button_frame_top_left_corner.tga",
  menu_button_frame_top_right_corner = "Textures\\menu_button_frame_top_right_corner.tga",
  menu_compass_large = "Textures\\menu_compass_large.tga",
  menu_credits = "Textures\\menu_credits.tga",
  menu_credits_over = "Textures\\menu_credits_over.tga",
  menu_credits_pressed = "Textures\\menu_credits_pressed.tga",
  menu_divider = "Textures\\menu_divider.tga",
  menu_exitgame = "Textures\\menu_exitgame.tga",
  menu_exitgame_over = "Textures\\menu_exitgame_over.tga",
  menu_exitgame_pressed = "Textures\\menu_exitgame_pressed.tga",
  menu_head_block_bottom = "Textures\\menu_head_block_bottom.tga",
  menu_head_block_bottom_left_corner = "Textures\\menu_head_block_bottom_left_corner.tga",
  menu_head_block_bottom_right_corner = "Textures\\menu_head_block_bottom_right_corner.tga",
  menu_head_block_left = "Textures\\menu_head_block_left.tga",
  menu_head_block_middle = "Textures\\menu_head_block_middle.tga",
  menu_head_block_right = "Textures\\menu_head_block_right.tga",
  menu_head_block_top = "Textures\\menu_head_block_top.tga",
  menu_head_block_top_left_corner = "Textures\\menu_head_block_top_left_corner.tga",
  menu_head_block_top_right_corner = "Textures\\menu_head_block_top_right_corner.tga",
  menu_icon_barter = "Textures\\menu_icon_barter.tga",
  menu_icon_equip = "Textures\\menu_icon_equip.tga",
  menu_icon_frame_bottom = "Textures\\menu_icon_frame_bottom.tga",
  menu_icon_frame_left = "Textures\\menu_icon_frame_left.tga",
  menu_icon_frame_right = "Textures\\menu_icon_frame_right.tga",
  menu_icon_frame_top = "Textures\\menu_icon_frame_top.tga",
  menu_icon_magic = "Textures\\menu_icon_magic.tga",
  menu_icon_magic_barter = "Textures\\menu_icon_magic_barter.tga",
  menu_icon_magic_equip = "Textures\\menu_icon_magic_equip.tga",
  menu_icon_magic_mini = "Textures\\menu_icon_magic_mini.tga",
  menu_icon_none = "Textures\\menu_icon_none.tga",
  menu_icon_select_magic = "Textures\\menu_icon_select_magic.tga",
  menu_icon_select_magic_magic = "Textures\\menu_icon_select_magic_magic.tga",
  menu_loadgame = "Textures\\menu_loadgame.tga",
  menu_loadgame_over = "Textures\\menu_loadgame_over.tga",
  menu_loadgame_pressed = "Textures\\menu_loadgame_pressed.tga",
  menu_map_dcreature = "Textures\\menu_map_dcreature.tga",
  menu_map_dkey = "Textures\\menu_map_dkey.tga",
  menu_map_dmagic = "Textures\\menu_map_dmagic.tga",
  menu_map_smark = "Textures\\menu_map_smark.tga",
  menu_morrowind = "Textures\\menu_morrowind.tga",
  menu_newgame = "Textures\\menu_newgame.tga",
  menu_newgame_over = "Textures\\menu_newgame_over.tga",
  menu_newgame_pressed = "Textures\\menu_newgame_pressed.tga",
  menu_number_dec = "Textures\\menu_number_dec.tga",
  menu_number_inc = "Textures\\menu_number_inc.tga",
  menu_off_dot = "Textures\\menu_off_dot.tga",
  menu_on_dot = "Textures\\menu_on_dot.tga",
  menu_options = "Textures\\menu_options.tga",
  menu_options_over = "Textures\\menu_options_over.tga",
  menu_options_pressed = "Textures\\menu_options_pressed.tga",
  menu_return = "Textures\\menu_return.tga",
  menu_return_over = "Textures\\menu_return_over.tga",
  menu_return_pressed = "Textures\\menu_return_pressed.tga",
  menu_rightbuttondown_bottom = "Textures\\menu_rightbuttondown_bottom.tga",
  menu_rightbuttondown_bottom_left = "Textures\\menu_rightbuttondown_bottom_left.tga",
  menu_rightbuttondown_bottom_right = "Textures\\menu_rightbuttondown_bottom_right.tga",
  menu_rightbuttondown_center = "Textures\\menu_rightbuttondown_center.tga",
  menu_rightbuttondown_left = "Textures\\menu_rightbuttondown_left.tga",
  menu_rightbuttondown_right = "Textures\\menu_rightbuttondown_right.tga",
  menu_rightbuttondown_top = "Textures\\menu_rightbuttondown_top.tga",
  menu_rightbuttondown_top_left = "Textures\\menu_rightbuttondown_top_left.tga",
  menu_rightbuttondown_top_right = "Textures\\menu_rightbuttondown_top_right.tga",
  menu_rightbuttonup_bottom = "Textures\\menu_rightbuttonup_bottom.tga",
  menu_rightbuttonup_bottom_left = "Textures\\menu_rightbuttonup_bottom_left.tga",
  menu_rightbuttonup_bottom_right = "Textures\\menu_rightbuttonup_bottom_right.tga",
  menu_rightbuttonup_center = "Textures\\menu_rightbuttonup_center.tga",
  menu_rightbuttonup_left = "Textures\\menu_rightbuttonup_left.tga",
  menu_rightbuttonup_right = "Textures\\menu_rightbuttonup_right.tga",
  menu_rightbuttonup_top = "Textures\\menu_rightbuttonup_top.tga",
  menu_rightbuttonup_top_left = "Textures\\menu_rightbuttonup_top_left.tga",
  menu_rightbuttonup_top_right = "Textures\\menu_rightbuttonup_top_right.tga",
  menu_savegame = "Textures\\menu_savegame.tga",
  menu_savegame_over = "Textures\\menu_savegame_over.tga",
  menu_savegame_pressed = "Textures\\menu_savegame_pressed.tga",
  menu_scroll_arrow = "Textures\\menu_scroll_arrow.tga",
  menu_scroll_bar_hor = "Textures\\menu_scroll_bar_hor.tga",
  menu_scroll_bar_vert = "Textures\\menu_scroll_bar_vert.tga",
  menu_scroll_button_bottom = "Textures\\menu_scroll_button_bottom.tga",
  menu_scroll_button_top = "Textures\\menu_scroll_button_top.tga",
  menu_scroll_button_vert = "Textures\\menu_scroll_button_vert.tga",
  menu_scroll_down = "Textures\\menu_scroll_down.tga",
  menu_scroll_elevator = "Textures\\menu_scroll_elevator.tga",
  menu_scroll_hortbar_bottom = "Textures\\menu_scroll_hortbar_bottom.tga",
  menu_scroll_hortbar_top = "Textures\\menu_scroll_hortbar_top.tga",
  menu_scroll_hortbar_vert = "Textures\\menu_scroll_hortbar_vert.tga",
  menu_scroll_left = "Textures\\menu_scroll_left.tga",
  menu_scroll_right = "Textures\\menu_scroll_right.tga",
  menu_scroll_scroller_bottom = "Textures\\menu_scroll_scroller_bottom.tga",
  menu_scroll_scroller_middle = "Textures\\menu_scroll_scroller_middle.tga",
  menu_scroll_scroller_top = "Textures\\menu_scroll_scroller_top.tga",
  menu_scroll_up = "Textures\\menu_scroll_up.tga",
  menu_scroll_vertbar_bottom = "Textures\\menu_scroll_vertbar_bottom.tga",
  menu_scroll_vertbar_top = "Textures\\menu_scroll_vertbar_top.tga",
  menu_scroll_vertbar_vert = "Textures\\menu_scroll_vertbar_vert.tga",
  menu_size_button = "Textures\\menu_size_button.tga",
  menu_small_energy_bar_bottom = "Textures\\menu_small_energy_bar_bottom.tga",
  menu_small_energy_bar_top = "Textures\\menu_small_energy_bar_top.tga",
  menu_small_energy_bar_vert = "Textures\\menu_small_energy_bar_vert.tga",
  menu_thick_border_bottom = "Textures\\menu_thick_border_bottom.tga",
  menu_thick_border_bottom_left_corner = "Textures\\menu_thick_border_bottom_left_corner.tga",
  menu_thick_border_bottom_right_corner = "Textures\\menu_thick_border_bottom_right_corner.tga",
  menu_thick_border_left = "Textures\\menu_thick_border_left.tga",
  menu_thick_border_right = "Textures\\menu_thick_border_right.tga",
  menu_thick_border_top = "Textures\\menu_thick_border_top.tga",
  menu_thick_border_top_left_corner = "Textures\\menu_thick_border_top_left_corner.tga",
  menu_thick_border_top_right_corner = "Textures\\menu_thick_border_top_right_corner.tga",
  menu_thin_border_bottom = "Textures\\menu_thin_border_bottom.tga",
  menu_thin_border_bottom_left_corner = "Textures\\menu_thin_border_bottom_left_corner.tga",
  menu_thin_border_bottom_right_corner = "Textures\\menu_thin_border_bottom_right_corner.tga",
  menu_thin_border_left = "Textures\\menu_thin_border_left.tga",
  menu_thin_border_right = "Textures\\menu_thin_border_right.tga",
  menu_thin_border_top = "Textures\\menu_thin_border_top.tga",
  menu_thin_border_top_left_corner = "Textures\\menu_thin_border_top_left_corner.tga",
  menu_thin_border_top_right_corner = "Textures\\menu_thin_border_top_right_corner.tga",
  scroll = "Textures\\scroll.tga",
  target = "Textures\\target.tga",
  tx_a_glass_emerald = "Textures\\tx_a_glass_emerald.tga",
  tx_ashl_lantern_01 = "Textures\\tx_ashl_lantern_01.tga",
  tx_ashl_lantern_02 = "Textures\\tx_ashl_lantern_02.tga",
  tx_ashl_lantern_03 = "Textures\\tx_ashl_lantern_03.tga",
  tx_ashl_lantern_04 = "Textures\\tx_ashl_lantern_04.tga",
  tx_ashl_lantern_05 = "Textures\\tx_ashl_lantern_05.tga",
  tx_ashl_lantern_06 = "Textures\\tx_ashl_lantern_06.tga",
  tx_ashl_lantern_07 = "Textures\\tx_ashl_lantern_07.tga",
  tx_banner_hlaalu_01 = "Textures\\tx_banner_hlaalu_01.tga",
  tx_banner_redoran_01 = "Textures\\tx_banner_redoran_01.tga",
  tx_banner_temple_01 = "Textures\\tx_banner_temple_01.tga",
  tx_banner_temple_02 = "Textures\\tx_banner_temple_02.tga",
  tx_banner_temple_03 = "Textures\\tx_banner_temple_03.tga",
  tx_bannerd_alchemy_01 = "Textures\\tx_bannerd_alchemy_01.tga",
  tx_bannerd_clothing_01 = "Textures\\tx_bannerd_clothing_01.tga",
  tx_bannerd_danger_01 = "Textures\\tx_bannerd_danger_01.tga",
  tx_bannerd_goods_01 = "Textures\\tx_bannerd_goods_01.tga",
  tx_bannerd_tavern_01 = "Textures\\tx_bannerd_tavern_01.tga",
  tx_bannerd_w_a_shop_01 = "Textures\\tx_bannerd_w_a_shop_01.tga",
  tx_bannerd_welcome_01 = "Textures\\tx_bannerd_welcome_01.tga",
  tx_block_adobe_brown_02 = "Textures\\tx_block_adobe_brown_02.tga",
  tx_block_adobe_redbrown_01 = "Textures\\tx_block_adobe_redbrown_01.tga",
  tx_block_adobe_white_01 = "Textures\\tx_block_adobe_white_01.tga",
  tx_block_metal_gold_01 = "Textures\\tx_block_metal_gold_01.tga",
  tx_c_robecommon03a_c_beltbutton = "Textures\\tx_c_robecommon03a_c_beltbutton.tga",
  tx_c_robecommon03b_c_jewel = "Textures\\tx_c_robecommon03b_c_jewel.tga",
  tx_c_robeextra01_c_jewel = "Textures\\tx_c_robeextra01_c_jewel.tga",
  tx_c_robeextra01r_c_jewel = "Textures\\tx_c_robeextra01r_c_jewel.tga",
  tx_c_robeextra01t_c_jewel = "Textures\\tx_c_robeextra01t_c_jewel.tga",
  tx_c_t_akatosh_01 = "Textures\\tx_c_t_akatosh_01.tga",
  tx_c_t_apprentice_01 = "Textures\\tx_c_t_apprentice_01.tga",
  tx_c_t_arkay_01 = "Textures\\tx_c_t_arkay_01.tga",
  tx_c_t_dibella_01 = "Textures\\tx_c_t_dibella_01.tga",
  tx_c_t_golem_01 = "Textures\\tx_c_t_golem_01.tga",
  tx_c_t_julianos_01 = "Textures\\tx_c_t_julianos_01.tga",
  tx_c_t_kynareth_01 = "Textures\\tx_c_t_kynareth_01.tga",
  tx_c_t_lady_01 = "Textures\\tx_c_t_lady_01.tga",
  tx_c_t_lord_01 = "Textures\\tx_c_t_lord_01.tga",
  tx_c_t_lover_01 = "Textures\\tx_c_t_lover_01.tga",
  tx_c_t_mara_01 = "Textures\\tx_c_t_mara_01.tga",
  tx_c_t_ritual_01 = "Textures\\tx_c_t_ritual_01.tga",
  tx_c_t_shadow_01 = "Textures\\tx_c_t_shadow_01.tga",
  tx_c_t_steed_01 = "Textures\\tx_c_t_steed_01.tga",
  tx_c_t_stendarr_01 = "Textures\\tx_c_t_stendarr_01.tga",
  tx_c_t_thief_01 = "Textures\\tx_c_t_thief_01.tga",
  tx_c_t_tower_01 = "Textures\\tx_c_t_tower_01.tga",
  tx_c_t_warrior_01 = "Textures\\tx_c_t_warrior_01.tga",
  tx_c_t_wizard_01 = "Textures\\tx_c_t_wizard_01.tga",
  tx_c_t_zenithar_01 = "Textures\\tx_c_t_zenithar_01.tga",
  tx_creature_goldsipder04 = "Textures\\tx_creature_goldsipder04.tga",
  tx_crystal_01 = "Textures\\tx_crystal_01.tga",
  tx_crystal_02 = "Textures\\tx_crystal_02.tga",
  tx_crystal_03 = "Textures\\tx_crystal_03.tga",
  tx_de_banner_ald_velothi = "Textures\\tx_de_banner_ald_velothi.tga",
  tx_de_banner_book_01 = "Textures\\tx_de_banner_book_01.tga",
  tx_de_banner_gnaar_mok = "Textures\\tx_de_banner_gnaar_mok.tga",
  tx_de_banner_hla_oad = "Textures\\tx_de_banner_hla_oad.tga",
  tx_de_banner_khull = "Textures\\tx_de_banner_khull.tga",
  tx_de_banner_pawn_01 = "Textures\\tx_de_banner_pawn_01.tga",
  tx_de_banner_sadrith_mora = "Textures\\tx_de_banner_sadrith_mora.tga",
  tx_de_banner_tel_aruhn = "Textures\\tx_de_banner_tel_aruhn.tga",
  tx_de_banner_tel_branora = "Textures\\tx_de_banner_tel_branora.tga",
  tx_de_banner_tel_fyr = "Textures\\tx_de_banner_tel_fyr.tga",
  tx_de_banner_tel_mora = "Textures\\tx_de_banner_tel_mora.tga",
  tx_de_banner_tel_vos = "Textures\\tx_de_banner_tel_vos.tga",
  tx_de_banner_telvani_01 = "Textures\\tx_de_banner_telvani_01.tga",
  tx_de_banner_vos = "Textures\\tx_de_banner_vos.tga",
  tx_default = "Textures\\tx_default.tga",
  tx_dwrv_golem10 = "Textures\\tx_dwrv_golem10.tga",
  tx_dwrv_golem20 = "Textures\\tx_dwrv_golem20.tga",
  tx_dwrv_obs_sky00 = "Textures\\tx_dwrv_obs_sky00.tga",
  tx_emerald00 = "Textures\\tx_emerald00.tga",
  tx_fabric_tapestry = "Textures\\tx_fabric_tapestry.tga",
  tx_fabric_tapestry_01 = "Textures\\tx_fabric_tapestry_01.tga",
  tx_fabric_tapestry_02 = "Textures\\tx_fabric_tapestry_02.tga",
  tx_fabric_tapestry_03 = "Textures\\tx_fabric_tapestry_03.tga",
  tx_fabric_tapestry_04 = "Textures\\tx_fabric_tapestry_04.tga",
  tx_flag_imp_01 = "Textures\\tx_flag_imp_01.tga",
  tx_fresco_exodus_01 = "Textures\\tx_fresco_exodus_01.tga",
  tx_fresco_newtribunal_01 = "Textures\\tx_fresco_newtribunal_01.tga",
  tx_frost_salt_01 = "Textures\\tx_frost_salt_01.tga",
  tx_gem_diamond_01 = "Textures\\tx_gem_diamond_01.tga",
  tx_gem_emerald_01 = "Textures\\tx_gem_emerald_01.tga",
  tx_gem_pearl_01 = "Textures\\tx_gem_pearl_01.tga",
  tx_gem_rawebony = "Textures\\tx_gem_rawebony.tga",
  tx_gem_ruby_01 = "Textures\\tx_gem_ruby_01.tga",
  tx_gg_fence_01 = "Textures\\tx_gg_fence_01.tga",
  tx_gg_fence_02 = "Textures\\tx_gg_fence_02.tga",
  tx_longboatsail02 = "Textures\\tx_longboatsail02.tga",
  tx_menu_4x4white = "Textures\\tx_menu_4x4white.tga",
  tx_menu_8x8black = "Textures\\tx_menu_8x8black.tga",
  tx_menu_8x8grad = "Textures\\tx_menu_8x8grad.tga",
  tx_menubook = "Textures\\tx_menubook.tga",
  tx_menubook_bookmark = "Textures\\tx_menubook_bookmark.tga",
  tx_menubook_cancel_idle = "Textures\\tx_menubook_cancel_idle.tga",
  tx_menubook_cancel_over = "Textures\\tx_menubook_cancel_over.tga",
  tx_menubook_cancel_pressed = "Textures\\tx_menubook_cancel_pressed.tga",
  tx_menubook_close_idle = "Textures\\tx_menubook_close_idle.tga",
  tx_menubook_close_over = "Textures\\tx_menubook_close_over.tga",
  tx_menubook_close_pressed = "Textures\\tx_menubook_close_pressed.tga",
  tx_menubook_journal_idle = "Textures\\tx_menubook_journal_idle.tga",
  tx_menubook_journal_over = "Textures\\tx_menubook_journal_over.tga",
  tx_menubook_journal_pressed = "Textures\\tx_menubook_journal_pressed.tga",
  tx_menubook_next_idle = "Textures\\tx_menubook_next_idle.tga",
  tx_menubook_next_over = "Textures\\tx_menubook_next_over.tga",
  tx_menubook_next_pressed = "Textures\\tx_menubook_next_pressed.tga",
  tx_menubook_options_idle = "Textures\\tx_menubook_options_idle.tga",
  tx_menubook_options_over = "Textures\\tx_menubook_options_over.tga",
  tx_menubook_options_pressed = "Textures\\tx_menubook_options_pressed.tga",
  tx_menubook_prev_idle = "Textures\\tx_menubook_prev_idle.tga",
  tx_menubook_prev_over = "Textures\\tx_menubook_prev_over.tga",
  tx_menubook_prev_pressed = "Textures\\tx_menubook_prev_pressed.tga",
  tx_menubook_quests_active_idle = "Textures\\tx_menubook_quests_active_idle.tga",
  tx_menubook_quests_active_over = "Textures\\tx_menubook_quests_active_over.tga",
  tx_menubook_quests_active_pressed = "Textures\\tx_menubook_quests_active_pressed.tga",
  tx_menubook_quests_all_idle = "Textures\\tx_menubook_quests_all_idle.tga",
  tx_menubook_quests_all_over = "Textures\\tx_menubook_quests_all_over.tga",
  tx_menubook_quests_all_pressed = "Textures\\tx_menubook_quests_all_pressed.tga",
  tx_menubook_quests_idle = "Textures\\tx_menubook_quests_idle.tga",
  tx_menubook_quests_over = "Textures\\tx_menubook_quests_over.tga",
  tx_menubook_quests_pressed = "Textures\\tx_menubook_quests_pressed.tga",
  tx_menubook_take_idle = "Textures\\tx_menubook_take_idle.tga",
  tx_menubook_take_over = "Textures\\tx_menubook_take_over.tga",
  tx_menubook_take_pressed = "Textures\\tx_menubook_take_pressed.tga",
  tx_menubook_topics_idle = "Textures\\tx_menubook_topics_idle.tga",
  tx_menubook_topics_over = "Textures\\tx_menubook_topics_over.tga",
  tx_menubook_topics_pressed = "Textures\\tx_menubook_topics_pressed.tga",
  tx_misc_lantern_paper_01 = "Textures\\tx_misc_lantern_paper_01.tga",
  tx_misc_lantern_paper_02 = "Textures\\tx_misc_lantern_paper_02.tga",
  tx_misc_lantern_paper_03 = "Textures\\tx_misc_lantern_paper_03.tga",
  tx_misc_lantern_paper_04 = "Textures\\tx_misc_lantern_paper_04.tga",
  tx_misc_lantern_paper_05 = "Textures\\tx_misc_lantern_paper_05.tga",
  tx_mooncircle_full_m = "Textures\\tx_mooncircle_full_m.tga",
  tx_mooncircle_full_s = "Textures\\tx_mooncircle_full_s.tga",
  tx_mooncircle_half_wan_m = "Textures\\tx_mooncircle_half_wan_m.tga",
  tx_mooncircle_half_wan_s = "Textures\\tx_mooncircle_half_wan_s.tga",
  tx_mooncircle_half_wax_m = "Textures\\tx_mooncircle_half_wax_m.tga",
  tx_mooncircle_half_wax_s = "Textures\\tx_mooncircle_half_wax_s.tga",
  tx_mooncircle_new = "Textures\\tx_mooncircle_new.tga",
  tx_mooncircle_one_wan_m = "Textures\\tx_mooncircle_one_wan_m.tga",
  tx_mooncircle_one_wan_s = "Textures\\tx_mooncircle_one_wan_s.tga",
  tx_mooncircle_one_wax_m = "Textures\\tx_mooncircle_one_wax_m.tga",
  tx_mooncircle_one_wax_s = "Textures\\tx_mooncircle_one_wax_s.tga",
  tx_mooncircle_three_wan_m = "Textures\\tx_mooncircle_three_wan_m.tga",
  tx_mooncircle_three_wan_s = "Textures\\tx_mooncircle_three_wan_s.tga",
  tx_mooncircle_three_wax_m = "Textures\\tx_mooncircle_three_wax_m.tga",
  tx_mooncircle_three_wax_s = "Textures\\tx_mooncircle_three_wax_s.tga",
  tx_redoran_floor_01 = "Textures\\tx_redoran_floor_01.tga",
  tx_redoran_hut_00 = "Textures\\tx_redoran_hut_00.tga",
  tx_redoran_marble_red = "Textures\\tx_redoran_marble_red.tga",
  tx_redoran_marble_white = "Textures\\tx_redoran_marble_white.tga",
  tx_ring00 = "Textures\\tx_ring00.tga",
  tx_ring10 = "Textures\\tx_ring10.tga",
  tx_saint_aralor_01 = "Textures\\tx_saint_aralor_01.tga",
  tx_saint_deyln_01 = "Textures\\tx_saint_deyln_01.tga",
  tx_saint_felms_01 = "Textures\\tx_saint_felms_01.tga",
  tx_saint_llothis_01 = "Textures\\tx_saint_llothis_01.tga",
  tx_saint_meris_01 = "Textures\\tx_saint_meris_01.tga",
  tx_saint_nerevar_01 = "Textures\\tx_saint_nerevar_01.tga",
  tx_saint_olms_01 = "Textures\\tx_saint_olms_01.tga",
  tx_saint_relms_01 = "Textures\\tx_saint_relms_01.tga",
  tx_saint_rilms_01 = "Textures\\tx_saint_rilms_01.tga",
  tx_saint_roris_01 = "Textures\\tx_saint_roris_01.tga",
  tx_saint_seryn_01 = "Textures\\tx_saint_seryn_01.tga",
  tx_saint_veloth_01 = "Textures\\tx_saint_veloth_01.tga",
  tx_saint_vivec_01 = "Textures\\tx_saint_vivec_01.tga",
  tx_scroll_bar = "Textures\\tx_scroll_bar.tga",
  tx_scroll_button = "Textures\\tx_scroll_button.tga",
  tx_scroll_close = "Textures\\tx_scroll_close.tga",
  tx_scroll_fleur = "Textures\\tx_scroll_fleur.tga",
  tx_scroll_take = "Textures\\tx_scroll_take.tga",
  tx_sign_alchemy_01 = "Textures\\tx_sign_alchemy_01.tga",
  tx_sign_arms_01 = "Textures\\tx_sign_arms_01.tga",
  tx_sign_clothing_01 = "Textures\\tx_sign_clothing_01.tga",
  tx_sign_goods_01 = "Textures\\tx_sign_goods_01.tga",
  tx_sign_guild_fight_01 = "Textures\\tx_sign_guild_fight_01.tga",
  tx_sign_guild_mage_01 = "Textures\\tx_sign_guild_mage_01.tga",
  tx_sign_inn_01 = "Textures\\tx_sign_inn_01.tga",
  tx_sign_pawn_01 = "Textures\\tx_sign_pawn_01.tga",
  tx_signpost_wood_01 = "Textures\\tx_signpost_wood_01.tga",
  tx_soulgem_common = "Textures\\tx_soulgem_common.tga",
  tx_soulgem_grand = "Textures\\tx_soulgem_grand.tga",
  tx_soulgem_greater = "Textures\\tx_soulgem_greater.tga",
  tx_soulgem_lesser = "Textures\\tx_soulgem_lesser.tga",
  tx_soulgem_petty = "Textures\\tx_soulgem_petty.tga",
  tx_stars = "Textures\\tx_stars.tga",
  tx_stars_mage = "Textures\\tx_stars_mage.tga",
  tx_stars_nebula = "Textures\\tx_stars_nebula.tga",
  tx_stars_nebula2 = "Textures\\tx_stars_nebula2.tga",
  tx_stars_nebula3 = "Textures\\tx_stars_nebula3.tga",
  tx_stars_thief = "Textures\\tx_stars_thief.tga",
  tx_stars_warrior = "Textures\\tx_stars_warrior.tga",
  tx_steam_centurions_35 = "Textures\\tx_steam_centurions_35.tga",
  tx_sun_05 = "Textures\\tx_sun_05.tga",
  tx_sun_flash_grey_05 = "Textures\\tx_sun_flash_grey_05.tga",
  tx_w_crystal_blade = "Textures\\tx_w_crystal_blade.tga",
  tx_w_dwemer_deco = "Textures\\tx_w_dwemer_deco.tga",
  tx_w_magnus03 = "Textures\\tx_w_magnus03.tga",
  tx_wall_workedstone_01 = "Textures\\tx_wall_workedstone_01.tga",
  tx_wax_aqua_02 = "Textures\\tx_wax_aqua_02.tga",
  tx_wax_black_01 = "Textures\\tx_wax_black_01.tga",
  tx_wax_green_01 = "Textures\\tx_wax_green_01.tga",
  tx_wax_green_02 = "Textures\\tx_wax_green_02.tga",
  tx_wax_green_03 = "Textures\\tx_wax_green_03.tga",
  tx_wax_purple_01 = "Textures\\tx_wax_purple_01.tga",
  tx_wax_red_02 = "Textures\\tx_wax_red_02.tga",
  tx_wg_cobblestones_01 = "Textures\\tx_wg_cobblestones_01.tga",
  tx_wg_road_01 = "Textures\\tx_wg_road_01.tga",
  tx_wheat00 = "Textures\\tx_wheat00.tga",
  tx_wood_cherry = "Textures\\tx_wood_cherry.tga",
  tx_wood_cherryfaded = "Textures\\tx_wood_cherryfaded.tga",
  tx_wood_cherryplanks = "Textures\\tx_wood_cherryplanks.tga",
  tx_wood_wethered = "Textures\\tx_wood_wethered.tga",
  tx_wood_wormridden = "Textures\\tx_wood_wormridden.tga",
  tx_wood_wornfloor_01 = "Textures\\tx_wood_wornfloor_01.tga",
  tx_woodfloor_brown = "Textures\\tx_woodfloor_brown.tga",
  vfx_crystal = "Textures\\vfx_crystal.tga",
  vfx_icecrystal02 = "Textures\\vfx_icecrystal02.tga",
  vfx_icestar = "Textures\\vfx_icestar.tga",
  vfx_ill_flare01 = "Textures\\vfx_ill_flare01.tga",
  vfx_lightningrod = "Textures\\vfx_lightningrod.tga",
  vfx_lightningrod02 = "Textures\\vfx_lightningrod02.tga",
  vfx_lightningrod03 = "Textures\\vfx_lightningrod03.tga",
  vfx_lightningrod04 = "Textures\\vfx_lightningrod04.tga",
  vfx_lightningrod05 = "Textures\\vfx_lightningrod05.tga",
  vfx_myst_glow = "Textures\\vfx_myst_glow.tga",
  vfx_rest_glow = "Textures\\vfx_rest_glow.tga",
  vfx_restbolt = "Textures\\vfx_restbolt.tga",
  vfx_restore_glow = "Textures\\vfx_restore_glow.tga",
  vfx_spark = "Textures\\vfx_spark.tga",
  vfx_star02 = "Textures\\vfx_star02.tga",
  vfx_star_blue = "Textures\\vfx_star_blue.tga",
  vfx_starglow = "Textures\\vfx_starglow.tga",
  vfx_starspike = "Textures\\vfx_starspike.tga",
  vfx_summon = "Textures\\vfx_summon.tga",
  vfx_summon_glow = "Textures\\vfx_summon_glow.tga",
  vfx_tgtdmg = "Textures\\vfx_tgtdmg.tga",
  vfx_whitestar = "Textures\\vfx_whitestar.tga",
  vfx_whitestar02 = "Textures\\vfx_whitestar02.tga"
}

bs.sound = {
  alitMOAN = "alitMOAN",
  alitROAR = "alitROAR",
  alitSCRM = "alitSCRM",
  Alma_att0 = "Alma_att0",
  Alma_att1 = "Alma_att1",
  Alma_att2 = "Alma_att2",
  Alma_hit0 = "Alma_hit0",
  Alma_hit1 = "Alma_hit1",
  Alma_hit2 = "Alma_hit2",
  alteration_area = "alteration area",
  alteration_bolt = "alteration bolt",
  alteration_cast = "alteration cast",
  alteration_hit = "alteration hit",
  Ambient_Factory_Ruins = "Ambient Factory Ruins",
  ancestor_ghost_moan = "ancestor ghost moan",
  ancestor_ghost_roar = "ancestor ghost roar",
  ancestor_ghost_scream = "ancestor ghost scream",
  animalLARGEleft = "animalLARGEleft",
  animalLARGEright = "animalLARGEright",
  animalSMALLleft = "animalSMALLleft",
  animalSMALLright = "animalSMALLright",
  ash_ghoul_moan = "ash ghoul moan",
  ash_ghoul_roar = "ash ghoul roar",
  ash_ghoul_scream = "ash ghoul scream",
  ash_slave_moan = "ash slave moan",
  ash_slave_roar = "ash slave roar",
  ash_slave_scream = "ash slave scream",
  ash_vampire_moan = "ash vampire moan",
  ash_vampire_roar = "ash vampire roar",
  ash_vampire_scream = "ash vampire scream",
  ash_zombie_moan = "ash zombie moan",
  ash_zombie_roar = "ash zombie roar",
  ash_zombie_scream = "ash zombie scream",
  Ashstorm = "Ashstorm",
  atroflame_moan = "atroflame moan",
  atroflame_roar = "atroflame roar",
  atroflame_scream = "atroflame scream",
  atrofrost_moan = "atrofrost moan",
  atrofrost_roar = "atrofrost roar",
  atrofrost_scream = "atrofrost scream",
  atrostorm_moan = "atrostorm moan",
  atrostorm_roar = "atrostorm roar",
  atrostorm_scream = "atrostorm scream",
  bear_moan = "bear moan",
  bear_roar = "bear roar",
  bear_scream = "bear scream",
  bearsniff = "bearsniff",
  bell1 = "bell1",
  bell2 = "bell2",
  bell3 = "bell3",
  bell4 = "bell4",
  bell5 = "bell5",
  bell6 = "bell6",
  blackoutin = "blackoutin",
  Blight = "Blight",
  BM_big_fire = "BM big fire",
  BM_Blizzard = "BM Blizzard",
  BM_Ice_Sheet = "BM_Ice_Sheet",
  BM_Nord_attack = "BM Nord attack",
  BM_Nord_attackF = "BM Nord attackF",
  BM_pipe_large = "BM pipe large",
  BM_pipe_medium = "BM pipe medium",
  BM_pipe_small = "BM pipe small",
  BM_Sun = "BM Sun",
  BM_Wilderness = "BM Wilderness",
  BM_Wilderness2 = "BM Wilderness2",
  BM_Wilderness3 = "BM Wilderness3",
  BM_Wind = "BM Wind",
  boar_moan = "boar moan",
  boar_roar = "boar roar",
  boar_scream = "boar scream",
  boarsniff = "boarsniff",
  Boat_Creak = "Boat Creak",
  boat_docked = "boat docked",
  Boat_Hull = "Boat Hull",
  Body_Fall_Large = "Body Fall Large",
  Body_Fall_Medium = "Body Fall Medium",
  Body_Fall_Small = "Body Fall Small",
  bonelord_moan = "bonelord moan",
  bonelord_roar = "bonelord roar",
  bonelord_scream = "bonelord scream",
  bonewalkerMOAN = "bonewalkerMOAN",
  bonewalkerROAR = "bonewalkerROAR",
  bonewalkerSCRM = "bonewalkerSCRM",
  bonewalkerWAR_moan = "bonewalkerWAR moan",
  bonewalkerWAR_roar = "bonewalkerWAR roar",
  bonewalkerWAR_scream = "bonewalkerWAR scream",
  book_close = "book close",
  book_open = "book open",
  book_page = "book page",
  book_page2 = "book page2",
  bowPull = "bowPull",
  bowShoot = "bowShoot",
  Bubbles = "Bubbles",
  Cave_Drip = "Cave Drip",
  Cave_Waterfall = "Cave_Waterfall",
  Cave_Wind = "Cave Wind",
  cavein = "cavein",
  cent_proj_moan = "cent proj moan",
  cent_proj_roar = "cent proj roar",
  cent_proj_scream = "cent proj scream",
  cent_proj_shoot = "cent proj shoot",
  cent_sphere_moan = "cent sphere moan",
  cent_sphere_roar = "cent sphere roar",
  cent_sphere_scream = "cent sphere scream",
  cent_spider_moan = "cent spider moan",
  cent_spider_roar = "cent spider roar",
  cent_spider_scream = "cent spider scream",
  cent_steam_fall = "cent steam fall",
  cent_steam_moan = "cent steam moan",
  cent_steam_roar = "cent steam roar",
  cent_steam_scream = "cent steam scream",
  chest_close = "chest close",
  chest_open = "chest open",
  chimes_wood = "chimes wood",
  clannfear_moan = "clannfear moan",
  clannfear_roar = "clannfear roar",
  clannfear_scream = "clannfear scream",
  cliff_racer_moan = "cliff racer moan",
  cliff_racer_roar = "cliff racer roar",
  cliff_racer_scream = "cliff racer scream",
  conjuration_area = "conjuration area",
  conjuration_bolt = "conjuration bolt",
  conjuration_cast = "conjuration cast",
  conjuration_hit = "conjuration hit",
  corpDRAG = "corpDRAG",
  corpus_stalker_moan = "corpus stalker moan",
  corpus_stalker_roar = "corpus stalker roar",
  corpus_stalker_scream = "corpus stalker scream",
  corpuslameMOAN = "corpuslameMOAN",
  corpuslameROAR = "corpuslameROAR",
  corpuslameSCRM = "corpuslameSCRM",
  Creeky_Wood = "Creeky Wood",
  critical_damage = "critical damage",
  crossbowPull = "crossbowPull",
  crossbowShoot = "crossbowShoot",
  crowd_booing = "crowd booing",
  CrowdBoo = "CrowdBoo",
  Crystal_Ringing = "Crystal Ringing",
  Daedric_Chant = "Daedric Chant",
  daedroth_moan = "daedroth moan",
  daedroth_roar = "daedroth roar",
  daedroth_scream = "daedroth scream",
  Dagoth_Ur_Moan = "Dagoth Ur Moan",
  Dagoth_Ur_Scream = "Dagoth Ur Scream",
  Default_Moan = "Default Moan",
  Default_Roar = "Default Roar",
  Default_Scream = "Default Scream",
  DefaultLand = "DefaultLand",
  DefaultLandWater = "DefaultLandWater",
  destruction_area = "destruction area",
  destruction_bolt = "destruction bolt",
  destruction_cast = "destruction cast",
  destruction_hit = "destruction hit",
  Disarm_Trap = "Disarm Trap",
  Disarm_Trap_Fail = "Disarm Trap Fail",
  Dock_Creak = "Dock Creak",
  Door_Creaky_Close = "Door Creaky Close",
  Door_Creaky_Open = "Door Creaky Open",
  Door_Heavy_Close = "Door Heavy Close",
  Door_Heavy_Open = "Door Heavy Open",
  Door_Latched_One_Close = "Door Latched One Close",
  Door_Latched_One_Open = "Door Latched One Open",
  Door_Latched_Two_Close = "Door Latched Two Close",
  Door_Latched_Two_Open = "Door Latched Two Open",
  Door_Metal_Close = "Door Metal Close",
  Door_Metal_Open = "Door Metal Open",
  Door_Stone_Close = "Door Stone Close",
  Door_Stone_Open = "Door Stone Open",
  dremora_moan = "dremora moan",
  dremora_roar = "dremora roar",
  dremora_scream = "dremora scream",
  dreugh_moan = "dreugh moan",
  dreugh_roar = "dreugh roar",
  dreugh_scream = "dreugh scream",
  drgr_moan = "drgr moan",
  drgr_roar = "drgr roar",
  drgr_scream = "drgr scream",
  Drink = "Drink",
  drown = "drown",
  drowning_damage = "drowning damage",
  dwarven_ghost_moan = "dwarven ghost moan",
  dwarven_ghost_roar = "dwarven ghost roar",
  dwarven_ghost_scream = "dwarven ghost scream",
  Dwe_waterfall = "Dwe_waterfall",
  Dwemer_Door_Close = "Dwemer Door Close",
  Dwemer_Door_Open = "Dwemer Door Open",
  Dwemer_Fan = "Dwemer Fan",
  enchant_fail = "enchant fail",
  enchant_success = "enchant success",
  endboom1 = "endboom1",
  endboom2 = "endboom2",
  endboom3 = "endboom3",
  endboom4 = "endboom4",
  endrumble = "endrumble",
  FabBossAlive = "FabBossAlive",
  FabBossClank = "FabBossClank",
  fabBossDead = "fabBossDead",
  FabBossGyro = "FabBossGyro",
  FabBossHit = "FabBossHit",
  fabBossLeft = "fabBossLeft",
  fabBossRight = "fabBossRight",
  FabBossRoar = "FabBossRoar",
  FabBossWhir = "FabBossWhir",
  FabHulkLeft = "FabHulkLeft",
  fabHulkMoan = "fabHulkMoan",
  FabHulkRight = "FabHulkRight",
  fabHulkRoar = "fabHulkRoar",
  fabHulkScream = "fabHulkScream",
  fabVermLeft = "fabVermLeft",
  fabVermMoan = "fabVermMoan",
  fabVermRight = "fabVermRight",
  fabVermRoar = "fabVermRoar",
  fabVermScream = "fabVermScream",
  Fire = "Fire",
  Fire_40 = "Fire 40",
  Fire_50 = "Fire 50",
  Flag = "Flag",
  Flies = "Flies",
  FootBareLeft = "FootBareLeft",
  FootBareRight = "FootBareRight",
  FootHeavyLeft = "FootHeavyLeft",
  FootHeavyRight = "FootHeavyRight",
  FootLightLeft = "FootLightLeft",
  FootLightRight = "FootLightRight",
  FootMedLeft = "FootMedLeft",
  FootMedRight = "FootMedRight",
  FootWaterLeft = "FootWaterLeft",
  FootWaterRight = "FootWaterRight",
  forcefield = "forcefield",
  frgiant_moan = "frgiant moan",
  frgiant_roar = "frgiant roar",
  frgiant_scream = "frgiant scream",
  frgtLeft = "frgtLeft",
  frgtRight = "frgtRight",
  frost_area = "frost area",
  frost_bolt = "frost_bolt",
  frost_cast = "frost_cast",
  frost_hit = "frost_hit",
  Gate_Large_Locked = "Gate Large Locked",
  ghostgate_sound = "ghostgate sound",
  goblin_large_moan = "goblin large moan",
  goblin_large_roar = "goblin large roar",
  goblin_large_scream = "goblin large scream",
  goblin_moan = "goblin moan",
  goblin_roar = "goblin roar",
  goblin_scream = "goblin scream",
  gold_saint_moan = "gold saint moan",
  gold_saint_roar = "gold saint roar",
  gold_saint_scream = "gold saint scream",
  gren_moan = "gren moan",
  gren_roar = "gren roar",
  gren_scream = "gren scream",
  greneat = "greneat",
  guar_moan = "guar moan",
  guar_roar = "guar roar",
  guar_scream = "guar scream",
  Hand_To_Hand_Hit = "Hand To Hand Hit",
  Hand_to_Hand_Hit_2 = "Hand to Hand Hit 2",
  Haunted = "Haunted",
  Health_Damage = "Health Damage",
  Heart = "Heart",
  heartdead = "heartdead",
  hearthit1 = "hearthit1",
  hearthit2 = "hearthit2",
  hearthit3 = "hearthit3",
  hearthit4 = "hearthit4",
  heartsunder = "heartsunder",
  Heavy_Armor_Hit = "Heavy Armor Hit",
  hirc_moan = "hirc moan",
  hirc_roar = "hirc roar",
  hirc_scream = "hirc scream",
  howl1 = "howl1",
  howl2 = "howl2",
  howl3 = "howl3",
  howl4 = "howl4",
  howl5 = "howl5",
  howl6 = "howl6",
  howl7 = "howl7",
  howl8 = "howl8",
  hrkLeft = "hrkLeft",
  hrkr_moan = "hrkr moan",
  hrkr_roar = "hrkr roar",
  hrkr_scream = "hrkr scream",
  hrkrbellow = "hrkrbellow",
  hrkRight = "hrkRight",
  ice_troll_moan = "ice troll moan",
  ice_troll_roar = "ice troll roar",
  ice_troll_scream = "ice troll scream",
  illusion_area = "illusion area",
  illusion_bolt = "illusion bolt",
  illusion_cast = "illusion cast",
  illusion_hit = "illusion hit",
  Item_Ammo_Down = "Item Ammo Down",
  Item_Ammo_Up = "Item Ammo Up",
  Item_Apparatus_Down = "Item Apparatus Down",
  Item_Apparatus_Up = "Item Apparatus Up",
  Item_Armor_Heavy_Down = "Item Armor Heavy Down",
  Item_Armor_Heavy_Up = "Item Armor Heavy Up",
  Item_Armor_Light_Down = "Item Armor Light Down",
  Item_Armor_Light_Up = "Item Armor Light Up",
  Item_Armor_Medium_Down = "Item Armor Medium Down",
  Item_Armor_Medium_Up = "Item Armor Medium Up",
  Item_Bodypart_Down = "Item Bodypart Down",
  Item_Bodypart_Up = "Item Bodypart Up",
  Item_Book_Down = "Item Book Down",
  Item_Book_Up = "Item Book Up",
  Item_Clothes_Down = "Item Clothes Down",
  Item_Clothes_Up = "Item Clothes Up",
  Item_Gold_Down = "Item Gold Down",
  Item_Gold_Up = "Item Gold Up",
  Item_Ingredient_Down = "Item Ingredient Down",
  Item_Ingredient_Up = "Item Ingredient Up",
  Item_Lockpick_Down = "Item Lockpick Down",
  Item_Lockpick_Up = "Item Lockpick Up",
  Item_Misc_Down = "Item Misc Down",
  Item_Misc_Up = "Item Misc Up",
  Item_Potion_Down = "Item Potion Down",
  Item_Potion_Up = "Item Potion Up",
  Item_Probe_Down = "Item Probe Down",
  Item_Probe_Up = "Item Probe Up",
  Item_Repair_Down = "Item Repair Down",
  Item_Repair_Up = "Item Repair Up",
  Item_Ring_Down = "Item Ring Down",
  Item_Ring_Up = "Item Ring Up",
  Item_Weapon_Blunt_Down = "Item Weapon Blunt Down",
  Item_Weapon_Blunt_Up = "Item Weapon Blunt Up",
  Item_Weapon_Bow_Down = "Item Weapon Bow Down",
  Item_Weapon_Bow_Up = "Item Weapon Bow Up",
  Item_Weapon_Crossbow_Down = "Item Weapon Crossbow Down",
  Item_Weapon_Crossbow_Up = "Item Weapon Crossbow Up",
  Item_Weapon_Longblade_Down = "Item Weapon Longblade Down",
  Item_Weapon_Longblade_Up = "Item Weapon Longblade Up",
  Item_Weapon_Shortblade_Down = "Item Weapon Shortblade Down",
  Item_Weapon_Shortblade_Up = "Item Weapon Shortblade Up",
  Item_Weapon_Spear_Down = "Item Weapon Spear Down",
  Item_Weapon_Spear_Up = "Item Weapon Spear Up",
  kagouti_moan = "kagouti moan",
  kagouti_roar = "kagouti roar",
  kagouti_scream = "kagouti scream",
  kwama_forager_slither = "kwama forager slither",
  kwamaF_left = "kwamaF left",
  kwamaF_right = "kwamaF right",
  kwamF_moan = "kwamF moan",
  kwamF_roar = "kwamF roar",
  kwamF_scream = "kwamF scream",
  kwamQ_moan = "kwamQ moan",
  kwamQ_roar = "kwamQ roar",
  kwamQ_scream = "kwamQ scream",
  kwamWK_moan = "kwamWK moan",
  kwamWK_roar = "kwamWK roar",
  kwamWK_scream = "kwamWK scream",
  kwamWR_moan = "kwamWR moan",
  kwamWR_roar = "kwamWR roar",
  kwamWR_scream = "kwamWR scream",
  Lava_Layer = "Lava Layer",
  LeftL = "LeftL",
  LeftM = "LeftM",
  LeftS = "LeftS",
  lich_lord_moan = "lich lord moan",
  lich_lord_roar = "lich lord roar",
  lich_lord_scream = "lich lord scream",
  Light_Armor_Hit = "Light Armor Hit",
  LockedChest = "LockedChest",
  LockedDoor = "LockedDoor",
  Machinery = "Machinery",
  magic_sound = "magic sound",
  Medium_Armor_Hit = "Medium Armor Hit",
  Menu_Click = "Menu Click",
  Menu_Size = "Menu Size",
  miss = "miss",
  MournDayAmb = "MournDayAmb",
  MournGates = "MournGates",
  MournGatesClose = "MournGatesClose",
  MournNightAmb = "MournNightAmb",
  MournSpray = "MournSpray",
  MournTempleAmb = "MournTempleAmb",
  mud_bubbles = "mud bubbles",
  mudcrab_moan = "mudcrab moan",
  mudcrab_roar = "mudcrab roar",
  mudcrab_scream = "mudcrab scream",
  mysticism_area = "mysticism area",
  mysticism_bolt = "mysticism bolt",
  mysticism_cast = "mysticism cast",
  mysticism_hit = "mysticism hit",
  netchBET_moan = "netchBET moan",
  netchBET_roar = "netchBET roar",
  netchBET_scream = "netchBET scream",
  netchBUL_moan = "netchBUL moan",
  netchBUL_roar = "netchBUL roar",
  netchBUL_scream = "netchBUL scream",
  nix_hound_moan = "nix hound moan",
  nix_hound_roar = "nix hound roar",
  nix_hound_scream = "nix hound scream",
  ogrim_moan = "ogrim moan",
  ogrim_roar = "ogrim roar",
  ogrim_scream = "ogrim scream",
  oil_bubbly = "oil bubbly",
  Open_Lock = "Open Lock",
  Open_Lock_Fail = "Open Lock Fail",
  Pack = "Pack",
  potion_fail = "potion fail",
  potion_success = "potion success",
  power_hummer = "power hummer",
  Power_Light = "Power Light",
  Power_light_50 = "Power light 50",
  Rain = "Rain",
  rain_heavy = "rain heavy",
  rat_moan = "rat moan",
  rat_roar = "rat roar",
  rat_scream = "rat scream",
  Repair = "Repair",
  repair_fail = "repair fail",
  restoration_area = "restoration area",
  restoration_bolt = "restoration bolt",
  restoration_cast = "restoration cast",
  restoration_hit = "restoration hit",
  riek_moan = "riek moan",
  riek_roar = "riek roar",
  riek_scream = "riek scream",
  RightL = "RightL",
  RightM = "RightM",
  RightS = "RightS",
  rmnt_moan = "rmnt moan",
  rmnt_roar = "rmnt roar",
  rmnt_scream = "rmnt scream",
  rock_and_roll = "rock and roll",
  rocks1 = "rocks1",
  rocks2 = "rocks2",
  rocks3 = "rocks3",
  rocks4 = "rocks4",
  rocks5 = "rocks5",
  rocks6 = "rocks6",
  rocks7 = "rocks7",
  rocks8 = "rocks8",
  ropebridge = "ropebridge",
  rumble1 = "rumble1",
  rumble2 = "rumble2",
  rumble3 = "rumble3",
  rumble4 = "rumble4",
  SatchelBlast = "SatchelBlast",
  scamp_moan = "scamp moan",
  scamp_roar = "scamp roar",
  scamp_scream = "scamp scream",
  scrib_moan = "scrib moan",
  scrib_roar = "scrib roar",
  scrib_scream = "scrib scream",
  scribLEFT = "scribLEFT",
  scribRIGHT = "scribRIGHT",
  scroll = "scroll",
  shalk_moan = "shalk moan",
  shalk_roar = "shalk roar",
  shalk_scream = "shalk scream",
  shock_area = "shock area",
  shock_bolt = "shock bolt",
  shock_cast = "shock cast",
  shock_hit = "shock hit",
  Silt_1 = "Silt_1",
  Silt_2 = "Silt_2",
  Silt_3 = "Silt_3",
  Sixth_Bell = "Sixth_Bell",
  SkaalAttackNoise = "SkaalAttackNoise",
  skeleton_moan = "skeleton moan",
  skeleton_roar = "skeleton roar",
  skeleton_scream = "skeleton scream",
  skillraise = "skillraise",
  slaughterfish_moan = "slaughterfish moan",
  slaughterfish_roar = "slaughterfish roar",
  slaughterfish_scream = "slaughterfish scream",
  sludgeworm_fall = "sludgeworm fall",
  sludgeworm_left = "sludgeworm left",
  sludgeworm_moan = "sludgeworm moan",
  sludgeworm_right = "sludgeworm right",
  sludgeworm_roar = "sludgeworm roar",
  sludgeworm_scream = "sludgeworm scream",
  SothaAmbient = "SothaAmbient",
  SothaBlade = "SothaBlade",
  SothaBladeRoll = "SothaBladeRoll",
  SothaDoorClose = "SothaDoorClose",
  SothaDoorOpen = "SothaDoorOpen",
  SothaFabMachine = "SothaFabMachine",
  SothaGear = "SothaGear",
  SothaGiantBlade = "SothaGiantBlade",
  SothaLab = "SothaLab",
  SothaLever = "SothaLever",
  SothaSpark = "SothaSpark",
  SothaSpikes = "SothaSpikes",
  sound_boat_creak = "sound_boat_creak",
  Sound_Test = "Sound Test",
  Sound_Test_Loop = "Sound Test Loop",
  Spell_Failure_Alteration = "Spell Failure Alteration",
  Spell_Failure_Conjuration = "Spell Failure Conjuration",
  Spell_Failure_Destruction = "Spell Failure Destruction",
  Spell_Failure_Illusion = "Spell Failure Illusion",
  Spell_Failure_Mysticism = "Spell Failure Mysticism",
  Spell_Failure_Restoration = "Spell Failure Restoration",
  spellmake_fail = "spellmake fail",
  spellmake_success = "spellmake success",
  spiderATTACK1 = "spiderATTACK1",
  spiderATTACK2 = "spiderATTACK2",
  spiderLEFT = "spiderLEFT",
  spiderRIGHT = "spiderRIGHT",
  Spirit_Ambient_Voices = "Spirit Ambient Voices",
  spriggan_moan = "spriggan moan",
  spriggan_resurrect = "spriggan resurrect",
  spriggan_roar = "spriggan roar",
  spriggan_scream = "spriggan scream",
  sprigganmagic = "sprigganmagic",
  Steam = "Steam",
  steamATTACK1 = "steamATTACK1",
  steamATTACK2 = "steamATTACK2",
  steamLEFT = "steamLEFT",
  steamRIGHT = "steamRIGHT",
  steamROLL = "steamROLL",
  Stone_Door_Open_1 = "Stone Door Open 1",
  StoneSound = "StoneSound",
  Swallow = "Swallow",
  swamp_1 = "swamp 1",
  swamp_2 = "swamp 2",
  swamp_3 = "swamp 3",
  Swim_Left = "Swim Left",
  Swim_Right = "Swim Right",
  SwishL = "SwishL",
  SwishM = "SwishM",
  SwishS = "SwishS",
  Thunder0 = "Thunder0",
  Thunder1 = "Thunder1",
  Thunder2 = "Thunder2",
  Thunder3 = "Thunder3",
  ThunderClap = "ThunderClap",
  Torch_Out = "Torch Out",
  Underwater = "Underwater",
  volcano_rumble = "volcano rumble",
  Water_Layer = "Water Layer",
  waterfall_small = "waterfall small",
  Weapon_Swish = "Weapon Swish",
  were_moan = "were moan",
  were_roar = "were roar",
  were_scream = "were scream",
  weregrowl = "weregrowl",
  werehowl = "werehowl",
  weresniff = "weresniff",
  wind_calm1 = "wind calm1",
  wind_calm2 = "wind calm2",
  wind_calm3 = "wind calm3",
  wind_calm4 = "wind calm4",
  wind_calm5 = "wind calm5",
  wind_des1 = "wind des1",
  wind_des2 = "wind des2",
  wind_des3 = "wind des3",
  wind_des4 = "wind des4",
  Wind_Light = "Wind Light",
  wind_low1 = "wind low1",
  wind_low2 = "wind low2",
  wind_low3 = "wind low3",
  wind_trees1 = "wind trees1",
  wind_trees2 = "wind trees2",
  wind_trees3 = "wind trees3",
  wind_trees4 = "wind trees4",
  wind_trees5 = "wind trees5",
  wind_trees6 = "wind trees6",
  wind_trees7 = "wind trees7",
  WindBag = "WindBag",
  winged_twil_moan = "winged twil moan",
  winged_twil_roar = "winged twil roar",
  winged_twil_scream = "winged twil scream",
  wolf_moan = "wolf moan",
  wolf_roar = "wolf roar",
  wolf_scream = "wolf scream",
  WolfActivator1 = "WolfActivator1",
  WolfContainer1 = "WolfContainer1",
  WolfContainer2 = "WolfContainer2",
  WolfCreature1 = "WolfCreature1",
  WolfCreature2 = "WolfCreature2",
  WolfCreature3 = "WolfCreature3",
  WolfEquip1 = "WolfEquip1",
  WolfEquip2 = "WolfEquip2",
  WolfEquip3 = "WolfEquip3",
  WolfEquip4 = "WolfEquip4",
  WolfEquip5 = "WolfEquip5",
  WolfHit1 = "WolfHit1",
  WolfHit2 = "WolfHit2",
  WolfHit3 = "WolfHit3",
  wolfhowl = "wolfhowl",
  WolfItem1 = "WolfItem1",
  WolfItem2 = "WolfItem2",
  WolfItem3 = "WolfItem3",
  WolfNPC1 = "WolfNPC1",
  WolfNPC2 = "WolfNPC2",
  WolfNPC3 = "WolfNPC3",
  WolfRun = "WolfRun",
  wolfskel_moan = "wolfskel moan",
  wolfskel_roar = "wolfskel roar",
  wolfskel_scream = "wolfskel scream",
  wolfskhowl = "wolfskhowl",
  WolfSwing = "WolfSwing",
  WolfSwing1 = "WolfSwing1",
  WolfSwing2 = "WolfSwing2",
  WolfSwing3 = "WolfSwing3",
  Wooden_Door_Close_1 = "Wooden Door Close 1",
  Wooden_Door_Open_1 = "Wooden Door Open 1",
}

return bs
