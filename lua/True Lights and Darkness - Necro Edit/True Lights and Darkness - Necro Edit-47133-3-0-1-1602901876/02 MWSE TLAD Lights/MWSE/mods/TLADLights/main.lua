local mod = "TLAD Lights"
local version = "3.0"

local config = require("TLADLights.config")
local data = require("TLADLights.data")

-- Print debug lines if the mod is configured to do so.
local function debugMsg(message)
    if config.debugMode then
        mwse.log("[%s %s DEBUG] %s", mod, version, message)
    end
end

local function onInitialized()
    local tlad = data.tlad
    local necro = data.necro
    local logical = data.logical

    -- Iterate through each light in the game's data one at a time.
    for light in tes3.iterateObjects(tes3.objectType.light) do
        local id = light.id:lower()
        local tladLight = tlad[id]

        -- If this light is not in the TLAD table, then it's not affected, so do nothing.
        if tladLight then
            debugMsg(string.format("Light %s is present in the TLAD table. Checking overrides.", id))
            local necroLight = necro[id]
            local logicalLight = logical[id]

            -- If a setting is set to use vanilla values, we don't want to make any changes.
            if config.name ~= "vanilla" then
                local table

                -- Determine which table we'll be looking at in advance, so we don't have to repeat the code actually making changes.
                if config.name == "necro" then
                    debugMsg("Light names are set to Necro edit.")
                    table = necroLight
                else
                    debugMsg("Light names are set to TLAD.")
                    table = tladLight
                end

                -- This light is in the TLAD table, but might not be in the Necro edit table.
                if table then
                    local name = table.name

                    -- If there's no name entry for this light in the table, then the name is not changed from vanilla, so do nothing.
                    if name then
                        debugMsg(string.format("Light %s name changed from %s to %s.", id, light.name, name))
                        light.name = name
                    else
                        debugMsg(string.format("Light %s does not have a name entry in the relevant table. Skipping name.", id))
                    end
                else
                    debugMsg(string.format("Light %s is not present in the relevant table. Skipping name.", id))
                end
            else
                debugMsg("Light names are set to vanilla. Skipping name.")
            end

            if config.weight ~= "vanilla" then
                debugMsg("Light weights are set to TLAD.")
                local weight = tladLight.weight

                -- In this case the only option other than vanilla is TLAD, so we just check the TLAD table.
                if weight then
                    debugMsg(string.format("Light %s weight changed from %.2f to %.2f.", id, light.weight, weight))
                    light.weight = weight
                else
                    debugMsg(string.format("Light %s does not have a weight entry in the relevant table. Skipping weight.", id))
                end
            else
                debugMsg("Light weights are set to vanilla. Skipping weight.")
            end

            if config.value ~= "vanilla" then
                debugMsg("Light values are set to TLAD.")
                local value = tladLight.value

                if value then
                    debugMsg(string.format("Light %s value changed from %.0f to %.0f.", id, light.value, value))
                    light.value = value
                else
                    debugMsg(string.format("Light %s does not have a value entry in the relevant table. Skipping value.", id))
                end
            else
                debugMsg("Light values are set to vanilla. Skipping value.")
            end

            if config.time ~= "vanilla" then
                debugMsg("Light times are set to TLAD.")
                local time = tladLight.time

                if time then
                    debugMsg(string.format("Light %s time changed from %.0f to %.0f.", id, light.time, time))
                    light.time = time
                else
                    debugMsg(string.format("Light %s does not have a time entry in the relevant table. Skipping time.", id))
                end
            else
                debugMsg("Light times are set to vanilla. Skipping time.")
            end

            if config.radius ~= "vanilla" then
                debugMsg("Light radius is set to TLAD.")
                local radius = tladLight.radius

                if radius then
                    debugMsg(string.format("Light %s radius changed from %.0f to %.0f.", id, light.radius, radius))
                    light.radius = radius
                else
                    debugMsg(string.format("Light %s does not have a radius entry in the relevant table. Skipping radius.", id))
                end
            else
                debugMsg("Light radius is set to vanilla. Skipping radius.")
            end

            if config.color ~= "vanilla" then
                local table

                if config.color == "necro" then
                    debugMsg("Light colors are set to Necro edit.")
                    table = necroLight
                else
                    debugMsg("Light colors are set to TLAD.")
                    table = tladLight
                end

                if table then
                    local color = table.color

                    -- Color is a table so it's handled a bit differently. r, g, b are aliases for the 1st/2nd/3rd entries in the tes3vector3 in the data table.
                    -- One or two of these colors might not be different, but at least one is guaranteed to be different from vanilla if color is in the table.
                    if color then
                        debugMsg(string.format("Light %s color: Red changed from %.0f to %.0f. Green changed from %.0f to %.0f. Blue changed from %.0f to %.0f.", id, light.color[1], color.r, light.color[2], color.g, light.color[3], color.b))
                        light.color[1] = color.r
                        light.color[2] = color.g
                        light.color[3] = color.b
                    else
                        debugMsg(string.format("Light %s does not have a color entry in the relevant table. Skipping color.", id))
                    end
                else
                    debugMsg(string.format("Light %s is not present in the relevant table. Skipping color.", id))
                end
            else
                debugMsg("Light colors are set to vanilla. Skipping color.")
            end

            if config.dynamic ~= "vanilla" then
                debugMsg("Light dynamic flag is set to TLAD.")
                local dynamic = tladLight.dynamic

                -- We have to specify that it's not equal to nil here because it's a boolean and we want to include false.
                if dynamic ~= nil then
                    debugMsg(string.format("Light %s dynamic flag changed from %s to %s.", id, light.isDynamic, dynamic))
                    light.isDynamic = dynamic
                else
                    debugMsg(string.format("Light %s does not have a dynamic flag entry in the relevant table. Skipping dynamic flag.", id))
                end
            else
                debugMsg("Light dynamic flag is set to vanilla. Skipping dynamic flag.")
            end

            if config.defaultOff ~= "vanilla" then
                debugMsg("Light off by default flag is set to TLAD.")
                local defaultOff = tladLight.defaultOff

                if defaultOff ~= nil then
                    debugMsg(string.format("Light %s off by default flag changed from %s to %s.", id, light.isOffByDefault, defaultOff))
                    light.isOffByDefault = defaultOff
                else
                    debugMsg(string.format("Light %s does not have an off by default flag entry in the relevant table. Skipping off by default flag.", id))
                end
            else
                debugMsg("Light off by default flag is set to vanilla. Skipping off by default flag.")
            end

            if config.flicker ~= "vanilla" then
                local table

                if config.flicker == "logical" then
                    debugMsg("Light flicker is set to logical.")
                    table = logicalLight
                elseif config.flicker == "necro" then
                    debugMsg("Light flicker is set to Necro edit.")
                    table = necroLight
                else
                    debugMsg("Light flicker is set to TLAD.")
                    table = tladLight
                end

                if table then

                    -- The "pulses" attribute (fast pulse) is not changed for any light in any of the tables, so we don't include it.
                    local flickerFast = table.flickerFast
                    local flickerSlow = table.flickerSlow
                    local pulseSlow = table.pulseSlow

                    if flickerFast ~= nil then
                        debugMsg(string.format("Light %s fast flicker changed from %s to %s.", id, light.flickers, flickerFast))
                        light.flickers = flickerFast
                    else
                        debugMsg(string.format("Light %s does not have a fast flicker entry in the relevant table. Skipping fast flicker.", id))
                    end

                    if flickerSlow ~= nil then
                        debugMsg(string.format("Light %s slow flicker changed from %s to %s.", id, light.flickersSlowly, flickerSlow))
                        light.flickersSlowly = flickerSlow
                    else
                        debugMsg(string.format("Light %s does not have a slow flicker entry in the relevant table. Skipping slow flicker.", id))
                    end

                    if pulseSlow ~= nil then
                        debugMsg(string.format("Light %s slow pulse changed from %s to %s.", id, light.pulsesSlowly, pulseSlow))
                        light.pulsesSlowly = pulseSlow
                    else
                        debugMsg(string.format("Light %s does not have a slow pulse entry in the relevant table. Skipping slow pulse.", id))
                    end
                else
                    debugMsg(string.format("Light %s is not present in the relevant table. Skipping flicker.", id))
                end
            else
                debugMsg("Light flicker is set to vanilla. Skipping flicker.")
            end
        else
            debugMsg(string.format("Light %s is not present in the TLAD table. Skipping.", id))
        end
    end

    mwse.log("[%s %s] Initialized.", mod, version)
end

event.register("initialized", onInitialized)

-- Register the Mod Config Menu.
local function onModConfigReady()
    dofile("Data Files\\MWSE\\mods\\TLADLights\\mcm.lua")
end

event.register("modConfigReady", onModConfigReady)