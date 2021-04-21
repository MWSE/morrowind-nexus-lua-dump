local mod = "Consistent Keys"
local version = "2.1"

local config = require("ConsistentKeys.config")
local data = require("ConsistentKeys.data")

local function onInitialized()
    if config.enable then

        -- Go through all keys in the data table one at a time.
        for _, dataKey in ipairs(data.keys) do
            local id = dataKey.id
            local key = tes3.getObject(id)

            -- Make sure the key exists in the game first.
            if key then

                -- Only change the name if the key is not blacklisted.
                if not config.blacklist[id] then
                    key.name = dataKey.name
                end

                key.value = 0
                key.weight = 0
            end
        end
    end

    mwse.log(string.format("[%s %s] Initialized.", mod, version))
end

event.register("initialized", onInitialized)

-- Register the Mod Config Menu.
local function onModConfigReady()
    dofile("Data Files\\MWSE\\mods\\ConsistentKeys\\mcm.lua")
end

event.register("modConfigReady", onModConfigReady)