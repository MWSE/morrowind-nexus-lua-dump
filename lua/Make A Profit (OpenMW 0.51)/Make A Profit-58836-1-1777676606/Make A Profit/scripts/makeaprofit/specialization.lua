local types = require('openmw.types')
local self  = require('openmw.self')
 
local Specialization = {}

-- wildcards
local FOOD_IDS   = {}
local SOULGEM_IDS = {}
local SPELLTOMES = {}
 
-- food: ingredients with restoreFatigue, food_* prefix, or mod food prefixes
-- if using sun's dusk use its database instead
for _, rec in pairs(types.Ingredient.records) do
	local id = rec.id:lower()
	local isFood = false
	
	if rec.effects then
		for _, eff in pairs(rec.effects) do
			if eff.id == 'restorefatigue' then
				isFood = true
				break
			end
		end
	end
 
	if id:find('^food_') then isFood = true end
	if id:find('^t_ingfood_') then isFood = true end
	if id:find('^ab_ingfood_') then isFood = true end
	if id:find('sweetroll') then isFood = true end
	if rec.value >= 35 then isFood = false end
	if id:find('^t_ingflor_') then isFood = false end
	if id:find('powder') then isFood = false end
	if id:find('choke') then isFood = false end
 
	if isFood then FOOD_IDS[id] = true end
end
 
-- drinks: potions with drink-like prefixes
-- if SD use its drinks/liquor database
for _, rec in pairs(types.Potion.records) do
	local id = rec.id:lower()
	if id:find('^ab_dri_')
		or id:find('^t_%w+_drink')
		or id:find('^potion_comberry')
		or id:find('^potion_cyro')
		or id:find('^potion_local')
		or id:find('^potion_nord_mead')
		or id:find('^potion_ancient_brandy')
	then
		FOOD_IDS[id] = true
	end
end
 
-- soul gems
for _, rec in pairs(types.Miscellaneous.records) do
	local id = rec.id:lower()
	if id:find('^misc_soulgem') then
		SOULGEM_IDS[id] = true
	end
end
 
for _, rec in pairs(types.Book.records) do
	local id = rec.id:lower()
	if id:find('^spelltome_') or id:find('^spellbook_') then
		SPELLTOMES[id] = true
	end
end
 
local function getItemCategory(item)
	if types.Weapon.objectIsInstance(item)         then return 'Weapon'      end
	if types.Armor.objectIsInstance(item)          then return 'Armor'       end
	if types.Clothing.objectIsInstance(item)       then return 'Clothing'    end
	if types.Potion.objectIsInstance(item)         then return 'Potions'     end
	if types.Ingredient.objectIsInstance(item)     then return 'Ingredients' end
	if types.Apparatus.objectIsInstance(item)      then return 'Apparatus'   end
	if types.Lockpick.objectIsInstance(item)       then return 'Picks'       end
	if types.Probe.objectIsInstance(item)          then return 'Probes'      end
	if types.Repair.objectIsInstance(item)         then return 'RepairItems' end
	if types.Light.objectIsInstance(item)          then return 'Lights'      end
	if types.Book.objectIsInstance(item)           then return 'Books'       end
	if types.Miscellaneous.objectIsInstance(item)  then return 'Misc'        end
	return nil
end
 
-- Class specialization table
-- Categories match servicesOffered keys
-- _food -> checks FOOD_IDS
-- _soulgem -> checks SOULGEM_IDS
-- _enchanted -> checks record.enchant
 
local CLASS_BONUS = {
	-- vanilla classes
	['acrobat']                = { Clothing = 0.05 },
	['agent']                  = { Clothing = 0.05, Picks = 0.05 },
	['alchemist']              = { Apparatus = 0.05, Potions = 0.05, Ingredients = 0.05, _spelltome = 0.05 },
	['alchemist service']      = { Apparatus = 0.1, Potions = 0.1, Ingredients = 0.1, _spelltome = 0.1 },
	['apothecary']             = { Apparatus = 0.05, Potions = 0.05, Ingredients = 0.05, _spelltome = 0.05 },
	['apothecary service']     = { Apparatus = 0.1, Potions = 0.1, Ingredients = 0.1, _spelltome = 0.1 },
	['archer']                 = { Weapon = 0.05 },
	['assassin']               = { Weapon = 0.05, Potions = 0.05 },
	['assassin service']       = { Weapon = 0.1, Potions = 0.1 },
	['barbarian']              = { Weapon = 0.05, Armor = 0.05 },
	['bard']                   = { Books = 0.05, Clothing = 0.05, _spelltome = 0.05 },
	['battlemage']             = { _enchanted = 0.05, Weapon = 0.05, _spelltome = 0.05 },
	['battlemage service']     = { _enchanted = 0.1, _spelltome = 0.1 },
	['bookseller']             = { Books = 0.2, _spelltome = 0.2 },
	['buoyant armiger']        = { Weapon = 0.05, Armor = 0.05, _spelltome = 0.05 },
	['caravaner']              = { Misc = 0.05 },
	['champion']               = { Weapon = 0.05, Armor = 0.05 },
	['clothier']               = { Clothing = 0.2 },
	['commoner']               = false,
	['crusader']               = { Weapon = 0.05, Armor = 0.05, _spelltome = 0.05 },
	['dreamers']               = false,
	['drillmaster']            = { Weapon = 0.05, Armor = 0.05 },
	['drillmaster service']    = { Weapon = 0.1, Armor = 0.1 },
	['enchanter']              = { _enchanted = 0.05, _soulgem = 0.05, _spelltome = 0.05 },
	['enchanter service']      = { _enchanted = 0.15, _soulgem = 0.15, _spelltome = 0.15 },
	['enforcer']               = { Weapon = 0.05, Armor = 0.05 },
	['farmer']                 = { _food = 0.1, Ingredients = 0.1 },
	['gondolier']              = false,
	['guard']                  = { Weapon = 0.05, Armor = 0.05 },
	['guild guide']            = { Books = 0.05, Potions = 0.05, _spelltome = 0.05 },
	['healer']                 = { Potions = 0.05, Ingredients = 0.05, _spelltome = 0.05 },
	['healer service']         = { Potions = 0.15, Ingredients = 0.15, _spelltome = 0.15 },
	['herder']                 = { _food = 0.05 },
	['hunter']                 = { Weapon = 0.1, Armor = 0.05 },
	['knight']                 = { Weapon = 0.05, Armor = 0.05 },
	['mabrigash']              = { Potions = 0.05, Ingredients = 0.05, _spelltome = 0.05 },
	['mage']                   = { _enchanted = 0.05, Potions = 0.05, _spelltome = 0.05 },
	['mage service']           = { Potions = 0.1, _enchanted = 0.1, _spelltome = 0.1 },
	['master-at-arms']         = { Weapon = 0.1, Armor = 0.1 },
	['merchant']               = false, -- fallback
	['miner']                  = { Misc = 0.05 },
	['monk']                   = { Potions = 0.05, _spelltome = 0.05 },
	['monk service']           = { Potions = 0.1, _spelltome = 0.1 },
	['necromancer']            = { _soulgem = 0.15, Ingredients = 0.1, _spelltome = 0.1 },
	['nightblade']             = { Potions = 0.05, Picks = 0.05, _spelltome = 0.05 },
	['nightblade service']     = { Potions = 0.1, Picks = 0.1, _spelltome = 0.1 },
	['noble']                  = { Clothing = 0.05, Books = 0.05, _spelltome = 0.05 },
	['ordinator']              = { Weapon = 0.05, Armor = 0.05, _spelltome = 0.05 },
	['ordinator guard']        = { Weapon = 0.05, Armor = 0.05, _spelltome = 0.05 },
	['pauper']                 = false,
	['pawnbroker']             = false, -- fallback
	['pilgrim']                = { Books = 0.05, Potions = 0.05, _spelltome = 0.05 },
	['priest']                 = { Books = 0.05, Potions = 0.05, Ingredients = 0.05, _spelltome = 0.05 },
	['priest service']         = { Books = 0.1, Potions = 0.1, Ingredients = 0.1, _spelltome = 0.1 },
	['publican']               = { _food = 0.2 },
	['rogue']                  = { Picks = 0.05, Weapon = 0.05 },
	['savant']                 = { Books = 0.05, _spelltome = 0.05 },
	['savant service']         = { Books = 0.2, _spelltome = 0.2 },
	['scout']                  = { Weapon = 0.05, Lights = 0.05 },
	['sharpshooter']           = { Weapon = 0.1 },
	['shipmaster']             = { Misc = 0.05 },
	['slave']                  = false,
	['smith']                  = { Armor = 0.1, Weapon = 0.1, RepairItems = 0.1 },
	['smuggler']               = { Picks = 0.1, Probes = 0.1 },
	['sorcerer']               = { _enchanted = 0.05, _soulgem = 0.05, _spelltome = 0.05 },
	['sorcerer service']       = { _enchanted = 0.1, _soulgem = 0.1, _spelltome = 0.1 },
	['spellsword']             = { _enchanted = 0.05, Weapon = 0.05, _spelltome = 0.05 },
	['thief']                  = { Picks = 0.05, Probes = 0.05 },
	['thief service']          = { Picks = 0.15, Probes = 0.15 },
	['trader']                 = false, -- fallback
	['trader service']         = false, -- fallback
	['warlock']                = { _enchanted = 0.05, Potions = 0.05, _spelltome = 0.05 },
	['warrior']                = { Weapon = 0.05, Armor = 0.05 },
	['wise woman']             = { Potions = 0.05, Ingredients = 0.05, _spelltome = 0.05 },
	['wise woman service']     = { Potions = 0.15, Ingredients = 0.15, _spelltome = 0.15 },
	['witch']                  = { Potions = 0.05, Ingredients = 0.05, _soulgem = 0.05, _spelltome = 0.05 },
	['witchhunter']            = { _enchanted = 0.05, Weapon = 0.05, _spelltome = 0.05 },
	
	-- Bloodmoon
	['caretaker']              = { Misc = 0.05, RepairItems = 0.05 },
	['gardener']               = { Ingredients = 0.1, _spelltome = 0.05 },
	['journalist']             = { Books = 0.05, _spelltome = 0.05 },
	['king']                   = false,
	['queen mother']           = false,
	['shaman']                 = { Potions = 0.15, Ingredients = 0.15, _spelltome = 0.15 },
	
	-- TR
	['t_glb_apothecaryservice'] = { Apparatus = 0.1, Potions = 0.1, Ingredients = 0.1, _spelltome = 0.1 },
	['t_glb_artist']           = { Misc = 0.05, Books = 0.05, _spelltome = 0.05 },
	['t_glb_astrologer']       = { Books = 0.1, _enchanted = 0.05, _spelltome = 0.1 },
	['t_glb_baker']            = { _food = 0.2 },
	['t_glb_banker']           = { Misc = 0.05 },
	['t_glb_barrister']        = { Books = 0.05, _spelltome = 0.05 },
	['t_glb_bookseller']       = { Books = 0.2, _spelltome = 0.2 },
	['t_glb_broker']           = false, -- fallback
	['t_glb_carpenter']        = { RepairItems = 0.1, Misc = 0.05 },
	['t_glb_commoner']         = false,
	['t_glb_cook']             = { _food = 0.2 },
	['t_glb_courtesan']        = { Clothing = 0.05, Potions = 0.05 },
	['t_glb_dockworker']       = { Misc = 0.05 },
	['t_glb_fisherman']        = { _food = 0.1 },
	['t_glb_fletcher']         = { Weapon = 0.15 },
	['t_glb_healer']           = { Potions = 0.15, Ingredients = 0.15, _spelltome = 0.15 },
	['t_glb_jeweler']          = { Clothing = 0.15, _spelltome = 0.05 },
	['t_glb_lampknight']       = { Lights = 0.15 },
	['t_glb_miner']            = { Misc = 0.05 },
	['t_glb_naturalist']       = { Ingredients = 0.15, _spelltome = 0.05 },
	['t_glb_pauper']           = false,
	['t_glb_potter']           = { Misc = 0.1 },
	['t_glb_priest']           = { Books = 0.1, Potions = 0.1, Ingredients = 0.1, _spelltome = 0.1 },
	['t_glb_publican']         = { _food = 0.2 },
	['t_glb_ratcatcher']       = { Misc = 0.05 },
	['t_glb_sailor']           = { Misc = 0.05 },
	['t_glb_savant']           = { Books = 0.05, _spelltome = 0.05 },
	['t_glb_scout']            = { Weapon = 0.05, Lights = 0.05 },
	['t_glb_scribe']           = { Books = 0.15, _spelltome = 0.15 },
	['t_glb_trader']           = false, -- fallback
	['t_glb_traderservice']    = false, -- fallback
	
	-- SHOTN
	['t_mw_catcatcher']        = { Misc = 0.05 },
	['t_mw_riverstriderservice'] = { Misc = 0.05 },
	['t_sky_clever-man']       = { Potions = 0.15, Ingredients = 0.15, _spelltome = 0.15 },
	['t_sky_jarl']             = { Weapon = 0.05, Armor = 0.05 },
	['t_sky_king']             = false,
	
	-- OAAB
	['ab_author']              = { Books = 0.15, _spelltome = 0.15 },
	['ab_beggar']              = false,
	['ab_butcher']             = { _food = 0.2 },
	['ab_clerk']               = { Books = 0.05, Misc = 0.05, _spelltome = 0.05 },
	['ab_eggminer']            = { _food = 0.05 },
	['ab_foreman']             = { Misc = 0.05, RepairItems = 0.05 },
	['ab_grocer']              = { _food = 0.15, Ingredients = 0.1 },
	['ab_painter']             = { Misc = 0.05, _spelltome = 0.05 },
	['ab_sailor']              = { Misc = 0.05 },
	['ab_sculptor']            = { Misc = 0.1, _spelltome = 0.05 },
	['ab_surgeon']             = { Potions = 0.15, Ingredients = 0.15 },
	['ab_weaver']              = { Clothing = 0.15 },
}
 
local function matchesSpecialKey(key, item)
	if key == '_food' then
		return FOOD_IDS[item.recordId:lower()] or false
	end
	if key == '_soulgem' then
		return SOULGEM_IDS[item.recordId:lower()] or false
	end
	if key == '_spelltome' then -- TODO: shortcircuit to save memory
		return SPELLTOMES[item.recordId:lower()] or false
	end
	if key == '_enchanted' then
		local rec = item.type.record(item)
		return rec.enchant and rec.enchant ~= '' or false
	end
	return false
end
 
local SERVICE_FALLBACK_BONUS = 0.05
 
-- specialization modifier for a merchant, returns modifier and label string or nil
function Specialization.getModifier(merchant, item)
	if not types.NPC.objectIsInstance(merchant) then
		return 0, nil
	end
	
	local record = types.NPC.record(merchant)
	local classId = record.class and record.class:lower() or ''
	
	local bonuses = CLASS_BONUS[classId]
	
	if bonuses == false then
		return 0, nil
	end
	
	if bonuses then
		local itemCat = getItemCategory(item)
		local best = 0
		local label = nil
		
		for key, bonus in pairs(bonuses) do
			local matches = false
			-- underscore keys: special checks
			if key:sub(1, 1) == '_' then
				matches = matchesSpecialKey(key, item)
			else
				matches = (key == itemCat)
			end
			if matches and bonus > best then
				best = bonus
				label = record.class
			end
		end
		
		if best > 0 then
			return best, label
		end
		return 0, nil
	end
	
	-- fallback
	local services = record.servicesOffered
	if services then
		local itemCat = getItemCategory(item)
		if itemCat and services[itemCat] then
			return SERVICE_FALLBACK_BONUS, nil
		end
		if services.MagicItems then
			local rec = item.type.record(item)
			if rec.enchant and rec.enchant ~= '' then
				return SERVICE_FALLBACK_BONUS, nil
			end
		end
	end
	
	return 0, nil
end
 
-- if playerMerc is high enough to see spec bonus
function Specialization.playerKnows()
	local threshold = S_KNOWS_SPECIALIZATION or 0
	if threshold <= 0 then return true end
	return self.type.stats.skills.mercantile(self).modified >= threshold
end
 
-- databases for other modules
Specialization.FOOD_IDS    = FOOD_IDS
Specialization.SOULGEM_IDS = SOULGEM_IDS
Specialization.SPELLTOMES  = SPELLTOMES
 
return Specialization