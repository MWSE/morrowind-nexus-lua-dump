local function CheckWeather(e)
  local playerCell = tes3.getPlayerCell()
  local inside = playerCell.isInterior
  if inside then
    if playerCell.behavesAsExterior == false then
      tes3.findGMST(57).value = "Resting here is illegal. You'll need to find a bed."
      return
    end
  else
    tes3.findGMST(57).value = "Resting here is illegal. You'll need to find a bed."
  end
  local weatherCurrent
  weatherCurrent = tes3.getCurrentWeather()
  local weatherCheck = weatherCurrent.index
  if weatherCheck > 3 then
    tes3.findGMST(57).value = "Rest in this weather is impossible. You'll need to find shelter."
    e.allowRest = false
  end
end

local function WeatherWake()
  local playerCell = tes3.getPlayerCell()
  local inside = playerCell.isInterior
  if inside then
    if playerCell.behavesAsExterior == false then
      return
    end
  end
  if tes3.mobilePlayer.sleeping then
    local weatherCurrent
    weatherCurrent = tes3.getCurrentWeather()
    local weatherCheck = weatherCurrent.index
    if weatherCheck > 3 then
      tes3.messageBox("Your rest was interrupted by bad weather")
      tes3.runLegacyScript({ command = "WakeUpPC" })
    end
  end
end

local function initialized()
  event.register("uiShowRestMenu", CheckWeather)
  event.register("weatherChangedImmediate", WeatherWake)
end
event.register("initialized", initialized)