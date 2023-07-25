local this = {}

local uiid = require("Hanafuda.Gamble.uiid")
local logger = require("Hanafuda.logger")
local i18n = mwse.loadTranslations("Hanafuda")

local headerColor = tes3ui.getPalette(tes3.palette.headerColor)

---@param value boolean
---@return string
local function GetYesNo(value)
    return (value and tes3.findGMST(tes3.gmst.sYes).value --[[@as string]] or tes3.findGMST(tes3.gmst.sNo).value --[[@as string]])
end

---@param parent tes3uiElement
---@param text string
---@param bool boolean
---@param callback fun(e: tes3uiEventData) : boolean
---@return tes3uiElement
---@return tes3uiElement
---@return tes3uiElement
local function CreateButton(parent, text, bool, callback)
    local block = parent:createBlock()
    block.widthProportional = 1
    block.autoWidth = true
    block.autoHeight = true
    local button = block:createButton({ text = GetYesNo(bool) })
    button.borderAllSides = 0
    local label = block:createLabel({ text = "Enable Hanami-Zake" })
    label.borderAllSides = 0
    button:register(tes3.uiEvent.mouseClick,
        ---@param e tes3uiEventData
        function(e)
            local result = callback(e)
            e.source.text = GetYesNo(result)
        end)
    return block, button, label
end

---@param parent tes3uiElement
---@param texts string[]
---@param enables boolean[]?
---@param selectedIndexChanged fun(selectedIndex:integer)?
---@param initialIndex integer?
---@return integer
---@return tes3uiElement[]
local function CreateListBox(parent, texts, enables, selectedIndexChanged, initialIndex)
    local frame = parent:createThinBorder()
    frame.widthProportional = 1
    frame.autoWidth = true
    frame.autoHeight = true
    frame.flowDirection = tes3.flowDirection.topToBottom
    --frame.borderAllSides = 4
    frame.paddingAllSides = 2

    local selectedIndex = initialIndex or -1
    if enables and not enables[selectedIndex] then
        selectedIndex = -1
    end
    local items = {} ---@type tes3uiElement[]
    local alpha = 0.2
    local selectedBgColor = tes3ui.getPalette(tes3.palette.activeColor)

    ---@param p tes3uiElement
    local function createItem(p, text)
        local bg = p:createRect()
        bg.widthProportional = 1
        bg.autoWidth = true
        bg.autoHeight = true
        bg.color = selectedBgColor
        bg.alpha = 0
        bg.paddingAllSides = 2
        local label = bg:createTextSelect({ text = text })
        table.insert(items, label)
        local index = table.size(items)
        if index == selectedIndex then
            label.widget.state = tes3.uiState.active
            bg.alpha = alpha
        end
        if not enables or enables[index] then
            bg:register(tes3.uiEvent.mouseClick,
            ---@param e uiEventEventData
            function(e)
                selectedIndex = index
                for i, item in ipairs(items) do
                    if not item.disabled then
                        item.widget.state = tes3.uiState.normal
                        item.parent.alpha = 0
                    end
                end
                e.source.alpha = alpha
                items[index].widget.state = tes3.uiState.active
                e.source:getTopLevelMenu():updateLayout()
                if selectedIndexChanged then
                    selectedIndexChanged(selectedIndex)
                end
                tes3.worldController.menuClickSound:play() -- self handling, but not clicked, clickgin is correctly.
            end)
            label:register(tes3.uiEvent.mouseClick,
            ---@param e uiEventEventData
            function(e)
                selectedIndex = index
                for i, item in ipairs(items) do
                    if not item.disabled then
                        item.widget.state = tes3.uiState.normal
                        item.parent.alpha = 0
                    end
                end
                e.source.parent.alpha = alpha
                e.source.widget.state = tes3.uiState.active
                e.source:getTopLevelMenu():updateLayout()
                if selectedIndexChanged then
                    selectedIndexChanged(selectedIndex)
                end
            end)
        else
            bg.disabled = true
            label.disabled = true
            label.widget.state = tes3.uiState.disabled
        end
    end

    for _, value in ipairs(texts) do
        createItem(frame, value)
    end

    return selectedIndex, items
end

---@param gold integer
---@param oddsList integer[]
---@param enables boolean[]?
---@param penaltyPoint integer
---@param callback fun(odds:integer)?
---@return tes3uiElement
function this.CreateBettingMenu(gold, oddsList, enables, penaltyPoint, callback)
    local menu = tes3ui.findMenu(uiid.gambleMenu)
    if menu then
        menu:destroy()
    end
    menu = tes3ui.createMenu({ id = uiid.gambleMenu, fixedFrame = true })
    menu.autoWidth = true
    menu.autoHeight = true
    menu.minWidth = 300
    menu.flowDirection = tes3.flowDirection.topToBottom
    local root = menu:createBlock()
    root.widthProportional = 1
    root.heightProportional = 1
    root.autoWidth = true
    root.autoHeight = true
    root.flowDirection = tes3.flowDirection.topToBottom
    local head = root:createBlock()
    head.widthProportional = 1
    head.autoWidth = true
    head.autoHeight = true
    head.childAlignX = 0.5
    head.borderAllSides = 4
    head:createLabel({ text = i18n("koi.service.label") }).color = headerColor

    local o = root:createBlock()
    o.widthProportional = 1
    o.autoWidth = true
    o.autoHeight = true
    o.borderAllSides = 4
    o.flowDirection = tes3.flowDirection.topToBottom
    local l = o:createLabel({ text = i18n("koi.service.odds.label")})
    l.borderBottom = 4
    local selectedIndex = 1
    local items = nil ---@type tes3uiElement[]
    local payout = nil ---@type tes3uiElement

    local function estimatePayout()
        if selectedIndex > 0 then
            return oddsList[selectedIndex] * penaltyPoint
        end
        return 0
    end

    local texts = {}
    for index, value in ipairs(oddsList) do
        local t = value > 0 and i18n("koi.service.odds.rate", {count = value}) or i18n("koi.service.odds.free")
        table.insert(texts, t)
    end

    selectedIndex, items = CreateListBox(o, texts, enables,
    function(index)
        selectedIndex = index
        payout.text = i18n("koi.service.payout", { count = estimatePayout() })
    end,
    selectedIndex)
    for index, item in ipairs(items) do
        item:register(tes3.uiEvent.help,
        ---@param e uiEventEventData
        function(e)
            if e.source.disabled then
                local tooltip = tes3ui.createTooltipMenu()
                -- wrap doesnt work
                tooltip:createLabel({ text = i18n("koi.service.odds.disabled") }).wrapText = true
            end
        end)
    end
    local info = root:createBlock()
    info.widthProportional = 1
    info.autoWidth = true
    info.autoHeight = true
    info.borderAllSides = 4
    info.flowDirection = tes3.flowDirection.topToBottom
    info:createLabel({ text = tes3.findGMST(tes3.gmst.sGold).value --[[@as string]] .. string.format(": %u", gold) })
    payout = info:createLabel({ text = i18n("koi.service.payout", { count = estimatePayout() })})
    --payout.wrapText = true

    -- house rule
    -- round

    local buttons = root:createBlock()
    buttons.widthProportional = 1
    buttons.autoWidth = true
    buttons.autoHeight = true
    buttons.borderAllSides = 4
    local ok = buttons:createButton({ text = tes3.findGMST(tes3.gmst.sOK).value --[[@as string]] })
    local right = buttons:createBlock()
    right.widthProportional = 1
    right.autoWidth = true
    right.autoHeight = true
    right.childAlignX = 1
    local cancel = right:createButton({ text = tes3.findGMST(tes3.gmst.sCancel).value --[[@as string]] })

    ok:register(tes3.uiEvent.mouseClick, function(e)
        e.source:getTopLevelMenu():destroy()
        if callback and selectedIndex > 0 then
            callback(oddsList[selectedIndex])
        end
    end)

    cancel:register(tes3.uiEvent.mouseClick, function(e)
        e.source:getTopLevelMenu():destroy()
    end)

    menu:updateLayout()
    --pane.widget:contentsChanged() ---@diagnostic disable-line: param-type-mismatch
    return menu
end


return this
