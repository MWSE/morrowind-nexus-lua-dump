require('akh.SanctionedIndorilArmor.MCM')
local modInfo = require('akh.SanctionedIndorilArmor.ModInfo')

local function onInitialized()
    require('akh.SanctionedIndorilArmor.events.EventBus')
    require('akh.SanctionedIndorilArmor.modules.OrdinatorUniform')
    print("[" .. modInfo.modName .. " " .. modInfo.modVersion .. "] Initialized")
end

event.register("initialized", onInitialized)