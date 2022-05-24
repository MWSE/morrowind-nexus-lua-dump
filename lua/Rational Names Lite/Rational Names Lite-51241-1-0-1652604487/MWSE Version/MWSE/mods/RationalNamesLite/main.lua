local mod = "Rational Names Lite"
local version = "1.0"
local modVersion = string.format("[%s %s]", mod, version)

local data = require("RationalNamesLite.data")

local function onInitialized()
    for id, newName in pairs(data.newNames) do
        local object = tes3.getObject(id)

        if object then
            object.name = newName
        end
    end

    mwse.log("%s Initialized.", modVersion)
end

event.register("initialized", onInitialized)