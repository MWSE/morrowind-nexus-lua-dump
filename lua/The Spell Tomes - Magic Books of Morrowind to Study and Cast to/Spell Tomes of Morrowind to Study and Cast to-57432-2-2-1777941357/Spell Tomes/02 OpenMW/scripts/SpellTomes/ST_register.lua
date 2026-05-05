-- register TR tomes and add weights so that ppl don't have to go down to narsis
local defs = {}
for tomeId, spellId in pairs(spellTomes) do
	if tomeId:match("^spelltome_tr_") then
		defs[#defs + 1] = {
			tomeId = tomeId,
			spellId = spellId,
			weight = 1.5,
		}
	end
end
return defs