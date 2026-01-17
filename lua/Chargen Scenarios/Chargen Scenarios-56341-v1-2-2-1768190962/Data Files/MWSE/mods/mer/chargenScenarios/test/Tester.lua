local UnitWind = include('unitwind.unitwind')
local common = require "mer.chargenScenarios.common"
local mcmConfig = common.config.mcm
if UnitWind then
    return UnitWind.new{
        enabled = mcmConfig.doTests,
        highlight = true,
        afterTest = function()
            if tes3.player and tes3.player.testPlayerObject then
                tes3.player = nil
            end
        end,
    }
end