local menu = require("BeefStranger.Transfer Enchantments.menu.menuUtil")
local cfg = require("BeefStranger.Transfer Enchantments.config")
local bs = require("BeefStranger.Transfer Enchantments.common")
local ts = tostring

local validType = {
    [tes3.objectType.armor] = true,
    [tes3.objectType.weapon] = true,
    [tes3.objectType.clothing] = true,
}


---@param selection string|"enchant"|"target"|"soulGem" The type of selection
function menu.ItemSelect.create(selection)
    local ItemSelectID = tes3ui.registerID("bsItemSelect")

    menu.ItemSelect.Main = tes3ui.createMenu { id = ItemSelectID, fixedFrame = true }
    local ItemSelect = menu.ItemSelect
    local Main = ItemSelect.Main

    ItemSelect.scrollPane = Main:createVerticalScrollPane({ id = "ScrollPane" })
    ItemSelect.scrollPane.paddingRight = 10
    ItemSelect.scrollPane:notProp()
    ItemSelect.scrollPane.width = 352
    ItemSelect.scrollPane.height = 455

    for _, stack in pairs(tes3.mobilePlayer.inventory) do
        local objectType = stack.object.objectType
        local hasScript = stack.object.script ~= nil
        local enchant = stack.object.enchantment
        local weapon = objectType == tes3.objectType.weapon

        if not hasScript or cfg.allowScript then
            if validType[objectType] then
                if selection == "enchant" then
                    local selected = ts(stack.object.id) == ts(menu:targetItem()) --Check if item is already selected as the Target
                    if enchant and not selected then
                        if menu:targetOnStrike() and weapon then
                            ItemSelect.createList(selection, stack.object)
                        elseif not menu:targetOnStrike() then
                            ItemSelect.createList(selection, stack.object)
                        end
                    end
                end

                if selection == "target" then
                    local selected = ts(stack.object.id) == ts(menu:enchantItem()) --Check if item is already selected as the Enchant
                    if menu.combine then
                        if enchant and not selected then
                            if menu:enchantOnStrike() and weapon then
                                ItemSelect.createList(selection, stack.object)
                            elseif not menu:enchantOnStrike() then
                                ItemSelect.createList(selection, stack.object)
                            end
                        end
                    else
                        if not enchant then
                            if menu:enchantOnStrike() and weapon then
                                ItemSelect.createList(selection, stack.object)
                            elseif not menu:enchantOnStrike() then
                                ItemSelect.createList(selection, stack.object)
                            end
                        end
                    end
                end
            end

            if selection == "soulGem" then
                if stack.object.isSoulGem and stack.variables then
                    for _, itemData in pairs(stack.variables) do
                        if itemData and itemData.soul and itemData.soul.soul then ---In what world does it make sense that itemData can be nil here????
                            ItemSelect.createList(selection, stack.object, itemData)
                        end
                    end
                end
            end
        end
    end

    ItemSelect.close = ItemSelect.Main:createClose()
    Main:updateLayout()
end

function menu.ItemSelect.createList(selection, object, itemData)
    menu.ItemSelect.scrollPane_Block = menu.ItemSelect.scrollPane:createBlock({ id = object.name })

    menu.ItemSelect.scrollPane_Block:autoSize()

    menu.ItemSelect.scrollPane_Block_Icon = menu.ItemSelect.scrollPane_Block:createImage({ id = object.name .. " Image", path = menu.getIcon(object) })
    menu.ItemSelect.scrollPane_Block_Icon.width = 40
    menu.ItemSelect.scrollPane_Block_Icon.height = 40
    menu.ItemSelect.scrollPane_Block_Icon.scaleMode = true

    menu.ItemSelect.scrollPane_Block_Name = menu.ItemSelect.scrollPane_Block:createLabel({ id = "Name", text = object .name })
    menu.ItemSelect.scrollPane_Block_Name.absolutePosAlignY = 0.03

    menu.ItemSelect.scrollPane_Block:itemTooltip(object, itemData) --Tooltips for items in the selection menu

    menu.ItemSelect.scrollPane_Block:register(tes3.uiEvent.mouseClick, function(e)
        if menu.Transfer.Main then         --Make sure Main menu is still a thing
            if selection == "enchant" then --When the Enchanted Item is Selected
                menu.Transfer.text_Info_Cost.text = menu.calcCost(object, menu.combine)

                menu.selectionUpdate(menu.Transfer.select_Enchant_Item, object)
            elseif selection == "target" then --When the Target Item is selected
                menu.selectionUpdate(menu.Transfer.select_Target_Item, object)
            elseif selection == "soulGem" then                                           --When the SoulGem is selected
                menu.Transfer.select_SoulGem_Item.visible = true                         --Make it visible
                menu.Transfer.select_SoulGem_Item.contentPath = menu.getIcon(object)     --Set icon to items icon
                menu.Transfer.select_SoulGem_Item:setLuaData("item", object)             --Add item to elements luaData
                menu.Transfer.select_SoulGem_Item:setLuaData("soul", itemData.soul.soul) --Add item to elements luaData
                menu.Transfer.text_Info_Soul.text = tostring(itemData.soul.soul)         --Set Soul info text

                menu.Transfer.select_SoulGem_Item:itemTooltip(object, itemData)

                menu.ItemSelect.Main:updateLayout()
                menu.ItemSelect.Main:exit()
                bs.playSound(bs.sound.Item_Misc_Down)
            end
        end
    end)
    menu.ItemSelect.Main:updateLayout()
end

---@param element tes3uiElement
---@param selection any
function menu.selection(element, selection) ---Select Squares
    --debug.log(element.name)
    ---Selection Squares in Transfer.select
    element.paddingAllSides = 4
    element.height = 60
    element.width = 60
    element.childAlignY = 0.5
    element.childOffsetX = 10
    element:registerAfter(tes3.uiEvent.mouseClick, function(e)
        if menu.data(element.children[1]) then ---If Item is Selected
            local icon = element.children[1]
            icon.contentPath = nil
            icon:setLuaData("item", nil)
            icon:setLuaData("soul", nil)
            icon.visible = false
            element:updateLayout()
        else
            menu.ItemSelect.create(selection) ---Create Item List Menu
        end
    end)
end