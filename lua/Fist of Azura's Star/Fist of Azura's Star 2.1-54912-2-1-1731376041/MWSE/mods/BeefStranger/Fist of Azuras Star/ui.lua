local MenuStat = require("BeefStranger.Fist of Azuras Star.MenuStat")
local bs = require("BeefStranger.Fist of Azuras Star.common")
local cfg = require("BeefStranger.Fist of Azuras Star.config")
local Azura

--- @param e loadedEventData
local function initData(e)
    tes3.player.data.bsFistOfAzura = tes3.player.data.bsFistOfAzura or {}
    Azura = tes3.player.data.bsFistOfAzura
end
event.register(tes3.event.loaded, initData)


local function perkSelectMenu()
    local menu = tes3ui.createMenu({ id = "BS_FistOfAzura", fixedFrame = true })

    local perkList = menu:createBlock { id = "Perks" }
    perkList.autoHeight = true
    perkList.autoWidth = true
    perkList.flowDirection = tes3.flowDirection.topToBottom

    for _, perkData in ipairs(bs.perkButtons) do
        local perk = perkData.perk
        local name = perkData.name
        if not bs.hasPerk(perk) then
            local button = perkList:createButton({ id = perk, text = name })
            button:register(tes3.uiEvent.help, function(e)
                local tip = tes3ui.createTooltipMenu()
                tip:createLabel { id = perk .. "_Desc", text = bs.perkDesc[perk] }
            end)
            button:register(tes3.uiEvent.mouseClick, function(e)
                tes3.messageBox { message = "Take Perk: " .. name,
                    buttons = { "Yes", "No" },
                    callback = function(c)
                        if c.button == 0 then
                            bs.enablePerk(perk)
                            e.source:getTopLevelMenu():destroy()
                            if MenuStat:AzuraPerks() then
                                MenuStat:AzuraPerks():updateLayout()
                            end
                            MenuStat:update()
                        end
                    end }
            end)
        end
    end

    local close = menu:createButton { id = "Close", text = "Close" }
    close:register(tes3.uiEvent.mouseClick, function(e)
        e.source:getTopLevelMenu():destroy()
    end)
end


--- @param e uiSkillTooltipEventData
local function skillTooltip(e)
    if e.skill == tes3.skill.handToHand then
        local azuraInfo = e.tooltip:createBlock { id = "BS_AzuraInfo" }
        azuraInfo.autoHeight = true
        azuraInfo.widthProportional = 1
        azuraInfo.flowDirection = tes3.flowDirection.topToBottom

        local header = azuraInfo:createBlock { id = "Header" }
        header.autoHeight = true
        header.widthProportional = 1

        local azuraMark = header:createImage { id = "BS_AzuraIcon", path = "icons\\w\\tx_art_azura_star.tga" }
        azuraMark.imageScaleX = 0.5
        azuraMark.imageScaleY = 0.5
        if Azura.attackSpeed then
            local speed = header:createLabel { id = "attackSpeed", text = "Punch Speed: " .. tostring(Azura.attackSpeed)}
        end
        if bs.perkPoints() > 0 then
            azuraInfo:createLabel { id = "BS_AvailPerk", text = "Perk Points Available: " .. tostring(bs.perkPoints()) }
        end
        azuraInfo:createDivider({ id = "Divider" })

        for _, perkData in ipairs(bs.perkButtons) do
            local perk = perkData.perk
            local name = perkData.name
            -- debug.log(Perk:has(perk))
            if bs.hasPerk(perk) then
                local border = azuraInfo:createThinBorder({ id = perk .. " Border" })
                border.autoHeight = true
                border.autoWidth = true
                border.borderTop = 6
                local perkDisplay = border:createLabel { id = perk, text = name }
                perkDisplay.borderAllSides = 4
            end
        end
        azuraInfo:createDivider({id = "Footer_divider"})
    end
end
event.register(tes3.event.uiSkillTooltip, skillTooltip)



---comments
---@param e tes3uiEventData
local function perkDispUpdate(e)
    e.source.visible = cfg.showPerk
    if cfg.showPerk then
        for _, perkData in pairs(bs.perkButtons) do
            if tes3.player.data.bsFistOfAzura.perks[perkData.perk] and not MenuStat:child(perkData.perk) then
                local label = e.source:createLabel({ id = perkData.perk, text = perkData.name })
                label.borderLeft = 15
                label.color = bs.rgb.headerColor
                label:register(tes3.uiEvent.help, function (e)
                    local tip = tes3ui.createTooltipMenu()
                    local desc = tip:createLabel({id = perkData.perk, text = bs.perkDesc[perkData.perk]})
                    desc.color = bs.rgb.headerColor
                end)
            end
            if not bs.hasPerk(perkData.perk) then
                if e.source:findChild(perkData.perk) then
                    e.source:findChild(perkData.perk):destroy()
                end
            end
        end

    end
    -- logmsg("PerkBlock Update TEST")
    -- logmsg("PerkBlock Update")
end

local function perkDisplay()
    if MenuStat:AzuraPerks() then return end
    local perkBlock = MenuStat:SkillList():createBlock { id = "bs_AzuraPerks" }
    perkBlock.flowDirection = tes3.flowDirection.topToBottom
    perkBlock.widthProportional = 1
    perkBlock.autoHeight = true

    local childIndex = table.find(MenuStat:SkillList().children, MenuStat:HandToHand())
    MenuStat:SkillList():reorderChildren(childIndex, perkBlock, -1)

    perkBlock:register(tes3.uiEvent.update, perkDispUpdate)
    perkBlock:updateLayout()
end

--- @param e uiActivatedEventData
local function onMenuStatCreation(e)
    if e.element == MenuStat:get() then
            MenuStat:get():registerAfter(tes3.uiEvent.preUpdate, function(e)
                if MenuStat:AzuraPerks() then
                    MenuStat:AzuraPerks():triggerEvent(tes3.uiEvent.update)
                else
                    perkDisplay()
                end
            end)
        end
    end
event.register(tes3.event.uiActivated, onMenuStatCreation)

--- @param e menuEnterEventData
local function menuEnterCallback(e)
    if MenuStat:visible() then
        MenuStat:get():registerBefore(tes3.uiEvent.preUpdate, function(e)
            MenuStat:HandToHand().children[1].color = (bs.perkPoints() > 0) and bs.rgb.bsPrettyGreen or bs.rgb.normalColor
        end)

        if MenuStat:HandToHand() then
            if bs.perkPoints() > 0 then
                MenuStat:HandToHand():register(tes3.uiEvent.mouseClick, perkSelectMenu)
            end
        end
        MenuStat:get():updateLayout() ---Needed to make color change on initial open
    end
end
event.register(tes3.event.menuEnter, menuEnterCallback, {priority = -100000000})
