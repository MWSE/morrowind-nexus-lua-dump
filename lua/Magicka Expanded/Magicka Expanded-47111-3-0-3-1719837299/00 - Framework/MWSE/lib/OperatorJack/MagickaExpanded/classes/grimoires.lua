local common = require("OperatorJack.MagickaExpanded.common")
local log = require("OperatorJack.MagickaExpanded.utils.logger")

--- Grimoires module for interacting with grimoire objects.
---@class MagickaExpanded.Grimoires
local this = {}

---@class MagickaExpanded.Grimoires.Grimoire
---@field id string The ID of the Grimoire. This should be the book object ID.
---@field spellIds string[] The IDs of the spells to learn from the Grimoire.

---@type MagickaExpanded.Grimoires.Grimoire[]
local grimoires = {}

--[[
	Adds all grimoires that are currently registered to the player's inventory.
]]
this.addGrimoiresToPlayer = function()
    for _, grimoire in ipairs(grimoires) do
        if (tes3.getObject(grimoire.id)) then
            tes3.addItem({reference = tes3.player, item = grimoire.id})
        else
            log:debug("Unable to find grimoire ID: " .. grimoire.id)
        end
    end
end

--[[
    Registers the given grimoire to be checked when a book is opened.
]]
---@param grimoire MagickaExpanded.Grimoires.Grimoire
this.registerGrimoire = function(grimoire) table.insert(grimoires, grimoire) end

--[[
    Registers the given grimoires as a collection of grimoires to be checked
        for when a book is opened.
]]
---@param grimoires MagickaExpanded.Grimoires.Grimoire[]
this.registerGrimoires = function(grimoires)
    for _, grimoire in ipairs(grimoires) do this.registerGrimoire(grimoire) end
end

---@param bookId string
---@return MagickaExpanded.Grimoires.Grimoire | nil
local function FindGrimoire(bookId)
    for _, grimoire in ipairs(grimoires) do if (grimoire.id == bookId) then return grimoire end end
    return nil
end

--[[
    Attempts to teach the player the given Grimoire if they qualify. 
    The player will learn the Grimoire if their current magicka is greater than the 
    learning cost of the spell set, which is the sum of each Grimoire's spell magicka cost * 2. 
    If successful, the player will have that amount drained from their current magicka.
    Otherwise, they lose all magicka.
]]
---@param grimoire MagickaExpanded.Grimoires.Grimoire
local function tryLearningSpells(grimoire)
    tes3.fadeOut({duration = 2})

    local hasMagicka = false

    local learningCost = 0
    for _, spellId in ipairs(grimoire.spellIds) do
        learningCost = learningCost + tes3.getObject(spellId).magickaCost * 2
    end

    local newMagicka = tes3.mobilePlayer.magicka.current - learningCost
    if (newMagicka >= 0) then hasMagicka = true end

    if (hasMagicka) then
        tes3.modStatistic({
            reference = tes3.mobilePlayer,
            name = "magicka",
            current = learningCost * -1
        })
        for _, spellId in ipairs(grimoire.spellIds) do
            tes3.addSpell({reference = tes3.player, spell = spellId, updateGUI = false})
        end
        tes3.updateMagicGUI({reference = tes3.player})
        tes3.messageBox(
            "As you study the tome and practice the spells described within, you feel new spells enter your mind.")
    else
        tes3.modStatistic({
            reference = tes3.mobilePlayer,
            name = "magicka",
            current = tes3.mobilePlayer.magicka.current * -1
        })
        tes3.messageBox(
            "As you study the tome, you find that you do not have enough magicka to practice the spells described within and learn them.")
    end

    tes3.fadeIn({duration = 2})
end

---@param e bookGetTextEventData
local function onBookGetText(e)
    local grimoire = FindGrimoire(e.book.id)

    if (grimoire == nil) then return end

    local newSpell = false
    for _, spellId in ipairs(grimoire.spellIds) do
        if (common.hasSpell(tes3.player, spellId) == false) then newSpell = true end
    end
    if (newSpell) then
        tryLearningSpells(grimoire)
    else
        tes3.messageBox("You attempt to read the grimoire but can learn nothing more.")
    end
end

--[[
	Registers the grimoire event. On bookGetText, the collection of
		registered grimoires will be iterated through. If the book belongs to the
		collection of registered grimoires, the spells mapped to that grimoire will be
		added to the player, if the player does not already have them.
]]
this.registerEvent = function() event.register(tes3.event.bookGetText, onBookGetText) end

return this
