-- ------------------------------ Evening Star : favor bar -----------------
-- hud overlay shown around prayer. "praying" shows current favor; "completed"
-- shows the gain animation and lingers a few seconds before fading.
--
-- public api:
--   M.beginPraying(deity, favorBefore)
--   M.markCompleted(gained, lingerSeconds)
--   M.bumpVisible(seconds)
--   M.update()    -- frame tick
--   M.destroy()

local M = {}

-- ------------------------------ constants ---------------------------------

local BAR_WIDTH  = 180
local BAR_HEIGHT = 8
local COLOR_LOW  = util.color.rgb(0.6, 0.4, 0.2)
local COLOR_MID  = util.color.rgb(0.8, 0.6, 0.1)
local COLOR_HIGH = util.color.rgb(1.0, 0.85, 0.3)

local borderTemplate = makeBorder("thin", nil, 1, {
	type = ui.TYPE.Image,
	props = {
		resource = ui.texture { path = 'black' },
		relativeSize = v2(1, 1),
		alpha = 0.4,
	}
}).borders

-- ------------------------------ state -------------------------------------

local widget, fill, gainFill, background, text = nil, nil, nil, nil, nil

local phase       = nil    -- "praying" | "completed" | nil
local showUntil   = 0
local prayerDeity = nil
local favorBefore = nil
local favorGained = nil

-- ------------------------------ helpers -----------------------------------

local function getFavorColor(favor)
	local n = favor / ES.C.FAVOR_MAX
	if n < 0.33 then return COLOR_LOW end
	if n < 0.66 then return mixColors(COLOR_MID, COLOR_LOW, (n - 0.33) / 0.33) end
	return mixColors(COLOR_HIGH, COLOR_MID, (n - 0.66) / 0.34)
end

local function destroyWidget()
	if widget then
		widget:destroy()
		widget     = nil
		fill       = nil
		gainFill   = nil
		background = nil
		text       = nil
	end
end

-- ------------------------------ public api --------------------------------

function M.beginPraying(deity, favorBeforeValue)
	prayerDeity = deity
	favorBefore = favorBeforeValue
	favorGained = nil
	phase       = "praying"
end

function M.markCompleted(gained, lingerSeconds)
	favorGained = gained
	showUntil   = core.getSimulationTime() + (lingerSeconds or 3)
	phase       = "completed"
	-- force fresh rebuild with new content
	destroyWidget()
	M.update()
end

function M.bumpVisible(seconds)
	showUntil = core.getSimulationTime() + (seconds or 3)
end

function M.destroy()
	destroyWidget()
end

function M.update()
	if not ES.S.TOGGLE_ENABLED or ES.S.FAVOR_BAR_DISPLAY == "Never" then
		destroyWidget()
		return
	end

	local now = core.getSimulationTime()
	local shouldShow = phase == "completed" and now < showUntil
		or phase == "praying"
	if not shouldShow then
		destroyWidget()
		if phase == "completed" and now >= showUntil then
			phase       = nil
			favorBefore = nil
			favorGained = nil
		end
		return
	end

	local deity = prayerDeity
	if not deity and ES.saveData.currentDeity then
		deity = ES.DB.deities[ES.saveData.currentDeity]
	end
	local deityName    = deity and deity.name or "the Divine"
	local displayFavor = ES.saveData.favor or 0
	local baseFavor    = favorBefore or displayFavor
	local gained       = favorGained or 0

	local displayText
	if phase == "completed" then
		displayText = string.format("Favor: %.2f%% -> %.2f%% (+%.2f%%)", baseFavor, displayFavor, gained)
	else
		displayText = string.format("Praying to %s... (%.2f%%)", deityName, displayFavor)
	end

	if not widget then
		-- dark backdrop
		background = {
			name = "favor_bg",
			type = ui.TYPE.Image,
			props = {
				resource = ui.texture { path = 'white' },
				color = util.color.rgb(0.15, 0.12, 0.08),
				relativeSize = v2(1, 1),
				alpha = 0.9,
			},
		}
		-- base fill
		fill = {
			name = "favor_fill",
			type = ui.TYPE.Image,
			props = {
				resource = ui.texture { path = 'white' },
				color = getFavorColor(baseFavor),
				relativeSize = v2(baseFavor / ES.C.FAVOR_MAX, 1),
				alpha = 1,
			},
		}
		-- gain highlight
		gainFill = {
			name = "favor_gain",
			type = ui.TYPE.Image,
			props = {
				resource = ui.texture { path = 'white' },
				color = util.color.rgb(1.0, 0.95, 0.6),
				relativeSize = v2(0, 1),
				relativePosition = v2(baseFavor / ES.C.FAVOR_MAX, 0),
				alpha = 0,
			},
		}
		-- label above
		text = {
			name = "favor_text",
			type = ui.TYPE.Text,
			props = {
				text = displayText,
				textColor = G_morrowindLight or util.color.rgb(1,1,1),
				textShadow = true,
				textSize = math.max(1, WORLD_TOOLTIP_FONT_SIZE or 16),
				textAlignH = ui.ALIGNMENT.Center,
				relativePosition = v2(0.5, -1.2),
				anchor = v2(0.5, 1),
				autoSize = true,
			},
		}
		-- root widget
		widget = ui.create{
			layer = "Scene",
			name = "es_favor_bar",
			type = ui.TYPE.Widget,
			template = borderTemplate,
			props = {
				size = v2(BAR_WIDTH, BAR_HEIGHT),
				relativePosition = v2(0.5, 0.65),
				anchor = v2(0.5, 0.5),
				alpha = 1,
			},
			content = ui.content { background, fill, gainFill, text },
		}
		return
	end

	-- live update of existing widget
	local norm = displayFavor / ES.C.FAVOR_MAX
	if phase == "completed" and gained > 0 then
		local baseNorm = baseFavor / ES.C.FAVOR_MAX
		fill.props.relativeSize = v2(baseNorm, 1)
		fill.props.color = getFavorColor(baseFavor)
		gainFill.props.relativePosition = v2(baseNorm, 0)
		gainFill.props.relativeSize = v2(gained / ES.C.FAVOR_MAX, 1)
		gainFill.props.alpha = 1
	else
		fill.props.relativeSize = v2(norm, 1)
		fill.props.color = getFavorColor(displayFavor)
		gainFill.props.alpha = 0
	end
	text.props.text = displayText
	widget:update()
end

return M
