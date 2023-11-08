local distantLandConfig = require("colossus.distantLandConfig")

local function barrier()
    local position = tes3.player.position
    local tempData = tes3.player.tempData
    local previous = tempData.ggw_prevPos

    local max = 32000
    if position.x > max
        or position.x < -max
        or position.y > max
        or position.y < -max
    then
        tes3.player.position = previous:copy()
        tes3.messageBox(" ")
        tes3.messageBox(" ")
        tes3.messageBox(
            "The endless dunes of Elsweyr stretch out before you. Straying too far from the oasis would be unwise."
        )
    else
        tempData.ggw_prevPos = position:copy()
    end
end

local function enteredElsweyr()
    tes3.player.tempData.ggw_prevPos = tes3.player.position:copy()

    distantLandConfig.setEnabled(true)

    if not event.isRegistered("simulate", barrier) then
        event.register("simulate", barrier)
    end
end

local function exitedElsweyr()
    tes3.player.tempData.ggw_prevPos = nil

    distantLandConfig.setEnabled(false)

    event.unregister("simulate", barrier)
end
event.register("loaded", exitedElsweyr)

---@param e cellChangedEventData
local function onCellChanged(e)
    local previous = e.previousCell and e.previousCell.id or ""

    local isElsweyr = e.cell.id:endswith("Elsweyr, Oasis")
    local wasElsweyr = previous:endswith("Elsweyr, Oasis")
    if isElsweyr and not wasElsweyr then
        enteredElsweyr()
    elseif wasElsweyr and not isElsweyr then
        exitedElsweyr()
    end
end
event.register("cellChanged", onCellChanged)
