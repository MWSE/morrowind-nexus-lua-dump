-- A ring you equip, that auto unequips, that will allow you to change the weather for your current region, there is also a random option just for fun.
-- Note the weather transitions can be configured in a simple MCM "Weather Ring" if set to yes then transition is immediate. "All" will override "Random".
-- The code for this is written in Lua.

-- Debug message to ensure the script is loaded
mwse.log("[Weather Control Ring] script loaded.")

local ringId = "tw_weathercontrolring"
local weatherTypes = {
    "Clear", "Cloudy", "Foggy", "Overcast", "Rain", "Thunderstorm", "Ash", "Blight", "Snow", "Blizzard", "Random", "Cancel"
}
local config = mwse.loadConfig("tw_weatherring", {
    enableOne = false, 
    enableTwo = false             
})

-- Function to auto-unequip the ring and show the weather menu
local function tw_WeatherRingEquipped(e)
    if e.item.id == ringId then
		local region = tes3.getRegion()

        -- Display the weather change menu
        tes3.messageBox{
            message = "Select the desired weather:",
            buttons = weatherTypes,
            callback = function(e)
                --if e.button < #weatherTypes then
                if e.button <= 9 then
					local butt = e.button			
                    region:changeWeather(butt)			
					if ( config.enableOne ) then
						tes3.worldController.weatherController:switchImmediate(region.weather.index)
					end					
				elseif e.button == 10 then
					-- set as random
					region:randomizeWeather()
					if ( config.enableOne ) then  --or  config.enableOtwo ) then
						tes3.worldController.weatherController:switchImmediate(region.weather.index)
					end					
				else
					return
                end
            end
        }
		-- Auto-unequip the ring
		timer.frame.delayOneFrame(function() tes3.mobilePlayer:unequip({item = ringId}) end)
    end
end

-- Function to change the weather
local function changeWeather(weatherIndex)
    local currentRegion = tes3.getRegion({useDoors = true})
    if currentRegion then
		changeWeather()
    --    mwse.log("Weather changed to %s.", weatherTypes[weatherIndex])

    end
end
-- Register the event listener for equipping items
event.register(tes3.event.equipped, tw_WeatherRingEquipped)

-------------------------------------------------------------------------
local function setDoOnce(ref,Var)
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.ringId = refData.ringId or {} -- Force initializing the parent table.
    refData.ringId.doOnce = Var -- Actually set your value.
end
local function getDoOnce(ref)
    local refData = ref.data
    return refData.ringId and refData.ringId.doOnce
end
local function onLoadWeatherRing(e)
--Only give them the weather ring once.
  if getDoOnce(e.reference) ~= true then
    setDoOnce(e.reference, true)
    mwscript.addItem({ reference = tes3.player, item = ringId, count = 1 })
    tes3.messageBox("You have been given the Weather ring" )
  end
  
end
--Register the "loaded" event
event.register("loaded", onLoadWeatherRing)

----------------------------------------------------------------------------

local function registerModConfig()
    local template = mwse.mcm.createTemplate("Weather Ring")
    template:saveOnClose("tw_weatherring", config)
    template:register()
	
	--local settings = page:createCategory("Weather ring Settings\n\n\n\nTransitions")
-- Create a simple container Page under Template
    local settings = template:createPage({ label = "Transition Settings" })
	
    -- First Yes/No option
    settings:createYesNoButton({
        label = "Disable transitions for all weathers",
        description = "Disable transitions all weathers.",
        variable = mwse.mcm.createTableVariable{ id = "enableOne", table = config }
    })

--   -- Second Yes/No option
--   settings:createYesNoButton({
--       label = "Disable transitions random only",
--       description = "Disable transitions for random weathers only.",
--       variable = mwse.mcm.createTableVariable{ id = "enableTwo", table = config }
--   })

end

event.register("modConfigReady", registerModConfig)