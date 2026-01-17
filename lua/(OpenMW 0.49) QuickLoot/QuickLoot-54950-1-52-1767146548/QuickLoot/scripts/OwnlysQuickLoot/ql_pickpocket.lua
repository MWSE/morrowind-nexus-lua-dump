local core = require('openmw.core')
local types = require('openmw.types')
local ambient = require('openmw.ambient')
local getSound = require("scripts.OwnlysQuickLoot.ql_getSound")
local fFatigueBase = core.getGMST("fFatigueBase")
local fFatigueMult = core.getGMST("fFatigueMult")
local fPickPocketMod = core.getGMST("fPickPocketMod")
local iPickMinChance = core.getGMST("iPickMinChance")
local iPickMaxChance = core.getGMST("iPickMaxChance")
local maxAttempts = 5
-- global variable: "savegameData"

local qlpp = {}

local function updateFooterText(target)
	local attempts = savegameData[target.id] or 0

	if attempts > maxAttempts+200000 then
		qlpp.footerColor = util.color.rgb(0.85,0, 0)
		qlpp.footerText = "caught"
	elseif attempts >= maxAttempts then
		qlpp.footerColor = util.color.rgb(0.85,0, 0)
		qlpp.footerText = attempts.." / "..maxAttempts
	else
		qlpp.footerColor = nil
		qlpp.footerText = attempts.." / "..maxAttempts
	end
end

local function getFatigueTerm(target) -- float CreatureStats::getFatigueTerm() const
	local max = types.Actor.stats.dynamic.fatigue(target).base  --float max = getFatigue().getModified();
	local current = types.Actor.stats.dynamic.fatigue(target).current  --float current = getFatigue().getCurrent();
	local normalised = math.max(0,current/max) --float normalised = std::floor(max) == 0 ? 1 : std::max(0.0f, current / max);
	
	--const MWWorld::Store<ESM::GameSetting>& gmst
	--	= MWBase::Environment::get().getESMStore()->get<ESM::GameSetting>();
	
	--local fFatigueBase = core.getGMST("fFatigueBase") --static const float fFatigueBase = gmst.find("fFatigueBase")->mValue.getFloat();
	--local fFatigueMult = core.getGMST("fFatigueMult") --static const float fFatigueMult = gmst.find("fFatigueMult")->mValue.getFloat();
	
	return fFatigueBase - fFatigueMult * (1 - normalised);
end

--unused (in buildCache)
local function getPickpocketingChanceModifier(target, add) --float Pickpocket::getChanceModifier(const MWWorld::Ptr& ptr, float add)
		--NpcStats& stats = ptr.getClass().getNpcStats(ptr);
        local agility = types.Actor.stats.attributes.agility(target).modified  --float agility = stats.getAttribute(ESM::Attribute::Agility).getModified();
        local luck = types.Actor.stats.attributes.luck(target).modified        --float luck = stats.getAttribute(ESM::Attribute::Luck).getModified();
        local sneak = types.NPC.stats.skills.sneak(target).modified          --float sneak = static_cast<float>(ptr.getClass().getSkill(ptr, ESM::Skill::Sneak));
        return (add + 0.2 * agility + 0.1 * luck + sneak) *getFatigueTerm(target) --return (add + 0.2f * agility + 0.1f * luck + sneak) * stats.getFatigueTerm();
end

local function buildCache(self, target) --TODO
	qlpp.cache = {}
	
	local selfAgility = types.Actor.stats.attributes.agility(self).modified  
    local selfLuck = types.Actor.stats.attributes.luck(self).modified
    local selfSneak = types.NPC.stats.skills.sneak(self).modified
	local selfFatigueTerm = getFatigueTerm(self)
	qlpp.cache.selfChanceMod = function(add) return (add + 0.2 * selfAgility + 0.1 * selfLuck + selfSneak) * selfFatigueTerm end
	
	local targetAgility = types.Actor.stats.attributes.agility(target).modified  
    local targetLuck = types.Actor.stats.attributes.luck(target).modified
    local targetSneak = types.NPC.stats.skills.sneak(target).modified
	local targetFatigueTerm = getFatigueTerm(target)
	qlpp.cache.targetChanceMod = function(add) return (add + 0.2 * targetAgility + 0.1 * targetLuck + targetSneak) *targetFatigueTerm end
	qlpp.cache.pcSneak = types.NPC.stats.skills.sneak(self).modified
	qlpp.cache.benchResult = qlpp.calcChance(self,target,nil,true)
	qlpp.cache.lastUpdate = core.getRealTime()
	
	updateFooterText(target)
end

local function toInt(x)
    if x >= 0 then
        return math.floor(x)
    else
        return math.ceil(x - 1)
    end
end

qlpp.calcChance = function (self, target, item, benchmark) --bool Pickpocket::pick(const MWWorld::Ptr& item, int count)
	if not qlpp.cache then buildCache(self,target) end
	local valueTerm = 0
	if item then
		local count = item.count or 1
		local record = item.type.records[item.recordId]
		local stackValue = record.value * count --float stackValue = static_cast<float>(item.getClass().getValue(item) * count);
		
		--local fPickPocketMod = core.getGMST("fPickPocketMod")   -- float fPickPocketMod = MWBase::Environment::get()
																--	.getESMStore()
																--	->get<ESM::GameSetting>()
																--	.find("fPickPocketMod")
																--	->mValue.getFloat();
		valueTerm = 10*fPickPocketMod * stackValue --float valueTerm = 10 * fPickPocketMod * stackValue;
	end
    local x = qlpp.cache.selfChanceMod(0) --local x = getPickpocketingChanceModifier(self, 0) --float x = getChanceModifier(mThief);
    local y = qlpp.cache.targetChanceMod(valueTerm) --local y = getPickpocketingChanceModifier(target, valueTerm) --float y = getChanceModifier(mVictim, valueTerm);

    local t = 2 * x - y --float t = 2 * x - y;

    local pcSneak = qlpp.cache.pcSneak --types.NPC.stats.skills.sneak(self).modified --float pcSneak = static_cast<float>(mThief.getClass().getSkill(mThief, ESM::Skill::Sneak));
    --local iPickMinChance = core.getGMST("iPickMinChance")	--int iPickMinChance = MWBase::Environment::get()
															--.getESMStore()
															--->get<ESM::GameSetting>()
															--.find("iPickMinChance")
															--->mValue.getInteger();
    --local iPickMaxChance = core.getGMST("iPickMaxChance")	--int iPickMaxChance = MWBase::Environment::get()
															--.getESMStore()
															--->get<ESM::GameSetting>()
															--.find("iPickMaxChance")
															--->mValue.getInteger();

    --    auto& prng = MWBase::Environment::get().getWorld()->getPrng();
    --local roll = math.floor(100*math.random()) --int roll = Misc::Rng::roll0to99(prng);
	if benchmark then
		return t
	end
    if t < pcSneak / iPickMinChance then --if (t < pcSneak / iPickMinChance)
        return toInt(pcSneak / iPickMinChance) --return (roll > int(pcSneak / iPickMinChance));
    else
        local t = math.min(iPickMaxChance, t) --t = std::min(float(iPickMaxChance), t);
        return toInt(t) --return (roll > int(t));
    end
end

qlpp.stealItem = function (self, target, item)
	if not qlpp.cache then buildCache(self,target) end
	local chance = qlpp.calcChance(self, target, item)
	
	if (savegameData[target.id] or 0) >=maxAttempts then
		local record = 7
		if math.random() < 0.5 then
			record = 8
		end
		for j, dialogue in ipairs(core.dialogue.voice.records[record].infos) do
			if dialogue.filterActorRace==types.NPC.record(target).race and ((dialogue.filterActorGender=="female" and types.NPC.record(target).isMale==false) or (dialogue.filterActorGender=="male" and types.NPC.record(target).isMale==true))  then
				ambient.playSoundFile(dialogue.sound)
				break
			end
		end
		core.sendGlobalEvent("OwnlysQuickLoot_rotateNpc", {self, target})
		core.sendGlobalEvent("OwnlysQuickLoot_modDisposition", {self, target, -10})
		return
	end
	
	if math.random()*100 < chance then
		savegameData[target.id] = (savegameData[target.id] or 0) +1
		ambient.playSound(getSound(item))
		core.sendGlobalEvent("OwnlysQuickLoot_take",{self, target, item, true})
	else
		savegameData[target.id] = (savegameData[target.id] or 0) +1000000
		local price = item.type.record(item).value
		core.sendGlobalEvent("OwnlysQuickLoot_commitCrime",{self, target, 0})
	end
	updateFooterText(target)
end

qlpp.validateTarget = function(self, target, input)
	return target.type == types.NPC
	and not types.Actor.isDead(target)
	and types.Actor.getStance(target) == types.Actor.STANCE.Nothing
	and self.controls.sneak
end

qlpp.closeHud = function(self)
	qlpp.filteredItems = nil
	qlpp.message = nil
	qlpp.showContents = false
	qlpp.cache = nil
	qlpp.footerColor = nil
	qlpp.footerText = nil
end

qlpp.filterItems = function(self, target, containerItems )
	if not qlpp.cache then buildCache(self,target) end
	local tempContainerItems = {}
	local chance = qlpp.calcChance(self, target)
	if qlpp.showContents or chance >= 100 then
		qlpp.showContents = true
		
		
		if not qlpp.filteredItems then
			qlpp.undisplayedItems = 0
			qlpp.filteredItems = {}
			local selfSneak = types.NPC.stats.skills.sneak(self).modified
			for _, item in pairs(containerItems) do
				if not types.Actor.hasEquipped(target,item) then
					if math.random()<selfSneak/100 then
						table.insert(qlpp.filteredItems, item)
					else
						qlpp.undisplayedItems = qlpp.undisplayedItems + 1
					end
				end
			end
		end
		
		for _, item in pairs(containerItems) do
			if tableContains(qlpp.filteredItems, item) then
				table.insert(tempContainerItems, item)
			end
		end
		if qlpp.undisplayedItems > 0 then
			if #tempContainerItems == 0 then
				qlpp.message = qlpp.undisplayedItems.." item".. (qlpp.undisplayedItems > 1 and "s" or "")
			else
				qlpp.message = "and "..qlpp.undisplayedItems.." more"
			end
		else
			qlpp.message = nil
		end
	else
		local chance = qlpp.calcChance(self, target)
		qlpp.message = "reveal pocket contents ("..chance.."%)"
	end
	return tempContainerItems
end


qlpp.activate = function(self, target, input)
	if not qlpp.validateTarget(self, target, input) then return end
	if qlpp.showContents then return end
	local chance = qlpp.calcChance(self, target)
	if math.random()*100 > chance then
		core.sendGlobalEvent("OwnlysQuickLoot_commitCrime",{self, target, 0})
	else
		qlpp.showContents = true
		qlpp.message = nil
	end
	return true --to refresh the ui
end


qlpp.scroll = function(self, target, input)
	if not qlpp.validateTarget(self, target, input) then return end
	if qlpp.showContents then return end
	local chance = qlpp.calcChance(self, target)
	if math.random()*100 > chance then
		core.sendGlobalEvent("OwnlysQuickLoot_commitCrime",{self, target, 0})
	else
		qlpp.showContents = true
		qlpp.message = nil
	end
	return true --to refresh the ui
end

qlpp.getTooltipText1 = function(self,target,item) --next to the item name: "[itemname x2] (75%)"
	return " ("..qlpp.calcChance(self, target, item).."%)"
end

qlpp.getColumnText = function(self,target,item) --in the pickpocket column (if enabled) for all displayed items
	return qlpp.calcChance(self, target, item).."%"
end

qlpp.onFrame = function(self,target,item, drawUI)
	if qlpp.cache and qlpp.cache.lastUpdate < core.getRealTime() - 1 then
		local lastBench = qlpp.cache.benchResult
		buildCache(self, target)
		if math.abs(lastBench -qlpp.cache.benchResult) > 1 then
			drawUI()
		end
	end
end

return qlpp