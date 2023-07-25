-- Regardless of the view representation format, this handles UI that can be used in common.
local this = {}

local uiid = require("Hanafuda.KoiKoi.MWSE.uiid")
local card = require("Hanafuda.card")
local logger = require("Hanafuda.logger")
local koi = require("Hanafuda.KoiKoi.koikoi")
local config = require("Hanafuda.config")
local i18n = mwse.loadTranslations("Hanafuda")

local headerColor = tes3ui.getPalette(tes3.palette.headerColor)

local rainman = card.Find({ symbol = card.symbol.rainman }) ---@cast rainman integer
local curtain = card.Find({ symbol = card.symbol.curtain }) ---@cast curtain integer
local moon = card.Find({ symbol = card.symbol.moon }) ---@cast moon integer
local boar = card.Find({ symbol = card.symbol.boar }) ---@cast boar integer
local deer = card.Find({ symbol = card.symbol.deer }) ---@cast deer integer
local butterfly = card.Find({ symbol = card.symbol.butterfly }) ---@cast butterfly integer
local sakeCup = card.Find({ symbol = card.symbol.sakeCup }) ---@cast sakeCup integer
local redPoetry = card.Find({ symbol = card.symbol.redPoetry, findAll = true }) ---@cast redPoetry integer[]
local blueRibbon = card.Find({ symbol = card.symbol.blue, findAll = true }) ---@cast blueRibbon integer[]
assert(rainman)
assert(curtain)
assert(moon)
assert(boar)
assert(deer)
assert(butterfly)
assert(sakeCup)
assert(redPoetry and table.size(redPoetry) == 3)
assert(blueRibbon and table.size(blueRibbon) == 3)

---@param parent tes3uiElement
---@param asset CardAssetPackage
---@param combination KoiKoi.CombinationType
---@param actualPoint integer?
---@param maxWidth integer?
---@param cardScale number?
---@param summary boolean?
---@return tes3uiElement
function this.CreateCombinationView(parent, asset, combination, actualPoint, maxWidth, cardScale, summary)
    --local indent = 0
    local block = parent:createBlock()
    block.flowDirection = tes3.flowDirection.topToBottom
    block.widthProportional = 1
    block.autoWidth = true
    block.autoHeight = true
    --block.borderAllSides = 8
    block.paddingAllSides = 0
    -- block.paddingLeft = 8
    -- block.paddingRight = 8
    if maxWidth then
        block.maxWidth = maxWidth
    end
    local scale = cardScale or 0.75

    ---@param cardIds integer[]
    local listup = function(cardIds)
        local pattern = block:createBlock()
        pattern.autoWidth = true
        pattern.autoHeight = true
        pattern.flowDirection = tes3.flowDirection.leftToRight
        -- pattern.borderAllSides = 0
        -- pattern.borderLeft = indent * 2

        for index, cardId in ipairs(cardIds) do
            local a = asset:GetAsset(cardId)
            local b = pattern:createBlock()
            b.borderAllSides = 0
            b.autoWidth = true
            b.autoHeight = true
            b.flowDirection = tes3.flowDirection.topToBottom
            b.childAlignX = 0.5
            local image = b:createImage({ path = a.path })
            image.width = card.GetCardWidth() * scale
            image.height = card.GetCardHeight() * scale
            image.scaleMode = true
            image.consumeMouseEvents = false
            image.borderAllSides = 2
            image.flowDirection = tes3.flowDirection.topToBottom
            b:register(tes3.uiEvent.help,
                function(_)
                    this.CreateCardTooltip(cardId, asset, false)
                end)
        end
        return pattern
    end
    local desc = {
        [koi.combination.fiveBrights] = {
            name = i18n("koi.combo.fiveBrights.name"),
            type = card.type.bright,
            point = i18n("koi.combo.fiveBrights.point", { count = koi.basePoint[koi.combination.fiveBrights] }),
            condition = i18n("koi.combo.fiveBrights.condition", { type = card.GetCardTypeText(card.type.bright).name }),
        },
        [koi.combination.fourBrights] = {
            name = i18n("koi.combo.fourBrights.name"),
            type = card.type.bright,
            point = i18n("koi.combo.fourBrights.point", { count = koi.basePoint[koi.combination.fourBrights] }),
            condition = i18n("koi.combo.fourBrights.condition",
                { type = card.GetCardTypeText(card.type.bright).name, symbol = card.GetCardText(rainman).name }),
        },
        [koi.combination.rainyFourBrights] = {
            name = i18n("koi.combo.rainyFourBrights.name"),
            type = card.type.bright,
            point = i18n("koi.combo.rainyFourBrights.point", { count = koi.basePoint[koi.combination.rainyFourBrights] }),
            condition = i18n("koi.combo.rainyFourBrights.condition", { type = card.GetCardTypeText(card.type.bright).name }),
        },
        [koi.combination.threeBrights] = {
            name = i18n("koi.combo.threeBrights.name"),
            type = card.type.bright,
            point = i18n("koi.combo.threeBrights.point", { count = koi.basePoint[koi.combination.threeBrights] }),
            condition = i18n("koi.combo.threeBrights.condition", { type = card.GetCardTypeText(card.type.bright).name }),
        },
        [koi.combination.boarDeerButterfly] = {
            name = i18n("koi.combo.boarDeerButterfly.name"),
            type = card.type.animal,
            point = i18n("koi.combo.boarDeerButterfly.point", { count = koi.basePoint[koi.combination.boarDeerButterfly] }),
            condition = i18n("koi.combo.boarDeerButterfly.condition", {
                symbol1 = card.GetCardText(boar).name,
                symbol2 = card.GetCardText(deer).name,
                symbol3 = card.GetCardText(butterfly).name
            }),
        },
        [koi.combination.animals] = {
            name = i18n("koi.combo.animals.name"),
            type = card.type.animal,
            point = i18n("koi.combo.animals.point",
                { count = koi.basePoint[koi.combination.animals], type = card.GetCardTypeText(card.type.animal).name }),
            condition = i18n("koi.combo.animals.condition", { type = card.GetCardTypeText(card.type.animal).name }),
        },
        [koi.combination.poetryAndBlueRibbons] = {
            name = i18n("koi.combo.poetryAndBlueRibbons.name"),
            type = card.type.ribbon,
            point = i18n("koi.combo.poetryAndBlueRibbons.point",
                { count = koi.basePoint[koi.combination.poetryAndBlueRibbons], type = card.GetCardTypeText(card.type.ribbon).name }),
            condition = i18n("koi.combo.poetryAndBlueRibbons.condition",
                { type = card.GetCardTypeText(card.type.ribbon).name }),
        },
        [koi.combination.poetryRibbons] = {
            name = i18n("koi.combo.poetryRibbons.name"),
            type = card.type.ribbon,
            point = i18n("koi.combo.poetryRibbons.point",
                { count = koi.basePoint[koi.combination.poetryRibbons], type = card.GetCardTypeText(card.type.ribbon).name }),
            condition = i18n("koi.combo.poetryRibbons.condition", {
                symbol1 = card.GetCardText(redPoetry[1]).name,
                symbol2 = card.GetCardText(redPoetry[2]).name,
                symbol3 = card.GetCardText(redPoetry[3]).name
            }),
        },
        [koi.combination.blueRibbons] = {
            name = i18n("koi.combo.blueRibbons.name"),
            type = card.type.ribbon,
            point = i18n("koi.combo.blueRibbons.point",
                { count = koi.basePoint[koi.combination.blueRibbons], type = card.GetCardTypeText(card.type.ribbon).name }),
            condition = i18n("koi.combo.blueRibbons.condition", {
                symbol1 = card.GetCardText(blueRibbon[1]).name,
                symbol2 = card.GetCardText(blueRibbon[2]).name,
                symbol3 = card.GetCardText(blueRibbon[3]).name
            }),
        },
        [koi.combination.ribbons] = {
            name = i18n("koi.combo.ribbons.name"),
            type = card.type.ribbon,
            point = i18n("koi.combo.ribbons.point",
                { count = koi.basePoint[koi.combination.ribbons], type = card.GetCardTypeText(card.type.ribbon).name }),
            condition = i18n("koi.combo.ribbons.condition", { type = card.GetCardTypeText(card.type.ribbon).name }),
        },
        [koi.combination.flowerViewingSake] = {
            name = i18n("koi.combo.flowerViewingSake.name"),
            type = card.type.chaff, -- no chaff but no suitable type
            point = i18n("koi.combo.flowerViewingSake.point", { count = koi.basePoint[koi.combination.flowerViewingSake] }),
            condition = i18n("koi.combo.flowerViewingSake.condition",
                { symbol1 = card.GetCardText(curtain).name, symbol2 = card.GetCardText(sakeCup).name }),
        },
        [koi.combination.moonViewingSake] = {
            name = i18n("koi.combo.moonViewingSake.name"),
            type = card.type.chaff, -- no chaff but no suitable type
            point = i18n("koi.combo.moonViewingSake.point", { count = koi.basePoint[koi.combination.moonViewingSake] }),
            condition = i18n("koi.combo.moonViewingSake.condition",
                { symbol1 = card.GetCardText(moon).name, symbol2 = card.GetCardText(sakeCup).name }),
        },
        [koi.combination.chaff] = {
            name = i18n("koi.combo.chaff.name"),
            type = card.type.chaff,
            point = i18n("koi.combo.chaff.point",
                { count = koi.basePoint[koi.combination.chaff], type = card.GetCardTypeText(card.type.chaff).name }),
            condition = i18n("koi.combo.chaff.condition", { type = card.GetCardTypeText(card.type.chaff).name }),
        },
    }
    local combo = {
        [koi.combination.fiveBrights] = function()
            local list = card.Find({ type = card.type.bright, findAll = true }) ---@cast list integer[]
            listup(list)
        end,
        [koi.combination.fourBrights] = function()
            local list = card.Find({ type = card.type.bright, findAll = true }) ---@cast list integer[]
            table.removevalue(list, rainman)
            listup(list)
        end,
        [koi.combination.rainyFourBrights] = function()
        end,
        [koi.combination.threeBrights] = function()
        end,
        [koi.combination.boarDeerButterfly] = function()
            local list = { boar, deer, butterfly }
            listup(list)
        end,
        [koi.combination.animals] = function()
        end,
        [koi.combination.poetryAndBlueRibbons] = function()
            local list = {}
            list = { redPoetry[1], redPoetry[2], redPoetry[3], blueRibbon[1], blueRibbon[2], blueRibbon[3] }
            listup(list)
        end,
        [koi.combination.poetryRibbons] = function()
            listup(redPoetry)
        end,
        [koi.combination.blueRibbons] = function()
            listup(blueRibbon)
        end,
        [koi.combination.ribbons] = function()
        end,
        [koi.combination.flowerViewingSake] = function()
            local list = { curtain, sakeCup }
            listup(list)
        end,
        [koi.combination.moonViewingSake] = function()
            local list = { moon, sakeCup }
            listup(list)
        end,
        [koi.combination.chaff] = function()
        end,
    }

    if combo[combination] and desc[combination] then
        local d = desc[combination]

        local head = block:createBlock()
        head.widthProportional = 1
        head.autoHeight = true
        local name = head:createLabel({ text = d.name })
        name.color = card.GetCardTypeColor(d.type)
        --name.borderLeft = indent
        local right = head:createBlock()
        right.widthProportional = 1
        right.autoHeight = true
        right.childAlignX = 1

        if actualPoint then
            local point = right:createLabel({ text = i18n("koi.view.point", { count = actualPoint }) })
            --point.borderRight = indent * 2
            --point.wrapText = true
        else
            local point = block:createLabel({ text = d.point })
            --point.borderLeft = indent * 2
            point.wrapText = true
        end

        if summary then
            -- not showing
        else
            local condition = block:createLabel({ text = d.condition })
            --condition.borderLeft = indent * 2
            condition.wrapText = true
            combo[combination]()
        end
    else
        logger:error("unknown combination %u", combination)
    end
    return block
end

---@param parent tes3uiElement
---@param luckyHands KoiKoi.LuckyHands
---@param actualPoint integer?
---@param maxWidth integer?
---@return tes3uiElement
function this.CreateLuckyHandsView(parent, luckyHands, actualPoint, maxWidth)
    --local indent = 0
    local block = parent:createBlock()
    block.flowDirection = tes3.flowDirection.topToBottom
    block.widthProportional = 1
    block.autoWidth = true
    block.autoHeight = true
    --block.borderAllSides = 8
    block.paddingAllSides = 0
    -- block.paddingLeft = 8
    -- block.paddingRight = 8
    if maxWidth then
        block.maxWidth = maxWidth
    end

    local desc = {
        [koi.luckyHands.fourOfAKind] = {
            name = i18n("koi.luckyHands.fourOfAKind.name"),
            point = i18n("koi.luckyHands.fourOfAKind.point", { count = koi.luckyHandsPoint[koi.luckyHands.fourOfAKind] }),
            condition = i18n("koi.luckyHands.fourOfAKind.condition"),
        },
        [koi.luckyHands.fourPairs] = {
            name = i18n("koi.luckyHands.fourPairs.name"),
            point = i18n("koi.luckyHands.fourPairs.point", { count = koi.luckyHandsPoint[koi.luckyHands.fourPairs] }),
            condition = i18n("koi.luckyHands.fourPairs.condition"),
        },
    }

    if desc[luckyHands] then
        local d = desc[luckyHands]

        local head = block:createBlock()
        head.widthProportional = 1
        head.autoHeight = true
        local name = head:createLabel({ text = d.name })
        name.color = headerColor
        --name.borderLeft = indent
        local right = head:createBlock()
        right.widthProportional = 1
        right.autoHeight = true
        right.childAlignX = 1

        if actualPoint then
            local point = right:createLabel({ text = i18n("koi.view.point", { count = actualPoint }) })
            --point.borderRight = indent * 2
            --point.wrapText = true
        else
            local point = block:createLabel({ text = d.point })
            --point.borderLeft = indent * 2
            point.wrapText = true
        end

        local condition = block:createLabel({ text = d.condition })
        --condition.borderLeft = indent * 2
        condition.wrapText = true
    else
        logger:error("unknown luckyhands %u", luckyHands)
    end
    return block
end

---@param e uiEventEventData
---@param asset CardAssetPackage
function this.CreateCardList(e, asset)
    local menu = tes3ui.findMenu(uiid.helpCardListMenu)
    if menu then
        -- can be forecround focusing?
        return
    end

    local viewportWidth, viewportHeight = tes3ui.getViewportSize()
    local size = math.min(viewportWidth, viewportHeight)

    menu = tes3ui.createMenu({ id = uiid.helpCardListMenu, fixedFrame = true })
    menu.width = size * 0.9
    menu.height = size * 0.9
    menu.autoWidth = false
    menu.autoHeight = false
    menu.flowDirection = tes3.flowDirection.topToBottom

    local root = menu:createBlock()
    root.widthProportional = 1
    root.heightProportional = 1
    root.flowDirection = tes3.flowDirection.topToBottom

    local pane = root:createVerticalScrollPane()
    pane.widthProportional = 1
    pane.heightProportional = 1
    local parent = pane:getContentElement()
    parent.paddingAllSides = 6

    -- card table
    local scale = 0.75
    local padding = 4
    local minWidth = math.max(card.GetCardWidth() * scale + padding, 72)
    local suitWidth = math.max(card.GetCardWidth() * scale + padding, 128)
    local frame = parent
    -- local frame = parent:createThinBorder()
    -- frame.widthProportional = 1
    -- frame.autoWidth = true
    -- frame.autoHeight = true
    -- frame.flowDirection = tes3.flowDirection.topToBottom
    do
        local row = frame:createBlock()
        row.widthProportional = 1
        row.autoWidth = true
        row.autoHeight = true
        row.flowDirection = tes3.flowDirection.leftToRight
        --row.paddingAllSides = 2
        do
            local col = row:createBlock()
            col.autoHeight = true
            col.minWidth = suitWidth
            col.width = suitWidth
        end
        for _, j in ipairs(table.values(card.type, true)) do
            local col = row:createBlock()
            col.autoHeight = true
            col.flowDirection = tes3.flowDirection.leftToRight
            col.minWidth = minWidth
            col.width = minWidth
            col:createLabel({ text = card.GetCardTypeText(j).name }).color = card.GetCardTypeColor(j)
        end
    end
    frame:createDivider().widthProportional = 1
    for _, i in ipairs(table.values(card.suit, true)) do
        local row = frame:createBlock()
        row.widthProportional = 1
        row.autoWidth = true
        row.autoHeight = true
        row.flowDirection = tes3.flowDirection.leftToRight
        --row.paddingAllSides = 2
        do
            local col = row:createBlock()
            col.autoHeight = true
            col.minWidth = suitWidth
            col.width = suitWidth
            col.flowDirection = tes3.flowDirection.topToBottom
            -- not working...
            -- col.childAlignX = 1
            -- col.childAlignY = 0.5
            local text = card.GetCardSuitText(i)
            --col:createLabel({text = tostring(i) })
            local suit = col:createLabel({ text = text.name })
            suit.wrapText = true
            suit.color = headerColor
            if text.alt then
                local alt = col:createLabel({ text = text.alt })
                alt.wrapText = true
            end
        end

        for _, j in ipairs(table.values(card.type, true)) do
            local col = row:createBlock()
            col.autoWidth = true
            col.autoHeight = true
            col.minWidth = minWidth
            col.flowDirection = tes3.flowDirection.leftToRight
            local cards = card.Find({ suit = i, type = j, findAll = true }) --[[@as integer[]?]]
            if cards then
                for _, cardId in ipairs(cards) do
                    local a = asset:GetAsset(cardId)
                    local b = col:createBlock()
                    b.autoWidth = true
                    b.autoHeight = true
                    b.paddingAllSides = 0
                    b.paddingRight = padding
                    local image = b:createImage({ path = a.path })
                    image.width = card.GetCardWidth() * scale
                    image.height = card.GetCardHeight() * scale
                    image.scaleMode = true
                    b:register(tes3.uiEvent.help,
                        function(_)
                            this.CreateCardTooltip(cardId, asset, false)
                        end)
                end
            end
        end
        frame:createDivider().widthProportional = 1
    end

    local bottom = root:createBlock()
    bottom.widthProportional = 1
    bottom.autoHeight = true
    bottom.flowDirection = tes3.flowDirection.leftToRight
    bottom.childAlignX = 1
    local close = bottom:createButton({ text = tes3.findGMST(tes3.gmst.sClose).value --[[@as string]] })
    close:register(tes3.uiEvent.mouseClick,
        ---@param ev uiEventEventData
        function(ev)
            ev.source:getTopLevelMenu():destroy()
        end)

    menu:updateLayout()
    pane.widget:contentsChanged() ---@diagnostic disable-line: param-type-mismatch
end

---@param e uiEventEventData
---@param asset CardAssetPackage
function this.CreateCombinationList(e, asset)
    local menu = tes3ui.findMenu(uiid.helpComboListMenu)
    if menu then
        -- can be forecround focusing?
        return
    end

    local viewportWidth, viewportHeight = tes3ui.getViewportSize()
    local size = math.min(viewportWidth, viewportHeight)

    menu = tes3ui.createMenu({ id = uiid.helpComboListMenu, fixedFrame = true })
    menu.width = size * 0.9
    menu.height = size * 0.9
    menu.autoWidth = false
    menu.autoHeight = false
    menu.flowDirection = tes3.flowDirection.topToBottom

    local root = menu:createBlock()
    root.widthProportional = 1
    root.heightProportional = 1
    root.flowDirection = tes3.flowDirection.topToBottom

    local pane = root:createVerticalScrollPane()
    pane.widthProportional = 1
    pane.heightProportional = 1

    -- combo
    local parent = pane:getContentElement()
    parent.paddingAllSides = 6

    local label = parent:createLabel({ text = i18n("koi.combinations.label") })
    label.color = headerColor
    label.borderAllSides = 0
    label.borderTop = 6
    label.borderBottom = 6
    for _, value in ipairs(table.values(koi.combination, true)) do
        this.CreateCombinationView(parent, asset, value)
        parent:createDivider().widthProportional = 1.0
    end

    -- luckyhands
    label = parent:createLabel({ text = i18n("koi.luckyHands.label") })
    label.color = headerColor
    label.borderAllSides = 0
    label.borderTop = 6
    label.borderBottom = 6
    for _, value in ipairs(table.values(koi.luckyHands, true)) do
        this.CreateLuckyHandsView(parent, value)
        parent:createDivider().widthProportional = 1.0
    end

    local bottom = root:createBlock()
    bottom.widthProportional = 1
    bottom.autoHeight = true
    bottom.flowDirection = tes3.flowDirection.leftToRight
    bottom.childAlignX = 1
    local close = bottom:createButton({ text = tes3.findGMST(tes3.gmst.sClose).value --[[@as string]] })
    close:register(tes3.uiEvent.mouseClick,
        ---@param ev uiEventEventData
        function(ev)
            ev.source:getTopLevelMenu():destroy()
        end)

    menu:updateLayout()
    pane.widget:contentsChanged() ---@diagnostic disable-line: param-type-mismatch
end

---@param e uiEventEventData
function this.CreateRule(e)
    local menu = tes3ui.findMenu(uiid.helpRuleMenu)
    if menu then
        -- can be forecround focusing?
        return
    end

    local viewportWidth, viewportHeight = tes3ui.getViewportSize()
    local size = math.min(viewportWidth, viewportHeight)

    local menu = tes3ui.createMenu({ id = uiid.helpRuleMenu, fixedFrame = true })
    menu.width = size * 0.9
    menu.height = size * 0.9
    menu.autoWidth = false
    menu.autoHeight = false
    menu.flowDirection = tes3.flowDirection.topToBottom

    local root = menu:createBlock()
    root.widthProportional = 1
    root.heightProportional = 1
    root.flowDirection = tes3.flowDirection.topToBottom

    local pane = root:createVerticalScrollPane()
    pane.widthProportional = 1
    pane.heightProportional = 1
    local parent = pane:getContentElement()

    ---@param p tes3uiElement
    ---@param text string
    ---@param indent integer?
    local function createHeader(p, text, indent)
        indent = indent or 0
        local l = p:createLabel({ text = text })
        l.color = headerColor
        l.wrapText = true
        l.borderAllSides = 6
        l.borderTop = 12
        l.borderLeft = indent * 12
    end
    ---@param p tes3uiElement
    ---@param text string
    ---@param indent integer?
    local function createText(p, text, indent)
        indent = indent and (indent + 1) or 1
        local l = p:createLabel({ text = text })
        l.wrapText = true
        l.borderAllSides = 6
        l.borderLeft = indent * 12
    end
    ---@param p tes3uiElement
    ---@param text string
    ---@param indent integer?
    local function createLink(p, text, url, indent)
        indent = indent and (indent + 1) or 1
        local l = p:createHyperlink({ text = text, url = url })
        l.wrapText = true
        l.borderAllSides = 6
        l.borderLeft = indent * 12
    end
    -- tl;dr
    createHeader(parent, i18n("koi.help.tldr.header"))
    createText(parent, i18n("koi.help.tldr.description"))
    createHeader(parent, i18n("koi.help.tips.header"), 1)
    createText(parent, i18n("koi.help.tips.description"), 1)
    parent:createDivider().widthProportional = 1.0

    -- hanafuda abstruct
    createHeader(parent, i18n("hanafuda.help.summary.header"))
    createText(parent, i18n("hanafuda.help.summary.description"))
    parent:createDivider().widthProportional = 1.0

    -- koikoi abstruct
    createHeader(parent, i18n("koi.help.summary.header"))
    createText(parent, i18n("koi.help.summary.description"))

    createHeader(parent, i18n("koi.help.rule.header"), 1)
    createHeader(parent, i18n("koi.help.rule.setup.header"), 2)
    createText(parent, i18n("koi.help.rule.setup.description"), 2)

    createHeader(parent, i18n("koi.help.rule.luckyHands.header"), 3)
    createText(parent, i18n("koi.help.rule.luckyHands.description"), 3)

    createHeader(parent, i18n("koi.help.rule.turn.header"), 2)
    createHeader(parent, i18n("koi.help.rule.turn.match.header"), 3)
    createText(parent, i18n("koi.help.rule.turn.match.description"), 3)
    createHeader(parent, i18n("koi.help.rule.turn.draw.header"), 3)
    createText(parent, i18n("koi.help.rule.turn.draw.description"), 3)
    createHeader(parent, i18n("koi.help.rule.turn.check.header"), 3)
    createText(parent, i18n("koi.help.rule.turn.check.description"), 3)
    createHeader(parent, i18n("koi.help.rule.turn.check.continue.header"), 4)
    createText(parent, i18n("koi.help.rule.turn.check.continue.description"), 4)
    createHeader(parent, i18n("koi.help.rule.turn.check.end.header"), 4)
    createText(parent, i18n("koi.help.rule.turn.check.end.description"), 4)

    createHeader(parent, i18n("koi.help.rule.round.header"), 3)
    createText(parent, i18n("koi.help.rule.round.description"), 3)
    createHeader(parent, i18n("koi.help.rule.round.scoring.header"), 4)
    createText(parent, i18n("koi.help.rule.round.scoring.description"), 4)
    createHeader(parent, i18n("koi.help.rule.round.emptyDeck.header"), 4)
    createText(parent, i18n("koi.help.rule.round.emptyDeck.description"), 4)

    createHeader(parent, i18n("koi.help.rule.end.header"), 2)
    createText(parent, i18n("koi.help.rule.end.description"), 2)

    -- more info
    parent:createDivider().widthProportional = 1.0
    createHeader(parent, i18n("koi.help.more"))
    createLink(parent, "Wikipedia", "https://en.wikipedia.org/wiki/Koi-Koi")
    createLink(parent, "Fuda Wiki", "https://fudawiki.org/en/hanafuda/games/koi-koi")
    createLink(parent, "The History & Art of Hanafuda", "https://games.porg.es/articles/cards/japan/hanafuda/art/")

    local bottom = root:createBlock()
    bottom.widthProportional = 1
    bottom.autoHeight = true
    bottom.flowDirection = tes3.flowDirection.leftToRight
    bottom.childAlignX = 1
    local close = bottom:createButton({ text = tes3.findGMST(tes3.gmst.sClose).value --[[@as string]] })
    close:register(tes3.uiEvent.mouseClick,
        ---@param ev uiEventEventData
        function(ev)
            ev.source:getTopLevelMenu():destroy()
        end)

    menu:updateLayout()
    pane.widget:contentsChanged() ---@diagnostic disable-line: param-type-mismatch
end

---@param cardId integer
---@param asset CardAssetPackage
---@param backface boolean
---@return tes3uiElement?
function this.CreateCardTooltip(cardId, asset, backface)
    local tooltip = tes3ui.createTooltipMenu()
    if backface then
        -- It would be better if it could be replaced with a person's name. but it not make sence to receive in args.
        tooltip:createLabel({ text = i18n("koi.opponentCard") })
    else
        tooltip = tes3ui.createTooltipMenu()
        tooltip.flowDirection = tes3.flowDirection.leftToRight
        local ref = card.GetCardData(cardId)
        local name = tooltip:createLabel({ text = card.GetCardText(cardId).name })
        name.color = headerColor
        if config.tooltipImage then -- Unfortunately, displaying the image impairs gameplay.
            local a = asset:GetAsset(cardId)
            local thumb = tooltip:createImage({ path = a.path })
            thumb.width = card.GetCardWidth() * 1.5
            thumb.height = card.GetCardHeight() * 1.5
            thumb.scaleMode = true
        end
        tooltip:createLabel({ text = card.GetCardSuitText(ref.suit).name .. " (" .. tostring(ref.suit) .. ")" })
        local type = tooltip:createLabel({ text = card.GetCardTypeText(ref.type).name })
        type.color = card.GetCardTypeColor(ref.type)
        -- add flavor?
    end
    return tooltip
end

---@param deck integer[]
---@return tes3uiElement tooltip
function this.CreateDeckTooltip(deck)
    local tooltip = tes3ui.createTooltipMenu()
    local header = tooltip:createLabel({ text = "Deck" })
    header.color = headerColor
    local label = tooltip:createLabel({ text = i18n("koi.deck.remain", { count = table.size(deck) }) })
    return tooltip
end

---@param id number|string?
---@param parent tes3uiElement
---@param texts string[]
---@param selectedIndexChanged fun(selectedIndex:integer)?
---@param initialIndex integer?
---@return tes3uiElement
---@return tes3uiElement[]
---@return integer
function this.CreateSimpleListBox(id, parent, texts, selectedIndexChanged, initialIndex)
    local pane = parent:createVerticalScrollPane({ id = id })
    local content = pane:getContentElement()

    local selectedIndex = initialIndex or -1
    local items = {} ---@type tes3uiElement[]

    ---@param p tes3uiElement
    local function createItem(p, text)
        local label = p:createTextSelect({ text = text })
        table.insert(items, label)
        local index = table.size(items)
        if index == selectedIndex then
            label.widget.state = tes3.uiState.active
        end
        label:register(tes3.uiEvent.mouseClick,
        ---@param e uiEventEventData
        function(e)
            -- if selectedIndex == index then
            --     return
            -- end
            selectedIndex = index
            for i, item in ipairs(items) do
                if not item.disabled then
                    item.widget.state = tes3.uiState.normal
                end
            end
            e.source.widget.state = tes3.uiState.active
            e.source:getTopLevelMenu():updateLayout()
            if selectedIndexChanged then
                selectedIndexChanged(selectedIndex)
            end
        end)
    end

    for _, value in ipairs(texts) do
        createItem(content, value)
    end

    return pane, items, selectedIndex
end

---@param id number|string?
---@param parent tes3uiElement
---@param initialValue number
---@param valueChanged fun(value:number)?
---@return tes3uiElement
---@return tes3uiElement
---@return tes3uiElement
function this.CreateSimpleSlider(id, parent, initialValue, valueChanged)
    local resolution = 100
    local max = 1.0 * resolution

    local format = function(value)
        return string.format("%.2f", value)
    end

    local outer = parent:createBlock()
    outer.widthProportional = 1
    outer.autoWidth = true
    outer.autoHeight = true
    outer.flowDirection = tes3.flowDirection.leftToRight
    outer.borderAllSides = 0
    outer.borderLeft = 4
    outer.borderRight = 4
    local slider = outer:createSlider({ current = initialValue * resolution, max = max })
    slider.widthProportional = 1.5
    slider.autoWidth = true
    slider.autoHeight = true
    slider.borderAllSides = 0
    slider.paddingAllSides = 0
    slider.borderLeft = 4
    slider.borderTop = 4
    local label = outer:createLabel({ text = format(initialValue) }) -- one way
    label.widthProportional = 0.5
    label.autoWidth = true
    label.autoHeight = true
    label.borderAllSides = 0
    label.paddingAllSides = 0
    label.borderLeft = 4

    ---@param e tes3uiEventData
    local function OnValueChanged(e)
        local val = (slider.widget.current) / resolution
        val = math.clamp(val, 0.0, 1.0)
        label.text = format(val)
        if valueChanged then
            valueChanged(val)
        end
    end

    for _, child in ipairs(slider.children) do
        child:register(tes3.uiElementType.mouseClick, OnValueChanged)  -- click, drag
        child:register(tes3.uiEvent.mouseRelease, OnValueChanged)      -- drag
        for _, gchild in ipairs(child.children) do
            gchild:register(tes3.uiEvent.mouseClick, OnValueChanged)   -- click, drag
            gchild:register(tes3.uiEvent.mouseRelease, OnValueChanged) -- drag
        end
    end

    -- need to update only value test?
    slider:register(tes3.uiEvent.partScrollBarChanged, OnValueChanged)

    return outer, slider, label
end

return this
