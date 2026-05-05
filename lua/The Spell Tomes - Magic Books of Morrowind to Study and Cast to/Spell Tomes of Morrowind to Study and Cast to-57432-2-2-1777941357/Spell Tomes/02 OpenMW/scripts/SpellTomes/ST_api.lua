local core = require('openmw.core')
local types = require('openmw.types')
local vfs = require('openmw.vfs')
 
require("scripts.spelltomes.ST_database")
require("scripts.spelltomes.ST_rareSpells")
 
registeredTomes = {}
 
local DEFAULTS = {
	learnTrigger = "read",
	distributeToClasses = true,
	distributeToMerchants = "both",
	allowRestockWhenKnown = true,
	rare = false,
	replaceable = true,
	weight = 1,
	addSpellToVendors = false,
	addTomeToVendors = false,
	spellVendorRequireTrainer = false,	
}
 
local VALID_TRIGGERS = {
	read = true,
	activate = true,
}
 
local VALID_MERCHANT_DIST = {
	enchanter = true,
	bookseller = true,
	both = true,
	none = true,
}
 
 -- global function
function registerSpellTome(def)
	if type(def) ~= "table" then
		print("SpellTomes: register() called with non-table")
		return nil
	end
	if not def.tomeId or not def.spellId then
		print("SpellTomes: register() missing tomeId or spellId")
		return nil
	end
	
	local tomeId = def.tomeId:lower()
	local spellId = def.spellId:lower()
	
	if not types.Book.record(tomeId) then
		print("SpellTomes: skipped '"..tomeId.."': book record not found")
		return nil
	end
	if not core.magic.spells.records[spellId] then
		print("SpellTomes: skipped '"..tomeId.."': spell '"..spellId.."' not found")
		return nil
	end
	
	if registeredTomes[tomeId] then
		print("SpellTomes: overwriting existing registration for '"..tomeId.."'")
	end
	
	def.tomeId = tomeId
	def.spellId = spellId
	for key, value in pairs(DEFAULTS) do
		if def[key] == nil then
			def[key] = value
		end
	end
	
	if not VALID_TRIGGERS[def.learnTrigger] then
		print("SpellTomes: '"..tomeId.."': invalid learnTrigger '"..tostring(def.learnTrigger).."', using 'read'")
		def.learnTrigger = DEFAULTS.learnTrigger
	end
	if type(def.distributeToMerchants) == "string" and not VALID_MERCHANT_DIST[def.distributeToMerchants] then
		print("SpellTomes: '"..tomeId.."': invalid distributeToMerchants '"..tostring(def.distributeToMerchants).."', using 'both'")
		def.distributeToMerchants = DEFAULTS.distributeToMerchants
	end
	
	if def.spellVendorSkill ~= nil then
		local skillId = tostring(def.spellVendorSkill):lower()
		if not core.stats.Skill.records[skillId] then
			print("SpellTomes: "..tomeId.."': invalid spellVendorSkill '"..tostring(def.spellVendorSkill).."', ignoring")
			def.spellVendorSkill = nil
		else
			def.spellVendorSkill = skillId
		end
	end
	
	-- spawn weight has to be positive
	if type(def.weight) ~= "number" or def.weight < 0 then
		print("SpellTomes: '"..tomeId.."': invalid weight '"..tostring(def.weight).."', using 1")
		def.weight = DEFAULTS.weight
	end
	
	registeredTomes[tomeId] = def
	spellTomes[tomeId] = spellId
	if def.rare then
		rareSpells[tomeId] = true
	end
	return def
end
 
for filename in vfs.pathsWithPrefix("SpellTomes/") do
	if filename:match("%.lua$") and not filename:match("/%._") then
		local requirePath = filename:gsub("%.lua$", ""):gsub("/", ".")
		local ok, result = pcall(require, requirePath)
		if not ok then
			print("SpellTomes: failed to load '"..requirePath.."': "..tostring(result))
		elseif type(result) == "table" then
			-- single def or list of defs
			if result.tomeId then
				registerSpellTome(result)
			else
				for _, entry in ipairs(result) do
					registerSpellTome(entry)
				end
			end
		end
	end
end
