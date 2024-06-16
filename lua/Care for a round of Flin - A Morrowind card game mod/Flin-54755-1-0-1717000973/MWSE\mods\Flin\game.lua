local lib                   = require("Flin.lib")
local pathing               = require("Flin.pathing")
local Card                  = require("Flin.card")
local CardSlot              = require("Flin.cardSlot")
local bb                    = require("Flin.blackboard")
local config                = require("Flin.config") ---@type FlinConfig
local AiStrategy            = require("Flin.ai.strategy")

local log                   = lib.log
local ESuit                 = lib.ESuit
local EValue                = lib.EValue
local GameState             = lib.GameState

-- constants
local GAME_WARNING_DISTANCE = 300
local GAME_FORFEIT_DISTANCE = 400

---@class FlinNpcData
---@field npcHandle mwseSafeObjectHandle?
---@field npcOriginalPosition tes3vector3?
---@field npcOriginalFacing number?
---@field npcOriginalCell string?
---@field npcStrategy FlinNpcAi

---@class FlinGame
---@field private currentState GameState
---@field private state AbstractState?
---@field pot number
---@field npcData FlinNpcData?
---@field talon Card[]
---@field trumpSuit ESuit?
---@field playerHand Card[]
---@field npcHand Card[]
---@field talonSlot CardSlot?
---@field trumpCardSlot CardSlot?
---@field trickPCSlot CardSlot?
---@field trickNPCSlot CardSlot?
---@field goldSlot CardSlot?
---@field private wonCardsPc number
---@field private wonCardsNpc number
local FlinGame              = {}

-- constructor
---@param pot number
---@param npcHandle mwseSafeObjectHandle
---@return FlinGame
function FlinGame:new(pot, npcHandle)
    ---@type FlinGame
    local newObj = {
        currentState = GameState.INVALID,
        pot = pot,
        npcData = {
            npcHandle = npcHandle,
            npcStrategy = AiStrategy:new(npcHandle)
        },
        playerHand = {},
        npcHand = {},
        talon = {},
        wonCardsNpc = 0,
        wonCardsPc = 0
    }
    self.__index = self
    setmetatable(newObj, self)
    ---@cast newObj FlinGame
    return newObj
end

-- singleton instance
--- @return FlinGame?
function FlinGame.getInstance()
    return tes3.player.tempData.FlinGame
end

--#region methods

function FlinGame:AddPoints(points, isPlayer)
    if isPlayer then
        self.wonCardsPc = self.wonCardsPc + points
    else
        self.wonCardsNpc = self.wonCardsNpc + points
    end
end

---@return number
function FlinGame:GetPlayerPoints()
    return self.wonCardsPc
end

---@return number
function FlinGame:GetNpcPoints()
    return self.wonCardsNpc
end

function FlinGame:ShuffleTalon()
    for i = #self.talon, 2, -1 do
        local j = math.random(i)
        self.talon[i], self.talon[j] = self.talon[j], self.talon[i]
    end
end

function FlinGame:SetNewTalon()
    local talon = {}

    table.insert(talon, Card:new(ESuit.Hearts, EValue.Unter))
    table.insert(talon, Card:new(ESuit.Hearts, EValue.Ober))
    table.insert(talon, Card:new(ESuit.Hearts, EValue.King))
    table.insert(talon, Card:new(ESuit.Hearts, EValue.X))
    table.insert(talon, Card:new(ESuit.Hearts, EValue.Ace))

    table.insert(talon, Card:new(ESuit.Bells, EValue.Unter))
    table.insert(talon, Card:new(ESuit.Bells, EValue.Ober))
    table.insert(talon, Card:new(ESuit.Bells, EValue.King))
    table.insert(talon, Card:new(ESuit.Bells, EValue.X))
    table.insert(talon, Card:new(ESuit.Bells, EValue.Ace))

    table.insert(talon, Card:new(ESuit.Acorns, EValue.Unter))
    table.insert(talon, Card:new(ESuit.Acorns, EValue.Ober))
    table.insert(talon, Card:new(ESuit.Acorns, EValue.King))
    table.insert(talon, Card:new(ESuit.Acorns, EValue.X))
    table.insert(talon, Card:new(ESuit.Acorns, EValue.Ace))

    table.insert(talon, Card:new(ESuit.Leaves, EValue.Unter))
    table.insert(talon, Card:new(ESuit.Leaves, EValue.Ober))
    table.insert(talon, Card:new(ESuit.Leaves, EValue.King))
    table.insert(talon, Card:new(ESuit.Leaves, EValue.X))
    table.insert(talon, Card:new(ESuit.Leaves, EValue.Ace))

    self.talon = talon
    self:ShuffleTalon()
end

---@return Card?
function FlinGame:talonPop()
    if #self.talon == 0 then
        -- update slot
        local talonSlot = self.talonSlot
        if talonSlot and talonSlot.handle and talonSlot.handle:valid() then
            talonSlot.handle:getObject():delete()
            talonSlot.handle = nil
        end

        return nil
    end

    local card = self.talon[1]
    table.remove(self.talon, 1)

    -- update talon with correct number of cards
    local newRefName = lib.GetTalonRefForCardCount(#self.talon)
    if newRefName then
        local talonSlot = self.talonSlot
        if talonSlot then
            if talonSlot.handle and talonSlot.handle:valid() then
                talonSlot.handle:getObject():delete()
                talonSlot.handle = nil
            end
            local newRef = tes3.createReference({
                object = newRefName,
                position = talonSlot.position,
                orientation = talonSlot.orientation,
                cell = tes3.player.cell
            })
            talonSlot.handle = tes3.makeSafeObjectHandle(newRef)
        end
    end

    if #self.talon == 0 then
        -- update slot
        local talonSlot = self.talonSlot
        if talonSlot and talonSlot.handle and talonSlot.handle:valid() then
            talonSlot.handle:getObject():delete()
            talonSlot.handle = nil
        end
    end

    return card
end

---@param isPlayer boolean
---@return Card?
function FlinGame:CanDoMarriage(isPlayer)
    if isPlayer then
        -- need to go first
        if self.trickNPCSlot.card then
            return nil
        end

        -- check if the player holds the king and ober of the same suit
        for _, c in ipairs(self.playerHand) do
            if c.value == EValue.King then
                for _, c2 in ipairs(self.playerHand) do
                    if c2.value == EValue.Ober and c2.suit == c.suit then
                        return c
                    end
                end
            end
        end
    else
        -- need to go first
        if self.trickPCSlot.card then
            return nil
        end

        -- check if the NPC holds the king and ober of the same suit
        for _, c in ipairs(self.npcHand) do
            if c.value == EValue.King then
                for _, c2 in ipairs(self.npcHand) do
                    if c2.value == EValue.Ober and c2.suit == c.suit then
                        return c
                    end
                end
            end
        end
    end

    return nil
end

---@param isPlayer boolean
---@return boolean
function FlinGame:CanExchangeTrumpCard(isPlayer)
    if not self.trumpCardSlot then
        return false
    end
    if not self.trumpCardSlot.card then
        return false
    end

    if isPlayer then
        -- need to go first
        if self.trickNPCSlot.card then
            return false
        end

        -- check if the player has the trump unter
        for _, c in ipairs(self.playerHand) do
            if c.suit == self.trumpSuit and c.value == EValue.Unter then
                return true
            end
        end
    else
        -- need to go first
        if self.trickPCSlot.card then
            return false
        end

        -- check if the NPC has the trump unter
        for _, c in ipairs(self.npcHand) do
            if c.suit == self.trumpSuit and c.value == EValue.Unter then
                return true
            end
        end
    end

    return false
end

---@param isPlayer boolean
function FlinGame:ExchangeTrumpCard(isPlayer)
    if isPlayer then
        -- check if the player has the trump unter
        for i, c in ipairs(self.playerHand) do
            if c.suit == self.trumpSuit and c.value == EValue.Unter then
                -- remove the unter from the player's hand
                local unter = table.remove(self.playerHand, i)

                -- add the trump card to the player's hand
                table.insert(self.playerHand, self.trumpCardSlot:RemoveCardFromSlot())

                -- add the unter to the trump card slot
                self.trumpCardSlot:AddCardToSlot(unter)

                log:debug("Player exchanges trump card")

                return
            end
        end
    else
        -- check if the NPC has the trump unter
        for i, c in ipairs(self.npcHand) do
            if c.suit == self.trumpSuit and c.value == EValue.Unter then
                -- remove the unter from the NPC's hand
                local unter = table.remove(self.npcHand, i)

                -- add the trump card to the NPC's hand
                table.insert(self.npcHand, self.trumpCardSlot:RemoveCardFromSlot())

                -- add the unter to the trump card slot
                self.trumpCardSlot:AddCardToSlot(unter)

                log:debug("NPC exchanges trump card")

                return
            end
        end
    end
end

---@param card Card
---@return boolean
function FlinGame:CanPlayCard(card)
    if self:IsPhase2() and self.trickNPCSlot and self.trickNPCSlot.card then
        -- if we're in phase 2 and there is a trick to beat we are forced into "Farb und Stichzwang"
        local farbe = self.trickNPCSlot.card.suit
        local valueToBeat = self.trickNPCSlot.card.value

        -- first check if this card can beat the current trick
        if card.suit == farbe and card.value > valueToBeat then
            return true
        end

        -- if that fails then check if the player has any other card of the same suit that can win - then they must play it
        for _, c in ipairs(self.playerHand) do
            if c.suit == farbe and c.value > valueToBeat then --c ~= card and
                if c == card then
                    return true
                end
                return false
            end
        end

        -- if that also fails then check if the player has any card of the same suit - then they must play it
        for _, c in ipairs(self.playerHand) do
            if c.suit == farbe then
                if c == card then
                    return true
                end
                return false
            end
        end

        -- if that fails then check if the player has any trump card that can win - then they must play it
        for _, c in ipairs(self.playerHand) do
            if c.suit == self.trumpSuit then
                if c == card then
                    return true
                end
                return false
            end
        end

        -- if that also fails then I can play any card
        return true
    else
        return true
    end
end

---@param card Card
function FlinGame:PcPlayCard(card)
    for i, c in ipairs(self.playerHand) do
        if c == card then
            local result = table.remove(self.playerHand, i)
            self.trickPCSlot:AddCardToSlot(result)

            log:debug("PC plays card: %s", result:toString())

            -- adjust the position of the slot
            -- if the trickNPCSlot is not empty then move the trickNCSlot up
            if self.trickNPCSlot and self.trickNPCSlot.card then
                self.trickPCSlot:MoveUp(0.5)
            end

            return
        end
    end
end

---@param card Card
function FlinGame:NpcPlayCard(card)
    for i, c in ipairs(self.npcHand) do
        if c == card then
            local result = table.remove(self.npcHand, i)
            self.trickNPCSlot:AddCardToSlot(result)

            log:debug("NPC plays card: %s", result:toString())

            -- adjust the position of the slot
            -- if the trickPCSlot is not empty then move the trickNPCSlot up
            if self.trickPCSlot and self.trickPCSlot.card then
                self.trickNPCSlot:MoveUp(0.5)
            end

            return
        end
    end
end

---@return boolean
function FlinGame:IsTalonEmpty()
    return #self.talon == 0
end

---@return boolean
function FlinGame:IsPhase2()
    local hasTrumpCard = self.trumpCardSlot and self.trumpCardSlot.card
    return self:IsTalonEmpty() and not hasTrumpCard
end

---@return tes3reference?
function FlinGame:GetNpcTrickRef()
    -- get the id of the trick activator
    local trickNPCSlot = self.trickNPCSlot
    if trickNPCSlot and trickNPCSlot.handle and trickNPCSlot.handle:valid() then
        return trickNPCSlot.handle:getObject()
    end

    return nil
end

---@return tes3reference?
function FlinGame:GetTrumpCardRef()
    -- get the id of the trump card activator
    local trumpCardSlot = self.trumpCardSlot
    if trumpCardSlot and trumpCardSlot.handle and trumpCardSlot.handle:valid() then
        return trumpCardSlot.handle:getObject()
    end

    return nil
end

---@return tes3reference?
function FlinGame:GetTalonRef()
    -- get the id of the talon activator
    local talonSlot = self.talonSlot
    if talonSlot and talonSlot.handle and talonSlot.handle:valid() then
        return talonSlot.handle:getObject()
    end
    return nil
end

---@param isPlayer boolean
function FlinGame:dealCardTo(isPlayer)
    if isPlayer then
        table.insert(self.playerHand, self:talonPop())
    else
        table.insert(self.npcHand, self:talonPop())
    end
end

function FlinGame:DEBUG_printCards()
    log:trace("============")
    log:trace("player hand:")
    for i, c in ipairs(self.playerHand) do
        log:trace("\t%s", c:toString())
    end
    log:trace("npc hand:")
    for i, c in ipairs(self.npcHand) do
        log:trace("\t%s", c:toString())
    end
    log:trace("talon:")
    for i, c in ipairs(self.talon) do
        log:trace("\t%s", c:toString())
    end
    log:trace("trick pc:")
    if self.trickPCSlot and self.trickPCSlot.card then
        log:trace("\t%s", self.trickPCSlot.card:toString())
    end
    log:trace("trick npc:")
    if self.trickNPCSlot and self.trickNPCSlot.card then
        log:trace("\t%s", self.trickNPCSlot.card:toString())
    end
    log:trace("============")
end

---@return Card?
function FlinGame:drawCard(isPlayer)
    -- only draw a card if the hand is less than 5 cards
    if isPlayer and #self.playerHand >= 5 then
        return nil
    end

    if not isPlayer and #self.npcHand >= 5 then
        return nil
    end

    local card = self:talonPop()

    -- if the talon is empty then the trump card is the last card in the talon
    if not card and self.trumpCardSlot and self.trumpCardSlot.card then
        log:debug("No more cards in the talon")
        tes3.messageBox("No more cards in the talon")
        card = self.trumpCardSlot:RemoveCardFromSlot()
    end

    if not card then
        log:debug("No more cards in the talon")
        return nil
    end

    if isPlayer then
        log:debug("player draws card: %s (total %s)", card:toString(), #self.playerHand + 1)

        table.insert(self.playerHand, card)
    else
        log:debug("NPC draws card: %s (total %s)", card:toString(), #self.npcHand + 1)
        table.insert(self.npcHand, card)
    end


    -- sounds for picking up a card
    -- Menu Size
    -- scroll
    -- Item Misc Down

    -- play a sound
    tes3.playSound({
        sound = "Menu Size",
        reference = tes3.player
    })


    return card
end

---@return GameState
function FlinGame:evaluateTrick()
    log:trace("evaluate")

    local trickPCSlot = self.trickPCSlot
    local trickNPCSlot = self.trickNPCSlot
    local trumpSuit = self.trumpSuit

    if not trickPCSlot then
        return GameState.INVALID
    end
    if not trickNPCSlot then
        return GameState.INVALID
    end


    -- Code to evaluate the trick

    -- if the player has played and the NPC has not then it is the NPC's turn
    if trickPCSlot.card and not trickNPCSlot.card then
        log:debug("Player has played a card, NPC has not")
        return GameState.NPC_TURN
    end

    -- if the NPC has played and the player has not then it is the player's turn
    if trickNPCSlot.card and not trickPCSlot.card then
        log:debug("NPC has played a card, player has not")
        return GameState.PLAYER_TURN
    end

    -- evaluate the trick if both players have played a card
    if trickPCSlot.card and trickNPCSlot.card then
        log:debug("Both players have played a card")

        -- the winner of the trick goes next
        -- evaluate the trick
        local playerWins = false
        -- if the player has played a trump card and the NPC has not then the player wins
        if trickPCSlot.card.suit == trumpSuit and trickNPCSlot.card.suit ~= trumpSuit then
            playerWins = true
            -- if the NPC has played a trump card and the player has not then the NPC wins
        elseif trickNPCSlot.card.suit == trumpSuit and trickPCSlot.card.suit ~= trumpSuit then
            playerWins = false
            -- if both players have played a trump card then the higher value wins
        elseif trickPCSlot.card.suit == trumpSuit and trickNPCSlot.card.suit == trumpSuit then
            if trickPCSlot.card.value > trickNPCSlot.card.value then
                playerWins = true
            else
                playerWins = false
            end
            -- if both players have played a card of the same suit then the higher value wins
        elseif trickPCSlot.card.suit == trickNPCSlot.card.suit then
            if trickPCSlot.card.value > trickNPCSlot.card.value then
                playerWins = true
            else
                playerWins = false
            end
        else
            -- the suits don't match so the current player loses as they went last
            if self.currentState == GameState.PLAYER_TURN then
                playerWins = false
            elseif self.currentState == GameState.NPC_TURN then
                playerWins = true
            end
        end


        -- add the value of the trick to the winner's points
        if playerWins then
            log:debug("> Player wins the trick (%s > %s)", trickPCSlot.card:toString(),
                trickNPCSlot.card:toString())
            if config.enableMessages then
                tes3.messageBox("You won the trick (%s > %s)", trickPCSlot.card:toString(),
                    trickNPCSlot.card:toString())
            end

            -- move the cards to the player's won cards
            self.wonCardsPc = self.wonCardsPc + trickPCSlot:RemoveCardFromSlot().value
            self.wonCardsPc = self.wonCardsPc + trickNPCSlot:RemoveCardFromSlot().value
        else
            log:debug("> NPC wins the trick (%s > %s)", trickNPCSlot.card:toString(),
                trickPCSlot.card:toString())
            if config.enableMessages then
                tes3.messageBox("NPC won the trick (%s > %s)", trickNPCSlot.card:toString(),
                    trickPCSlot.card:toString())
            end

            -- move the cards to the NPC's won cards
            self.wonCardsNpc = self.wonCardsNpc + trickPCSlot:RemoveCardFromSlot().value
            self.wonCardsNpc = self.wonCardsNpc + trickNPCSlot:RemoveCardFromSlot().value
        end


        log:debug("\tPlayer points: %s, NPC points: %s", self:GetPlayerPoints(), self:GetNpcPoints())

        -- check if the game has ended
        if #self.playerHand == 0 and #self.npcHand == 0 then
            return GameState.GAME_END
        end

        -- determine who goes next
        -- sounds
        -- enchant fail
        -- enchant success
        if playerWins then
            -- play a sound
            if config.enableTrickSounds then
                tes3.playSound({
                    sound = "enchant success",
                    reference = tes3.player
                })
            end

            return GameState.PLAYER_TURN
        else
            -- play a sound
            if config.enableTrickSounds then
                tes3.playSound({
                    sound = "enchant fail",
                    reference = tes3.player
                })
            end
            return GameState.NPC_TURN
        end
    end

    -- if neither player has played a card then the game is in an invalid state
    log:error("Invalid state")
    return GameState.INVALID
end

--#endregion

--#region statemachine

-- only certain transitions are allowed
local transitions = {
    [GameState.SETUP] = {
        [GameState.DEAL] = true,
        [GameState.INVALID] = true
    },
    [GameState.DEAL] = {
        [GameState.PLAYER_TURN] = true,
        [GameState.NPC_TURN] = true,
        [GameState.INVALID] = true
    },
    [GameState.PLAYER_TURN] = {
        [GameState.PLAYER_TURN] = true,
        [GameState.NPC_TURN] = true,
        [GameState.GAME_END] = true,
        [GameState.INVALID] = true
    },
    [GameState.NPC_TURN] = {
        [GameState.PLAYER_TURN] = true,
        [GameState.NPC_TURN] = true,
        [GameState.GAME_END] = true,
        [GameState.INVALID] = true
    },
    [GameState.GAME_END] = {
        [GameState.INVALID] = true
    },
    [GameState.INVALID] = {
        [GameState.SETUP] = true
    }
}

---@param nextState GameState
function FlinGame:PushState(nextState)
    log:trace("PushState: %s -> %s", lib.stateToString(self.currentState), lib.stateToString(nextState))

    -- check if the transition is allowed
    if not transitions[self.currentState][nextState] then
        log:error("Invalid state transition: %s -> %s", lib.stateToString(self.currentState),
            lib.stateToString(nextState))
        return
    end

    self:ExitState()
    self:EnterState(nextState)
end

---@private
function FlinGame:ExitState()
    log:trace("ExitState: %s", lib.stateToString(self.currentState))
    if self.state then
        self.state:endState()
    end
end

---@private
---@param state GameState
function FlinGame:EnterState(state)
    log:trace("EnterState: %s", lib.stateToString(state))

    if state == GameState.SETUP then
        local setupState = require("Flin.states.gameSetup")
        self.state = setupState:new(self)
    elseif state == GameState.DEAL then
        local dealState = require("Flin.states.gameDeal")
        self.state = dealState:new(self)
    elseif state == GameState.PLAYER_TURN then
        local playerTurnState = require("Flin.states.playerTurn")
        self.state = playerTurnState:new(self)
    elseif state == GameState.NPC_TURN then
        local npcTurnState = require("Flin.states.npcTurn")
        self.state = npcTurnState:new(self)
    elseif state == GameState.GAME_END then
        local gameEndState = require("Flin.states.gameEnd")
        self.state = gameEndState:new(self)
    elseif state == GameState.INVALID then
        log:error("Invalid state: Cleaning up")
        self:cleanup()
        return
    end

    self.currentState = state
    self.state:enterState()
end

--#endregion

--#region event callbacks

-- prevent saving while in game
--- @param e saveEventData
local function saveCallback(e)
    tes3.messageBox("You cannot save during a game.")
    return false
end

--- this runs during the whole game
--- @param e simulateEventData
local function simulateCallback(e)
    local game = bb.getInstance():getData("game") ---@type FlinGame

    if not game then
        return
    end
    if not game.talonSlot then
        return
    end

    -- if I leave the interior cell of the npc, I lose the game
    if not game.npcData.npcHandle then
        return
    end
    local currentCell = tes3.player.cell
    local referenceCell = game.npcData.npcHandle:getObject().cell
    if currentCell ~= referenceCell and referenceCell.isInterior then
        -- forfeit the game
        log:warn("You lose the game")
        tes3.messageBox("You lose the game")
        game.endGame(false)
        return
    end

    local gameWarned = bb.getInstance():getData("gameWarned")
    if gameWarned then
        -- calculate the distance between the NPC and the player
        local distance = game.talonSlot.position:distance(tes3.player.position)
        if distance > GAME_FORFEIT_DISTANCE then
            -- forfeit the game
            log:warn("You lose the game")
            tes3.messageBox("You lose the game")
            game.endGame(false)
        end
    else
        -- calculate the distance between the NPC and the player
        local distance = game.talonSlot.position:distance(tes3.player.position)
        if distance > GAME_WARNING_DISTANCE then
            -- warn the player
            tes3.messageBox("You are too far away to continue the game, you will forfeit if you move further away")
            bb.getInstance():setData("gameWarned", true)
        end
    end
end

--- @param e uiObjectTooltipEventData
local function uiObjectTooltipCallback(e)
    local game = bb.getInstance():getData("game") ---@type FlinGame
    if not game then
        return
    end

    -- we want to change the tooltip of the gold slot
    local name = nil
    if game.goldSlot.handle and game.goldSlot.handle:valid() and e.reference == game.goldSlot.handle:getObject() then
        name = string.format("Gold pot: %s", game.pot)
    elseif game.trumpCardSlot.card and game.trumpCardSlot.handle and game.trumpCardSlot.handle:valid() and e.reference == game.trumpCardSlot.handle:getObject() then
        -- change the name of the trump card to include "trump"
        name = string.format("Trump: %s", game.trumpCardSlot.card:toString())
    elseif game.talonSlot.handle and game.talonSlot.handle:valid() and e.reference == game.talonSlot.handle:getObject() then
        -- change the name of the talon to include "talon" and the number of cards
        name = string.format("Talon: %s", #game.talon)
    end

    if name then
        local label = e.tooltip:findChild("HelpMenu_name")
        if label then
            label.text = name
        end
    end
end

--- @param e activateEventData
local function activateCallback(e)
    local game = bb.getInstance():getData("game") ---@type FlinGame
    if not game then
        return
    end

    if game.goldSlot.handle and game.goldSlot.handle:valid() and e.target == game.goldSlot.handle:getObject() then
        -- block picking up
        log:debug("Block activate on %s", e.target.object.id)
        e.claim = true
        return false
    end
end

--#endregion

--- @param deckRef tes3reference
function FlinGame:startGame(deckRef)
    log:info("The game is on! The pot is %s gold", self.pot)
    --tes3.messageBox("The game is on! The pot is %s gold", self.pot)

    -- register event callbacks
    event.register(tes3.event.save, saveCallback)
    event.register(tes3.event.simulate, simulateCallback)
    event.register(tes3.event.activate, activateCallback)
    event.register(tes3.event.uiObjectTooltip, uiObjectTooltipCallback)
    -- add game to blackboard for events
    bb.getInstance():setData("game", self)

    local zOffsetTrump = 0
    local deckPos = deckRef.position:copy()
    local deckOrientation = deckRef.orientation:copy()
    local deckWorldTransform = deckRef.sceneNode.worldTransform:copy()

    -- store positions: deck, trump, trickPC, trickNPC
    -- 1. talon slot is the deck
    self.talonSlot = CardSlot:new(deckPos, deckOrientation)
    self.talonSlot.handle = tes3.makeSafeObjectHandle(deckRef)

    -- 2. trump slot is under the talon and rotated
    -- rotate by 90 degrees around the z axis
    log:trace("placing trump slot")
    local rotation = tes3matrix33.new()
    rotation:fromEulerXYZ(deckOrientation.x, deckOrientation.y, deckOrientation.z)
    rotation = rotation * tes3matrix33.new(
        0, 1, 0,
        -1, 0, 0,
        0, 0, 1
    )
    local trumpOrientation = rotation:toEulerXYZ()
    -- move it a bit along the orientation
    local trumpPosition = (deckWorldTransform * tes3vector3.new(0, -4, zOffsetTrump))
    self.trumpCardSlot = CardSlot:new(trumpPosition, trumpOrientation)

    -- 3. trick slots are off to the side
    log:trace("placing trick slot 1")
    local trickOrientation = deckOrientation
    local trickPosition = (deckWorldTransform * tes3vector3.new(10, 0, zOffsetTrump))
    self.trickPCSlot = CardSlot:new(trickPosition, trickOrientation)

    -- 4. rotate by 45 degrees around the z axis
    log:trace("placing trick slot 2")
    local angle_rad = math.rad(45)
    rotation = tes3matrix33.new(
        math.cos(angle_rad), -math.sin(angle_rad), 0,
        math.sin(angle_rad), math.cos(angle_rad), 0,
        0, 0, 1
    )
    local trick2orientation = rotation:toEulerXYZ()
    self.trickNPCSlot = CardSlot:new(trickPosition, trick2orientation)

    -- 5. add gold pot slot
    log:trace("placing gold slot")
    local goldSlotPos = (deckWorldTransform * tes3vector3.new(0, 10, zOffsetTrump))
    local goldSlotOrientation = deckOrientation
    self.goldSlot = CardSlot:new(goldSlotPos, goldSlotOrientation)

    -- 6. add NPC handle
    -- find a spot for the npc
    local position = self.npcData.npcHandle:getObject().position:copy()
    local refBelow = lib.FindRefBelow(deckRef)
    if refBelow then
        local refName = string.lower(refBelow.object.id)
        if string.find(refName, "table") or
            string.find(refName, "crate") or
            string.find(refName, "bar") or
            string.find(refName, "barrel") then
            log:debug("Found a spot for the NPC at %s", refBelow.object.id)
            position = lib.findPlayerPosition(refBelow)
        else
            log:warn("Not a table")
        end
    else
        log:warn("Could not find a spot for the NPC")
    end

    -- move NPC to that location
    log:debug("Start pathing")
    self.npcData.npcOriginalPosition = self.npcData.npcHandle:getObject().position:copy()
    self.npcData.npcOriginalFacing = self.npcData.npcHandle:getObject().facing
    self.npcData.npcOriginalCell = self.npcData.npcHandle:getObject().cell.id

    pathing.registerCallback("onPathingFinished", function(timer, npcData)
        log:debug("NPC has arrived at the table")
        local reference = npcData.npcHandle:getObject()
        -- make the npc face the deckRef
        -- get the vector between the npc and the deck
        local direction = deckPos - reference.position
        direction.z = 0
        direction = direction:normalized()
        local facing = math.atan2(direction.x, direction.y)
        reference.facing = facing

        -- Set the AI to stand in place
        tes3.setAIWander({ reference = reference, idles = { 0, 0, 0, 0, 0, 0, 0, 0 } })
    end)

    pathing.startPathing({
        data = self.npcData,
        destination = position,
        onFinish = "onPathingFinished",
        resetAi = false
    })
end

local function onReturnFinished(timer, npcData)
    log:debug("NPC has arrived back at their position")

    tes3.positionCell({
        reference = npcData.npcHandle:getObject(),
        position = npcData.npcOriginalPosition,
        cell =
            npcData.npcOriginalCell
    })
    npcData.npcHandle:getObject().facing = npcData.npcOriginalFacing
end

---@param isSetup boolean
function FlinGame.endGame(isSetup)
    log:info("Game is over: %s", isSetup and "setup" or "forfeit")

    -- call exit of the current state
    local game = tes3.player.tempData.FlinGame
    game:ExitState()

    -- remove event callbacks
    event.unregister(tes3.event.save, saveCallback)
    event.unregister(tes3.event.simulate, simulateCallback)
    event.unregister(tes3.event.activate, activateCallback)
    event.unregister(tes3.event.uiObjectTooltip, uiObjectTooltipCallback)

    if isSetup then
        tes3.addItem({ reference = game.npcData.npcHandle:getObject(), item = "Gold_001", count = game.pot })
    else
        -- give back the deck
        tes3.addItem({ reference = tes3.player, item = lib.FLIN_DECK_ID, count = 1 })
    end

    -- move the NPC back
    if game.npcData and game.npcData.npcOriginalPosition then
        pathing.registerCallback("onReturnFinished", onReturnFinished)

        pathing.startPathing({
            data = game.npcData,
            destination = game.npcData.npcOriginalPosition,
            onFinish = "onReturnFinished",
            resetAi = true
        })
    end

    -- cleanup
    tes3.player.tempData.FlinGame:cleanup()
end

---@param slot CardSlot?
local function CleanupSlot(slot)
    if slot then
        slot:RemoveCardFromSlot()
        slot = nil
    end
end

function FlinGame:cleanup()
    log:trace("Cleaning up")

    self.currentState = GameState.INVALID
    self.pot = 0
    self.talon = {}
    self.trumpSuit = nil
    self.playerHand = {}
    self.npcHand = {}
    self.wonCardsPc = 0
    self.wonCardsNpc = 0

    -- cleanup handles and references
    self.npcData = nil

    CleanupSlot(self.talonSlot)
    CleanupSlot(self.trumpCardSlot)
    CleanupSlot(self.trickPCSlot)
    CleanupSlot(self.trickNPCSlot)
    CleanupSlot(self.goldSlot)

    -- remove event callbacks
    event.unregister(tes3.event.save, saveCallback)
    event.unregister(tes3.event.simulate, simulateCallback)
    event.unregister(tes3.event.activate, activateCallback)
    event.unregister(tes3.event.uiObjectTooltip, uiObjectTooltipCallback)
    -- remove game from blackboard
    bb.getInstance():removeData("game")
    bb.getInstance():removeData("setupWarned")
    bb.getInstance():clean()

    tes3.player.tempData.FlinGame = nil
end

return FlinGame
