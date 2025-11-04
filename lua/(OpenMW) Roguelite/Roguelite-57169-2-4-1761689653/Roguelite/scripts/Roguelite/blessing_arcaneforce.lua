local fFatigueBase = core.getGMST("fFatigueBase") --static const float fFatigueBase = gmst.find("fFatigueBase")->mValue.getFloat();
local fFatigueMult = core.getGMST("fFatigueMult") --static const float fFatigueMult = gmst.find("fFatigueMult")->mValue.getFloat();

local casting = false
local frame = 0
local startedCasting = 0
local stoppedCasting = 0
local lastMagicka = -9000

local function onFrame()
	lastMagicka = types.Actor.stats.dynamic.magicka(self).current
end
table.insert(onFrameFunctions, onFrame)

local spellDB = {}

local function checkSpell(spell)
	local spellId = spell.id
	if not spellDB[spellId] then
		spellDB[spellId] = {}
		local s = spellDB[spellId]
		s.schools = {}
		s.calculatedCost = 0
		s.autoCalculated = spell.autocalcFlag
		s.isSpell = spell.type == core.magic.SPELL_TYPE.Spell
		local playerSpell = spellId:sub(1,9) == "Generated"
		for _,effect in pairs(spell.effects) do
			local school = effect.effect.school
			local hasMagnitude = effect.effect.hasMagnitude
			local hasDuration = effect.effect.hasDuration
			local appliedOnce = effect.effect.isAppliedOnce
			local minMagn = hasMagnitude and effect.magnitudeMin or 1;
			local maxMagn = hasMagnitude and effect.magnitudeMax or 1;
			--if (method == EffectCostMethod::PlayerSpell || method == EffectCostMethod::GameSpell)
				minMagn = math.max(1, minMagn);
				maxMagn = math.max(1, maxMagn);
			-- }
			local duration = hasDuration and effect.duration or 1;
			if (not appliedOnce) then
				duration = math.max(1, duration);
			end
			local fEffectCostMult =  core.getGMST("fEffectCostMult")
			--local iAlchemyMod = core.getGMST("iAlchemyMod") 
	
			local durationOffset = 0;
			local minArea = 0;
			local costMult = fEffectCostMult;
			if playerSpell then
				durationOffset = 1;
				minArea = 1;
			end -- elseif GamePotion
			--	minArea = 1;
			--	costMult = iAlchemyMod;
			-- end
	
			local x = 0.5 * (minMagn + maxMagn);
			x = x * (0.1 * effect.effect.baseCost);
			x = x * (durationOffset + duration);
			x = x + (0.05 * math.max(minArea, effect.area) * effect.effect.baseCost);
	
			x = x * costMult;
			if effect.range == core.magic.RANGE.Target then--  if (effect.mData.mRange == ESM::RT_Target)
				x = x * 1.5
			end
			x= math.max(0,x)
			s.schools[school] = (s.schools[school] or 0) + x
			s.calculatedCost = s.calculatedCost + x
		end
		if spell.autocalcFlag then
			s.cost = math.floor(s.calculatedCost+0.5)
		else
			s.cost = math.floor(spell.cost+0.5)
		end
	end
	return spellDB[spellId]
end



local function getCastChance(spell)
	local cost = checkSpell(spell).cost
	--const ESM::Spell* spell, const MWWorld::Ptr& actor, ESM::RefId* effectiveSchool, bool cap, bool checkMagicka)
	--{
	--// NB: Base chance is calculated here because the effective school pointer must be filled
	--float baseChance = calcSpellBaseSuccessChance(spell, actor, effectiveSchool);
	--
	
	local godmode = debug.isGodMode() --bool godmode = actor == getPlayer() && MWBase::Environment::get().getWorld()->getGodModeState();
	
	if not godmode then --if (stats.getMagicEffects().getOrDefault(ESM::MagicEffect::Silence).getMagnitude() && !godmode)
		if types.Actor.activeEffects(self):getEffect("silence").magnitude > 0 then
			return 0 --return 0;
		end			
	end
	
	if spell.type == core.magic.SPELL_TYPE.Power then --if (spell->mData.mType == ESM::Spell::ST_Power)
		if types.Actor.activeSpells(self):canUsePower(spell) then --return stats.getSpells().canUsePower(spell) ? 100 : 0;
			return 1
		else
			return 0
		end
	end
	
	if godmode then --if(godmode)
		return 1 --return 100;
	end
	
	if spell.type ~= core.magic.SPELL_TYPE.Spell then --if (spell->mData.mType != ESM::Spell::ST_Spell)
		return 1 --return 100;
	end
	
	--if cost > lastMagicka then --if (checkMagicka && calcSpellCost(*spell) > 0 && stats.getMagicka().getCurrent() < calcSpellCost(*spell))
	--	return 0 --return 0;
	--end
	
	if spell.alwaysSucceedFlag then --if (spell->mData.mFlags & ESM::Spell::F_Always)
		return 1 --return 100;
	end
	
	--float calcSpellBaseSuccessChance(const ESM::Spell* spell, const MWWorld::Ptr& actor, ESM::RefId* effectiveSchool)
	--// Morrowind for some reason uses a formula slightly different from magicka cost calculation
	local y = 2000000000 --float y = std::numeric_limits<float>::max();
	local lowestSkill = 0 --float lowestSkill = 0;
	
	for _,effect in pairs(spell.effects) do --for (const ESM::IndexedENAMstruct& effect : spell->mEffects.mList)
		local x = effect.duration or 0 --float x = static_cast<float>(effect.mData.mDuration);
	
		
		
		if effect.effect.isAppliedOnce then --if (!(magicEffect->mData.mFlags & ESM::MagicEffect::AppliedOnce))
			x = math.max(1,x) --x = std::max(1.f, x);
		end
		
		x = x * 0.1 * effect.effect.baseCost -- x *= 0.1f * magicEffect->mData.mBaseCost;
		x = x * 0.5 * (effect.magnitudeMin + effect.magnitudeMax) --x *= 0.5f * (effect.mData.mMagnMin + effect.mData.mMagnMax);
		x = x + effect.area * 0.05 * effect.effect.baseCost --x += effect.mData.mArea * 0.05f * magicEffect->mData.mBaseCost;
		if effect.range == core.magic.RANGE.Target then --if (effect.mData.mRange == ESM::RT_Target)
			x = x * 1.5 --x *= 1.5f;
		end
		local fEffectCostMult = core.getGMST("fEffectCostMult") --static const float fEffectCostMult = MWBase::Environment::get().getESMStore()->get<ESM::GameSetting>().find("fEffectCostMult")->mValue.getFloat();
		x = x * fEffectCostMult --x *= fEffectCostMult;
	
		local s = 2 * types.NPC.stats.skills[effect.effect.school](self).base --float s = 2.0f * actor.getClass().getSkill(actor, magicEffect->mData.mSchool);
		if s - x < y then --if (s - x < y)
			y = s - x --y = s - x;
			--if (effectiveSchool)
			--	*effectiveSchool = magicEffect->mData.mSchool;
			lowestSkill = s --lowestSkill = s;
		end
	end
	
	local actorWillpower = types.Player.stats.attributes["willpower"](self).modified --float actorWillpower = stats.getAttribute(ESM::Attribute::Willpower).getModified();
	local actorLuck = types.Player.stats.attributes["luck"](self).base --float actorLuck = stats.getAttribute(ESM::Attribute::Luck).getModified();
	
	local castChance = lowestSkill - cost + 0.2 * actorWillpower + 0.1 * actorLuck --float castChance = (lowestSkill - calcSpellCost(*spell) + 0.2f * actorWillpower + 0.1f * actorLuck);
	
	--return castChance;
	--float castBonus = -stats.getMagicEffects().getOrDefault(ESM::MagicEffect::Sound).getMagnitude();
	local castBonus =  types.Actor.activeEffects(self):getEffect("sound").magnitude
	castChance = castChance + castBonus --float castChance = baseChance + castBonus;
	--castChance *= stats.getFatigueTerm();
	local max = types.Actor.stats.dynamic.fatigue(self).base --float max = getFatigue().getModified();
	local current = types.Actor.stats.dynamic.fatigue(self).current --float current = getFatigue().getCurrent();
	local normalised = max == 0 and 1 or math.max(0, current / max) --float normalised = std::floor(max) == 0 ? 1 : std::max(0.0f, current / max);
	local fatigueTerm = fFatigueBase - fFatigueMult * (1 - normalised)
	castChance = castChance * fatigueTerm
	--
	--if (cap)
	--	return std::clamp(castChance, 0.f, 100.f);
	--
	--return std::max(castChance, 0.f);
	return math.min(1, castChance/100)
end


I.AnimationController.addTextKeyHandler('', function(groupname, key)
	if saveData.blessings and saveData.blessings.arcaneforce then
		if groupname == "spellcast" then
			if key == "self start" or key == "touch start" or key == "target start" then
				castedSpell = Player.getSelectedSpell(self)
				if castedSpell then
					if not debug.isGodMode() and types.Actor.activeEffects(self):getEffect("silence").magnitude <= 0 and castedSpell.type ~= core.magic.SPELL_TYPE.Power and types.Actor.stats.dynamic.magicka(self).current < lastMagicka then
						local castChance = getCastChance(castedSpell)
						if castChance < 1 then
							local cost = checkSpell(castedSpell).cost
							local missingCastChance = 1-castChance
							local additionalCost = 5 * missingCastChance + (cost * missingCastChance / 1.55)
							types.Actor.stats.dynamic.magicka(self).current = types.Actor.stats.dynamic.magicka(self).current - additionalCost
							types.Actor.spells(self):add("roguelite_soundhack")
						end
					end
				end
			elseif key == "self stop" or key == "touch stop" or key == "target stop" then
				types.Actor.spells(self):remove("roguelite_soundhack")
			--	castedSpell = nil
			--	casting = false
			--	stoppedCasting = frame
			end
		end
	end
	--print(groupname,key)
end)
