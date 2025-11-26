local self  = require('openmw.self')
local types = require('openmw.types')
local core  = require('openmw.core')
local time  = require('openmw_aux.time')

-- Map spell IDs → weather *names* (simple strings)
local weatherSpells = {
    detd_Clear_spell        = 'Clear',
    detd_Cloudy_spell       = 'Cloudy',
    detd_Foggy_spell        = 'Foggy',
    detd_Overcast_spell     = 'Overcast',
    detd_Rain_spell         = 'Rain',
    detd_Thunder_spell      = 'Thunderstorm',
    detd_Ashstorm_spell     = 'Ashstorm',
    detd_Blight_spell       = 'Blight',
    detd_Snow_spell         = 'Snow',
    detd_Blizzard_spell     = 'Blizzard',
}

local CHECK_INTERVAL = 0.5
local lastWeather = nil
local lastRegion = nil

local function hasSpell(id)
    return types.Actor.activeSpells(self):isSpellActive(id)
end

time.runRepeatedly(function()
    if not self.cell or not self.cell.region then return end
    local regionId = self.cell.region

    local newWeather = nil
    for spellId, weatherName in pairs(weatherSpells) do
        if hasSpell(spellId) then
            newWeather = weatherName
            break
        end
    end

    if newWeather then
      --  print("hello")
        core.sendGlobalEvent('detd_UpdateWeather', {
            regionId = regionId,
            weather = newWeather
        })
  --      print(regionId)
  --      print(newWeather)
        lastWeather = newWeather
        lastRegion = regionId
    end

    if not newWeather then
        lastWeather = nil
    end
end, CHECK_INTERVAL * time.second)
