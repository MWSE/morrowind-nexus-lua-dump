local menu = require("BeefStranger.Transfer Enchantments.menu.menuUtil")
local cfg = require("BeefStranger.Transfer Enchantments.config")
local ItemSelect = require("BeefStranger.Transfer Enchantments.menu.itemSelect")
local transferMenu = {}

function transferMenu.create()
    local TransferEnchant = tes3ui.registerID("bsTransferEnchant")
    local Transfer = menu.Transfer

    menu.combine = false

    menu.Transfer.Main = tes3ui.createMenu({id = TransferEnchant, fixedFrame = true, modal = true})
        Transfer.Main.autoHeight = true
        Transfer.Main.autoWidth = true

        --debug.log(getmetatable(Transfer.Main))
        --debug.log(getmetatable(tes3ui.findMenu("MenuMulti")))

    Transfer.text = Transfer.Main:createBlock{id = "Text Layout"}
        Transfer.text:autoSize()

    Transfer.text_Border = Transfer.text:createThinBorder({id = "Text Input Box"})
        Transfer.text_Border.width = 230
        Transfer.text_Border.height = 30
        Transfer.text_Border.borderRight = 3
        Transfer.text_Border.paddingAllSides = 5
        Transfer.text_Border.borderBottom = 30

    Transfer.text_Border_Input = Transfer.text_Border:createTextInput({id = "Text Input", placeholderText = "Rename Item", autoFocus = true})

    Transfer.text_Info = Transfer.text:createBlock({id = "Info"})
        Transfer.text_Info:autoSize()
        Transfer.text_Label_Cost = Transfer.text_Info:createLabel({id = "Cost Label", text = "Cost:"})
        Transfer.text_Label_Cost.borderRight = 50
        Transfer.text_Label_Cost.color = { 0.875, 0.788, 0.624 }

        Transfer.text_Info_Soul = Transfer.text_Info:createLabel({id = "Soul", text = "0"})
        Transfer.text_Info_Slash = Transfer.text_Info:createLabel({id = "Slash", text = "\\"})
        Transfer.text_Info_Cost = Transfer.text_Info:createLabel({id = "Cost", text = "0"})

    Transfer.select = Transfer.Main:createBlock({id = "Selectors"})
        Transfer.select:autoSize()
        -- ui.autoSize(Transfer.select)
        Transfer.select.borderBottom = 10

    Transfer.select_Enchant = Transfer.select:createThinBorder({id = "Enchant Select Border"})

        menu.selection(Transfer.select_Enchant, "enchant") ----Start ItemSelect Menu Creation

        Transfer.select_Enchant.borderLeft = 15
        Transfer.select_Enchant.borderRight = 26

    Transfer.select_Enchant_Item = Transfer.select_Enchant:createImage({id = "Enchanted Item"})
        Transfer.select_Enchant_Item.height = 32
        Transfer.select_Enchant_Item.width = 32
        Transfer.select_Enchant_Item.scaleMode = true

    Transfer.select_Target = Transfer.select:createThinBorder({id = "Item Select Border"})
        menu.selection(Transfer.select_Target, "target")
        Transfer.select_Target.borderRight = 22

    Transfer.select_Target_Item = Transfer.select_Target:createImage({id = "Target Item"})
        Transfer.select_Target_Item.height = 32
        Transfer.select_Target_Item.width = 32
        Transfer.select_Target_Item.scaleMode = true

        Transfer.select_Options = Transfer.select:createCycleButton({ id = "Options", options = { { text = "Transfer", value = false }, { text = "Combine", value = true } }, })
            Transfer.select_Options.absolutePosAlignY = 0.5
            Transfer.select_Options.autoWidth = false
            Transfer.select_Options.width = 78

            Transfer.select_Options.disabled = not cfg.combine

            Transfer.select_Options:registerAfter(tes3.uiEvent.mouseClick, function (e)
                menu.combine = e.source.widget.value
                if menu:enchantItem() then
                    Transfer.text_Info_Cost.text = menu.calcCost(menu:enchantItem(), e.source.widget.value)
                    -- ui.update(menu.Transfer.Main)
                end

                --debug.log(menu.combine)
                --debug.log(e.source.widget.value)
                --debug.log(e.source.widget.text)
            end)
            menu.cycleWidget = Transfer.select_Options.widget ---@type tes3uiCycleButton

    Transfer.select_SoulGem = Transfer.select:createThinBorder({id = "SoulGem Select Border"})
        menu.selection(Transfer.select_SoulGem, "soulGem")
        Transfer.select_SoulGem.borderLeft = 17
        Transfer.select_SoulGem.borderRight = 0

    Transfer.select_SoulGem_Item = Transfer.select_SoulGem:createImage({id = "SoulGem"})
        Transfer.select_SoulGem_Item.height = 32
        Transfer.select_SoulGem_Item.width = 32
        Transfer.select_SoulGem_Item.scaleMode = true

    Transfer.label = Transfer.Main:createBlock({id = "Labels"})
        -- ui.autoSize(Transfer.label)
        Transfer.label:autoSize()
        Transfer.label.borderBottom = 25

        Transfer.label_Enchant = Transfer.label:createLabel({id = "Enchant Label", text = "Enchantment"})

        Transfer.label_Target = Transfer.label:createLabel({id = "Target Label", text = "Item"})
            Transfer.label_Target.borderLeft = 20

        Transfer.label_SoulGem = Transfer.label:createLabel({id = "SoulGem Label", text = "Soul"})
            Transfer.label_SoulGem.borderLeft = 152

    Transfer.buttons = Transfer.Main:createBlock({id = "buttons"})
        Transfer.buttons.widthProportional = 1
        -- ui.autoSize(Transfer.buttons)
        Transfer.buttons:autoSize()

        Transfer.buttons_Close = Transfer.buttons:createClose() --[[ ui.close(Transfer.buttons) ]]

        Transfer.buttons_Confirm = Transfer.buttons:createButton({id = "confirm", text = "Confirm"})
            Transfer.buttons_Confirm.absolutePosAlignX = 1
            Transfer.buttons_Confirm:autoSize()
            Transfer.buttons_Confirm:register(tes3.uiEvent.mouseClick, menu.transferConfirm)

        Transfer.Main:updateLayout()
--debug.log(menu.Transfer.buttons_Close)


    tes3ui.enterMenuMode(TransferEnchant)
end

return transferMenu