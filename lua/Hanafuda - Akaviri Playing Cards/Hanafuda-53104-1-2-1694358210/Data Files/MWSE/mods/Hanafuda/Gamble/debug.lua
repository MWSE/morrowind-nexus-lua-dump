local config = require("Hanafuda.config")

-- gamble ui
event.register(tes3.event.keyDown,
---@param e keyDownEventData
function(e)
    local mod = e.isAltDown or e.isControlDown or e.isShiftDown or e.isSuperDown
    if mod then
        return
    end
    require("Hanafuda.Gamble.ui").CreateBettingMenu(123456, {0, 1, 2}, {true, true, false}, 3 * config.koikoi.round)
end, { filter = tes3.scanCode.x })
