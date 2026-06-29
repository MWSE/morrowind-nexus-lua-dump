-- ------------------------------ Evening Star : sun's dusk hud widget ------
-- the deity icon in the sun's dusk hud column: it tracks the deity most overdue for prayer,
-- and its urgency style (staged tint / transparency) reflects how close that deity is to favor
-- decay. ticks each game-minute so the styling ramps live as time passes.
-- the deity-selection flow + lifecycle glue live in es_ui; this file owns only the widget.

-- ------------------------------ state -------------------------------------

local deityIconWidget = nil
local deityIcon       = nil  -- retained content refs, mutated in place on each tick
local deityBackground = nil
local lastDeityId     = nil
local lastStyleKey    = nil  -- throttles urgency-styling churn to ~1% steps
local lastTooltipStr  = nil

-- ------------------------------ urgency palettes --------------------------
-- urgency tint: a green -> yellow -> red ramp echoing sun's dusk's staged need icons,
-- continuous since prayer urgency has no fixed stages. each palette is the six stage colours
-- sampled from that texture pack, so the icon harmonizes with whichever hud pack is active.
-- resample if a pack's art is recoloured; unknown/greyscale packs fall back to modern2.
local URGENCY_PALETTES = {
	modern = {
		{ 0.16, 0.48, 0.19 }, { 0.26, 0.48, 0.16 }, { 0.40, 0.48, 0.16 },
		{ 0.48, 0.43, 0.16 }, { 0.48, 0.29, 0.16 }, { 0.48, 0.16, 0.16 },
	},
	velothi = {
		{ 0.35, 0.90, 0.30 }, { 0.72, 0.79, 0.32 }, { 0.87, 0.86, 0.20 },
		{ 0.82, 0.63, 0.18 }, { 0.82, 0.37, 0.18 }, { 0.82, 0.18, 0.24 },
	},
}
URGENCY_PALETTES.velothi2 = URGENCY_PALETTES.velothi  -- same art family
URGENCY_PALETTES.starwind = URGENCY_PALETTES.velothi  -- same art family
URGENCY_PALETTES.modern2 = URGENCY_PALETTES.modern  -- same art family
local URGENCY_DEFAULT   = URGENCY_PALETTES.modern2
local ICON_ALPHA_FLOOR  = 0.1  -- transparency mode never fully hides the icon

-- which staged pack the hud is currently showing, by folder id; checks each need skin in
-- turn and prefers one we have a palette for (mixed packs / disabled needs stay sane)
local function activeStagedPackId()
	if not G_iconPacks then return nil end
	local needSkins = {
		{ bucket = "hunger", skin = H_SKIN },
		{ bucket = "thirst", skin = T_SKIN },
		{ bucket = "sleep",  skin = S_SKIN },
		{ bucket = "clean",  skin = C_SKIN },
	}
	local fallbackId
	for _, entry in ipairs(needSkins) do
		local bucket = G_iconPacks[entry.bucket]
		local pack = entry.skin and bucket and bucket[entry.skin]
		if pack and pack.id then
			if URGENCY_PALETTES[pack.id] then return pack.id end
			fallbackId = fallbackId or pack.id
		end
	end
	return fallbackId
end

-- interpolate the active pack's six stage colours at urgency u, composed with the icon tint
local function urgencyTint(urgency)
	local stages = URGENCY_PALETTES[activeStagedPackId() or ""] or URGENCY_DEFAULT
	local u = math.max(0, math.min(1, urgency)) * (#stages - 1)
	local i = math.floor(u)
	local r, g, b
	if i >= #stages - 1 then
		r, g, b = stages[#stages][1], stages[#stages][2], stages[#stages][3]
	else
		local lo, hi, f = stages[i + 1], stages[i + 2], u - i
		r = lo[1] + (hi[1] - lo[1]) * f
		g = lo[2] + (hi[2] - lo[2]) * f
		b = lo[3] + (hi[3] - lo[3]) * f
	end
	-- compose with the user's icon tint (white by default)
	local ic = ES.S.ICON_COLOR
	if ic then return util.color.rgb(r * ic.r, g * ic.g, b * ic.b) end
	return util.color.rgb(r, g, b)
end

-- hud tooltip: every worshipped deity, most overdue for prayer first (the one on the icon)
local function buildIconTooltip()
	local active = ES.saveData and ES.saveData.activeDeities or {}
	if #active == 1 then
		local d = ES.getDeity(active[1])
		if not d then return "" end
		local st = ES.saveData.deities[active[1]]
		local favor = st and st.favor or 0
		local level = ES.getDevotionLevel(active[1])
		return string.format("%s\n%s\nFavor: %.2f%% (%s)", d.name, d.title or "", favor, ES.DEVOTION_NAMES[level])
	end
	local order = {}
	for _, id in ipairs(active) do order[#order + 1] = id end
	table.sort(order, function(a, b)
		local ua, ub = ES.getDeityUrgency(a), ES.getDeityUrgency(b)
		if ua ~= ub then return ua > ub end
		local sa, sb = ES.saveData.deities[a], ES.saveData.deities[b]
		return (sa and sa.favor or 0) < (sb and sb.favor or 0)
	end)
	local lines = {}
	for i, id in ipairs(order) do
		local d = ES.getDeity(id)
		if d then
			local st = ES.saveData.deities[id]
			local favor = st and st.favor or 0
			local level = ES.getDevotionLevel(id)
			-- arrow marks the deity shown on the icon (the most overdue)
			lines[#lines + 1] = string.format("%s  %.0f%% (%s)", d.name, favor, ES.DEVOTION_NAMES[level])
			local now = core.getGameTime()
			local idleHours = (now - (st and st.lastFavorGain or now)) / 3600
			lines[#lines + 1] = string.format(" Last worship: %d:%02d hours ago", math.floor(idleHours), math.floor(idleHours * 60) % 60)
		end
	end
	return table.concat(lines, "\n")
end

-- ------------------------------ widget ------------------------------------

function ES.destroyDeityIcon()
	if deityIconWidget then
		deityIconWidget:destroy()
		deityIconWidget = nil
	end
	deityIcon       = nil
	deityBackground = nil
	lastDeityId     = nil
	lastStyleKey    = nil
	lastTooltipStr  = nil
	if G_columnWidgets and G_columnWidgets.m_deity_icon then
		G_columnWidgets.m_deity_icon = nil
		G_columnsNeedUpdate = true
	end
end

function ES.updateDeityIcon()
	if not ES.S.TOGGLE_ENABLED or not ES.S.TOGGLE_SHOW_ICON or ES.S.ICON_DISPLAY == "Never" then
		ES.destroyDeityIcon()
		return
	end
	-- single icon for the deity most overdue for prayer
	local deity, urgency = ES.getMostUrgentDeity()
	if not deity then
		ES.destroyDeityIcon()
		return
	end

	if not G_columnWidgets then G_columnWidgets = {} end
	local tex  = getTexture("textures/EveningStar/deities/"..deity.id..".png")
	local mode = ES.S.ICON_URGENCY_STYLE or "Off"

	-- (re)build on first show or when the displayed deity changes
	if not deityIconWidget or lastDeityId ~= deity.id then
		ES.destroyDeityIcon()

		deityBackground = ES.S.ICON_BACKGROUND ~= "No Background" and {
			name = "es_icon_bg",
			type = ui.TYPE.Image,
			props = {
				resource = ES.S.ICON_BACKGROUND == "Classic"
					and getTexture("textures/EveningStar/deities/BlankTexture.png")
					or tex,
				color = ES.S.ICON_BACKGROUND == "Classic" and ES.S.ICON_BACKGROUND_COLOR or util.color.rgb(0,0,0),
				relativeSize = v2(1, 1),
				relativePosition = ES.S.ICON_BACKGROUND == "Shadow" and v2(0.04, 0.027) or nil,
				alpha = 1,
			},
		} or {}

		deityIcon = {
			name = "es_icon",
			type = ui.TYPE.Image,
			props = {
				resource = tex,
				color = ES.S.ICON_COLOR,
				relativeSize = v2(1, 1),
				alpha = 1,
			},
		}

		deityIconWidget = ui.create{
			name = "m_deity_icon",
			type = ui.TYPE.Widget,
			props = { size = v2(HUD_ICON_SIZE, HUD_ICON_SIZE) },
			userData = {
				order = "widget-deity",
			},
			content = ui.content { deityBackground, deityIcon },
		}

		G_columnWidgets.m_deity_icon = deityIconWidget
		lastDeityId  = deity.id
		lastStyleKey = nil  -- force a styling pass on the fresh widget
		G_columnsNeedUpdate = true
	end

	-- throttle styling to ~1% urgency steps; active pack folds in so a hud pack swap refreshes the tint
	local styleKey = mode..":"..(activeStagedPackId() or "?")..":"..math.floor(math.min(1, urgency) * 100 + 0.5)
	if deityIcon and styleKey ~= lastStyleKey then
		lastStyleKey = styleKey
		if mode == "Staged" then
			deityIcon.props.color = urgencyTint(urgency)
			deityIcon.props.alpha = 1
			if deityBackground.props then deityBackground.props.alpha = 1 end
		elseif mode == "Transparent" then
			--local iconAlpha = HUD_ALPHA == "Static" and 1 or getWidgetAlpha(urgency, nil, ICON_ALPHA_FLOOR)
			local iconAlpha = HUD_ALPHA == "Static" and 1 or urgency
			deityIcon.props.color = ES.S.ICON_COLOR
			deityIcon.props.alpha = iconAlpha
			if deityBackground.props then
				deityBackground.props.alpha = ES.S.ICON_BACKGROUND == "Classic" and iconAlpha ^ 2 or iconAlpha
			end
		else
			deityIcon.props.color = ES.S.ICON_COLOR
			deityIcon.props.alpha = 1
			if deityBackground.props then deityBackground.props.alpha = 1 end
		end
		deityIconWidget:update()
	end

	-- tooltip lists every worshipped deity
	local tip = buildIconTooltip()
	if tip ~= lastTooltipStr then
		lastTooltipStr = tip
		addTooltip(deityIconWidget.layout, tip)
	end
end

-- post-frame icon refresh once UI templates are ready
table.insert(G_onLoadJobs, ES.updateDeityIcon)

-- tick the icon each game-minute so prayer urgency ramps as time passes
table.insert(G_perMinuteJobs, ES.updateDeityIcon)
