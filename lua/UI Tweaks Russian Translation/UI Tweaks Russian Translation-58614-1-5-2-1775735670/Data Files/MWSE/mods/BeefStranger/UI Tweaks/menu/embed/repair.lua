local cfg = require("BeefStranger.UI Tweaks.config")
local bs = require("BeefStranger.UI Tweaks.common")
local id = require("BeefStranger.UI Tweaks.ID")
local Dialog = require("BeefStranger.UI Tweaks.menu.MenuDialog")
local prop = require("BeefStranger.UI Tweaks.property").embed
local embed = Dialog.embed
local uid = id.embed

-----------------------------------
--------------Repair---------------
-----------------------------------

---@class bs_EmbededServices.Repair
local repair = {}

function repair:get() return embed:child((uid.repair)) end

---@param e uiActivatedEventData
function repair.creation(e)
    repair.TXT = {
        TITLE = bs.GMST(tes3.gmst.sServiceRepairTitle),
        CLOSE = bs.GMST(tes3.gmst.sClose),
    }

    Dialog:get().visible = true
    Dialog:get():updateLayout()

    if Dialog:child("BS_Repair") then
        Dialog:child("BS_Repair"):destroy()
        Dialog:get():updateLayout()
        return
    else
        -- local embed:get() = Dialog:child("BS_Embedded Services")
        local actor = tes3ui.getServiceActor()
        local menu = embed:get():createBlock({ id = uid.repair })
        menu:bs_autoSize(true)
        menu.childAlignX = 0.5
        menu.flowDirection = tes3.flowDirection.topToBottom
        menu.heightProportional = 0.45
        menu.heightProportional = 1
        menu.minWidth = 130
        menu.widthProportional = 1
        menu:setPropertyBool(prop.visible, true)

        local header = menu:createBlock({ id = uid.header })
        -- header.autoHeight = true
        header:bs_autoSize(true)
        header.borderBottom = 6
        header.childAlignX = 0.5
        header.widthProportional = 1

        local title = header:createLabel({ id = uid.title, text = repair.TXT.TITLE })
        title.color = bs.rgb.headerColor

        local list = menu:createVerticalScrollPane({ id = uid.repair_list })
        list:scrollAutoSize()
        list.autoHeight = false
        list.heightProportional = 1
        list.minHeight = 130
        list.minWidth = 130

        for _, stack in pairs(tes3.mobilePlayer.inventory) do
            local repairable = (stack.object.objectType == tes3.objectType.armor or stack.object.objectType == tes3.objectType.weapon)
            if stack.variables then
                if repairable then
                    if stack.variables[1].condition < stack.object.maxCondition then
                        local cost = tes3.calculatePrice({ merchant = actor, repairing = true, object = stack.object, itemData = stack.variables[1] })

                        local block = list:createBlock({ id = stack.object.id .. " Block" })
                        block:bs_autoSize(true)
                        block.widthProportional = 1
                        block.childAlignX = -1
                        block.childAlignY = 0.5
                        block:bs_setObj({ id = prop.repair_obj, object = stack.object })
                        block:bs_setItemData({ id = prop.repair_data, data = stack.variables[1] })
                        block:setPropertyInt(prop.repair_cost, cost)

                        local button = block:createTextSelect({ id = uid.button, text = stack.object.name .. ":" })

                        local price = block:createLabel({ id = uid.price, text = cost .. "зол" })
                        price.borderLeft = 15

                        if tes3.getPlayerGold() < cost then
                            button.color = bs.rgb.disabledColor
                            button.disabled = true
                        end

                    
                        button:register(tes3.uiEvent.mouseClick, function(e)
                            if cfg.embed.notify then
                                bs.notify({success = false, text = ("-%sзол"):format(block:getPropertyInt(prop.repair_cost))})
                            end
                            tes3.playSound({ sound = bs.sound.Repair })
                            tes3.payMerchant({ cost = cost, merchant = actor })
                            block:bs_getItemData(prop.repair_data).condition = block:bs_getObj(prop.repair_obj) .maxCondition
                            block:destroy()
                            Dialog:get():updateLayout()
                        end)

                        button:register(tes3.uiEvent.help, function(e)
                            tes3ui.createTooltipMenu({ item = stack.object, itemData = stack.variables[1] })
                        end)
                    end
                end
            end
        end

        local footer = menu:createBlock({id = uid.footer})
        footer.autoHeight = true
        footer.borderTop = 5
        footer.childAlignX = -1
        footer.childAlignY = 0.5
        footer.widthProportional = 1

        local close = footer:createButton({id = uid.close, text = repair.TXT.CLOSE})
        close:register(tes3.uiEvent.mouseClick, function(e)
            menu:destroy()
            Dialog:get():updateLayout()
        end)

        menu:registerAfter(tes3.uiEvent.preUpdate, function(e)
            bs.updateList({
                list = list,
                propPrefix = "repair",
                defaultState = tes3.uiState.normal,
                service = tes3.merchantService.repair
            })
        end)
    end
    Dialog:get():updateLayout()
end

return repair