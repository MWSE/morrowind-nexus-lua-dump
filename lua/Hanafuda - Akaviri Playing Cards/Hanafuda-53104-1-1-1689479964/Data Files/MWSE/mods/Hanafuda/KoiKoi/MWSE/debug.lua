local config = require("Hanafuda.config")

-- koikoi
local eventHandler = nil ---@type KoiKoi.EventHandler?
event.register(tes3.event.keyDown,
---@param e keyDownEventData
function(e)
    local mod = e.isAltDown or e.isControlDown or e.isShiftDown or e.isSuperDown
    if mod then
        return
    end
    if eventHandler then
        eventHandler:Destory()
        eventHandler = nil
    else
        local logger = require("Hanafuda.logger")
        -- todo need game settings menu
        -- brain, parameters, debug options
        eventHandler = require("Hanafuda.KoiKoi.MWSE.event").new(
            require("Hanafuda.KoiKoi.service").new(
                require("Hanafuda.KoiKoi.game").new(
                    require("Hanafuda.config").koikoi,
                    require("Hanafuda.KoiKoi.brain.randomBrain").new({ koikoiChance = 0.3, meaninglessDiscardChance = 0.1, waitHand = { s = 1, e = 4}, waitDrawn = { s = 0.5, e = 1.5}, waitCalling = { s = 2, e = 4 } }),
                    nil,
                    logger
                ),
                require("Hanafuda.KoiKoi.MWSE.view").new(nil, nil, config.cardStyle, config.cardBackStyle),
                function()
                    if eventHandler then
                        eventHandler:Destory()
                        eventHandler = nil
                    end
                end,
                logger
            )
        )
        eventHandler:Initialize()
    end
end, {filter = tes3.scanCode.k} )

-- sound player
event.register(tes3.event.keyDown,
---@param e keyDownEventData
function(e)
    local mod = e.isAltDown or e.isControlDown or e.isShiftDown or e.isSuperDown
    if mod then
        return
    end
    require("Hanafuda.KoiKoi.MWSE.sound").CreateSoundPlayer()
end, { filter = tes3.scanCode.v })

-- runner
local function CreateRunner()
    local menuid = "Hanafuda.KoiKoi.Runner"
    local menu = tes3ui.findMenu(menuid)
    if menu then
        menu:destroy()
        tes3ui.leaveMenuMode()
        return
    end
    local logger = require("Hanafuda.logger")

    local params = {
        batchSize = 10,
        iteration = 10,
        epoch = 10,
        p1 = { index = 1,
            numbers = { 0, 0 },
        },
        p2 = { index = 1,
            numbers = { 0, 0 },
        },
    }

    menu = tes3ui.createMenu({ id = menuid, fixedFrame = true })
    menu.autoWidth = true
    menu.autoHeight = true
    menu.minWidth = 560
    menu.minHeight = 400
    menu.flowDirection = tes3.flowDirection.topToBottom
    local root = menu:createBlock()
    root.widthProportional = 1
    root.heightProportional = 1
    root.autoWidth = true
    root.autoHeight = true
    root.flowDirection = tes3.flowDirection.topToBottom

    local header = root:createBlock()
    header.widthProportional = 1
    header.autoWidth = true
    header.autoHeight = true
    header.flowDirection = tes3.flowDirection.leftToRight

    header:createLabel({ text = "batch: " }).borderRight = 6
    local batchInput = header:createTextInput({ text = tostring(params.batchSize), numeric = true, placeholderText = "batch" })
    batchInput.widthProportional = 1
    batchInput:register(tes3.uiEvent.mouseClick,
    ---@param e uiEventEventData
    function(e)
        tes3ui.acquireTextInput(e.source)
    end)

    header:createLabel({ text = "iteration: " }).borderRight = 6
    local iterationInput = header:createTextInput({ text = tostring(params.iteration), numeric = true, placeholderText = "iteration" })
    iterationInput.widthProportional = 1
    iterationInput:register(tes3.uiEvent.mouseClick,
    ---@param e uiEventEventData
    function(e)
        tes3ui.acquireTextInput(e.source)
    end)
    header:createLabel({ text = "epoch: "}).borderRight = 6
    local epochInput = header:createTextInput({ text = tostring(params.epoch), numeric = true, placeholderText = "epoch" })
    epochInput.widthProportional = 1
    epochInput:register(tes3.uiEvent.mouseClick,
    ---@param e uiEventEventData
    function(e)
        tes3ui.acquireTextInput(e.source)
    end)

    root:createDivider().widthProportional = 1

    local parent = root:createBlock()
    parent.widthProportional = 1
    parent.heightProportional = 1
    parent.autoWidth = true
    parent.autoHeight = true
    parent.flowDirection = tes3.flowDirection.topToBottom

    local p1 = parent:createBlock()
    p1.widthProportional = 1
    p1.heightProportional = 1
    p1.autoWidth = true
    p1.autoHeight = true
    p1.flowDirection = tes3.flowDirection.leftToRight
    local p2 = parent:createBlock()
    p2.widthProportional = 1
    p2.heightProportional = 1
    p2.autoWidth = true
    p2.autoHeight = true
    p2.flowDirection = tes3.flowDirection.leftToRight

    local dir = "Data Files\\MWSE\\mods\\Hanafuda\\KoiKoi\\brain\\"
    local relative = "Hanafuda.KoiKoi.brain."
    ---@type string[]
    local brains = {}
    for file in lfs.dir(dir) do
        if not file:startswith(".") and file:endswith(".lua") and file ~= "brain.lua" then
            local lua = file:sub(1, file:len() - 4)
            logger:trace(relative .. lua)
            table.insert(brains, lua)
        end
    end

    local ui = require("Hanafuda.KoiKoi.MWSE.ui")

    local pane1 = ui.CreateSimpleListBox(nil, p1, brains, function (selectedIndex)
        params.p1.index = selectedIndex
    end, params.p1.index)

    local o1 = p1:createBlock()
    o1.widthProportional = 1
    o1.heightProportional = 1
    o1.autoWidth = true
    o1.autoHeight = true
    o1.flowDirection = tes3.flowDirection.topToBottom
    o1.paddingBottom = 8
    for index, value in ipairs(params.p1.numbers) do
        ui.CreateSimpleSlider(nil, o1, value, function (v)
            params.p1.numbers[index] = v
        end)
    end

    local pane2 = ui.CreateSimpleListBox(nil, p2, brains, function (selectedIndex)
        params.p2.index = selectedIndex
    end, params.p2.index)

    local o2 = p2:createBlock()
    o2.widthProportional = 1
    o2.heightProportional = 1
    o2.autoWidth = true
    o2.autoHeight = true
    o2.flowDirection = tes3.flowDirection.topToBottom
    o2.paddingBottom = 8
    for index, value in ipairs(params.p2.numbers) do
        ui.CreateSimpleSlider(nil, o2, value, function (v)
            params.p2.numbers[index] = v
        end)
    end


    local footer = parent:createBlock()
    footer.widthProportional = 1
    -- parent.heightProportional = 1
    footer.autoWidth = true
    footer.autoHeight = true
    footer.flowDirection = tes3.flowDirection.leftToRight
    local run = footer:createButton({ text = "Run"})
    local cancel = footer:createButton({ text = "Cancel"})
    local cancellation = false
    cancel:register(tes3.uiEvent.mouseClick, function ()
        cancellation = true
    end)

    run:register(tes3.uiEvent.mouseClick,
    ---@param e uiEventEventData
    function (e)
        -- seems its not working well.
        e.source.disabled = true
        menu:updateLayout()

        cancellation = false

        local ba = tonumber(batchInput.text)
        params.batchSize = ba and math.max(math.ceil(ba), 0) or 1
        local it = tonumber(iterationInput.text)
        params.iteration = it and math.max(math.ceil(it), 0) or 1
        local ep = tonumber(epochInput.text)
        params.epoch = ep and math.max(math.ceil(ep), 0) or 1

        ---@param batch KoiKoi.Runner[]
        ---@param iteration integer
        ---@param epoch integer
        ---@return KoiKoi.Runner.Stats[]
        local function Run(batch, iteration, epoch)
            ---@type KoiKoi.Runner.Stats[]
            local stats = table.new(table.size(batch),0)
            for _, runner in ipairs(batch) do
                runner:Reset()
                while runner:Run() do
                end
                table.insert(stats, runner:GetStats())
            end
            return stats
        end

        local runlogger = require("logging.logger").new({
            name = "Hanafuda.Runner",
            logLevel = "INFO",
        })

        local batch = table.new(params.batchSize, 0)
        local epoch = 1
        -- flatten layout is better
        local koi = require("Hanafuda.KoiKoi.koikoi")
        ---@type KoiKoi.Runner.Stats[][][]
        local epochStats = table.new(params.epoch, 0)
        local allResults = {
            win = {
                [koi.player.you] = 0,
                [koi.player.opponent] = 0,
            },
            tie = 0,
        }

        logger:info("batch %d, iterations %d, epoch %d, total %d",
            params.batchSize,
            params.iteration,
            params.epoch,
            params.batchSize * params.iteration * params.epoch
        )
        logger:info("%s, %s, %s, %s",
            "epoch",
            brains[params.p1.index],
            brains[params.p2.index],
            "tie"
        )

        -- set custom rules
        local rule = require("Hanafuda.settings").Default().koikoi
        rule.houseRule.luckyHands = false

        timer.start({
            type = timer.real,
            ---@param callbackData mwseTimerCallbackData
            callback = function(callbackData)
                if cancellation then
                    logger:debug("cancel")
                    callbackData.timer:cancel()
                    e.source.disabled = false
                    menu:updateLayout()
                    return
                end
                runlogger:debug("epoch %d", epoch)

                table.clear(batch)
                local runner = require("Hanafuda.KoiKoi.runner")
                local b1 = require(relative .. brains[params.p1.index])
                local b2 = require(relative .. brains[params.p2.index])
                for i = 1, params.batchSize do
                    table.insert(batch, runner.new(
                        rule,
                        b1.generate({ logger = runlogger, numbers = params.p1.numbers }),
                        b2.generate({ logger = runlogger, numbers = params.p2.numbers }),
                        runlogger
                    ))
                end

                ---@type KoiKoi.Runner.Stats[][]
                local iterationStats = table.new(params.iteration, 0)
                for iteration = 1, params.iteration do
                    local stats = Run(batch, iteration, epoch)
                    table.insert(iterationStats, stats)
                end
                table.insert(epochStats, iterationStats)

                local result = {
                    win = {
                        [koi.player.you] = 0,
                        [koi.player.opponent] = 0,
                    },
                    tie = 0,
                }

                for _, batchStats in ipairs(iterationStats) do
                    for _, stats in ipairs(batchStats) do
                        if stats.winner then
                            result.win[stats.winner] = result.win[stats.winner] + 1
                        else
                            result.tie = result.tie + 1
                        end
                    end
                end

                allResults.win[koi.player.you] = allResults.win[koi.player.you] + result.win[koi.player.you]
                allResults.win[koi.player.opponent] = allResults.win[koi.player.opponent] + result.win[koi.player.opponent]
                allResults.tie = allResults.tie + result.tie

                local numPerEpoch = params.iteration * params.batchSize
                logger:info("%d, %d (%.1f%%), %d (%.1f%%), %d (%.1f%%)",
                    epoch,
                    result.win[koi.player.you], result.win[koi.player.you] / numPerEpoch * 100,
                    result.win[koi.player.opponent], result.win[koi.player.opponent] / numPerEpoch * 100,
                    result.tie, result.tie / numPerEpoch * 100
                 )

                -- end
                if epoch >= params.epoch then

                    local total = params.epoch * numPerEpoch
                    logger:info("result: %d (%.1f%%), %d (%.1f%%), %d (%.1f%%)",
                        allResults.win[koi.player.you], allResults.win[koi.player.you] / total * 100,
                        allResults.win[koi.player.opponent], allResults.win[koi.player.opponent] / total * 100,
                        allResults.tie, allResults.tie / total * 100
                    )

                    e.source.disabled = false
                    menu:updateLayout()

                    tes3.messageBox("Done.\n%s, %s\n%d (%.1f%%), %d (%.1f%%), %d (%.1f%%)",
                        brains[params.p1.index],
                        brains[params.p2.index],
                        allResults.win[koi.player.you], allResults.win[koi.player.you] / total * 100,
                        allResults.win[koi.player.opponent], allResults.win[koi.player.opponent] / total * 100,
                        allResults.tie, allResults.tie / total * 100)
                end
                epoch = epoch + 1
            end,
            iterations = params.epoch,
            duration = 0.1, -- hmm
            persist = false,
        })

    end)


    menu:updateLayout()
    pane1.widget:contentsChanged() ---@diagnostic disable-line: param-type-mismatch
    pane2.widget:contentsChanged() ---@diagnostic disable-line: param-type-mismatch
    tes3ui.enterMenuMode(menuid)

end

event.register(tes3.event.keyDown,
---@param e keyDownEventData
function(e)
    local mod = e.isAltDown or e.isControlDown or e.isShiftDown or e.isSuperDown
    if mod then
        return
    end

    CreateRunner()

end, { filter = tes3.scanCode.b })
