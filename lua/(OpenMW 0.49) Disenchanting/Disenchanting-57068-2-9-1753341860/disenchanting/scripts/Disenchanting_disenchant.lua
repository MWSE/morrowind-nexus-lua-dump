local types = require('openmw.types')
local core = require('openmw.core')
local MODNAME = "Disenchanting"
local storage = require('openmw.storage')
local globalSection = storage.globalSection('Settings'..MODNAME)



-- debug bestInSlot:
--for cat, max in pairs(bestInSlot) do
--	local dash = cat:find("-",-3)
--	local subTypeId = tonumber(cat:sub(dash+1,-1))
--	local typeName = cat:sub(1,dash-1)
--	local subTypeName = ""
--	local recordIdWithMax = ""
--	
--	for name, id in pairs(types[typeName].TYPE) do
--		if id == subTypeId then
--			subTypeName = name
--		end
--	end
--	for _, record in pairs(types[typeName].records) do
--		if record.id:sub(1, #"Generated") ~= "Generated" and not record.id:lower():find("_uni") and not record.enchant and record.enchantCapacity == max then
--			recordIdWithMax = record.id
--		end
--	end
--	print("BiS "..typeName.."-"..subTypeName.." = ".. max.." ("..recordIdWithMax..")")
--end

local function getEnchantPoints(enchantment, precise)
    --if (mEffectList.mList.empty())
    --    // No effects added, cost = 0
    --    return 0;

    --const MWWorld::ESMStore& store = *MWBase::Environment::get().getESMStore();
    --const float fEffectCostMult = store.get<ESM::GameSetting>().find("fEffectCostMult")->mValue.getFloat();
    --const float fEnchantmentConstantDurationMult
    --    = store.get<ESM::GameSetting>().find("fEnchantmentConstantDurationMult")->mValue.getFloat();
	local fEffectCostMult = core.getGMST("fEffectCostMult")
	local fEnchantmentConstantDurationMult = core.getGMST("fEnchantmentConstantDurationMult")
    local enchantmentCost = 0
    local cost = 0
    for _, effect in pairs(enchantment.effects) do
        local baseCost = effect.effect.baseCost --(store.get<ESM::MagicEffect>().find(effect.mData.mEffectID))->mData.mBaseCost;

        local magMin = math.max(1, effect.magnitudeMin) --std::max(1, effect.mData.mMagnMin);
        local magMax = math.max(1, effect.magnitudeMax) --std::max(1, effect.mData.mMagnMax);
        local area = math.max(1, effect.area) --std::max(1, effect.mData.mArea);
        local duration = effect.duration --static_cast<float>(effect.mData.mDuration);
        if enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then  --if (mCastStyle == ESM::Enchantment::ConstantEffect)
            duration = fEnchantmentConstantDurationMult;
		end
        cost = cost + ((magMin + magMax) * duration + area) * baseCost * fEffectCostMult * 0.05 --cost += ((magMin + magMax) * duration + area) * baseCost * fEffectCostMult * 0.05f;

        cost = math.max(1, cost) --cost = std::max(1.f, cost);

		if effect.range == core.magic.RANGE.Target then	--if (effect.mData.mRange == ESM::RT_Target)
			cost = cost * 1.5 -- cost *= 1.5;
		end

        enchantmentCost = enchantmentCost + (precise and cost or math.floor(cost)) --enchantmentCost += precise ? cost : std::floor(cost);
    end

    return enchantmentCost;
end


local soulgems = {}
for _, t in pairs{
	{"Misc_SoulGem_Petty"},
	{"Misc_SoulGem_Lesser"},
	{"Misc_SoulGem_Common"},
	{"Misc_SoulGem_Greater"},
	{"Misc_SoulGem_Grand"},
	{"Misc_SoulGem_Giant_DE",600},
	{"Misc_SoulGem_Titanic_DE",1800},
	{"Misc_SoulGem_Cosmic_DE",5400},
	{"Misc_SoulGem_Ultimate_DE",16200},
} do
	local gem = t[1]:lower()
	local value = t[2]
	if types.Miscellaneous.record(gem) then
		if not value then
			value = types.Miscellaneous.record(gem).value
		end
		if types.Miscellaneous.records[gem.."_worthless"] then
			gem = gem.."_worthless"
		end
		table.insert(soulgems, {name = gem, value = value})
	end
end

local function f1(number)
	local formatted = string.format("%.1f",number)
	if formatted:sub(#formatted,#formatted) == "0" then
		return math.floor(number)
	end
	return formatted
end

return function(item, preview, player)
	local ret = {}
	local record = item.type.record(item)
	local enchantment = item and (record.enchant or record.enchant ~= "" and record.enchant )
	local enchantmentRecord = core.magic.enchantments.records[enchantment]
	if not enchantmentRecord then return nil end
	ret.effects = {}
	for _, eff in pairs(enchantmentRecord.effects) do
		if eff.id then
			table.insert(ret.effects, {id = eff.id, icon = eff.effect.icon})
		end
	end
	local enchPoints = getEnchantPoints(enchantmentRecord, false)
	
	local template = item.type.record(item)
	local oldCapacity = template.enchantCapacity/0.1*core.getGMST("FEnchantmentMult")
	local buggyApiBestMax = bestInSlot[tostring(item.type).."-"..template.type] or 99999999
	local bestMax = buggyApiBestMax / 0.1 * core.getGMST("FEnchantmentMult")
	
	if preview then
		local previewNewCapacity = oldCapacity * globalSection:get("CAPACITY_MULT") + math.min(2*oldCapacity, enchPoints) * globalSection:get("CAPACITY_FROM_ENCHANTMENT")
		print("old capacity: ", f1(oldCapacity), "*"..globalSection:get("CAPACITY_MULT"))
		print("+ old enchantment magnitude: ", enchPoints > 2*oldCapacity and (f1(enchPoints).." (clamped to "..f1(2*oldCapacity)..")") or f1(enchPoints), "*"..globalSection:get("CAPACITY_FROM_ENCHANTMENT"))
		print("= "..f1(previewNewCapacity))
		if enchPoints / 7 > previewNewCapacity then
			previewNewCapacity = enchPoints/7
			print("too low, using 1/7 of enchantment magnitude instead: "..f1(previewNewCapacity))
		end
		if previewNewCapacity > bestMax * globalSection:get("BEST_IN_SLOT_CAP") then -- buggyApiCapacity
			local bestOtherItem = ""
			for _, record in pairs(item.type.records) do
				if record.id:sub(1, #"Generated") ~= "Generated" and not record.id:lower():find("_uni") and not record.enchant and record.enchantCapacity == buggyApiBestMax then
					bestOtherItem = record.id
					break
				end
			end
			print("higher than BiS enchantable: "..bestOtherItem.." has "..f1(bestMax).." (* "..globalSection:get("BEST_IN_SLOT_CAP").." = "..f1(bestMax * globalSection:get("BEST_IN_SLOT_CAP"))..")")
		end
		local previewInternalCapacity = previewNewCapacity/core.getGMST("FEnchantmentMult")
		if types.Armor.objectIsInstance(item) and previewInternalCapacity > 2^30 then
			print("armor integer overflow, capacity capped to ".. math.floor(2^30*core.getGMST("FEnchantmentMult")))
		elseif not types.Armor.objectIsInstance(item) and previewInternalCapacity > 2^16-1 then
			print("integer overflow, capacity capped to ".. math.floor((2^16-1)*core.getGMST("FEnchantmentMult")))
		end
	end
	
	local newCapacity = math.max(enchPoints / 7, oldCapacity * globalSection:get("CAPACITY_MULT") + math.min(2*oldCapacity, enchPoints) * globalSection:get("CAPACITY_FROM_ENCHANTMENT"))
	
	newCapacity = math.min(newCapacity, bestMax * globalSection:get("BEST_IN_SLOT_CAP"))
	local realInternalCapacity = math.floor(newCapacity/core.getGMST("FEnchantmentMult"))
	if types.Armor.objectIsInstance(item) and realInternalCapacity > 2^30 then
		realInternalCapacity = math.floor(2^30*core.getGMST("FEnchantmentMult"))
	elseif not types.Armor.objectIsInstance(item) and realInternalCapacity > 2^16-1 then
		realInternalCapacity = math.floor((2^16-1)*core.getGMST("FEnchantmentMult"))
	end
	local buggyApiCapacity =  math.floor(realInternalCapacity *0.1)
	
	ret.newCapacity = math.floor(newCapacity)
	ret.enchPoints = enchPoints
	ret.value = template.value * globalSection:get("VALUE_MULT")
	
	if not preview then
		local weaponOrArmor = types.Weapon.objectIsInstance(item) or types.Armor.objectIsInstance(item)
		local condition = nil
		if weaponOrArmor then
			condition = types.Item.itemData(item).condition
		end
		
		local tbl = {name = "Drained "..item.type.record(item).name,template = template, enchant = 1, value = ret.newValue, enchantCapacity = buggyApiCapacity}
		
		if globalSection:get("VALUE_MULT") > 0 then
			local recordDraft = item.type.createRecordDraft(tbl)
			local newRecord = world.createRecord(recordDraft)
			local newObject = world.createObject(newRecord.id)
			if condition then
				types.Item.itemData(newObject).condition = condition
			end
			newObject:moveInto(player)
		end
		item:remove(1)
	end
	
	if globalSection:get("RECOUPED_SOUL") > 0 and enchPoints * globalSection:get("RECOUPED_SOUL") >= globalSection:get("MINIMUM_RECOUPED_SOUL") then
		local soulPoints = enchPoints * globalSection:get("RECOUPED_SOUL")
		local fSoulGemMult = core.getGMST("fSoulGemMult")
		local fittingCreature = creatures[1][1]
		local soulSize = 0
		for a,b in ipairs(creatures) do
			local creatureSoul = b[2]
			local creature = b[1]
			if creatureSoul <= soulPoints and creatureSoul < (soulgems[#soulgems].value * fSoulGemMult*1.25) or soulSize == 0 then
				fittingCreature = creature
				soulSize = creatureSoul
			elseif math.abs(creatureSoul - soulPoints) < (creatureSoul - soulSize)*0.5 then
				fittingCreature = creature
				soulSize = creatureSoul
			else
				--print(creature,creatureSoul,"too big, using ", soulSize)
				break
			end
		end	
		local fittingSoulgem = soulgems[#soulgems].name
		for a,t in ipairs(soulgems) do
			if t.value * fSoulGemMult >= soulSize then
				fittingSoulgem = t.name
				break
			end
		end
		ret.soulgem = fittingSoulgem
		ret.soul = fittingCreature
		ret.soulSize = soulSize
		if not preview then
			local soulgem = world.createObject(fittingSoulgem)
			types.Item.itemData(soulgem).soul = fittingCreature
			soulgem:moveInto(player)
		end
	end
	return ret
end

