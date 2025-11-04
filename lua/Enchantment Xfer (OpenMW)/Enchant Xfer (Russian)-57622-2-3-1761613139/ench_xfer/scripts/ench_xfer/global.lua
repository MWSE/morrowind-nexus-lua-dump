-- Перенос зачарования — Глобальный скрипт (OpenMW 0.49/0.50)
-- Локализация сообщений на русский язык.
-- Логика: переносит зачарование с источника на цель, корректирует стоимость:
--   - целевой предмет получает "базовую" цену цели + дельту стоимости зачарования донора,
--   - у источника снимается зачарование и цена сбрасывается к "базовой" для его класса.

local world = require('openmw.world')
local types = require('openmw.types')
local core  = require('openmw.core')

-- --------------------------- локализация ------------------------------------

local TAG = '[Перенос зачарования]'

local function msgMissingItems()        return TAG .. ' Отсутствует источник или цель.' end
local function msgInvalidItems()        return TAG .. ' Предмет(ы) недействителен(ы).' end
local function msgUnsupportedTypes()    return TAG .. ' Неподдерживаемый тип предмета.' end
local function msgBadFamilies()         return TAG .. ' Оружие можно переносить только на оружие; броня/одежда — только между собой.' end
local function msgSameContainer()       return TAG .. ' Оба предмета должны находиться в одном контейнере.' end
local function msgDonorNeedsEnchant()   return TAG .. ' Источник должен быть зачарован.' end
local function msgTargetMustBePlain()   return TAG .. ' Цель должна быть без зачарования.' end
local function msgEnchNotFound()        return TAG .. ' Запись зачарования источника не найдена.' end
local function msgEnchTypeInvalid()     return TAG .. ' Тип зачарования не подходит для целевого предмета.' end
local function msgMakeTargetFail()      return TAG .. ' Не удалось создать запись целевого предмета.' end
local function msgMakeDonorFail()       return TAG .. ' Не удалось создать замену для исходного предмета.' end
local function msgSuccess(newValue)
  return string.format('%s Готово! Зачарование перенесено на цель; исходный предмет сохранил внешний вид, но потерял зачарование. Цена цели установлена: %d.', TAG, newValue or 0)
end

-- --------------------------- helpers ----------------------------------------

local function familyOf(obj)
  if types.Weapon.objectIsInstance(obj)   then return types.Weapon end
  if types.Armor.objectIsInstance(obj)    then return types.Armor  end
  if types.Clothing.objectIsInstance(obj) then return types.Clothing end
  return nil
end

local function isEmptyId(x) return x == nil or x == '' end

local function appendDisenchantedSuffix(name)
  name = name or ''
  if name:sub(-18) == ' (Без зачарования)' then return name end
  return name .. ' (Без зачарования)'
end

local function normPath(p)
  if not p or p == '' then return '' end
  return p:gsub('\\', '/'):lower()
end

-- варианты имён моделей для поиска "базовой" записи
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

-- сравнение "ядра" статов
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

-- минимальная цена среди незачарованных записей того же семейства и слота
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

-- поиск "базы" по (1) модели, (2) иконке, (3) ядру статов; выбираем самую дешёвую подходящую
local function findBaseRecordSmart(T, donorRec)
  local recs = T.records
  local donorModel   = normPath(donorRec.model)
  local donorIcon    = normPath(donorRec.icon)
  local modelKeys    = modelCandidates(donorModel)
  local bestModel, bestModelValue
  local bestIcon,  bestIconValue
  local bestCore,  bestCoreValue

  for i = 1, #recs do
    local r = recs[i]
    if isEmptyId(r.enchant) and r.type == donorRec.type then
      local v = r.value or 0
      local rModel = normPath(r.model)
      local rIcon  = normPath(r.icon)

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

-- создание записи на основе шаблона с переопределениями
local function buildFromTemplate(T, templateRec, overrides)
  overrides = overrides or {}
  local clearEnchant    = overrides.clearEnchant or false
  local nameOverride    = overrides.name
  local enchantOverride = overrides.enchant -- может быть nil
  local valueOverride   = overrides.value   -- может быть nil

  if T == types.Armor then
    local draft = types.Armor.createRecordDraft({
      template = templateRec,
      name     = nameOverride or templateRec.name,
      enchant  = clearEnchant and "" or enchantOverride,
      value    = valueOverride,
    })
    return world.createRecord(draft)
  elseif T == types.Clothing then
    local draft = types.Clothing.createRecordDraft({
      template = templateRec,
      name     = nameOverride or templateRec.name,
      enchant  = clearEnchant and "" or enchantOverride,
      value    = valueOverride,
    })
    return world.createRecord(draft)
  else -- Weapon
    local draft = types.Weapon.createRecordDraft({
      template = templateRec,
      name     = nameOverride or templateRec.name,
      enchant  = clearEnchant and "" or enchantOverride,
      value    = valueOverride,
    })
    return world.createRecord(draft)
  end
end

-- замена экземпляра; переносим состояние/заряд при необходимости
local function replaceOne(oldObj, newRecordId, opts)
  local container = oldObj.parentContainer
  if not container then return nil end

  local newObj = world.createObject(newRecordId, 1)
  newObj:moveInto(container)

  local src = types.Item.itemData(oldObj)
  local dst = types.Item.itemData(newObj)

  if opts and opts.copyCondition and src.condition ~= nil then
    local maxHealth
    if types.Weapon.objectIsInstance(newObj) then
      maxHealth = types.Weapon.record(newObj).health
    elseif types.Armor.objectIsInstance(newObj) then
      maxHealth = types.Armor.record(newObj).health
    end
    if maxHealth then
      dst.condition = math.min(src.condition, maxHealth)
    else
      dst.condition = src.condition
    end
  end

  if opts and opts.copyChargeFrom then
    local donorData = types.Item.itemData(opts.copyChargeFrom)
    dst.enchantmentCharge = donorData.enchantmentCharge
  end
  if opts and opts.resetCharge then
    dst.enchantmentCharge = nil
  end

  oldObj:remove(1)
  return newObj
end

local function sendToPlayer(event, payload)
  local p = world.players and world.players[1]
  if p and p.isValid and p:isValid() then
    p:sendEvent(event, payload)
  else
    core.sendGlobalEvent(event, payload)
  end
end

-- --------------------- совместимость зачарований -----------------------------

local ENCH = core.magic.ENCHANTMENT_TYPE

local function isArmorOrClothing(T)
  return (T == types.Armor) or (T == types.Clothing)
end

local function isEnchantmentAllowedFor(Ttarget, enchType)
  if Ttarget == types.Weapon then
    return (enchType == ENCH.CastOnStrike) or (enchType == ENCH.CastOnUse) or (enchType == ENCH.CastOnce)
  else
    return (enchType == ENCH.CastOnUse) or (enchType == ENCH.ConstantEffect)
  end
end

-- дельта цены зачарования донора относительно "базы"
local function computeDonorPriceDelta(Tdonor, donorRec)
  local baseRec = findBaseRecordSmart(Tdonor, donorRec)
  local baseLikeValue = baseRec and baseRec.value or minValueForFamilySlot(Tdonor, donorRec)
  local donorV = donorRec.value or 0
  local baseV  = baseLikeValue or 0
  local delta  = math.max(0, donorV - baseV)
  return delta, baseLikeValue
end

-- ------------------------- обработчики событий -------------------------------

local eventHandlers = {}

eventHandlers.ET_DoTransfer = function(data)
  if not data or not data.donor or not data.target then
    sendToPlayer('ET_Result', { ok = false, message = msgMissingItems() })
    return
  end

  local donor, target = data.donor, data.target
  if not donor:isValid() or not target:isValid() then
    sendToPlayer('ET_Result', { ok = false, message = msgInvalidItems() })
    return
  end

  local Tdonor, Ttarget = familyOf(donor), familyOf(target)
  if not Tdonor or not Ttarget then
    sendToPlayer('ET_Result', { ok = false, message = msgUnsupportedTypes() })
    return
  end

  -- разрешаем броня<->одежда; оружие только с оружием
  local sameFamily = (Tdonor == Ttarget)
  local armorClothMix = isArmorOrClothing(Tdonor) and isArmorOrClothing(Ttarget)
  if not (sameFamily or armorClothMix) then
    sendToPlayer('ET_Result', { ok = false, message = msgBadFamilies() })
    return
  end

  if donor.parentContainer ~= target.parentContainer then
    sendToPlayer('ET_Result', { ok = false, message = msgSameContainer() })
    return
  end

  local donorRec  = Tdonor.record(donor)
  local targetRec = Ttarget.record(target)
  if isEmptyId(donorRec.enchant) then
    sendToPlayer('ET_Result', { ok = false, message = msgDonorNeedsEnchant() })
    return
  end
  if not isEmptyId(targetRec.enchant) then
    sendToPlayer('ET_Result', { ok = false, message = msgTargetMustBePlain() })
    return
  end

  local ench = core.magic.enchantments.records[donorRec.enchant]
  if not ench then
    sendToPlayer('ET_Result', { ok = false, message = msgEnchNotFound() })
    return
  end
  if not isEnchantmentAllowedFor(Ttarget, ench.type) then
    sendToPlayer('ET_Result', { ok = false, message = msgEnchTypeInvalid() })
    return
  end

  local delta, baseLikeValue = computeDonorPriceDelta(Tdonor, donorRec)

  local newNameForTarget     = (data.newName and data.newName ~= '' and data.newName) or targetRec.name
  local donorReplacementName = appendDisenchantedSuffix(donorRec.name)

  -- создаём новую запись цели с зачарованием донора и новой ценой
  local newTargetValue = (targetRec.value or 0) + delta
  local newTargetRecord = buildFromTemplate(Ttarget, targetRec, {
    enchant = donorRec.enchant,
    name    = newNameForTarget,
    value   = newTargetValue,
  })
  if not newTargetRecord then
    sendToPlayer('ET_Result', { ok = false, message = msgMakeTargetFail() })
    return
  end

  -- создаём замену донору: снимаем зачарование, откатываем цену к базовой
  local donorReplacementRecord = buildFromTemplate(Tdonor, donorRec, {
    name         = donorReplacementName,
    clearEnchant = true,
    value        = baseLikeValue
  })
  if not donorReplacementRecord then
    sendToPlayer('ET_Result', { ok = false, message = msgMakeDonorFail() })
    return
  end

  -- меняем экземпляры, копируем состояние и заряд (заряд у донора сбрасывается)
  replaceOne(target, newTargetRecord.id, { copyCondition = true, copyChargeFrom = donor })
  replaceOne(donor,  donorReplacementRecord.id, { copyCondition = true, resetCharge = true })

  sendToPlayer('ET_Result', { ok = true, message = msgSuccess(newTargetValue) })
end

return { eventHandlers = eventHandlers }
