-- ------------------------------ Evening Star : ralts interop -------------
-- combined interop for ralts' mods:
--   * Stats Window Extender -- adds a "Religion" line + favor tooltip
--   * Inventory Extender    -- adds a tribunal icon to the info bar (opens
--                              tenets on click)

local esDeityUi   = require('scripts.EveningStar.lib.es_deity_ui')

-- ------------------------------ stats window line -------------------------
-- one "Religion:" line in levelStats; tooltip shows a card per worshipped deity

local LINE_ID = "es_religion"

local function deityPerksList(deity, level)
	local perks = {}
	if level >= 1 and deity.gift_1 then
		local rec = core.magic.spells.records[deity.gift_1]
		if rec and rec.name and rec.name ~= "" then perks[#perks + 1] = rec.name end
	end
	if level >= 2 and deity.gift_2_alias then perks[#perks + 1] = deity.gift_2_alias end
	if level >= 3 and deity.gift_3_alias then perks[#perks + 1] = deity.gift_3_alias end
	return perks
end

-- favor bar with a tick at each devotion threshold
local function segmentedFavorBar(favor, label, width)
	local STATS    = I.StatsWindow.Templates.STATS
	local favorMax = ES.C.FAVOR_MAX or 100
	local bar = STATS.progressBar{
		value    = math.floor(favor),
		maxValue = favorMax,
		color    = util.color.rgb(0.15, 0.3, 0.6),
		size     = v2(width, STATS.LINE_HEIGHT),
		text     = label,
	}
	for _, threshold in ipairs(ES.C.FAVOR_THRESHOLDS or {}) do
		if threshold > 0 and threshold < favorMax then
			bar.content:insert(2, {
				type = ui.TYPE.Image,
				props = {
					position = v2(math.floor(width * threshold / favorMax), 0),
					size = v2(2, STATS.LINE_HEIGHT),
					resource = STATS.TEXTURES.progressBar,
					color = I.StatsWindow.Constants.Colors.DEFAULT_LIGHT,
				},
			})
		end
	end
	return bar
end

-- rich card for the single-deity view
local function singleCard(deityId)
	local deity = ES.getDeity(deityId)
	if not deity then return nil end
	local st    = ES.saveData.deities[deityId]
	local STATS = I.StatsWindow.Templates.STATS
	local BASE  = I.StatsWindow.Templates.BASE
	local light = I.StatsWindow.Constants.Colors.DEFAULT_LIGHT
	
	local favor = st and st.favor or 0
	local level = ES.getDevotionLevel(deityId)
	local title = deity.title or ""
	local body  = deity.tooltipDesc or deity.description or ""
	
	local parts = ui.content {}
	
	-- icon + name
	parts:add({
		name = 'header',
		type = ui.TYPE.Flex,
		props = {
			horizontal = true,
			arrange = ui.ALIGNMENT.Center,
		},
		content = ui.content {
			{
				name = 'icon',
				type = ui.TYPE.Image,
				props = {
					size = v2(32, 32),
					resource = getTexture("icons/EveningStar/b_tx_s_es_tt_"..deity.id..".dds"),
				},
			},
			BASE.padding(4),
			{
				name = 'name',
				template = BASE.textHeader,
				props = { text = deity.name },
			},
		},
	})
	
	-- deity title
	if title ~= "" then
		parts:add(BASE.padding(4))
		parts:add({
			name = 'deityTitle',
			template = BASE.textNormal,
			props = {
				text = title,
				textAlignH = ui.ALIGNMENT.Center,
				textColor = light,
			},
		})
	end
	
	-- description body
	if body ~= "" then
		parts:add(BASE.padding(4))
		parts:add({
			name = 'desc',
			template = BASE.textParagraph,
			props = {
				size = v2(280, 0),
				text = body,
				autoSize = true,
			},
		})
	end
	
	-- favor bar
	parts:add(BASE.padding(6))
	parts:add(STATS.progressBar{
		value    = math.floor(favor),
		maxValue = ES.C.FAVOR_MAX or 100,
		color    = util.color.rgb(0.15, 0.3, 0.6),
		size     = v2(220, STATS.LINE_HEIGHT),
		text     = string.format("%.2f%% (%s)", favor, ES.DEVOTION_NAMES[level]),
	})
	
	-- unlocked perks
	local perks = deityPerksList(deity, level)
	if #perks > 0 then
		parts:add(BASE.padding(2))
		parts:add({
			name = 'perks',
			template = BASE.textNormal,
			props = {
				text = table.concat(perks, ", "),
				textAlignH = ui.ALIGNMENT.Center,
				textColor = light,
			},
		})
	end
	
	return {
		name = 'card',
		type = ui.TYPE.Flex,
		props = {
			align = ui.ALIGNMENT.Center,
			arrange = ui.ALIGNMENT.Center,
		},
		content = parts,
	}
end

-- compact card for the multi-deity view
local function multiCard(deityId)
	local deity = ES.getDeity(deityId)
	if not deity then return nil end
	local st    = ES.saveData.deities[deityId]
	local STATS = I.StatsWindow.Templates.STATS
	local BASE  = I.StatsWindow.Templates.BASE
	local light = I.StatsWindow.Constants.Colors.DEFAULT_LIGHT
	
	local favor = st and st.favor or 0
	local level = ES.getDevotionLevel(deityId)
	
	-- icon + bar in one row, perk lines stacked below
	local parts = ui.content {
		{
			name = 'row',
			type = ui.TYPE.Flex,
			props = {
				horizontal = true,
				align = ui.ALIGNMENT.Center,
			},
			content = ui.content {
				-- deity icon, matched to the bar height
				{
					name = 'icon',
					type = ui.TYPE.Image,
					props = {
						size = v2(STATS.LINE_HEIGHT, STATS.LINE_HEIGHT),
						resource = getTexture("icons/EveningStar/b_tx_s_es_tt_"..deity.id..".dds"),
					},
				},
				BASE.padding(4),
				-- favor bar
				segmentedFavorBar(favor, string.format("%s  %.1f%%", deity.name, favor), 200),
			},
		},
	}
	-- gift 1 is called "<deity> worshipper", so only show "worshipper"
	local gift1Name = deity.gift_1 and core.magic.spells.records[deity.gift_1]
		and core.magic.spells.records[deity.gift_1].name
	for _, perk in ipairs(deityPerksList(deity, level)) do
		parts:add({
			template = BASE.textNormal,
			props = {
				text = (gift1Name and perk == gift1Name) and "Worshipper" or perk,
				textColor = light,
				textAlignH = ui.ALIGNMENT.End,
			},
		})
	end
	
	return {
		name = 'card',
		type = ui.TYPE.Flex,
		props = { arrange = ui.ALIGNMENT.End },
		content = parts,
	}
end

-- line value: a single deity's name, or a count when several are worshipped
local function religionValue()
	local active = ES.saveData and ES.saveData.activeDeities or {}
	if #active == 1 then
		local deity = ES.getDeity(active[1])
		return { string = deity and deity.name or "-None-" }
	elseif #active > 1 then
		return { string = string.format("%d Deities", #active) }
	end
	return { string = "-None-" }
end

-- one rich card for a single deity, stacked compact cards for several
local function religionTooltip()
	if not I.StatsWindow then return {props = {}} end
	local active = ES.saveData and ES.saveData.activeDeities or {}
	if #active == 0 then return {props = {}} end
	local STATS = I.StatsWindow.Templates.STATS
	local BASE  = I.StatsWindow.Templates.BASE
	
	if #active == 1 then
		local card = singleCard(active[1])
		if not card then return {props = {}} end
		return STATS.tooltip(4, ui.content { card }, 'es_deity_tooltip')
	end
	
	local column = ui.content {}
	local added  = 0
	for _, deityId in ipairs(active) do
		local card = multiCard(deityId)
		if card then
			if added > 0 then column:add(BASE.padding(8)) end
			column:add(card)
			added = added + 1
		end
	end
	if added == 0 then return {props = {}} end
	
	return STATS.tooltip(6, ui.content {
		{
			name = 'tooltip',
			type = ui.TYPE.Flex,
			props = {
				align = ui.ALIGNMENT.Start,
				arrange = ui.ALIGNMENT.Center,
			},
			content = column,
		},
	}, 'es_deity_tooltip')
end

local registered = false

local function initSWLine()
	if registered or not I.StatsWindow then return end
	local API = I.StatsWindow
	local C   = API.Constants
	if not API.getSection(C.DefaultSections.LEVEL_STATS) then return end
	
	-- religion line
	local lineParams = {
		label = "Religion:",
		labelColor = C.Colors.DEFAULT_LIGHT,
		value = religionValue,
		tooltip = religionTooltip,
		visibleFn = function()
			return ES.S and ES.S.TOGGLE_ENABLED and ES.S.TOGGLE_USE_SWE
				and ES.saveData and #ES.saveData.activeDeities > 0
		end,
	}
	-- with character backgrounds, chain after Belief; otherwise append
	local afterId = I.CharacterTraits and "CharacterTraits_belief" or nil
	if afterId then
		lineParams.placement = { type = C.Placement.AFTER, target = afterId }
	end
	API.addLineToSection(LINE_ID, C.DefaultSections.LEVEL_STATS, lineParams)
	registered = true
end

-- runs once interfaces are bound (sd_p calls G_onActiveJobs there)
table.insert(G_onActiveJobs, initSWLine)

-- ------------------------------ inventory button --------------------------
-- adds a tribunal icon to ie's info bar when a deity is chosen; click opens the deity's tenets read-only.
-- pattern lifted from crafting framework's hammer button, plus a sluggish poll mirroring the worship set.

local BTN_NAME = "es_ie_tribunal_btn"
local BTN_SIZE = 26

local function openTenets()
	local deity = ES.getHighestFavorDeity()
	if not deity then return end
	-- full worshipped set in slot order, for prev/next nav in the tenets view
	local deities = {}
	for _, id in ipairs(ES.saveData.activeDeities) do
		local d = ES.getDeity(id)
		if d then deities[#deities + 1] = d end
	end
	esDeityUi.showTenetsOnly{
		deity       = deity,
		deities     = deities,
		borderStyle = ES.S.BORDER_STYLE or "thin",
		borderColor = ES.S.BORDER_COLOR or util.color.rgb(1, 1, 1),
	}
end

-- rebuilt on each (re)add so events close over the current ctx + infoBar
local function buildBtn(ctx, infoBar)
	local normalTex = getTexture("icons/EveningStar/ie_tribunal.png")
	local hoverTex  = getTexture("icons/EveningStar/ie_tribunal_hover.png")
	
	-- tribunal icon
	local icon = {
		type = ui.TYPE.Image,
		props = {
			resource = normalTex,
			relativeSize = v2(1, 1),
			alpha = 1,
		},
	}
	
	-- click target
	return {
		name = BTN_NAME,
		props = { size = v2(BTN_SIZE, BTN_SIZE) },
		content = ui.content {
			icon,
		},
		events = {
			focusGain = async:callback(function()
				icon.props.resource = hoverTex
				ctx.updateQueue[infoBar] = true
			end),
			focusLoss = async:callback(function()
				icon.props.resource = normalTex
				ctx.updateQueue[infoBar] = true
			end),
			mousePress = async:callback(function(e)
				if e.button == 1 then
					ambient.playSound("menu click")
				end
			end),
			mouseRelease = async:callback(function(e)
				if e.button ~= 1 then return end
				-- ignore mid-drag clicks
				if ctx.dragAndDrop and ctx.dragAndDrop.draggingObject then return end
				openTenets()
			end),
		},
	}
end

-- ie has no removeInfoLayout,
-- so removal pulls the button and the 8px spacer that addInfoLayout inserts before it.
local function syncButton()
	if not I.InventoryExtender or not I.InventoryExtender.getWindow then return end
	local invWin = I.InventoryExtender.getWindow('Inventory')
	if not invWin or not invWin.infoBar or not invWin.ctx then return end
	
	local infoBar  = invWin.infoBar
	local enabled  = ES.S and ES.S.TOGGLE_ENABLED and ES.S.TOGGLE_USE_IE
	local hasDeity = enabled and ES.saveData and #ES.saveData.activeDeities > 0
	local idx      = infoBar.layout.content:indexOf(BTN_NAME)
	
	if hasDeity and not idx then
		infoBar.layout.userData.addInfoLayout(buildBtn(invWin.ctx, infoBar))
	elseif not hasDeity and idx then
		-- pull button, then the preceding spacer
		infoBar.layout.content:remove(idx)
		infoBar.layout.content:remove(idx - 1)
		infoBar:update()
	end
end

-- deity-state tick: fires syncButton when the worship set goes empty/non-empty
local hadDeity = nil
local function tickDeityState()
	local has = (ES.saveData and #ES.saveData.activeDeities > 0) or false
	if has ~= hadDeity then
		hadDeity = has
		syncButton()
	end
end

table.insert(G_onActiveJobs, function()
	if not I.InventoryExtender or not I.InventoryExtender.getWindow then return end
	local invWin = I.InventoryExtender.getWindow('Inventory')
	if not invWin or not invWin.infoBar or not invWin.ctx then return end
	G_onFrameJobsSluggish["es_ie_button_tick"] = tickDeityState
end)

-- re-sync on toggle changes (deity-state tick only catches deity flips)
table.insert(G_settingsChangedJobs, function(_, setting)
	if setting == "TOGGLE_USE_IE" or setting == "TOGGLE_ENABLED" then
		syncButton()
	end
end)
