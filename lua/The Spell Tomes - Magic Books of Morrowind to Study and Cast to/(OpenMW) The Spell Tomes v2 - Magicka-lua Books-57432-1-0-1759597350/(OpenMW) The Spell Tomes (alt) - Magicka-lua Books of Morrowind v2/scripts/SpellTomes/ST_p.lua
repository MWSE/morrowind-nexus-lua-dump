local I = require('openmw.interfaces')
local types = require('openmw.types')
local self = require('openmw.self')
local Player = require('openmw.types').Player
local core = require('openmw.core')
local self = require('openmw.self')
local async = require('openmw.async')
local input = require('openmw.input')
local time = require('openmw_aux.time')
local storage = require('openmw.storage')
local ui = require('openmw.ui')
local currentCell
local MOD_NAME = "SpellTomes"
local playerSection = storage.playerSection("Settings"..MOD_NAME)

local skills = {
	alteration = 0,
	conjuration = 0,
	destruction = 0,
	illusion = 0,
	mysticism = 0,
	restoration = 0,
}
local blacklistedCells = {}

local hardcodedBlacklistedCells = {
["Ancestral Refuge, Soul Forge"] = true,
["Balmora, Nord House"] = true,
["Balmora, Nord House Lower"] = true,
["Underwater Dwemer Home"] = true,
["Bamz-Amschend, Radac's Forge"] = true,
["Molag Mar, Dwelling"] = true,
["Balmora Stronghold"] = true,
["Bamz-Amschend, Passage of the Walker"] = true,
["Thirr Residence"] = true,
["Maar Gan, Andus Tradehouse"] = true,
["Underwater Home, kitchen"] = true,
["Underwater Home, Mages Room"] = true,
["Solstheim, Hirstaang Cabin"] = true,
["Tel Vos, Central Tower"] = true,
["Seyda Neen, My Shack"] = true,
["Underwater Home, Geabar's forge"] = true,
["Underwater Home, Bed Room"] = true,
["Old Ebonheart Cottage"] = true,
["Mournhold, Godsreach"] = true,
["Abandoned Storage"] = true,
["The Maniac's Shack"] = true,
["Tel Aruhn, House"] = true,
["Vivec, St. Olms My House"] = true,
["Nerevar Stronghold,  Trader"] = true,
["Nerevar Stronghold,  East Guard Tower"] = true,
["Lord Nerevar's Grand Abode"] = true,
["Nerevar Stronghold, Dagoth-No-Mur Inn, Upper Floor"] = true,
["Sotha Sil, Dome of the Imperfect"] = true,
["Akamora Manor"] = true,
["Ebon Tower, Imperial Real Estate Office"] = true,
["Vivec, St. Delyn"] = true,
["Balmora Castle"] = true,
["Nerevarine's Yurt"] = true,
["Voya Manor, Library"] = true,
["Beached Shipwreck, Lower Level"] = true,
["Wolverine Hall"] = true,
["Nivalis Manor"] = true,
["Balmora Castle Chamber"] = true,
["Karthwasten, Wheatfield Home"] = true,
["Vivec, St. Delyn My House"] = true,
["Nerevar Manor, Vault"] = true,
["Mournhold, My House"] = true,
["Unerwater Home, Yagrum's Room"] = true,
["Omaynis"] = true,
["Tel Mora, Lower Tower"] = true,
["Zainab Camp, Ababael Timsar-Dadisun's Yurt"] = true,
["Nerevar Stronghold,  South Guard Tower"] = true,
["Dagon Fel, House"] = true,
["Pelagiad, Minuet Cottage"] = true,
["Old Ebonheart, Feldsen Farm"] = true,
["Balmora, Odai House"] = true,
["Vivec, Guild of Fighters"] = true,
["Tel Vos, House"] = true,
["Urshilaku Camp, Clanfriend's Yurt"] = true,
["Nerevar Manor,  Upper Floor"] = true,
["Underwater Hall"] = true,
["Balmora, My House"] = true,
["Balmora, Hlaalo Manor"] = true,
["Nerevar Stronghold, Guard Store Tower"] = true,
["Maar Gan, Hut"] = true,
["Caldera, House"] = true,
["Gnaar Mok, Shack"] = true,
["Vivec, St. Olms Canal East-One"] = true,
["Nerevar Stronghold, Ulrik Bfarograb's Shack"] = true,
["Seyda Neen, The Scrib Runner"] = true,
["Maar Gan, My Hut"] = true,
["Tel Mora, Shack"] = true,
["Suran, Farmhouse"] = true,
["Gnisis, Madach Tradehouse"] = true,
["Sadrith Mora, House"] = true,
["Nerevar Stronghold,  Fighters Guild Office"] = true,
["Gnisis, Hut"] = true,
["Nerevar Stronghold, Nova Star's Shack"] = true,
["Ebonheart, Sojourner Quarters"] = true,
["Ald'ruhn, My Manor"] = true,
["Solstheim, Nerevar's House"] = true,
["Nerevar Stronghold,  Dagoth-No-Mur Inn"] = true,
["Ashlander Tent"] = true,
["Tel Mora, House"] = true,
["Pelagiad, Cottage"] = true,
["Cursed Diamond Mine"] = true,
["Tel Branora, House"] = true,
["Beached Shipwreck, Cabin"] = true,
["Khuul, Shack"] = true,
["Pelagiad, Abendgold"] = true,
["Vivec, Foreign Quarter Suite"] = true,
["Balmora, Nord House Armoury"] = true,
["Vivec, Hall of Wisdom"] = true,
["Ald Velothi, Shack"] = true,
["Norenen-dur"] = true,
["Hla Oad, Shack"] = true,
["Tel Aruhn, Plot and Plaster"] = true,
["Ald-ruhn, Ald Skar Inn"] = true,
["Mournhold, Royal Palace: Courtyard"] = true,
["Vivec, High Fane"] = true,
["Bal Foyen Manor"] = true,
["Skaal Village"] = true,
["Vos, Vos Chapel"] = true,
["Ashlander Yurt"] = true,
["Ald-ruhn, Ancestral Refuge"] = true,
["Beached Shipwreck, Upper Level"] = true,
["Sadrith Mora, Telvanni Council House"] = true,
["Tel Branora, Lower Tower"] = true,
["Balmora, Residence"] = true,
["Seyda Neen, Fine-Mouth's Shack"] = true,
["Khuul, Home"] = true,
["Underwater Home, Living Room"] = true,
["Solstheim, Hirstaang Cabin Cellar"] = true,
["Balmora, Hlaalu Council Manor"] = true,
["The Maniac's Mansion, Tower"] = true,
["Ald Velothi"] = true,
["Balmora Castle Dining"] = true,
["Stronghold Mine"] = true,
["Voya Manor, Study"] = true,
["Voya Manor, Servant's Quarters"] = true,
["Balmora Castle Armory"] = true,
["Voya Manor, Armory"] = true,
["Voya Manor, Tower"] = true,
["Nerevar Stronghold,  Mages Guild Office"] = true,
["Voya Manor, South Wing"] = true,
["Bamz-Amschend, Skybreak Gallery"] = true,
["Omaynis, My Cave Dwelling"] = true,
["The Maniac's Mansion, Entrance"] = true,
["Ebonheart, Imperial Commission"] = true,
["Nerevar Stronghold, North Guard Tower"] = true,
["Nerevar Stronghold"] = true,
["Tatooine, Old Water Station"] = true,
["Tatooine, Sandriver"] = true,
["Ancestral Refuge, Living Quarters"] = true,
["An Abandoned Shack"] = true,
["Skaal Village, The Blodskaal's House"] = true,
["Nerevar Stronghold,  Guard Quarters"] = true,
["Balmora, Nerano Manor"] = true,
["Solstheim, Nerevar's Home - Kitchen"] = true,
["Underwater Home, Armory And Training Room"] = true,
["Feldsen Farm"] = true,
["Balmora, My House on North"] = true,
["Solstheim, Nerevar's Home - Display Room"] = true,
["Solstheim, Nerevar's Home - Bottom Floor"] = true,
["Skaal Village, Hut"] = true,
["Underwater Home, Hall Of Victory"] = true,
["Nur Kishar"] = true,
["Balmora, Caius Cosades' Upstairs"] = true,
["Nerevar Stronghold, Olrine-Kei's Shack"] = true,
["Blightward"] = true,
["Firewatch"] = true,
["Balmora, My House on South"] = true,
["Seyda Neen, My House"] = true,
["Nerevar Manor,  Main Floor"] = true,
["Firewatch Cottage"] = true,
["Mournhold, My Manor"] = true,
["Balmora, My Manor"] = true,
["Bamz-Amschend, King's Walk"] = true,
["Balmora, Vorar Helas' House"] = true,
["Balmora, Storage Home"] = true,
["Balmora Stronghold Armory"] = true,
["Kaiserliches Gefangenenschiff"] = true,
["Gnisis, Arvs-Drelen"] = true,
["Vivec, Arena Hidden Area"] = true,
["Abendgold, crypt"] = true,
["Balmora, My House on East"] = true,
["Underwater Home, Dome Of The Warlord"] = true,
["Imperial Safehouse"] = true,
["Karthwasten"] = true,
["Nerevar Stronghold,  West Guard Tower"] = true,
["Voya Manor, Main Hall"] = true,
["Nerevar Manor,  Basement"] = true,
["Voya Manor, Storage"] = true,
["Solstheim, Neverar's Home - Main Interior"] = true,
["Ald'ruhn, My House"] = true,
["Tel Uvirith, Secret Lab"] = true,
}

function split_entries(str)
	local entries = {}
	
	-- Handle empty or nil string
	if not str or str == "" then
		return entries
	end
	
	for entry in string.gmatch(str, "([^;]+)") do
		entry = entry:match("^%s*(.-)%s*$")
		
		if entry and entry ~= "" then
			entries[entry:lower()] = true
		end
	end
	
	return entries
end

I.Settings.registerGroup {
	key = "Settings" .. MOD_NAME,
	l10n = MOD_NAME,
	name = "Settings",
	page = MOD_NAME,
	description = "",
	permanentStorage = true,
	settings = {
		--{
		--	key = "BOOL",
		--	name = "BOOL",
		--	description = "",
		--	default = true,
		--	renderer = "checkbox",
		--},
		{
			key = "CONVERSION_CHANCE",
			name = "Conversion Chance (%)",
			description = "Chance that a book gets converted, in percent",
			default = 5,
			renderer = "number",
		},
		{
			key = "CONVERSION_DECLINE",
			name = "Conversion Decline",
			description = "Multiplier on conversion chance after each converted book",
			default = 0.8,
			renderer = "number",
		},
		{
			key = "MIN_CAST_CHANCE",
			name = "Min Cast Chance (%)",
			description = "of the spell in the book",
			default = 50,
			renderer = "number",
		},
		{
			key = "MAX_CAST_CHANCE",
			name = "Max Cast Chance (%)",
			description = "of the spell in the book",
			default = 200,
			renderer = "number",
		},
		{
			key = "ADD_TO_ENCHANTERS",
			name = "Enchanter spell tomes",
			description = "enchanters will sell this many spell tomes",
			default = 3,
			renderer = "number",
		},
		{
			key = "BLACKLISTED_CELLS",
			name = "Blacklisted Cells",
			description = "Has to be set before entering the cell.\nSeperated by semicolons",
			default = "Tel Uvirith Tower Lower; Tel Uvirith Tower Upper",
			renderer = "textLine",
		},
	}
}


I.Settings.registerPage {
	key = MOD_NAME,
	l10n = MOD_NAME,
	name = MOD_NAME,
	description = ""
}

playerSection:subscribe(async:callback(function (_,setting)
	if setting == "MIN_CAST_CHANCE" or setting == "MAX_CAST_CHANCE" then
		core.sendGlobalEvent("SpellTomes_registerPlayer", {player = self, minCastChance = playerSection:get("MIN_CAST_CHANCE")/100, maxCastChance = playerSection:get("MAX_CAST_CHANCE")/100} )
	end
	if setting == "BLACKLISTED_CELLS" then
		blacklistedCells = split_entries(playerSection:get("BLACKLISTED_CELLS"))
		for cell in pairs(hardcodedBlacklistedCells) do
			blacklistedCells[cell:lower()] = true
		end		
	end
end))

blacklistedCells = split_entries(playerSection:get("BLACKLISTED_CELLS"))
for cell in pairs(hardcodedBlacklistedCells) do
	blacklistedCells[cell:lower()] = true
end		

	
local function job()
	if self.cell then
		--print(self.cell)
		if not currentCell or self.cell.id ~=currentCell.id then
			if not blacklistedCells[self.cell.id:lower()] then
				core.sendGlobalEvent("SpellTomes_convertBooksInCell", {
					player = self, 
					chance = playerSection:get("CONVERSION_CHANCE")/100,
					chanceDecline = playerSection:get("CONVERSION_DECLINE"),
					minCastChance = playerSection:get("MIN_CAST_CHANCE")/100,
					maxCastChance = playerSection:get("MAX_CAST_CHANCE")/100,
					addToEnchanters = playerSection:get("ADD_TO_ENCHANTERS"),
				})
			end
			currentCell = self.cell
		end
	end
	for skill, level in pairs(skills) do
		local newLevel = types.NPC.stats.skills[skill](self).modified
		if level ~= newLevel then
			skills[skill] = newLevel
			core.sendGlobalEvent("SpellTomes_registerPlayer", {player = self, minCastChance = playerSection:get("MIN_CAST_CHANCE")/100, maxCastChance = playerSection:get("MAX_CAST_CHANCE")/100} )
		end
	end
end

local function onLoad(data)
	--saveData = data or {}
	core.sendGlobalEvent("SpellTomes_registerPlayer", {player = self, minCastChance = playerSection:get("MIN_CAST_CHANCE")/100, maxCastChance = playerSection:get("MAX_CAST_CHANCE")/100} )
	currentCell = nil
	stopTimerFn = time.runRepeatedly(job, 0.489 * time.second, {
		type = time.SimulationTime,
		initialDelay = 0.489 * time.second
	})
end

--local function onSave(data)
--	return saveData
--end

return {
	engineHandlers = { 
		onLoad = onLoad,
		onInit = onLoad,
		--onSave = onSave,
	},
}
