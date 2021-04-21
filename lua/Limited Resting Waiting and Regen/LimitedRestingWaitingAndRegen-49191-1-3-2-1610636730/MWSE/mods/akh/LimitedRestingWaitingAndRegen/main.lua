require('akh.LimitedRestingWaitingAndRegen.MCM')
local modInfo = require('akh.LimitedRestingWaitingAndRegen.ModInfo')

local function onInitialized()
    require('akh.LimitedRestingWaitingAndRegen.events.EventBus')
    require('akh.LimitedRestingWaitingAndRegen.modules.UI')
    require('akh.LimitedRestingWaitingAndRegen.modules.Resting')
    require('akh.LimitedRestingWaitingAndRegen.modules.Healing')
    require('akh.LimitedRestingWaitingAndRegen.modules.Magicka')
    print("[" .. modInfo.modName .. " " .. modInfo.modVersion .. "] Initialized")
end

event.register("initialized", onInitialized)