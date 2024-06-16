local common = require("OperatorJack.MagickaExpanded.common")

local this = {}

local grimoires = {}

--[[
	Description: Adds all grimoires that are currently registered to the player's inventory.
]]
this.addGrimoiresToPlayer = function ()
    for _, grimoire in ipairs(grimoires) do
        if (tes3.getObject(grimoire.id)) then
            tes3.addItem({
                reference = tes3.getPlayerRef(), 
                item = grimoire.id
            })
        else
            common.debug("Unable to find grimoire ID: " .. grimoire.id)
        end
	end
end

--[[
    Description: Registers the given @grimoire to be checked when a book is opened.

    @grimoire: The grimoire to register. Must be in the following format:
    example = {
        id = "exampleGrimoireBookId1",
        spellIds = {
            "exampleSpellId1",
            "exampleSpellId2"
        }
    }
]]
this.registerGrimoire = function(grimoire)	
	table.insert(grimoires, grimoire)
end

--[[
    Description: Registers @grimoires as a collection of grimoires to be checked 
        for when a book is opened.

    @grimoires: The grimoires to register. Must be in the following format:
    example = {
        {
            id = "exampleGrimoireBookId1",
            spellIds = {
                "exampleSpellId1",
                "exampleSpellId2"
            }
        },
        {
            id = "exampleGrimoireBookId2",
            spellIds = {
                "exampleSpellId1",
                "exampleSpellId2"
            }
        }
    }
]]
this.registerGrimoires = function(grimoires)
	for _, grimoire in ipairs(grimoires) do
		this.registerGrimoire(grimoire)
	end
end

local function FindGrimoire(bookId)   
    for _, grimoire in ipairs(grimoires) do 
		if (grimoire.id == bookId) then
			return grimoire
		end
	end
	return nil
end


local function tryLearningSpells(grimoire)
	tes3.fadeOut({duration = 2})

    local hasMagicka = false
    
    local learningCost = 0
    for _, spellId in ipairs(grimoire.spellIds) do      
        learningCost = learningCost + tes3.getObject(spellId).magickaCost * 2
    end

	local newMagicka = tes3.mobilePlayer.magicka.current - learningCost
	if (newMagicka >= 0) then
		hasMagicka = true
	end

	if (hasMagicka) then
		tes3.modStatistic({
			reference = tes3.mobilePlayer,
			name = "magicka",
			current = learningCost * -1
		})
        for _, spellId in ipairs(grimoire.spellIds) do      
            mwscript.addSpell({reference = tes3.player, spell = spellId})
        end
		tes3.messageBox("Изучая гримуар и практикуя описанные в нем заклинания, вы чувствуете, как новые заклинания проникают в ваш разум.")
	else
		tes3.modStatistic({
			reference = tes3.mobilePlayer,
			name = "magicka",
			current = tes3.mobilePlayer.magicka.current * -1
		})
		tes3.messageBox("Изучая гримуар, вы обнаружили, что у вас недостаточно магии, чтобы практиковать описанные в нем заклинания и выучить их.")
	end

	tes3.fadeIn({duration = 2})
end

local function onBookGetText(e)
	local grimoire = FindGrimoire(e.book.id)

	if (grimoire == nil) then  
		return
	end
    
    local newSpell = false
    for _, spellId in ipairs(grimoire.spellIds) do      
        if (common.hasSpell(tes3.player, spellId) == false) then		
            newSpell = true
        end
    end
    if (newSpell) then
        tryLearningSpells(grimoire)
    else
        tes3.messageBox("Вы пытаетесь прочитать гримуар, но больше ничего не можете узнать.")
    end
end

--[[
	Description: Registers the grimoire event. On bookGetText, the collection of 
		registered grimoires will be iterated through. If the book belongs to the
		collection of registered grimoires, the spells mapped to that grimoire will be
		added to the player, if the player does not already have them.
]]
this.registerEvent = function ()
	event.register("bookGetText", onBookGetText)
end

return this