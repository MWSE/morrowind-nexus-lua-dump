local cfg = require("BeefStranger.UI Tweaks.config")
local id = require("BeefStranger.UI Tweaks.ID")
local ts = tostring

---@class bsMenuSpellMaking
local Spellmaking = {}
function Spellmaking:get() return tes3ui.findMenu(tes3ui.registerID(id.Spellmaking)) end
function Spellmaking:child(child) if not self:get() then return end return self:get():findChild(child) end
function Spellmaking:Price() if not self:get() then return end return self:child("MenuSpellmaking_PriceLayout") end
function Spellmaking:BottomSpacer() if self:get() then return self:child("MenuSpellmaking_BottomSpacer") end end
function Spellmaking:Close() if not self:get() then return end return self:child("MenuSpellmaking_Cancelbutton") end

Spellmaking.SetValues = {}
function Spellmaking.SetValues:get() return tes3ui.findMenu(tes3ui.registerID(id.SetValues)) end
function Spellmaking.SetValues:child(child) if not self:get() then return end return self:get():findChild(child) end
function Spellmaking.SetValues:Close() if not self:get() then return end return self:child("MenuSetValues_Cancelbutton") end

local function showGold()
    if cfg.spellmaking.serviceOnly and not tes3ui.getServiceActor() then return end
    Spellmaking:BottomSpacer().width = 175
    local playerGold = 0
    for _, stack in pairs(tes3.mobilePlayer.inventory) do
        if stack.object.name == "Золото" then
            playerGold = stack.count
        end
    end
    Spellmaking:Price():bs_autoSize(true)
    local gold = Spellmaking:Price():createLabel { id = "BS_PlayerGold", text = "Золото" }
    gold.borderLeft = 20
    gold.borderRight = 10
    gold.color = { 0.875, 0.788, 0.624 }

    local amount = Spellmaking:Price():createLabel { id = "BS_Value", text = ts(playerGold) }
    amount.color = { 1.000, 0.647, 0.376 }
    Spellmaking:get():updateLayout()
end

---@param e uiActivatedEventData
local function enchantActivated(e)
    if not cfg.spellmaking.enable then return end
    if cfg.spellmaking.showGold then showGold() end
end
event.register(tes3.event.uiActivated, enchantActivated, {filter = id.Spellmaking})


return Spellmaking