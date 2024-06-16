local lib = require("Flin.lib")
local log = lib.log

local AbstractState = require("Flin.states.abstractState")

---@class GameDealState: AbstractState
---@field game FlinGame
local state = {}
setmetatable(state, { __index = AbstractState })

---@param game FlinGame
---@return GameDealState
function state:new(game)
    ---@type GameDealState
    local newObj = {
        game = game
    }
    self.__index = self
    setmetatable(newObj, self)
    return newObj
end

function state:enterState()
    log:trace("Dealing cards")

    local game = self.game

    -- add the gold pot
    if game.pot == 1 then
        game.goldSlot:AddRefToSlot(lib.GOLD_01_ID)
    elseif game.pot < 10 then
        game.goldSlot:AddRefToSlot(lib.GOLD_05_ID)
    elseif game.pot < 25 then
        game.goldSlot:AddRefToSlot(lib.GOLD_10_ID)
    elseif game.pot < 100 then
        game.goldSlot:AddRefToSlot(lib.GOLD_25_ID)
    else
        game.goldSlot:AddRefToSlot(lib.GOLD_100_ID)
    end

    -- Code to deal cards to players
    -- first init the talon
    game:SetNewTalon()

    -- deal 3 cards to each player, remove them from the talon
    for i = 1, 3 do
        game:dealCardTo(true)
        game:dealCardTo(false)
    end

    -- the trump card is the next card in the talon
    local trumpCard = game:talonPop()
    if not trumpCard then
        log:error("No trump card")
        game:PushState(lib.GameState.INVALID)
        return
    end

    game.trumpCardSlot:AddCardToSlot(trumpCard)
    -- save the trump suit
    game.trumpSuit = trumpCard.suit
    log:debug("Trump suit: %s", lib.suitToString(game.trumpSuit))
    -- tes3.messageBox("Trump suit: %s", suitToString(trumpSuit))

    -- deal the rest of the cards to the players
    -- 2 cards to the player, 2 cards to the npc
    for i = 1, 2 do
        game:dealCardTo(true)
        game:dealCardTo(false)
    end

    -- game:DEBUG_printCards()

    -- determine at random who goes next
    local startPlayer = math.random(2)
    -- go to the next state, depending on who starts
    if startPlayer == 1 then
        log:debug("Player starts")

        self.game:PushState(lib.GameState.PLAYER_TURN)
    else
        log:debug("NPC starts")

        self.game:PushState(lib.GameState.NPC_TURN)
    end
end

function state:endState()

end

return state
