local config = require("Flin.config") ---@type FlinConfig
local lib = require("Flin.lib")
local log = lib.log

local AbstractState = require("Flin.states.abstractState")
local bb = require("Flin.blackboard")

---@class PlayerTurnState: AbstractState
---@field game FlinGame
local state = {}
setmetatable(state, { __index = AbstractState })

state.id_menu = tes3ui.registerID("flin:MenuHand")

---@param game FlinGame
---@return PlayerTurnState
function state:new(game)
    ---@type PlayerTurnState
    local newObj = {
        game = game
    }
    self.__index = self
    setmetatable(newObj, self)
    ---@cast newObj PlayerTurnState
    return newObj
end

---@param game FlinGame
---@return string
local function getHeaderText(game)
    if config.enableHints then
        return string.format("Play a card (Trump is %s, you have %s points, NPC has %s points)",
            lib.suitToString(game.trumpSuit), game:GetPlayerPoints(), game:GetNpcPoints())
    end

    return "Play a card"
end

-- Cancel button callback.
function state.onCancel(e)
    local menu = tes3ui.findMenu(state.id_menu)

    if (menu) then
        tes3ui.leaveMenuMode()
        menu:destroy()
    end
end

---@param game FlinGame
local function createWindow(game)
    -- Return if window is already open
    if (tes3ui.findMenu(state.id_menu) ~= nil) then
        return
    end

    -- Create window and frame
    local dragFrame = false
    local menu = tes3ui.createMenu { id = state.id_menu, dragFrame = dragFrame, fixedFrame = true }
    if dragFrame then
        menu.text = "Play a card"
    end
    menu.minHeight = 200
    menu.minWidth = 500
    -- To avoid low contrast, text input windows should not use menu transparency settings
    menu.alpha = 1.0

    -- Create layout
    local input_label = menu:createLabel { text = getHeaderText(game) }
    input_label.borderBottom = 5

    -- local block = menu:createBlock {}
    local block = menu:createThinBorder {}
    block.autoHeight = true
    block.autoWidth = true
    block.childAlignX = 0.5 -- centre content alignment

    block.flowDirection = tes3.flowDirection.leftToRight
    for i, card in ipairs(game.playerHand) do
        -- check if I am allowed to play this card
        local grayscale = false
        if not game:CanPlayCard(card) then
            log:debug("Player cannot play card %s", card:toString())
            grayscale = true
        end

        local imagePath = lib.GetCardIconName(card.suit, card.value, grayscale)
        if imagePath then
            local button = block:createImageButton({ idle = imagePath, over = imagePath, pressed = imagePath })
            if grayscale then
                button.disabled = true
            end

            -- hover tooltip
            button:register(tes3.uiEvent.mouseOver, function()
                local buttonText = string.format("%s of %s (%u)", lib.valueToString(card.value),
                    lib.suitToString(card.suit), card.value)
                local tooltip = tes3ui.createTooltipMenu()
                tooltip.autoHeight = true
                tooltip.autoWidth = true
                tooltip.wrapText = true
                local label = tooltip:createLabel { text = buttonText }
                label.autoHeight = true
                label.autoWidth = true
                label.wrapText = true
            end)

            -- click event
            button:register(tes3.uiEvent.mouseClick, function()
                game:PcPlayCard(card)

                event.unregister(tes3.event.activate, state.activateCallback)
                tes3ui.leaveMenuMode()
                menu:destroy()

                -- wait one second before updating
                timer.start({
                    duration = 1,
                    callback = function()
                        local nextState = game:evaluateTrick()

                        -- we wait a bit before the NPC can play to simulate thinking
                        if nextState == lib.GameState.NPC_TURN and
                            game.trickNPCSlot and not game.trickNPCSlot.card and
                            game.trickPCSlot and not game.trickPCSlot.card
                        then
                            timer.start({
                                duration = 1,
                                callback = function()
                                    game:PushState(nextState)
                                end
                            })
                        else
                            game:PushState(nextState)
                        end
                    end
                })
            end)
        end
    end

    local button_block = menu:createBlock {}
    button_block.widthProportional = 1.0 -- width is 100% parent width
    button_block.autoHeight = true
    button_block.childAlignX = 1.0       -- right content alignment
    button_block.childAlignX = 0.5
    button_block.paddingAllSides = 8

    -- call the game, only show if player has >= 66 points
    if game:GetPlayerPoints() >= 66 then
        local callButton = button_block:createButton({
            text = "Call the game",
            id = tes3ui.registerID("flin:callGame")
        })
        callButton:register("mouseClick", function()
            log:debug("Player calls the game")

            tes3ui.leaveMenuMode()
            menu:destroy()

            game:PushState(lib.GameState.GAME_END)
        end)
    end

    -- check if the player has marriages
    local marriageKing = game:CanDoMarriage(true)
    if marriageKing then
        local isRoyalMarriage = marriageKing.suit == game.trumpSuit
        local text = "Marriage"
        if isRoyalMarriage then
            text = "Royal Marriage"
        end

        local marriageButton = button_block:createButton({
            text = text,
            id = tes3ui.registerID("flin:playMarriages")
        })
        marriageButton:register("mouseClick", function()
            log:debug("Player calls a marriage")

            -- add points
            local points = 20
            if isRoyalMarriage then
                points = 40
            end
            game:AddPoints(points, true)

            game:PcPlayCard(marriageKing)

            event.unregister(tes3.event.activate, state.activateCallback)
            tes3ui.leaveMenuMode()
            menu:destroy()

            -- wait one second before updating
            timer.start({
                duration = 1,
                callback = function()
                    -- this is always the NPC
                    local nextState = game:evaluateTrick()
                    game:PushState(nextState)
                end
            })
        end)
    end



    local button_cancel = button_block:createButton { text = tes3.findGMST("sCancel").value }
    button_cancel:register(tes3.uiEvent.mouseClick, state.onCancel)

    -- Final setup
    menu:updateLayout()
    tes3ui.enterMenuMode(state.id_menu)
end

---@param game FlinGame
local function playerDrawCard(game)
    if #game.playerHand == 5 or game:IsPhase2() then
        log:debug("Player already drew a card")
        tes3.messageBox("You already drew a card")
        return
    end

    -- draw a card
    local card = game:drawCard(true)
    if not card then
        log:debug("Player cannot draw a card")
        tes3.messageBox("You cannot draw another card")
        return
    end

    local key = tes3.getKeyName(config.openkeybind.keyCode)
    tes3.messageBox("You draw: %s, press %s to play a card!", card:toString(), key)
end

--#region event callbacks

--- @param e keyDownEventData
local function KeyDownCallback(e)
    local game = bb.getInstance():getData("game") ---@type FlinGame

    if #game.playerHand == 5 or game:IsPhase2() then -- and not game:GetNpcTrickRef()
        createWindow(game)
    else
        tes3.messageBox("You must draw a card first")
    end
end

--- @param e activateEventData
function state.activateCallback(e)
    local game = bb.getInstance():getData("game") ---@type FlinGame
    if not game then
        return
    end

    -- exchange the trump card
    if not game:IsTalonEmpty() and game:GetTrumpCardRef() and e.target.id == game:GetTrumpCardRef().id and game:CanExchangeTrumpCard(true) then
        -- message box to confirm exchange
        tes3.messageBox({
            message = "Do you want to exchange the trump card?",
            buttons = { "Yes", "No" },
            showInDialog = false,
            callback = function(e2)
                if e2.button == 0 then
                    game:ExchangeTrumpCard(true)
                end
            end,
        })
    end

    if #game.playerHand == 5 or game:IsPhase2() then
        -- activate the trick
        if game:GetNpcTrickRef() and e.target.id == game:GetNpcTrickRef().id then
            -- head the trick
            createWindow(game)
            return
        end

        -- activate the talon
        if game:GetTalonRef() and e.target.id == game:GetTalonRef().id then
            tes3.messageBox("You cannot draw another card")
            return
        end
    else
        -- activate the talon
        if game:GetTalonRef() and e.target.id == game:GetTalonRef().id then
            playerDrawCard(game)
            return
            -- activate the trump card
        elseif game:IsTalonEmpty() and game:GetTrumpCardRef() and e.target.id == game:GetTrumpCardRef().id then
            -- if the talon is empty and there is a trump card then the player can draw the trump card
            playerDrawCard(game)
            return
        end

        -- activate the trick
        if game:GetNpcTrickRef() and e.target.id == game:GetNpcTrickRef().id then
            tes3.messageBox("You must draw a card first")
            return
        end
    end
end

--#endregion

function state:enterState()
    -- register event callbacks
    local game = self.game

    if #game.playerHand == 5 or game:IsPhase2() then
        if game:GetNpcTrickRef() then
            tes3.messageBox("It's your turn, head the trick!")
        else
            local key = tes3.getKeyName(config.openkeybind.keyCode)
            tes3.messageBox("It's your turn, press %s to play a card!", key)
        end
    else
        tes3.messageBox("It's your turn, draw a card from the talon!")
    end

    -- register event callbacks
    event.register(tes3.event.activate, self.activateCallback)
    event.register(tes3.event.keyDown, KeyDownCallback, { filter = config.openkeybind.keyCode })
    -- add game to blackboard for events
    bb.getInstance():setData("game", self.game)
    -- add check for player drew card to bb
end

function state:endState()
    -- NPC may draw a card if both players have played a card
    if self.game.trickNPCSlot and not self.game.trickNPCSlot.card and
        self.game.trickPCSlot and not self.game.trickPCSlot.card then
        self.game:drawCard(false)
    end

    -- unregister event callbacks
    event.unregister(tes3.event.activate, self.activateCallback)
    event.unregister(tes3.event.keyDown, KeyDownCallback, { filter = config.openkeybind.keyCode })
    -- remove game from blackboard
    bb.getInstance():removeData("game")
end

return state
