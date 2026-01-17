local async = require 'openmw.async'
local gameSelf = require 'openmw.self'
local storage = require 'openmw.storage'
local types = require 'openmw.types'

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

---@type ShadowTableSubscriptionHandler
local function defaultSubscribeHandler(shadowSettings, group, groupName, key)
  for k, v in pairs(group:asTable()) do
    shadowSettings[k] = v
  end
end

---@alias StorageSection userdata

--- Bridges onto a global storage section, providing easy access to the storage group with caching and logging methods
--- All settings associated with the storage section provided in the constructor are accessible by simply indexing the table.
--- They will always be up-to-date thanks to the provided subscription function, but that sub function may be overridden during construction.
---@class ProtectedTable:table table Semi-Read-only table which allows insertion of functions and hooks to a global storage section
---@field private shadowSettings ShadowSettingsTable Cached copies of setting values returned by the index method. Do NOT work with this directly.
---@field private thisGroup StorageSection Storage section this ProtectedTable owns. Do not work with this directly, instead iterate over or index the ProtectedTable.
---@field state table a writable table to store arbitrary values in
---@field getState fun(): table return the entire inner state table
---@field notifyPlayer fun(any) shorthand to display all arguments as a table in a Morrowind MessageBox from a protectedTable. Only works on player scripts.
---@field debuglog fun(any) If debug logging setting is enabled, then prints the arguments to log, as a concatenated table

---@alias ShadowSettingsTable table<string, any>
---@alias ShadowTableSubscriptionHandler fun(shadowSettings: ShadowSettingsTable, group: StorageSection, groupName: string, key: string)

---@class ProtectedTableConstructor
---@field modName string Used for the __tostring method
---@field logPrefix string
---@field inputGroupName string name of the *global* storage section to use
---@field managerName string? optional name to override inputGroupName in the __tostring method
---@field subscribeHandler ShadowTableSubscriptionHandler|false? override function to use instead of the default subscription handler. Since global sections may not be written from local scripts, an explicit value of `false` can be used to indicate no subscription at all.

---@param constructorData ProtectedTableConstructor
---@return ProtectedTable
local function new(constructorData)
  local requestedGroup = storage.globalSection(constructorData.inputGroupName)

  assert(constructorData.inputGroupName ~= nil and requestedGroup ~= nil,
    'An invalid setting group was provided!')

  local proxy = {
    thisGroup = requestedGroup,
    shadowSettings = {},
  }

  if constructorData.subscribeHandler then
    assert(type(constructorData.subscribeHandler) == 'function')
  end

  ---@type ShadowTableSubscriptionHandler
  local handler = constructorData.subscribeHandler ~= nil and constructorData.subscribeHandler or defaultSubscribeHandler

  if not (type(constructorData.subscribeHandler) == 'boolean' and constructorData.subscribeHandler == false) then
    requestedGroup:subscribe(async:callback(function(groupName, key)
      handler(proxy.shadowSettings, requestedGroup, groupName, key)
    end))
  else
    -- If the subscription is overridden entirely, nullify the cached settings when the group changes
    requestedGroup:subscribe(async:callback(function()
      proxy.shadowSettings = {}
    end))
  end

  local state = {}
  local methods = {}
  local managerString = constructorData.managerName or constructorData.inputGroupName

  function proxy.debugLog(...)
    if gameSelf.type ~= types.Player or not proxy.DebugLog then return end
    print(constructorData.logPrefix, table.concat({ ... }, ' '))
  end

  function proxy.notifyPlayer(...)
    if gameSelf.type ~= types.Player or not proxy.MessageEnable then return end
    require('openmw.ui').showMessage(constructorData.logPrefix .. ' ' .. table.concat({ ... }, ' '))
  end

  function proxy.getState()
    return state
  end

  local meta = {
    __metatable = ('%sManager'):format(managerString),
    __index = function(_, key)
      if key == 'DebugLog' then
        return storage.globalSection(constructorData.inputGroupName):get('DebugEnable') == true
      elseif key == 'MessageEnable' then
        return storage.globalSection(constructorData.inputGroupName):get('MessageEnable') == true
      elseif key == 'debugLog' then
        return proxy.debugLog
      elseif key == 'state' then
        return state
      end

      if proxy.shadowSettings[key] then return proxy.shadowSettings[key] end

      if methods[key] then return methods[key] end

      local savedValue = proxy.thisGroup:get(key)
      proxy.shadowSettings[key] = savedValue

      return savedValue
    end,
    __newindex = function(_, key, value)
      if key == 'state' and type(value) == 'table' then
        state = value
      elseif type(value) ~= 'function' or
          (type(value) ~= 'table' and key == 'state') then
        error(
          string.format([[%s Unauthorized table access when updating '%s' to '%s'.
This table is not writable and values must be updated through its associated storage group: '%s'.]],
            constructorData.logPrefix,
            tostring(key), tostring(value), constructorData.inputGroupName),
          2)
      else
        rawset(methods, key, value)
      end
    end,
    __tostring = function(_)
      local members = {}
      local methodParts = {}

      for key, value in pairsByKeys(proxy.thisGroup:asTable()) do
        members[#members + 1] = string.format('        %s = %s', tostring(key), tostring(value))
      end

      for key, _ in pairsByKeys(methods) do
        methodParts[#methodParts + 1] = string.format('        %s', tostring(key))
      end

      if #members == 0 then
        members[1] = 'None'
      end

      if #methodParts == 0 then
        methodParts[1] = 'None'
      end

      return string.format('%sManager {\n    Members:\n%s\n    Methods:\n%s\n  }',
        managerString, table.concat(members, ',\n'), table.concat(methodParts, ',\n'))
    end,
    __pairs = function()
      return next, proxy.thisGroup:asTable(), nil
    end,
  }
  setmetatable(proxy, meta)

  return proxy
end

return {
  interfaceName = 'StarwindVersion4ProtectedTable',
  interface = {
    new = new,
  }
}
