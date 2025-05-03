local animation = require('openmw.animation')
local gameSelf = require('openmw.self')
local types = require('openmw.types')

local noSelfInputFunctions = {
  ['createRecordDraft'] = true,
}

local function pairsByKeys(t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0
  local iter = function()
    i = i + 1
    if a[i] == nil then
      return nil
    else
      return a[i], t[a[i]]
    end
  end
  return iter
end

local function alphabeticalParts(input)
  assert(type(input) == 'table', 'Cannot sort something that isn\'t a table!')
  local parts = {}
  local methodParts = {}
  local userDataParts = {}

  for key, value in pairsByKeys(input) do
    if type(value) == 'function' then
      methodParts[#methodParts + 1] = string.format('%s'
      , tostring(key))
    elseif type(value) == 'userdata' then
      userDataParts[#userDataParts + 1] = string.format('%s = %s'
      , tostring(key)
      , tostring(value))
    else
      parts[#parts + 1] = string.format('%s = %s'
      , tostring(key)
      , tostring(value))
    end
  end

  return string.format('S3GameGameSelf {\n Fields: { %s },\n Methods: { %s },\n UserData: { %s }\n}'
  , table.concat(parts, ', ')
  , table.concat(methodParts, ', ')
  , table.concat(userDataParts, ', '))
end

local nearby = require('openmw.nearby')
local PlayerType = types.Player
local function instanceDisplay(instance)
  local resultString = alphabeticalParts(instance)
  for _, actor in pairs(nearby.actors) do
    if PlayerType.objectIsInstance(actor) then
      actor:sendEvent('S3LFDisplay', resultString)
    end
  end
end

local function getObjectType(object)
  local result, _ = object.type.records[object.recordId].__type.name:gsub('ESM::', '')
  return result:lower()
end

local GameObjectWrapper = {}

GameObjectWrapper._mt = {
  __index = function(instance, key)
    local gameObject = rawget(instance, 'gameObject')
    -- There's a name conflict between `gameObject.id` and `record.id`
    -- since gameObject.recordId is a thing, gameObject.id always wins over record.id
    if key == 'id' then
      local id = gameObject.id
      rawset(instance, key, id)
      return id
      -- Record function does whole-ass map lookups which are slow, so hardcode it out
    elseif key == 'record' then
      local record = gameObject.type.records[gameObject.recordId]
      rawset(instance, key, record)
      return record
    elseif key == 'cell' then
      return gameObject.cell
    elseif key == 'object' then
      return gameObject
    elseif key == 'baseType' or key == 'type' or key == 'stats' then
      return nil
    end

    local isActor = types.Actor.objectIsInstance(gameObject)
    local isNPC = types.NPC.objectIsInstance(gameObject)
    local record = rawget(instance, 'record')
    if record == nil then
      record = gameObject.type.records[gameObject.recordId]
      rawset(instance, 'record', record)
    end
    local recordValue = record[key]
    local stats = gameObject.type.stats

    if gameObject.type[key] then
      local value = gameObject.type[key]
      if type(value) ~= "function" or noSelfInputFunctions[key] then
        rawset(instance, key, value)
      else
        rawset(instance, key, function(...) return value(gameObject, ...) end)
      end
    elseif recordValue then
      rawset(instance, key, recordValue)
    elseif isNPC and stats.skills[key] then
      rawset(instance, key, stats.skills[key](gameObject))
    elseif isActor and key == 'level' then
      rawset(instance, key, stats.level(gameObject))
    elseif isActor and stats.ai[key] then
      rawset(instance, key, stats.ai[key](gameObject))
    elseif isActor and stats.attributes[key] then
      rawset(instance, key, stats.attributes[key](gameObject))
    elseif isActor and stats.dynamic[key] then
      rawset(instance, key, stats.dynamic[key](gameObject))
    elseif isActor and animation[key] then
      if type(animation[key]) == 'function' then
        rawset(instance, key, function(...) return animation[key](gameObject, ...) end)
      else
        rawset(instance, key, animation[key])
      end
    elseif gameObject[key] then
      rawset(instance, key, gameObject[key])
    end
    return rawget(instance, key)
  end,
}

local function From(gameObject)
  assert(gameObject.__type.name == 'MWLua::LObject', 'S3GameSelf.From expects a raw gameObject')
  local instance = { gameObject = gameObject, From = From }

  instance.display = function()
    instanceDisplay(instance)
  end

  instance.objectType = function()
    return getObjectType(instance.gameObject)
  end

  setmetatable(instance, GameObjectWrapper._mt)
  return instance
end

local instance = { gameObject = gameSelf, From = From }
instance.display = function()
  instanceDisplay(instance)
end

instance.objectType = function()
  return getObjectType(instance.gameObject)
end

setmetatable(instance, GameObjectWrapper._mt)

local eventHandlers = {}

if PlayerType.objectIsInstance(gameSelf) then
  eventHandlers.S3LFDisplay = function(resultString)
    local ui = require('openmw.ui')
    local SuccessColor = ui.CONSOLE_COLOR.Success
    ui.printToConsole(resultString, SuccessColor)
  end
end

return {
  eventHandlers = eventHandlers,
  interfaceName = 's3lf',
  interface = instance,
}
