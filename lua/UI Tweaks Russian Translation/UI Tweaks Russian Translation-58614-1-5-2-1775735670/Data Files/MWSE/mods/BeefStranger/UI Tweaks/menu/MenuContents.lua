local cfg = require("BeefStranger.UI Tweaks.config")
local id = require("BeefStranger.UI Tweaks.ID")
local bs = require("BeefStranger.UI Tweaks.common")

--- *The Contents Menu:*
---
--- `Various elements can be accessed from the Contents Menu.`
---@class bs_MenuContents
local MenuContents = {}
MenuContents.prop = {
    object = "MenuContents_Object",
    itemData = "MenuContents_extra",
}
--- Get the Contents Menu Element
---@return tes3uiElement? ContentsMenu
function MenuContents:get() return tes3ui.findMenu(id.Contents) end

--- Get the first child with this Id/Name
---@param child string|number The Id/Name of the child element
---@return tes3uiElement? childElement
function MenuContents:child(child) return self:get() and self:get():findChild(child) or nil end

--- Get the Button Block Element
---@return tes3uiElement? ButtonBlock
function MenuContents:ButtonBlock() return self:child("Buttons") end

--- Get the Button Block Element
---@return boolean isVisible
function MenuContents:visible() return self:get() and self:get().visible end

--- Get the Close Button Element
---@return tes3uiElement? CloseButton
function MenuContents:Close() return self:child("MenuContents_closebutton") end

--- Get the Dispose Corpse Button Element
---@return tes3uiElement? DisposeButton
function MenuContents:Dispose() return self:child("MenuContents_removebutton") end

--- Get the Items Scroll Pane Element
---@return tes3uiElement? ItemsScrollPane
function MenuContents:Items() return self:child("MenuContents_scrollpane"):getContentElement() end

--- Get the Take All Button Element
---@return tes3uiElement? TakeAllButton
function MenuContents:TakeAll() return self:child("MenuContents_takeallbutton") end

--- Get the Title Block Element
---@return tes3uiElement? TitleBlock
function MenuContents:TitleBlock() return self:child("PartDragMenu_title_tint") end

--- Get the Title Text Element
---@return tes3uiElement? TitleText
function MenuContents:TitleText() return self:child("PartDragMenu_title") end

--- Check if the menu is for pickpocketing
---@return boolean isPickpocket
function MenuContents:isPickpocket() return self:get():getPropertyInt("MenuContents_PickPocket") == 1 end

--- Get the Actor associated with the menu
---@return tes3mobileActor|tes3mobileNPC? Actor
function MenuContents:Actor() return self:get():getPropertyObject("MenuContents_Actor") or nil end

--- Get the UIExp Capacity Fillbar Element
---@return tes3uiElement? UIExp_CapacityFillbar
function MenuContents:UIExp_Capacity() return self:child("UIEXP_MenuContents_capacity") end

--- Get the UIExp Filter Block Element
---@return tes3uiElement? UIExp_FilterBlock
function MenuContents:UIExp_Filter() return self:child("UIEXP:ContentsMenu:FilterBlock") end

---@return tes3reference containerReference The Containers Reference
function MenuContents:Reference() return self:get():getPropertyObject("MenuContents_ObjectRefr") end

---@return boolean hasAccess If the player has Access
function MenuContents:HasAccess() return tes3.hasOwnershipAccess({ target = self:Reference() }) end

---@return tes3faction|tes3npc refOwner If the player has Access
function MenuContents:Owner() return tes3.getOwner({ reference = self:Reference() }) end

---Return itemTiles Object
---@param itemTile tes3uiElement
---@return tes3object|tes3misc|tes3weapon|tes3item object If the player has Access
function MenuContents:Object(itemTile) return itemTile:getPropertyObject(self.prop.object) end

---Return ItemTiles Stack Size
---@param itemTile tes3uiElement itemTile_tile
---@return number stackSize
function MenuContents:StackSize(itemTile) return itemTile:findChild("MenuContents_count") and tonumber(itemTile:findChild("MenuContents_count").text) or 1 end

---@class bsUITweaksContents_totalValue
local totalValue = {}

---Gets Total Value of all items in Container
---@return number
function totalValue.getValue()
    local total = 0
    for _, columns in ipairs(MenuContents:Items().children) do
        for _, itemTile in ipairs(columns.children) do
            local count = MenuContents:StackSize(itemTile)
            local obj = MenuContents:Object(itemTile)
            local value = obj.value
            if obj.id:match("key_" )  then value = 0 end
            total = total + (count * value)
        end
    end
    return total
end

---@param e uiEventEventData
function totalValue.valueUpdate(e)
    local element = e.source:findChild("Total Value")
    if element and cfg.contents.totalValue then
        element.text = "Общая стоимость: " .. tostring(totalValue.getValue())
    end
end

---Refresh Contents to cause TotalValue to update
--- @param e itemTileUpdatedEventData
local function tileUpdate(e)
    if cfg.contents.enable then
        if e.menu == MenuContents:get() then
            if cfg.contents.totalValue then e.menu:updateLayout() end
        end
    end
end
event.register(tes3.event.itemTileUpdated, tileUpdate)

--- @param e uiActivatedEventData
local function uiActivatedCallback(e)
    if cfg.contents.enable then
        if e.element == MenuContents:get() then
            if cfg.contents.totalValue then
                local value = MenuContents:ButtonBlock():createLabel { id = "Total Value", text = "Общая стоимость: " .. tostring(totalValue.getValue()) }
                value.borderAllSides = 4
                value.color = bs.rgb.normalColor
                MenuContents:ButtonBlock():reorderChildren(MenuContents:Dispose(), value, -1)

                MenuContents:get():registerAfter(tes3.uiEvent.preUpdate, totalValue.valueUpdate)
            end

            if cfg.contents.showOwner then
                local owner = MenuContents:Owner()
                if owner then
                    MenuContents:TitleText().text = MenuContents:TitleText().text .. ": " .. MenuContents:Owner().name
                    MenuContents:TitleText().color = MenuContents:HasAccess() and bs.rgb.bsPrettyGreen or bs.rgb.bsNiceRed
                elseif MenuContents:isPickpocket() then
                    MenuContents:TitleText().text = MenuContents:TitleText().text .. ": " .. "Карманная кража"
                    MenuContents:TitleText().color = bs.rgb.bsNiceRed
                end
            end
            MenuContents:get():updateLayout()
        end
    end
end
event.register(tes3.event.uiActivated, uiActivatedCallback)

return MenuContents