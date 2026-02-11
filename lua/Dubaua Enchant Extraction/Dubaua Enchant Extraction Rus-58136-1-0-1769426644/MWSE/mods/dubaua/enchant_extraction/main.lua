local CONFIG_PATH = "dubaua_enchant_extraction"
local i18n = mwse.loadTranslations("dubaua.enchant_extraction")
local config = mwse.loadConfig(CONFIG_PATH, {
  enabled = true,
  nextId = 1,
  renamePrompt = true,
  verboseHits = true,
})
local SPELL_ID = "dubaua_enchant_extraction"

local function hasCorrectObjectType(objectType)
  if objectType == tes3.objectType.weapon then return true end
  if objectType == tes3.objectType.armor then return true end
  if objectType == tes3.objectType.clothing then return true end
  return false
end

local function getItemName(object)
  if not object then return nil end
  local name = object.name
  if not name or name == "" then return object.id end
  return name
end

local function showHint(messageKey, playFail)
  if config.verboseHits then tes3.messageBox(i18n(messageKey)) end
  if playFail then tes3.playSound({sound = "spell failure mysticism"}) end
end

local function isEnchantmentCompatible(castType, objectType)
  if castType == tes3.enchantmentType.onStrike then return objectType == tes3.objectType.weapon end
  if castType == tes3.enchantmentType.onUse or castType == tes3.enchantmentType.constant then
    return
        objectType == tes3.objectType.weapon or objectType == tes3.objectType.armor or objectType ==
            tes3.objectType.clothing
  end
  return false
end

local function buildReenchantedId(baseId)
  config.nextId = (config.nextId or 1)
  local suffix = tostring(config.nextId)
  config.nextId = config.nextId + 1
  mwse.saveConfig(CONFIG_PATH, config)

  local prefix = "db_reench_"
  local maxLen = 31
  local usableBaseLen = maxLen - #prefix - 1 - #suffix
  if usableBaseLen < 1 then usableBaseLen = 1 end
  local base = baseId or "item"
  if #base > usableBaseLen then base = string.sub(base, 1, usableBaseLen) end
  return string.format("%s%s_%s", prefix, base, suffix)
end

local function unequipSelected(selectedItem, selectedItemData)
  if not selectedItem then return end
  if not tes3.player.object:hasItemEquipped(selectedItem, selectedItemData) then return end
  tes3.mobilePlayer:unequip({item = selectedItem, itemData = selectedItemData})
end

local function createReenchantedItemAndSwap(args)
  local selectedItem = args.selectedItem
  local targetRef = args.targetRef
  local targetObject = args.targetObject
  local enchantment = args.enchantment
  local nameOverride = args.nameOverride
  local renameToTarget = args.renameToTarget
  local selectedItemData = args.selectedItemData
  if renameToTarget == nil then renameToTarget = true end

  -- validation
  if not selectedItem then return end
  if not (targetRef and targetRef.object) then return end
  if not enchantment then return end
  if selectedItem.enchantment then return end
  if not isEnchantmentCompatible(enchantment.castType, selectedItem.objectType) then return end

  -- create new item
  local newId = buildReenchantedId(selectedItem.id)
  local newObject = selectedItem:createCopy({id = newId})
  if not newObject then
    showHint("msg.failedCreate", true)
    return
  end
  newObject.enchantment = enchantment

  if nameOverride and nameOverride ~= "" then
    newObject.name = nameOverride
  elseif renameToTarget and targetObject then
    newObject.name = getItemName(targetObject) or newObject.name
  end
  if targetObject and targetObject.value then newObject.value = targetObject.value end

  local dropPos = targetRef.position:copy()

  -- place new item
  local newRef = tes3.createReference({
    object = newObject,
    position = dropPos,
    orientation = tes3.player.orientation,
    cell = targetRef.cell,
  })
  if not newRef then
    showHint("msg.failedCreate", true)
    return
  end

  unequipSelected(selectedItem, selectedItemData)

  tes3.removeItem({
    reference = tes3.player,
    item = selectedItem,
    itemData = selectedItemData,
    count = 1,
  })

  targetRef:delete()

  tes3.playSound({reference = tes3.player, sound = "enchant success"})

  tes3.mobilePlayer:exerciseSkill(tes3.skill.enchant, 25)
  showHint("msg.success")
end

local function showRenameMenu(defaultName, onConfirm)
  local menuId = tes3ui.registerID("Reenchant_RenameMenu")
  local existing = tes3ui.findMenu(menuId)
  if existing then existing:destroy() end

  local menu = tes3ui.createMenu({id = menuId, fixedFrame = true})
  tes3ui.enterMenuMode(menuId)

  local content = menu:getContentElement()
  content.flowDirection = "top_to_bottom"
  content.paddingAllSides = 8
  content.childAlignX = 0.5

  content:createLabel({text = i18n("ui.rename.title")})

  local input = content:createTextInput({text = defaultName or ""})
  input.width = 300

  local buttonRow = content:createBlock()
  buttonRow.flowDirection = "left_to_right"
  buttonRow.autoHeight = true
  buttonRow.autoWidth = true
  buttonRow.childAlignX = 0.5
  buttonRow.borderTop = 6

  local function closeMenu()
    menu:destroy()
    tes3ui.leaveMenuMode(menuId)
  end

  local cancelButton = buttonRow:createButton({text = i18n("ui.rename.cancel")})
  cancelButton:register(tes3.uiEvent.mouseClick, closeMenu)

  local function confirm(e)
    if onConfirm then onConfirm(e.source.text) end
    closeMenu()
  end

  local nextButton = buttonRow:createButton({text = i18n("ui.rename.ok")})
  nextButton:register(tes3.uiEvent.mouseClick, function() confirm({source = input}) end)

  input:registerAfter(tes3.uiEvent.keyEnter, confirm)
  input:registerAfter(tes3.uiEvent.keyPress,
                      function(e) if e.keyCode == tes3.scanCode.escape then closeMenu() end end)

  tes3ui.acquireTextInput(input)
  menu:updateLayout()
end

local function onSpellCast(e)
  if e.caster ~= tes3.player then return end
  if not (e.source and e.source.id == SPELL_ID) then return end

  -- check if cast on target
  local target = tes3.getPlayerTarget()
  if not (target and target.object) then
    showHint("msg.noTarget", true)
    return
  end

  -- check if correct object type
  local object = target.object
  if not hasCorrectObjectType(object.objectType) then
    showHint("msg.invalidTarget", true)
    return
  end
  -- check if target have enchantment
  if not object.enchantment then
    showHint("msg.noEnchantment", true)
    return
  end

  -- check if target has no special logic
  if object.script and object.script.id and object.script.id ~= "" then
    tes3.messageBox(i18n("msg.specialItem"))
    tes3.playSound({sound = "spell failure mysticism"})
    return
  end

  local enchantmentType = object.enchantment.castType

  tes3ui.showInventorySelectMenu({
    title = i18n("ui.select.title"),
    filter = function(params)
      local item = params.item
      if not item or item.enchantment then return false end
      if item.script and item.script.id and item.script.id ~= "" then return false end

      return isEnchantmentCompatible(enchantmentType, item.objectType)
    end,
    callback = function(params)
      if not params or not params.item then return end
      local defaultName = getItemName(object) or getItemName(params.item) or ""
      if config.renamePrompt then
        showRenameMenu(defaultName, function(newName)
          createReenchantedItemAndSwap({
            selectedItem = params.item,
            selectedItemData = params.itemData,
            targetRef = target,
            targetObject = object,
            enchantment = object.enchantment,
            renameToTarget = true,
            nameOverride = newName,
          })
        end)
      else
        createReenchantedItemAndSwap({
          selectedItem = params.item,
          selectedItemData = params.itemData,
          targetRef = target,
          targetObject = object,
          enchantment = object.enchantment,
          renameToTarget = true,
          nameOverride = defaultName,
        })
      end
    end,
  })

end

local function registerModConfig()
  local EasyMCM = require("easyMCM.EasyMCM")
  local template = EasyMCM.createTemplate(i18n("mod.name"))
  template:saveOnClose(CONFIG_PATH, config)

  local settingsPage = template:createSidebarPage({label = i18n("mcm.settings.label")})
  settingsPage.sidebar:createInfo({text = i18n("mcm.info")})

  settingsPage:createYesNoButton({
    label = i18n("mcm.enabled.label"),
    description = i18n("mcm.enabled.desc"),
    variable = mwse.mcm.createTableVariable({id = "enabled", table = config}),
  })
  settingsPage:createYesNoButton({
    label = i18n("mcm.renamePrompt.label"),
    description = i18n("mcm.renamePrompt.desc"),
    variable = mwse.mcm.createTableVariable({id = "renamePrompt", table = config}),
  })
  settingsPage:createYesNoButton({
    label = i18n("mcm.verboseHits.label"),
    description = i18n("mcm.verboseHits.desc"),
    variable = mwse.mcm.createTableVariable({id = "verboseHits", table = config}),
  })

  EasyMCM.register(template)
end

local function init() mwse.log("[Dubaua Enchant Extraction] Initialized") end

event.register("modConfigReady", registerModConfig)
event.register("initialized", init)
event.register("spellCast", onSpellCast)

