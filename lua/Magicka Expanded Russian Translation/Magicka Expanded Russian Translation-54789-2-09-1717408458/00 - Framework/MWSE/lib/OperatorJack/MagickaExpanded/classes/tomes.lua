local common = require("OperatorJack.MagickaExpanded.common")

local this = {}

local tomes = {}

--[[
	Description: Adds all tomes that are currently registered to the player's inventory.
]]
this.addTomesToPlayer = function()
	for _, tome in ipairs(tomes) do
		if (tes3.getObject(tome.id)) then
			tes3.addItem({
				reference = tes3.getPlayerRef(), 
				item = tome.id
			})
        else
            common.debug("Unable to find tome ID: " .. tome.id)
        end
	end
end

--[[
	Description: Registers the given @tome to be checked when a book is opened.

	@tome: The tome to register. Must be in the following format:
	example = {
		id = "exampleTomeBookId",
		spellId = "exampleSpellId"
	}
]]
this.registerTome = function(tome)	
	table.insert(tomes, tome)
end

--[[
	Description: Registers @tomes as a collection of tomes to be checked for
		when a book is opened.

	@tomes: The tomes to register. Must be in the following format:
	example = {
		{
			id = "exampleTomeBookId1",
			spellId = "exampleSpellId1"
		},
		{
			id = "exampleTomeBookId2",
			spellId = "exampleSpellId2"
		}
	}
]]
this.registerTomes = function(tomes)
	for _, tome in ipairs(tomes) do
		this.registerTome(tome)
	end
end

local function FindTome(bookId)
	for _, tome in ipairs(tomes) do
		if (tome.id == bookId) then
			return tome
		end
	end
	return nil
end

local function tryLearningSpell(tome)
	tes3.fadeOut({duration = 2})

	local hasMagicka = false
	local learningCost = tes3.getObject(tome.spellId).magickaCost * 2
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
		mwscript.addSpell({reference = tes3.player, spell = tome.spellId})
		tes3.messageBox("Изучая том и практикуя описанное в нем заклинание, вы чувствуете, как новое заклинание проникает в ваш разум.")
	else
		tes3.modStatistic({
			reference = tes3.mobilePlayer,
			name = "magicka",
			current = tes3.mobilePlayer.magicka.current * -1
		})
		tes3.messageBox("Изучая том, вы обнаружили, что у вас недостаточно магии, чтобы практиковать описанное в нем заклинание и выучить его.")
	end

	tes3.fadeIn({duration = 2})
end

local function onBookGetText(e)
	local tome = FindTome(e.book.id)

	if (tome == nil) then
		return
	end

	if (common.hasSpell(tes3.player, tome.spellId)) then
		tes3.messageBox("Вы пытаетесь прочитать том, но больше ничего не можете узнать.")
	else	
		tryLearningSpell(tome)
	end
end

--[[
	Description: Registers the tome event. On bookGetText, the collection of 
		registered tomes will be iterated through. If the book belongs to the
		collection of registered tomes, the spell mapped to that tome will be
		added to the player, if the player does not already have it.
]]
this.registerEvent = function ()
	event.register("bookGetText", onBookGetText)
end


return this