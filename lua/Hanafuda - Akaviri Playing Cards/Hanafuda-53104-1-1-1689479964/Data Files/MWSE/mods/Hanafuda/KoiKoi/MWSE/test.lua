local logger = require("Hanafuda.logger")
local config = require("Hanafuda.config")

do
    local card = require("Hanafuda.card")
    local koi = require("Hanafuda.KoiKoi.koikoi")
    local combo = require("Hanafuda.KoiKoi.combination")
    local caps ---@type {[CardType] : integer[]}

    --- helper
    ---@param params Card.Find.Params|integer
    ---@return {[CardType] : integer[]}
    local function AddCard(params)
        ---@param cardId integer
        local function add(cardId)
            table.insert(caps[card.GetCardData(cardId).type], cardId)
        end

        if type(params) == "table" then
            local ids = card.Find(params)
            if type(ids) == "table" then
                for _, id in ipairs(ids) do
                    add(id)
                end
            elseif type(ids) == "number" then
                add(ids)
            end
        elseif type(params) == "number" then
            add(params)
        end
        return caps
    end

    -- todo pattern
    local settings = require("Hanafuda.settings")
    local houseRule = settings.Default().koikoi.houseRule

    local unitwind = require("unitwind").new({
        enabled = true,
        highlight = false,
        beforeEach = function()
            caps = {
                [card.type.bright] = {},
                [card.type.animal] = {},
                [card.type.ribbon] = {},
                [card.type.chaff] = {},
            }
        end,
    })
    unitwind:start("Koi-Koi Combination Test")

    unitwind:test("No Combo", function()
        local actual = combo.Calculate(caps, houseRule, logger)
        unitwind:expect(actual).toBe(nil)
        -- todo edge case
    end)

    unitwind:test("Goko", function()
        local actual = combo.Calculate(AddCard({ type = card.type.bright, findAll = true }), houseRule, logger)
        unitwind:expect(actual).NOT.toBe(nil)
        if actual then
            unitwind:expect(actual[koi.combination.fiveBrights]).toBe(koi.basePoint[koi.combination.fiveBrights])
        end
    end)

    unitwind:test("Different", function()
        local goko = AddCard({ type = card.type.bright, findAll = true })
        local shiko = table.deepcopy(goko)
        table.removevalue(shiko[card.type.bright], card.Find({ symbol = card.symbol.rainman }))
        local current = combo.Calculate(goko, houseRule, logger)
        local prev = combo.Calculate(shiko, houseRule, logger)

        do
            local diff = combo.Different(prev, prev, logger)
            unitwind:expect(diff).toBe(nil)
            diff = combo.Different(current, current, logger)
            unitwind:expect(diff).toBe(nil)
        end
        do
            local diff = combo.Different(current, prev, logger)
            unitwind:expect(diff).NOT.toBe(nil)
            if diff then
                for key, value in pairs(diff) do
                    logger:debug("%d: %d", key, value)
                end
                unitwind:expect(diff[koi.combination.fiveBrights]).toBe(koi.basePoint[koi.combination.fiveBrights])
            end
        end
    end)

    unitwind:finish()
end

do
    local card = require("Hanafuda.card")
    local koi = require("Hanafuda.KoiKoi.koikoi")
    local combo = require("Hanafuda.KoiKoi.combination")
    local hand ---@type {[CardType] : integer[]}

    --- helper
    ---@param params Card.Find.Params|integer
    ---@return {[CardType] : integer[]}
    local function AddCard(params)
        ---@param cardId integer
        local function add(cardId)
            table.insert(hand, cardId)
        end

        if type(params) == "table" then
            local ids = card.Find(params)
            if type(ids) == "table" then
                for _, id in ipairs(ids) do
                    add(id)
                end
            elseif type(ids) == "number" then
                add(ids)
            end
        elseif type(params) == "number" then
            add(params)
        end
        return hand
    end

    -- todo pattern
    local settings = require("Hanafuda.settings")
    local houseRule = settings.Default().koikoi.houseRule

    local unitwind = require("unitwind").new({
        enabled = true,
        highlight = false,
        beforeEach = function()
            hand = {}
        end,
    })
    unitwind:start("Koi-Koi LuckyHands Test")

    unitwind:test("No Hands", function()
        local actual = combo.CalculateLuckyHands(hand, houseRule, logger)
        unitwind:expect(actual).toBe(nil)
        -- todo edge case
    end)
    unitwind:test("Teshi", function()
    end)
    unitwind:test("Kuttsuki", function()
    end)

    unitwind:finish()

    unitwind:start("Koi-Koi UnluckyGround Test")
    unitwind:test("Unluck", function()
        local game = require("Hanafuda.KoiKoi.game").new(config.koikoi, nil, nil, logger)
        game.groundPool = { 1, 2, 3, 5, 6, 7, 9, 10}
        unitwind:expect(game:CheckUnluckyGround()).toBe(false)
    end)
    unitwind:test("Normal", function()
        local game = require("Hanafuda.KoiKoi.game").new(config.koikoi, nil, nil, logger)
        game.groundPool = { 6, 10, 7, 11, 12, 5, 20, 8 }
        unitwind:expect(game:CheckUnluckyGround()).toBe(true)
    end)
    unitwind:finish()
end

do
    local unitwind = require("unitwind").new({
        enabled = true,
        highlight = false,
    })
    unitwind:start("Koi-Koi Integration Test")

    unitwind:test("Run Game", function()
        unitwind:expect(function()
            local runner = require("Hanafuda.KoiKoi.runner").new(
                require("Hanafuda.settings").Default().koikoi,
                require("Hanafuda.KoiKoi.brain.randomBrain").new({ koikoiChance = 0.3, meaninglessDiscardChance = 0.1}),
                require("Hanafuda.KoiKoi.brain.simpleBrain").new(),
                logger
            )
            while runner:Run() do
            end
        end).NOT.toFail()
    end)

    unitwind:finish()
end

do
    local unitwind = require("unitwind").new({
        enabled = true,
        highlight = false,
    })
    unitwind:start("Koi-Koi Sound Test")

    unitwind:test("General NPC Voice Valid Path", function()
        local soundData = require("Hanafuda.KoiKoi.soundData")
        for race, genders in pairs(soundData.voiceData) do
            local r = string.sub(race, 1, 1)
            local dir1 = "vo\\" .. r .. "\\"
            for gender, voices in pairs(genders) do
                local dir = dir1 .. gender .. "\\"
                for voiceId, paths in pairs(voices) do
                    for index, path in ipairs(paths) do
                        local valid = path:lower():startswith(dir)
                        if not valid then
                            logger:warn("invalid voice path %s, %s, %d, %d, '%s'", race, gender, voiceId, index, path)
                        end
                        unitwind:expect(valid).toBe(true)
                    end
                end
            end
        end
    end)

    unitwind:finish()
end
