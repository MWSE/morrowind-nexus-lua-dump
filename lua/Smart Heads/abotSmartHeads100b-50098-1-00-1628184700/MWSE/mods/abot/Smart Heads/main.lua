--[[
randomizes cloned NPCs standard heads
]]

local defaultConfig = {
skipFullHeadCoveredActors = true,
debugLevel = 0, -- 0 = Minimum, 1 = Low, 2 = Medium, 3 = High
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

local config = mwse.loadConfig(configName, defaultConfig)

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
heads['breton_m'] = 8
heads['dark elf_f'] = 10
heads['dark elf_m'] = 17
heads['high elf_f'] = 6
heads['high elf_m'] = 6
heads['imperial_f'] = 7
heads['imperial_m'] = 7
heads['khajiit_f_f'] = 4
heads['khajiit_f_m'] = 4
heads['nord_f'] = 8
heads['nord_m'] = 8
heads['orc_f'] = 3
heads['orc_m'] = 4
heads['redguard_f'] = 6
heads['redguard_m'] = 6
heads['wood elf_f'] = 5
heads['wood elf_m'] = 5

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

local function delayedUpdateNode(reference)
	local ref = tes3.makeSafeObjectHandle(reference)
	timer.frame.delayOneFrame(
		function ()
			if not ref:valid() then
				return
			end
			if not ref.bodyPartManager then
				return
			end
			local sceneNode = ref.bodyPartManager:getActiveBodyPart(SKIN, HEAD).node
			if sceneNode then
				sceneNode:update()
			end
		end		
	)
end

local skipCount = 0
local function bodyPartAssigned(e)
	local ref = e.reference
	if ref.id:endswith('00000000') then
		return -- always skip first instance
	end

	local debugLevel = config.debugLevel
	local prefix = modPrefix .. ' bodyPartAssigned'

	local bodyPart = e.bodyPart
	if not bodyPart then
		return -- skip empty body parts (e.g. invisible sonar race)
	end

	---mwse.log("id = %s, bodyPart = %s", ref.id, bodyPart)
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

	local refObj = ref.object
	if refObj.baseObject then
		refObj = refObj.baseObject
	end

	-- only interested in clones
	local cloneCount = refObj.cloneCount
	if not cloneCount then
		return
	end
	if cloneCount < 2 then
		return
	end

	local race = refObj.race
	if not race then
		return
	end

	if bodyPart.vampiric then
		return
	end

--begin skip those probably doubled by some silly mod
	local blocked = refObj.blocked
	if blocked then
		return
	end

	local isEssential = refObj.isEssential
	if isEssential then
		return
	end

	local factionRank = refObj.factionRank
	if factionRank then
		if factionRank >= 10 then
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
		if debugLevel > 1 then
			mwse.log("%s: not '%s':startswith('%s')", prefix, currHeadId, b_n_raceId_sex)
		end
		return -- skip non-vanilla format head meshes
	end

	if config.skipFullHeadCoveredActors then
		local stack = tes3.getEquippedItem({actor = ref, objectType = ARMOR, slot = HELMETslot})
		if isFullHeadCover(stack) then
			if debugLevel > 0 then
				mwse.log("%s: '%s' head covered by full helmet, skipping", prefix, ref.id)
			end
			return
		end
		stack = tes3.getEquippedItem({actor = ref, objectType = CLOTH, slot = ROBEslot})
		if isFullHeadCover(stack) then
			if debugLevel > 0 then
				mwse.log("%s: '%s' head covered, skipping", prefix, ref.id)
			end
			return
		end
	end

	local headId
	local headNum = ref.data.ab01hn
	
	if headNum then
		headId = string.format("%s_head_%02d", b_n_raceId_sex, headNum)
		if not (currHeadId == headId) then
			if skipCount > 0 then
				skipCount = skipCount - 1
				return
			end	
			skipCount = 1
			if debugLevel > 0 then
				mwse.log("%s: '%s' head mesh restored from %s to %s", prefix, ref.id, currHeadId, headId)
			end
			e.bodyPart = tes3.getObject(headId)
			delayedUpdateNode(ref)
		end
		return
	end
	
	if debugLevel > 2 then
		mwse.log("%s: %s head mesh %s", prefix, ref.id, currHeadId)
	end

	local headMax = heads[raceId_sex]
	if not headMax then
		if debugLevel > 2 then
			mwse.log("%s: not heads['%s']", prefix, raceId_sex)
		end
		return -- not a standard race
	end

	headNum = lastHeadNum + 1
	if headNum > headMax then
		headNum = 2
	end
	lastHeadNum = headNum

	headId = string.format("%s_head_%02d", b_n_raceId_sex, headNum)

	if not (currHeadId == headId) then
		if debugLevel > 0 then
			mwse.log("%s: '%s' head mesh changed from %s to %s", prefix, ref.id, currHeadId, headId)
		end
		e.bodyPart = tes3.getObject(headId)
		ref.data.ab01hn = headNum
		delayedUpdateNode(ref)
	end
end

local function initialized()
	event.register('bodyPartAssigned', bodyPartAssigned)
	local msg = string.format('%s initialized', modPrefix)
	mwse.log(msg)
end
event.register('initialized', initialized)


local function createConfigVariable(varId)
	return mwse.mcm.createTableVariable{id = varId,	table = config}
end

local function modConfigReady()

	---local sYes = tes3.findGMST(tes3.gmst.sYes).value
	---local sNo = tes3.findGMST(tes3.gmst.sNo).value

	local template = mwse.mcm.createTemplate(mcmName)

	template.onClose = function()
		mwse.saveConfig(configName, config, {indent = false})
	end

	-- Preferences Page
	local preferences = template:createSideBarPage{
		label="Info",
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
	
	controls:createYesNoButton{
		label = "Skip actor clones wearing full covering helmet/mask",
		variable = createConfigVariable("skipFullHeadCoveredActors"),
		description = [[
Skip changing faces of actor clones when they are wearing a full covering helmet/mask. Default: Yes.
By setting it to No you may be able to see different heads if/when removing the full helmet from the cloned actors (e.g. when you loot the armor from a killed ordinator clone).
]]
	}

	controls:createDropdown{
		label = "Logging level:",
		options = {
			{ label = "0. Off", value = 0 },
			{ label = "1. Low", value = 1 },
			{ label = "2. Medium", value = 2 },
			{ label = "3. High", value = 3 },
		},
		variable = createConfigVariable("debugLevel"),
		description = [[
Debug logging level. Default: 0. Off.
]]
	}

	mwse.mcm.register(template)
	logConfig(config, {indent = false})
end
event.register('modConfigReady', modConfigReady)

