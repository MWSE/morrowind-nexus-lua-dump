local cfg = require("BeefStranger.UI Tweaks.config")
local bs = require("BeefStranger.UI Tweaks.common")
local id = require("BeefStranger.UI Tweaks.ID")
local Dialog = require("BeefStranger.UI Tweaks.menu.MenuDialog")
local Services = require("BeefStranger.UI Tweaks.menu.MenuServices")

local embed = Dialog.embed
local prop = require("BeefStranger.UI Tweaks.property").embed
local uid = id.embed

---@class bs_EmbededServices.Train
local train = {}

---@param e uiActivatedEventData
function train.creation(e)
    train.TXT = {
        TITLE = bs.GMST(tes3.gmst.sServiceTrainingTitle),
        CLOSE = bs.GMST(tes3.gmst.sClose),
    }

    function train:get() return Dialog:child(uid.train) end

    -- ui.Services.Train:get():destroy()
    Dialog:get().visible = true
    Dialog:get():updateLayout()

    if train:get() then
        train:get():destroy()
        Dialog:get():updateLayout()
        return
    end

    -- local embed = Dialog:child("BS_Embedded Services")
    local actor = tes3ui.getServiceActor()

    local menu = embed:get():createBlock({ id = uid.train })
    menu.flowDirection = tes3.flowDirection.topToBottom
    menu.minWidth = 130
    menu.heightProportional = 0.45
    menu:bs_autoSize(true)
    menu.heightProportional = 1
    menu.widthProportional = 1
    menu.childAlignX = 0.5
    menu:setPropertyBool(prop.visible, true)

    local header = menu:createBlock({ id = uid.header })
    header.widthProportional = 1
    header.borderBottom = 6
    header.autoHeight = true
    header.childAlignX = 0.5

    local title = header:createLabel({ id = uid.title, text = train.TXT.TITLE })
    title.color = bs.rgb.headerColor

    local border = menu:createThinBorder({ id = uid.border })
    border.flowDirection = tes3.flowDirection.topToBottom
    border:bs_autoSize(true)
    border.widthProportional = 1

    local list = border:createBlock({ id = uid.train_list})
    list.flowDirection = tes3.flowDirection.topToBottom
    list:bs_autoSize(true)
    list.borderBottom = 2
    list.borderTop = 6
    list.borderLeft = 7
    list.borderRight = 7
    list.widthProportional = 1

    for _, npcSkill in ipairs(train.getTopSkills(actor)) do
        local skillId = npcSkill.id
        local level = npcSkill.level
        local skillName = tes3.getSkillName(skillId)
        local skillObj = tes3.getSkill(skillId)
        local levelUp = tes3.mobilePlayer:getSkillStatistic(skillId).base + 1
        local calcCost = tes3.calculatePrice({ merchant = actor, training = true, skill = skillId })

        local block = list:createBlock({ id = skillName })
        block:bs_autoSize(true)
        block.widthProportional = 1
        block.childAlignY = 0.4
        block.borderBottom = 4
        block:setPropertyInt(prop.trainSkill, skillId)
        block:setPropertyInt(prop.trainNPCLevel, level)
        block:setPropertyInt(prop.trainNext, tes3.mobilePlayer:getSkillStatistic(skillId).base + 1)
        block:setPropertyInt(prop.trainCost, calcCost)
        block:setPropertyInt(prop.trainAttribute, tes3.mobilePlayer.attributes[skillObj.attribute + 1].base)

        local icon = block:createImage({ id = uid.train_skillIcon, path = skillObj.iconPath })
        local bg = icon:createRect({ id = uid.train_bg, color = { 0.25, 0.25, 0.25 } })
        bg:bs_autoSize(true)
        bg.absolutePosAlignX = 0
        bg.absolutePosAlignY = 1

        local npcLevel = bg:createLabel({ id = uid.train_NPCLevel, text = "" .. level })
        npcLevel.color = bs.rgb.headerColor
        -- npcLevel.ignoreLayoutX = true
        -- npcLevel.ignoreLayoutY = true
        -- npcLevel.absolutePosAlignX = 0
        -- npcLevel.absolutePosAlignY = 1

        local button = block:createTextSelect({ id = uid.train_button, text = skillName })
        button.borderLeft = 3


        local infoBlock = block:createBlock({ id = uid.train_info})
        infoBlock.borderLeft = 10
        infoBlock.childAlignX = 1
        infoBlock.childAlignY = 0.5
        infoBlock:bs_autoSize(true)
        infoBlock.widthProportional = 1

        local nextLevel = infoBlock:createLabel({ id = uid.train_level, text = "" .. levelUp })

        local cost = infoBlock:createLabel({ id = uid.train_cost, text = ": " .. calcCost .. "зол" })

        button:register(tes3.uiEvent.mouseClick, function(e)
            tes3.payMerchant({merchant = actor, cost = calcCost})
            tes3.playSound({ sound = bs.sound.Item_Gold_Down })
            tes3.mobilePlayer:progressSkillToNextLevel(skillId)
            bs.notify({success = false, text = "-" .. "" .. block:getPropertyInt(prop.trainCost) .. "зол"})

            block:setPropertyInt(prop.trainNext, tes3.mobilePlayer:getSkillStatistic(skillId).base + 1)
            block:setPropertyInt(prop.trainCost, tes3.calculatePrice({ merchant = actor, training = true, skill = skillId }))
            Dialog:get():setPropertyInt(prop.trainHours, Dialog:get():getPropertyInt(prop.trainHours) + 1)
            ---Update for Improved Vanilla Levelling
            block:setPropertyInt(prop.trainAttribute, tes3.mobilePlayer.attributes[skillObj.attribute + 1].base)

            -- menu:updateLayout()
            embed:get():updateLayout()
        end)
    end

    local footer = menu:createBlock({ id = uid.footer})
    footer.childAlignX = -1
    footer.borderTop = 5
    footer.childAlignY = 0.5
    footer.widthProportional = 1
    footer.autoHeight = true

    local close = footer:createButton({ id = uid.close, text = train.TXT.CLOSE })
    close:register(tes3.uiEvent.mouseClick, function(e)
        menu:destroy()
        Dialog:get():updateLayout()
    end)
    menu:registerAfter(tes3.uiEvent.preUpdate, train.trainUpdate)
    menu:updateLayout()
end

---@param e tes3uiEventData
function train.trainUpdate(e)
    local menu = e.source
    if menu then
        local actor = tes3ui.getServiceActor()
        for index, skill in ipairs(e.source:findChild(uid.train_list).children) do
            local willing = tes3.checkMerchantOffersService({ reference = actor, service = tes3.merchantService.training})
            local skillId = skill:getPropertyInt(prop.trainSkill)
            local npcLevel = skill:getPropertyInt(prop.trainNPCLevel)
            local attribute = skill:getPropertyInt(prop.trainAttribute)
            local nextLevel = skill:getPropertyInt(prop.trainNext)
            local currentLevel = tes3.mobilePlayer:getSkillStatistic(skillId).base
            local cost = tes3.calculatePrice({ merchant = actor, training = true, skill = skillId })
            skill:setPropertyInt(prop.trainCost, cost)

            local button = skill:findChild(uid.train_button)
            local npcElement = skill:findChild(uid.train_NPCLevel)
            local levelElement = skill:findChild(uid.train_level)
            local costElement = skill:findChild(uid.train_cost)
            local title = e.source:findChild(uid.title)

            npcElement.text = "" .. npcLevel
            levelElement.text = "" .. currentLevel + 1
            costElement.text = ": " .. cost .. "зол"

            if (attribute < currentLevel) or (npcLevel <= currentLevel + 1) or cost > tes3.getPlayerGold() then
                button.disabled = true
                button.color = bs.rgb.disabledColor
            end
            if (npcLevel <= currentLevel + 1) then
                npcElement.color = bs.rgb.bsNiceRed
            end
            if (attribute < currentLevel) then
                levelElement.color = bs.rgb.bsNiceRed
            end
            if cost > tes3.getPlayerGold() then
                costElement.color = bs.rgb.bsNiceRed
            end
            if not willing then
                menu.alpha = 0.50
                title.color = bs.rgb.bsNiceRed
                button.disabled = true
                button.color = bs.rgb.disabledColor
            end
        end
    end
end

---@param actor tes3mobileNPC
function train.getTopSkills(actor)
    ---@class BStrain_skillArray
    ---@field id number
    ---@field level number

    ---@type BStrain_skillArray[]
    local skillArray = {}

    ---Create table of skills. skillID and level
    for index, level in ipairs(actor.skills) do
        table.insert(skillArray, { id = index - 1, level = level.base })
    end

    ---Sort Skills so they match CS
    table.sort(skillArray, function(a, b)
        if a.level == b.level then
            return a.id < b.id
        else
            return a.level > b.level
        end
    end)

    ---Get just the top3
    ---@type BStrain_skillArray[]
    local top3 = {}
    for i = 1, 3 do
        table.insert(top3, skillArray[i])
    end

    return top3
end

return train