local windowBox = auxUi.deepLayoutCopy(I.MWUI.templates.boxTransparentThick)
windowBox.content[1].props.alpha = 0.85
local buttonTemplate = require("scripts.Uncapper.buttonTemplate")
local levelUpDialogueClosing = false

-- Color helper
function getColorFromGameSettings(gmst)
	local result = core.getGMST(gmst)
	if not result then
		return util.color.rgb(1,1,1)
	end
	local rgb = {}
	for color in string.gmatch(result, '(%d+)') do
		table.insert(rgb, tonumber(color))
	end
	if #rgb ~= 3 then
		print("Unexpected color triplet size = " .. #rgb .. " ; using white")
		return util.color.rgb(1, 1, 1)
	end
	return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end

-- gmst cache
local gmstMults = {}
for i = 1, 10 do
	gmstMults[i] = core.getGMST('iLevelUp' .. string.format('%02d', i) .. 'Mult') or 1
end
local normalColor = getColorFromGameSettings('FontColor_color_normal')
local overColor =   getColorFromGameSettings('FontColor_color_normal_over')

local texCache = {}

local function tex(path)
	if not texCache[path] then
		texCache[path] = ui.texture{ path = path }
	end
	return texCache[path]
end


local paddingTemplates = {}
local function makePadding(x, y)
	if not paddingTemplates[x .. "/" .. y] then
		local borderV = v2(x, y)
		paddingTemplates[x .. "/" .. y] = {
			type = ui.TYPE.Container,
			content = ui.content {
				{
					props = {
						size = borderV,
					},
				},
				{
					external = { slot = true },
					props = {
						position = borderV,
						relativeSize = v2(1, 1),
					},
				},
				{
					props = {
						position = borderV,
						relativePosition = v2(1, 1),
						size = borderV,
					},
				},
			}
		}
	end
	return paddingTemplates[x .. "/" .. y]
end

local function wrapInPadding(elemTable, x, y)
	return {
		template = makePadding(x, y),
		content = ui.content(elemTable),
	}
end

----- Constants -----
local MAX_COINS = 3
local PER_COL = 4
local COIN_SIZE = 16
local GRID_W = 390
local COL_GAP = 16
local WINDOW_PADDING_X = 20
local WINDOW_PADDING_Y = 10
local ROW_H = math.max(constants.textNormalSize, COIN_SIZE)+3
local PREFIX_W = COIN_SIZE + constants.textNormalSize * 1.25
local COLUMN_SPACER = 0
local X_SIZE = constants.textNormalSize

local ATTR_IDS = {
	'strength', 'intelligence', 'willpower', 'agility',
	'speed', 'endurance', 'personality', 'luck',
}

----- State -----
local refs = {
	root = nil,
	attr = {},
	coinRow = nil,
	okLabel = nil,
	closeLabel = nil,
}
local spentAttrs = {}
local coinCount = MAX_COINS
local hoveredAttr = nil
local hoveredOk = false
local hoveredClose = false
local controllerRow = 0
local controllerCol = 1
local dpadMoveDirection = nil
local lastDpadMove = 0

----- Multiplier logic -----
local function getRawMult(attrId)
	local ups = (stats.level.skillIncreasesForAttribute or {})[attrId] or 0
	if ups <= 0 then return 1 end
	return gmstMults[math.min(ups, 10)] or 1
end

-- cap-aware gain
function getAttrAllowedGain(attrId)
	local minGain = 0
	if attrId == "luck" and S_luckGains > 0 then
		minGain = math.max(1, S_luckGains)
	end
	local cap = capTable[attrId]
	if not cap then return getRawMult(attrId) end
	local base = math.floor(stats[attrId].base)
	if base >= cap.hardCap then return minGain end

	local ups = (stats.level.skillIncreasesForAttribute or {})[attrId] or 0
	local rawMult
	if ups <= 0 then
		rawMult = 1
	elseif base >= cap.softCap and cap.neededSkillIncMult > 1 then
		local effectiveUps = math.max(0, math.floor((ups - cap.neededSkillIncFlat) / cap.neededSkillIncMult + 0.5))
		if effectiveUps <= 0 then
			rawMult = 1
		else
			rawMult = gmstMults[math.min(effectiveUps, 10)] or 1
		end
	else
		rawMult = gmstMults[math.min(ups, 10)] or 1
	end

	local gain = rawMult

	-- clamp to maxGainsPerLevel above soft cap
	if base >= cap.softCap and cap.maxGainsPerLevel then
		gain = math.min(gain, cap.maxGainsPerLevel)
	end

	-- clamp to hard cap
	gain = math.min(gain, cap.hardCap - base)

	return math.max(minGain, gain)
end

local function getAttrGain(attrId)
	if S_AttributeUncapper then
		return getAttrAllowedGain(attrId)
	end
	return getRawMult(attrId)
end

----- Class image -----
local function getLevelupClassImage()
	local s = stats.level.skillIncreasesForSpecialization or {}
	local combat, magic, stealth = s.combat or 0, s.magic or 0, s.stealth or 0
	local total = combat + magic + stealth
	if total == 0 then return 'acrobat' end
	local cf = math.floor(combat / total * 10)
	local mf = math.floor(magic / total * 10)
	local sf = math.floor(stealth / total * 10)
	
	local ret = 'acrobat'
	
	if cf > 7 then ret = 'warrior'
	elseif mf > 7 then ret = 'mage'
	elseif sf > 7 then ret = 'thief'
	end
	
	if cf == 7 then
		ret = 'warrior'
	elseif cf == 6 then
		if sf == 1 then ret = 'barbarian'
		elseif sf == 3 then ret = 'crusader'
		else ret = 'knight'
		end
	elseif cf == 5 then
		if sf == 3 then ret = 'scout'
		else ret = 'archer'
		end
	elseif cf == 4 then
		ret = 'rogue'
	end
	
	if mf == 7 then
		ret = 'mage'
	elseif mf == 6 then
		if cf == 2 then ret = 'sorcerer'
		elseif combat == 3 then ret = 'healer'
		else ret = 'battlemage'
		end
	elseif mf == 5 then
		ret = 'witchhunter'
	elseif mf == 4 then
		ret = 'spellsword'
	end
	
	if sf == 7 then
		ret = 'thief'
	elseif sf == 6 then
		if mf == 1 then ret = 'agent'
		elseif magic == 3 then ret = 'assassin'
		else ret = 'acrobat'
		end
	elseif sf == 5 then
		if magic == 3 then ret = 'monk'
		else ret = 'pilgrim'
		end
	elseif sf == 3 then
		if mf == 3 then ret = 'bard' end
	end
	return ret
end

local buildLayout, refreshUI

local disabledColor = util.color.rgb(0.5, 0.5, 0.5)

local function spacer(x)
	return { props = { size = v2(1, 1) * x } }
end

local function getControllerAttr()
	if controllerRow <= 0 or controllerRow > PER_COL then return nil end
	return ATTR_IDS[controllerRow + (controllerCol - 1) * PER_COL]
end

-- update a single attr row's prefix, name, and value
local function updateAttr(attrId)
	local row = refs.attr[attrId]
	local base = math.floor(stats[attrId].base)
	local gain = getAttrGain(attrId)
	local disabled = (gain <= 0)
	local spent = false
	local spentCount = 0
	for _, id in ipairs(spentAttrs) do
		if id == attrId then spent = true; spentCount = spentCount + 1 end
	end
	local previewVal = spentCount > 0 and (base + gain * spentCount) or base
	local txtColor = disabled and disabledColor
		or hoveredAttr == attrId and overColor
		or getControllerAttr() == attrId and overColor
		or normalColor
	local multStr = (not disabled and gain > 1) and ('x' .. tostring(gain)) or nil

	-- update prefix content
	local prefixItems = {}
	for c = 1, spentCount do
		-- spent coin
		table.insert(prefixItems, {
			type = ui.TYPE.Image,
			props = {
				resource = tex('icons\\tx_goldicon.dds'),
				size = v2(COIN_SIZE/spentCount, COIN_SIZE/spentCount),
			},
		})
		table.insert(prefixItems, spacer(1))
	end
	if multStr then
		-- multiplier
		table.insert(prefixItems, {
			template = I.MWUI.templates.textNormal,
			props = {
				text = multStr,
				textColor = txtColor,
			},
		})
		table.insert(prefixItems, spacer(1))
	end
	row.layout.content.prefix.content = ui.content(prefixItems)

	-- update name color
	row.layout.content.attrName.props.textColor = txtColor

	-- update value
	row.layout.content.attrValue.props.text = tostring(previewVal)
	row.layout.content.attrValue.props.textColor = txtColor

	row:update()
end

-- update the coin row
local function updateCoins()
	local unspent = coinCount - #spentAttrs
	local coinChildren = {}
	for c = 1, unspent do
		-- unspent coin
		table.insert(coinChildren, {
			type = ui.TYPE.Image,
			props = {
				resource = tex('icons\\tx_goldicon.dds'),
				size = v2(COIN_SIZE, COIN_SIZE),
			},
		})
		if c < unspent then
			table.insert(coinChildren, spacer(8))
		end
	end
	refs.coinRow.layout.content = ui.content(coinChildren)
	refs.coinRow:update()
end

----- Conditional refresh -----
-- 'click'              - all attrs + coins (attr was toggled)
-- 'hover', id [, prev] - just the listed attr(s)
-- 'ok'                 - just the ok label
-- 'close'              - just the close label
refreshUI = function(hint, a, b)
	if not refs.root or levelUpDialogueClosing then return end

	if hint == 'ok' then
		local active = hoveredOk or (controllerRow == 5 and controllerCol ~= 3)
		refs.okLabel.layout.props.textColor = active and overColor or normalColor
		refs.okLabel:update()
		return
	end

	if hint == 'close' then
		local active = hoveredClose or (controllerCol == 3 and controllerRow > 0)
		refs.closeLabel.layout.props.textColor = active and overColor or normalColor
		refs.closeLabel:update()
		return
	end

	if hint == 'hover' then
		if a then updateAttr(a) end
		if b then updateAttr(b) end
		return
	end

	-- 'click' or fallback: all attrs + coins
	for _, attrId in ipairs(ATTR_IDS) do
		updateAttr(attrId)
	end
	updateCoins()
end


----- Click handlers -----
local onAttrClicked = function(attrId)
	ambient.playSound("menu click")
	if attrId == 'luck' and S_luckGains > 0 then
		-- deselect last luck entry when no free coins
		if #spentAttrs >= coinCount then
			for i = #spentAttrs, 1, -1 do
				if spentAttrs[i] == 'luck' then
					table.remove(spentAttrs, i)
					refreshUI('click')
					return
				end
			end
		end
	else
		for i, id in ipairs(spentAttrs) do
			if id == attrId then
				table.remove(spentAttrs, i)
				refreshUI('click')
				return
			end
		end
	end
	if #spentAttrs >= coinCount then
		spentAttrs[coinCount] = attrId
	else
		table.insert(spentAttrs, attrId)
	end
	refreshUI('click')
end

-- How many skill increases were used above the minimum due to softcap? (Based on "Improved Vanilla Leveling"'s formula)
local function getExtraSkillIncs(attrId)
    local ups = (stats.level.skillIncreasesForAttribute or {})[attrId] or 0
    if ups <= 0 then return 0 end
	
    local cap = capTable[attrId]
    local base = math.floor(stats[attrId].base)
	if not (S_AttributeUncapper and cap and base >= cap.softCap and (cap.neededSkillIncMult > 1 or cap.neededSkillIncFlat > 0)) then return nil end
	
    local gain = getAttrGain(attrId)

    local minEffectiveUps = ups
    for i = 1, 10 do
        if (gmstMults[i] or 1) >= gain then
            minEffectiveUps = i
            break
        end
    end

    local minRealUps = minEffectiveUps * cap.neededSkillIncMult + cap.neededSkillIncFlat
    return minRealUps - minEffectiveUps
end

local onOkClicked = function()
    if #spentAttrs < coinCount then
        local msg = core.getGMST('sNotifyMessage36')
        if msg then ui.showMessage(msg) end
        return
    end
	
	-- ImprovedVanillaLeveling support
	if core.contentFiles.has("ImprovedVanillaLeveling.omwscripts") then
		local IVLSection = storage.playerSection('SettingsPlayerImprovedVanillaLeveling')
		if IVLSection:get("keepAttributeProgress") then
			local surplusSkillIncs = {}
			for _, attrId in ipairs(spentAttrs) do
				surplusSkillIncs[attrId] = getExtraSkillIncs(attrId)
			end
			core.sendGlobalEvent("Uncapper_IVLRoundtrip",{self, surplusSkillIncs})
		end
	end
	
	-- inc attrs
    for _, attrId in ipairs(spentAttrs) do
        stats[attrId].base = stats[attrId].base + getAttrGain(attrId)
    end
	
	-- inc HP
	local healthGain = stats.endurance.base * (core.getGMST('fLevelUpHealthEndMult') or 0.1)
	local hp = types.Actor.stats.dynamic.health(self)
	hp.base = hp.base + healthGain
	hp.current = math.max(1, hp.current + healthGain)

	-- inc Level
	stats.level.current = stats.level.current + 1

	-- resets
	stats.level.progress = math.max(0, stats.level.progress - core.getGMST('iLevelUpTotal'))
	local incs = stats.level.skillIncreasesForAttribute
	for _, id in ipairs(ATTR_IDS) do 
		incs[id] = 0 
	end
	stats.level.skillIncreasesForSpecialization.combat = 0
	stats.level.skillIncreasesForSpecialization.magic = 0
	stats.level.skillIncreasesForSpecialization.stealth = 0
	spentAttrs = {}
	levelUpDialogueClosing = true
	I.UI.removeMode('LevelUp')
end

-- 2 frames later..
function Uncapper_IVLRoundtrip(surplusSkillIncs)
	local incs = stats.level.skillIncreasesForAttribute
	for attrId, consumed in pairs(surplusSkillIncs) do
		incs[attrId] = math.max(0,incs[attrId] - math.max(0,math.floor(consumed + 0.5)))
	end
end

----- Controller navigation -----
-- 5 rows (incl ok button), 3 columns (incl x button)
local function controllerMove(dRow, dCol)
	if not refs.root or levelUpDialogueClosing then return end
	local prevAttr = getControllerAttr()
	local prevOk = (controllerRow == 5 and controllerCol ~= 3)
	local prevClose = (controllerCol == 3 and controllerRow > 0)

	if controllerRow == 0 then
		-- entering from no selection
		controllerRow = 1
		if dCol > 0 then
			controllerCol = 2
		elseif dCol < 0 then
			controllerCol = 1
		end
	elseif dRow ~= 0 and controllerCol ~= 3 then
		-- up/down in attr/ok columns
		controllerRow = controllerRow + dRow
		if controllerRow < 1 then controllerRow = 5 end
		if controllerRow > 5 then controllerRow = 1 end
	elseif dCol ~= 0 then
		-- left/right
		controllerCol = controllerCol + dCol
		if controllerCol < 1 then controllerCol = 1 end
		if controllerCol > 3 then controllerCol = 3 end
		-- entering col 3 from row 5: clamp to attr range
		if controllerCol == 3 and controllerRow == 5 then
			controllerRow = PER_COL
		end
	end

	local newAttr = getControllerAttr()
	local newOk = (controllerRow == 5 and controllerCol ~= 3)
	local newClose = (controllerCol == 3 and controllerRow > 0)

	-- refresh only what changed
	if prevAttr ~= newAttr then
		if prevAttr then updateAttr(prevAttr) end
		if newAttr then updateAttr(newAttr) end
	end
	if prevOk ~= newOk then refreshUI('ok') end
	if prevClose ~= newClose then refreshUI('close') end
end

local function controllerConfirm()
	if controllerRow <= 0 then return end
	ambient.playSound("menu click")
	-- close button
	if controllerCol == 3 then
		levelUpDialogueClosing = true
		I.UI.removeMode('LevelUp')
		return
	end
	-- ok button
	if controllerRow == 5 then
		onOkClicked()
		return
	end
	-- attr click
	local attrId = getControllerAttr()
	if attrId and getAttrGain(attrId) > 0 then
		onAttrClicked(attrId)
	end
end

function onLevelUpControllerButtonPress(key)
	if not refs.root or levelUpDialogueClosing then return end
	if key == input.CONTROLLER_BUTTON.DPadDown then
		dpadMoveDirection = 1
		controllerMove(1, 0)
		lastDpadMove = core.getRealTime() + 0.12
	elseif key == input.CONTROLLER_BUTTON.DPadUp then
		dpadMoveDirection = -1
		controllerMove(-1, 0)
		lastDpadMove = core.getRealTime() + 0.12
	elseif key == input.CONTROLLER_BUTTON.DPadRight then
		controllerMove(0, 1)
	elseif key == input.CONTROLLER_BUTTON.DPadLeft then
		controllerMove(0, -1)
	elseif key == input.CONTROLLER_BUTTON.A then
		controllerConfirm()
	end
end

function onLevelUpControllerButtonRelease(key)
	if key == input.CONTROLLER_BUTTON.DPadDown or key == input.CONTROLLER_BUTTON.DPadUp then
		dpadMoveDirection = nil
	end
end

function onLevelUpFrame(dt)
	if not refs.root or levelUpDialogueClosing then return end
	if dpadMoveDirection then
		local now = core.getRealTime()
		if now > lastDpadMove + 0.1 then
			controllerMove(dpadMoveDirection, 0)
			lastDpadMove = now
		end
	end
end



----- Layout builder -----
buildLayout = function()
	levelUpDialogueClosing = false
	local newLevel = stats.level.current + 1
	
	------------------------------------------ 1. CLASS IMAGE ------------------------------------------
	local levelupImage = wrapInPadding({
		-- class image
		{
			template = I.MWUI.templates.box,
			content = ui.content {
				-- levelup image
				{
					type = ui.TYPE.Image,
					props = {
						resource = tex('textures\\levelup\\' .. getLevelupClassImage() .. '.dds'),
						size = v2(GRID_W, 190),
					},
				},
			},
		},
	}, WINDOW_PADDING_X, WINDOW_PADDING_Y)
	
	------------------------------------------ 2. LEVEL TEXT ------------------------------------------
	local levelLabel = (core.getGMST('sLevelUpMenu1') or 'You have reached Level')
		.. ' ' .. tostring(newLevel)
	-- level text
	local levelText = {
		template = I.MWUI.templates.textNormal,
		props = {
			text = levelLabel,
		},
	}
	
	------------------------------------------ 3. FLAVOR TEXT ------------------------------------------
	local flavorText = core.getGMST('Level_Up_Level'..(stats.level.current + 1)) or core.getGMST('Level_Up_Default') or ''
	-- flavor paragraph
	local flavorParagraph = {
		template = I.MWUI.templates.textParagraph,
		props = {
			text = flavorText,
			size = v2(GRID_W, 0),
		},
	}
	
	------------------------------------------ 4. COIN ROW ------------------------------------------
	local unspent = coinCount - #spentAttrs
	local coinChildren = {}
	for c = 1, unspent do
		-- unspent coin
		table.insert(coinChildren, {
			type = ui.TYPE.Image,
			props = {
				resource = tex('icons\\tx_goldicon.dds'),
				size = v2(COIN_SIZE, COIN_SIZE),
			},
		})
		if c < unspent then
			table.insert(coinChildren, spacer(8))
		end
	end
	-- coin row
	refs.coinRow = ui.create({
		type = ui.TYPE.Flex,
		props = {
			size = v2(GRID_W, COIN_SIZE),
			horizontal = true,
			align = ui.ALIGNMENT.Center,
		},
		content = ui.content(coinChildren),
	})
	
	------------------------------------------ 5. ATTRIBUTE GRID ------------------------------------------
	local function makeAttrRow(attrId)
		local base = math.floor(stats[attrId].base)
		local gain = getAttrGain(attrId)
		local disabled = (gain <= 0)
		
		local spent = false
		local spentCount = 0
		for _, id in ipairs(spentAttrs) do
			if id == attrId then spent = true; spentCount = spentCount + 1 end
		end
		
		local previewVal = spentCount > 0 and (base + gain * spentCount) or base
		
		local txtColor = disabled and disabledColor
			or hoveredAttr == attrId and overColor
			or normalColor
		
		local multStr = (not disabled and gain > 1) and ('x' .. tostring(gain)) or nil
		
		local nameEvents = not disabled and {
			mouseClick = async:callback(function() onAttrClicked(attrId) end),
			focusGain  = async:callback(function()
				local prev = hoveredAttr
				local prevController = getControllerAttr()
				local prevOk = (controllerRow == 5 and controllerCol ~= 3)
				local prevClose = (controllerCol == 3 and controllerRow > 0)
				hoveredAttr = attrId
				controllerRow = 0
				refreshUI('hover', attrId, prev or prevController)
				if prevOk then refreshUI('ok') end
				if prevClose then refreshUI('close') end
			end),
			focusLoss  = async:callback(function()
				if hoveredAttr == attrId then
					hoveredAttr = nil
					refreshUI('hover', attrId)
				end
			end),
		} or nil
		
		-- prefix: coin icon(s) + multiplier
		local prefixItems = {}
		for c = 1, spentCount do
			-- spent coin
			table.insert(prefixItems, {
				type = ui.TYPE.Image,
				props = {
					resource = tex('icons\\tx_goldicon.dds'),
					size = v2(COIN_SIZE, COIN_SIZE),
				},
			})
			table.insert(prefixItems, spacer(1))
		end
		if multStr then
			-- multiplier
			table.insert(prefixItems, {
				template = I.MWUI.templates.textNormal,
				props = {
					text = multStr,
					textColor = txtColor,
				},
			})
			table.insert(prefixItems, spacer(1))
		end
		
		-- attr row element
		refs.attr[attrId] = ui.create({
			type = ui.TYPE.Flex,
			props = {
				horizontal = true,
				autoSize = false,
				size = v2((GRID_W - COLUMN_SPACER) / 2, ROW_H),
				arrange = ui.ALIGNMENT.Center,
			},
			content = ui.content {
				-- prefix
				{
					name = 'prefix',
					type = ui.TYPE.Flex,
					props = {
						horizontal = true,
						autoSize = false,
						size = v2(PREFIX_W, ROW_H),
						align = ui.ALIGNMENT.End,
						arrange = ui.ALIGNMENT.Center,
					},
					content = ui.content(prefixItems),
				},
				-- attr name
				{
					name = 'attrName',
					template = I.MWUI.templates.textNormal,
					props = {
						text = statNames[attrId],
						textColor = txtColor,
					},
					events = nameEvents,
				},
				spacer(3),
				-- attr value
				{
					name = 'attrValue',
					template = I.MWUI.templates.textNormal,
					props = {
						text = tostring(previewVal),
						textColor = txtColor,
					},
				},
			},
		})
		return refs.attr[attrId]
	end
	
	---------------------------- Generate columns ----------------------------
	local leftCol, rightCol = {}, {}
	for i = 1, PER_COL do
		table.insert(leftCol, makeAttrRow(ATTR_IDS[i]))
		table.insert(rightCol, makeAttrRow(ATTR_IDS[PER_COL + i]))
	end
	
	-- attribute table
	local attrGrid = {
		type = ui.TYPE.Flex,
		props = {
			horizontal = true,
			autoSize = true,
		},
		content = ui.content {
			spacer(WINDOW_PADDING_X),
			-- left column
			{
				type = ui.TYPE.Flex,
				props = {
					horizontal = false,
					autoSize = true,
				},
				content = ui.content(leftCol),
			},
			spacer(COLUMN_SPACER),
			-- right column
			{
				type = ui.TYPE.Flex,
				props = {
					horizontal = false,
					autoSize = true,
				},
				content = ui.content(rightCol),
			},
		},
	}
	
	------------------------------------------ 6. OK BUTTON ------------------------------------------
	local okText = " "..(core.getGMST('sOK') or 'OK').." "
	-- ok label element
	refs.okLabel = ui.create({
		template = I.MWUI.templates.textNormal,
		props = {
			text = okText,
			textColor = normalColor,
		},
	})
	-- ok button row
	local okButton = {
		type = ui.TYPE.Flex,
		props = {
			horizontal = true,
			autoSize = false,
			size = v2(GRID_W + WINDOW_PADDING_X*2, constants.textNormalSize + 20),
			align = ui.ALIGNMENT.End,
		},
		content = ui.content {
			-- ok border
			wrapInPadding({
			{
				template = buttonTemplate,
				content = ui.content {
					refs.okLabel,
				},
				events = {
					mouseClick = async:callback(function() ambient.playSound("menu click"); onOkClicked() end),
					focusGain = async:callback(function()
						local prevAttr = getControllerAttr()
						local prevClose = (controllerCol == 3 and controllerRow > 0)
						hoveredOk = true
						controllerRow = 0
						refreshUI('ok')
						if prevAttr then updateAttr(prevAttr) end
						if prevClose then refreshUI('close') end
					end),
					focusLoss = async:callback(function()
						hoveredOk = false; refreshUI('ok')
					end),
				},
			}}, 5, 5),
		},
	}
	
	------------------------------------------ 7. CLOSE BUTTON ------------------------------------------
	-- close label element
	refs.closeLabel = ui.create({
		template = I.MWUI.templates.textNormal,
		props = {
			text = 'X',
			textColor = normalColor,
			textSize = X_SIZE,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
			size = v2(X_SIZE, X_SIZE),
			autoSize = false,
		},
	})
	-- close button
	local closeButton = {
		template = buttonTemplate,
		props = {
			size = v2(X_SIZE, X_SIZE),
			autoSize = false
		},
		content = ui.content {
			refs.closeLabel,
		},
		events = {
			mouseClick = async:callback(function()
				ambient.playSound("menu click")
				levelUpDialogueClosing = true
				I.UI.removeMode('LevelUp')
			end),
			focusGain = async:callback(function()
				local prevAttr = getControllerAttr()
				local prevOk = (controllerRow == 5 and controllerCol ~= 3)
				hoveredClose = true
				controllerRow = 0
				refreshUI('close')
				if prevAttr then updateAttr(prevAttr) end
				if prevOk then refreshUI('ok') end
			end),
			focusLoss = async:callback(function()
				hoveredClose = false; refreshUI('close')
			end),
		},
	}
	
	------------------------------------------ ROOT ------------------------------------------
	return {
		layer = 'Windows',
		type = ui.TYPE.Flex,
		props = {
			horizontal = true,
			autoSize = true,
			relativePosition = v2(0.5, 0.5),
			anchor = v2(0.5, 0.5),
			position = v2(X_SIZE / 2, 0),
		},
		content = ui.content {
			-- window body
			{
				template = windowBox,
				content = ui.content {
					-- outer vflex
					{
						type = ui.TYPE.Flex,
						props = {
							horizontal = false,
							autoSize = true,
						},
						content = ui.content {
							-- centered vflex
							{
								type = ui.TYPE.Flex,
								props = {
									horizontal = false,
									autoSize = true,
									arrange = ui.ALIGNMENT.Center,
								},
								content = ui.content {
									levelupImage,
									levelText,
									spacer(WINDOW_PADDING_Y),
									flavorParagraph,
									spacer(WINDOW_PADDING_Y),
									refs.coinRow,
									spacer(WINDOW_PADDING_Y),
								},
							},
							-- attr grid
							attrGrid,
							-- ok button
							okButton,
						},
					},
				},
			},
			closeButton,
		},
	}
end

----- Window registration -----
local function showLevelUp()
	if S_AttributeUncapper and S_attributeUncapperMode == 'CustomUI' then
		ambient.streamMusic("music/special/mw_triumph.mp3")
		spentAttrs = {}
		hoveredAttr = nil
		hoveredOk = false
		hoveredClose = false
		controllerRow = 0
		controllerCol = 1
		dpadMoveDirection = nil
		local available = MAX_COINS
		if S_luckGains == 0 then
			available = 0
			for _, id in ipairs(ATTR_IDS) do
				if getAttrGain(id) > 0 then
					available = available + 1
				end
			end
		end
		coinCount = math.min(MAX_COINS, available)
		refs.root = ui.create(buildLayout())
	end
end

local function hideLevelUp()
	if refs.root then
		auxUi.deepDestroy(refs.root)
		refs.root = nil
	end
	refs.attr = {}
	refs.coinRow = nil
	refs.okLabel = nil
	refs.closeLabel = nil
	spentAttrs = {}
	hoveredAttr = nil
	hoveredOk = false
	hoveredClose = false
	controllerRow = 0
	controllerCol = 1
	dpadMoveDirection = nil
end


I.UI.registerWindow('LevelUpDialog', showLevelUp, hideLevelUp)

if S_AttributeUncapper and S_attributeUncapperMode == 'CustomUI' then
	-- using custom window
else
	ui._setWindowDisabled('LevelUpDialog', false)
end