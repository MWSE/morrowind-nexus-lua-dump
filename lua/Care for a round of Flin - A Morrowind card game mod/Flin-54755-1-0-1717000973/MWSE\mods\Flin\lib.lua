local logger = require("logging.logger")
local config = require("Flin.config") ---@type FlinConfig

local this   = {}


this.FLIN_DECK_ID  = "flin_deck_20"
this.FLIN_TALON_20 = "a_flin_deck_20_r"
this.FLIN_TALON_9  = "a_flin_deck_9_r"
this.FLIN_TALON_8  = "a_flin_deck_8_r"
this.FLIN_TALON_7  = "a_flin_deck_7_r"
this.FLIN_TALON_6  = "a_flin_deck_6_r"
this.FLIN_TALON_5  = "a_flin_deck_5_r"
this.FLIN_TALON_4  = "a_flin_deck_4_r"
this.FLIN_TALON_3  = "a_flin_deck_3_r"
this.FLIN_TALON_2  = "a_flin_deck_2_r"
this.FLIN_TALON_1  = "a_flin_deck_1_r"

this.GOLD_01_ID    = "Gold_001"
this.GOLD_05_ID    = "Gold_005"
this.GOLD_10_ID    = "Gold_010"
this.GOLD_25_ID    = "Gold_025"
this.GOLD_100_ID   = "Gold_100"


this.log = logger.new {
    name = "Flin",
    logLevel = config.logLevel,
    logToConsole = false,
    includeTimestamp = false
}


---@enum ESuit
this.ESuit = {
    Hearts = 1,
    Bells = 2,
    Acorns = 3,
    Leaves = 4
}

---@param suit ESuit
---@return string
function this.suitToString(suit)
    if suit == this.ESuit.Hearts then
        return "Hearts"
    elseif suit == this.ESuit.Bells then
        return "Bells"
    elseif suit == this.ESuit.Acorns then
        return "Acorns"
    elseif suit == this.ESuit.Leaves then
        return "Leaves"
    end
    return "Unknown"
end

---@enum EValue
this.EValue = {
    Unter = 2,
    Ober = 3,
    King = 4,
    X = 10,
    Ace = 11,
}

-- TODO english names
---@param value EValue
---@return string
function this.valueToString(value)
    if value == this.EValue.Unter then
        return "Unter"
    elseif value == this.EValue.Ober then
        return "Ober"
    elseif value == this.EValue.King then
        return "King"
    elseif value == this.EValue.X then
        return "X"
    elseif value == this.EValue.Ace then
        return "Ace"
    end
    return "Unknown"
end

---@param suit ESuit
---@param value EValue
---@return string?
function this.GetCardMiscItemName(suit, value)
    local suitName = this.suitToString(suit):lower()
    if suitName == "unknown" then
        return nil
    end

    local valueName = this.valueToString(value):lower()
    if valueName == "unknown" then
        return nil
    end

    return string.format("card_%s_%s", suitName, valueName)
end

---@param suit ESuit
---@param value EValue
---@return string?
function this.GetCardActivatorName(suit, value)
    local suitName = this.suitToString(suit):lower()
    if suitName == "unknown" then
        return nil
    end

    local valueName = this.valueToString(value):lower()
    if valueName == "unknown" then
        return nil
    end

    return string.format("a_%s_%s", suitName, valueName)
end

---@param suit ESuit
---@param value EValue
---@return string?
function this.GetCardMeshName(suit, value)
    local suitName = this.suitToString(suit)
    if suitName == "Unknown" then
        return nil
    end

    local valueName = this.valueToString(value)
    if valueName == "Unknown" then
        return nil
    end

    return string.format("rf\\%s.%s.nif", suitName, valueName)
end

---@param suit ESuit
---@param value EValue
---@param grayscale boolean
---@return string?
function this.GetCardIconName(suit, value, grayscale)
    local suitName = this.suitToString(suit)
    if suitName == "Unknown" then
        return nil
    end

    local valueName = this.valueToString(value)
    if valueName == "Unknown" then
        return nil
    end

    if grayscale then
        return string.format("Icons\\rf\\%s.%s.g.dds", suitName, valueName)
    else
        return string.format("Icons\\rf\\%s.%s.dds", suitName, valueName)
    end
end

---@param count number
---@return string?
function this.GetTalonRefForCardCount(count)
    if count == 20 then
        return this.FLIN_TALON_20
    elseif count == 9 then
        return this.FLIN_TALON_9
    elseif count == 8 then
        return this.FLIN_TALON_8
    elseif count == 7 then
        return this.FLIN_TALON_7
    elseif count == 6 then
        return this.FLIN_TALON_6
    elseif count == 5 then
        return this.FLIN_TALON_5
    elseif count == 4 then
        return this.FLIN_TALON_4
    elseif count == 3 then
        return this.FLIN_TALON_3
    elseif count == 2 then
        return this.FLIN_TALON_2
    elseif count == 1 then
        return this.FLIN_TALON_1
    end
    return nil
end

---@enum GameState
this.GameState = {
    INVALID = 0,
    SETUP = 1,
    DEAL = 2,
    PLAYER_TURN = 3,
    NPC_TURN = 4,
    GAME_END = 5
}

---@param state GameState
---@return string
function this.stateToString(state)
    if state == this.GameState.INVALID then
        return "INVALID"
    elseif state == this.GameState.SETUP then
        return "SETUP"
    elseif state == this.GameState.DEAL then
        return "DEAL"
    elseif state == this.GameState.PLAYER_TURN then
        return "PLAYER_TURN"
    elseif state == this.GameState.NPC_TURN then
        return "NPC_TURN"
    elseif state == this.GameState.GAME_END then
        return "GAME_END"
    end
    return "Unknown"
end

--#region tes3

---@param actor tes3mobileActor
function this.GetAttributesSum(actor)
    return actor.agility.current +
        actor.endurance.current +
        actor.intelligence.current +
        actor.luck.current +
        actor.personality.current +
        actor.speed.current +
        actor.strength.current +
        actor.willpower.current
end

function this.getLookedAtReference()
    -- Get the player's eye position and direction.
    local eyePos = tes3.getPlayerEyePosition()
    local eyeDir = tes3.getPlayerEyeVector()

    -- Perform a ray test from the eye position along the eye direction.
    local result = tes3.rayTest({
        position = eyePos,
        direction = eyeDir,
        ignore = { tes3.player }
    })

    -- If the ray hit something, return the reference of the object.
    if (result) then return result.reference end

    -- Otherwise, return nil.
    return nil
end

-- DEBUG
function this.DEBUG_ShowMarkerAt(pos)
    tes3.createReference({
        object = "light_com_candle_06_64",
        position = pos,
        orientation = tes3vector3.new(0, 0, 0),
        cell = tes3.getPlayerCell(),
        scale = 0.2
    })
end

---@param ref tes3reference
---@return tes3reference?
function this.FindRefBelow(ref)
    local result = tes3.rayTest({
        position = ref.position + tes3vector3.new(0, 0, 10),
        direction = tes3vector3.new(0, 0, -1),
        maxDistance = 20,
        ignore = { ref },
        root = tes3.game.worldPickRoot
    })

    local result2 = tes3.rayTest({
        position = ref.position + tes3vector3.new(0, 0, 10),
        direction = tes3vector3.new(0, 0, -1),
        maxDistance = 20,
        root = tes3.game.worldObjectRoot
    })

    if result then
        return result.reference
    end
    if result2 then
        return result2.reference
    end

    return nil
end

---@param ref tes3reference
---@return tes3vector3?
function this.findPlayerPosition(ref)
    local bb = ref.object.boundingBox:copy()
    local xyoffset = 20
    bb.max.x = math.round(bb.max.x + xyoffset)
    bb.max.y = math.round(bb.max.y + xyoffset)
    bb.min.x = math.round(bb.min.x - xyoffset)
    bb.min.y = math.round(bb.min.y - xyoffset)

    local t = ref.sceneNode.worldTransform

    local stepsize = 40
    -- get x steps in a table
    local xsteps = {}
    for x = bb.min.x, bb.max.x, stepsize do
        table.insert(xsteps, x)
    end
    -- insert end pos
    table.insert(xsteps, bb.max.x)
    -- get y steps in a table
    local ysteps = {}
    for y = bb.min.y, bb.max.y, stepsize do
        table.insert(ysteps, y)
    end
    -- insert end pos
    table.insert(ysteps, bb.max.y)

    -- get all positions on the edge of the bounding box in xyoffset step
    local testOffset = 10
    local height = bb.max.z - bb.min.z
    local testHeight = height + testOffset
    local results = {}
    for _, x in ipairs(xsteps) do
        for _, y in ipairs(ysteps) do
            -- only test the edges of the bounding box
            if x == bb.min.x or x == bb.max.x or y == bb.min.y or y == bb.max.y then
                -- log:trace("Testing %d %d", x, y)

                -- convert to world position
                local testPosRaw = t * tes3vector3.new(x, y, testHeight)
                local testPos1 = testPosRaw --+ (direction * 30)
                local result = tes3.rayTest({
                    position = testPos1,
                    direction = tes3vector3.new(0, 0, -1),
                    maxDistance = testHeight - (testOffset / 2),
                    root = tes3.game.worldPickRoot
                })
                local result2 = tes3.rayTest({
                    position = testPos1,
                    direction = tes3vector3.new(0, 0, -1),
                    maxDistance = testHeight - (testOffset / 2),
                    root = tes3.game.worldObjectRoot
                })

                -- if no result then we found no obstacles
                -- DEBUG_ShowMarkerAt(testPos1)

                if result == nil and result2 == nil then
                    -- DEBUG_ShowMarkerAt(testPos1 - tes3vector3.new(0, 0, testHeight - (testOffset / 2)))

                    -- final pos is on the ground
                    local resultPos = testPos1 - tes3vector3.new(0, 0, testHeight)
                    -- add to results
                    table.insert(results, { pos = resultPos, rating = nil })
                end
            end
        end
    end

    -- if table is empty then we found no valid positions
    if table.size(results) == 0 then
        return nil
    end

    -- now we rate the positions by distance to the ref and distance to the player, then pick the one that minimizes the sum of both distances
    local playerPos = tes3.player.position
    for i, v in ipairs(results) do
        local distToRef = ref.position:distance(v.pos)
        local distToPlayer = playerPos:distance(v.pos)

        local rating = distToRef + distToPlayer
        -- if the distance to the player is less than 50 then we add a penalty
        if distToPlayer < 100 then
            rating = rating + ((100 - distToPlayer) * (100 - distToPlayer))
        end

        results[i].rating = rating
    end

    -- sort the table by rating
    table.sort(results, function(a, b)
        return a.rating < b.rating
    end)

    -- return the best position
    return results[1].pos
end

--#endregion

return this
