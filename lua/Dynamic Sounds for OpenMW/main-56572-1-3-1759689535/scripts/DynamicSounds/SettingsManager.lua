local SettingsManager = {}

local _currentSettings = {
    enableMod = true,
    playChance = 20,
    enableDebugMode = false,
    maxDistanceObjectSounds = 2000,
    dayStartingHour = 6,
    dayEndingHour = 19,
    enableCreatureComponent = true,
    creatureDistanceToPlayer = 3500,
}

function SettingsManager.setSettings(data)
    _currentSettings = data
end

function SettingsManager.currentSettings()
    return _currentSettings
end


function SettingsManager.dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' ..  SettingsManager.dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end


return SettingsManager
