local koi = require("Hanafuda.KoiKoi.koikoi")
local card = require("Hanafuda.card")

---@class KoiKoi.Runner
---@field game KoiKoi.Game
---@field state integer
---@field round integer
---@field drawnCard integer?
---@field logger mwseLogger
local this = {}

---@param rule Config.KoiKoi
---@param brain1 KoiKoi.IBrain
---@param brain2 KoiKoi.IBrain
---@param logger mwseLogger
---@return KoiKoi.Runner
function this.new(rule, brain1, brain2, logger)
    --@type KoiKoi.Runner
    local instance = {
        game = require("Hanafuda.KoiKoi.game").new(
            rule,
            brain2, -- opponent
            brain1, -- player
            logger
        ),
        state = 0,
        round = 1,
        drawnCard = nil,
        logger = logger,
    }
    setmetatable(instance, { __index = this })
    return instance
end

---debugging
---@param self KoiKoi.Runner
function this.DumpData(self)
    self.logger:debug("state       = " .. tostring(self.state))
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


---@param self KoiKoi.Runner
---@param next integer?
function this.Next(self, next)
    if not next then
        next = self.state + 1
    end
    self.state = next
    return self.state
end

---@param self KoiKoi.Runner
function this.Reset(self)
    self.state = 0
    self.game:ResetPoints()
end

---@class KoiKoi.Runner.Stats
---@field winner KoiKoi.Player?
-- todo statics. brain, winner, turn, point, combo, koikoi count, etc...

---@param self KoiKoi.Runner
---@return KoiKoi.Runner.Stats
function this.GetStats(self)
    return {
        winner = self.game:GetGameWinner(),
    }
end

---@param self KoiKoi.Runner
function this.Run(self)
    local func = {
        [0] = function ()
            self.logger:debug("Run")
            self.game:Initialize()
            local choices = self.game:ChoiceDecidingParentCards(2)
            self.game:DecideParent(choices[1])
            self.game:DealInitialCards()

            while self.game:CheckUnluckyGround() do
                self.game:Initialize()
                self.game:DealInitialCards()
            end

            local accept, winner, lh, points = self.game:CheckLuckyHandsEach()
            if accept then
                if winner then -- not tie
                    -- No transition to win, so we settle here.
                    self.game:SetRoundWinnerByLuckyHands(winner, points[winner])
                    self:Next(99) -- win
                else
                    self:Next(100) -- no game
                end
            else
                self:Next()
            end
        end,
        [1] = function()
            local command = self.game:Simulate(self.game.current, nil, 1, 0)
            if command then
                -- todo com:Execute()
                if command.selectedCard and command.matchedCard then
                    -- match
                    if not koi.CanMatchSuit(command.selectedCard, command.matchedCard) then
                        self.logger:error("wrong matching %d %d", command.selectedCard, command.matchedCard)
                    end
                    self.game:Capture(self.game.current, command.selectedCard, false, false)

                    local many = self.game:CanCaptureExtra(command.selectedCard)
                    if many ~= nil then
                        for _, value in ipairs(many) do
                            self.game:Capture(self.game.current, value, true, false)
                        end
                    else
                        self.game:Capture(self.game.current, command.matchedCard, true, false)
                    end

                elseif command.selectedCard and not command.matchedCard then
                    -- discard
                    for _, cardId in ipairs(self.game.groundPool) do
                        if koi.CanMatchSuit(command.selectedCard, cardId) then
                            self.logger:error("wrong discarding %d, it can match %d", command.selectedCard, cardId)
                        end
                    end
                    self.game:Discard(self.game.current, command.selectedCard, false)
                else
                    -- skip
                    if table.size(self.game.pools[self.game.current].hand) > 0 then
                        self.logger:error("wrong command, must be choice card in hand")
                    end
                end
                self:Next()
            end
        end,
        [2] = function()
            -- state is optimizable
            self.drawnCard = card.DealCard(self.game.deck)
            self:Next()
        end,
        [3] = function()
            local command = self.game:Simulate(self.game.current, self.drawnCard, 1, 0)
            if command then
                -- todo com:Execute()
                if command.selectedCard and command.matchedCard then
                    -- match
                    if not koi.CanMatchSuit(command.selectedCard, command.matchedCard) then
                        self.logger:error("wrong matching %d %d", command.selectedCard, command.matchedCard)
                    end
                    self.game:Capture(self.game.current, command.selectedCard, false, true)

                    local many = self.game:CanCaptureExtra(command.selectedCard)
                    if many ~= nil then
                        for _, value in ipairs(many) do
                            self.game:Capture(self.game.current, value, true, true)
                        end
                    else
                        self.game:Capture(self.game.current, command.matchedCard, true, true)
                    end

                elseif command.selectedCard and not command.matchedCard then
                    -- discard
                    for _, cardId in ipairs(self.game.groundPool) do
                        if koi.CanMatchSuit(command.selectedCard, cardId) then
                            self.logger:error("wrong discarding %d, it can match %d", command.selectedCard, cardId)
                        end
                    end
                    self.game:Discard(self.game.current, command.selectedCard, true)
                else
                    -- skip
                    if self.drawnCard then
                        self.logger:error("wrong command, must be matching or discard %d", self.drawnCard)
                    else
                        self.logger:error("wrong drawnCard is nil")
                    end
                end
                self.drawnCard = nil
                local combo = self.game:CheckCombination(self.game.current)
                if combo then
                    self:Next()
                else
                    self:Next(5)
                end
            end
        end,
        [4] = function()
            local combo = self.game.combinations[self.game.current]
            if combo then
                local command = self.game:Call(self.game.current, self.game.combinations[self.game.current], 1, 0)
                if command then
                    if command.calling == koi.calling.koikoi then
                        -- continue
                        self:Next()
                    elseif command.calling == koi.calling.shobu then
                        -- finish
                        self:Next(99)
                    end
                end
            else
                -- no comb
                self.logger:error("wrong state")
                self:Next()
            end
        end,
        [5] = function()
            if self.game:CheckEnd() then
                self:Next(100)
            else
                self.game:SwapPlayer()
                self:Next(1)
            end
        end,
        [99] = function()
            -- self.game.current won
            -- add score
            -- round increment
            self.game:SetRoundWinner(self.game.current)
            self:Next()
        end,
        [100] = function()
            -- add score
            -- round increment
            -- next
            local winner = self.game:GetGameWinner()
            if winner then
                self.logger:debug("WIN %d", winner)
            else
                self.logger:debug("TIE")
            end
            self:Next()
        end,
    }
    if func[self.state] then
        func[self.state]()
        return true
    end
    self.logger:debug("Finished")
    return false
end

return this
