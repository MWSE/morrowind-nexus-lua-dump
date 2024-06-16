local lib = require("Flin.lib")
local log = lib.log

local AbstractState = require("Flin.states.abstractState")
local bb = require("Flin.blackboard")

---@class GameSetupState: AbstractState
---@field game FlinGame
local state = {}
setmetatable(state, { __index = AbstractState })

local SETUP_WARNING_DISTANCE = 300
local SETUP_FORFEIT_DISTANCE = 400

---@param game FlinGame
---@return GameSetupState
function state:new(game)
    ---@type GameSetupState
    local newObj = {
        game = game
    }
    self.__index = self
    setmetatable(newObj, self)
    ---@cast newObj GameSetupState
    return newObj
end

--#region event callbacks

--- @param e activateEventData
local function ActivateCallback(e)
    log:debug("ActivateCallback")

    if e.target and e.target.object.id == lib.FLIN_DECK_ID then
        local game = bb.getInstance():getData("game") ---@type FlinGame

        -- delete the old deck
        e.target:delete()

        -- create the new deck
        local zOffsetTalon = 2

        local deckRef = tes3.createReference({
            object = lib.FLIN_TALON_20,
            position = e.target.position + tes3vector3.new(0, 0, zOffsetTalon),
            orientation = e.target.orientation,
            cell = tes3.player.cell
        })

        game:startGame(deckRef)
        game:PushState(lib.GameState.DEAL)

        -- do not continue to pick up the old deck
        e.claim = true
        return false
    end
end

--- @param e simulateEventData
local function SimulateCallback(e)
    local game = bb.getInstance():getData("game") ---@type FlinGame

    if not game.npcData then
        return
    end
    if not game.npcData.npcHandle then
        return
    end
    if not game.npcData.npcHandle:valid() then
        return
    end

    -- if I leave the interior cell of the npc, I lose the game
    local currentCell = tes3.player.cell
    local referenceCell = game.npcData.npcHandle:getObject().cell
    if currentCell ~= referenceCell and referenceCell.isInterior then
        -- unregister event callbacks
        event.unregister(tes3.event.activate, ActivateCallback)
        event.unregister(tes3.event.simulate, SimulateCallback)

        -- forfeit the game
        tes3.messageBox("You lose the game")
        game.endGame(true)
        return
    end

    local setupWarned = bb.getInstance():getData("setupWarned")
    if setupWarned then
        -- calculate the distance between the NPC and the player
        local npcLocation = game.npcData.npcHandle:getObject().position
        local distance = npcLocation:distance(tes3.player.position)
        if distance > SETUP_FORFEIT_DISTANCE then
            -- unregister event callbacks
            event.unregister(tes3.event.activate, ActivateCallback)
            event.unregister(tes3.event.simulate, SimulateCallback)

            -- warn the player and forfeit the game
            tes3.messageBox("You lose the game")
            game.endGame(true)
        end
    else
        -- calculate the distance between the NPC and the player
        local npcLocation = game.npcData.npcHandle:getObject().position
        local distance = npcLocation:distance(tes3.player.position)
        if distance > SETUP_WARNING_DISTANCE then
            -- warn the player
            tes3.messageBox("You are too far away to continue the game, you will forfeit if you move further away")
            bb.getInstance():setData("setupWarned", true)
        end
    end
end

--#endregion

function state:enterState()
    log:info("Setup game with gold: %s", self.game.pot)
    log:info("Setup game with NPC: %s", self.game.npcData.npcHandle)

    tes3.messageBox("Place the deck somewhere and and activate it to start the game")

    -- add game to blackboard for events
    bb.getInstance():setData("game", self.game)

    -- register event callbacks
    event.register(tes3.event.activate, ActivateCallback)
    event.register(tes3.event.simulate, SimulateCallback)
end

function state:endState()
    -- unregister event callbacks
    event.unregister(tes3.event.activate, ActivateCallback)
    event.unregister(tes3.event.simulate, SimulateCallback)
    -- remove game from blackboard
    bb.getInstance():removeData("game")
    bb.getInstance():removeData("setupWarned")
end

return state
