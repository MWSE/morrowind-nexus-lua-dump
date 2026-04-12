local cfg = require("BeefStranger.UI Tweaks.config")
local id = require("BeefStranger.UI Tweaks.ID")
local ts = tostring

---@class bsMenuEnchantment
local Enchant = {}
function Enchant:get() return tes3ui.findMenu(id.Enchantment) end
function Enchant:child(child) if not self:get() then return end return self:get():findChild(child) end
function Enchant:Price() if not self:get() then return end return self:child("MenuEnchantment_priceContainer") end
function Enchant:PriceLabel() if not self:get() then return end return self:child("MenuEnchantment_priceLabel") end
function Enchant:Close() if not self:get() then return end return self:child("MenuEnchantment_Cancelbutton") end
function Enchant:Cost() return self:child("MenuEnchantment_Cost") end

function Enchant:bsGold() return self:child("bsPlayerGold") end
function Enchant:bsValue() return self:child("bsValue") end


---@param e uiActivatedEventData
local function enchantActivated(e)
    if not cfg.enchant.enable then return end
    if cfg.enchant.showGold then
        e.element.minWidth = 580
        if tes3ui.getServiceActor() then
            local playerGold = 0
            for _, stack in pairs(tes3.mobilePlayer.inventory) do
                if stack.object.name == "Золото" then
                    playerGold = stack.count
                end
            end

            Enchant:Price():bs_autoSize(true)
            Enchant:PriceLabel().borderRight = 10
            Enchant:Cost().parent:bs_autoSize(true)

            -- Enchant:PriceLabel().borderRight = 10
            local gold = Enchant:Price():createLabel { id = "BS_PlayerGold", text = "Золото" }
            gold.borderLeft = 20
            gold.color = tes3ui.getPalette(tes3.palette.positiveColor)

            local amount = Enchant:Price():createLabel { id = "BS_Value", text = ts(playerGold) }
            amount.borderLeft = 10
            Enchant:get():updateLayout()
        end
    end
end
event.register(tes3.event.uiActivated, enchantActivated, {filter = id.Enchantment})

return Enchant