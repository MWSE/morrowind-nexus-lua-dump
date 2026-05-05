local tomeDefs = trData.TOME_DEFS

local tomeByBook = {}
for _, def in ipairs(tomeDefs) do
	tomeByBook[def.tomeId:lower()] = def
end

local function playerKnowsSpell(spellId)
	for _, s in pairs(types.Player.spells(self)) do
		if s.id == spellId then return true end
	end
	return false
end

local function teachSpellsFromTome(def)
	local playerSpells = types.Player.spells(self)
	local learnedAny = false
	for _, spellId in ipairs(def.spells) do
		if not playerKnowsSpell(spellId) then
			playerSpells:add(spellId)
			learnedAny = true
		end
	end
	if learnedAny then
		ui.showMessage(def.message)
		ambient.playSound("skillraise")
	end
end

table.insert(G.uiModeChangedJobs, function(data)
	if data.newMode == "Book" and data.arg then
		local def = tomeByBook[data.arg.recordId:lower()]
		if def then teachSpellsFromTome(def) end
	end
end)