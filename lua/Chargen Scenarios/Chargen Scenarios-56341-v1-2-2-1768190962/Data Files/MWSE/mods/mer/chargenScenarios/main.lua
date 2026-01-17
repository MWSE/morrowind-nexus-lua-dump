local enabled = true
if not enabled then
    return
end


local common = require('mer.chargenScenarios.common')
local logger = common.createLogger("main")
--Do MCM
require('mer.chargenScenarios.mcm')

event.register("initialized", function()
    common.initAll("mer\\chargenScenarios\\integrations")
    common.initAll("mer\\chargenScenarios\\menus")
    common.initAll("mer\\chargenScenarios\\features")
    common.initAll("mer\\chargenScenarios\\modules")
    logger:info("Initialized v^%s", common.getVersion())
    event.trigger("ChargenScenarios:Initialized")
end)


-- ---@param e loadEventData
-- event.register("loaded", function(e)
--     if e.newGame then
--         if common.config.mcm.enabled then
--             tes3.getObject("player").inventory:removeItem{item = tes3.getObject("common_shoes_01")}
--             tes3.getObject("player").inventory:removeItem{item = tes3.getObject("common_shirt_01")}
--             tes3.getObject("player").inventory:removeItem{item = tes3.getObject("common_pants_01")}
--         else
--             tes3.getObject("player").inventory:addItem{item = tes3.getObject("common_shoes_01")}
--             tes3.getObject("player").inventory:addItem{item = tes3.getObject("common_shirt_01")}
--             tes3.getObject("player").inventory:addItem{item = tes3.getObject("common_pants_01")}
--         end
--     end
-- end)

--Run Unit tests
require('mer.chargenScenarios.test.unitTests')
require('mer.chargenScenarios.test.initializedTests')
require('mer.chargenScenarios.test.gameLoadedTests')
