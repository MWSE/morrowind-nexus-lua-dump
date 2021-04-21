--[[
	Show Value/Weight ratio, skillbook and other info in tooltip if enabled /abot
--]]

-- BEGIN configurable parameters,  -- set to false to disable

local defaultConfig = {
showValueWeightRatio = true,
showSkillBook = true,
-- prefix/suffix enabling, one should be true, one should be false
prefixReadSkillBook = true, -- e.g. *Sithis (nice to have read skillbook displayed at the inventory start)
suffixReadSkillBook = false, -- e.g. Sithis* (if you don't want to have read skillbooks displayed at inventory start)
showSource = false, -- show source mod hint
}

-- END configurable parameters

local readSkillBookMarker = '*' -- set to desired read skillbook marker

local author = 'abot'
local modName = 'Tooltip'
local modPrefix = author .. '/'.. modName
local configName = author .. modName
configName = string.gsub(configName, ' ', '_') -- replace spaces with underscores
local mcmName = author .. "'s " .. modName

local function logConfig(config, options)
	mwse.log(json.encode(config, options))
end

-- 2nd parameter advantage: anything not defined in the loaded file inherits the value from defaultConfig
local config = mwse.loadConfig(configName, defaultConfig)
assert(config)

local mcm = require(author .. '.' .. modName .. '.mcm')
mcm.config = table.copy(config)

local function checkConfig(c)
	if c.prefixReadSkillBook then
		if c.suffixReadSkillBook then
			c.suffixReadSkillBook = false
			mwse.saveConfig(configName, c, {indent = false})
		end
	end
end
checkConfig(config)

mcm.config = table.copy(config)

local function modConfigReady()
	mwse.registerModConfig(mcmName, mcm)
	mwse.log(modPrefix .. " modConfigReady")
	logConfig(config, {indent = false})
end
event.register('modConfigReady', modConfigReady)

function mcm.onClose()
	checkConfig(mcm.config)
	config = table.copy(mcm.config)
	mwse.saveConfig(configName, config, {indent = false})
end

local BOOK = tes3.objectType.book

 -- set in Initialized()
local sValue
local sWeight
local PartHelpMenu_mainId

local skillBooks = {} -- store hovered skillbooks ids

local function NewTooltipBlock(tooltip, s)
	local block = tooltip:createBlock{}
	block.minWidth = 1
	block.maxWidth = 440
	block.autoWidth = true
	block.autoHeight = true
	--- block.paddingAllSides = 4
	local label = block:createLabel{text = s}
	label.wrapText = true
	return block
end

local function SortTooltipElements(tooltip, moveFrom, prefix)
	local block = tooltip:findChild(PartHelpMenu_mainId)
	if not block then
		return
	end
	local insertBefore = -1
	local t, lt
	for i, element in ipairs(block.children) do
		t = element.text
		if t then
			lt = string.lower(t)
			if string.startswith(lt, prefix) then
				insertBefore = i + 1 -- 0-based
				break
			end
		end
	end
	if insertBefore >= 0 then
--[[
boolean reorderChildren (Element or number insertBefore, Element or number moveFrom, number count)
Returns: true if the operation succeeded, or false if at least one argument was invalid.
Moves the layout order of the children of this element.
Count elements are taken from starting child Element or index (0-based) moveFrom, and moved before the
child Element or index (0-based) insertBefore. If count is -1, all children after moveFrom are moved.
If any index is a negative number, then the index represents a distance from the end of the child list.
e.g. reorderChildren(0, -3, 3) causes the last 3 children to be moved to the start of the order (before index 0).
--]]
		block:reorderChildren(insertBefore, moveFrom, -1 )
		block:updateLayout()
	end
end

-- set in initialized()
local useMCPSoulgemValueRebalance

local function uiObjectTooltip(e)
	local obj = e.object
	if obj then
		if obj.object then
			obj = obj.object
		end
	end

	if not obj then
		return
	end

	local tooltip = e.tooltip

	if config.showValueWeightRatio then
		local value = obj.value
		if value then
			if value > 0 then
				if obj.isSoulGem then
					local itemData = e.itemData
					if itemData then
						local soul = itemData.soul
						if soul then
							local rawSoulValue = soul.soul
							if rawSoulValue then
								-- Fixup item value based on MCP feature state -- from UI Expansion
								if useMCPSoulgemValueRebalance then
									value = (rawSoulValue * rawSoulValue / 10000 + 2) * rawSoulValue
								else
									value = value * rawSoulValue
								end
								value = math.floor(value + 0.5)
							end
						end
					end
				end
				local weight = obj.weight
				if weight then
					if weight > 0 then
						local ratio = value / weight
						local s = string.format("%s/%s: %.02f", sValue, sWeight, ratio)
						---mwse.log("%s Value/Weight Ratio: %s", modPrefix, s)
						local newBlock = NewTooltipBlock(tooltip, s)
						SortTooltipElements(tooltip, newBlock, sWeight..':')
					end
				end
			end
		end
	end -- if showValueWeightRatio

	if obj.objectType == BOOK then

		local skillId = obj.skill
		if skillId then
			if skillId == -1 then -- may be read skillbook (it is -1 also with books with attached scripts)
				if skillBooks[obj.id] then
					local s = obj.name
					---mwse.log("%s id=%s skill=%s", modPrefix, obj.id, obj.skill)

					local l = string.len(s)
					if l > 0 then
						local maxBookTitleLen = 31 - string.len(readSkillBookMarker)
						if l <= maxBookTitleLen then
							if config.prefixReadSkillBook then
								if not string.startswith(s, readSkillBookMarker) then
									obj.name = readSkillBookMarker .. s -- mark read skillbook name with prefix
								end
							elseif config.suffixReadSkillBook then
								if not string.endswith(s, readSkillBookMarker) then
									obj.name = s .. readSkillBookMarker -- mark read skillbook name with suffix
								end
							end
						end
					end -- if ( l > 0 )
					return
				end -- if skillBooks[obj.id]
			elseif skillId >= 0 then
				if config.showSkillBook then
					local s = tes3.skillName[skillId]
					if s then
						s = string.format("Teaches: %s", s)
						--- mwse.log("%s Teaches: %s", modPrefix, s)
						NewTooltipBlock(tooltip, s)
						if not skillBooks[obj.id] then
							skillBooks[obj.id] = 1
						end
					end
				end
			end
		end -- if skillId

	end -- if ( obj.objectType == BOOK )

	if config.showSource then
		local s = obj.sourceMod
		if s then
			s = string.format("Source: %s", s)
			NewTooltipBlock(tooltip, s)
		end
	end

end

--[[
local function loaded()
	-- just to verify they are persistent on reload
	local s = tes3.findGMST('sValue').value
	if not (s == sValue) then
		mwse.log("%s sValue changed on reload!", modPrefix)
	end
	s = tes3.findGMST('sWeight').value
	if not (s == sWeight) then
		mwse.log("%s sWeight changed on reload!", modPrefix)
	end
	s = tes3ui.registerID('PartHelpMenu_main')
	if not (s == PartHelpMenu_mainId) then
		mwse.log("%s PartHelpMenu_mainId changed on reload!", modPrefix)
	end
end
--]]

local function initialized()
	sValue = tes3.findGMST('sValue').value
	sWeight = tes3.findGMST('sWeight').value
	useMCPSoulgemValueRebalance = tes3.hasCodePatchFeature(65)
	PartHelpMenu_mainId = tes3ui.registerID('PartHelpMenu_main')
	event.register('uiObjectTooltip', uiObjectTooltip)
	---event.register('loaded', loaded)
	---mwse.log("%s initialized", modPrefix)
end
event.register('initialized', initialized)

--[[
CodePatchFeature
id: 65,
brief: Soulgem value rebalance
description: "Rebalances soul gem values such that they are not an excessive source of income or ridiculously
overvalued, while still reflecting the usefulness of greater souls. Value now depends solely on soul size,
the empty soul gem value no longer matters.
Some selected examples:
Kagouti 20 soul 41 septims
Bull Netch 50 soul 113 septims
Scamp 100 soul 300 septims
Ogrim 165 soul 779 septims
Hunger 250 soul 2063 septims
Golden Saint 400 soul 7200 septims

rawSoulValue * ( (rawSoulValue * rawSoulValue / 10000) + 2 )
250 * ( 250 * 250 / 10000) + 2 )
400 * ( 400 * 400 / 10000) + 2 )
--]]

--[[
function myOnKeyCallback(e)
	showValueWeightRatio = math.random(0,1) == 1
	showSkillBook = math.random(0,1) == 1
	tes3.messageBox(
		{ message = string.format("showValueWeightRatio %s, showSkillBook %s", showValueWeightRatio, showSkillBook) }
	)
end

-- Filter by scan code 44 to get Z key presses only.
event.register("keyDown", myOnKeyCallback, { filter = 44 } )
--]]
