local lib = require("Flin.lib")
local log = lib.log

local AbstractState = require("Flin.states.abstractState")

---@class GameEndState: AbstractState
---@field game FlinGame
local state = {}
setmetatable(state, { __index = AbstractState })

---@param game FlinGame
---@return GameEndState
function state:new(game)
    ---@type GameEndState
    local newObj = {
        game = game
    }
    self.__index = self
    setmetatable(newObj, self)
    ---@cast newObj GameEndState
    return newObj
end

function state:enterState()
    -- Code for ending the game
    log:debug("Game ended")

    local game = self.game

    -- calculate the points
    local playerPoints = game:GetPlayerPoints()
    local npcPoints = game:GetNpcPoints()

    log:debug("Player points: %s, NPC points: %s", playerPoints, npcPoints)
    log:debug("Pot: %s", game.pot)

    -- determine the winner
    if playerPoints >= 66 then
        log:debug("Player wins")
        tes3.messageBox("You won the game and the pot of %s gold", game.pot)

        -- give the player the pot
        tes3.addItem({ reference = tes3.player, item = "Gold_001", count = game.pot })
        tes3.playSound({ sound = "Item Gold Up" })
    elseif npcPoints >= 66 then
        log:debug("NPC wins")
        tes3.messageBox("You lose!")

        -- give NPC the pot
        tes3.addItem({ reference = game.npcData.npcHandle:getObject(), item = "Gold_001", count = game.pot })
    else
        log:debug("It's a draw")
        tes3.messageBox("It's a draw!")

        -- give the player half the pot
        tes3.addItem({ reference = tes3.player, item = "Gold_001", count = math.floor(game.pot / 2) })
        tes3.playSound({ sound = "Item Gold Up" })

        -- give NPC half the pot
        tes3.addItem({ reference = game.npcData.npcHandle:getObject(), item = "Gold_001", count = math.floor(game.pot / 2) })
    end

    game.endGame(false)
end

function state:endState()

end

return state
