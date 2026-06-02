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
--   }
--   M.showTenetsOnly(opts)  opts = {
--       deity         = es_deities record
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
-- sun's dusk's makeButton (dynamic highlight + click cancel) wrapped in an
-- invisible backing widget carrying the mod's border, so the buttons pick up
-- the same thick frame the windows use.

-- rebuilt per show() from the active border style + color
local buttonBorderTpl = nil
local buttonBorderPad = 0
local function buildButtonBorder(borderStyle, borderColor)
	local file, size = resolveBorder(borderStyle or "thick")
	buttonBorderTpl = makeBorder(file, borderColor or util.color.rgb(1, 1, 1), size).borders
	buttonBorderPad = size + 1 -- frame sits just outside the button
end

-- same (label, props, func) shape as makeButton; frames the real button in the
-- mod border. props.size is the button; the wrapper adds the border margin.
local function makeEsButton(label, props, onClick)
	props.relativePosition = v2(0.5, 0.5)
	props.anchor = v2(0.5, 0.5)
	local btn = makeButton(label, props, onClick)

	local pad = v2(buttonBorderPad, buttonBorderPad)
	local wrapper = ui.create {
		type = ui.TYPE.Widget,
		props = { size = props.size + pad * 2 },
		content = ui.content {
			{ template = buttonBorderTpl, props = { relativeSize = v2(1, 1) } },
		},
	}
	wrapper.layout.content:add(btn.box)
	return { box = wrapper }
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
local showSelector, showTenets

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
		-- close (view-only / no selector to return to) or back-to-selector
		local btn
		if viewOnly then
			btn = makeEsButton("Close", { size = v2(130, BTN_HEIGHT) }, function()
				local cb = thisCallbacks and thisCallbacks.onClose
				M.close()
				if cb then cb() end
			end)
		elseif hasSelector then
			btn = makeEsButton("Back", { size = v2(130, BTN_HEIGHT) }, function()
				showSelector()
			end)
		else
			btn = makeEsButton("Close", { size = v2(130, BTN_HEIGHT) }, function()
				local cb = thisCallbacks and thisCallbacks.onCancel
				M.close()
				if cb then cb() end
			end)
		end

		table.insert(bodyParts, { props = { size = v2(0, 0) }, external = { grow = 1 } })
		table.insert(bodyParts, placeholder)
		table.insert(bodyParts, { props = { size = v2(0, 0) }, external = { grow = 1 } })
		table.insert(bodyParts, btn.box)
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
			local closeBtn = makeEsButton("Close", { size = v2(130, BTN_HEIGHT) }, function()
				local cb = thisCallbacks and thisCallbacks.onClose
				M.close()
				if cb then cb() end
			end)
			table.insert(bodyParts, closeBtn.box)
		else
			local acceptBtn = makeEsButton("Accept " .. d.name, { size = v2(180, BTN_HEIGHT) }, function()
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

-- ------------------------------ public show -------------------------------

function M.show(showOpts)
	opts = showOpts or {}
	thisCallbacks = {
		onAccept = opts.onAccept,
		onCancel = opts.onCancel,
	}
	windowTpl = buildWindowTemplate(opts.borderStyle, opts.borderColor)
	buildButtonBorder(opts.borderStyle, opts.borderColor)
	hasSelector = false
	-- shrine activation passes initialDeityId to skip the selector and open
	-- that deity's tenets directly; Cancel then closes (no selector to return to)
	if opts.initialDeityId and opts.records and opts.records[opts.initialDeityId] then
		showTenets(opts.initialDeityId)
	else
		showSelector()
	end
end

-- read-only tenets view for the player's current deity; single Close button.
function M.showTenetsOnly(showOpts)
	local d = showOpts and showOpts.deity
	if not d then return end
	opts = {
		records = { [d.id] = d },
	}
	thisCallbacks = {
		onClose = showOpts.onClose,
	}
	windowTpl = buildWindowTemplate(showOpts.borderStyle, showOpts.borderColor)
	buildButtonBorder(showOpts.borderStyle, showOpts.borderColor)
	showTenets(d.id, true)
end

return M