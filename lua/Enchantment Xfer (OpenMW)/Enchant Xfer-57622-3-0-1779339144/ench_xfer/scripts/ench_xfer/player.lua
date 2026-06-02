-- Enchant Transfer — Player script (OpenMW 0.49)
-- Fixed: unified page size for the item picker so page count and slicing match.

local ui    = require('openmw.ui')
local util  = require('openmw.util')
local types = require('openmw.types')
local core  = require('openmw.core')
local self  = require('openmw.self')
local async = require('openmw.async')
local I     = require('openmw.interfaces')
local input = require('openmw.input')

local v2 = util.vector2
local ENCH = core.magic.ENCHANTMENT_TYPE
local L10N = 'EnchantXfer'
local l10n = core.l10n(L10N, 'en')

local function tr(key, args)
  return l10n(key, args or {})
end

-- ======================= INPUT (Settings-bound ACTION only) =======================
local ACTION_KEY = 'EnchantXfer_OpenMenu'
local UI_MODE = 'EnchantTransfer'
local FALLBACK_UI_MODE = 'Interface'
local UI_CLOSE_ACTIONS = {
  input.ACTION.GameMenu,
  input.ACTION.Inventory,
  input.ACTION.Journal,
  input.ACTION.QuickMenu,
  input.ACTION.QuickKeysMenu,
  input.ACTION.TogglePostProcessorHUD,
}
local lastActionDown = false

local function ensureActionRegistered()
  if not input.actions[ACTION_KEY] then
    input.registerAction({
      key          = ACTION_KEY,
      l10n         = L10N,
      name         = 'action_open_menu_name',
      description  = 'action_open_menu_description',
      type         = input.ACTION_TYPE.Boolean,
      defaultValue = false,
    })
  end
end

-- ======================= WINDOW / GRID LAYOUT CONSTANTS =======================
local WINDOW_W, WINDOW_H = 760, 520
local TITLE_H = 28
local INNER_W,  INNER_H  = WINDOW_W - 20, WINDOW_H - 90
local FRAME_INSET = 2
local FRAME_W, FRAME_H = WINDOW_W - 2 * FRAME_INSET, WINDOW_H - 2 * FRAME_INSET

-- GRID: define rows/cols once, then derive PER_PAGE and use it everywhere
local PER_ROW, PER_COL = 4, 3
local PER_PAGE = PER_ROW * PER_COL  -- <<< single source of truth

-- ======================= STATE =======================
local state = {
  donorObj      = nil,
  targetObj     = nil,
  donorId       = nil,
  targetId      = nil,
  nameInput     = '',
  pickerMode    = nil,    -- 'donor' | 'target' | nil
  pickerPage    = 1,
  pickerFilter  = 'All',
  pickerSearch  = '',
}

local window      = nil
local windowPos   = v2(100, 100)
local dragging    = false
local dragOffset  = v2(0, 0)
local activeUiMode = nil

local function uiModeIsActive(mode)
  local modes = I.UI and I.UI.modes or {}
  for i = 1, #modes do
    if modes[i] == mode then return true end
  end
  return false
end

local function topUiMode()
  return I.UI and I.UI.getMode and I.UI.getMode() or nil
end

local function enterUiMode()
  if not I.UI then return false end
  if I.UI.setPauseOnMode then pcall(function() I.UI.setPauseOnMode(UI_MODE, false) end) end

  local ok = pcall(function()
    if not uiModeIsActive(UI_MODE) then I.UI.addMode(UI_MODE) end
  end)
  if ok and topUiMode() == UI_MODE then
    activeUiMode = UI_MODE
    return true
  end
  if uiModeIsActive(UI_MODE) then I.UI.removeMode(UI_MODE) end

  ok = pcall(function() I.UI.addMode(FALLBACK_UI_MODE, { windows = {} }) end)
  if ok and topUiMode() == FALLBACK_UI_MODE then
    activeUiMode = FALLBACK_UI_MODE
    return true
  end

  activeUiMode = nil
  return false
end

local function leaveUiMode()
  if I.UI then
    if activeUiMode and uiModeIsActive(activeUiMode) then I.UI.removeMode(activeUiMode) end
    if activeUiMode ~= UI_MODE and uiModeIsActive(UI_MODE) then I.UI.removeMode(UI_MODE) end
  end
  activeUiMode = nil
end

local function builtinUiActionPressed()
  for _, action in ipairs(UI_CLOSE_ACTIONS) do
    if action and input.isActionPressed(action) then return true end
  end
  return false
end

-- ======================= UI helpers =======================
local function spacer(w, h) return { type = ui.TYPE.Container, props = { size = v2(w or 1, h or 1) } } end
local function hstack(children, width)
  return { type = ui.TYPE.Flex, props = { size = v2(width or INNER_W, 1), autoSize = true, horizontal = true,  align = ui.ALIGNMENT.Start, arrange = ui.ALIGNMENT.Center }, content = ui.content(children) }
end
local function vstack(children, width)
  return { type = ui.TYPE.Flex, props = { size = v2(width or INNER_W, 1), autoSize = true, horizontal = false, align = ui.ALIGNMENT.Start, arrange = ui.ALIGNMENT.Start   }, content = ui.content(children) }
end
local function sep(width)
  return { type = ui.TYPE.Image, props = { size = v2(width or INNER_W, 2), resource = ui.texture { path = 'white' }, color = util.color.rgb(1,1,1), alpha = 0.35 } }
end
local function nameText(str, w)
  return { template = I.MWUI.templates.textNormal, type = ui.TYPE.Text, props = { text = str, textSize = 14, wordWrap = true, multiline = true, size = v2(w or 200, 40) } }
end
local function textNode(str, w, h, size)
  return { template = I.MWUI.templates.textNormal, type = ui.TYPE.Text, props = { text = str or '', textSize = size or 13, wordWrap = true, multiline = true, size = v2(w or 200, h or 22) } }
end
local function headerText(str, w, h, size)
  return { template = I.MWUI.templates.textHeader, type = ui.TYPE.Text, props = { text = str or '', textSize = size or 15, wordWrap = true, multiline = true, size = v2(w or 200, h or 24) } }
end
local function smallText(str, w, h)
  return textNode(str, w, h or 18, 12)
end
local function iconNode(tex, w, h)
  if not tex then return { template = I.MWUI.templates.textNormal, type = ui.TYPE.Text, props = { text = tr('generic_no_icon'), size = v2(w or 32, h or 32) } } end
  return { type = ui.TYPE.Image, props = { size = v2(w or 32, h or 32), resource = tex } }
end
local function mwButton(text, width, onClick)
  return {
    template = I.MWUI.templates.box, type = ui.TYPE.Container, props = { size = v2(width or 120, 28) },
    events = { mouseClick = async:callback(function() if onClick then onClick() end end) },
    content = ui.content({
      { type = ui.TYPE.Flex, props = { horizontal = true, size = v2(width or 120, 28), align = ui.ALIGNMENT.Center, arrange = ui.ALIGNMENT.Center },
        content = ui.content({ { template = I.MWUI.templates.textHeader, type = ui.TYPE.Text, props = { text = text, textSize = 14 } } }) },
    }),
  }
end

-- ======================= Inventory / records =======================
local function recAndType(obj)
  if not (obj and obj.isValid and obj:isValid()) then return nil end
  if types.Weapon.objectIsInstance(obj)   then return types.Weapon.record(obj),   types.Weapon   end
  if types.Armor.objectIsInstance(obj)    then return types.Armor.record(obj),    types.Armor    end
  if types.Clothing.objectIsInstance(obj) then return types.Clothing.record(obj), types.Clothing end
  return nil
end
local function iconTex(obj)
  local rec = recAndType(obj)
  local icon = rec and rec.icon
  if not icon or icon == '' then return nil end
  return ui.texture { path = icon }
end
local function isSupported(obj)
  return types.Weapon.objectIsInstance(obj) or types.Armor.objectIsInstance(obj) or types.Clothing.objectIsInstance(obj)
end
local function getInv() return types.Actor.inventory(self) end

local function objectIsUsable(obj)
  return obj and obj.isValid and obj:isValid() and obj.count and obj.count > 0
end

local function lookupObjById(id)
  if not id then return nil end
  for _, obj in ipairs(getInv():getAll()) do
    if obj.recordId == id and obj.count > 0 then return obj end
  end
  return nil
end
local function currentDonor()
  if state.donorObj then
    if objectIsUsable(state.donorObj) then return state.donorObj end
    state.donorObj = nil
    state.donorId = nil
    return nil
  end
  local obj = lookupObjById(state.donorId)
  if obj then state.donorObj = obj end
  return obj
end
local function currentTarget()
  if state.targetObj then
    if objectIsUsable(state.targetObj) then return state.targetObj end
    state.targetObj = nil
    state.targetId = nil
    return nil
  end
  local obj = lookupObjById(state.targetId)
  if obj then state.targetObj = obj end
  return obj
end

local function isUnenchanted(rec)
  return rec and (rec.enchant == nil or rec.enchant == '')
end
local function isEmptyId(x) return x == nil or x == '' end
local function isEnchantable(rec)
  return (rec.enchantCapacity == nil) or (rec.enchantCapacity > 0)
end

local function familyOf(obj)
  if not obj then return nil end
  if types.Weapon.objectIsInstance(obj)   then return types.Weapon end
  if types.Armor.objectIsInstance(obj)    then return types.Armor end
  if types.Clothing.objectIsInstance(obj) then return types.Clothing end
  return nil
end

local function isArmorOrClothing(T)
  return (T == types.Armor) or (T == types.Clothing)
end

local function isEnchantmentAllowedFor(Ttarget, enchType)
  if Ttarget == types.Weapon then
    return (enchType == ENCH.CastOnStrike) or (enchType == ENCH.CastOnUse) or (enchType == ENCH.CastOnce) or (enchType == ENCH.ConstantEffect)
  else
    return (enchType == ENCH.CastOnUse) or (enchType == ENCH.ConstantEffect)
  end
end

local function isCompatiblePair(donorObj, targetObj)
  local donorRec = recAndType(donorObj)
  local targetRec = recAndType(targetObj)
  local Tdonor = familyOf(donorObj)
  local Ttarget = familyOf(targetObj)
  if not donorRec or not targetRec or not Tdonor or not Ttarget then return false end
  if not donorRec.enchant or donorRec.enchant == '' then return false end
  if not isUnenchanted(targetRec) or not isEnchantable(targetRec) then return false end

  local sameFamily = (Tdonor == Ttarget)
  local armorClothMix = isArmorOrClothing(Tdonor) and isArmorOrClothing(Ttarget)
  if not (sameFamily or armorClothMix) then return false end

  local ench = core.magic.enchantments.records[donorRec.enchant]
  return ench and isEnchantmentAllowedFor(Ttarget, ench.type) or false
end

local function fmtInt(n) return tostring(math.floor((n or 0) + 0.5)) end
local function fmtSigned(n)
  n = n or 0
  if n >= 0 then return '+' .. fmtInt(n) end
  return '-' .. fmtInt(math.abs(n))
end

local function normPath(p)
  if not p or p == '' then return '' end
  return p:gsub('\\', '/'):lower()
end

local function modelCandidates(modelPath)
  local out = {}
  local p = normPath(modelPath)
  if p == '' then return out end
  out[#out+1] = p
  local stripped = p:gsub('_(uni%w*)%.nif$', '.nif'); if stripped ~= p then out[#out+1] = stripped end
  stripped = p:gsub('_(unique)%.nif$', '.nif');       if stripped ~= p then out[#out+1] = stripped end
  local chopped = p:gsub('_[^/_]+%.nif$', '.nif');    if chopped  ~= p then out[#out+1] = chopped  end
  return out
end

local function eq(a,b) return a == b end
local function armorCoreEqual(a,b)
  return eq(a.type,b.type) and eq(a.baseArmor,b.baseArmor) and eq(a.health,b.health)
     and eq(a.weight,b.weight) and eq(a.enchantCapacity,b.enchantCapacity)
end
local function clothingCoreEqual(a,b)
  return eq(a.type,b.type) and eq(a.weight,b.weight) and eq(a.enchantCapacity,b.enchantCapacity)
end
local function weaponCoreEqual(a,b)
  return eq(a.type,b.type)
     and eq(a.chopMinDamage,b.chopMinDamage) and eq(a.chopMaxDamage,b.chopMaxDamage)
     and eq(a.slashMinDamage,b.slashMinDamage) and eq(a.slashMaxDamage,b.slashMaxDamage)
     and eq(a.thrustMinDamage,b.thrustMinDamage) and eq(a.thrustMaxDamage,b.thrustMaxDamage)
     and eq(a.speed,b.speed) and eq(a.reach,b.reach) and eq(a.weight,b.weight) and eq(a.health,b.health)
end
local function coreEqual(T,a,b)
  if T == types.Armor then return armorCoreEqual(a,b)
  elseif T == types.Clothing then return clothingCoreEqual(a,b)
  else return weaponCoreEqual(a,b) end
end

local function minValueForFamilySlot(T, donorRec)
  local minV
  local records = T.records
  for i = 1, #records do
    local r = records[i]
    if isEmptyId(r.enchant) and r.type == donorRec.type then
      local v = r.value or 0
      if not minV or v < minV then minV = v end
    end
  end
  return minV or (donorRec.value or 0)
end

local function findBaseRecordSmart(T, donorRec)
  local recs = T.records
  local donorModel = normPath(donorRec.model)
  local donorIcon = normPath(donorRec.icon)
  local modelKeys = modelCandidates(donorModel)
  local bestModel, bestModelValue
  local bestIcon, bestIconValue
  local bestCore, bestCoreValue

  for i = 1, #recs do
    local r = recs[i]
    if isEmptyId(r.enchant) and r.type == donorRec.type then
      local v = r.value or 0
      local rModel = normPath(r.model)
      local rIcon = normPath(r.icon)

      for _, key in ipairs(modelKeys) do
        if key ~= '' and rModel == key then
          if not bestModel or v < bestModelValue then bestModel, bestModelValue = r, v end
          break
        end
      end
      if donorIcon ~= '' and rIcon ~= '' and rIcon == donorIcon then
        if not bestIcon or v < bestIconValue then bestIcon, bestIconValue = r, v end
      end
      if coreEqual(T, r, donorRec) then
        if not bestCore or v < bestCoreValue then bestCore, bestCoreValue = r, v end
      end
    end
  end

  return bestModel or bestIcon or bestCore
end

local function enchantmentFallbackValue(ench)
  if not ench then return 0 end
  return math.floor(math.max(ench.cost or 0, ench.charge or 0) + 0.5)
end

local function computeDonorPriceDelta(Tdonor, donorRec)
  local baseRec = findBaseRecordSmart(Tdonor, donorRec)
  local baseLikeValue = baseRec and baseRec.value or minValueForFamilySlot(Tdonor, donorRec)
  local donorV = donorRec.value or 0
  local baseV = baseLikeValue or 0
  local delta = math.max(0, donorV - baseV)
  if delta <= 0 and not isEmptyId(donorRec.enchant) then
    local ench = core.magic.enchantments.records[donorRec.enchant]
    local fallback = enchantmentFallbackValue(ench)
    if fallback > 0 then
      delta = math.min(donorV, fallback)
      baseLikeValue = donorV - delta
    end
  end
  return delta, baseLikeValue
end

local function itemName(obj)
  local rec = recAndType(obj)
  return (rec and rec.name and rec.name ~= '' and rec.name) or tr('generic_none')
end

local function familyLabel(value)
  local T = value
  if value and value.isValid then T = familyOf(value) end
  if T == types.Weapon then return tr('family_weapon') end
  if T == types.Armor then return tr('family_armor') end
  if T == types.Clothing then return tr('family_clothing') end
  return tr('generic_unknown')
end

local function isJewelryRecord(rec)
  local C = types.Clothing.TYPE
  return rec and (rec.type == C.Ring or rec.type == C.Amulet or rec.type == C.Belt)
end

local function itemKindLabel(obj)
  local rec, T = recAndType(obj)
  if T == types.Clothing and isJewelryRecord(rec) then return tr('family_jewelry') end
  return familyLabel(T)
end

local function enchantTypeLabel(enchType)
  if enchType == ENCH.CastOnStrike then return tr('enchant_type_cast_on_strike') end
  if enchType == ENCH.CastOnUse then return tr('enchant_type_cast_on_use') end
  if enchType == ENCH.CastOnce then return tr('enchant_type_cast_once') end
  if enchType == ENCH.ConstantEffect then return tr('enchant_type_constant_effect') end
  return tr('generic_unknown')
end

local function enchantRecordForItem(obj)
  local rec = recAndType(obj)
  if not rec or not rec.enchant or rec.enchant == '' then return nil, nil end
  return core.magic.enchantments.records[rec.enchant], rec.enchant
end

local function appendDisenchantedSuffix(name)
  name = name or ''
  local suffix = tr('suffix_disenchanted')
  if name:sub(-#suffix) == suffix or name:sub(-15) == ' (Disenchanted)' then return name end
  return name .. suffix
end

local function donorCompatibilityHint(donorObj)
  local rec = recAndType(donorObj)
  local Tdonor = familyOf(donorObj)
  local ench = rec and rec.enchant and core.magic.enchantments.records[rec.enchant] or nil
  if not rec or not ench then return tr('donor_hint_pick') end
  if Tdonor == types.Weapon then return tr('donor_hint_weapons') end
  if isArmorOrClothing(Tdonor) then return tr('donor_hint_armor_clothing') end
  return tr('donor_hint_unknown')
end

local function chargeText(obj, ench)
  if not ench or not ench.charge or ench.charge <= 0 then return nil end
  local data = types.Item.itemData(obj)
  local chargeCur = data and data.enchantmentCharge
  if chargeCur == nil then chargeCur = ench.charge end
  return tr('line_charge', { current = fmtInt(chargeCur), max = fmtInt(ench.charge) })
end

local function statRecordName(group, id)
  if not id or not core.stats or not core.stats[group] then return nil end
  local rec = core.stats[group].records[id]
  return rec and rec.name or id
end

local function specializeEffectName(name, token)
  if not token or token == '' then return name end
  local specialized, count = name:gsub('Attribute', token)
  if count == 0 then specialized, count = name:gsub('Skill', token) end
  if count == 0 then specialized = name .. ' ' .. token end
  return specialized
end

local function rangeLabel(range)
  local R = core.magic.RANGE
  if range == R.Self then return tr('range_self') end
  if range == R.Touch then return tr('range_touch') end
  if range == R.Target then return tr('range_target') end
  return tr('generic_unknown')
end

local function secondsLabel(n)
  n = math.max(0, math.floor((n or 0) + 0.5))
  return tr('duration_seconds', { seconds = n })
end

local function effectDisplayName(effectWithParams)
  local effect = effectWithParams and effectWithParams.effect
  local name = (effect and effect.name) or (effectWithParams and effectWithParams.id) or tr('generic_unknown_effect')
  local attrName = statRecordName('Attribute', effectWithParams and effectWithParams.affectedAttribute)
  local skillName = statRecordName('Skill', effectWithParams and effectWithParams.affectedSkill)
  return specializeEffectName(name, attrName or skillName)
end

local function effectDescription(effectWithParams)
  local effect = effectWithParams and effectWithParams.effect
  if not effectWithParams or not effect then return tr('generic_unknown_effect') end

  local effectName = effectDisplayName(effectWithParams)
  local magnitude = ''
  if effect.hasMagnitude then
    local minMag = math.floor((effectWithParams.magnitudeMin or 0) + 0.5)
    local maxMag = math.floor((effectWithParams.magnitudeMax or minMag) + 0.5)
    if minMag == maxMag then
      magnitude = tr('effect_magnitude_single', { magnitude = minMag })
    else
      magnitude = tr('effect_magnitude_range', { min = minMag, max = maxMag })
    end
  end
  local duration = ''
  if effect.hasDuration and (effectWithParams.duration or 0) > 0 then
    duration = tr('effect_duration', { duration = secondsLabel(effectWithParams.duration) })
  end
  local area = ''
  if (effectWithParams.area or 0) > 0 then
    area = tr('effect_area', { area = math.floor(effectWithParams.area + 0.5) })
  end
  return tr('effect_description', {
    effect = effectName,
    magnitude = magnitude,
    duration = duration,
    area = area,
    range = rangeLabel(effectWithParams.range),
  })
end

local function effectIcon(effectWithParams, size)
  local effect = effectWithParams and effectWithParams.effect
  if effect and effect.icon and effect.icon ~= '' then
    return iconNode(ui.texture { path = effect.icon }, size or 18, size or 18)
  end
  return spacer(size or 18, size or 18)
end

local function effectRows(ench, width, maxRows)
  local rows = {}
  if not ench or not ench.effects then return rows end
  maxRows = maxRows or 2
  for i = 1, math.min(#ench.effects, maxRows) do
    local effectWithParams = ench.effects[i]
    rows[#rows+1] = hstack({
      effectIcon(effectWithParams, 18),
      spacer(6,1),
      textNode(effectDescription(effectWithParams), width - 30, 32, 12),
    }, width)
  end
  if #ench.effects > maxRows then
    rows[#rows+1] = smallText(tr('effect_more', { count = #ench.effects - maxRows }), width, 16)
  end
  return rows
end

local function matchesSearch(obj, searchText)
  if not searchText or searchText == '' then return true end
  local rec = recAndType(obj)
  local name = rec and rec.name
  if not name then return false end
  return name:lower():find(searchText:lower(), 1, true) ~= nil
end

local function pickerFilterSummary()
  local selectedDonor = currentDonor()
  local selectedTarget = currentTarget()
  if state.pickerMode == 'target' and selectedDonor then
    return tr('picker_showing_targets_for', { item = itemName(selectedDonor) })
  elseif state.pickerMode == 'donor' and selectedTarget then
    return tr('picker_showing_donors_for', { item = itemName(selectedTarget) })
  elseif state.pickerMode == 'donor' then
    return tr('picker_showing_all_enchanted')
  else
    return tr('picker_showing_all_unenchanted')
  end
end

-- ======================= Tooltip =======================
local tooltipElement = nil
local function destroyTooltip() if tooltipElement and tooltipElement.destroy then tooltipElement:destroy() end tooltipElement=nil end
local function makeTooltipContentForItem(obj)
  local rec = recAndType(obj)
  if not rec then return ui.content({ { template = I.MWUI.templates.textNormal, type = ui.TYPE.Text, props = { text = tr('generic_unknown_item'), textSize = 13 } } }) end
  local lines = {}
  lines[#lines+1] = { template = I.MWUI.templates.textHeader, type = ui.TYPE.Text, props = { text = rec.name or tr('generic_unknown'), textSize = 14 } }
  if rec.value or rec.weight then
    local vw = tr('tooltip_value_weight', {
      value = rec.value and tostring(rec.value) or '-',
      weight = rec.weight and string.format('%.2f', rec.weight) or '-',
    })
    lines[#lines+1] = { template = I.MWUI.templates.textNormal, type = ui.TYPE.Text, props = { text = vw, textSize = 12 } }
  end
  if rec.enchant and rec.enchant ~= '' then
    local ench = core.magic.enchantments.records[rec.enchant]
    local chargeMax = (ench and ench.charge) or 0
    local data = types.Item.itemData(obj)
    local chargeCur = data and data.enchantmentCharge; if chargeCur == nil then chargeCur = chargeMax end
    lines[#lines+1] = { template = I.MWUI.templates.textNormal, type = ui.TYPE.Text, props = { text = tr('line_charge', { current = fmtInt(chargeCur), max = fmtInt(chargeMax) }), textSize = 12 } }
  elseif rec.enchantCapacity then
    lines[#lines+1] = { template = I.MWUI.templates.textNormal, type = ui.TYPE.Text, props = { text = tr('tooltip_enchant_capacity', { capacity = fmtInt(rec.enchantCapacity) }), textSize = 12 } }
  end
  return ui.content(lines)
end
local function showTooltipForItem(obj, mousePos)
  destroyTooltip()
  if not obj then return end
  tooltipElement = ui.create({
    layer = 'Notification',
    template = I.MWUI.templates.boxSolid,
    type = ui.TYPE.Container,
    props = { position = v2(mousePos.x + 16, mousePos.y + 16), autoSize = true },
    content = makeTooltipContentForItem(obj),
  })
end
local function moveTooltip(mousePos)
  if not tooltipElement then return end
  tooltipElement.layout.props.position = v2(mousePos.x + 16, mousePos.y + 16)
  tooltipElement:update()
end

-- ======================= Window geometry / dragging =======================
local function screenSize() local s = ui.screenSize(); return v2(s.x, s.y) end
local function clampToScreen(pos, size)
  local ss = screenSize()
  local x = math.max(0, math.min(pos.x, ss.x - size.x))
  local y = math.max(0, math.min(pos.y, ss.y - size.y))
  return v2(x, y)
end
local function headerBar()
  return {
    type  = ui.TYPE.Container,
    props = { size = v2(FRAME_W, TITLE_H) },
    content = ui.content({
      {
        type  = ui.TYPE.Flex,
        props = { size = v2(FRAME_W, TITLE_H), autoSize = false, horizontal = true, align = ui.ALIGNMENT.Start, arrange = ui.ALIGNMENT.Center },
        events = {
          mousePress   = async:callback(function(e) if e.button == 1 then dragging=true;  dragOffset=v2(e.position.x-windowPos.x, e.position.y-windowPos.y) end end),
          mouseRelease = async:callback(function(e) if e.button == 1 then dragging=false end end),
          mouseMove    = async:callback(function(e)
            if dragging and window then
              local newPos = v2(e.position.x - dragOffset.x, e.position.y - dragOffset.y)
              windowPos = clampToScreen(newPos, v2(WINDOW_W, WINDOW_H))
              window.layout.props.position = windowPos
              window:update()
            end
          end),
        },
        content = ui.content({ { template = I.MWUI.templates.textHeader, type = ui.TYPE.Text, props = { text = tr('window_title'), textSize = 14 } } }),
      },
    }),
  }
end

-- ======================= Lists & filtering =======================
local listCache = { All = {}, Weapon = {}, Armor = {}, Clothing = {} }
local function rebuildLists()
  for k in pairs(listCache) do listCache[k] = {} end
  for _, obj in ipairs(getInv():getAll()) do
    if isSupported(obj) then
      local rec = recAndType(obj)
      if rec and rec.name and rec.name ~= '' then
        table.insert(listCache.All, obj)
        if types.Weapon.objectIsInstance(obj)   then table.insert(listCache.Weapon,   obj) end
        if types.Armor.objectIsInstance(obj)    then table.insert(listCache.Armor,    obj) end
        if types.Clothing.objectIsInstance(obj) then table.insert(listCache.Clothing, obj) end
      end
    end
  end
  local function byName(a,b) return (recAndType(a).name or ''):lower() < (recAndType(b).name or ''):lower() end
  table.sort(listCache.All, byName); table.sort(listCache.Weapon, byName); table.sort(listCache.Armor, byName); table.sort(listCache.Clothing, byName)
end

-- ======================= Picker tile =======================
local function itemTile(obj, onPick)
  local rec = recAndType(obj); local name = rec and rec.name or tr('generic_unknown'); local tex = iconTex(obj)
  return {
    template = I.MWUI.templates.box, type = ui.TYPE.Container, props = { size = v2(150, 84) },
    events = {
      mouseEnter = async:callback(function(e) showTooltipForItem(obj, e.position) end),
      mouseMove  = async:callback(function(e) moveTooltip(e.position) end),
      mouseLeave = async:callback(function() destroyTooltip() end),
      mouseClick = async:callback(function() if onPick then onPick(obj) end end),
    },
    content = ui.content({ iconNode(tex, 36, 36), spacer(0,4), { type = ui.TYPE.Container, props = { size = v2(140, 34) }, content = ui.content({ textNode(name, 140, 34, 13) }) } }),
  }
end

-- ======================= Picker =======================
local function applyFilter(list, label)
  if label == 'All' then return list end
  local out = {}
  local W,A,C,J = label=='Weapon', label=='Armor', label=='Clothing', label=='Jewelry'
  for _, it in ipairs(list) do
    local rec = recAndType(it)
    if     W and types.Weapon.objectIsInstance(it) then out[#out+1]=it
    elseif A and types.Armor.objectIsInstance(it) then out[#out+1]=it
    elseif C and types.Clothing.objectIsInstance(it) and not isJewelryRecord(rec) then out[#out+1]=it
    elseif J and types.Clothing.objectIsInstance(it) and isJewelryRecord(rec) then out[#out+1]=it
    end
  end
  return out
end

local function pageSlice(all, page)
  local a = (page-1) * PER_PAGE + 1       -- <<< use PER_PAGE here
  local b = page * PER_PAGE
  local out = {}
  for i = a, math.min(b, #all) do out[#out+1] = all[i] end
  return out
end

local function pickerHeader(kind)
  local label = (kind=='donor') and tr('picker_pick_donor') or tr('picker_pick_target')
  return vstack({
    headerText(label, INNER_W, 24, 16),
    smallText(pickerFilterSummary(), INNER_W, 26),
  }, INNER_W)
end

local function filterTab(label, value)
  local text = (state.pickerFilter == value) and tr('filter_selected', { label = label }) or label
  return mwButton(text, 86, function()
    state.pickerFilter = value
    state.pickerPage = 1
    if window then window.layout=buildLayout(); window:update() end
  end)
end

local function pickerTabs()
  return hstack({
    filterTab(tr('filter_all'), 'All'), spacer(6,1),
    filterTab(tr('filter_weapons'), 'Weapon'), spacer(6,1),
    filterTab(tr('filter_armor'), 'Armor'), spacer(6,1),
    filterTab(tr('filter_clothing'), 'Clothing'), spacer(6,1),
    filterTab(tr('filter_jewelry'), 'Jewelry'),
  }, INNER_W)
end

local function pickerSearchRow()
  return hstack({
    textNode(tr('search_label'), 70, 26, 13),
    { template = I.MWUI.templates.textEditLine, type = ui.TYPE.TextEdit,
      props = { size = v2(300, 26), text = state.pickerSearch or '' },
      events = {
        textChanged = async:callback(function(arg)
          local newText
          if type(arg) == 'table' then newText = arg.text or ''
          else newText = arg or '' end
          if newText ~= state.pickerSearch then
            state.pickerSearch = newText
            state.pickerPage = 1
            if window then window.layout=buildLayout(); window:update() end
          end
        end),
      },
    },
  }, INNER_W)
end

local function buildPicker()
  if not state.pickerMode then return nil end
  local pool = listCache.All
  local filtered = {}
  local selectedDonor = currentDonor()
  local selectedTarget = currentTarget()
  for _,obj in ipairs(applyFilter(pool, state.pickerFilter)) do
    local rec = recAndType(obj)
    if rec and matchesSearch(obj, state.pickerSearch) then
      if state.pickerMode == 'donor' then
        if rec.enchant and rec.enchant ~= '' and ((not selectedTarget) or isCompatiblePair(obj, selectedTarget)) then
          filtered[#filtered+1] = obj
        end
      else
        if isUnenchanted(rec) and isEnchantable(rec) and ((not selectedDonor) or isCompatiblePair(selectedDonor, obj)) then
          filtered[#filtered+1] = obj
        end
      end
    end
  end

  -- <<< FIX: totalPages uses the same PER_PAGE as pageSlice
  local totalPages = math.max(1, math.ceil(#filtered / PER_PAGE))
  state.pickerPage = math.min(state.pickerPage, totalPages)
  local slice = pageSlice(filtered, state.pickerPage)

  local rows, row = {}, {}
  for i, it in ipairs(slice) do
    row[#row+1] = itemTile(it, function(picked)
      destroyTooltip()
      if state.pickerMode=='donor' then
        state.donorObj=picked
        state.donorId=picked.recordId
      else
        state.targetObj=picked
        state.targetId=picked.recordId
        local rec2 = recAndType(picked)
        state.nameInput = (rec2 and rec2.name) or ''
      end
      state.pickerMode=nil; if window then window.layout=buildLayout(); window:update() end
    end)
    if (#row==PER_ROW) or (i==#slice) then rows[#rows+1]=hstack(row, INNER_W); row={} end
  end
  if #rows == 0 then
    rows[#rows+1] = hstack({
      { template = I.MWUI.templates.textNormal, type = ui.TYPE.Text, props = { text = tr('picker_empty'), textSize = 14, size = v2(INNER_W, 32) } },
    }, INNER_W)
  end

  local firstItem = (#filtered == 0) and 0 or ((state.pickerPage - 1) * PER_PAGE + 1)
  local lastItem = math.min(state.pickerPage * PER_PAGE, #filtered)
  local pageInfo = tr('page_info', { page = state.pickerPage, pages = totalPages, first = firstItem, last = lastItem, count = #filtered })
  local prevBtn = mwButton(tr('button_prev_page'), 120, function() state.pickerPage=math.max(1, state.pickerPage-1); if window then window.layout=buildLayout(); window:update() end end)
  local nextBtn = mwButton(tr('button_next_page'), 120, function() state.pickerPage=math.min(totalPages, state.pickerPage+1); if window then window.layout=buildLayout(); window:update() end end)

  return {
    template = I.MWUI.templates.boxSolidThick, type = ui.TYPE.Container, props = { size = v2(INNER_W, INNER_H) },
    content = ui.content({
      vstack({
        pickerHeader(state.pickerMode),
        spacer(0,4),
        pickerTabs(),
        spacer(0,4),
        pickerSearchRow(),
        spacer(0,4),
        sep(INNER_W), spacer(0,4),
        vstack(rows, INNER_W),
        spacer(0,8),
        hstack({ prevBtn, spacer(16,1), { template = I.MWUI.templates.textNormal, type=ui.TYPE.Text, props={ text=pageInfo, textSize=14 } }, spacer(16,1), nextBtn }, INNER_W),
      }, INNER_W),
    }),
  }
end

-- ======================= Workbench body =======================
local function donorSummaryLines(donor)
  if not donor then
    return { tr('donor_none_selected'), tr('donor_pick_prompt') }
  end
  local ench, enchantId = enchantRecordForItem(donor)
  if not ench then return { tr('donor_no_enchantment') } end
  local lines = {
    tr('line_type', { type = enchantTypeLabel(ench.type) }),
  }
  local charge = chargeText(donor, ench)
  if charge then lines[#lines+1] = charge end
  lines[#lines+1] = donorCompatibilityHint(donor)
  return lines
end

local function targetSummaryLines(target, donor)
  if not target then
    return { tr('target_none_selected'), tr('target_pick_prompt') }
  end
  local rec = recAndType(target)
  local lines = {}
  if rec and isUnenchanted(rec) then lines[#lines+1] = tr('target_status_unenchanted')
  else lines[#lines+1] = tr('target_status_already_enchanted') end
  if donor then
    if isCompatiblePair(donor, target) then
      lines[#lines+1] = tr('target_compatible')
    else
      lines[#lines+1] = tr('target_not_compatible')
    end
  else
    lines[#lines+1] = tr('target_pick_donor_for_check')
  end
  return lines
end

local function selectedItemPanel(role, obj, button, width)
  local rec = recAndType(obj)
  local title = (role == 'donor') and tr('panel_donor') or tr('panel_target')
  local status = obj and itemKindLabel(obj) or ((role == 'donor') and tr('panel_enchanted_source') or tr('panel_unenchanted_destination'))
  local tex = obj and iconTex(obj) or nil
  local summary = (role == 'donor') and donorSummaryLines(obj) or targetSummaryLines(obj, currentDonor())
  local ench = (role == 'donor') and select(1, enchantRecordForItem(obj)) or nil
  local children = {
    headerText(title, width, 20, 14),
    spacer(0,4),
    hstack({
      iconNode(tex, 42, 42),
      spacer(10,1),
      vstack({
        headerText(obj and itemName(obj) or tr('generic_none'), width - 70, 34, 14),
        smallText(status, width - 70, 16),
      }, width - 70),
    }, width),
    spacer(0,4),
    sep(width - 12),
    spacer(0,4),
  }
  if role == 'donor' and ench then
    local rows = effectRows(ench, width - 16, 2)
    for i = 1, #rows do children[#children+1] = rows[i] end
  end
  for i = 1, math.min(#summary, role == 'donor' and 3 or 4) do
    children[#children+1] = smallText(summary[i], width - 16, 18)
  end
  children[#children+1] = spacer(0,4)
  children[#children+1] = hstack({ button }, width)

  return {
    template = I.MWUI.templates.box, type = ui.TYPE.Container, props = { size = v2(width, 188) },
    events = {
      mouseEnter = async:callback(function(e) if obj then showTooltipForItem(obj, e.position) end end),
      mouseMove  = async:callback(function(e) if obj then moveTooltip(e.position) end end),
      mouseLeave = async:callback(function() destroyTooltip() end),
    },
    content = ui.content({ vstack(children, width) }),
  }
end

local function transferDirectionPanel(donor, target)
  local label = '=>'
  local detail = tr('direction_transfer')
  if donor and target and not isCompatiblePair(donor, target) then
    label = 'X'
    detail = tr('direction_blocked')
  end
  return {
    type = ui.TYPE.Container, props = { size = v2(80, 188) },
    content = ui.content({
      vstack({
        spacer(0,62),
        headerText(label, 80, 32, 22),
        smallText(detail, 80, 18),
      }, 80),
    }),
  }
end

local function transferPreviewBox(donor, target)
  local lines = { headerText(tr('preview_title'), INNER_W - 20, 20, 14) }
  if not donor or not target then
    lines[#lines+1] = smallText(tr('preview_pick_prompt'), INNER_W - 20, 18)
  elseif not isCompatiblePair(donor, target) then
    lines[#lines+1] = smallText(tr('preview_incompatible'), INNER_W - 20, 18)
  else
    local donorRec, Tdonor = recAndType(donor)
    local targetRec = recAndType(target)
    local targetName = (state.nameInput and state.nameInput ~= '' and state.nameInput) or (targetRec and targetRec.name) or itemName(target)
    local delta, baseLikeValue = computeDonorPriceDelta(Tdonor, donorRec)
    local donorValue = donorRec and donorRec.value or 0
    local donorReplacementValue = baseLikeValue or donorValue
    local targetValue = targetRec and targetRec.value or 0
    local newTargetValue = targetValue + delta
    lines[#lines+1] = smallText(tr('preview_donor_becomes', { item = appendDisenchantedSuffix(donorRec and donorRec.name or itemName(donor)) }), INNER_W - 20, 18)
    lines[#lines+1] = smallText(tr('preview_target_becomes', { item = targetName }), INNER_W - 20, 18)
    lines[#lines+1] = smallText(tr('preview_donor_value', { old = donorValue, new = donorReplacementValue, delta = fmtSigned(donorReplacementValue - donorValue) }), INNER_W - 20, 18)
    lines[#lines+1] = smallText(tr('preview_target_value', { old = targetValue, new = newTargetValue, delta = fmtSigned(delta) }), INNER_W - 20, 18)
  end
  return {
    template = I.MWUI.templates.box, type = ui.TYPE.Container, props = { size = v2(INNER_W, 116) },
    content = ui.content({ vstack(lines, INNER_W - 20) }),
  }
end

local function buildBody()
  local donor, target = currentDonor(), currentTarget()

  local pickDonorBtn  = mwButton(tr('button_pick_donor'), 160, function()
    rebuildLists()
    state.pickerMode='donor';  state.pickerFilter='All'; state.pickerPage=1; state.pickerSearch=''
    if window then window.layout=buildLayout(); window:update() end
  end)
  local pickTargetBtn = mwButton(tr('button_pick_target'),160, function()
    rebuildLists()
    state.pickerMode='target'; state.pickerFilter='All'; state.pickerPage=1; state.pickerSearch=''
    if window then window.layout=buildLayout(); window:update() end
  end)
  local transferBtn   = mwButton(tr('button_transfer_enchant'), 180, function()
    destroyTooltip()
    local donorObj, targetObj = currentDonor(), currentTarget()
    if donorObj and targetObj and isCompatiblePair(donorObj, targetObj) then
      core.sendGlobalEvent('ET_DoTransfer', { donor=donorObj, target=targetObj, newName=(state.nameInput ~= '' and state.nameInput or nil) })
    elseif donorObj and targetObj then
      ui.showMessage(tr('message_selected_incompatible'))
    else
      ui.showMessage(tr('message_pick_first'))
    end
  end)

  return {
    template = I.MWUI.templates.boxSolidThick, type = ui.TYPE.Container, props = { size = v2(INNER_W, INNER_H) },
    content = ui.content({
      vstack({
        headerText(tr('workbench_title'), INNER_W, 22, 16),
        sep(INNER_W), spacer(0,4),
        hstack({
          { template = I.MWUI.templates.textNormal, type = ui.TYPE.Text, props = { text = tr('new_name_label'), textSize = 14, size = v2(110, 26) } },
          { template = I.MWUI.templates.textEditLine, type = ui.TYPE.TextEdit,
            props = { size = v2(INNER_W - 130, 26), text = state.nameInput or '' },
            events = {
              textChanged = async:callback(function(arg)
                if type(arg) == 'table' then state.nameInput = arg.text or ''
                else state.nameInput = arg or '' end
              end),
            },
          },
        }, INNER_W),
        spacer(0,6),
        hstack({
          selectedItemPanel('donor', donor, pickDonorBtn, 300),
          spacer(20,1),
          transferDirectionPanel(donor, target),
          spacer(20,1),
          selectedItemPanel('target', target, pickTargetBtn, 300),
        }, INNER_W),
        spacer(0,6),
        transferPreviewBox(donor, target),
        spacer(0,6),
        hstack({ transferBtn }, INNER_W),
      }, INNER_W),
    }),
  }
end

-- ======================= Build window =======================
function buildLayout()
  local bodyOrOverlay = state.pickerMode and buildPicker() or buildBody()
  return {
    layer = 'Windows',
    type  = ui.TYPE.Container,
    props = { size = v2(WINDOW_W, WINDOW_H), position = windowPos },
    events = { mouseRelease = async:callback(function(e) if e.button == 1 then dragging = false end end) },
    content = ui.content({
      {
        template = I.MWUI.templates.boxSolidThick,
        type     = ui.TYPE.Container,
        props    = { position = v2(FRAME_INSET, FRAME_INSET), size = v2(FRAME_W, FRAME_H) },
        content  = ui.content({
          vstack({
            headerBar(),
            spacer(0, 6),
            { template = I.MWUI.templates.padding, type = ui.TYPE.Container, props = { relativeSize = v2(1,1) },
              content = ui.content({ bodyOrOverlay }) },
          }, FRAME_W),
        }),
      },
    }),
  }
end

-- ======================= Open/close window =======================
local function openUI()
  if window then return end
  if topUiMode() ~= nil then return end
  if not enterUiMode() then return end
  windowPos = clampToScreen(windowPos, v2(WINDOW_W, WINDOW_H))
  rebuildLists()
  window = ui.create(buildLayout())
end
local function closeUI()
  if window then window:destroy(); window=nil end
  destroyTooltip()
  leaveUiMode()
end

-- ======================= Global events =======================
local eventHandlers = {}
eventHandlers.ET_PickedDonor  = function(p)
  state.donorObj = p and p.object or nil
  state.donorId = p and (p.id or (p.object and p.object.recordId)) or nil
  if window then window.layout=buildLayout(); window:update() end
end
eventHandlers.ET_PickedTarget = function(p)
  state.targetObj = p and p.object or nil
  state.targetId = p and (p.id or (p.object and p.object.recordId)) or nil
  local obj = currentTarget()
  if obj then local rec = recAndType(obj); state.nameInput = (rec and rec.name) or '' end
  if window then window.layout=buildLayout(); window:update() end
end
eventHandlers.ET_Open         = function() if not window then openUI() end end
eventHandlers.ET_Result       = function(payload)
  if payload and payload.message then ui.showMessage(payload.message) end
  local ok = payload and payload.ok
  local ambient = require('openmw.ambient')
  if ok == nil or ok == true then
    ambient.playSound('enchant success')
    closeUI()
  else
    ambient.playSound('menu click')
  end
end
eventHandlers.UiModeChanged = function(data)
  if window and data and activeUiMode and data.newMode ~= activeUiMode then closeUI() end
end

return {
  eventHandlers = eventHandlers,
  engineHandlers = {
    onInit = function()
      ensureActionRegistered()
      lastActionDown = input.getBooleanActionValue(ACTION_KEY) or false
    end,
    onUpdate = function(dt)
      local nowDown = input.getBooleanActionValue(ACTION_KEY) or false
      if nowDown and (not lastActionDown) then
        if window then closeUI() else openUI() end
      end
      lastActionDown = nowDown
      if window and builtinUiActionPressed() then closeUI(); return end
      if window and activeUiMode and topUiMode() ~= activeUiMode then closeUI() end
    end,
  },
}
