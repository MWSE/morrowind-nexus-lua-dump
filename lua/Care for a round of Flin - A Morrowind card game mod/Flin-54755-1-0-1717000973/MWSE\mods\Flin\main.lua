local lib = require("Flin.lib")
local log = lib.log

-- --- @param e keyDownEventData
-- local function keyDownCallback(e)
--     if e.isAltDown then
--         if e.keyCode == tes3.scanCode["o"] then
--             local t = lib.getLookedAtReference()
--             if t then
--                 local refBelow = lib.FindRefBelow(t)
--                 if refBelow then
--                     local position = lib.findPlayerPosition(refBelow)
--                     lib.DEBUG_ShowMarkerAt(position)
--                 end
--             end
--         end
--     end
-- end
-- event.register(tes3.event.keyDown, keyDownCallback)

local GAME_TOPIC = "game of Flin"
local DECK_TOPIC = "deck of Flin cards"
local RULES_TOPIC = "rules of Flin"

--- @param e loadedEventData
local function loadedCallback(e)
    local result = tes3.addTopic({
        topic = GAME_TOPIC
    })
    log:debug("addTopic %s: %s", GAME_TOPIC, result)

    local result2 = tes3.addTopic({
        topic = DECK_TOPIC
    })
    log:debug("addTopic %s: %s", DECK_TOPIC, result2)

    local result3 = tes3.addTopic({
        topic = RULES_TOPIC
    })
    log:debug("addTopic %s: %s", RULES_TOPIC, result3)
end
event.register(tes3.event.loaded, loadedCallback)


-- /////////////////////////////////////////////////////////////////////////////////////////
-- ////////////// CONFIG
require("Flin.mcm")
