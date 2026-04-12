local cfg = require("BeefStranger.UI Tweaks.config")
local bs = require("BeefStranger.UI Tweaks.common")
local id = require("BeefStranger.UI Tweaks.ID")
local Dialog = require("BeefStranger.UI Tweaks.menu.MenuDialog")
local Services = require("BeefStranger.UI Tweaks.menu.MenuServices")

local embed = Dialog.embed
local prop = require("BeefStranger.UI Tweaks.property").embed
local uid = id.embed
local doOpen = false

---@class bs_EmbededServices.spells
local spells = {}

function spells:get() return embed:child((uid.spells)) end

---@param e uiActivatedEventData
function spells.creation(e)
    spells.TXT = {
        TITLE = bs.GMST(tes3.gmst.sServiceSpellsTitle),
        CLOSE = bs.GMST(tes3.gmst.sClose),
        OPEN = "Открыть окно",
    }

    Services.Spells:get().visible = false
    Services.Spells:get().disabled = true
    Dialog:get().visible = true
    Dialog:get():updateLayout()

    if spells:get() and not doOpen then
        spells:get():destroy()
        Dialog:get():updateLayout()
        return
    end

    if doOpen then
        doOpen = false
        Services.Spells:get().visible = true
        return
    end

    local actor = tes3ui.getServiceActor()
    ---The Embedded Spells Menu
    local menu = embed:get():createBlock({id = uid.spells})
    -- menu:bs_autoSize(true)
    menu.autoWidth = true
    menu.childAlignX = 0.5
    menu.flowDirection = tes3.flowDirection.topToBottom
    menu.heightProportional = 0.45
    menu.heightProportional = 1
    menu.minWidth = 130
    menu.widthProportional = 1
    menu:setPropertyBool(prop.visible, true)

    local header = menu:createBlock({ id = uid.header })
    header.widthProportional = 1
    header.borderBottom = 6
    header.autoHeight = true
    header.childAlignX = 0.5

    local title = header:createLabel({ id = uid.title, text = spells.TXT.TITLE })
    title.color = bs.rgb.headerColor

    local list = menu:createVerticalScrollPane({ id = uid.spells_list })
    list:bs_scrollAutoWidth()

    list.minWidth = 130
    list.minHeight = 130

    for _, spell in pairs(actor.object.spells) do
        if not tes3.hasSpell({spell = spell, mobile = tes3.mobilePlayer}) then
            local cost = tes3.calculatePrice({ merchant = actor, object = spell })
            local block = list:createBlock({ id = spell.id .. " Block" })
            block:bs_autoSize(true)
            block.widthProportional = 1
            block.childAlignX = -1
            block.childAlignY = 0.5
            block:bs_setObj({ id = prop.spell_obj, object = spell })
            block:setPropertyInt(prop.spell_cost, cost)

            local icon = block:createImage({id = uid.spells_icon, path = "Icons\\"..spell.effects[1].object.icon})

            local button = block:createTextSelect({ id = uid.button, text = spell.name })
            button.borderLeft = 5
            button.widget.state = tes3.uiState.active

            for _, pcSpell in pairs(tes3.player.object.spells) do
                for i = 1, pcSpell:getActiveEffectCount() do
                    for j = 1, spell:getActiveEffectCount() do
                        if spell.effects[j] == pcSpell.effects[i] then
                            button.widget.state = tes3.uiState.normal
                            break
                        end
                    end
                end
            end

            button:register(tes3.uiEvent.mouseClick, function(e)
                -- debug.log(block:getPropertyInt(prop.spell_cost))
                -- debug.log(cost)
                -- debug.log(block:bs_getObj(prop.spell_obj))
                tes3.addSpell { spell = block:bs_getObj(prop.spell_obj), mobile = tes3.mobilePlayer }
                tes3.payMerchant({ merchant = actor, cost = block:getPropertyInt(prop.spell_cost) })
                tes3.playSound { sound = bs.sound.Item_Gold_Down }
                if cfg.embed.notify then
                    bs.notify({success = false, text = "-" .. "" .. block:getPropertyInt(prop.spell_cost) .. "зол"})
                end
                block:destroy()
                Dialog:get():updateLayout()
            end)

            button:register(tes3.uiEvent.help, function (e)
                tes3ui.createTooltipMenu({spell = spell})
            end)

            local price = block:createLabel({ id = uid.price, text = cost .. "зол" })
            price.borderLeft = 15
            list:getContentElement():sortChildren(function(a, b)
                return a.name < b.name
            end)
        end
    end

    local footer = menu:createBlock({ id = uid.footer })
    footer.childAlignX = -1
    footer.borderTop = 5
    footer.childAlignY = 0.5
    footer.widthProportional = 1
    footer.autoHeight = true

    local open = footer:createButton({ id = uid.spells_open, text = spells.TXT.OPEN })
    open:register(tes3.uiEvent.mouseClick, function(e)
        local spellMenu = Services.Spells:get()
        if spellMenu then
            spellMenu.visible = true
            spellMenu.disabled = false
        else
            doOpen = true
            Dialog:Spells():bs_click({ playSound = false })
        end
    end)

    local close = footer:createButton({ id = uid.close, text = spells.TXT.CLOSE })
    close:register(tes3.uiEvent.mouseClick, function(e)
        menu:destroy()
        Dialog:get():updateLayout()
    end)

    menu:registerBefore(tes3.uiEvent.destroy, function(e)
        if Services.Spells:get() then
            Services.Spells:get():destroy()
        end
    end)

    -- spells.popList()
    menu:registerAfter(tes3.uiEvent.preUpdate, function(e)
        bs.updateList({
            list = list,
            defaultState = tes3.uiState.active,
            service = tes3.merchantService.spells,
            propPrefix = "spell"
        })
        for _, v in ipairs(list:getContentElement().children) do
            local spell = v:getPropertyObject("BS_Spells_Spell")
            for k, pcSpell in pairs(tes3.player.object.spells) do ---Check every player spell
                for i = 1, pcSpell:getActiveEffectCount() do ---check every playerspell effect
                    for j = 1, spell:getActiveEffectCount() do
                        if spell.effects[j].id == pcSpell.effects[i].id then
                            v:findChild("Service Button").widget.state = tes3.uiState.normal
                        end
                    end
                end
            end
        end
    end)

    embed:get():updateLayout()
    menu:updateLayout()
end

return spells