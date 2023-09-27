---@class Gamble.Service
local this = {}

local logger = require("Hanafuda.logger")
local act = require("Hanafuda.Gamble.actor")
local uiid = require("Hanafuda.Gamble.uiid")
local koi = require("Hanafuda.KoiKoi.koikoi")
local config = require("Hanafuda.config")
local settings = require("Hanafuda.Gamble.settings")
local i18n = mwse.loadTranslations("Hanafuda")

---@param player tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@param opponent tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@param conf Config.KoiKoi
local function CalculateBettingSettings(player, opponent, conf)
    local playerGold = act.GetActorGold(player)
    local opponentGold = act.GetActorGold(opponent)
    logger:debug("Player money " .. tostring(playerGold))
    logger:debug("NPC money " .. tostring(opponentGold))

    -- Allow odds if there is some amount of payment on both sides.
    local gold = math.min(playerGold, opponentGold)
    local bettingModifier = act.CalculateBettingOddsModifier(player, opponent)
    local metric = gold / (settings.penaltyPointPerRound * settings.GetMultiplierFactorByHouseRule(config.koikoi.houseRule.multiplier) * conf.round) -- average points per round... no evidence!
    metric = metric * bettingModifier
    metric = math.ceil(math.max(metric, 0))
    logger:debug("Betting Metric %f", metric)

    local enables = {}
    for _, value in ipairs(settings.oddsList) do
        local enable = value <= metric
        logger:trace("odds %d <= %d " .. tostring(enable), value, metric)
        table.insert(enables, enable)
    end
    return playerGold, enables
end

--- This is popular in hanafuda gambling, where money is transferred according to difference scores and unit price.
--- NPCs in morrowind have little or no money. It may be more obvious to deal with a unique currency. or other gambling, debt system.
---@param player tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@param npc tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@param playerPoint number
---@param opponentPoint number
---@param unitPrice number
---@param allowDupe boolean not zero-sum. Missing money will be made up.
---@return number expected
---@return number actual
---@return number insufficient +npc -player
local function TradeGold(player, npc, playerPoint, opponentPoint, unitPrice, allowDupe)
    local delta = playerPoint - opponentPoint
    local expected = delta * unitPrice
    local item = "Gold_001"
    local npcGold = act.GetActorGold(npc)
    local playerGold = act.GetActorGold(player)     -- tes3.getPlayerGold()

    if expected > 0 then -- palyer gain money
        -- collect barter gold first
        local actual = allowDupe and expected or math.min(npcGold, expected)
        logger:debug("player cash from %d to %d", playerGold, playerGold + actual)

        local barterGold = npc.barterGold
        if barterGold > 0 then
            npc.barterGold = math.max(barterGold - actual, 0)
            tes3.addItem({ reference = player.reference, item = item, count = actual })
            logger:debug("collect %d from npc barterGold %d, %d remaining", actual, barterGold, npc.barterGold)
        end
        local cash = math.max(actual - barterGold, 0)
        if cash > 0 then
            if allowDupe then
                tes3.addItem({ reference = player.reference, item = item, count = cash })
                tes3.removeItem({ reference = npc.reference, item = item, count = cash })
            else
                tes3.transferItem({ from = npc.reference, to = player.reference, item = item, count = cash })
            end
            logger:debug("collect %d from npc cash %d, %d remaining", cash, npcGold - barterGold,
                math.max(npcGold - barterGold - cash, 0))
        end
        return expected, actual, (expected - actual)

    elseif expected < 0 then -- player lose money
        -- No sound when there is no money
        expected = -expected
        local actual = allowDupe and expected or math.min(playerGold, expected)
        logger:debug("collect %d from player cash %d, %d remaining", actual, playerGold, math.max(playerGold - actual, 0))
        if act.CanBarter(npc) then
            -- barterGold resets periodically, so might better add it in npc's inventory at all times?
            npc.barterGold = npc.barterGold + actual
            tes3.removeItem({ reference = player.reference, item = item, count = actual })
            logger:debug("npc barterGold from %d to %d", npc.barterGold + actual, npc.barterGold)
        else
            if allowDupe then
                tes3.addItem({ reference = npc.reference, item = item, count = actual })
                tes3.removeItem({ reference = player.reference, item = item, count = actual })
            else
                tes3.transferItem({ from = player.reference, to = npc.reference, item = item, count = actual })
            end
            logger:debug("npc cash from %d to %d", npcGold - npc.barterGold, npcGold - npc.barterGold + actual)
        end
        return -expected, -actual, -(expected - actual)
    end

    return 0, 0, 0
end

---@param expected integer
---@param actual integer
---@param insufficient integer
---@param odds integer
---@return integer
local function CalculateDispositionByInsufficient(expected, actual, insufficient, odds)
    if insufficient == 0 or expected == 0 or odds == 0 then
        return 0
    end
    -- affect personality, luck reputation, speechcraft?
    -- The more insufficient money and the higher the odds, the more likely it is to change.
    local ratio = (insufficient / expected) -- relative
    -- ratio = insufficient * 0.3 -- absolute
    local delta = ratio * odds * settings.dispositionByInsufficientCoefficient
    delta = math.ceil(delta)
    if insufficient < 0 then -- sign, after ceil for negative value behaviour
        delta = -delta
     end
     return delta
end

---@param player tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@param opponent tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@param disposition integer
---@return boolean
local function ChangeDisposition(player, opponent, disposition)
    -- If they are teaming up with a PC like a companion, it seems better not to change their disposition, but how can I detect them?
    if not disposition then
        logger:debug("no disposition changed")
        return false
    end
    if player.actorType == tes3.actorType.player and opponent.actorType == tes3.actorType.npc then
        opponent.object.baseDisposition = math.clamp(opponent.object.baseDisposition + disposition, 0, 100)
        logger:debug("disposition changed %d", disposition)
        return true
    elseif opponent.actorType == tes3.actorType.player and player.actorType == tes3.actorType.npc then
        player.object.baseDisposition = math.clamp(player.object.baseDisposition + disposition, 0, 100)
        logger:debug("disposition changed %d", disposition)
        return true
    end
    -- creature
    return false
end

local eventHandler ---@type KoiKoi.EventHandler?

---@param player tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@param opponent tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@param odds integer
---@param penaltyPoint integer
local function LaunchKoiKoi(player, opponent, odds, penaltyPoint)
    local brain = act.GetAIBrain(opponent)

    -- I would like a helper.
    eventHandler = require("Hanafuda.KoiKoi.MWSE.event").new(
        require("Hanafuda.KoiKoi.service").new(
            require("Hanafuda.KoiKoi.game").new(config.koikoi, brain, nil, logger),
            require("Hanafuda.KoiKoi.MWSE.view").new(player, opponent, config.cardStyle, config.cardBackStyle),
            ---@param params KoiKoi.ExitStatus
            function(params)
                -- and maybe need to get points for gambling
                if eventHandler then
                    eventHandler:Destory()
                    eventHandler = nil
                end
                local winner = params.winner
                local pp = params.playerPoint
                local op = params.opponentPoint
                if params.conceding ~= nil then
                    if params.conceding == koi.player.you then
                        -- It's not actually winning, so it might not want to start referring to it for other things.
                        winner = koi.player.opponent
                        pp = 0
                        op = math.max(op, penaltyPoint)
                    else
                        winner = koi.player.you
                        pp = math.max(pp, penaltyPoint)
                        op = 0
                    end
                end
                if winner ~= nil and odds > 0 then
                    local expected, actual, insufficient = TradeGold(player, opponent, pp, op, odds, false)
                    -- Use insufficient for debt, etc.
                    logger:debug("trade gold expected=%d, actual=%d, insufficient=%d", expected, actual, insufficient)
                    if expected > 0 then
                        if insufficient == 0 then
                            tes3.messageBox(i18n("gamble.collected", {actual = actual}))
                        else
                            tes3.messageBox(i18n("gamble.collectedInsufficient", {expected = expected, actual = actual}))
                            ChangeDisposition(player, opponent, CalculateDispositionByInsufficient(expected, actual, insufficient, odds))
                        end
                    elseif expected < 0 then
                        if insufficient == 0 then
                            tes3.messageBox(i18n("gamble.paid", {actual = -actual}))
                        else
                            tes3.messageBox(i18n("gamble.paidInsufficient", {expected = -expected, actual = -actual}))
                            ChangeDisposition(player, opponent, CalculateDispositionByInsufficient(expected, actual, insufficient, odds))
                        end
                    end
                end
            end,
            logger
        )
    )
    eventHandler:Initialize()
end

---@param e uiEventEventData
---@param player tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@param opponent tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
local function UpdateServiceMenuVisibility(e, player, opponent)
    timer.delayOneFrame(function()
            local b = e.source:findChild(uiid.menuDialogServiceKoiKoi)
            if b and not b.visible then
                b.visible = true
                if act.CanPerformService(player, opponent) then
                    b.widget.state = tes3.uiState.normal
                    b.disabled = false
                else
                    b.widget.state = tes3.uiState.disabled
                    b.disabled = true
                end
                e.source:updateLayout() -- endless calling?
                logger:trace("UpdateServiceMenuVisibility")
            end
        end,
        timer.real)
end

---@param mobile tes3mobileActor
---@return string
local function GetActorName(mobile)
    return mobile.reference.object.name
end

---@param menu tes3uiElement
---@param player tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@param opponent tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
local function AddGamblingMenu(menu, player, opponent)
    ----[[
    logger:debug("willpower    %d", opponent.willpower.current)
    logger:debug("intelligence %d", opponent.intelligence.current)
    logger:debug("personality  %d", opponent.personality.current)
    logger:debug("luck         %d", opponent.luck.current)
    if opponent.actorType == tes3.actorType.npc then
        logger:debug("mercantile   %d", opponent.mercantile.current)
        logger:debug("speechcraft  %d", opponent.speechcraft.current)
    end
    --]]

    local divider = menu:findChild(uiid.menuDialogDivider)
    local parent = divider.parent
    assert(divider)
    assert(parent)

    local serviceButton = parent:createTextSelect({ id = uiid.menuDialogServiceKoiKoi, text = i18n("koi.service.label") })
    parent:reorderChildren(divider, serviceButton, 1) -- above divider

    if not act.CanPerformService(player, opponent) then
        serviceButton.widget.state = tes3.uiState.disabled
        serviceButton.disabled = true
    end
    serviceButton:register(tes3.uiEvent.mouseClick,
        ---@param _ uiEventEventData
        function(_)
            local gold, enables = CalculateBettingSettings(player, opponent, config.koikoi)
            local penaltyPayout = settings.penaltyPointPerRound * config.koikoi.round
            require("Hanafuda.Gamble.ui").CreateBettingMenu(gold, settings.oddsList, enables, penaltyPayout,
            ---@param odds integer
            function(odds)
                LaunchKoiKoi(player, opponent, odds, penaltyPayout)
            end)
        end)

    serviceButton:register(tes3.uiEvent.help,
        ---@param e uiEventEventData
        function(e)
            if e.source.disabled then
                -- show reason
                -- or cache to use setProperty reason
                local condition, reason, byOpponent = act.CanPerformService(player, opponent)
                if not condition and reason then
                    local text = act.GetRefusedReasonText(reason, GetActorName(byOpponent and opponent or player))
                    if text then
                        local tooltip = tes3ui.createTooltipMenu()
                        tooltip:createLabel({ text = text })
                    end
                end
            else
                local tooltip = tes3ui.createTooltipMenu()
                tooltip:createLabel({ text = i18n("koi.service.tooltip") })
            end
        end)

    menu:registerAfter(tes3.uiEvent.update,
    ---@param e uiEventEventData
    function(e)
        UpdateServiceMenuVisibility(e, player, opponent)
    end)
end

--- @param e uiActivatedEventData
local function OnMenuDialogActivated(e)
    if not e.newlyCreated then
        return
    end
    local serviceActor = tes3ui.getServiceActor()
    if not serviceActor then
        return
    end

    if not act.HasServiceMenu(tes3.mobilePlayer, serviceActor) then
        logger:debug("no service")
        return
    end

    AddGamblingMenu(e.element, tes3.mobilePlayer, serviceActor)
end
event.register(tes3.event.uiActivated, OnMenuDialogActivated, { filter = "MenuDialog", priority = 0 })

return this
