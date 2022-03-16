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
configName = string.gsub(configName, ' ', '_')
local mcmName = author .. "'s " .. modName

local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end

-- note the or defaultConfig is mostly to avoid Cisual Studio Code false problems detection
local config = mwse.loadConfig(configName, defaultConfig) or defaultConfig

local HEAD = tes3.activeBodyPart.head
local SKIN = tes3.activeBodyPartLayer.base
local ARMOR = tes3.objectType.armor
local CLOTH = tes3.objectType.clothing
local HELMETslot = tes3.armorSlot.helmet
local ROBEslot = tes3.clothingSlot.robe

local heads = {}
heads['argonian_f'] = 3
heads['argonian_m'] = 3
heads['breton_f'] = 6
heads['breton_m'] = 9
heads['dark elf_f'] = 10
heads['dark elf_m'] = 17
heads['high elf_f'] = 6
heads['high elf_m'] = 6
heads['imperial_f'] = 7
heads['imperial_m'] = 7
heads['khajiit_f_f'] = 4
heads['khajiit_f_m'] = 4
heads['nord_f'] = 13
heads['nord_m'] = 13
heads['orc_f'] = 3
heads['orc_m'] = 4
heads['redguard_f'] = 6
heads['redguard_m'] = 6
heads['wood elf_f'] = 6
heads['wood elf_m'] = 8

local lastLoggedId
local function logOnce(loggedId, ...)
	if loggedId == lastLoggedId then
		return
	end
	lastLoggedId = loggedId
	mwse.log(...)
end

local function getHeadId(b_n_raceId_sex, num)
	return string.format("%s_head_%02d", b_n_raceId_sex, num)
end

local function expandHeads() -- called in initialized()
	local logLevel = config.logLevel
	local b_n_raceId_sex
	local headNum, newMax, headId, obj, from
	for raceId_sex, _ in pairs(heads) do
		b_n_raceId_sex = 'b_n_' .. raceId_sex
		---mwse.log("%s expandHeads: b_n_raceId_sex = %s",modPrefix, b_n_raceId_sex)
		headNum = heads[raceId_sex]
		newMax = headNum
		for n = headNum + 1, 20, 1 do
			headId = getHeadId(b_n_raceId_sex, n)
			---mwse.log("%s expandHeads: n = %s, heads['%s'] = %s",modPrefix, n, raceId_sex, headNum)
			obj = tes3.getObject(headId)
			if obj then
				newMax = n
			else
				break
			end
		end
		if newMax > headNum then
			if logLevel > 1 then
				if obj.sourceless then
					from = ''
				else
					from = string.format("from '%s' ", obj.sourceMod)
				end
				mwse.log("%s expandHeads: available heads['%s'] increased to %s (%s %sdetected)",
					modPrefix, raceId_sex, newMax, obj.id , from)
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
			for _, part in pairs(item.parts) do
				if part.type == HEAD then
					return true
				end
			end
		end
	end
	return false
end

-- not entirely sure this handle thing is not causing crashes/incompatibilities though
local function delayedUpdateNode(reference)
	local handle = tes3.makeSafeObjectHandle(reference)
	timer.delayOneFrame(
		function ()
			if not handle then
				return
			end
			if not handle:valid() then
				return
			end
			local ref = handle:getObject()
			if not ref.bodyPartManager then
				return
			end
			local scene = ref.bodyPartManager:getActiveBodyPart(SKIN, HEAD)
			if scene then
				local sceneNode = scene.node
				if sceneNode then
					sceneNode:update()
				end
			end
		end, timer.real
	)
end

--[[
local function delayedUpdateNode(ref)
	timer.frame.delayOneFrame(
		function ()
			if not ref.bodyPartManager then
				return
			end
			local scene = ref.bodyPartManager:getActiveBodyPart(SKIN, HEAD)
			if scene then
				local sceneNode = scene.node
				if sceneNode then
					sceneNode:update()
				end
			end
		end
	)
end
]]

local skipCount = 0
local function bodyPartAssigned(e)
	local ref = e.reference
	local refBaseObj = ref.baseObject
	--[[
	if not refBaseObj then
		assert(refBaseObj)
		return
	end
	]]
	local refObj = ref.object
	--[[
	if not refObj then
		assert(refObj)
		return
	end
	]]
	local logLevel = config.logLevel
	local prefix = modPrefix .. ' bodyPartAssigned'
	local refId = ref.id

	if e.object then -- ignore e.g. helmet
		if logLevel > 3 then
			logOnce(refId, '%s: skipping "%s" (object = "%s")', prefix, refId, e.object.id)
		end
		return
	end

	if ref == tes3.player then
		if logLevel > 3 then
			logOnce(refId, '%s: skipping "%s" (ref = tes3.player)', prefix, refId)
		end
		return
	end

	if ref.disabled then
		if logLevel > 3 then
			logOnce(refId, '%s: skipping disabled "%s"', prefix, refId)
		end
		return
	end
	if ref.deleted then
		if logLevel > 3 then
			logOnce(refId, '%s: skipping deleted "%s"', prefix, refId)
		end
		return
	end

	local lcRefId = refId:lower()
	if lcRefId:endswith('00000000') then
		if logLevel > 3 then
			logOnce(refId, '%s: skipping "%s" (first instance, lcRefId:endswith("00000000"))', prefix, refId)
		end
		return -- always skip first instance
	end

	local bodyPart = e.bodyPart
	if not bodyPart then
		if logLevel > 3 then
			logOnce(refId, '%s: skipping "%s" (empty body part e.g. invisible sonar race)', prefix, refId)
		end
		return -- skip empty body parts (e.g. invisible sonar race)
	end

	local bodyPartIndex = e.index
	if not bodyPartIndex then
		return
	end
	if not (bodyPartIndex == HEAD) then
		return
	end
	local bodyPartType = bodyPart.partType
	if not (bodyPartType == SKIN) then
		return
	end
	---logOnce(refId, "id = %s, bodyPart = %s", refId, bodyPart)

	assert(ref.data)
	local headNum = ref.data.ab01hn
	local sourceMod = refBaseObj.sourceMod
	if sourceMod then
		local lcSourceMod = sourceMod:lower()
		if config.blocked[lcSourceMod] then
			if logLevel > 1 then
				logOnce(refId, '%s: skipping "%s" (blocked mod "%s")', prefix, refId, sourceMod)
			end
			if headNum then
				ref.data.ab01hn = nil
			end
			return
		end
	end

	local lcBaseId = refBaseObj.id:lower()
	if config.blocked[lcBaseId] then
		if logLevel > 1 then
			mwse.log('%s: skipping "%s" (blocked NPC)', prefix, refId)
		end
		if headNum then
			ref.data.ab01hn = nil
		end
		return
	end

	--[[
	if refObj == refBaseObj then
		if logLevel > 2 then
			mwse.log('%s: skipping "%s" (first instance, refObj == refBaseObj)', prefix, refId)
		end
		return
	end
	]]

	if lcRefId:startswith('nm_npc') then
		if logLevel > 1 then
			mwse.log('%s: skipping "%s" (MWSE Random NPC)', prefix, refId)
		end
		return -- skip MWSE Random NPC https://www.nexusmods.com/morrowind/mods/48992
	end

	-- only interested in clones
	local cloneCount = refBaseObj.cloneCount
	if not cloneCount then
		assert(cloneCount)
		return
	end
	if cloneCount < config.minClones then
		if logLevel > 2 then
			mwse.log('%s: skipping "%s" (cloneCount < %s)', prefix, refId, config.minClones)
		end
		return
	end

	local race = refObj.race
	if not race then
		return
	end

	if bodyPart.vampiric then
		if logLevel > 2 then
			mwse.log('%s: skipping "%s" (bodyPart.vampiric)', prefix, refId)
		end
		return
	end

--begin skip those probably doubled by some silly mod
	local blocked = refObj.blocked
	if blocked then
		if logLevel > 2 then
			mwse.log('%s: skipping "%s" (blocked)', prefix, refId)
		end
		return
	end

	local isEssential = refObj.isEssential
	if isEssential then
		if logLevel > 2 then
			mwse.log('%s: skipping "%s" (essential)', prefix, refId)
		end
		return
	end

	local factionRank = refObj.factionRank
	if not factionRank then
		factionRank = refBaseObj.factionRank
	end
	if factionRank then
		if factionRank >= 10 then
			if logLevel > 2 then
				mwse.log('%s: skipping "%s" (factionRank >= 10)', prefix, refId)
			end
			return
		end
	end
--end skip those probably doubled by some silly mod

	local raceId = race.id:lower()
	local sex = 'm'
	if refObj.female then
		sex = 'f'
	end

	local raceId_sex = string.format("%s_%s", raceId, sex)
	local b_n_raceId_sex = 'b_n_' .. raceId_sex

	local currHeadId = bodyPart.id:lower()
	if not currHeadId:startswith(b_n_raceId_sex) then
		if logLevel > 2 then
			logOnce(refId, "%s: not '%s':startswith('%s')", prefix, currHeadId, b_n_raceId_sex)
		end
		return -- skip non-vanilla format head meshes
	end

	if config.skipFullHeadCoveredActors then
		local stack = tes3.getEquippedItem({actor = ref, objectType = ARMOR, slot = HELMETslot})
		if isFullHeadCover(stack) then
			if logLevel > 0 then
				logOnce(refId, "%s: '%s' head covered by full helmet, skipping", prefix, refId)
			end
			return
		end
		stack = tes3.getEquippedItem({actor = ref, objectType = CLOTH, slot = ROBEslot})
		if isFullHeadCover(stack) then
			if logLevel > 0 then
				logOnce(refId, "%s: '%s' head covered, skipping", prefix, refId)
			end
			return
		end
	end

	if logLevel > 2 then
		if ref.sourceless then
			logOnce(refId, "%s: reference %s", prefix, refId)
		elseif ref.sourceMod then
			logOnce(refId, "%s: reference %s from %s", prefix, refId, ref.sourceMod)
		end
	end

	if config.guardsOnly then
		local objClass = refObj.class
		if not objClass then
			return -- it happens a lot /abot
		end
		local classId = objClass.id
		local lcClassId = string.lower(classId)
		if not (lcClassId == 'guard') then
			return
		end
	end

	if ref.mobile then -- IMPORTANT!!! it seems I can safely access the variable only when mobile is available
		if refBaseObj.script then
			local context = ref.context
			if context then
				local variables = context:getVariableData()
				if variables then
					if variables['companion']
					or variables['Companion'] then
						if logLevel > 0 then
							logOnce(refId, "%s: skipping cloned companion %s", prefix, refId)
						end
						return
					end
				end
			end
		end
	elseif logLevel > 3 then
		logOnce(refId, "%s: %s has invalid .mobile", prefix, refId)
	end

	if mwscript.getSpellEffects({ reference = ref, spell = 'werewolf blood' }) then
		if logLevel > 0 then
			logOnce(refId, "%s: skipping cloned werewolf %s", prefix, refId)
		end
		return
	end

	local headId, obj

	if headNum then
		headId = getHeadId(b_n_raceId_sex, headNum)
		if not (currHeadId == headId) then
			if skipCount > 0 then
				skipCount = skipCount - 1
				return
			end
			skipCount = 1
			if logLevel > 0 then
				logOnce(refId, "%s: '%s' head mesh restored from %s to %s", prefix, refId, currHeadId, headId)
			end
			obj = tes3.getObject(headId)
			if obj then
				e.bodyPart = obj
				delayedUpdateNode(ref)
			end
		end
		return
	end

	if logLevel > 2 then
		logOnce(refId, "%s: %s head mesh %s", prefix, refId, currHeadId)
	end

	local headMax = heads[raceId_sex]
	if not headMax then
		if logLevel > 2 then
			logOnce(refId, "%s: not heads['%s']", prefix, raceId_sex)
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

	if not (currHeadId == headId) then
		if logLevel > 0 then
			-- note ref.cell may still be nil here!
			logOnce(refId, "%s: '%s' in '%s' head mesh changed from %s to %s", prefix, refId, ref.cell, currHeadId, headId)
		end
		local obj = tes3.getObject(headId)
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
	else
		return false
	end
end

local function initialized()
	if isMoreHeadAndDiversityMWSEActive() then
		return
	end
	expandHeads()
	event.register('bodyPartAssigned', bodyPartAssigned)
	mwse.log("%s initialized", modPrefix)
end
event.register('initialized', initialized)


local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()
	if isMoreHeadAndDiversityMWSEActive() then
		if not isMoreHeadAndDiversityActive() then
			mwse.log("%s [WARNING]: 'More Heads And Diversity MWSE' mod detected, but the needed 'MoreHeads' plugin is not loaded!", modPrefix)
		end
		mwse.log("%s [WARNING]: 'More Heads And Diversity MWSE' mod detected, disabling 'Smart Heads' mod as 'More Heads And Diversity MWSE' already replaces cloned NPCs heads", modPrefix)
		return
	end
	---local sYes = tes3.findGMST(tes3.gmst.sYes).value
	---local sNo = tes3.findGMST(tes3.gmst.sNo).value

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		mwse.saveConfig(configName, config, {indent = false})
	end

	-- Preferences Page
	local preferences = template:createSideBarPage{
		label="Preferences",
		postCreate = function(self)
			-- total width must be 2
			self.elements.sideToSideBlock.children[1].widthProportional = 1.3
			self.elements.sideToSideBlock.children[2].widthProportional = 0.7
		end
	}

	local sidebar = preferences.sidebar
	sidebar:createInfo{text = ""}

	local controls = preferences:createCategory{label = mcmName}

	controls:createInfo({text = 'Randomizes cloned NPCs standard heads'})

	controls:createSlider{
		label = "Min clones number",
		variable = createConfigVariable("minClones")
		,min = 2, max = 10,
		description = [[
Minimum number of clones needed for NPC head to be randomized (default: 2).
If you think you are using quest mods placing multiple copies of the same quest character NPC, you may want to increase this value
(to avoid the risk of seeing what in theory is the same character having different faces in different places),
else it may be safe to decrease the value to 2. Or you could add the NPCs to the Blacklist.
]]
	}

	controls:createYesNoButton{
		label = "Skip actor clones wearing full covering helmet/mask",
		variable = createConfigVariable("skipFullHeadCoveredActors"),
		description = [[
Skip changing faces of actor clones when they are wearing a full covering helmet/mask. Default: Yes.
By setting it to No you may be able to see different heads if/when removing the full helmet from the cloned actors (e.g. when you loot the armor from a killed ordinator clone).
]]
	}

	controls:createYesNoButton{
		label = "Only process guard clones",
		variable = createConfigVariable("guardsOnly"),
		description = [[
Only process clones of actors belonging to the special Guard class. Default: No.
]]
	}

	controls:createYesNoButton{
		label = "Use expanded standard heads if detected",
		variable = createConfigVariable("expandedHeads"),
		description = [[
Use expanded standard heads if detected (e.g. from 'More Heads And Diversity' mod. Default: yes.
Else it will only use default standard heads.
Note: if you are using also 'More Heads And Diversity MWSE' add-on, 'Smart Heads' will be disabled
as 'More Heads And Diversity MWSE' is already replacing all heads for all NPCs and you should use
only one of these MWSE-Lua mods.
]]
	}

	template:createExclusionsPage{
		label = "Blacklist",
		description = "Select the NPCs and plugins whose heads will never change.",
		showAllBlocked = false,
		variable = createConfigVariable("blocked"),
	    filters = {
			{ label = "Plugins", type = "Plugin", },
			{ label = "NPCs", type = "Object", objectType = tes3.objectType.npc	}
		}
	}

	controls:createDropdown{
		label = "Logging level:",
		options = {
			{ label = "0. Off", value = 0 },
			{ label = "1. Low", value = 1 },
			{ label = "2. Medium", value = 2 },
			{ label = "3. High", value = 3 },
			{ label = "4. Max", value = 4 },
		},
		variable = createConfigVariable("logLevel"),
		description = [[
Debug logging level. Default: 0. Off.
]]
	}

	mwse.mcm.register(template)
	logConfig(config, {indent = false})
end
event.register('modConfigReady', modConfigReady)
