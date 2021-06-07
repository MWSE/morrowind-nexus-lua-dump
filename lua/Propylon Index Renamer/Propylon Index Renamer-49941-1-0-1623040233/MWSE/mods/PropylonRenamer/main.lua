local modInfo = require("PropylonRenamer.modInfo")
local config = require("PropylonRenamer.config")
local data = require("PropylonRenamer.data")

local function onInitialized()
    if config.enable then

        -- Go through all indexes in the data table one at a time.
        for _, dataIndex in ipairs(data.indexes) do
            local id = dataIndex.id
            local index = tes3.getObject(id)

            if index then

                -- In the case of the Master Index, change the name only if the mod is configured to do so.
                if config.master
                or not dataIndex.master then
                    index.name = dataIndex.name
                end
            end
        end
    end

    mwse.log("[%s %s] Initialized.", modInfo.mod, modInfo.version)
end

event.register("initialized", onInitialized)

local function onModConfigReady()
    dofile("Data Files\\MWSE\\mods\\PropylonRenamer\\mcm.lua")
end

event.register("modConfigReady", onModConfigReady)