-- ------------------------------ Evening Star : favor bar -----------------
-- hud overlay shown around prayer.
-- one bar per deity whose favor just changed (a shrine can honor several), each animating its gain.
--
-- public api:
--   M.beginPraying(deity, favorBefore)   -- call per deity being prayed to
--   M.markCompleted(deity, gained, lingerSeconds)
--   M.bumpVisible(seconds)
--   M.update()    -- frame tick
--   M.destroy()

local M = {}

-- ------------------------------ constants ---------------------------------

local BAR_WIDTH  = 180
local BAR_HEIGHT = 11
local FONT_SIZE = 14
local BAR_GAP    = 6
local COLOR_LOW  = util.color.rgb(0.6, 0.4, 0.2)
local COLOR_MID  = util.color.rgb(0.8, 0.6, 0.1)
local COLOR_HIGH = util.color.rgb(1.0, 0.85, 0.3)
local COLOR_GAIN = util.color.rgb(1.0, 0.95, 0.6)

local borderTemplate = makeBorder("thin", nil, 1, {
	type = ui.TYPE.Image,
	props = {
		resource = ui.texture { path = 'black' },
		relativeSize = v2(1, 1),
		alpha = 0.4,
	}
}).borders

-- ------------------------------ state -------------------------------------

local widget        = nil
local phase         = nil    -- "praying" | "completed" | nil
local showUntil     = 0
local previewUntil  = 0      -- color preview, set while tuning in settings
local prayerInfo    = {}     -- [deityId] = { before = n, gained = n }
local lastSignature = nil    -- rebuild guard so update() is cheap per frame

-- ------------------------------ helpers -----------------------------------

local function getFavorColor(favor)
	do return ES.S.FAVOR_BAR_COLOR end
	local n = favor / ES.C.FAVOR_MAX
	if n < 0.33 then return COLOR_LOW end
	if n < 0.66 then return mixColors(COLOR_MID, COLOR_LOW, (n - 0.33) / 0.33) end
	return mixColors(COLOR_HIGH, COLOR_MID, (n - 0.66) / 0.34)
end

local function destroyWidget()
	if widget then
		widget:destroy()
		widget        = nil
		lastSignature = nil
	end
end

local function makeBar(baseNorm, baseColor, gainNorm)
	local children = {
		{
			type = ui.TYPE.Image,
			props = {
				resource = getTexture("textures/EveningStar/bar.dds"),
				color = util.color.rgb(0.15, 0.12, 0.08),
				relativeSize = v2(1, 1),
				alpha = 0.9,
			},
		},
		{
			type = ui.TYPE.Image,
			props = {
				resource = getTexture("textures/EveningStar/bar.dds"),
				color = baseColor,
				relativeSize = v2(baseNorm, 1),
				alpha = 1,
			},
		},
	}
	if gainNorm and gainNorm > 0 then
		children[#children + 1] = {
			type = ui.TYPE.Image,
			props = {
				resource = ui.texture { path = 'white' }, -- looks better than getTexture("textures/EveningStar/bar.dds")
				color = mixColors(ES.S.FAVOR_BAR_COLOR, util.color.rgb(1, 1, 1)),
				relativeSize = v2(gainNorm, 1),
				relativePosition = v2(baseNorm, 0),
				alpha = 1,
			},
		}
	end
	return {
		type = ui.TYPE.Widget,
		template = borderTemplate,
		props = { size = v2(BAR_WIDTH, BAR_HEIGHT) },
		content = ui.content(children),
	}
end

-- ------------------------------ public api --------------------------------

function M.beginPraying(deity, favorBeforeValue)
	if not deity then return end
	prayerInfo[deity.id] = { before = favorBeforeValue, gained = nil }
	phase = "praying"
end

function M.markCompleted(deity, gained, lingerSeconds)
	if deity and prayerInfo[deity.id] then
		prayerInfo[deity.id].gained = gained
	end
	showUntil = core.getRealTime() + (lingerSeconds or 3)
	phase     = "completed"
	destroyWidget()
	M.update()
end

function M.bumpVisible(seconds)
	showUntil = core.getRealTime() + (seconds or 3)
end

-- sample bar shown while the color is being tuned in settings
function M.preview(seconds)
	previewUntil = core.getRealTime() + (seconds or 3)
	destroyWidget()
	M.update()
end

function M.destroy()
	destroyWidget()
end

function M.update()
	local now = core.getRealTime()

	-- color preview: explicit settings action, bypasses the display rule
	if now < previewUntil then
		if not ES.S.TOGGLE_ENABLED then
			previewUntil = 0
			destroyWidget()
			return
		end
		local signature = "preview:"..tostring(ES.S.FAVOR_BAR_COLOR)
		if widget and signature == lastSignature then return end
		destroyWidget()
		lastSignature = signature
		local base = ES.C.FAVOR_MAX * 0.6
		local gain = ES.C.FAVOR_MAX * 0.15
		local rows = {}
		if FONT_SIZE > 0 then
			rows[#rows + 1] = {
				type = ui.TYPE.Text,
				props = {
					text = "Favor Bar Color",
					textColor = G_morrowindLight or util.color.rgb(1, 1, 1),
					textShadow = true,
					textSize = FONT_SIZE,
					textAlignH = ui.ALIGNMENT.Center,
					autoSize = true,
				},
			}
		end
		rows[#rows + 1] = makeBar(base / ES.C.FAVOR_MAX, getFavorColor(base), gain / ES.C.FAVOR_MAX)
		widget = ui.create {
			layer = "Notification",
			name = "es_favor_bar",
			type = ui.TYPE.Flex,
			props = {
				horizontal = false,
				align = ui.ALIGNMENT.Center,
				arrange = ui.ALIGNMENT.Center,
				relativePosition = v2(0.5, 0.65),
				anchor = v2(0.5, 0.5),
				autoSize = true,
			},
			content = ui.content(rows),
		}
		return
	end

	if not ES.S.TOGGLE_ENABLED or ES.S.FAVOR_BAR_DISPLAY == "Never" then
		destroyWidget()
		return
	end
	local shouldShow = (phase == "completed" and now < showUntil)
		or phase == "praying"
	if not shouldShow then
		destroyWidget()
		if phase == "completed" and now >= showUntil then
			phase      = nil
			prayerInfo = {}
		end
		return
	end
	
	local active = ES.saveData.activeDeities
	if #active == 0 then
		destroyWidget()
		return
	end
	
	local changed = {}
	for _, id in ipairs(active) do
		if prayerInfo[id] then changed[#changed + 1] = id end
	end
	if #changed == 0 then
		destroyWidget()
		return
	end
	
	-- rebuild only when the visible state changes
	local sigParts = { phase }
	for _, id in ipairs(changed) do
		local st   = ES.saveData.deities[id]
		local info = prayerInfo[id]
		sigParts[#sigParts + 1] = id..":"..math.floor((st and st.favor or 0) * 100)
			..":"..tostring(info.before)
			..":"..tostring(info.gained)
	end
	local signature = table.concat(sigParts, "|")
	if widget and signature == lastSignature then return end
	
	destroyWidget()
	lastSignature = signature
	
	local rows = {}
	for _, id in ipairs(changed) do
		local deity    = ES.getDeity(id)
		local st       = ES.saveData.deities[id]
		local favorNow = st and st.favor or 0
		local info     = prayerInfo[id]
		
		local base, gain, labelText
		if phase == "completed" and info.gained then
			base = info.before or favorNow
			gain = info.gained or 0
			labelText = string.format("%s: +%.1f%%",
				deity and deity.name or "?", gain)
		else
			base = favorNow
			gain = 0
			labelText = string.format("Praying to %s... (%.1f%%)",
				deity and deity.name or "the Divine", favorNow)
		end
		
		-- label
		if FONT_SIZE > 0 then
			rows[#rows + 1] = {
				type = ui.TYPE.Text,
				props = {
					text = labelText,
					textColor = G_morrowindLight or util.color.rgb(1, 1, 1),
					textShadow = true,
					textSize = FONT_SIZE,
					textAlignH = ui.ALIGNMENT.Center,
					autoSize = true,
				},
			}
		end
		-- bar
		rows[#rows + 1] = makeBar(base / ES.C.FAVOR_MAX, getFavorColor(base), gain / ES.C.FAVOR_MAX)
		-- gap
		rows[#rows + 1] = { props = { size = v2(0, BAR_GAP) } }
	end
	
	widget = ui.create {
		layer = "Notification",
		name = "es_favor_bar",
		type = ui.TYPE.Flex,
		props = {
			horizontal = false,
			align = ui.ALIGNMENT.Center,
			arrange = ui.ALIGNMENT.Center,
			relativePosition = v2(0.5, 0.62),
			anchor = v2(0.5, 0.5),
			autoSize = true,
		},
		content = ui.content(rows),
	}
end

return M
