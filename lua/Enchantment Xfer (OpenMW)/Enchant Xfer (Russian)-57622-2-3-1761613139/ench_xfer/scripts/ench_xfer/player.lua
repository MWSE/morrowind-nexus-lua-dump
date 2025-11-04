-- Enchant Transfer — Скрипт игрока (OpenMW 0.49)
-- Окно переноса зачарования + обработка горячей клавиши (Boolean ACTION).

local ui    = require('openmw.ui')
local util  = require('openmw.util')
local types = require('openmw.types')
local core  = require('openmw.core')
local self  = require('openmw.self')
local async = require('openmw.async')
local I     = require('openmw.interfaces')
local input = require('openmw.input')

local v2 = util.vector2

-- ======================= ВВОД (привязанное действие из настроек) =======================
local ACTION_KEY = 'EnchantXfer_OpenMenu'
local lastActionDown = false

local function ensureActionRegistered()
  if not input.actions[ACTION_KEY] then
    input.registerAction({
      key          = ACTION_KEY,
      l10n         = 'EnchantXfer',
      name         = '',
      description  = '',
      type         = input.ACTION_TYPE.Boolean,
      defaultValue = false,
    })
  end
end

-- ======================= ГЕОМЕТРИЯ ОКНА =======================
local WINDOW_W, WINDOW_H = 760, 520
local TITLE_H = 28
local INNER_W,  INNER_H  = WINDOW_W - 20, WINDOW_H - 90
local FRAME_INSET = 2
local FRAME_W, FRAME_H = WINDOW_W - 2 * FRAME_INSET, WINDOW_H - 2 * FRAME_INSET

-- ======================= СОСТОЯНИЕ =======================
local state = {
  donorId       = nil,
  targetId      = nil,
  nameInput     = '',
  pickerMode    = nil,    -- 'donor' | 'target' | nil
  pickerPage    = 1,
  pickerFilter  = 'All',
  perPage       = 24,
}

local window      = nil
local windowPos   = v2(100, 100)
local dragging    = false
local dragOffset  = v2(0, 0)

-- ======================= UI-помощники =======================
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
local function iconNode(tex, w, h)
  if not tex then return { template = I.MWUI.templates.textNormal, type = ui.TYPE.Text, props = { text = '(нет иконки)', size = v2(w or 32, h or 32) } } end
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

-- ======================= Записи / фильтры =======================
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

local function lookupObjById(id)
  if not id then return nil end
  for _, obj in ipairs(getInv():getAll()) do
    if obj.recordId == id and obj.count > 0 then return obj end
  end
  return nil
end
local function currentDonor()  return lookupObjById(state.donorId) end
local function currentTarget() return lookupObjById(state.targetId) end

-- Проверки зачарования
local function isUnenchanted(rec)
  return rec and (rec.enchant == nil or rec.enchant == '')
end
local function isEnchantable(rec)
  return (rec.enchantCapacity == nil) or (rec.enchantCapacity > 0)
end

-- ======================= Подсказка (плотная) =======================
local tooltipElement = nil
local function destroyTooltip() if tooltipElement and tooltipElement.destroy then tooltipElement:destroy() end tooltipElement=nil end
local function fmtInt(n) return tostring(math.floor((n or 0) + 0.5)) end
local function makeTooltipContentForItem(obj)
  local rec = recAndType(obj)
  if not rec then
    return ui.content({ { template = I.MWUI.templates.textNormal, type = ui.TYPE.Text, props = { text = '(неизвестный предмет)', textSize = 13 } } })
  end
  local lines = {}
  lines[#lines+1] = { template = I.MWUI.templates.textHeader, type = ui.TYPE.Text, props = { text = rec.name or '(неизвестно)', textSize = 14 } }
  if rec.value or rec.weight then
    local vw = string.format('Стоимость: %s   Вес: %s', rec.value and tostring(rec.value) or '-', rec.weight and string.format('%.2f', rec.weight) or '-')
    lines[#lines+1] = { template = I.MWUI.templates.textNormal, type = ui.TYPE.Text, props = { text = vw, textSize = 12 } }
  end
  if rec.enchant and rec.enchant ~= '' then
    local ench = core.magic.enchantments.records[rec.enchant]
    local chargeMax = (ench and ench.charge) or 0
    local data = types.Item.itemData(obj)
    local chargeCur = data and data.enchantmentCharge; if chargeCur == nil then chargeCur = chargeMax end
    lines[#lines+1] = { template = I.MWUI.templates.textNormal, type = ui.TYPE.Text, props = { text = ('Заряд: %s/%s'):format(fmtInt(chargeCur), fmtInt(chargeMax)), textSize = 12 } }
  elseif rec.enchantCapacity then
    lines[#lines+1] = { template = I.MWUI.templates.textNormal, type = ui.TYPE.Text, props = { text = ('Ёмкость зачарования: %s'):format(fmtInt(rec.enchantCapacity)), textSize = 12 } }
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

-- ======================= Перемещение окна =======================
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
        content = ui.content({ { template = I.MWUI.templates.textHeader, type = ui.TYPE.Text, props = { text = 'Перенос зачарования', textSize = 14 } } }),
      },
    }),
  }
end

-- ======================= Инвентарь / списки =======================
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

-- ======================= Плитка предмета =======================
local function itemTile(obj, onPick)
  local rec = recAndType(obj); local name = rec and rec.name or '(неизвестно)'; local tex = iconTex(obj)
  return {
    template = I.MWUI.templates.box, type = ui.TYPE.Container, props = { size = v2(150, 110) },
    events = {
      mouseEnter = async:callback(function(e) showTooltipForItem(obj, e.position) end),
      mouseMove  = async:callback(function(e) moveTooltip(e.position) end),
      mouseLeave = async:callback(function() destroyTooltip() end),
      mouseClick = async:callback(function() if onPick then onPick(obj) end end),
    },
    content = ui.content({ iconNode(tex, 48, 48), spacer(0,6), { type = ui.TYPE.Container, props = { size = v2(140, 40) }, content = ui.content({ nameText(name, 140) }) } }),
  }
end

-- ======================= Пикер =======================
local PER_ROW, PER_COL = 4, 3
local PAGE_SIZE = PER_ROW * PER_COL
local function applyFilter(list, label)
  if label == 'All' then return list end
  local out = {}
  local W,A,C = label=='Weapon', label=='Armor', label=='Clothing'
  for _, it in ipairs(list) do
    if     W and types.Weapon.objectIsInstance(it)   then out[#out+1]=it
    elseif A and types.Armor.objectIsInstance(it)    then out[#out+1]=it
    elseif C and types.Clothing.objectIsInstance(it) then out[#out+1]=it
    end
  end
  return out
end
local function pageSlice(all, page)
  local a,b=(page-1)*PAGE_SIZE+1, page*PAGE_SIZE
  local out={}; for i=a, math.min(b, #all) do out[#out+1]=all[i] end; return out
end
local function pickerHeader(kind)
  local label = (kind=='donor') and 'Выберите донора (зачарован)' or 'Выберите цель (без зачарования)'
  return { type=ui.TYPE.Flex, props={ size=v2(INNER_W,40), horizontal=true, autoSize=false, align=ui.ALIGNMENT.Start, arrange=ui.ALIGNMENT.Center },
           content=ui.content({ { template=I.MWUI.templates.textHeader, type=ui.TYPE.Text, props={ text=label, textSize=16 } } }) }
end
local function buildPicker()
  if not state.pickerMode then return nil end
  local pool = listCache.All
  local filtered = {}
  for _,obj in ipairs(applyFilter(pool, state.pickerFilter)) do
    local rec = recAndType(obj)
    if rec then
      if state.pickerMode == 'donor' then
        -- ТОЛЬКО зачарованные
        if rec.enchant and rec.enchant ~= '' then
          filtered[#filtered+1] = obj
        end
      else
        -- ЦЕЛЬ: только без зачарования (+при наличии поля емкости — > 0)
        if isUnenchanted(rec) and isEnchantable(rec) then
          filtered[#filtered+1] = obj
        end
      end
    end
  end
  local totalPages = math.max(1, math.ceil(#filtered / state.perPage))
  state.pickerPage = math.min(state.pickerPage, totalPages)
  local slice = pageSlice(filtered, state.pickerPage)

  local rows, row = {}, {}
  for i, it in ipairs(slice) do
    row[#row+1] = itemTile(it, function(picked)
      destroyTooltip()
      if state.pickerMode=='donor' then
        state.donorId=picked.recordId
      else
        state.targetId=picked.recordId
        local rec2 = recAndType(picked)
        state.nameInput = (rec2 and rec2.name) or ''
      end
      state.pickerMode=nil; if window then window.layout=buildLayout(); window:update() end
    end)
    if (#row==PER_ROW) or (i==#slice) then rows[#rows+1]=hstack(row, INNER_W); row={} end
  end

  local pageInfo = ('Стр. %d / %d'):format(state.pickerPage, totalPages)
  local prevBtn = mwButton('Предыдущая стр.', 160, function() state.pickerPage=math.max(1, state.pickerPage-1); if window then window.layout=buildLayout(); window:update() end end)
  local nextBtn = mwButton('Следующая стр.', 160, function() state.pickerPage=math.min(totalPages, state.pickerPage+1); if window then window.layout=buildLayout(); window:update() end end)

  return {
    template = I.MWUI.templates.boxSolidThick, type = ui.TYPE.Container, props = { size = v2(INNER_W, INNER_H) },
    content = ui.content({
      vstack({
        pickerHeader(state.pickerMode),
        sep(INNER_W), spacer(0,6),
        vstack(rows, INNER_W),
        spacer(0,8),
        hstack({ prevBtn, spacer(16,1), { template = I.MWUI.templates.textNormal, type=ui.TYPE.Text, props={ text=pageInfo, textSize=14 } }, spacer(16,1), nextBtn }, INNER_W),
      }, INNER_W),
    }),
  }
end

-- ======================= Блок подтверждения =======================
local function buildBody()
  local donor, target = currentDonor(), currentTarget()
  local dTex, tTex = donor and iconTex(donor) or nil, target and iconTex(target) or nil
  local dName = donor and (recAndType(donor).name or '') or '(нет)'
  local tName = target and (recAndType(target).name or '') or '(нет)'

  local pickDonorBtn  = mwButton('Выбрать донора', 160, function()
    rebuildLists()
    state.pickerMode='donor';  state.pickerFilter='All'; state.pickerPage=1
    if window then window.layout=buildLayout(); window:update() end
  end)
  local pickTargetBtn = mwButton('Выбрать цель', 160, function()
    rebuildLists()
    state.pickerMode='target'; state.pickerFilter='All'; state.pickerPage=1
    if window then window.layout=buildLayout(); window:update() end
  end)
  local transferBtn   = mwButton('Перенести зачарование', 200, function()
    destroyTooltip()
    local donorObj, targetObj = currentDonor(), currentTarget()
    if donorObj and targetObj then
      core.sendGlobalEvent('ET_DoTransfer', { donor=donorObj, target=targetObj, newName=(state.nameInput ~= '' and state.nameInput or nil) })
    else
      ui.showMessage('[Перенос зачарования] Сначала выберите донора и цель.')
    end
  end)

  local leftBox = {
    template = I.MWUI.templates.box, type = ui.TYPE.Container, props = { size = v2(360,160) },
    events = {
      mouseEnter = async:callback(function(e) if donor  then showTooltipForItem(donor,  e.position) end end),
      mouseMove  = async:callback(function(e) if donor  then moveTooltip(e.position) end end),
      mouseLeave = async:callback(function() destroyTooltip() end),
    },
    content = ui.content({
      vstack({
        { template = I.MWUI.templates.textNormal, type=ui.TYPE.Text, props={ text='Донор (зачарован)', textSize=14 } },
        spacer(0,6), hstack({ iconNode(dTex,48,48), spacer(12,1), nameText(dName,260) }, 360),
        spacer(0,8), pickDonorBtn,
      }, 360),
    }),
  }

  local rightBox = {
    template = I.MWUI.templates.box, type = ui.TYPE.Container, props = { size = v2(360,160) },
    events = {
      mouseEnter = async:callback(function(e) if target then showTooltipForItem(target, e.position) end end),
      mouseMove  = async:callback(function(e) if target then moveTooltip(e.position) end end),
      mouseLeave = async:callback(function() destroyTooltip() end),
    },
    content = ui.content({
      vstack({
        { template = I.MWUI.templates.textNormal, type=ui.TYPE.Text, props={ text='Цель (без зачарования)', textSize=14 } },
        spacer(0,6), hstack({ iconNode(tTex,48,48), spacer(12,1), nameText(tName,260) }, 360),
        spacer(0,8), pickTargetBtn,
      }, 360),
    }),
  }

  return {
    template = I.MWUI.templates.boxSolidThick, type = ui.TYPE.Container, props = { size = v2(INNER_W, INNER_H) },
    content = ui.content({
      vstack({
        hstack({ { template = I.MWUI.templates.textHeader, type=ui.TYPE.Text, props={ text='Подтвердите перенос', textSize=16 } } }, INNER_W),
        sep(INNER_W), spacer(0,8),
        -- Строка ввода нового имени
        hstack({
          { template = I.MWUI.templates.textNormal, type = ui.TYPE.Text, props = { text = 'Новое имя:', textSize = 14, size = v2(110, 26) } },
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
        spacer(0,8),
        hstack({ leftBox, spacer(20,1), rightBox }, INNER_W),
        spacer(0,12),
        hstack({ transferBtn }, INNER_W),
      }, INNER_W),
    }),
  }
end

-- ======================= Построение окна =======================
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

-- ======================= Открыть/закрыть окно =======================
local function openUI()
  if window then return end
  windowPos = clampToScreen(windowPos, v2(WINDOW_W, WINDOW_H))
  rebuildLists()
  window = ui.create(buildLayout())
end
local function closeUI()
  if window then window:destroy(); window=nil end
  destroyTooltip()
end

-- ======================= Глобальные события =======================
local eventHandlers = {}
eventHandlers.ET_PickedDonor  = function(p) state.donorId  = p and p.id or nil; if window then window.layout=buildLayout(); window:update() end end
eventHandlers.ET_PickedTarget = function(p)
  state.targetId = p and p.id or nil
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
    end,
  },
}
