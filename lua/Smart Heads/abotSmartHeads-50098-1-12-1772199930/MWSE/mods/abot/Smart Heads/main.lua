--[[
randomizes cloned NPCs standard heads
]]

local defaultConfig = {
minClones = 2, -- minimum number of NPC clones before changing head
skipFullHeadCoveredActors = true,
guardsOnly = false,
expandedHeads = true,
blocked = {},
logLevel = 0, -- 0 = Minimum, 1 = Low, 2 = Medium, 3 = High, 4 = max
}

local author = 'abot'
local modName = 'Smart Heads'
local modPrefix = author .. '/' .. modName
local configName = author .. modName
configName = configName:gsub(' ', '_')
local mcmName = author .. "'s " .. modName

local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end

local config = mwse.loadConfig(configName, defaultConfig)
assert(config)

local tes3_activeBodyPart_head = tes3.activeBodyPart.head
local tes3_activeBodyPartLayer_base = tes3.activeBodyPartLayer.base
local tes3_objectType_armor = tes3.objectType.armor
---local tes3_objectType_clothing = tes3.objectType.clothing
local tes3_armorSlot_helmet = tes3.armorSlot.helmet
---local tes3_clothingSlot_robe = tes3.clothingSlot.robe

-- heads[race_sex] = numDifferentHeadsAvailable
local heads = {
['argonian_f'] = 3,
['argonian_m'] = 3,
['breton_f'] = 6,
['breton_m'] = 9,
['dark elf_f'] = 10,
['dark elf_m'] = 17,
['high elf_f'] = 6,
['high elf_m'] = 6,
['imperial_f'] = 7,
['imperial_m'] = 7,
['khajiit_f_f'] = 4,
['khajiit_f_m'] = 4,
['nord_f'] = 13,
['nord_m'] = 13,
['orc_f'] = 3,
['orc_m'] = 4,
['redguard_f'] = 6,
['redguard_m'] = 6,
['wood elf_f'] = 6,
['wood elf_m'] = 8,
}

local lastLoggedRef
local function logOnce(loggedRef, ...)
	if loggedRef == lastLoggedRef then
		return
	end
	lastLoggedRef = loggedRef
	mwse.log(...)
end

local function getHeadId(b_n_raceId_sex, num)
	return ("%s_head_%02d"):format(b_n_raceId_sex, num)
end

local logLevel, logLevel1, logLevel2, logLevel3, logLevel4, logLevel5

local function updateFromConfig()
	logLevel = config.logLevel
	logLevel1 = logLevel >= 1
	logLevel2 = logLevel >= 2
	logLevel3 = logLevel >= 3
	logLevel4 = logLevel >= 4
	logLevel5 = logLevel >= 5
end
updateFromConfig()

local function expandHeads() -- called in initialized()
	local b_n_raceId_sex
	local newMax, headId, obj, lastObj, from
	for raceId_sex, headNum in pairs(heads) do
		b_n_raceId_sex = 'b_n_' .. raceId_sex
		---mwse.log("%s expandHeads: b_n_raceId_sex = %s",modPrefix, b_n_raceId_sex)
		newMax = headNum
		lastObj = nil
		for n = headNum + 1, 20, 1 do
			headId = getHeadId(b_n_raceId_sex, n)
			obj = tes3.getObject(headId)
			if obj then
				newMax = n
				lastObj = obj
				if logLevel4 then
					mwse.log("%s expandHeads: n = %s, heads['%s'] = %s",
						modPrefix, n, raceId_sex, headNum)
				end
			else
				break
			end
		end
		if newMax > headNum then
			if logLevel2 then
				mwse.log("%s expandHeads: newMax = %s > headNum = %s",
					modPrefix, newMax, headNum)
			end
			if lastObj then
				from = ''
				if lastObj.sourceMod then
					from = 'from "' .. lastObj.sourceMod .. '" '
				end
				mwse.log('%s expandHeads: available heads["%s"] increased to %s\n(%s %sdetected)',
					modPrefix, raceId_sex, newMax, lastObj.id , from)
			else
				mwse.log('%s expandHeads: available heads["%s"] increased to %s',
					modPrefix, raceId_sex, newMax)
			end
			heads[raceId_sex] = newMax
		end
	end
end

local lastHeadNum = 1

local function isFullHeadCover(stack)
	if stack then
		local item = stack.object
		if item then
			local parts = item.parts
			local part
			for i = 1, #parts do
				part = parts[i]
				if part.type == tes3_activeBodyPart_head then
					return true
				end
			end
		end
	end
	return false
end

local function getTimerRef(e)
	local timer = e.timer
	---assert(timer)
	local data = timer.data
	---assert(data)
	local handle = data.handle
	if not handle then
		return
	end
	if not handle['valid'] then
		return -- hackish workaround
	end
	if not handle:valid() then
		return
	end
	local ref = handle:getObject()
	return ref
end

local function ab01smheadPT1(e)
	local ref = getTimerRef(e)
	if not ref then
		return
	end
	if not ref.bodyPartManager then
		return
	end
	local scene = ref.bodyPartManager:getActiveBodyPart(
		tes3_activeBodyPartLayer_base, tes3_activeBodyPart_head)
	if scene then
		local sceneNode = scene.node
		if sceneNode then
			sceneNode:update()
		end
	end
end

local function delayedUpdateNode(reference)
	local refHandle = tes3.makeSafeObjectHandle(reference)
	if refHandle then
		timer.start({duration = (0.05 * math.random()) + 0.15, type = timer.real,
			callback = 'ab01smheadPT1',	data = {handle = refHandle}
		})
	end
end


local function hasLocalVariable(ref, variableId)
	-- ref.context may not always be valid from BodyPartAssigned event
	-- and possibly crashing
	local script = ref.object.script -- so better not to use ref.context
	if script then -- script.context is valid but it returns default 0 variable value
		-- luckily for this mod we only need to check if the variable is present
		local context = script.context
		if context then
			local value = context[variableId]
			if value then
				---assert(value == context[variableId:lower()]) -- not case sensitive any more?
				---assert(value == context[variableId:upper()]) -- not case sensitive any more?
				return true
			end
		end
	end
	return false
end

local function hasCompanion(ref)
	return hasLocalVariable(ref, 'companion')
end

local skipCount = 0

local bpaPrefix = modPrefix .. ' bodyPartAssigned'

-- set in modConfigReady()
local werewolfBloodSpell


local function bodyPartAssigned(e)

	local bodyPartIndex = e.index
	if not bodyPartIndex then
		return
	end
	if not (bodyPartIndex == tes3_activeBodyPart_head) then
		return
	end

	local ref = e.reference

	local bodyPart = e.bodyPart
	if not bodyPart then
		if logLevel4 then
			logOnce(ref, '%s: skipping "%s" (empty body part e.g. invisible sonar race)', bpaPrefix, ref)
		end
		return -- skip empty body parts (e.g. invisible sonar race)
	end

	local bodyPartType = bodyPart.partType
	if not (bodyPartType == tes3_activeBodyPartLayer_base) then
		return
	end

	local refBaseObj = ref.baseObject
	-- only interested in clones
	local cloneCount = refBaseObj.cloneCount
	if not cloneCount then
		---assert(cloneCount) -- should never happen
		if logLevel4 then
			logOnce(ref, '%s: skipping "%s" with refBaseObj.cloneCount = %s',
				bpaPrefix, ref, cloneCount)
		end
		return
	end
	---local refId = ref.id
	if cloneCount < config.minClones then
		if logLevel5 then
			logOnce(ref, '%s: skipping "%s" (cloneCount < %s)', bpaPrefix, ref, config.minClones)
		end
		return -- also skipping player1stPerson view ASAP here
	end
	local refObj = ref.object

	if e.object then -- ignore e.g. helmet
		if logLevel4 then
			logOnce(ref, '%s: skipping "%s" (object = "%s")', bpaPrefix, ref, e.object.id)
		end
		return
	end

	if ref == tes3.player then
		if logLevel4 then
			logOnce(ref, '%s: skipping "%s" (ref = tes3.player)', bpaPrefix, ref)
		end
		return
	end

	if ref.disabled then
		if logLevel4 then
			logOnce(ref, '%s: skipping disabled "%s"', bpaPrefix, ref)
		end
		return
	end
	if ref.deleted then
		if logLevel4 then
			logOnce(ref, '%s: skipping deleted "%s"', bpaPrefix, ref)
		end
		return
	end

	local refId = ref.id
	assert(refId)
	local lcRefId = refId:lower()
	if lcRefId:endswith('00000000') then
		if logLevel4 then
			logOnce(ref, '%s: skipping "%s" (first instance, lcRefId:endswith("00000000"))', bpaPrefix, ref)
		end
		return -- always skip first instance
	end

	---logOnce(ref, "id = %s, bodyPart = %s", ref, bodyPart)

	if not ref.data then
		if logLevel2 then
			logOnce(ref, '%s: skipping no "%s".data NPC', bpaPrefix, ref)
		end
		return
	end
	local headNum = ref.data.ab01hn
	local sourceMod = refBaseObj.sourceMod
	if sourceMod then
		local lcSourceMod = sourceMod:lower()
		if config.blocked[lcSourceMod] then
			if logLevel2 then
				logOnce(ref, '%s: skipping "%s" (blocked mod "%s")', bpaPrefix, ref, sourceMod)
			end
			if headNum then
				ref.data.ab01hn = nil
			end
			return
		end
	end

	local lcBaseId = refBaseObj.id:lower()
	if config.blocked[lcBaseId] then
		if logLevel2 then
			logOnce(ref, '%s: skipping "%s" (blocked NPC)', bpaPrefix, ref)
		end
		if headNum then
			ref.data.ab01hn = nil
		end
		return
	end

	--[[
	if refObj == refBaseObj then
		if logLevel3 then
			mwse.log('%s: skipping "%s" (first instance, refObj == refBaseObj)', prefix, ref)
		end
		return
	end
	]]

	if lcRefId
	and lcRefId:startswith('nm_npc') then
		if logLevel2 then
			logOnce(ref, '%s: skipping "%s" (MWSE Random NPC)', bpaPrefix, ref)
		end
		return -- skip MWSE Random NPC https://www.nexusmods.com/morrowind/mods/48992
	end

	local race = refBaseObj.race
	if not race then
		if logLevel2 then
			logOnce(ref, '%s: skipping no race "%s"', bpaPrefix, ref)
		end
		return
	end

	if bodyPart.vampiric then
		if logLevel3 then
			logOnce(ref, '%s: skipping "%s" (bodyPart.vampiric)', bpaPrefix, ref)
		end
		return
	end

--begin skip those probably doubled by some silly mod
	local blocked = refObj.blocked
	if blocked then
		if logLevel3 then
			logOnce(ref, '%s: skipping "%s" (blocked)', bpaPrefix, ref)
		end
		return
	end

	local isEssential = refObj.isEssential
	if isEssential then
		if logLevel3 then
			logOnce(ref, '%s: skipping "%s" (essential)', bpaPrefix, ref)
		end
		return
	end

	local factionRank = refObj.factionRank
	if not factionRank then
		factionRank = refBaseObj.factionRank
	end
	if factionRank
	and (factionRank >= 10) then
		if logLevel3 then
			logOnce(ref, '%s: skipping "%s" (factionRank >= 10)', bpaPrefix, ref)
		end
		return
	end
--end skip those probably doubled by some silly mod

	local raceId = race.id:lower()
	local sex = 'm'
	if refObj.female then
		sex = 'f'
	end

	local raceId_sex = raceId .. '_' .. sex
	local b_n_raceId_sex = 'b_n_' .. raceId_sex

	local currHeadId = bodyPart.id:lower()
	if not currHeadId:startswith(b_n_raceId_sex) then
		if logLevel3 then
			logOnce(ref, "%s: not '%s':startswith('%s')", bpaPrefix, currHeadId, b_n_raceId_sex)
		end
		return -- skip non-vanilla format head meshes
	end

	if config.skipFullHeadCoveredActors then
		local stack = tes3.getEquippedItem({actor = ref, objectType = tes3_objectType_armor, slot = tes3_armorSlot_helmet})
		if isFullHeadCover(stack) then
			if logLevel > 0 then
				logOnce(ref, "%s: '%s' head covered by full helmet, skipping", bpaPrefix, ref)
			end
			return
		end
		--[[stack = tes3.getEquippedItem({actor = ref, objectType = tes3_objectType_clothing, slot = tes3_clothingSlot_robe})
		if isFullHeadCover(stack) then
			if logLevel1 then
				logOnce(ref, "%s: '%s' head covered, skipping", bpaPrefix, ref)
			end
			return
		end]]
	end

	if logLevel3 then
		if ref.sourceless then
			logOnce(ref, "%s: reference %s", bpaPrefix, ref)
		elseif ref.sourceMod then
			logOnce(ref, "%s: reference %s from %s", bpaPrefix, ref, ref.sourceMod)
		end
	end

	if config.guardsOnly then
		local objClass = refObj.class
		if not objClass then
			return -- it happens a lot /abot
		end
		local classId = objClass.id
		local lcClassId = classId:lower()
		if not (lcClassId == 'guard') then
			return
		end
	end


	local mobile = ref.mobile
	if mobile -- IMPORTANT!!! it seems I can safely access the variable only when mobile is available
	and (ref == mobile.reference) then -- cross checking for safety -- nope that's not enough
		local hasCompanionLocalVar = hasCompanion(ref) -- note variable value may be not be updated correctly,
		if hasCompanionLocalVar then -- but luckily we just need to know if the variable exists
			if logLevel1 then
				logOnce(ref, "%s: skipping cloned companion %s", bpaPrefix, ref)
			end
			return
		end
		if werewolfBloodSpell then
			if tes3.isAffectedBy({reference = ref, object = werewolfBloodSpell}) then
				if logLevel1 then
					logOnce(ref, "%s: skipping cloned werewolf %s", bpaPrefix, ref)
				end
				return
			end
		end
	elseif logLevel4 then
		logOnce(ref, "%s: %s has invalid .mobile", bpaPrefix, ref)
	end

	local headId, obj

	if headNum then
		headId = getHeadId(b_n_raceId_sex, headNum)
		if headId
		and ( not (currHeadId == headId) ) then
			if skipCount > 0 then
				skipCount = skipCount - 1
				return
			end
			skipCount = 1
			if logLevel1 then
				logOnce(ref, "%s: '%s' head mesh restored from %s to %s", bpaPrefix, ref, currHeadId, headId)
			end
			obj = tes3.getObject(headId)
			if obj then
				e.bodyPart = obj
				ref.data.ab01hn = headNum
				delayedUpdateNode(ref)
			end
		end
		return
	end

	if logLevel3 then
		logOnce(ref, "%s: %s head mesh %s", bpaPrefix, ref, currHeadId)
	end

	local headMax = heads[raceId_sex]
	if not headMax then
		if logLevel3 then
			logOnce(ref, "%s: not heads['%s']", bpaPrefix, raceId_sex)
		end
		return -- not a standard race
	end

	if lastHeadNum < headMax then
		headNum = lastHeadNum + 1
	else
		headNum = 1
	end
	lastHeadNum = headNum

	headId = getHeadId(b_n_raceId_sex, headNum)
	if not headId then
		return
	end
	if not currHeadId then
		return
	end
	if not (currHeadId == headId) then
		if logLevel1 then
			-- note ref.cell may still be nil here!
			local s = ' '
			if ref.cell then
				s = (' in cell "%s" '):format(ref.cell.id)
			end
			logOnce(ref, '%s: "%s"%shead mesh changed from "%s" to "%s"',
				bpaPrefix, ref, s, currHeadId, headId)
		end
		obj = tes3.getObject(headId)
		if obj then
			e.bodyPart = obj
			ref.data.ab01hn = headNum
			delayedUpdateNode(ref)
		end
	end
end

local function isMoreHeadAndDiversityMWSEActive()
	return tes3.getFileExists("MWSE\\mods\\OEA\\OEA2Heads\\main.lua")
end

local function isMoreHeadAndDiversityActive()
	if tes3.getObject('b_n_orc_f_head_20') then
		return true
	end
	return false
end


--[[local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end]]

local function onClose()
	updateFromConfig()
	mwse.saveConfig(configName, config, {indent = false})
end

local function modConfigReady()

	if isMoreHeadAndDiversityMWSEActive() then
		if not isMoreHeadAndDiversityActive() then
			mwse.log("%s [WARNING]: 'More Heads And Diversity MWSE' mod detected, but the needed 'MoreHeads' plugin is not loaded!", modPrefix)
		end
		mwse.log("%s [WARNING]: 'More Heads And Diversity MWSE' mod detected, disabling 'Smart Heads' mod as 'More Heads And Diversity MWSE' already replaces cloned NPCs heads", modPrefix)
		return
	end

	expandHeads()
	timer.register('ab01smheadPT1', ab01smheadPT1)
	event.register('bodyPartAssigned', bodyPartAssigned)

	werewolfBloodSpell = tes3.getObject('werewolf blood')
	---assert(werewolfBloodSpell)

	local template = mwse.mcm.createTemplate({name = mcmName,
		config = config, defaultConfig = defaultConfig,
		showDefaultSetting = true, onClose = onClose})

	local sideBarPage = template:createSideBarPage({
		label = modName,
		showHeader = false,
		description = [[Randomize cloned NPCs standard heads.]],
		showReset = true,
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	})

	local category = sideBarPage:createCategory({})

	category:createSlider({
		label = 'Min clones number',
		configKey = 'minClones'
		,min = 2, max = 10,
		description = [[Minimum number of clones needed for NPC head to be randomized.
If you think you are using quest mods placing multiple copies of the same quest character NPC, you may want to increase this value
(to avoid the risk of seeing what in theory is the same character having different faces in different places),
else it may be safe to decrease the value to 2. Or you could add the NPCs to the Blacklist.]]
	})


	category:createYesNoButton({
		label = 'Skip actor clones wearing full covering helmet/mask',
		description = [[Skip actor clones wearing full covering helmet/mask as their head is normally not visible.]],
		configKey = 'skipFullHeadCoveredActors'
	})

	category:createYesNoButton({
		label = 'Process only guard clones',
		description = [[Process only clones of actors belonging to the special Guard class.]],
		configKey = 'guardsOnly'
	})

	category:createYesNoButton({
		label = 'Use expanded standard heads if detected',
		description = [[Use expanded standard heads if detected (e.g. from 'More Heads And Diversity' mod.
Else it will only use default standard heads.
Note: if you are using also 'More Heads And Diversity MWSE' add-on, 'Smart Heads' will be disabled
as 'More Heads And Diversity MWSE' is already replacing all heads for all NPCs and you should use
only one of these MWSE-Lua mods.]],
		configKey = 'expandedHeads'
	})


	template:createExclusionsPage({
		label = 'Blacklist',
		description = 'Select the NPCs and plugins whose heads will never change.',
		showAllBlocked = false,
		configKey = 'blocked',
	    filters = {
			{label = "Plugins", type = "Plugin"},
			{label = "NPCs", type = "Object", objectType = tes3.objectType.npc}
		}
	})

	local optionList = {'Off', 'Low', 'Medium', 'High', 'Higher', 'Max'}

	local function getOptions()
		local options = {}
		for i = 1, #optionList do
			options[i] = {label = ('%s. %s'):format(i - 1, optionList[i]), value = i - 1}
		end
		return options
	end

	category:createDropdown({
		label = 'Logging level:',
		options = getOptions(),
		configKey = 'logLevel',
		description = [[Debug logging level.]]
	})

	mwse.mcm.register(template)
	logConfig(config, {indent = false})
end
event.register('modConfigReady', modConfigReady)
