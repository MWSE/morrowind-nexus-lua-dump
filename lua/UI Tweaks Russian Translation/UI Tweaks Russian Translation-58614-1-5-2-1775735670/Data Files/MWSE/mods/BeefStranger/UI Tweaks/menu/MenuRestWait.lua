local id = require("BeefStranger.UI Tweaks.ID")
local cfg = require("BeefStranger.UI Tweaks.config")
local bs = require("BeefStranger.UI Tweaks.common")
---@class bs_RestWait_This
local this = {}

---@class bsMenuRestWait
local Rest = {}

function Rest:get() return tes3ui.findMenu(tes3ui.registerID(id.RestWait)) end
function Rest:child(child) return self:get() and self:get():findChild(child) end
function Rest:Scrollbar() return self:child("MenuRestWait_scrollbar") end
function Rest:ButtonBlock() return self:child("MenuRestWait_buttonlayout") end
function Rest:WaitButton() return self:child("MenuRestWait_wait_button") end
function Rest:RestButton() return self:child("MenuRestWait_rest_button") end
function Rest:HealedButton() return self:child("MenuRestWait_untilhealed_button") end
function Rest:LeftArrow() return self:child("PartScrollBar_left_arrow") end
function Rest:RightArrow() return self:child("PartScrollBar_right_arrow") end
function Rest:CancelButton() return self:child("MenuRestWait_cancel_button") end
function Rest:FullRest() return self:child("Full Rest") end
function Rest:TimeUp() return self:child("timeUp") end
function Rest:TimeDown() return self:child("timeDown") end

---Triggers whatever button is Visible
function Rest:trigger_wait_rest()
    if self:RestButton().visible then
        self:RestButton():bs_click({playSound = false})
    elseif self:WaitButton().visible then
        self:WaitButton():bs_click({playSound = false})
    end
end

---@param e uiEventEventData
function this.trigger24hr(e)
    Rest:Scrollbar().widget.current = 23
    Rest:Scrollbar():bs_scrollChanged()
    Rest:trigger_wait_rest()
end

---@param amount number
function Rest:change_Time(amount)
    local scroll = Rest:Scrollbar()
    scroll.widget.current = math.clamp(scroll.widget.current + amount, 0, 23)
    scroll:bs_scrollChanged()
    scroll:bs_Update()
end

---@param e uiActivatedEventData
function this.onRestMenu(e)
    e.element.minWidth = 367
    local timeUp = e.element:createBlock{id = "timeUp"}
    local timeDown = e.element:createBlock{id = "timeDown"}

    timeUp:bs_holdClick({
        accelerate = true,
        triggerClick = true,
        startInterval = 0.12,
        minInterval = 0.05,
        acceleration = 0.97,
        skipFirstClick = false,
        keyControl = true,
        playSound = true
    })
    timeDown:bs_holdClick({
        accelerate = true,
        triggerClick = true,
        startInterval = 0.12,
        minInterval = 0.05,
        acceleration = 0.97,
        skipFirstClick = false,
        keyControl = true,
        playSound = true
    })

    timeUp:registerAfter(tes3.uiEvent.mouseClick, function (e) Rest:change_Time(1) end)
    timeDown:registerAfter(tes3.uiEvent.mouseClick, function (e) Rest:change_Time(-1) end)

    if cfg.wait.fullRest then
        Rest:ButtonBlock().autoWidth = true
        local fullRest = Rest:ButtonBlock():createButton{id = "Full Rest", text = "24 часа"}
        fullRest.borderAllSides = 0
        fullRest.absolutePosAlignX = 0
        fullRest:register(tes3.uiEvent.mouseClick, this.trigger24hr)
        e.element:updateLayout()
    end
end
event.register(tes3.event.uiActivated, this.onRestMenu, { filter = "MenuRestWait" })

return Rest
