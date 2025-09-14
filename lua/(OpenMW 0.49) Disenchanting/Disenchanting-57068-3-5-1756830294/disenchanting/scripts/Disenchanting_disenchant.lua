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

function getMaxEnchantmentCharge(enchantment)
	if not enchantment.autocalcFlag and enchantment.charge ~= 0 then
		return enchantment.charge
	end
	local cost = 0
	local fEnchantmentConstantDurationMult = core.getGMST("fEnchantmentConstantDurationMult")
	for _, effect in pairs(enchantment.effects) do
		-- note: EffectCostMethod = EffectCostMethod::GameEnchantment
	
		-- float calcEffectCost(
        -- const ESM::ENAMstruct& effect, const ESM::MagicEffect* magicEffect, const EffectCostMethod method)
		-- {
        -- const MWWorld::ESMStore& store = *MWBase::Environment::get().getESMStore();
		--  if (!magicEffect)
		-- magicEffect = store.get<ESM::MagicEffect>().find(effect.mEffectID);
		local hasMagnitude = effect.effect.hasMagnitude -- bool hasMagnitude = !(magicEffect->mData.mFlags & ESM::MagicEffect::NoMagnitude);
        local hasDuration = effect.effect.hasDuration -- bool hasDuration = !(magicEffect->mData.mFlags & ESM::MagicEffect::NoDuration);
        local appliedOnce = effect.effect.isAppliedOnce -- bool appliedOnce = magicEffect->mData.mFlags & ESM::MagicEffect::AppliedOnce;
		local minMagn = hasMagnitude and effect.magnitudeMin or 1; -- int minMagn = hasMagnitude ? effect.mMagnMin : 1;
		local maxMagn = hasMagnitude and effect.magnitudeMax or 1; -- int maxMagn = hasMagnitude ? effect.mMagnMax : 1;
		--if (method == EffectCostMethod::PlayerSpell || method == EffectCostMethod::GameSpell)
        --{
        --    minMagn = std::max(1, minMagn);
        --    maxMagn = std::max(1, maxMagn);
        --}
		local duration = hasDuration and effect.duration or 1; -- int duration = hasDuration ? effect.mDuration : 1;
		if not appliedOnce then -- if (!appliedOnce)
			duration = math.max(1, duration) -- duration = std::max(1, duration);
		end
		-- NEW:
		if enchantment.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then  --if (mCastStyle == ESM::Enchantment::ConstantEffect)
            duration = fEnchantmentConstantDurationMult;
		end
		local fEffectCostMult = core.getGMST("fEffectCostMult") -- static const float fEffectCostMult = store.get<ESM::GameSetting>().find("fEffectCostMult")->mValue.getFloat();
		-- static const float iAlchemyMod = store.get<ESM::GameSetting>().find("iAlchemyMod")->mValue.getFloat();
		local durationOffset = 0;            -- int durationOffset = 0;
        local minArea = 0;                   -- int minArea = 0;
        local costMult = fEffectCostMult;  -- float costMult = fEffectCostMult;
		-- if (method == EffectCostMethod::PlayerSpell)
        -- {
        --     durationOffset = 1;
        --     minArea = 1;
        -- }
        -- else if (method == EffectCostMethod::GamePotion)
        -- {
        --     minArea = 1;
        --     costMult = iAlchemyMod;
        -- }
		local x = 0.5 * (minMagn + maxMagn);                                          -- float x = 0.5 * (minMagn + maxMagn);
		x = x * (0.1 * effect.effect.baseCost);                                      -- x *= 0.1 * magicEffect->mData.mBaseCost;
		x = x * (durationOffset + duration);                                               -- x *= durationOffset + duration;
		x = x + (0.05 * math.max(minArea, effect.area) * effect.effect.baseCost);   -- x += 0.05 * std::max(minArea, effect.mArea) * magicEffect->mData.mBaseCost;
		
		if effect.range == core.magic.RANGE.Target then	--if (effect.mData.mRange == ESM::RT_Target)
			x = x * 1.5 -- effectCost *= 1.5;
		end
		x = math.floor(x * costMult + 0.5) -- round here i think (not 100% sure)
		cost = cost + x
		
	end
	
	if enchantment.type == core.magic.ENCHANTMENT_TYPE.CastOnce then
		cost = cost * core.getGMST("iMagicItemChargeOnce")
	elseif enchantment.type == 	core.magic.ENCHANTMENT_TYPE.CastOnUse then
		cost = cost * core.getGMST("iMagicItemChargeUse")
	elseif enchantment.type == 	core.magic.ENCHANTMENT_TYPE.CastOnStrike then
		cost = cost * core.getGMST("iMagicItemChargeStrike")
	elseif enchantment.type == 	core.magic.ENCHANTMENT_TYPE.ConstantEffect then
		cost = cost * core.getGMST("iMagicItemChargeConst")
	end
	return cost or 0
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
		--if types.Miscellaneous.records[gem.."_worthless"] then
		--	gem = gem.."_worthless"
		--end
		table.insert(soulgems, {id = gem, value = value})
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
	if preview then
		print("-------")
	end
	local maxCharges = getMaxEnchantmentCharge(enchantmentRecord)
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
		print("+ old enchantment magnitude: ", enchPoints > 2*oldCapacity and (f1(enchPoints).." -> clamped to "..f1(oldCapacity).."*2") or f1(enchPoints), "*"..globalSection:get("CAPACITY_FROM_ENCHANTMENT"))
		print("= "..f1(previewNewCapacity))
		if enchPoints * globalSection:get("CAPACITY_CAP_FOR_TRASH") > previewNewCapacity then
			previewNewCapacity = enchPoints * globalSection:get("CAPACITY_CAP_FOR_TRASH")
			print("too low, using "..f1(globalSection:get("CAPACITY_CAP_FOR_TRASH")*100).."% of enchantment magnitude instead: "..f1(previewNewCapacity))
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
	
	local newCapacity =  oldCapacity * globalSection:get("CAPACITY_MULT") + math.max(enchPoints * globalSection:get("CAPACITY_CAP_FOR_TRASH"), math.min(2*oldCapacity, enchPoints)) * globalSection:get("CAPACITY_FROM_ENCHANTMENT")
	
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
		
		local tbl = {name = "Drained "..item.type.record(item).name.." ["..math.floor(newCapacity).."]",template = template, enchant = 1, value = ret.value, enchantCapacity = buggyApiCapacity}
		
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
	
	local soulPoints = enchPoints * globalSection:get("RECOUPED_SOUL")
	if soulPoints > maxCharges and preview then
		print("Capping soul gem because enchant is bigger than charges: "..soulPoints.." > "..maxCharges)
	end
	soulPoints = math.min(maxCharges, soulPoints)
	
	if soulPoints >= globalSection:get("MINIMUM_RECOUPED_SOUL") then
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
		local availableSoulgems = {}
		local REQUIRE_EMPTY = globalSection:get("REQUIRE_EMPTY_SOULGEM")
		if REQUIRE_EMPTY then
			for a,b in pairs(types.Actor.inventory(player):getAll()) do
				if b.recordId:sub(1,#"misc_soulgem_") == "misc_soulgem_" and not types.Item.itemData(b).soul then
					availableSoulgems[b.recordId] = b
				end
			end
		end
		local smallestAvailableSoulgem = nil
		local fittingSoulgem = soulgems[#soulgems].id
		for a,t in ipairs(soulgems) do
			if REQUIRE_EMPTY and availableSoulgems[t.id] then
				smallestAvailableSoulgem = t.id
			end
			if t.value * fSoulGemMult >= soulSize then
				fittingSoulgem = t.id
				break
			end
		end
		if REQUIRE_EMPTY then
			if not smallestAvailableSoulgem then
				return ret
			end
			fittingSoulgem = smallestAvailableSoulgem
			local gemValue = types.Miscellaneous.records[smallestAvailableSoulgem].value
			local gemCapacity = gemValue * fSoulGemMult
			if preview then
				print("smallest available: "..smallestAvailableSoulgem.." ("..gemCapacity..")")
			end
			if gemCapacity < soulSize*0.9 then
				soulPoints = gemCapacity
				fittingCreature = creatures[1][1]
				soulSize = 0
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
			end
		end
		if types.Miscellaneous.records[fittingSoulgem.."_worthless"] then
			fittingSoulgem = fittingSoulgem.."_worthless"
		end
		ret.soulgem = fittingSoulgem
		ret.soul = fittingCreature
		ret.soulSize = soulSize
		if not preview then
			local soulgem = world.createObject(fittingSoulgem)
			types.Item.itemData(soulgem).soul = fittingCreature
			soulgem:moveInto(player)
			if REQUIRE_EMPTY then
				availableSoulgems[smallestAvailableSoulgem]:remove(1)
			end
		end
	elseif preview then
		print("recouped soulgem too small ("..enchPoints.." * "..globalSection:get("RECOUPED_SOUL").." = "..soulPoints..")")
	end
	if preview then
		print("-------")
	end
	return ret
end

