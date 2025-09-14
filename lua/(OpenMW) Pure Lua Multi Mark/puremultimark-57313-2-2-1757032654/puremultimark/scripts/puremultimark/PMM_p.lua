I = require('openmw.interfaces')
types = require('openmw.types')
self = require('openmw.self')
Player = require('openmw.types').Player
async = require('openmw.async')
ui = require('openmw.ui')
util = require('openmw.util')
v2 = util.vector2
I = require('openmw.interfaces')
core = require('openmw.core')
ambient = require('openmw.ambient')
animation = require('openmw.animation')
input = require('openmw.input')
local camera = require('openmw.camera')
nearby = require('openmw.nearby')
local time = require('openmw_aux.time')
local debug = require('openmw.debug')


MODNAME = "PureMultiMark"
local storage = require('openmw.storage')
playerSection = storage.playerSection('Settings'..MODNAME)
local settings = require("scripts.puremultimark.PMM_settings")
DEMO_MODE = false
onFrameFunctions = {}

renameDialog = require("scripts.puremultimark.PMM_renameDialog")

LIST_ENTRIES = playerSection:get("LIST_ENTRIES")
silenceSpell = nil --record id
silenceEffect = nil --index of the effect
longestSilence = 1
isSilenced = false
castChance = 0.5
willSucceed = false
lastMagicka = 0
originalAnimSpeed = 1
isMarking = false
casting = false
destination = 1
currentScrollPos = 1
controllerRow = 0
controllerColumn = 1
controllerConfirmDown = false
recallSound = core.magic.effects.records.recall.hitSound
markSound = core.magic.effects.records.mark.hitSound
if markSound == "" then --vanilla = ""
	markSound = "mysticism hit"
end
if recallSound == "" then --vanilla = ""
	recallSound = "mysticism hit"
end




for a,b in pairs(core.magic.spells.records) do
	for c,d in pairs(b.effects) do
		if d.id == "silence" and (d.duration or 0) > longestSilence then
			silenceSpell = b.id
			silenceEffect = c-1
			longestSilence = d.duration or 0
		end
	end
end

function getMaxMarks()
	local actorIntelligence = types.Player.stats.attributes["intelligence"](self).modified
	local actorMysticism = types.Player.stats.skills["mysticism"](self).modified
	local maxMarks = playerSection:get("MARKS_BASELINE") + math.floor((actorMysticism + actorIntelligence*0.2)/playerSection:get("SKILL_STEP"))
	for a,b in pairs(types.Actor.spells(self)) do
		if b.id == "roguelite_mark" then
			maxMarks = maxMarks + 2
			break
		end
	end
	return maxMarks
end


local spellDB = {}

do -- engine function translations

function checkSpell(spell)
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
			--    minArea = 1;
			--    costMult = iAlchemyMod;
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



function getCastChance(spell)
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
	
	if cost > lastMagicka then --if (checkMagicka && calcSpellCost(*spell) > 0 && stats.getMagicka().getCurrent() < calcSpellCost(*spell))
		return 0 --return 0;
	end
	
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
    local fFatigueBase = core.getGMST("fFatigueBase") --static const float fFatigueBase = gmst.find("fFatigueBase")->mValue.getFloat();
    local fFatigueMult = core.getGMST("fFatigueMult") --static const float fFatigueMult = gmst.find("fFatigueMult")->mValue.getFloat();
    local fatigueTerm = fFatigueBase - fFatigueMult * (1 - normalised)
	castChance = castChance * fatigueTerm
	--
	--if (cap)
	--	return std::clamp(castChance, 0.f, 100.f);
	--
	--return std::max(castChance, 0.f);
	return math.max(0, math.min(1, castChance/100))
end
end


local function finalizeCast()
	--print("finalize cast")
	if saveData.vanillaRecall then
		saveData.vanillaRecall = false
		--print(types.Actor.activeEffects(self):getEffect("sound").magnitude.."+10000")
		types.Actor.activeEffects(self):modify(10000, "sound")
	end
	if isSilenced then -- multimark casting or failed cast
		for a,b in pairs(types.Actor.activeSpells(self)) do
			if b.id == silenceSpell then
				types.Actor.activeSpells(self):remove(b.activeSpellId)
				--break
			end
		end
	end
	isSilenced = false
	waitingForInput = false
	isMarking = false
	casting = false
	I.UI.setMode()
end

I.AnimationController.addTextKeyHandler('', 
function(key, group)
	if key == "spellcast" and group == "self start" then
		isMarking = false
		local castedSpell = Player.getSelectedSpell(self)
		for a,b in pairs(castedSpell.effects) do
			if b.id == "recall" then
				print("recall detected ("..#saveData.locations.."/"..getMaxMarks().." marks)")
				if #saveData.locations > 1 then
					casting = true
					originalAnimSpeed = 1 --animation.getSpeed(self, group) -- BUGGY?
					--animation.setSpeed(self, "spellcast", 0)
					local castChance = getCastChance(castedSpell)
					
					if math.random() < castChance then
						willSucceed = true
						waitingForInput = true
						local windows = {}
						if I.UI.isWindowVisible then
							for _, windowName in pairs(I.UI.WINDOW) do
								if I.UI.isWindowVisible(windowName) then
									table.insert(windows, windowName)
								end
							end
						end
						I.UI.setMode("Interface",{windows = windows})
						require("scripts.puremultimark.PMM_markWindow")
					else
						willSucceed = false
						isSilenced = true
						types.Actor.activeSpells(self):add({
							id = silenceSpell,
							effects = {silenceEffect},
							ignoreResistances  = true,
							ignoreSpellAbsorption = true,
							ignoreReflect = true,
							caster = randomCaster,
						})
					end
				end
				break
			elseif b.id == "mark" then
				print("mark detected")
				isMarking = true
				break
			end
		end
	elseif key == "spellcast" and group == "self release" and isSilenced then -- multimark casting or failed cast
		casting = false
		isSilenced = false
		otherSilence = false
		for a,b in pairs(types.Actor.activeSpells(self)) do
			if b.id == silenceSpell then
				types.Actor.activeSpells(self):remove(b.activeSpellId)
			else
				for c,d in pairs(b.effects) do
					if d.id == "silence" then
						otherSilence = true
					end
				end
			end
		end
		if willSucceed and not otherSilence then
			ambient.playSound(recallSound, {volume = 0.9})
			if(core.sound.isSoundPlaying("Spell Failure Mysticism", self)) then
				core.sound.stopSound3d("Spell Failure Mysticism", self) 
			end
			core.sendGlobalEvent("PMM_loadLoc", {self, saveData.locations[destination]})
			ui.showMessage("")
			ui.showMessage("")
			ui.showMessage("")
			I.SkillProgression.skillUsed('mysticism', {skillGain=3, useType = I.SkillProgression.SKILL_USE_TYPES.Spellcast_Success, scale = nil})
		end
		
	end
end
)

function selectedMark(id)
	--print("selected "..id)
	if id <= 0 then
		if not saveData.vanillaRecall then
			--print("applying cast buff")
			saveData.vanillaRecall = true
			types.Actor.activeEffects(self):modify(-10000, "sound")
		end
		-- vanilla recall
	else
		destination = id
		isSilenced = true
		types.Actor.activeSpells(self):add({
			id = silenceSpell,
			effects = {silenceEffect},
			ignoreResistances  = true,
			ignoreSpellAbsorption = true,
			ignoreReflect = true,
			caster = randomCaster,
		})
	end
	I.UI.setMode()
	waitingForInput = false
	dpadMoveDirection = nil
	animation.setSpeed(self, "spellcast", originalAnimSpeed or 1)
end

function cancelCasting()
	if playerSection:get("QSC_FIX") then
		willSucceed = false
		isSilenced = true
		types.Actor.activeSpells(self):add({
			id = silenceSpell,
			effects = {silenceEffect},
			ignoreResistances  = true,
			ignoreSpellAbsorption = true,
			ignoreReflect = true,
			caster = randomCaster,
		})
		waitingForInput = false
		isMarking = false
		--casting = false
		casting = true
		animation.setSpeed(self, "spellcast", originalAnimSpeed or 1)
		I.UI.setMode()
	else
		animation.cancel(self, "spellcast")
		finalizeCast()
	end
	dpadMoveDirection = nil
end


local function onFrame(dt)
	for _, onFrameFunction in pairs(onFrameFunctions) do
		onFrameFunction(dt)
	end
	if waitingForInput and teleportWindow then
		originalAnimSpeed = math.max(originalAnimSpeed, animation.getSpeed(self, "spellcast"))
		animation.setSpeed(self, "spellcast", 0)
		local now = core.getRealTime()
		if dpadMoveDirection and now > lastDpadMove + 0.1 then 
			dpadMove(dpadMoveDirection)
			lastDpadMove = now
		end
	end
	if dt == 0 then return end
	lastMagicka = types.Player.stats.dynamic.magicka(self).current
	if isMarking then
		if core.sound.isSoundPlaying(markSound, self) then
			if not self.cell then return end
			local maxMarks = getMaxMarks()
			local slot = #saveData.locations+1
			local overwritten = false
			if slot > maxMarks then
				overwritten = true
				slot = slot - 1
				ui.showMessage("last mark overwritten ("..slot.."/"..maxMarks..")")
			end
			local name = self.cell.name
			if not name or name == "" then
				name = self.cell.region 
				if not name or name == "" then
					name = self.cell.id
				elseif core.regions then
					name = core.regions.records[name].name
				end
			end
			if self.cell.isExterior then
				name = name.." "..self.cell.gridX.."/"..self.cell.gridY
				print("marked "..name.." (slot "..slot.."/"..maxMarks..")")
				saveData.locations[slot] = {name = name, gridX = self.cell.gridX, gridY = self.cell.gridY, position = self.position, rotation = self.rotation}
			else
				print("marked "..name.." (slot "..slot.."/"..maxMarks..")")
				saveData.locations[slot] = {name = name, cell = self.cell.id, position = self.position, rotation = self.rotation}
			end
			isMarking = false
		end
	end
	if casting and not animation.isPlaying(self, "spellcast") then
		finalizeCast()
	end
end

local function UiModeChanged(data)
	if data.oldMode == "MainMenu" and data.newMode == nil and teleportWindow then
		destroyTeleportWindow()
		DEMO_MODE = false
	end
	if not data.newMode and waitingForInput and teleportWindow then
		destroyTeleportWindow()
		selectedMark(0)
	end
end

function onMouseWheel(vertical)
	if waitingForInput and teleportWindow and #teleportLocations > LIST_ENTRIES then
		vertical = vertical
		currentScrollPos = math.max(1,math.min(#teleportLocations-LIST_ENTRIES+1, currentScrollPos - vertical))
		refreshTeleportList()
	end
	controllerRow = 0 --clear controller selection if player uses mouse
end

function dpadMove(direction, wrapAround)
	local oldIndex = controllerRow
	controllerRow = math.max(0,math.min(#saveData.locations, controllerRow + direction))
	if oldIndex == controllerRow and wrapAround then
		if oldIndex == 0 then
			controllerRow = #saveData.locations
		else
			controllerRow = 0
		end
	end
	if controllerRow < currentScrollPos then
		currentScrollPos = controllerRow
	elseif controllerRow >= currentScrollPos + LIST_ENTRIES then
		currentScrollPos = controllerRow - LIST_ENTRIES + 1
	end
	currentScrollPos = math.max(1, math.min(#saveData.locations - LIST_ENTRIES+1, currentScrollPos))
	refreshTeleportList()
end

function onControllerButtonPress(key)
	if not waitingForInput or not teleportWindow then return end
	if key == input.CONTROLLER_BUTTON.DPadDown or key == input.CONTROLLER_BUTTON.DPadUp then
		local direction = (key == input.CONTROLLER_BUTTON.DPadDown) and 1 or -1
		dpadMoveDirection = direction
		dpadMove(dpadMoveDirection, true)
		lastDpadMove = core.getRealTime()+0.12
	elseif key == input.CONTROLLER_BUTTON.DPadRight and controllerColumn < 3 then
		controllerColumn = controllerColumn + 1
		refreshTeleportList()
	elseif key == input.CONTROLLER_BUTTON.DPadLeft and controllerColumn > 1 then
		controllerColumn = controllerColumn - 1
		refreshTeleportList()
	elseif key == input.CONTROLLER_BUTTON.X then
		controllerConfirmDown = true
		refreshTeleportList()
	end
	if controllerRow == 0 and controllerColumn == 1 then
		if controllerConfirmDown then
			xButton.content.clickbox.userData.focus = 2
		else
			xButton.content.clickbox.userData.focus = 1
		end
		xButton.content.clickbox.userData.applyColor()
	elseif xButton.content.clickbox.userData.focus > 0 then
		xButton.content.clickbox.userData.focus = 0
		xButton.content.clickbox.userData.applyColor()
	end
end

-- DPAD
function onControllerButtonRelease(key)
	if not waitingForInput or not teleportWindow then return end
	if key == input.CONTROLLER_BUTTON.X then
		controllerConfirmDown = false
		if controllerRow > 0 and saveData.locations[controllerRow] then
			if controllerColumn == 1 then
				destroyTeleportWindow()
				selectedMark(controllerRow)
			elseif controllerColumn == 2 then
				if controllerRow == 1 or playerSection:get("SORT_DIRECTION") == "Down" then
					moveLocationDown(controllerRow)
				elseif controllerRow == #saveData.locations or playerSection:get("SORT_DIRECTION") == "Up" then
					moveLocationUp(controllerRow)
				end
			elseif controllerColumn == 3 then
				deleteLocation(controllerRow)
			end
			
		elseif controllerColumn == 1 then
			destroyTeleportWindow()
			cancelCasting()
		end
	elseif key == input.CONTROLLER_BUTTON.DPadDown or key == input.CONTROLLER_BUTTON.DPadUp then
		dpadMoveDirection = nil
	end
end



local function onLoad(data)
	saveData = data or {}
	if not saveData.locations then
		saveData.locations = {}
	end
	local soundMagnitude = types.Actor.activeEffects(self):getEffect("sound").magnitude
	local magicNumber = 10000
	if not saveData.version or saveData.version == 1 then
		magicNumber = 100 -- check old saves for 100 magnitude buffs
	end
	local fix = false
	if soundMagnitude <= -magicNumber*0.85 then
		fix = true
	elseif soundMagnitude >= magicNumber*0.85 then
		fix = true
		magicNumber = -magicNumber
	end
	if fix then
		saveData.vanillaRecall = false
		local mod = math.floor(-soundMagnitude/magicNumber)*magicNumber
		local newMagnitude = soundMagnitude + mod
		types.Actor.activeEffects(self):modify(mod, "sound")
		if math.abs(magicNumber) ~= 100 then
			ui.showMessage("MultiMark Inconsistency detected: bonus cast chance ".. -soundMagnitude.."% -> ".. -newMagnitude.."%")
					 print("MultiMark Inconsistency detected: bonus cast chance ".. -soundMagnitude.."% -> ".. -newMagnitude.."%")
		else
			ui.showMessage("MultiMark updated, cast chance issue fixed")
			print("MultiMark updated, cast chance issue fixed")
		end
	end
	saveData.version = 2
end

local function onSave()
    return saveData
end

return {
	engineHandlers = {
        onLoad = onLoad,
        onInit = onLoad,
        onSave = onSave,
		onFrame = onFrame,
		onMouseWheel = onMouseWheel,
		onControllerButtonPress = onControllerButtonPress,
		onControllerButtonRelease = onControllerButtonRelease,
	},
	eventHandlers = { 
		UiModeChanged = UiModeChanged,
	},
}