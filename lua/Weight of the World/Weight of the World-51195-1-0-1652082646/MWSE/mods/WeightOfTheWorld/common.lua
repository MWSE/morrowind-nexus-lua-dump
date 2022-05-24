local config = require("WeightOfTheWorld.config")
local this = {}

local inventoryMenuID = tes3ui.registerID("MenuInventory")
local weightBarID = tes3ui.registerID("MenuInventory_Weightbar")
local weightBarTextID = tes3ui.registerID("PartFillbar_text_ptr")

-- Force encumbrance to display to two digits past the decimal point in the menu.
function this.updateEncDisplay()
    local menu = tes3ui.findMenu(inventoryMenuID)

    if not menu then
        return
    end

    local weightBar = menu:findChild(weightBarID)
    local weightBarText = menu:findChild(weightBarTextID)

    if (not weightBar) or (not weightBarText) then
        return
    end

    local curEnc = weightBar.widget.current
    local maxEnc = weightBar.widget.max
    local oldText = weightBarText.text
    local newText

    if config.accurateDisplay then
        newText = string.format("%.2f/%.2f", curEnc, maxEnc)
    else
        -- Only happens when this function is called from the MCM when the player has disabled this setting. We do this
        -- so the menu will return to the less accurate display right away.
        newText = string.format("%.0f/%.0f", curEnc, maxEnc)
    end

    if oldText ~= newText then
        weightBarText.text = newText

        -- This is awkward but unfortunately necessary. The game seems to update the encumbrance display more than once
        -- when the player adds/removes items from a container, so we have to do this so the display doesn't revert.
        timer.frame.delayOneFrame(function()
            weightBarText.text = newText
        end)
    end
end

function this.getAttributes()
    local newStr = tes3.mobilePlayer.strength.current
    local newEnd = tes3.mobilePlayer.endurance.current
    local newAgi = tes3.mobilePlayer.agility.current
    return newStr, newEnd, newAgi
end

function this.changeEnc(newStr, newEnd, newAgi)
    -- tonumber is needed because the MCM will annoyingly convert numbers to strings in the config file.
    -- Also sanity check, this number and the multipliers should not be negative.
    local constantTerm = math.max(tonumber(config.constantTerm), 0)

    -- Negative value means no cap.
    local maxMax = (tonumber(config.maxMax) >= 0 and tonumber(config.maxMax)) or math.huge
    local curMaxEnc = tes3.mobilePlayer.encumbrance.base

    local strMult = math.max(tonumber(config.strMult), 0)
    local endMult = math.max(tonumber(config.endMult), 0)
    local agiMult = math.max(tonumber(config.agiMult), 0)

    local strComp = strMult * newStr
    local endComp = endMult * newEnd
    local agiComp = agiMult * newAgi

    local newMaxEnc = strComp + endComp + agiComp + constantTerm
    newMaxEnc = math.min(newMaxEnc, maxMax)

    if curMaxEnc ~= newMaxEnc then
        tes3.setStatistic{
            reference = tes3.player,
            name = "encumbrance",
            base = newMaxEnc,
        }
    end
end

return this