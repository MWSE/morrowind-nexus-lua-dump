-- ------------------------------ Evening Star : ralts interop -------------
-- combined interop for ralts' mods:
--   * Stats Window Extender -- adds a "Religion" line + favor tooltip
--   * Inventory Extender    -- adds a tribunal icon to the info bar (opens
--                              tenets on click)

local esCtInterop = require('scripts.EveningStar.lib.es_ct_interop')
local esDeityUi   = require('scripts.EveningStar.lib.es_deity_ui')

-- ------------------------------ shared helper -----------------------------

local function getDeity()
	local id = ES.saveData and ES.saveData.currentDeity
	if not id then return nil end
	return ES.DB.deities[id:lower()]
end

-- ------------------------------ stats window line -------------------------
-- placement:
--   * with character backgrounds  -> line in levelStats, after Belief
--   * without it                  -> standalone section after Birthsign

local LINE_ID    = "es_religion"
local SECTION_ID = "es_religion_section"

local function deityNameValue()
	local deity = getDeity()
	return { string = deity and deity.name or "-None-" }
end

local function deityTooltip()
	if not I.StatsWindow then return {props = {}} end
	local deity = getDeity()
	if not deity then return {props = {}} end

	local STATS = I.StatsWindow.Templates.STATS
	local BASE  = I.StatsWindow.Templates.BASE

	local favor    = ES.saveData and ES.saveData.favor or 0
	local favorMax = ES.C.FAVOR_MAX or 100
	local level    = ES.getDevotionLevel and ES.getDevotionLevel(favor) or "uninitiated"
	local levelStr = level:sub(1,1):upper() .. level:sub(2)

	-- title + tooltip description (falls back to short description)
	local title = deity.title or ""
	local body  = deity.tooltipDesc or deity.description or ""

	return STATS.tooltip(4, ui.content {
		{
			name = 'tooltip',
			type = ui.TYPE.Flex,
			props = {
				align = ui.ALIGNMENT.Center,
				arrange = ui.ALIGNMENT.Center,
			},			
			content = ui.content {
				-- deity icon + name
				{
					name = 'header',
					type = ui.TYPE.Flex,
					props = {
						horizontal = true,
						arrange = ui.ALIGNMENT.Center,
					},
					content = ui.content {
						-- big deity icon
						{
							name = 'icon',
							type = ui.TYPE.Image,
							props = {
								size = v2(32, 32),
								resource = getTexture("icons/EveningStar/b_tx_s_es_tt_" .. deity.id .. ".dds"),
							},
						},
						BASE.padding(4),
						-- deity name
						{
							name = 'name',
							template = BASE.textHeader,
							props = {
								text = deity.name,
							},
						},
					},
				},
				-- deity title
				title ~= "" and BASE.padding(4) or {},
				title ~= "" and {
					name = 'deityTitle',
					template = BASE.textNormal,
					props = {
						text = title,
						textAlignH = ui.ALIGNMENT.Center,
						textColor = I.StatsWindow.Constants.Colors.DEFAULT_LIGHT,
					},
				} or {},
				-- description body
				body ~= "" and BASE.padding(4) or {},
				body ~= "" and {
					name = 'desc',
					template = BASE.textParagraph,
					props = {
						size = v2(280, 0),
						text = body,
						autoSize = true,
					},
				} or {},
				BASE.padding(6),
				-- favor bar
				STATS.progressBar{
					value    = math.floor(favor),
					maxValue = favorMax,
					color    = util.color.rgb(0.15, 0.3, 0.6),
					size     = v2(220, STATS.LINE_HEIGHT),
					text     = string.format("%.2f%% (%s)", favor, levelStr),
				},
			},
		},
	}, 'es_deity_tooltip')
end

local function initSWLine()
	if not I.StatsWindow then return end
	local API = I.StatsWindow
	local C   = API.Constants

	-- shared params for both placement scenarios
	local lineParams = {
		label = "Religion:",
		labelColor = C.Colors.DEFAULT_LIGHT,
		value = deityNameValue,
		tooltip = deityTooltip,
		visibleFn = function()
			return ES.S and ES.S.TOGGLE_ENABLED and ES.S.TOGGLE_USE_SWE
				and ES.saveData and ES.saveData.currentDeity ~= nil
		end,
	}

	if esCtInterop.isInstalled() then
		-- between Belief and Culture lines in levelStats
		lineParams.placement = {
			type = C.Placement.AFTER,
			target = esCtInterop.BELIEF_LINE_ID,
		}
		API.addLineToSection(LINE_ID, C.DefaultSections.LEVEL_STATS, lineParams)
	else
		API.addLineToSection(LINE_ID, C.DefaultSections.LEVEL_STATS, lineParams)
	end
end

-- runs once interfaces are bound (sd_p calls G_onActiveJobs there)
table.insert(G_onActiveJobs, initSWLine)

-- ------------------------------ inventory button --------------------------
-- adds a tribunal icon to ie's info bar when a deity is chosen; click opens
-- the deity's tenets read-only. pattern lifted from crafting framework's
-- hammer button, plus a sluggish poll mirroring ES.saveData.currentDeity.

local BTN_NAME = "es_ie_tribunal_btn"
local BTN_SIZE = 26

local function openTenets()
	local deity = getDeity()
	if not deity then return end
	esDeityUi.showTenetsOnly{
		deity       = deity,
		borderStyle = ES.S.BORDER_STYLE or "thin",
		borderColor = ES.S.BORDER_COLOR,
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

-- ie has no removeInfoLayout, so removal pulls the button and the 8px spacer
-- that addInfoLayout inserts before it.
local function syncButton()
	if not I.InventoryExtender or not I.InventoryExtender.getWindow then return end
	local invWin = I.InventoryExtender.getWindow('Inventory')
	if not invWin or not invWin.infoBar or not invWin.ctx then return end

	local infoBar  = invWin.infoBar
	local enabled  = ES.S and ES.S.TOGGLE_ENABLED and ES.S.TOGGLE_USE_IE
	local hasDeity = enabled and ES.saveData and ES.saveData.currentDeity ~= nil
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

-- deity-state tick: fires syncButton on currentDeity flips
local lastDeity = nil
local function tickDeityState()
	local cur = ES.saveData and ES.saveData.currentDeity or nil
	if cur ~= lastDeity then
		lastDeity = cur
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
