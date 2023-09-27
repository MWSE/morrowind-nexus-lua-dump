local koi = require("Hanafuda.KoiKoi.koikoi")
local card = require("Hanafuda.card")

---@enum KoiKoi.Phase
local phase = {
    new = 1,
    initialized = 2,
    decidingParent = 10,
    decidedParent = 11,
    decidedParentWait = 12,
    setupRound = 20,
    dealingInitial = 21,
    checkLuckyHands = 22,
    luckyHandsWait = 23,
    beginTurn = 30,
    matchCard = 40, -- rename
    matchCardFlip = 41, -- rename
    matchCardFlipWait = 42, -- rename
    matchCardWait = 43, -- rename
    drawCard = 50, -- rename
    drawCardWait = 51, -- rename
    matchDrawCard = 52, -- rename
    matchDrawCardWait = 53, -- rename
    checkCombo = 60,
    checkComboWait = 61,
    calling = 70,
    callingWait = 71,
    endTurn = 72,
    noMatch = 80,
    win = 81,
    roundResultWait = 82,
    roundFinished = 83,
    gameFinished = 90,
    resultWait = 91,
    terminate = 100,

    wait = 1000,
}

---@class KoiKoi.ExitStatus
---@field winner KoiKoi.Player? tie is nil
---@field playerPoint integer
---@field opponentPoint integer
---@field conceding KoiKoi.Player?

--- aka controller
---@class KoiKoi.Service
---@field phase KoiKoi.Phase
---@field phaseNext KoiKoi.Phase
---@field game KoiKoi.Game
---@field view KoiKoi.View
---@field drawnCard integer? or game has this
---@field skipDecidingParent boolean
---@field waitScale number
---@field lastCommand KoiKoi.ICommand?
---@field onExit fun(params : KoiKoi.ExitStatus)?
---@field logger mwseLogger
local Service = {}

-- todo debug: hold key skip to deside parent
-- fixed deciding and more debugging function

---@param game KoiKoi.Game
---@param view KoiKoi.View
---@param onExit fun(params : KoiKoi.ExitStatus)?
---@param logger mwseLogger
---@return KoiKoi.Service
function Service.new(game, view, onExit, logger)
    --@type KoiKoi.Service
    local instance = {
        phase = phase.new,
        phaseNext = phase.new,
        game = game,
        view = view,
        drawnCard = nil,
        skipDecidingParent = false, -- or table flags
        waitScale = 1.0,
        lastCommand = nil,
        onExit = onExit,
        logger = logger,
    }
    setmetatable(instance, { __index = Service })
    return instance
end

---@param self KoiKoi.Service
---@param cardId integer
---@param targetId integer
---@return boolean
function Service.CanMatch(self, cardId, targetId)
    return self.game.current == koi.player.you and self.game:CanMatch(cardId, targetId)
end

---@param self KoiKoi.Service
---@param cardId integer
---@param ground integer
---@return integer[] -- captured ground card, there is a possibility of getting more than one.
---@return boolean
function Service.Capture(self, cardId, ground)
    local drawn = self.drawnCard == cardId
    self.game:Capture(self.game.current, cardId, false, drawn)
    local many = self.game:CanCaptureExtra(cardId)
    if many ~= nil then
        for _, value in ipairs(many) do
            self.game:Capture(self.game.current, value, true, drawn)
        end
    else
        self.game:Capture(self.game.current, ground, true, drawn)
    end
    if drawn then
        self.drawnCard = nil
    end
    return many or { ground }, drawn
end


---@param self KoiKoi.Service
---@param cardId integer
---@return boolean
function Service.CanDiscard(self, cardId)
    return self.game.current == koi.player.you and self.game:CanDiscard(cardId)
end

---@param self KoiKoi.Service
---@param cardId integer
---@return boolean
function Service.Discard(self, cardId)
    local drawn = self.drawnCard == cardId
    self.game:Discard(self.game.current, cardId, drawn)
    if drawn then
        self.drawnCard = nil
    end
    return drawn
end

---@param self KoiKoi.Service
---@param next KoiKoi.Phase
---@return KoiKoi.Phase
function Service.RequestPhase(self, next)
    local n = next or (self.phase + 1)
    self.logger:trace("Request Phase %d -> %d", self.phase, n)
    -- self.phase = n
    -- return self.phase
    self.phaseNext = n
    return self.phaseNext
end

---@param self KoiKoi.Service
---@return boolean
function Service.TransitPhase(self)
    if self.phase == self.phaseNext then
        return false
    end
    if self.phase == phase.wait then
        return false
    end
    local wait = 0.5 -- default wait
    -- specific wait
    local waitNext = {
        [phase.new] = 0,
        [phase.initialized] = 1, -- put cards for deciding parent
        [phase.decidingParent] = 1,
        [phase.decidedParent] = 1,
        [phase.decidedParentWait] = 1,
        [phase.setupRound] = 1,
        [phase.dealingInitial] = 1,
        -- [phase.checkLuckyHands] = 1,
        -- [phase.luckyHandsWait] = 1,
        -- [phase.beginTurn] = 0,
        -- [phase.matchCard] = 0,
        -- [phase.matchCardFlip] = 1,
        [phase.matchCardFlipWait] = 1.5,
        -- [phase.matchCardWait] = 0,
        [phase.drawCard] = 1,
        -- [phase.drawCardWait] = 0,
        [phase.matchDrawCard] = 1.5, -- acatial drawn card
        -- [phase.matchDrawCardWait] = 0,
        -- [phase.checkCombo] = 0,
        -- [phase.checkComboWait] = 0,
        -- [phase.calling] = 0,
        -- [phase.callingWait] = 0,
        -- [phase.endTurn] = 0,
        [phase.noMatch] = 2,
        [phase.win] = 2,
        [phase.roundResultWait] = 2,
        [phase.roundFinished] = 2,
        [phase.gameFinished] = 2,
        [phase.resultWait] = 2,
        [phase.terminate] = 0,
    }
    -- or use current phase
    if waitNext[self.phaseNext] ~= nil then
        wait = waitNext[self.phaseNext]
    end

    -- when player input available, no wait
    if self.game:HasBrain(self.game.current) == false then
        if phase.matchCard <= self.phaseNext and self.phaseNext <= phase.matchDrawCardWait then
            wait = 0
        end
    end

    wait = wait * self.waitScale

    if wait > 0 then
        self.phase = phase.wait
        timer.start({
            type = timer.real,
            ---@param e mwseTimerCallbackData
            callback = function(e)
                self.logger:trace("Transit Phase %d -> %d", self.phase, self.phaseNext)
                self.phase = self.phaseNext
            end,
            iterations = 1,
            duration = wait,
            persist = false,
        })
    else
        self.logger:trace("Transit Phase %d -> %d", self.phase, self.phaseNext)
        self.phase = self.phaseNext
    end

    return true
end

---@param self KoiKoi.Service
---@return boolean
function Service.CanDrawCard(self)
    if self.game.current == koi.player.you and (self.phase == phase.matchDrawCard or self.phase == phase.matchDrawCardWait) then
        if self.drawnCard == nil and not self.game:EmptyDeck() then
            return true
        end
    end
    return false
end


---@param self KoiKoi.Service
---@return integer?
function Service.DrawCard(self)
    if self.drawnCard == nil then
        self.drawnCard = self.game:DrawCard()
    end
    return self.drawnCard
end

---@param self KoiKoi.Service
---@param cardId integer
---@return boolean
function Service.CanGrabCard(self, cardId)
    if self.game.current == koi.player.you and (self.phase == phase.matchDrawCard or self.phase == phase.matchDrawCardWait) then
        if self.drawnCard and self.drawnCard == cardId then
            return true
        end
    end
    if self.game.current == koi.player.you and (self.phase == phase.matchCard or self.phase == phase.matchCardWait) then
        return self.game:HasCard(self.game.current, cardId)
    end
    return false
end

---@param self KoiKoi.Service
---@param cardId integer
---@param player KoiKoi.Player
---@return boolean
function Service.CanPutbackCard(self, cardId, player)
    if self.game.current == koi.player.you and (self.phase == phase.matchCard or self.phase == phase.matchCardWait) then
        return self.game:HasCard(player, cardId)
    end
    return false
end

---@param self KoiKoi.Service
---@return boolean
function Service.IsPaused(self)
    if self.view and self.view:IsPaused() then
        return true
    end
    return false
end

---@param self KoiKoi.Service
---@param delta number
---@param timestamp number
function Service.OnEnterFrame(self, delta, timestamp)
    if self:IsPaused() then
        --self.logger:trace("paused")
        -- TODO the view should do something in response to the pause.
        -- It's not serious, but grabed card is visible and not following.
        return
    end

    local state = {
        [phase.initialized] = function()
            self.logger:debug("initialized")
            self:RequestPhase(phase.decidingParent)
            local cards = self.game:ChoiceDecidingParentCards(2)
            self.view:CreateDecidingParent(self, cards[1], cards[2])
        end,
        [phase.decidingParent] = function()
            -- wait for input
        end,
        [phase.decidedParent] = function()
            self.logger:debug("inform parent %d", self.game.parent)
            self:RequestPhase(phase.decidedParentWait)
            local cards = self.game.decidingParent
            self.view:InformParent(self.game.parent, self, self.game.decidingParentCardId, cards[1], cards[2])
        end,
        [phase.decidedParentWait] = function()
            -- wait for view
        end,
        [phase.setupRound] = function()
            self:RequestPhase(phase.dealingInitial)
            self.game:SetCurrentPlayer(self.game.parent)
            self.game:DealInitialCards()

            -- If there are four cards of the same suit dealt on the field, they cannot be acquired. They must be redealt.
            -- It would be nice to show the actual handouts and then start over, but without the animation it doesn't make much sense, and it's not very fast-paced if it happens several times over.
            -- Super worst case scenario may occur many times, but should be handled until internally resolved.
            while self.game:CheckUnluckyGround() do
                self.game:Initialize()
                self.game:DealInitialCards()
            end

            self.view:DealInitialCards(self.game.parent, self.game.pools, self.game.groundPool, self.game.deck, self)
        end,
        [phase.dealingInitial] = function()
            -- wait for view
        end,
        [phase.checkLuckyHands] = function()
            local accept, winner, lh, points = self.game:CheckLuckyHandsEach()
            if accept then
                self:RequestPhase(phase.luckyHandsWait)
                self.view:ShowLuckyHands(lh, points, winner, self)
                if winner then -- not tie
                    -- No transition to win, so we settle here.
                    self.game:SetRoundWinnerByLuckyHands(winner, points[winner])
                    self.view:UpdateScorePoint(winner, self.game.points[winner])
                end
            else
                self:RequestPhase(phase.beginTurn)
            end
        end,
        [phase.luckyHandsWait] = function()
        end,
        [phase.beginTurn] = function()
            self.view:BeginTurn(self.game.current, self.game.parent, self)
            --self:TransitPhase()
        end,
        [phase.matchCard] = function()
            if self.game:EmptyHand(self.game.current) then
                self:RequestPhase(phase.drawCard)
                return
            end
            local command = self.game:Simulate(self.game.current, nil, delta, timestamp)
            if command then
                -- first flip card
                self.lastCommand = command
                if command.selectedCard then
                    self:RequestPhase(phase.matchCardFlip) -- wait for view
                    self.view:Flip(self, self.game.current, command.selectedCard)
                else
                    -- error?
                end
            else
                -- thinking or no brain
                self.view:ThinkMatchingHand(self.game.current, delta);
            end
        end,
        [phase.matchCardFlip] = function()
            -- wait view
        end,
        [phase.matchCardFlipWait] = function()
            if self.lastCommand then
                local command = self.lastCommand ---@cast command KoiKoi.MatchCommand
                -- todo com:Execute()
                if command.selectedCard then
                    self:RequestPhase(phase.matchCardWait) -- wait for view

                    if command.matchedCard then
                        -- match
                        local caps = self:Capture(command.selectedCard, command.matchedCard)
                        self.view:Capture(self, self.game.current, command.selectedCard, caps, false)
                    else
                        -- discard
                        self:Discard(command.selectedCard)
                        self.view:Discard(self, self.game.current, command.selectedCard, false)
                    end
                else
                    -- error?
                end
            end
        end,
        [phase.matchCardWait] = function()
            -- wait view
        end,
        [phase.drawCard] = function()
            if self.game.brains[self.game.current] then
                local draw = self:DrawCard()
                assert(draw)
                self:RequestPhase(phase.drawCardWait) -- wait for view
                self.view:Draw(self, self.game.current, draw, self.game:EmptyDeck())
            else
                -- draw? prepare for view
                self:RequestPhase(phase.matchDrawCard)
            end
        end,
        [phase.drawCardWait] = function()
            -- waiting...
        end,
        [phase.matchDrawCard] = function()
            local command = self.game:Simulate(self.game.current, self.drawnCard, delta, timestamp)
            if command then
                -- todo com:Execute()
                self:RequestPhase(phase.matchDrawCardWait) -- wait for view

                if command.selectedCard and command.matchedCard then
                    -- match
                    local caps = self:Capture(command.selectedCard, command.matchedCard)
                    self.view:Capture(self, self.game.current, command.selectedCard, caps, true)
                elseif not command.matchedCard then
                    -- discard
                    self.view:Discard(self, self.game.current, command.selectedCard, true)
                    self:Discard(command.selectedCard)
                else
                    -- error
                    self.logger:error("wrong command for drawn card")
                end
            else
                -- thinking or no brain
                self.view:ThinkMatchingDrawn(self.game.current, delta)
            end
        end,
        [phase.matchDrawCardWait] = function()
        end,
        [phase.checkCombo] = function()
            if self.drawnCard ~= nil then
                self.logger:error("The card drawn is still held internally %d", self.drawnCard)
                self.drawnCard = nil
            end

            local combo = self.game:CheckCombination(self.game.current)
            if combo then
                self:RequestPhase(phase.checkComboWait)
                local basePoint, multiplier = self.game:CalculateRoundPoint(self.game.current)
                if self.game.brains[self.game.current] then
                    -- message? or other notify
                    self.view:ShowCombo(self.game.current, self, combo, basePoint, multiplier)
                else
                    self.view:ShowCallingDialog(self.game.current, self, combo, basePoint, multiplier)
                end
            else
                -- no comb
                self:RequestPhase(phase.endTurn)
            end
        end,
        [phase.checkComboWait] = function()
            -- wait for pc calling
            self.view:ThinkCalling(self.game.current, delta);
        end,
        [phase.calling] = function()
            local command = self.game:Call(self.game.current, self.game.combinations[self.game.current], delta, timestamp)
            if command then
                self:RequestPhase(phase.callingWait)
                self.lastCommand = command
                local basePoint, multiplier = self.game:CalculateRoundPoint(self.game.current)
                self.view:ShowCalling(self.game.current, self, command.calling, basePoint * multiplier)
            else
                self.view:ThinkCalling(self.game.current, delta);
            end
        end,
        [phase.callingWait] = function()
            -- wait view
        end,
        [phase.endTurn] = function()
            if self.game:CheckEnd() then
                self:RequestPhase(phase.noMatch)
            else
                self.game:SwapPlayer()
                self:RequestPhase(phase.beginTurn)
            end
        end,
        [phase.noMatch] = function()
            self:RequestPhase(phase.roundResultWait)
            self.view:ShowNoMatch(self.game.parent, self)
            -- TODO tie or parent win (house rule)
        end,
        [phase.win] = function()
            self:RequestPhase(phase.roundResultWait)
            self.view:ShowWin(self.game.current, self)
            -- win current player
            self.game:SetRoundWinner(self.game.current)
            self.view:UpdateScorePoint(self.game.current, self.game.points[self.game.current])
        end,
        [phase.roundResultWait] = function()
            --wait
        end,
        [phase.roundFinished] = function ()
            if self.game:NextRound() then
                -- clean up
                self.game:Initialize()
                self.view:CleanUpCards()
                self.view:UpdateRound(self.game.round, self.game.settings.round)
                self.view:UpdateParent(self.game.parent)
                self:RequestPhase(phase.setupRound)
            else
                self:RequestPhase(phase.gameFinished)
            end
        end,
        [phase.gameFinished] = function ()
            self:RequestPhase(phase.resultWait)
            self.view:ShowResult(self, self.game:GetGameWinner(), self.game.points)
        end,
        [phase.resultWait] = function ()
            -- waiting
        end,
        [phase.terminate] = function ()
            self:Exit(false)
        end,
    }
    --logger:trace("phase ".. tostring(self.phase) )
    if state[self.phase] then
        state[self.phase]()
    end
    -- after?
    self.view:OnEnterFrame(delta, timestamp)

    self:TransitPhase()
end

---debugging
---@param self KoiKoi.Service
function Service.DumpData(self)
    self.logger:debug("phase       = " .. tostring(self.phase))
    self.logger:debug("round       = " .. tostring(self.game.round))
    self.logger:debug("parent      = " .. tostring(self.game.parent))
    self.logger:debug("current     = " .. tostring(self.game.current))
    self.logger:debug("drawn       = " .. tostring(self.drawnCard))
    self.logger:debug("you         = %d:{%s}", table.size(self.game.pools[koi.player.you].hand), table.concat(self.game.pools[koi.player.you].hand, ", "))
    self.logger:debug("     bright = %d:{%s}", table.size(self.game.pools[koi.player.you][card.type.bright]), table.concat(self.game.pools[koi.player.you][card.type.bright], ", "))
    self.logger:debug("     animal = %d:{%s}", table.size(self.game.pools[koi.player.you][card.type.animal]), table.concat(self.game.pools[koi.player.you][card.type.animal], ", "))
    self.logger:debug("     ribbon = %d:{%s}", table.size(self.game.pools[koi.player.you][card.type.ribbon]), table.concat(self.game.pools[koi.player.you][card.type.ribbon], ", "))
    self.logger:debug("      chaff = %d:{%s}", table.size(self.game.pools[koi.player.you][card.type.chaff]), table.concat(self.game.pools[koi.player.you][card.type.chaff], ", "))
    self.logger:debug("opponent    = %d:{%s}", table.size(self.game.pools[koi.player.opponent].hand), table.concat(self.game.pools[koi.player.opponent].hand, ", "))
    self.logger:debug("     bright = %d:{%s}", table.size(self.game.pools[koi.player.opponent][card.type.bright]), table.concat(self.game.pools[koi.player.opponent][card.type.bright], ", "))
    self.logger:debug("     animal = %d:{%s}", table.size(self.game.pools[koi.player.opponent][card.type.animal]), table.concat(self.game.pools[koi.player.opponent][card.type.animal], ", "))
    self.logger:debug("     ribbon = %d:{%s}", table.size(self.game.pools[koi.player.opponent][card.type.ribbon]), table.concat(self.game.pools[koi.player.opponent][card.type.ribbon], ", "))
    self.logger:debug("      chaff = %d:{%s}", table.size(self.game.pools[koi.player.opponent][card.type.chaff]), table.concat(self.game.pools[koi.player.opponent][card.type.chaff], ", "))
    self.logger:debug("ground      = %d:{%s}", table.size(self.game.groundPool), table.concat(self.game.groundPool, ", "))
    self.logger:debug("deck        = %d:{%s}", table.size(self.game.deck), table.concat(self.game.deck, ", "))
    self.logger:debug("points      = {%s}", table.concat(self.game.points, ", "))
    self.logger:debug("calls       = {%s}", table.concat(self.game.calls, ", "))
end


---@param self KoiKoi.Service
function Service.Initialize(self)
    assert(self.phase == phase.new)
    self.logger:debug("Begin Koi-Koi")
    self.game:Initialize()
    self.view:Initialize(self)
    self.view:UpdateRound(self.game.round, self.game.settings.round)
    self.view:UpdateScorePoint(koi.player.you, self.game.points[koi.player.you])
    self.view:UpdateScorePoint(koi.player.opponent, self.game.points[koi.player.opponent])
    self:RequestPhase(self.skipDecidingParent and phase.decidedParent or phase.initialized )
end

---@param self KoiKoi.Service
function Service.Destory(self)
    self.view:Shutdown()
    self.logger:debug("Finished Koi-Koi")
end

---@param self KoiKoi.Service
---@param giveup boolean
---@return boolean
function Service.Exit(self, giveup)
    local winner = self.game:GetGameWinner()
    self.logger:debug("Exit Koi-Koi " .. tostring(winner))

    -- callback or event trigger?
    if self.onExit then
        local pp = self.game.points[koi.player.you]
        local op = self.game.points[koi.player.opponent]
        local conceding = giveup and (koi.player.you) or nil
        self.onExit({ winner = winner, playerPoint = pp, opponentPoint = op, conceding = conceding })
        return true
    end
    return false
end

---@param self KoiKoi.Service
---@param player KoiKoi.Player
---@return integer[]
function Service.GetPlayerHand(self, player)
    return self.game.pools[player].hand
end

---@param self KoiKoi.Service
---@param selectedCardId integer
function Service.NotifyDecideParent(self, selectedCardId)
    self.game:DecideParent(selectedCardId)
    self:RequestPhase(phase.decidedParent)
end

---@param self KoiKoi.Service
function Service.NotifyInformParent(self)
    self:RequestPhase(phase.setupRound)
end

---@param self KoiKoi.Service
function Service.NotifyDealedInitialCards(self)
    self:RequestPhase(phase.checkLuckyHands)
end

---@param self KoiKoi.Service
function Service.NotifyLuckyHands(self)
    self:RequestPhase(phase.roundFinished)
end

---@param self KoiKoi.Service
function Service.NotifyBeganTurn(self)
    self:RequestPhase(phase.matchCard)
end

---@param self KoiKoi.Service
function Service.NotifyFlipCard(self)
    self:RequestPhase(phase.matchCardFlipWait)
end

---@param self KoiKoi.Service
---@param drawn boolean
function Service.NotifyMatchedCards(self, drawn)
    -- match or draw
    local next = drawn and phase.checkCombo or phase.drawCard
    self:RequestPhase(next)
end

---@param self KoiKoi.Service
---@param drawn boolean
function Service.NotifyDiscardCard(self, drawn)
    -- match or draw
    local next = drawn and phase.checkCombo or phase.drawCard
    self:RequestPhase(next)
end

---@param self KoiKoi.Service
function Service.NotifyDrawCard(self)
    self:RequestPhase(phase.matchDrawCard)
end

---@param self KoiKoi.Service
function Service.NotifyComfirmCombo(self)
    self:RequestPhase(phase.calling)
end

---@param self KoiKoi.Service
function Service.NotifyKoiKoi(self)
    -- Including logic in notify is not a good idea.
    self.game:AddKoiKoiCount(self.game.current)
    self:RequestPhase(phase.endTurn)
end

---@param self KoiKoi.Service
function Service.NotifyShobu(self)
    self:RequestPhase(phase.win)
end

---@param self KoiKoi.Service
---@param calling KoiKoi.Calling
function Service.NotifyCalling(self, calling)
    if calling == koi.calling.koikoi then
        self:NotifyKoiKoi()
    elseif calling == koi.calling.shobu then
        self:NotifyShobu()
    end
end

---@param self KoiKoi.Service
function Service.NotifyRoundFinished(self)
    self:RequestPhase(phase.roundFinished)
end

---@param self KoiKoi.Service
function Service.NotifyTerminate(self)
    self:RequestPhase(phase.terminate)
end

return Service
