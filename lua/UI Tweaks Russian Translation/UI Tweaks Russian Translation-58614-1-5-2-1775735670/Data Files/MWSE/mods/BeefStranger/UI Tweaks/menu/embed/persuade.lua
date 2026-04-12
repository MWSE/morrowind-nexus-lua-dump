local cfg = require("BeefStranger.UI Tweaks.config")
local bs = require("BeefStranger.UI Tweaks.common")
local id = require("BeefStranger.UI Tweaks.ID")
local Dialog = require("BeefStranger.UI Tweaks.menu.MenuDialog")
local embed = Dialog.embed
local prop = require("BeefStranger.UI Tweaks.property").embed
local uid = id.embed

local RussianDialogueMessage = {
        ["Admire Success"] = "Лесть подействовала",
        ["Admire Fail"] = "Лесть не подействовала",
        ["Intimidate Success"] = "Угроза подействовала",
        ["Intimidate Fail"] = "Угроза не подействовала",
        ["Taunt Success"] = "Оскорбление подействовало",
        ["Taunt Fail"] = "Оскорбление не подействовало",
        ["Bribe Success"] = "Подкуп удался",
        ["Bribe Fail"] = "Подкуп не удался"
    }

---@class bs_EmbededServices.persuade
local persuade = {}

persuade.type = {
    admire = 0,
    intimidate = 1,
    taunt = 2,
    bribe_10 = 3,
    bribe_100 = 4,
    bribe_1000 = 5
}
persuade.name = {
    admire = 0,
    intimidate = 1,
    taunt = 2,
    bribe_10 = 3,
    bribe_100 = 4,
    bribe_1000 = 5
}

persuade.response = {
    [0] = { [true] = tes3.dialoguePage.service.admireSuccess, [false] = tes3.dialoguePage.service.admireFail },
    [1] = { [true] = tes3.dialoguePage.service.intimidateSuccess, [false] = tes3.dialoguePage.service.intimidateFail },
    [2] = { [true] = tes3.dialoguePage.service.tauntSuccess, [false] = tes3.dialoguePage.service.tauntFail },
    [3] = { [true] = tes3.dialoguePage.service.bribeSuccess, [false] = tes3.dialoguePage.service.bribeFail },
    [4] = { [true] = tes3.dialoguePage.service.bribeSuccess, [false] = tes3.dialoguePage.service.bribeFail },
    [5] = { [true] = tes3.dialoguePage.service.bribeSuccess, [false] = tes3.dialoguePage.service.bribeFail },
}

persuade.costIndex = {
    [4] = 10,
    [5] = 100,
    [6] = 1000,
}
-- persuade.response

function persuade:get() return embed:child((uid.persuade)) end

---@param e uiActivatedEventData
function persuade.creation(e)
    if not embed:get() then return end
    persuade.TXT = {
        TITLE = bs.GMST(tes3.gmst.sPersuasionMenuTitle),
        ADMIRE = bs.GMST(tes3.gmst.sAdmire),
        INTIMIDATE = bs.GMST(tes3.gmst.sIntimidate),
        TAUNT = bs.GMST(tes3.gmst.sTaunt),
        BRIBE10 = bs.GMST(tes3.gmst.sBribe10Gold),
        BRIBE100 = bs.GMST(tes3.gmst.sBribe100Gold),
        BRIBE1000 = bs.GMST(tes3.gmst.sBribe1000Gold),
        CLOSE = bs.GMST(tes3.gmst.sClose)
    }


    local dialog = Dialog:get()

    ---Close if open
    if persuade:get() then
        persuade:get():destroy()
        dialog:updateLayout()
        return
    end

    local actor = tes3ui.getServiceActor()
    local menu = embed:get():createBlock({id = uid.persuade})
    menu.flowDirection = tes3.flowDirection.topToBottom
    menu.autoWidth = true
    menu.heightProportional = 1
    menu.widthProportional = 1
    menu.childAlignX = 0.5
    menu:setPropertyBool(prop.visible, true)

    local header = menu:createBlock({ id = uid.header })
    header.widthProportional = 1
    header.borderBottom = 6
    header.autoHeight = true
    header.childAlignX = 0.5

    local title = header:createLabel({ id = uid.title, text = persuade.TXT.TITLE })
    title.color = bs.rgb.headerColor

    local border = menu:createThinBorder({ id = uid.border })
    border:bs_autoSize(true)
    border.widthProportional = 1

    local list = border:createBlock({ id = uid.persuade_list })
    list.borderAllSides = 4
    list.borderRight = 40
    list:bs_autoSize(true)
    list.flowDirection = tes3.flowDirection.topToBottom

    local admire = list:createTextSelect({ id = uid.persuade_Admire, text = persuade.TXT.ADMIRE })
    local intimidate = list:createTextSelect({ id = uid.persuade_Intimidate, text = persuade.TXT.INTIMIDATE })
    local taunt = list:createTextSelect({ id = uid.persuade_Taunt, text = persuade.TXT.TAUNT })
    local bribe_10 = list:createTextSelect({ id = uid.persuade_Bribe_10, text = persuade.TXT.BRIBE10 })
    local bribe_100 = list:createTextSelect({ id = uid.persuade_Bribe_100, text = persuade.TXT.BRIBE100 })
    local bribe_1000 = list:createTextSelect({ id = uid.persuade_Bribe_1000, text = persuade.TXT.BRIBE1000 })

    if cfg.embed_persuade.hold then
        admire:bs_holdClick({ triggerClick = true, playSound = true, acceleration = 0.8, skipFirstClick = true })
        intimidate:bs_holdClick({ triggerClick = true, playSound = true, acceleration = 0.8, skipFirstClick = true })
        taunt:bs_holdClick({ triggerClick = true, playSound = true, acceleration = 0.8, skipFirstClick = true })
        if cfg.embed_persuade.holdBribe then
            bribe_10:bs_holdClick({ triggerClick = true, playSound = true, acceleration = 0.8, skipFirstClick = true })
            bribe_100:bs_holdClick({ triggerClick = true, playSound = true, acceleration = 0.8, skipFirstClick = true })
            bribe_1000:bs_holdClick({ triggerClick = true, playSound = true, acceleration = 0.8, skipFirstClick = true })
        end
    end

    for index, button in ipairs(list.children) do
        button:register(tes3.uiEvent.mouseClick, function (e)
            local cost = persuade.costIndex[index]
            if cost then
                tes3.playSound{sound = bs.sound.Item_Gold_Down}
                tes3.payMerchant({merchant = actor, cost = cost})
            end

            local success = tes3.persuade({actor = actor, index = index - 1})
            local dialogue = tes3.findDialogue({ type = tes3.dialogueType.service, page = persuade.response[index - 1][success] })
            local dialogIndex = math.random(#dialogue.info)
            tes3ui.showDialogueMessage({ text = RussianDialogueMessage[dialogue.id] or dialogue.id, style = 1})
            tes3ui.showDialogueMessage({ text = dialogue.info[dialogIndex].text, style = 0})
            
            -- tes3ui.showDialogueMessage({ text = notifyMsg, style = 4})
            
            local notifyMsg = ("%s %s"):format(button.text, success and "succeeded" or "failed")
            if cfg.embed.notify then
                bs.notify({success = success, text = RussianDialogueMessage[dialogue.id] or dialogue.id})
            end

            dialog:updateLayout()
            if actor.fight >= 80 then
                if not cfg.embed_persuade.instantFight then
                    tes3.messageBox({
                        message = "Это все решает!",
                        buttons = {"Дерись!"},
                        callback = function (e)
                            tes3ui.leaveMenuMode()
                        end
                    })
                end
                tes3.closeDialogueMenu({})
            end
        end)
    end

    local footer = menu:createBlock({ id = uid.footer })
    footer.childAlignX = -1
    footer.borderTop = 5
    footer.childAlignY = 0.5
    footer.widthProportional = 1
    footer.autoHeight = true

    local close = footer:createButton({ id = uid.close, text = persuade.TXT.CLOSE})
    close:register(tes3.uiEvent.mouseClick, function(e)
        menu:destroy()
        Dialog:get():updateLayout()
    end)

    menu:registerAfter(tes3.uiEvent.preUpdate, persuade.update)

    dialog:updateLayout()
end

---@param e tes3uiEventData
function persuade.update(e)
    for index, button in ipairs(e.source:findChild(uid.persuade_list).children) do
        local cost = persuade.costIndex[index]
        if cost then
            if tes3.getPlayerGold() < cost then
                button.color = bs.rgb.disabledColor
                button.disabled = true
            end
        end
    end
end

return persuade