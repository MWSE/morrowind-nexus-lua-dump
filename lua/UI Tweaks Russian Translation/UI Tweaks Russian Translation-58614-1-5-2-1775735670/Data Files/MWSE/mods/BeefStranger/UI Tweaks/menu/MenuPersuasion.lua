local bs = require("BeefStranger.UI Tweaks.common")
local cfg = require("BeefStranger.UI Tweaks.config")
local id = require("BeefStranger.UI Tweaks.ID")

---@class bsMenuPersuasion
local Persuasion = {}
function Persuasion:Admire() return bs.findText(self:ServiceList().children[1],"Вежливо") end
function Persuasion:Intimidate() return bs.findText(self:ServiceList().children[2],"Угрожающе") end
function Persuasion:Taunt() return bs.findText(self:ServiceList().children[3], "Оскорбительно") end
function Persuasion:Bribe10() return bs.findText(self:ServiceList().children[4],"Дать 10 монет") end
function Persuasion:Bribe100() return bs.findText(self:ServiceList().children[5],"Дать 100 монет") end
function Persuasion:Bribe1000() return bs.findText(self:ServiceList().children[6],"Дать 1000 монет") end
function Persuasion:child(child) if not self:get() then return end return self:get():findChild(child) end
function Persuasion:Close() if not self:get() then return end return self:child("MenuPersuasion_Okbutton") end
function Persuasion:get() return tes3ui.findMenu("MenuPersuasion") end
function Persuasion:ServiceList() if not self:get() then return end return self:child("MenuPersuasion_ServiceList") end
function Persuasion:Visible() if self:get() and self:get().visible then return true else return false end end


--- @param name "Admire"|"Intimidate"|"Taunt"|"Bribe10"|"Bribe100"|"Bribe1000"
function Persuasion:trigger(name)
    if not self:Visible() then return end
    -- if not self:get() and not self:get().visible then return end
    if name == "Admire" then self:Admire():triggerEvent("mouseClick") end
    if name == "Intimidate" then self:Intimidate():triggerEvent("mouseClick") end
    if name == "Taunt" then self:Taunt():triggerEvent("mouseClick") end
    if name == "Bribe10" then if self:Bribe10().disabled then return end self:Bribe10():triggerEvent("mouseClick") end
    if name == "Bribe100" then if self:Bribe100().disabled then return end self:Bribe100():triggerEvent("mouseClick") end
    if name == "Bribe1000" then if self:Bribe1000().disabled then return end self:Bribe1000():triggerEvent("mouseClick") end
    tes3.playSound({sound = "Menu Click"})
end

--- @param e uiActivatedEventData
local function uiActivatedCallback(e)
    if not cfg.persuade.showKey then return end
    local keyname = {
        ["Дать 10 монет"] = "bribe10",
        ["Дать 100 монет"] = "bribe100",
        ["Дать 1000 монет"] = "bribe1000",
        ["Вежливо"] = "admire",
        ["Угрожающе"] = "intimidate",
        ["Оскорбительно"] = "taunt",
    }
    for _, button in pairs(Persuasion:ServiceList().children) do
        local buttonText = button.children[1].text
        local keybind
        if keyname[button.children[1].text] then
            keybind = tes3.getKeyName(cfg.keybind[keyname[buttonText]].keyCode)
        else
            keybind = tes3.getKeyName(cfg.keybind[buttonText:lower()].keyCode)
        end
        keybind = string.gsub(keybind, "Numpad", "Num")
        local keyLabel = button:createLabel{id = "bs", text = keybind..":"}
        keyLabel.color = { 0.875, 0.788, 0.624 }
        keyLabel.autoHeight = true
        keyLabel.autoWidth = true
        keyLabel.borderRight = 5
        keyLabel.parent:reorderChildren(0, keyLabel, -1)
    end
    Persuasion:get().autoHeight = true
    Persuasion:get().autoWidth = true
    Persuasion:ServiceList().autoHeight = true
    Persuasion:ServiceList().autoWidth = true
    Persuasion:get():updateLayout()
    Persuasion:get():updateLayout()--Needs 2 Updates else auto sizing glitches
end
event.register(tes3.event.uiActivated, uiActivatedCallback, {filter = id.Persuasion})

return Persuasion