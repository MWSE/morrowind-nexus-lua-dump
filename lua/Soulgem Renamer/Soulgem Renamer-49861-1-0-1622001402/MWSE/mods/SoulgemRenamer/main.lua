local modInfo = require("SoulgemRenamer.modInfo")
local config = require("SoulgemRenamer.config")
local data = require("SoulgemRenamer.data")

local function onInitialized()
    if config.enable then

        -- Go through all soulgems in the data table one at a time.
        for _, dataSoulgem in ipairs(data.soulgems) do
            local id = dataSoulgem.id
            local soulgem = tes3.getObject(id)

            if soulgem then

                -- In the case of Azura's Star, change the name only if the mod is configured to do so.
                if config.azura
                or not dataSoulgem.azura then
                    soulgem.name = dataSoulgem.name
                end
            end
        end
    end

    mwse.log(string.format("[%s %s] Initialized.", modInfo.mod, modInfo.version))
end

event.register("initialized", onInitialized)

local function onModConfigReady()
    dofile("Data Files\\MWSE\\mods\\SoulgemRenamer\\mcm.lua")
end

event.register("modConfigReady", onModConfigReady)