local config = require("TLADLights.config")
local data = require("TLADLights.data")
local modInfo = require("TLADLights.modInfo")

local function debugMsg(message)
    if config.debugMode then
        mwse.log("%s DEBUG: %s", modInfo.modVersion, message)
    end
end

local function onInitialized()
    local tlad = data.tlad
    local necro = data.necro
    local logical = data.logical
    local glowing = data.glowing

    -- Iterate through each light in the game's data one at a time.
    for light in tes3.iterateObjects(tes3.objectType.light) do
        local id = light.id:lower()
        local tladLight = tlad[id]
        local glowingLight = glowing[id]

        -- If this light is not in the TLAD table, then it's not affected (for most settings), so do nothing.
        if tladLight then
            debugMsg(string.format("%s: Present in the TLAD table. Checking main overrides.", id))
            local necroLight = necro[id]
            local logicalLight = logical[id]

            -- If a setting is set to use vanilla values, we don't want to make any changes.
            if config.name ~= "vanilla" then
                local table

                -- Determine which table we'll be looking at in advance, so we don't have to repeat the code actually
                -- making changes.
                if config.name == "necro" then
                    debugMsg(string.format("%s: Names are set to Necro edit.", id))
                    table = necroLight
                else
                    debugMsg(string.format("%s: Names are set to TLAD.", id))
                    table = tladLight
                end

                -- This light is in the TLAD table, but might not be in the Necro edit table.
                if table then
                    local name = table.name

                    -- If there's no name entry for this light in the table, then the name is not changed from vanilla,
                    -- so do nothing.
                    if name then
                        debugMsg(string.format("%s: Name changed from %s to %s.", id, light.name, name))
                        light.name = name
                    else
                        debugMsg(string.format("%s: Does not have a name entry in the relevant table. Skipping name.", id))
                    end
                else
                    debugMsg(string.format("%s: Not present in the relevant table. Skipping name.", id))
                end
            else
                debugMsg(string.format("%s: Names are set to vanilla. Skipping name.", id))
            end

            if config.weight ~= "vanilla" then
                debugMsg(string.format("%s: Weights are set to TLAD.", id))
                local weight = tladLight.weight

                -- In this case the only option other than vanilla is TLAD, so we just check the TLAD table.
                if weight then
                    debugMsg(string.format("%s: Weight changed from %.2f to %.2f.", id, light.weight, weight))
                    light.weight = weight
                else
                    debugMsg(string.format("%s: Does not have a weight entry in the relevant table. Skipping weight.", id))
                end
            else
                debugMsg(string.format("%s: Weights are set to vanilla. Skipping weight.", id))
            end

            if config.value ~= "vanilla" then
                debugMsg(string.format("%s: Values are set to TLAD.", id))
                local value = tladLight.value

                if value then
                    debugMsg(string.format("%s: Value changed from %.0f to %.0f.", id, light.value, value))
                    light.value = value
                else
                    debugMsg(string.format("%s: Does not have a value entry in the relevant table. Skipping value.", id))
                end
            else
                debugMsg(string.format("%s: Values are set to vanilla. Skipping value.", id))
            end

            if config.time ~= "vanilla" then
                debugMsg(string.format("%s: Times are set to TLAD.", id))
                local time = tladLight.time

                if time then
                    debugMsg(string.format("%s: Time changed from %.0f to %.0f.", id, light.time, time))
                    light.time = time
                else
                    debugMsg(string.format("%s: Does not have a time entry in the relevant table. Skipping time.", id))
                end
            else
                debugMsg(string.format("%s: Times are set to vanilla. Skipping time.", id))
            end

            if config.radius ~= "vanilla" then
                debugMsg(string.format("%s: Radius is set to TLAD.", id))
                local radius = tladLight.radius

                if radius then
                    debugMsg(string.format("%s: Radius changed from %.0f to %.0f.", id, light.radius, radius))
                    light.radius = radius
                else
                    debugMsg(string.format("%s: Does not have a radius entry in the relevant table. Skipping radius.", id))
                end
            else
                debugMsg(string.format("%s: Radius is set to vanilla. Skipping radius.", id))
            end

            if config.color ~= "vanilla" then
                local table

                if config.color == "necro" then
                    debugMsg(string.format("%s: Colors are set to Necro edit.", id))
                    table = necroLight
                else
                    debugMsg(string.format("%s: Colors are set to TLAD.", id))
                    table = tladLight
                end

                if table then
                    local color = table.color

                    -- Color is a table so it's handled a bit differently. r, g, b are aliases for the 1st/2nd/3rd
                    -- entries in the tes3vector3 in the data table. One or two of these colors might not be different,
                    -- but at least one is guaranteed to be different from vanilla if color is in the table.
                    if color then
                        debugMsg(string.format("%s: Color: Red changed from %.0f to %.0f. Green changed from %.0f to %.0f. Blue changed from %.0f to %.0f.", id, light.color[1], color.r, light.color[2], color.g, light.color[3], color.b))
                        light.color[1] = color.r
                        light.color[2] = color.g
                        light.color[3] = color.b
                    else
                        debugMsg(string.format("%s: Does not have a color entry in the relevant table. Skipping color.", id))
                    end
                else
                    debugMsg(string.format("%s: Not present in the relevant table. Skipping color.", id))
                end
            else
                debugMsg(string.format("%s: Colors are set to vanilla. Skipping color.", id))
            end

            if config.dynamic ~= "vanilla" then
                debugMsg(string.format("%s: Dynamic flag is set to TLAD.", id))
                local dynamic = tladLight.dynamic

                -- We have to specify that it's not equal to nil here because it's a boolean and we want to include
                -- false.
                if dynamic ~= nil then
                    debugMsg(string.format("%s: Dynamic flag changed from %s to %s.", id, light.isDynamic, dynamic))
                    light.isDynamic = dynamic
                else
                    debugMsg(string.format("%s: Does not have a dynamic flag entry in the relevant table. Skipping dynamic flag.", id))
                end
            else
                debugMsg(string.format("%s: Dynamic flag is set to vanilla. Skipping dynamic flag.", id))
            end

            if config.defaultOff ~= "vanilla" then
                debugMsg(string.format("%s: Off by default flag is set to TLAD.", id))
                local defaultOff = tladLight.defaultOff

                if defaultOff ~= nil then
                    debugMsg(string.format("%s: Off by default flag changed from %s to %s.", id, light.isOffByDefault, defaultOff))
                    light.isOffByDefault = defaultOff
                else
                    debugMsg(string.format("%s: Does not have an off by default flag entry in the relevant table. Skipping off by default flag.", id))
                end
            else
                debugMsg(string.format("%s: Off by default flag is set to vanilla. Skipping off by default flag.", id))
            end

            if config.flicker ~= "vanilla" then
                local table

                if config.flicker == "logical" then
                    debugMsg(string.format("%s: Flicker is set to logical.", id))
                    table = logicalLight
                elseif config.flicker == "necro" then
                    debugMsg(string.format("%s: Flicker is set to Necro edit.", id))
                    table = necroLight
                else
                    debugMsg(string.format("%s: Flicker is set to TLAD.", id))
                    table = tladLight
                end

                if table then
                    -- The "pulses" attribute (fast pulse) is not changed for any light in any of the tables, so we
                    -- don't include it.
                    local flickerFast = table.flickerFast
                    local flickerSlow = table.flickerSlow
                    local pulseSlow = table.pulseSlow

                    if flickerFast ~= nil then
                        debugMsg(string.format("%s: Fast flicker changed from %s to %s.", id, light.flickers, flickerFast))
                        light.flickers = flickerFast
                    else
                        debugMsg(string.format("%s: Does not have a fast flicker entry in the relevant table. Skipping fast flicker.", id))
                    end

                    if flickerSlow ~= nil then
                        debugMsg(string.format("%s: Slow flicker changed from %s to %s.", id, light.flickersSlowly, flickerSlow))
                        light.flickersSlowly = flickerSlow
                    else
                        debugMsg(string.format("%s: Does not have a slow flicker entry in the relevant table. Skipping slow flicker.", id))
                    end

                    if pulseSlow ~= nil then
                        debugMsg(string.format("%s: Slow pulse changed from %s to %s.", id, light.pulsesSlowly, pulseSlow))
                        light.pulsesSlowly = pulseSlow
                    else
                        debugMsg(string.format("%s: Does not have a slow pulse entry in the relevant table. Skipping slow pulse.", id))
                    end
                else
                    debugMsg(string.format("%s: Not present in the relevant table. Skipping flicker.", id))
                end
            else
                debugMsg(string.format("%s: Flicker is set to vanilla. Skipping flicker.", id))
            end
        else
            debugMsg(string.format("%s: Not present in the TLAD table. Skipping main overrides.", id))
        end

        -- We need to handle this separately from the others, because there are lights in the Glowing Flames table that
        -- are not in the TLAD table.
        if glowingLight then
            if config.mesh ~= "vanilla" then
                debugMsg(string.format("%s: Meshes are set to Glowing Flames.", id))
                local mesh = glowingLight.mesh

                if mesh then
                    debugMsg(string.format("%s: Mesh changed from %s to %s.", id, light.mesh, mesh))
                    light.mesh = mesh
                else
                    -- This should never happen; any light in this table has a mesh entry.
                    debugMsg(string.format("%s: Does not have a mesh entry in the relevant table. Skipping mesh.", id))
                end
            else
                debugMsg(string.format("%s: Meshes are set to vanilla. Skipping mesh.", id))
            end
        else
            debugMsg(string.format("%s: Not present in the Glowing Flames table. Skipping mesh.", id))
        end
    end

    mwse.log("%s Initialized.", modInfo.modVersion)
end

event.register("initialized", onInitialized)

local function onModConfigReady()
    dofile("TLADLights.mcm")
end

event.register("modConfigReady", onModConfigReady)