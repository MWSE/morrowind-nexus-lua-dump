local interop = require("sanekEnchant.interop")

local function onLoaded()
    interop.applyEnchantGMST()
end

local function onInitialized()
    event.register("loaded", onLoaded)    
end

event.register("initialized", onInitialized)

local function onModConfigReady()
    dofile("sanekEnchant.mcm")
end

event.register("modConfigReady", onModConfigReady)