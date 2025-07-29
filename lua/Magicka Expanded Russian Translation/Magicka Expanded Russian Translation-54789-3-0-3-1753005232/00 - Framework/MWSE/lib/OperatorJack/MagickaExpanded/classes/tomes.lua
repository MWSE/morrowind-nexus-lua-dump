local common = require("OperatorJack.MagickaExpanded.common")
local log = require("OperatorJack.MagickaExpanded.utils.logger")

--- Tomes module for interacting with tome objects.
---@class Tomes
local this = {}

---@class Tomes.Tome
---@field id string The ID of the tome. This should be the book object ID.
---@field spellId string The ID of the spell to learn from the tome.

---@type Tomes.Tome[]
local tomes = {}

--[[
	Adds all tomes that are currently registered to the player's inventory.
]]
this.addTomesToPlayer = function()
    for _, tome in ipairs(tomes) do
        if (tes3.getObject(tome.id)) then
            tes3.addItem({reference = tes3.player, item = tome.id})
        else
            log:debug("Unable to find tome ID: " .. tome.id)
        end
    end
end

--[[
	Registers the given tome to be checked when a book is opened.
]]
---@param tome Tomes.Tome
this.registerTome = function(tome) table.insert(tomes, tome) end

--[[
	Registers the given tomes as a collection of tomes to be checked for
		when a book is opened.
]]
---@param tomes Tomes.Tome[]
this.registerTomes = function(tomes) for _, tome in ipairs(tomes) do this.registerTome(tome) end end

---@param bookId string
---@return Tomes.Tome | nil
local function FindTome(bookId)
    for _, tome in ipairs(tomes) do if (tome.id == bookId) then return tome end end
    return nil
end

--[[
    Attempts to teach the player the given tome if they qualify. 
    The player will learn the tome if their current magicka is greater than the 
    learning cost of the spell, which is the tome's spell magicka cost * 2. 
    If successful, the player will have that amount drained from their current magicka.
    Otherwise, they lose all magicka.
]]
---@param tome Tomes.Tome
local function tryLearningSpell(tome)
    tes3.fadeOut({duration = 2})

    local hasMagicka = false
    local learningCost = tes3.getObject(tome.spellId).magickaCost * 2
    local newMagicka = tes3.mobilePlayer.magicka.current - learningCost
    if (newMagicka >= 0) then hasMagicka = true end

    if (hasMagicka) then
        tes3.modStatistic({
            reference = tes3.mobilePlayer,
            name = "magicka",
            current = learningCost * -1
        })
        tes3.addSpell({reference = tes3.player, spell = tome.spellId})
        tes3.messageBox(
            "Изучая том и практикуя описанное в нем заклинание, вы чувствуете, как новое заклинание проникает в ваш разум.")
    else
        tes3.modStatistic({
            reference = tes3.mobilePlayer,
            name = "magicka",
            current = tes3.mobilePlayer.magicka.current * -1
        })
        tes3.messageBox(
            "Изучая том, вы обнаружили, что у вас недостаточно магии, чтобы практиковать описанное в нем заклинание и выучить его.")
    end

    tes3.fadeIn({duration = 2})
end

---@param e bookGetTextEventData
local function onBookGetText(e)
    local tome = FindTome(e.book.id)

    if (tome == nil) then return end

    if (common.hasSpell(tes3.player, tome.spellId)) then
        tes3.messageBox("Вы пытаетесь прочитать том, но не можете узнать ничего нового.")
    else
        tryLearningSpell(tome)
    end
end

--[[
	Registers the tome event. On bookGetText, the collection of
		registered tomes will be iterated through. If the book belongs to the
		collection of registered tomes, the spell mapped to that tome will be
		added to the player, if the player does not already have it.
]]
this.registerEvent = function() event.register(tes3.event.bookGetText, onBookGetText) end

return this
