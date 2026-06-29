-- ------------------------------ Evening Star : deity ui -------------------
-- two-screen modal:
--   1. selector  - header + horizontal row of deity buttons at the bottom
--   2. tenets    - deity info + tenets, with Yes / No (or Back for stubs)
--
-- public api:
--   M.show(opts)  opts = {
--       records        = es_deities table
--       deityIds       = ordered list of deity ids to show e.g. {"vivec","almalexia","sothasil"}
--       borderStyle    = "thin"|"normal"|"thick"|"verythick"
--       borderColor    = util.color
--       onAccept       = function(deityId)
--       onCancel       = function() | nil
--       initialDeityId = string | nil  -- if set, skip selector and open this deity's
--                                       -- tenets directly (Cancel then closes)
--       replaceWarning = string | nil  -- shown above the accept row (e.g. one-deity swap)
--   }
--   M.showTenetsOnly(opts)  opts = {
--       deity         = es_deities record  -- the one opened first
--       deities       = { record, ... } | nil  -- ordered set for prev/next nav
--       borderStyle   = "thin"|"normal"|"thick"|"verythick"
--       borderColor   = util.color
--       onClose       = function() | nil
--   }
--   M.close()
--   M.isOpen()
--
-- the caller owns I.UI mode; this module only manages the widgets.

-- buttons are sun's dusk makeButton wrapped in the mod's border (makeEsButton);
-- fixed sizes (widgets don't autosize)
local WINDOW_WIDTH = 580
local BTN_HEIGHT   = 38

local M = {}

-- ------------------------------ state -------------------------------------

local root        = nil
local opts        = nil
local screen      = nil  -- "selector" | "tenets"
local windowTpl   = nil
local thisCallbacks = nil
local hasSelector = false -- true once the selector has been shown this session

-- ------------------------------ helpers -----------------------------------

local TEXT_NORMAL   = G_morrowindLight
local TEXT_GOLD     = G_morrowindGold
local TEXT_DIM      = util.color.rgb(0.55, 0.5, 0.4)
local TEXT_FLAVOR   = util.color.rgb(0.7, 0.65, 0.55)
local TEXT_PLACEHOLDER = util.color.rgb(0.5, 0.5, 0.5)
local TEXT_WARN     = util.color.rgb(0.8, 0.35, 0.3)

-- map style name to (borderFile, borderOffset)
local function resolveBorder(style)
	local file = (style == "thick" or style == "verythick") and "thick" or "thin"
	local size = style == "verythick" and 4
		or style == "thick" and 3
		or style == "normal" and 2
		or 1
	return file, size
end

-- builds the window-border template once per show()
local function buildWindowTemplate(borderStyle, borderColor)
	local file, size = resolveBorder(borderStyle or "thin")
	local bg = {
		type = ui.TYPE.Image,
		props = {
			resource = ui.texture { path = "black" },
			relativeSize = v2(1, 1),
			alpha = 0.92,
		},
	}
	return makeBorder(file, borderColor or util.color.rgb(1, 1, 1), size, bg).borders
end

-- ------------------------------ buttons -----------------------------------

local function makeEsButton(label, props, onClick)
	return makeButton(label, props, onClick)
end

-- ------------------------------ close + destroy ---------------------------

local function destroyRoot()
	if root then
		root:destroy()
		root = nil
	end
end

function M.close()
	destroyRoot()
	opts = nil
	screen = nil
	windowTpl = nil
	thisCallbacks = nil
	hasSelector = false
end

function M.isOpen()
	return root ~= nil
end

-- forward decls
local showSelector, showTenets, showDropScreen

-- ------------------------------ screen 1: selector ------------------------

showSelector = function()
	destroyRoot()
	screen = "selector"
	hasSelector = true
	
	local windowWidth  = WINDOW_WIDTH
	local padding      = 16
	
	-- header
	local header = {
		type = ui.TYPE.Text,
		props = {
			text = "Choose a deity to worship",
			textSize = 22,
			textColor = TEXT_GOLD,
			textShadow = true,
			textAlignH = ui.ALIGNMENT.Center,
		},
	}
	
	-- deity row
	local row = ui.content {}
	for i, deityId in ipairs(opts.deityIds) do
		local d = opts.records[deityId]
		if d then
			if i > 1 then
				row:add{ props = { size = v2(16, 0) } }
			end
			-- stub status is shown on the tenets screen, so labels stay clean
			local btn = makeEsButton(d.name, { size = v2(160, BTN_HEIGHT) }, function()
				showTenets(deityId)
			end)
			row:add(btn.box)
		end
	end
	
	-- bottom-row container
	local rowBox = {
		type = ui.TYPE.Flex,
		props = {
			horizontal = true,
			align = ui.ALIGNMENT.Center,
			arrange = ui.ALIGNMENT.Center,
		},
		content = row,
	}
	
	-- cancel
	local cancelBtn = makeEsButton("Cancel", { size = v2(130, BTN_HEIGHT) }, function()
		ambient.playSound("Menu Click")
		local cb = thisCallbacks and thisCallbacks.onCancel
		M.close()
		if cb then cb() end
	end)
	
	-- assemble inner column; flex fills the template slot
	local body = {
		type = ui.TYPE.Flex,
		props = {
			horizontal = false,
			align = ui.ALIGNMENT.Center,
			arrange = ui.ALIGNMENT.Center,
			relativeSize = v2(1, 1),
		},
		content = ui.content {
			{ props = { size = v2(0, padding) } },
			header,
			{ props = { size = v2(0, padding * 1.5) } },
			rowBox,
			{ props = { size = v2(0, padding * 1.5) } },
			cancelBtn.box,
			{ props = { size = v2(0, padding) } },
		},
	}
	
	root = ui.create {
		layer = "Windows",
		name = "es_deity_selector",
		type = ui.TYPE.Widget,
		template = windowTpl,
		props = {
			size = v2(windowWidth, 280),
			relativePosition = v2(0.5, 0.5),
			anchor = v2(0.5, 0.5),
		},
		content = ui.content { body },
	}
end

-- ------------------------------ screen 2: tenets --------------------------

showTenets = function(deityId, viewOnly)
	destroyRoot()
	screen = "tenets"
	local d = opts.records[deityId]
	if not d then return end
	
	local windowWidth  = WINDOW_WIDTH
	local padding      = 16
	
	-- view-only nav: cycle prev/next through the worshipped set (opts.viewList)
	local function viewNav(delta)
		local list = opts.viewList or {}
		if #list <= 1 then return end
		local cur = 1
		for i, id in ipairs(list) do
			if id == deityId then cur = i; break end
		end
		local target = ((cur - 1 + delta) % #list) + 1
		ambient.playSound("Menu Click")
		showTenets(list[target], true)
	end
	
	local function buildViewOnlyRow()
		local closeBtn = makeEsButton("Close", { size = v2(130, BTN_HEIGHT) }, function()
			local cb = thisCallbacks and thisCallbacks.onClose
			M.close()
			if cb then cb() end
		end)
		if #(opts.viewList or {}) <= 1 then
			return closeBtn.box
		end
		local prevBtn = makeEsButton("Previous", { size = v2(130, BTN_HEIGHT) }, function()
			viewNav(-1)
		end)
		local nextBtn = makeEsButton("Next", { size = v2(130, BTN_HEIGHT) }, function()
			viewNav(1)
		end)
		return {
			type = ui.TYPE.Flex,
			props = {
				horizontal = true,
				align = ui.ALIGNMENT.Center,
				arrange = ui.ALIGNMENT.Center,
			},
			content = ui.content {
				prevBtn.box,
				{ props = { size = v2(20, 0) } },
				closeBtn.box,
				{ props = { size = v2(20, 0) } },
				nextBtn.box,
			},
		}
	end
	
	-- name + title + description block
	local nameText = {
		type = ui.TYPE.Text,
		props = {
			text = d.name or "Unknown",
			textSize = 28,
			textColor = TEXT_GOLD,
			textShadow = true,
			textAlignH = ui.ALIGNMENT.Center,
		},
	}
	local titleText = {
		type = ui.TYPE.Text,
		props = {
			text = d.title or "",
			textSize = 22,
			textColor = TEXT_NORMAL,
			textShadow = true,
			textAlignH = ui.ALIGNMENT.Center,
		},
	}
	local descText = {
		type = ui.TYPE.Text,
		props = {
			text = d.description or "",
			textSize = 22,
			textColor = TEXT_DIM,
			textShadow = true,
			textAlignH = ui.ALIGNMENT.Center,
		},
	}
	
	local bodyParts = {
		{ props = { size = v2(0, padding) } },
		nameText,
		{ props = { size = v2(0, 4) } },
		titleText,
		{ props = { size = v2(0, 2) } },
		descText,
		{ props = { size = v2(0, padding) } },
	}
	
	if d.stub then
		-- placeholder copy
		local placeholder = {
			type = ui.TYPE.Text,
			props = {
				text = "This deity is not yet implemented.\nCheck back in a future update.",
				textSize = 16,
				textColor = TEXT_PLACEHOLDER,
				textShadow = true,
				textAlignH = ui.ALIGNMENT.Center,
				multiline = true,
			},
		}
		local btnBox
		if viewOnly then
			btnBox = buildViewOnlyRow()
		elseif hasSelector then
			btnBox = makeEsButton("Back", { size = v2(130, BTN_HEIGHT) }, function()
				showSelector()
			end).box
		else
			btnBox = makeEsButton("Close", { size = v2(130, BTN_HEIGHT) }, function()
				local cb = thisCallbacks and thisCallbacks.onCancel
				M.close()
				if cb then cb() end
			end).box
		end
		
		table.insert(bodyParts, { props = { size = v2(0, 0) }, external = { grow = 1 } })
		table.insert(bodyParts, placeholder)
		table.insert(bodyParts, { props = { size = v2(0, 0) }, external = { grow = 1 } })
		table.insert(bodyParts, btnBox)
	else
		-- flavor quote (italic-ish via different color)
		if d.flavorText and d.flavorText ~= "" then
			local quote = '"' .. d.flavorText .. '"'
			-- autosize ignores width, so wrap needs it off + an explicit (estimated) height
			local wrapWidth    = windowWidth - padding * 10
			local lineHeight   = 26
			local charsPerLine = math.max(1, math.floor(wrapWidth / 8))
			-- overestimate lines so wrapped text is never clipped
			local lineCount    = math.ceil(#quote / charsPerLine) + 1
			table.insert(bodyParts, {
				type = ui.TYPE.Text,
				props = {
					text = quote,
					textSize = 20,
					textColor = TEXT_GOLD,
					textShadow = true,
					textAlignH = ui.ALIGNMENT.Center,
					autoSize = false,
					size = v2(wrapWidth, lineCount * lineHeight),
					wordWrap = true,
					multiline = true,
				},
			})
		end
		
		-- follower + devotee ability descriptions (one block, newline-joined)
		local abilities = {}
		if d.followerAbility then abilities[#abilities + 1] = d.followerAbility end
		if d.devoteeAbility  then abilities[#abilities + 1] = d.devoteeAbility  end
		if #abilities > 0 then
			local str   = table.concat(abilities, "\n\n")
			local w     = windowWidth - padding * 14
			-- +3 lines: two for the blank-line join, one safety
			local lines = math.ceil(#str / math.max(1, math.floor(w / 9))) + 3
			table.insert(bodyParts, { props = { size = v2(0, 4) } })
			table.insert(bodyParts, {
				type = ui.TYPE.Text,
				props = {
					text = str,
					textSize = 19,
					textColor = TEXT_GOLD,
					textShadow = true,
					textAlignH = ui.ALIGNMENT.Center,
					autoSize = false,
					size = v2(w, lines * 24),
					wordWrap = true,
					multiline = true,
				},
			})
		end
		
		-- grow spacer pins the button row to the bottom
		table.insert(bodyParts, { props = { size = v2(0, 0) }, external = { grow = 1 } })
		
		-- close (view-only) or yes/no row
		if viewOnly then
			table.insert(bodyParts, buildViewOnlyRow())
		else
			---- swap warning
			--if opts.replaceWarning and opts.replaceWarning ~= "" then
			--	table.insert(bodyParts, {
			--		type = ui.TYPE.Text,
			--		props = {
			--			text = opts.replaceWarning,
			--			textSize = 18,
			--			textColor = TEXT_WARN,
			--			textShadow = true,
			--			textAlignH = ui.ALIGNMENT.Center,
			--		},
			--	})
			--	table.insert(bodyParts, { props = { size = v2(0, 8) } })
			--end
			local acceptBtn = makeEsButton("Accept " .. d.name, { size = v2(200, BTN_HEIGHT) }, function()
				local cb = thisCallbacks and thisCallbacks.onAccept
				local pickedId = deityId
				M.close()
				if cb then cb(pickedId) end
			end)
			
			local cancelBtn = makeEsButton("Cancel", { size = v2(110, BTN_HEIGHT) }, function()
				ambient.playSound("Menu Click")
				if hasSelector then
					showSelector()
				else
					local cb = thisCallbacks and thisCallbacks.onCancel
					M.close()
					if cb then cb() end
				end
			end)
			
			local btnRow = {
				type = ui.TYPE.Flex,
				props = {
					horizontal = true,
					align = ui.ALIGNMENT.Center,
					arrange = ui.ALIGNMENT.Center,
				},
				content = ui.content {
					acceptBtn.box,
					{ props = { size = v2(20, 0) } },
					cancelBtn.box,
				},
			}
			table.insert(bodyParts, btnRow)
		end
	end
	
	table.insert(bodyParts, { props = { size = v2(0, padding) } })
	
	local body = {
		type = ui.TYPE.Flex,
		props = {
			horizontal = false,
			align = ui.ALIGNMENT.Center,
			arrange = ui.ALIGNMENT.Center,
			relativeSize = v2(1, 1),
		},
		content = ui.content(bodyParts),
	}
	
	root = ui.create {
		layer = "Windows",
		name = "es_deity_tenets",
		type = ui.TYPE.Widget,
		template = windowTpl,
		props = {
			size = v2(windowWidth, 650),
			relativePosition = v2(0.5, 0.5),
			anchor = v2(0.5, 0.5),
		},
		content = ui.content { body },
	}
end

-- ------------------------------ screen 3: drop ----------------------------
-- shown when all slots are full: pick a worshipped deity to abandon

showDropScreen = function()
	destroyRoot()
	screen = "drop"
	
	local windowWidth = WINDOW_WIDTH
	local padding     = 16
	local pending     = opts.pendingId and opts.records[opts.pendingId]
	
	-- header
	local header = {
		type = ui.TYPE.Text,
		props = {
			text = pending
				and string.format("To take up %s you must abandon another.\nChoose a deity to forsake:", pending.name)
				or "Choose a deity to forsake:",
			textSize = 22,
			textColor = TEXT_GOLD,
			textShadow = true,
			textAlignH = ui.ALIGNMENT.Center,
			multiline = true,
		},
	}
	
	local row = ui.content {}
	for i, entry in ipairs(opts.active or {}) do
		local d = opts.records[entry.id]
		if d then
			if i > 1 then
				row:add{ props = { size = v2(0, 8) } }
			end
			local label = string.format("%s  (%d%%, %s)", d.name, math.floor((entry.favor or 0) + 0.5), entry.tier or "")
			local btn = makeEsButton(label, { size = v2(450, BTN_HEIGHT) }, function()
				ambient.playSound("Menu Click")
				local cb = thisCallbacks and thisCallbacks.onDrop
				local droppedId = entry.id
				M.close()
				if cb then cb(droppedId) end
			end)
			row:add(btn.box)
		end
	end
	
	local rowBox = {
		type = ui.TYPE.Flex,
		props = {
			horizontal = false,
			align = ui.ALIGNMENT.Center,
			arrange = ui.ALIGNMENT.Center,
		},
		content = row,
	}
	
	-- cancel
	local cancelBtn = makeEsButton("Cancel", { size = v2(130, BTN_HEIGHT) }, function()
		ambient.playSound("Menu Click")
		local cb = thisCallbacks and thisCallbacks.onCancel
		M.close()
		if cb then cb() end
	end)
	
	local body = {
		type = ui.TYPE.Flex,
		props = {
			horizontal = false,
			align = ui.ALIGNMENT.Center,
			arrange = ui.ALIGNMENT.Center,
			relativeSize = v2(1, 1),
		},
		content = ui.content {
			{ props = { size = v2(0, padding) } },
			header,
			{ props = { size = v2(0, padding * 1.5) } },
			rowBox,
			{ props = { size = v2(0, padding * 1.5) } },
			cancelBtn.box,
			{ props = { size = v2(0, padding) } },
		},
	}
	
	root = ui.create {
		layer = "Windows",
		name = "es_deity_drop",
		type = ui.TYPE.Widget,
		template = windowTpl,
		props = {
			size = v2(windowWidth, 320),
			relativePosition = v2(0.5, 0.5),
			anchor = v2(0.5, 0.5),
		},
		content = ui.content { body },
	}
end

-- ------------------------------ public show -------------------------------

function M.show(showOpts)
	opts = showOpts or {}
	thisCallbacks = {
		onAccept = opts.onAccept,
		onCancel = opts.onCancel,
	}
	windowTpl = buildWindowTemplate(opts.borderStyle, opts.borderColor)
	hasSelector = false
	-- shrine activation passes initialDeityId to skip the selector and
	-- open that deity's tenets directly; Cancel then closes (no selector to return to)
	if opts.initialDeityId and opts.records and opts.records[opts.initialDeityId] then
		showTenets(opts.initialDeityId)
	else
		showSelector()
	end
end

-- read-only tenets view; close button, plus prev/next for multiple deities
function M.showTenetsOnly(showOpts)
	local d = showOpts and showOpts.deity
	if not d then return end
	
	local records  = { [d.id] = d }
	local viewList = { d.id }
	if showOpts.deities and #showOpts.deities > 1 then
		records, viewList = {}, {}
		for _, rec in ipairs(showOpts.deities) do
			if rec and rec.id then
				records[rec.id] = rec
				viewList[#viewList + 1] = rec.id
			end
		end
		-- guarantee the opening deity is reachable
		if not records[d.id] then
			records[d.id] = d
			table.insert(viewList, 1, d.id)
		end
	end
	
	opts = {
		records  = records,
		viewList = viewList,
	}
	thisCallbacks = {
		onClose = showOpts.onClose,
	}
	windowTpl = buildWindowTemplate(showOpts.borderStyle, showOpts.borderColor)
	showTenets(d.id, true)
end

-- drop screen: caller passes worshipped deities + pending id; onDrop fires on pick
function M.showDropChoice(showOpts)
	opts = showOpts or {}
	thisCallbacks = {
		onDrop   = opts.onDrop,
		onCancel = opts.onCancel,
	}
	windowTpl = buildWindowTemplate(opts.borderStyle, opts.borderColor)
	hasSelector = false
	showDropScreen()
end

return M