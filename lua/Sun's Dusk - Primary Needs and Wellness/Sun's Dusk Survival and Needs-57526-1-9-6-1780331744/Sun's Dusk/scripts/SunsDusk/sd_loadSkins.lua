-- ╭────────────────────────────────────────────────────────────────────────╮
-- │  Sun's Dusk - Skin Loader                                              │
-- ╰────────────────────────────────────────────────────────────────────────╯
-- one need-skin per folder under textures/sunsdusk/skins/<skin>/, described by
-- a meta.lua returning a table. writes into the shared G_iconPacks so widgets
-- and settings consume skins and legacy packs uniformly. must run AFTER
-- sd_loadTexturePacks (which replaces G_iconPacks) so entries merge, not clobber.

G_iconPacks = G_iconPacks or {}

local SKINS_ROOT = "textures/sunsdusk/skins/"

------------------------------ resolve ------------------------------
-- every meta field may be a value or function(ctx); resolve once per update to
-- a plain tree. userdata (vectors/colors) are not tables, so passed through.
function G_resolveSkin(node, ctx)
	if type(node) == "function" then
		return node(ctx)
	end
	if type(node) == "table" then
		local resolved = {}
		for key, value in pairs(node) do
			resolved[key] = G_resolveSkin(value, ctx)
		end
		return resolved
	end
	return node
end

------------------------------ content-skin renderer ------------------------------
-- shared shell for any need's content skin: builds the widget once from
-- skin.content(ctx), then lets skin.update(ctx) mutate it per tick (or rebuilds the
-- tree when the skin has no update()). the caller passes a ctx carrying the live
-- need state; this fills in the generic bits (art paths, docking hints, time, alpha)
-- and the sizing/visibility plumbing the hud column system needs. returns the widget
-- so the caller can attach a tooltip, or nil when the skin has no content().
function G_renderContentSkin(opts, ctx)
	local skin = ctx.skin
	if not (skin and skin.content) then return nil end

	-- generic live bits every skin may read
	ctx.base = skin.base
	ctx.extension = skin.extension
	ctx.stages = skin.stages
	ctx.time = core.getRealTime()
	ctx.hudOrientation = HUD_ORIENTATION
	ctx.dockedRight = G_hudLayerSize and HUD_X_POS > G_hudLayerSize.x / 2 or false
	ctx.dockedBottom = G_hudLayerSize and HUD_Y_POS > G_hudLayerSize.y / 2 or false

	-- sizing + visibility hints, each a value or a function of ctx
	-- evaluate then coerce: a function returning false/nil leaves the and/or chain holding
	-- the function itself, so anything that is not a number falls back to its default
	local aspectRatio = type(skin.aspectRatio) == "function" and skin.aspectRatio(ctx) or skin.aspectRatio
	local heightMult = type(skin.heightMult) == "function" and skin.heightMult(ctx) or skin.heightMult
	local effectiveAlpha = type(skin.alpha) == "function" and skin.alpha(ctx) or skin.alpha
	if type(aspectRatio) ~= "number" then aspectRatio = 1 end
	if type(heightMult) ~= "number" then heightMult = 1 end
	if type(effectiveAlpha) ~= "number" then effectiveAlpha = 1 end
	ctx.alpha = effectiveAlpha

	-- shell widget; content() runs once and captures the skin's element handles
	local widget = G_columnWidgets[opts.name]
	local justCreated = false
	if not widget then
		widget = ui.create{
			name = opts.name,
			type = ui.TYPE.Widget,
			props = {
				size = v2(HUD_ICON_SIZE * aspectRatio, HUD_ICON_SIZE * heightMult),
			},
			userData = {
				aspectRatio = aspectRatio,
				heightMult = heightMult,
				order = opts.order,
				effectiveAlpha = effectiveAlpha,
				stickToEdge = opts.stickToEdge or nil,
			},
			content = skin.content(ctx),
		}
		G_columnWidgets[opts.name] = widget
		justCreated = true
		G_columnsNeedUpdate = true
		G_iconSizeNeedsUpdate = true
	end

	-- keep hints fresh, re-sort columns on a visibility flip
	local prevAlpha = widget.layout.userData.effectiveAlpha or 1
	if (prevAlpha > 0) ~= (effectiveAlpha > 0) then
		G_columnsNeedUpdate = true
	end
	widget.layout.userData.aspectRatio = aspectRatio
	widget.layout.userData.heightMult = heightMult
	widget.layout.userData.effectiveAlpha = effectiveAlpha

	-- retained skins gate their own redraw via update(), simple skins rebuild
	local dirty = justCreated
	if not justCreated then
		if skin.update then
			dirty = skin.update(ctx) and true or false
		else
			widget.layout.content = skin.content(ctx)
			dirty = true
		end
	end
	if dirty then
		widget:update()
	end
	return widget
end

------------------------------ loader ------------------------------
function rebuildSkins()
	-- collect skin folder ids
	local skinSet = {}
	for filePath in vfs.pathsWithPrefix(SKINS_ROOT) do
		local skinId = filePath:match("^" .. SKINS_ROOT .. "([^/]+)/")
		if skinId and not skinId:match("^%._") then
			skinSet[skinId] = true
		end
	end

	local skinList = {}
	for skinId in pairs(skinSet) do
		table.insert(skinList, skinId)
	end
	table.sort(skinList, function(a, b) return a:lower() < b:lower() end)

	-- load each skin's meta and merge into G_iconPacks
	for skinIndex = 1, #skinList do
		local skinId = skinList[skinIndex]
		local skinBasePath = SKINS_ROOT .. skinId .. "/"
		local metaModule = "textures.sunsdusk.skins." .. skinId .. ".meta"

		-- meta.lua may be missing or malformed; never crash the loader
		local ok, meta = pcall(require, metaModule)

		-- identity fields must be concrete; everything else may be a function
		if ok and type(meta) == "table"
		and type(meta.need) == "string"
		and type(meta.name) == "string" then
			local needId = meta.need
			-- loader-supplied identity/path fields
			meta.id = skinId
			meta.base = skinBasePath
			meta.variant = "Skin"

			local niceName = meta.name

			if not G_iconPacks[needId] then
				G_iconPacks[needId] = { availablePacks = {} }
			end
			if not G_iconPacks[needId][niceName] then
				G_iconPacks[needId][niceName] = meta
				table.insert(G_iconPacks[needId].availablePacks, niceName)
			end
		end
	end

	-- re-sort each need's pack list so skins interleave with legacy packs
	for _, bucket in pairs(G_iconPacks) do
		table.sort(bucket.availablePacks, function(a, b) return a:lower() < b:lower() end)
	end

	return G_iconPacks
end

rebuildSkins()
