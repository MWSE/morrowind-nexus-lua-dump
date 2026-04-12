local I = require('openmw.interfaces')
world = require('openmw.world')
types = require('openmw.types')
core = require('openmw.core')
local time = require('openmw_aux.time')
local vfs = require('openmw.vfs')
local procPotions = {}
local recentActive = {}
local soulgems = {}
local currentCells = {}
local fFightDispMult = core.getGMST("fFightDispMult")
local iFightDistanceBase =core.getGMST("iFightDistanceBase")
local fFightDistanceMultiplier = core.getGMST("fFightDistanceMultiplier")
local fightDistanceConstant = iFightDistanceBase - 500 * fFightDistanceMultiplier
local anyDispositionBlessings = false
local anySlumbering = false
local slumbering = 0

local function updateBlessingCounts()
	local dispositionBlessings = 0
	for playerId, blessings in pairs(saveData.playerBlessings) do
		if blessings.disposition then
			dispositionBlessings = dispositionBlessings + 1
		end
		if blessings.gatherer then
			gatherers[playerId] = true
		end
	end
	anyDispositionBlessings = dispositionBlessings > 0
end


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



local function makeSoulgem(data)
	local player = data[1]
	local died = data[2]
	local soulSize = 0
	local soulId = died.recordId
	if types.Creature.objectIsInstance(died) then
		soulSize = types.Creature.record(died).soulValue
	elseif types.NPC.objectIsInstance(died) then
		--soulSize = types.NPC.record(died).soulValue
		soulSize = math.min(7,math.floor(types.Actor.stats.level(died).current/10))
		soulId = "roguelite_human_soul_"..soulSize
		soulSize = types.Creature.record(soulId).soulValue
	end
	
	if soulSize == 0 then
		return
	end
	local fSoulGemMult = core.getGMST("fSoulGemMult")
	local fittingSoulgem = soulgems[#soulgems].name
	for a,t in ipairs(soulgems) do
		if t.value * fSoulGemMult >= soulSize then
			fittingSoulgem = t.name
			break
		end
	end
	local soulgem = world.createObject(fittingSoulgem)
	types.Item.itemData(soulgem).soul =  soulId
	soulgem:moveInto(player)
end


local function increaseBarterGold(data)
	if not types.Actor.setBarterGold then return end
	local target = data[1]
	local gold = data[2] or 0
	local oldBarterGold = types.Actor.getBarterGold(target)
	if gold > 0 then
		types.Actor.setBarterGold(target, oldBarterGold + gold)
	end
end

local function setPlayerBlessings(data)
	local player = data[1]
	local blessings = data[2]
	saveData.playerBlessings[player.id] = blessings
	saveData.playerBlessings[player.id].player = player
	updateBlessingCounts()
end

--local NPCFightThreshold = 90
--local CreatureFightThreshold = 83
		
local function onActorActive(object)
	if anyDispositionBlessings and types.NPC.objectIsInstance(object) and not object.type.isDead(object) then
		local fight = object.type.stats.ai.fight(object).modified + fightDistanceConstant
		--local fightLimit = isNPC and NPCFightThreshold or CreatureFightThreshold
		for playerId, blessings in pairs(saveData.playerBlessings) do
			if blessings.disposition then
				--local fightDispoModifier = (50-types.NPC.getDisposition(object, player))*fFightDispMult
				if fight < 100 then
					types.NPC.modifyBaseDisposition(object, blessings.player,100)
				end
			end
		end
	end
	if anySlumbering then
		table.insert(recentActive, {object, core.getRealTime()})
		if #recentActive >100 then
			table.remove(recentActive, 1)
		end
	end
end

local function buffPotion(data)
	local player = data[1]
	local item = data[2]
	local amount = data[3]

	if not item:isValid() then
		return 
	elseif item.count == 0 then
		item = types.Player.inventory(player):find(item.recordId)
	end
	if not item:isValid() or item.count == 0 then
		return
	end
	if not procPotions[item.recordId] then
		local template = types.Potion.record(item)
		local effects = template.effects
		local newEffects = {}
		for a,effect in pairs(effects) do
			table.insert(newEffects, effect)
			table.insert(newEffects, effect)
		end
		local tbl = {name = "Flawless "..template.name, template = template, effects = newEffects, weight = 0}
		local recordDraft = item.type.createRecordDraft(tbl)
		procPotions[item.recordId] = world.createRecord(recordDraft).id
	end
	local newObject = world.createObject(procPotions[item.recordId], amount)
	newObject:moveInto(player)
	item:remove(amount)
end

local function spawnItem(data)
	local player = data[1]
	local recordId = data[2]
	local amount = data[3]
	local newObject = world.createObject(recordId,amount )
	newObject:moveInto(player)
end

local function wakeUp (player)
	local now = core.getRealTime()
	for _, t in pairs(recentActive) do
		local distance = (t[1].position - player.position):length()
		if t[2] > now-1 and distance < 400 then
			print("slumber pacify")
			
			types.Actor.spells(t[1]):add("roguelite_hitchance_companion")
			types.Actor.spells(t[1]):add("roguelite_sanctuary_companion")
			
			t[1]:addScript("scripts/Roguelite/RL_pacify.lua")
			t[1]:sendEvent('StartAIPackage', {
				type = 'Follow',
				cancelOther = true,
				target = player,
				duration = 3*3600,
				isRepeat = true
			})
		end
	end
	slumbering = math.max(0,slumbering - 1)
	if slumbering == 0 then
		recentActive = {}
		anySlumbering = false
	else
		anySlumbering = true
	end
	print("Woke up "..slumbering)
end

local function slumberMode()
	slumbering = slumbering + 1
	anySlumbering = true
	print("Zzz "..slumbering)
end

local challenge_dungeon = require("scripts.Roguelite.challenge_dungeon")
local function cellChanged(player)
	local prevCell = currentCells[player.id]
	local nextCell = player.cell
	if prevCell and prevCell.id ~= nextCell.id then
		challenge_dungeon.onCellChange(player,prevCell, nextCell)
	end
	currentCells[player.id] = nextCell
end

local function checkDungeonCleared(player)
	challenge_dungeon.checkCurrentDungeon(player)
end



local function fixTimeskip(data)
	local player = data[1]
	local seconds = data[2]
	local fMagicItemRechargePerSecond = core.getGMST("fMagicItemRechargePerSecond")/30 -- idk
	for a,b in pairs(types.Actor.inventory(player):getAll()) do
		local charge = types.Item.itemData(b).enchantmentCharge
		if charge then
			types.Item.itemData(b).enchantmentCharge = charge-fMagicItemRechargePerSecond*seconds
		end
	end
end

local function startVampirism(player)
	local vampScript = world.mwscript.getGlobalScript("VampireCheck", player)
	local vampirismVariants = {
		"Vampire Blood Quarra",
		"Vampire Blood Aundae",
		"Vampire Blood Berne"
	}
	
	-- maybe todo: https://wiki.project-tamriel.com/wiki/Vampirism
	-- if core.magic.spells.records["t_vamp_dis_baluath"]
	
	types.Actor.spells(player):add(vampirismVariants[math.random(1,#vampirismVariants)])
	vampScript.variables.state = 10
	saveData.vampChallenges = saveData.vampChallenges or {}
	table.insert(saveData.vampChallenges, player)
end

local function detachPacify(actor)
	if actor:isValid() and actor:hasScript("scripts/Roguelite/RL_pacify.lua") then
		actor:removeScript("scripts/Roguelite/RL_pacify.lua")
	end
end

local function blooddividend(data)
	local player = data[1]
	local enemy = data[2]
	local averageItemValue = data[3]
	local playerLevel = types.Actor.stats.level(player).current
	local enemyLevel = types.Actor.stats.level(enemy).current
	local term = (0.7 + enemyLevel/7 + playerLevel/12 )*averageItemValue/35
	--print(math.floor(term))
	local result = math.floor((math.random()+0.5)*term)
	world.createObject("gold_001",result):moveInto(enemy)
end

local function attachWither(data)
	local actor = data[1]
	local player = data[2]
	if not actor:isValid() or types.Actor.isDead(actor) then return end
	if not actor:hasScript("scripts/Roguelite/RL_wither.lua") then
		actor:addScript("scripts/Roguelite/RL_wither.lua")
	end
	actor:sendEvent("Roguelite_setWitherPlayer", player)
end

local function detachWither(actor)
	if actor:isValid() and actor:hasScript("scripts/Roguelite/RL_wither.lua") then
		actor:removeScript("scripts/Roguelite/RL_wither.lua")
	end
end

local function spawnSoultrapVFX(position)
	world.vfx.spawn(types.Static.records["VFX_Soul_Trap"].model, position)
end

time.runRepeatedly(function()
	if saveData.vampChallenges and math.random() < 0.1 then
		for i, player in pairs(saveData.vampChallenges) do
			var = world.mwscript.getGlobalVariables(player).PCVampire
			if var == -1 then
				player:sendEvent("Roguelite_curedVampirism")
				saveData.vampChallenges[i] = nil
				if #saveData.vampChallenges == 0 then
					saveData.vampChallenges = nil
					break
				end
			end
		end			
	end
end, 1 * time.second)



local function onLoad(data)
	if data then
		saveData = data		
	else
		saveData = {}
	end
	if not saveData.hostileCells then
		saveData.hostileCells = {}
	end
	if not saveData.clearedCells then
		saveData.clearedCells = {}
	end
	if not saveData.originalHostileState then
		saveData.originalHostileState = {}
	end
	if not saveData.playerBlessings then
		saveData.playerBlessings = {}
	end
	if not saveData.gatheredContainers then
		saveData.gatheredContainers = {}
	end
	updateBlessingCounts()
end

local function onSave()
	return saveData
end

---uuuI.Activation.addHandlerForType(types.Container, gathererPerk)

return {
	engineHandlers = { 
		onActorActive = onActorActive,
		onLoad = onLoad,
		onInit = onLoad,
		onSave = onSave,
	},
	eventHandlers = { 
		Roguelite_makeSoulgem = makeSoulgem,
		Roguelite_increaseBarterGold = increaseBarterGold,
		Roguelite_setPlayerBlessings = setPlayerBlessings,
		Roguelite_buffPotion = buffPotion,
		Roguelite_spawnItem = spawnItem,
		Roguelite_wakeUp = wakeUp,
		Roguelite_slumberMode = slumberMode,
		Roguelite_cellChanged = cellChanged,
		Roguelite_fixTimeskip = fixTimeskip,
		Roguelite_startVampirism = startVampirism,
		Roguelite_blooddividend = blooddividend,
		Roguelite_checkDungeonCleared = checkDungeonCleared,
		Roguelite_attachWither = attachWither,
		Roguelite_detachWither = detachWither,
		Roguelite_spawnSoultrapVFX = spawnSoultrapVFX,
		Roguelite_detachPacify = detachPacify,
		---uuuOwnlysQuickLoot_resolve = gathererPerk,
		---uuuRoguelite_receiveCellInfo = receiveCellInfo,
	}
}