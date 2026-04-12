-----------------------------------
--------------Travel---------------
-----------------------------------
local cfg = require("BeefStranger.UI Tweaks.config")
local bs = require("BeefStranger.UI Tweaks.common")
local id = require("BeefStranger.UI Tweaks.ID")
local Dialog = require("BeefStranger.UI Tweaks.menu.MenuDialog")
local embed = Dialog.embed
local prop = require("BeefStranger.UI Tweaks.property").embed
local uid = id.embed


---@class bs_EmbededServices.Travel
local travel = {}

---@class bs_EmbededServices.Travel
function travel:get() return Dialog:child((uid.travel)) end

---@param e uiActivatedEventData
function travel.creation(e)
    if not embed:get() then return end
    local dialog = Dialog:get()

    travel.TXT = {
        TITLE = bs.GMST(tes3.gmst.sServiceTravelTitle),
        CLOSE = bs.GMST(tes3.gmst.sClose),
    }

    ---Close if open
    if travel:get() then
        travel:get():destroy()
        dialog:updateLayout()
        return
    end

    local actor = tes3ui.getServiceActor()
    local menu = embed:get():createBlock({ id = uid.travel })
    menu:bs_autoSize(true)
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

    local title = header:createLabel({ id = uid.title, text = travel.TXT.TITLE })
    title.color = bs.rgb.headerColor

    local list = menu:createVerticalScrollPane({ id = uid.travel_list })
    list:scrollAutoSize()
    list.minWidth = 130
    list.minHeight = 130

    function travel.popList()
        list:getContentElement():destroyChildren()
        for i, v in ipairs(actor.object.aiConfig.travelDestinations) do
            local dist = tes3.mobilePlayer.position:distance(v.marker.position)
            local basePrice = math.floor(dist / bs.GMST(tes3.gmst.fTravelMult))
            local guide = tes3.findClass("Guild Guide")
            if actor.object.class == guide then basePrice = bs.GMST(tes3.gmst.fMagesGuildTravel) end
            local cost = bs.barterOffer(actor, basePrice, true)
            local time = math.floor(dist / bs.GMST(tes3.gmst.fTravelTimeMult))
            local keyCode = i < 10 and tes3.scanCode[""..i]

            local dest = list:createBlock { id = uid.travel_destinationPre .. i }
            dest:bs_autoSize(true)
            dest.childAlignX = -1
            dest.widthProportional = 1

            if cfg.keybind and cfg.embed_travel.keybind then
                local key = dest:createLabel({ id = uid.travel_keyPre .. i, text = i .. ":" })
                key.color = bs.rgb.headerColor
                key.borderRight = 5
            end
            local cellName = tes3.isLuaModActive("Pirate.CelDataModule") and CellNameTranslations[v.cell.name] or v.cell.name
            local button = dest:createTextSelect { id = uid.button, text = cellName..":" }
            if cfg.keybind and cfg.embed_travel.keybind then button:bs_hotkey({keyCode = keyCode}) end
            button:register(tes3.uiEvent.mouseClick, function(e)
                tes3.fadeOut({ duration = 0.2 })
                tes3.payMerchant({ merchant = actor, cost = cost })
                tes3.closeDialogueMenu({})
                tes3.positionCell({
                    position = v.marker.position,
                    cell = v.cell,
                    forceCellChange = true,
                    orientation = v.marker.orientation,
                    suppressFader = true
                })
                if actor.object.class == guide then
                    tes3.playSound({ sound = bs.sound.mysticism_cast })
                else
                    tes3.advanceTime({ resting = false, hours = time })
                end
                tes3.fadeIn({ duration = 1.5 })
            end)

            local price = dest:createLabel({ id = uid.price, text = cost .. "зол" })
            price.borderLeft = 20
        end
    end

    local footer = menu:createBlock({ id = uid.footer })
    footer.childAlignX = -1
    footer.borderTop = 5
    footer.childAlignY = 0.5
    footer.widthProportional = 1
    footer.autoHeight = true

    local close = footer:createButton({ id = uid.close, text = travel.TXT.CLOSE })
    close:register(tes3.uiEvent.mouseClick, function(e)
        menu:destroy()
        Dialog:get():updateLayout()
    end)

    menu:registerAfter(tes3.uiEvent.preUpdate, function (e)
        travel.popList()
    end)
    Dialog:get():updateLayout()
end
return travel