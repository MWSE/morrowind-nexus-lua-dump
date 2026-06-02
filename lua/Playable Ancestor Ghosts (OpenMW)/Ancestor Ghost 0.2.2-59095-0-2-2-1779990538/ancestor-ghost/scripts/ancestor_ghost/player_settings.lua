-- Read mod settings from playerSection (player script only).
local storage = require('openmw.storage')
local config = require('scripts.ancestor_ghost.config')

local M = {}

local function snapImmunity(value)
  if value == 0 or value == '0' then return 0 end
  local fallback = config.settingDefaults.normalWeaponsImmunity
  local v = tonumber(value) or fallback
  if v <= 0 then return 0 end
  if v <= 50 then return 50 end
  return 100
end

local function readBool(section, key, defaultKey)
  local v = section:get(key)
  if v == nil then
    return config.settingDefaults[defaultKey]
  end
  return v == true
end

function M.readFromStorage()
  local section = storage.playerSection(config.settingsGroupKey)
  return {
    normalWeaponsImmunity = snapImmunity(section:get(config.settingNormalWeaponsKey)),
    levitate = readBool(section, config.settingLevitateKey, 'ghostlyLevitate'),
    diseaseResist = readBool(section, config.settingDiseaseResistKey, 'commonDiseaseImmunity'),
    undeadFriendly = readBool(section, config.settingUndeadFriendlyKey, 'undeadFriendly'),
  }
end

return M
