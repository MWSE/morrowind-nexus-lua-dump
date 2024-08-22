local cfg = require("BeefStranger.Experience Bar.config")
local menu = {
    Main = nil, ---@type tes3uiElement
    Main_Id = tes3ui.registerID("bsExpHelpMenu"),
    Main_NonDrag = nil, ---@type tes3uiElement

    FillBar = nil, ---@type tes3uiElement
    FillBar_Id = tes3ui.registerID("Exp Bar"), --FillBar MenuID
    FillBar_Text = nil,---@type tes3uiElement

    widget = nil, ---@type tes3uiWidget
    displayTimer = nil, ---@type mwseTimer
    fadeTimer = nil, ---@type mwseTimer
}

function menu:get()
    return tes3ui.findHelpLayerMenu(self.Main_Id)
end

function menu.create() --Initialize Menu on save load
    if not menu:get() then
        menu.Main = tes3ui.createHelpLayerMenu({ id = menu.Main_Id }) --HelpMenu Creation
    end

    local Main = menu.Main

    Main.absolutePosAlignY = 1 --Bottom of screen
    Main.visible = false --HelpMenu not visible by default WILL BE FALSE ON ACTUAL MENU
    Main.alpha = 0 --Remove Black Background
    Main.minHeight = 0 --Remove MinHeight to Shrink more

    Main.children[2].paddingAllSides = 0 --Remove Padding from "PartNonDragMenu_main"

    menu.FillBar = Main:createFillBar({id = menu.FillBar_Id,  max = 100}) --Make the fillbar
    menu.FillBar.width = tes3ui.getViewportSize() --Set its width to screen width
    menu.FillBar.height = 13
    menu.FillBar.contentPath = "" --Remove extra decoration
    menu.FillBar.scaleMode = true
    menu.FillBar.imageScaleY = 0.01
    menu.FillBar.childOffsetY = -3

    menu.FillBar_Text = menu.FillBar.children[2]
    menu.FillBar_Text.absolutePosAlignY = 0.80
    menu.widget = menu.FillBar.widget
    menu.widget.fillAlpha = 1

    Main:updateLayout()
end


---@param e exerciseSkillEventData
function menu.skillUp(e)
    if not cfg.blacklist[tes3.skillName[e.skill]] then
        if menu:get() then
            timer.delayOneFrame(function()
                menu.fadeOutCancel()
                menu.Main.visible = true
                menu.widget.current = menu.skillProgress(e.skill)
                menu.fillText(e)
                menu:alpha(1)
                menu.Main:updateLayout()
                menu.displayTimerCheck()
            end, timer.real)
        end
    end
end

---Cancel the fadeOut Timer
function menu.fadeOutCancel()
    if menu.fadeOutRunning() then
        menu.fadeTimer:cancel()
    end
end

---Get if fadeTimer running
function menu.fadeOutRunning()
    return menu.fadeTimer and menu.fadeTimer.state ~= 2
end

---Check if displayTimer Running, if it is reset, if not start
function menu.displayTimerCheck()
    if menu.displayTimerRunning() then
        menu.displayTimer:reset()
    else
        menu:displayTime()
    end
end

---Get if displayTimer is running
function menu.displayTimerRunning()
    return menu.displayTimer and menu.displayTimer.state ~= 2
end

---Create Timer for how long ui should be visible before fadeout
function menu:displayTime()
    if self.displayTimerRunning() then
        self.displayTimer:cancel()
    end

    self.displayTimer = timer.start{
        duration = cfg.displayTime,
        callback = function (e)
            if self.fadeOutRunning() then
                self.fadeTimer:cancel()
            else
                self:fadeOut()
            end
        end
    }
end

---Set alpha of fillbar elements
---@param alpha number What to set fillbar alpha
function menu:alpha(alpha)
    if not self.widget then return end
    self.FillBar_Text.alpha = alpha
    self.widget.fillAlpha = alpha
end

---Create Timer to slowly fadeout ui
function menu:fadeOut()
    if menu.fadeOutRunning() then
        self.fadeTimer:cancel()
    end

    if self.widget then
        self.fadeTimer = timer.start {
            duration = 0.1,
            iterations = 50,
            type = timer.real,
            callback = function(e)
                self:alpha(self.FillBar_Text.alpha - 0.02)
                self.Main:updateLayout()
            end
        }
    end
end

---Get the Base Level of Player Skill
---@param skill tes3.skill
---@return number
function menu.getLevel(skill)
    return tes3.mobilePlayer:getSkillStatistic(skill).base
end

---Generate the FillBar Text
---@param e exerciseSkillEventData
function menu.fillText(e)
    local text = string.format("%s %s  |  ", tes3.skillName[e.skill], menu.getLevel(e.skill))
    menu.FillBar_Text.text = text .. menu.FillBar_Text.text
end

---Gets the normalized Progress towards next level of Skill
---@param skill tes3.skill
---@return integer skillProgress
function menu.skillProgress(skill)
    local progress = tes3.mobilePlayer.skillProgress[skill + 1]
    local progressRequirement = tes3.mobilePlayer:getSkillProgressRequirement(skill)
    local normalizedProgress = (progress / progressRequirement) * 100
    return math.floor(normalizedProgress)
end


event.register("initialized", function()
    print("[MWSE:Experience Bar] initialized")
end)
event.register(tes3.event.loaded, menu.create)
event.register(tes3.event.exerciseSkill, menu.skillUp)