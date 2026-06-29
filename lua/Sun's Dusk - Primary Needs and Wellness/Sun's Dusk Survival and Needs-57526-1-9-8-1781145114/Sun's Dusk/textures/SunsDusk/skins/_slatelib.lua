-- ╭────────────────────────────────────────────────────────────────────────╮
-- │  Slate skins - shared builder for the simple needs                     │
-- ╰────────────────────────────────────────────────────────────────────────╯
-- builds a content skin for a leveled need (hunger/thirst/sleep/clean). the art is
-- the ring carries its own green->red severity gradient, so it is drawn untinted
-- while the glyph still takes the need color.
local RING_STEPS = 48   -- must match GAUGE_STEPS in _generate_slate.py

-- cfg fields:
--   need, name, prefix           identity + frame naming
--   colorKey, hideKey            global setting names read live each tick
--   profileField                 optional ctx field holding a profile state string
--   primaryProfiles              optional set of profiles that replace the glyph (e.g. insomniac)

local function makeSlateSkin(cfg)
	local bgEl, glyphEl, ringEl, profileEl
	local lastRing, lastAlpha, lastProfile, lastPrimary

	-- ring frame for the live value: 0 (good) .. RING_STEPS-1 (bad)
	local function ringIndex(ctx)
		local i = math.floor(ctx.value * (RING_STEPS - 1) + 0.5)
		if i < 0 then return 0 elseif i > RING_STEPS - 1 then return RING_STEPS - 1 end
		return i
	end
	local function profileName(ctx)
		local p = cfg.profileField and ctx[cfg.profileField]
		if p and p ~= "fasting" then return p end
		return nil
	end
	-- a primary profile (e.g. insomniac) takes over the glyph instead of riding along as a badge
	local function primaryProfile(ctx)
		local p = profileName(ctx)
		if p and cfg.primaryProfiles and cfg.primaryProfiles[p] then return p end
		return nil
	end
	-- main art: the profile frame for a primary profile, else the static need glyph
	local function glyphTex(ctx)
		local primary = primaryProfile(ctx)
		if primary then return getTexture(ctx.base .. cfg.prefix .. "_" .. primary .. ctx.extension) end
		return getTexture(ctx.base .. cfg.prefix .. ctx.extension)
	end

	return {
		need = cfg.need,
		name = cfg.name,
		-- single static base texture; the smooth ring is composited inside this skin,
		-- so tooltips and the settings preview just take base..prefix
		stages = 1,
		extension = ".png",

		-- hide-no-buff: drop the icon only when the user opted in and the need yields no
		-- active effect for the chosen mode (raw buff is false; nil just means loading)
		alpha = function(ctx)
			if _G[cfg.hideKey] and ctx.buff == false then return 0 end
			return 1
		end,

		-- build once, capture handles
		content = function(ctx)
			local tex = glyphTex(ctx)
			local a = ctx.alpha
			local tint = _G[cfg.colorKey] or util.color.rgb(1, 1, 1)
			local profile = profileName(ctx)
			local primary = primaryProfile(ctx)

			-- drop shadow, the glyph tinted black and nudged down-right
			bgEl = {
				name = cfg.prefix .. "_background",
				type = ui.TYPE.Image,
				props = {
					resource = tex,
					color = util.color.rgb(0, 0, 0),
					tileH = false,
					tileV = false,
					relativeSize = v2(1, 1),
					relativePosition = v2(0.04, 0.027),
					alpha = a > 0 and 0.5 or 0,
				},
			}
			-- static need glyph, tinted by the need color
			glyphEl = {
				name = cfg.prefix .. "_icon",
				type = ui.TYPE.Image,
				props = {
					resource = tex,
					color = tint,
					tileH = false,
					tileV = false,
					relativeSize = v2(1, 1),
					alpha = a,
				},
			}
			-- gauge-ring overlay, untinted so its severity gradient shows; hidden under a primary profile
			ringEl = {
				name = cfg.prefix .. "_ring",
				type = ui.TYPE.Image,
				props = {
					resource = getTexture(ctx.base .. "ring_" .. ringIndex(ctx) .. ctx.extension),
					color = util.color.rgb(1, 1, 1),
					tileH = false,
					tileV = false,
					relativeSize = v2(1, 1),
					alpha = primary and 0 or a,
				},
			}
			-- profile/state badge, lower-left so it clears the corner signature
			-- a primary profile owns the glyph, so its badge stays hidden
			profileEl = {
				name = cfg.prefix .. "_profile",
				type = ui.TYPE.Image,
				props = {
					-- when no profile is active the badge is hidden; fall back to the
					-- static glyph so getTexture never hits a missing file
					resource = getTexture(ctx.base .. cfg.prefix .. (profile and ("_" .. profile) or "") .. ctx.extension),
					color = tint,
					tileH = false,
					tileV = false,
					relativeSize = v2(0.45, 0.45),
					relativePosition = v2(0.0, 0.55),
					alpha = (profile and not primary) and a or 0,
				},
			}
			lastRing = ringIndex(ctx)
			lastAlpha = a
			lastProfile = profile
			lastPrimary = primary
			return ui.content { bgEl, glyphEl, ringEl, profileEl }
		end,

		-- poke only what changed, report whether anything did
		update = function(ctx)
			local dirty = false
			local ri = ringIndex(ctx)
			local profile = profileName(ctx)
			local primary = primaryProfile(ctx)
			local a = ctx.alpha
			-- glyph swaps only when a primary profile takes over or releases it
			if primary ~= lastPrimary then
				local tex = glyphTex(ctx)
				glyphEl.props.resource = tex
				bgEl.props.resource = tex
				lastPrimary = primary
				dirty = true
			end
			-- ring advances with the live value
			if ri ~= lastRing then
				ringEl.props.resource = getTexture(ctx.base .. "ring_" .. ri .. ctx.extension)
				lastRing = ri
				dirty = true
			end
			if a ~= lastAlpha then
				lastAlpha = a
				glyphEl.props.alpha = a
				bgEl.props.alpha = a > 0 and 0.5 or 0
				dirty = true
			end
			-- ring rides the comfort-fade but vanishes while a primary profile owns the glyph
			ringEl.props.alpha = primary and 0 or a
			if profile ~= lastProfile then
				lastProfile = profile
				if profile and not primary then
					profileEl.props.resource = getTexture(ctx.base .. cfg.prefix .. "_" .. profile .. ctx.extension)
				end
				dirty = true
			end
			profileEl.props.alpha = (profile and not primary) and a or 0
			return dirty
		end,
	}
end

return { makeSlateSkin = makeSlateSkin }
