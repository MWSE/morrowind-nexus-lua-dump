do
    local card = require("Hanafuda.card")
    local cardData = require("Hanafuda.cardData")

    local unitwind = require("unitwind").new({
        enabled = true,
        highlight = false,
    })

    unitwind:start("Hanafuda Card")

    ---@param t table
    local function IsSequence(t)
        local values = table.values(t, true)
        for i = 1, table.size(values) do
            unitwind:expect(values[i]).NOT.toBe(nil)
        end
    end

    unitwind:test("Suit", function()
        IsSequence(cardData.cardSuit)
        unitwind:expect(table.size(cardData.suitText)).toBe(table.size(cardData.cardSuit))
    end)

    unitwind:test("Type", function()
        IsSequence(cardData.cardType)
        unitwind:expect(table.size(cardData.typeText)).toBe(table.size(cardData.cardType))
        unitwind:expect(table.size(cardData.typeColor)).toBe(table.size(cardData.cardType))
    end)

    unitwind:test("Symbol", function()
        IsSequence(cardData.cardSymbol)
    end)

    unitwind:test("Data", function()
        unitwind:expect(card.GetCardWidth() > 0).toBe(true)
        unitwind:expect(card.GetCardHeight() > 0).toBe(true)
        unitwind:expect(cardData.cardCount > 0).toBe(true)
        unitwind:expect(table.size(cardData.cardText)).toBe(cardData.cardCount)
    end)

    unitwind:test("CreateDeck", function()
        local deck = card.CreateDeck()
        unitwind:expect(table.size(deck)).toBe(cardData.cardCount)
        -- sequence and unique?
        for index, value in ipairs(deck) do
            unitwind:expect(value).toBe(index)
        end
    end)

    unitwind:test("ShuffleDeck", function()
        local deck = card.CreateDeck()
        local shuffled = card.ShuffleDeck(deck)
        unitwind:expect(table.size(shuffled)).toBe(table.size(deck))

        -- no duplicated?
        -- smarter way in lua?
        for i, v1 in ipairs(shuffled) do
            for j, v2 in ipairs(shuffled) do
                if i ~= j then
                    unitwind:expect(v1 ~= v2).toBe(true)
                end
            end
        end
    end)

    unitwind:test("DealCard", function()
        local deck = card.CreateDeck()
        for i = 48, 1, -1 do
            local cardId = card.DealCard(deck)
            unitwind:expect(cardId).toBe(i)
            if cardId then
                unitwind:expect(card.GetCardData(cardId)).NOT.toBe(nil)
            end
        end
        local cardId = card.DealCard(deck)
        unitwind:expect(cardId).toBe(nil)
    end)

    -- todo asset test

    unitwind:finish()
end
