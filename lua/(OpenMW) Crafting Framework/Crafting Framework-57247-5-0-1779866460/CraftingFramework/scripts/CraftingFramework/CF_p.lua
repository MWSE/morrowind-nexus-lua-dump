MODNAME = "CraftingFramework"

vfs = require('openmw.vfs')
local f = vfs.open("scripts/CraftingFramework/api_version.txt")
VERSION = tonumber(f:read("*all"))
f:close()

core = require('openmw.core')
I = require('openmw.interfaces')
types = require('openmw.types')
self = require('openmw.self')
Player = require('openmw.types').Player
async = require('openmw.async')
ui = require('openmw.ui')
util = require('openmw.util')
v2 = util.vector2
ambient = require('openmw.ambient')
animation = require('openmw.animation')
input = require('openmw.input')
camera = require('openmw.camera')
nearby = require('openmw.nearby')
time = require('openmw_aux.time')
playerHealth = types.Actor.stats.dynamic.health(self)
onFrameFunctions = {}
onActiveFunctions = {}
API = {}
-- holds every live ui element of the crafting window; cleared on destroy
WINDOW = {}
-- ------------------------------ api surface ------------------------------
-- version = 5
--
-- recipe gates, password must match recipe.disabled / recipe.hidden
-- enableRecipe(recipeId, password)   - open the disabled gate
-- resetRecipe(recipeId, password)    - re-close the disabled gate
-- discoverRecipe(recipeId, password) - open the hidden gate
-- forgetRecipe(recipeId, password)   - re-close the hidden gate
--
-- setProfession(name) -> bool        - switch active profession
-- getProfessionList() -> {[name]=visible}  - all profs + visible bool (unordered)
-- openCraftingWindow(name[opt])      - open; name = external invoke
-- closeCraftingWindow()              - destroy the window
-- clearCraftingQueue()               - empty queue, abort active craft
-- skipCurrentRecipe()                - drop current queued recipe, advance
--
-- registration, opts table, version-gated, returns bool
-- registerWildcard{id,name,version,icon,strict,func}
-- registerStation{id,name,version,icon,func}
-- registerProfession{name,skillId,version,hidden,solo,priority}
-- registerTouch{id,label,gate,priority}    - player-toggle modifier
-- toggleTouch(id, state[opt])              - flip if nil, else set true/false
-- onTouchToggled(fn)                       - sync listener; fn({id, active})
-- registerVirtual{id,name,version,icon,label,consumed,countFunc,formatCount,unit}
-- onVirtualConsumed(fn)                    - sync listener; fn({virtualId, count, recipe})
--
-- modifier chains: register{id,global,priority,func} / unregister(id|func)
-- registerQualityModifier / unregisterQualityModifier         - quality mult
-- registerExpModifier / unregisterExpModifier                 - exp award
-- registerStatsModifier / unregisterStatsModifier             - stat overrides
-- registerValueModifier / unregisterValueModifier             - gold value
-- registerRecipeNameModifier / unregisterRecipeNameModifier   - display name
-- registerResultItemModifier / unregisterResultItemModifier   - result recordId
-- registerResultCountModifier / unregisterResultCountModifier - output count
-- registerEnchantmentModifier / unregisterEnchantmentModifier - enchantment
-- registerIngredientsModifier / unregisterIngredientsModifier - ingredient list
-- registerTimeModifier / unregisterTimeModifier               - craft duration
-- registerTooltipLine / unregisterTooltipLine                 - appended line
-- registerTooltipModifier / unregisterTooltipModifier         - tooltip mutate
-- registerWindowBuilder / unregisterWindowBuilder             - mutate window at build
--
-- manual crafting
-- advanceManualCrafting(id, percent[0..100], data[opt]) -> bool
--
-- live accessors, read only
-- getCraftingState() -> craftingState
-- getCraftingQueue() -> craftingQueue
-- getCraftingWindow() -> window element or nil
-- getGlobals() -> _G
-- getItemQuality(item) -> quality mult
-- -------------------------------------------------------------------------
-- carried so `interface = API` keeps the version field
API.version = VERSION

-- settings
storage = require('openmw.storage')
S_CRAFTING_TIME = 0
require("scripts.CraftingFramework.CF_settings")

require("scripts.CraftingFramework.CF_core")
cheatMode = false

-- re-run on USE_VANILLA_COLORS toggle
function refreshColors()
	textColor = getColorFromGameSettings("fontColor_color_normal_over")
	lightText = util.color.rgb(textColor.r ^ 0.5, textColor.g ^ 0.5, textColor.b ^ 0.5)
	morrowindGold = getColorFromGameSettings("fontColor_color_normal")
	goldenMix = mixColors(textColor, morrowindGold)
	darkerFont = getColorFromGameSettings("fontColor_color_normal")
	morrowindBlue = getColorFromGameSettings("fontColor_color_journal_link")
	morrowindBlue2 = getColorFromGameSettings("fontColor_color_journal_link_over")
	morrowindBlue3 = getColorFromGameSettings("fontColor_color_journal_link_pressed")
end
refreshColors()
selectedColor = util.color.rgb(0.6, 0.5, 0.2)
hoverColor = util.color.rgb(0.3, 0.25, 0.15)
background = ui.texture { path = 'black' }
GREEN = util.color.rgb(0, 1, 0)

skillValueCache = {}
currentSubcategory = nil
currentIndex = nil
cachedTempInventory = nil
lastScroll = 0
activeTouches = {}
filterRecipes = false

tempInventory = nil
tempInventoryByType = nil
tempInventoryByRecord = nil
tempInventoryVirtual = nil
lastSelectionMove = 0
moveSelectionDirection = nil
selectedRecipe = nil
selectedCount = 0
lastFxTime = 0

lastTooltipPos = v2(0,0)
craftingQueue = {}
pendingInventoryChanges = {}
textureCache = {}
windowPos = v2(0, 0)
local inventoryChanged = false
local lastEncumbrance = 0
craftingSounds = {} -- definitions

-- ========================= WILDCARDS v2 =========================
local wildcardVersions = {}
wildcardNames = {}
wildcardIcons = {}
wildcardStrict = {}
wildcards = {}

-- registerWildcard{ id="...", name="...", version=1, icon="path.dds", strict=false, func=... }
-- icon: optional, fallback if no item
-- strict: never substitute other pool items when the selected one runs short.
function registerWildcard(opts)
	local id = opts.id
	local version = opts.version or 0
	local existing = wildcardVersions[id] or -1
	if version >= existing then
		wildcards[id] = opts.func
		wildcardVersions[id] = version
		wildcardNames[id] = opts.name or wildcardNames[id] or id
		wildcardIcons[id] = opts.icon or wildcardIcons[id]
		wildcardStrict[id] = opts.strict or false
		return true
	end
	return false
end
API.registerWildcard = registerWildcard -- used internally

-- legacy support
wildcardFunctions = setmetatable({}, {
	__newindex = function(_, id, func)
		registerWildcard{ id = id, name = id, version = 0, func = func }
	end,
})

-- ========================= VIRTUAL INGREDIENTS =========================
-- ingredients with no engine record; registrant supplies count via countFunc
local virtualVersions = {}
virtuals = {} -- id -> { name, description, icon, label, consumed, countFunc, formatCount, unit }
virtualConsumedListeners = {}

-- registerVirtual{ id, name, version, description, icon, label, consumed, countFunc, formatCount, unit }
-- name/icon/label/description may be value or function(available, required)
-- countFunc runs per snapshot; call invalidateInventoryCache on outside changes
function registerVirtual(opts)
	local id = opts.id
	local version = opts.version or 0
	local existing = virtualVersions[id] or -1
	if version >= existing then
		virtuals[id] = {
			name = opts.name or id,
			description = opts.description,
			icon = opts.icon,
			label = opts.label,
			consumed = opts.consumed,
			countFunc = opts.countFunc,
			formatCount = opts.formatCount,
			unit = opts.unit,
		}
		virtualVersions[id] = version
		-- next snapshot must include this virtual
		invalidateInventoryCache()
		return true
	end
	return false
end
API.registerVirtual = registerVirtual

-- listen to other mod's virtual consumption {virtualId, count, recipe}
function onVirtualConsumed(fn)
	table.insert(virtualConsumedListeners, fn)
end
API.onVirtualConsumed = onVirtualConsumed

-- ========================= STATIONS =========================
local stationVersions = {}
stationNames = {}
stationIcons = {}
stationIconFuncs = {}
stations = {}

-- registerStation{ id="fire", name="Fire", version=1, icon="textures/fire.png", func=function() end }
function registerStation(opts)
	local id = opts.id
	local version = opts.version or 0
	local existing = stationVersions[id] or -1
	if version >= existing then
		stations[id] = opts.func
		stationVersions[id] = version
		stationNames[id] = opts.name or stationNames[id] or id
		stationIcons[id] = opts.icon or stationIcons[id]
		stationIconFuncs[id] = opts.iconFunc or stationIconFuncs[id]
		return true
	end
	return false
end
API.registerStation = registerStation -- api-only

-- ========================= MODIFIER CHAINS =========================
-- register{id, global=false, priority=0, func=fn(recipe, ctx)}; func mutates ctx.modified (or reassigns), return false halts.
-- anonymous/global=true fires per recipe; named non-global fires only when a recipe's <chain>Func names it.

local function makeModifierChain()
	local list = {}
	local seq = 0
	local chain = {}
	function chain.register(opts)
		if opts.id then
			for i, entry in ipairs(list) do
				if entry.id == opts.id then
					table.remove(list, i)
					break
				end
			end
		end
		seq = seq + 1
		table.insert(list, {
			id = opts.id,
			global = opts.id and opts.global or not opts.id,
			priority = opts.priority or 0,
			seq = seq,
			func = opts.func,
		})
		table.sort(list, function(a, b)
			if a.priority ~= b.priority then return a.priority < b.priority end
			return a.seq < b.seq
		end)
	end
	-- unregister by id or a func ref
	function chain.unregister(key)
		for i, entry in ipairs(list) do
			if entry.id == key or entry.func == key then
				table.remove(list, i)
				return
			end
		end
	end
	function chain.byId(id)
		if id == nil then return end
		for _, entry in ipairs(list) do
			if entry.id == id then return entry end
		end
	end
	function chain.apply(recipe, ctx, skipId)
		for _, entry in ipairs(list) do
			if entry.global and (skipId == nil or entry.id ~= skipId)
					and entry.func(recipe, ctx) == false then
				break
			end
		end
		return ctx.modified
	end
	return chain
end

-- quality chain: ctx.modified is the quality multiplier (1.0 = baseline); base is skillMult.
-- ctx has base, modified, recipe, skillMult, artisanMult, touches, isPreview, ingredients, craftData.
qualityModifierChain = makeModifierChain()
-- exp chain: fires once per recipe. ctx.base and ctx.modified are { [skillId] = exp }
-- (split recipes halve each entry); mutate ctx.modified[skillId] to award.
-- ctx.skills is { [skillId] = { diffMod, level, skillExpMult, isSecondSkill } }.
-- ctx also has recipe, recipeExp, touches, ingredients, globalExpMult, fileExpMult, splittedExp, isPreview, craftData.
expModifierChain = makeModifierChain()
-- stats chain: ctx.modified is a stat-overrides table for createRecordDraft; nil = passthrough.
-- ctx has base, modified, recipe, record, recordType, qualityMult, touches, isPreview, ingredients, craftData.
statsModifierChain = makeModifierChain()
-- value chain: ctx.modified is the gold value of the crafted item.
-- ctx has base, modified, recipe, touches, qualityMult, ingredients, isPreview, craftData.
valueModifierChain = makeModifierChain()
-- name chain: ctx.modified is the display name (string or nil = use record name); base is recipe.name.
-- ctx has base, modified, recipe, touches, qualityMult, ingredients, isPreview, craftData.
recipeNameModifierChain = makeModifierChain()
-- result chain: ctx.modified is the recordId to create; runs first so other chains see the swap.
-- ctx has base, modified, recipe, touches, ingredients, isPreview, craftData.
resultItemModifierChain = makeModifierChain()
-- count chain: ctx.modified is the output count (may be fractional); runs after result.
-- ctx has base, modified, recipe, touches, ingredients, isPreview, craftData, resultId, resultType.
resultCountModifierChain = makeModifierChain()
-- enchantment chain: ctx.modified is a createRecordDraft def, a record id, "" for none, or nil for no override.
-- ctx has base, modified, recipe, record, recordType, qualityMult, touches, isPreview, ingredients, craftData.
enchantmentModifierChain = makeModifierChain()
-- time chain: ctx.modified is the craft duration in seconds, before skill/speed scaling.
-- ctx has base, modified, recipe, touches, ingredients, craftData.
timeModifierChain = makeModifierChain()
-- finalize chain: last-chance rewrite once every other chain has resolved.
-- ctx.base/ctx.modified are bundles { resultId, count, value, qualityMult, stats,
-- enchantment, customName, expBySkill, additionalProducts }; ctx.modified is a
-- deepcopy, mutate fields in place or reassign. ctx also has recipe, touches,
-- craftData, ingredients, consumedIngredients, consumedVirtuals, toolsUsed,
-- shiftPressed, stationSnapshots, duration, resultType. never fires during preview.
finalizeCraftModifierChain = makeModifierChain()

-- ========================= TOUCHES =========================
-- player-toggleable craft modifier (e.g. Artisan's touch); effects ride the modifier chains, registry owns toggle/gate/ctx threading.

-- ingredients chain: ctx is shared mutable; mutate via ingredientsMutable (never ctx.base); return ignored.
-- ctx has base (live recipe.ingredients, read-only), modified (nil until materialized), recipe, touches.
ingredientsModifierChain = makeModifierChain()

-- ========================= WINDOW BUILDER CHAIN =========================
-- runs once when ui_craftingWindow is built, after all built-in elements
-- exist and before the first refresh. each entry func(ctx) gets the live
-- layout tables and ui.create roots and may mutate anything; the changes
-- ride the same first-frame render so no :update() is needed.
-- ctx is the global WINDOW table. fields include: craftingWindow (alias
-- `window`), mainFlex, topBar, topBarButtonFlex, contentFlex, leftColumnWrapper,
-- rightPanel, craftingButtonFlex, searchRow, leftBox, infoScroller, infoContent
-- (and many other built-in elements; see ui_craftingWindow.lua).
windowBuilders = {}
local windowBuilderSeq = 0
function registerWindowBuilder(opts)
	if opts.id then
		for i, entry in ipairs(windowBuilders) do
			if entry.id == opts.id then table.remove(windowBuilders, i); break end
		end
	end
	windowBuilderSeq = windowBuilderSeq + 1
	table.insert(windowBuilders, {
		id = opts.id,
		priority = opts.priority or 0,
		seq = windowBuilderSeq,
		func = opts.func,
	})
	table.sort(windowBuilders, function(a, b)
		if a.priority ~= b.priority then return a.priority < b.priority end
		return a.seq < b.seq
	end)
end
function unregisterWindowBuilder(key)
	for i, entry in ipairs(windowBuilders) do
		if entry.id == key or entry.func == key then table.remove(windowBuilders, i); return end
	end
end

touchList = {}
local touchById = {}
local touchSeq = 0
activeTouches = {}

-- registerTouch{ id, label, gate(recipe)->bool, priority }
-- re-register by id replaces the prior touch (mirrors the modifier chains).
-- sort: priority asc, seq asc; drives touchList order.
-- craft-time scaling now rides the time modifier chain; a touch's modifier
-- self-gates on ctx.touches just like the other effect chains.
function registerTouch(opts)
	if touchById[opts.id] then
		for i, touch in ipairs(touchList) do
			if touch.id == opts.id then
				table.remove(touchList, i)
				break
			end
		end
	end
	touchSeq = touchSeq + 1
	local touch = {
		id = opts.id,
		label = opts.label or opts.id,
		gate = opts.gate,
		priority = opts.priority or 0,
		seq = touchSeq,
	}
	touchById[opts.id] = touch
	table.insert(touchList, touch)
	table.sort(touchList, function(a, b)
		if a.priority ~= b.priority then return a.priority < b.priority end
		return a.seq < b.seq
	end)
	return true
end
API.registerTouch = registerTouch -- api-only

-- subscribe to touch toggle notifications. fires sync on each state change
-- with { id, active }. listeners persist for the session (recipe files load once).
touchListeners = {}
function onTouchToggled(fn)
	table.insert(touchListeners, fn)
end
API.onTouchToggled = onTouchToggled -- api-only

-- toggle a touch's active state; state nil = flip, true/false = set explicitly.
-- listeners fire synchronously after the state changes. window auto-refreshes
-- so the recipe list and info panel reflect the new gate immediately.
function toggleTouch(id, state)
	if not touchById[id] then return end
	if state == nil then state = not activeTouches[id] end
	state = state == true
	if (activeTouches[id] == true) == state then return end
	activeTouches[id] = state or nil
	for _, fn in ipairs(touchListeners) do
		fn({ id = id, active = state })
	end
	if WINDOW.craftingWindow then
		if filterRecipes then updateRecipeAvailability(true) end
		refreshRecipeList()
		updateinfoContent()
		WINDOW.craftingWindow:update()
	end
end
API.toggleTouch = toggleTouch -- api-only

-- nil when nothing is active, else { [id]=true }; gate decides per recipe.
-- snapshotted into the queue so a mid-queue toggle never alters a queued craft.
function getActiveTouches(recipe)
	local active
	for _, touch in ipairs(touchList) do
		if activeTouches[touch.id] and (not touch.gate or touch.gate(recipe)) then
			active = active or {}
			active[touch.id] = true
		end
	end
	return active
end

-- ingredients-chain mutation: copy-on-first-write off the live recipe table.
-- nil-until-mutate makes a careless mutate of ctx.base fail loudly in testing.
function ingredientsMutable(ctx)
	if not ctx.modified then ctx.modified = deepcopy(ctx.base) end
	return ctx.modified
end

-- ========================= TOOLTIP CHAINS =========================
-- register{id, priority, func=fn(recipe, ctx)}; fires per tooltip, recipe nil for station/external callers.
-- ctx has record, item, info, customName, qualityMult, count, enchantId, enchantment (raw chain output), stats (rendered overrides).
-- line chain: return string to append, nil skips. modifier chain: ctx adds root, flex, textElement, statTextElement; return false halts.
local function makeTooltipChain()
	local list = {}
	local seq = 0
	local chain = { entries = list }
	function chain.register(opts)
		if opts.id then
			for i, entry in ipairs(list) do
				if entry.id == opts.id then table.remove(list, i); break end
			end
		end
		seq = seq + 1
		table.insert(list, {
			id = opts.id,
			priority = opts.priority or 0,
			seq = seq,
			func = opts.func,
		})
		table.sort(list, function(a, b)
			if a.priority ~= b.priority then return a.priority < b.priority end
			return a.seq < b.seq
		end)
	end
	function chain.unregister(key)
		for i, entry in ipairs(list) do
			if entry.id == key or entry.func == key then table.remove(list, i); return end
		end
	end
	return chain
end

tooltipLineChain = makeTooltipChain()
tooltipModifierChain = makeTooltipChain()

registerQualityModifier = qualityModifierChain.register
unregisterQualityModifier = qualityModifierChain.unregister
registerExpModifier = expModifierChain.register
unregisterExpModifier = expModifierChain.unregister
registerStatsModifier = statsModifierChain.register
unregisterStatsModifier = statsModifierChain.unregister
registerValueModifier = valueModifierChain.register
unregisterValueModifier = valueModifierChain.unregister
registerRecipeNameModifier = recipeNameModifierChain.register
unregisterRecipeNameModifier = recipeNameModifierChain.unregister
registerResultItemModifier = resultItemModifierChain.register
unregisterResultItemModifier = resultItemModifierChain.unregister
registerResultCountModifier = resultCountModifierChain.register
unregisterResultCountModifier = resultCountModifierChain.unregister
registerEnchantmentModifier = enchantmentModifierChain.register
unregisterEnchantmentModifier = enchantmentModifierChain.unregister
registerIngredientsModifier = ingredientsModifierChain.register
unregisterIngredientsModifier = ingredientsModifierChain.unregister
registerTimeModifier = timeModifierChain.register
unregisterTimeModifier = timeModifierChain.unregister
registerFinalizeCraftModifier = finalizeCraftModifierChain.register
unregisterFinalizeCraftModifier = finalizeCraftModifierChain.unregister
registerTooltipLine = tooltipLineChain.register
unregisterTooltipLine = tooltipLineChain.unregister
registerTooltipModifier = tooltipModifierChain.register
unregisterTooltipModifier = tooltipModifierChain.unregister

API.registerQualityModifier = registerQualityModifier
API.unregisterQualityModifier = unregisterQualityModifier
API.registerExpModifier = registerExpModifier
API.unregisterExpModifier = unregisterExpModifier
API.registerStatsModifier = registerStatsModifier
API.unregisterStatsModifier = unregisterStatsModifier
API.registerValueModifier = registerValueModifier
API.unregisterValueModifier = unregisterValueModifier
API.registerRecipeNameModifier = registerRecipeNameModifier
API.unregisterRecipeNameModifier = unregisterRecipeNameModifier
API.registerResultItemModifier = registerResultItemModifier
API.unregisterResultItemModifier = unregisterResultItemModifier
API.registerResultCountModifier = registerResultCountModifier
API.unregisterResultCountModifier = unregisterResultCountModifier
API.registerEnchantmentModifier = registerEnchantmentModifier
API.unregisterEnchantmentModifier = unregisterEnchantmentModifier
API.registerIngredientsModifier = registerIngredientsModifier
API.unregisterIngredientsModifier = unregisterIngredientsModifier
API.registerTimeModifier = registerTimeModifier
API.unregisterTimeModifier = unregisterTimeModifier
API.registerFinalizeCraftModifier = registerFinalizeCraftModifier
API.unregisterFinalizeCraftModifier = unregisterFinalizeCraftModifier
API.registerTooltipLine = registerTooltipLine
API.unregisterTooltipLine = unregisterTooltipLine
API.registerTooltipModifier = registerTooltipModifier
API.unregisterTooltipModifier = unregisterTooltipModifier
API.registerWindowBuilder = registerWindowBuilder
API.unregisterWindowBuilder = unregisterWindowBuilder

-- registerXpModifier renamed to registerExpModifier; the known friend ids are
-- already provided above so their old call is an inert no-op, anyone else must migrate
local expModifierFriends = {
--	["jc_xp"] = {
--		id = "jc_xp",
--		priority = -10,  -- run before artisans
--		func = function(recipe, ctx)
--			if recipe.level >= 45 then
--				for skillId, info in pairs(ctx.skills) do
--					local d = (info.diffMod + 2) / 3
--					ctx.modified[skillId] = ctx.modified[skillId] * (d / info.diffMod)
--					print("JC: diffmod "..info.diffMod.." -> "..((info.diffMod + 2) / 3))
--					info.diffMod = (info.diffMod + 2) / 3
--				end
--			end
--			local bonus = 0
--			for a in pairs(ctx.ingredients) do
--				if not ({
--					["ingred_adamantium_ore_01"] = true,
--					["ingred_bonemeal_01"] = true,
--					["t_ingmine_coal_01"] = true,
--					["ingred_daedras_heart_01"] = true,
--					["ingred_scrap_metal_01"] = true,
--					["ingred_raw_ebony_01"] = true,
--					["ingred_fire_petal_01"] = true,
--					["t_ingmine_oregold_01"] = true,
--					["t_ingmine_oreiron_01"] = true,
--					["misc_soulgem_lesser"] = true,
--					["ingred_racer_plumes_01"] = true,
--					["ingred_raw_glass_01"] = true,
--					["t_ingmine_oresilver_01"] = true,
--				})[a.recordId] then
--					bonus = bonus + 2.5
--				end
--			end
--			if bonus ~= 0 then
--				for skillId in pairs(ctx.skills) do
--					ctx.modified[skillId] = ctx.modified[skillId] + bonus
--				end
--			end
--		end,
--	},
}
function registerXpModifier(opts)
	local id = opts and opts.id or false
	if not expModifierFriends[id] then
		print("\27[91m registerXpModifier overhauled, please check how registerExpModifier works. ignoring: " .. tostring(opts and opts.id) .. ")")
	else
		registerExpModifier(expModifierFriends[id])
	end
end
API.registerXpModifier = registerXpModifier

API.getItemQuality = function(item)
	local recordId = type(item) == "string" and item or item.recordId
    return saveData.craftedQuality[recordId]
end


-- compute the stats overrides table for a recipe.
-- opts: {record, recordId, recordType, qualityMult, touches, isPreview, snapshotIngredients, craftData}
function computeCraftedStats(recipe, opts)
	local recordType = opts.recordType or recipe.type
	local recordId = opts.recordId or recipe.id
	local record = opts.record or (types[recordType] and types[recordType].records[recordId])
	if not record then return {} end
	-- vanilla baseline: scale stats by qualityMult per record type
	local q = opts.qualityMult or 1
	local stats = {}
	if recordType == "Armor" then
		stats.baseArmor = math.floor(record.baseArmor * q + 0.5)
	elseif recordType == "Weapon" then
		local maxDamage = math.max(record.thrustMaxDamage, record.slashMaxDamage, record.chopMaxDamage)
		stats.thrustMaxDamage = math.floor(math.max(record.thrustMaxDamage, maxDamage * 0.8) * q + 0.5)
		stats.slashMaxDamage = math.floor(math.max(record.slashMaxDamage, maxDamage * 0.8) * q + 0.5)
		stats.chopMaxDamage = math.floor(math.max(record.chopMaxDamage, maxDamage * 0.8) * q + 0.5)
		-- clamp min to scaled max
		stats.thrustMinDamage = math.min(record.thrustMinDamage, stats.thrustMaxDamage)
		stats.slashMinDamage = math.min(record.slashMinDamage, stats.slashMaxDamage)
		stats.chopMinDamage = math.min(record.chopMinDamage, stats.chopMaxDamage)
	elseif recordType == "Clothing" then
		stats.enchantCapacity = math.floor(record.enchantCapacity * q + 0.5)
	end
	local base = {}
	for k, v in pairs(stats) do base[k] = v end
	local ctx = {
		base = base,
		modified = stats,
		record = record,
		recordType = recordType,
		qualityMult = opts.qualityMult,
		touches = opts.touches,
		isPreview = opts.isPreview,
		ingredients = resolveIngredients(recipe, opts.touches, opts.snapshotIngredients),
		craftData = opts.craftData or {},
	}
	-- recipe-tied modifier: run the named one first.
	-- false from it halts; otherwise the chain runs (skipping this one).
	if recipe.statsFunc then
		local entry = statsModifierChain.byId(recipe.statsFunc)
		if entry and entry.func(recipe, ctx) == false then
			return ctx.modified
		end
	end
	return statsModifierChain.apply(recipe, ctx, recipe.statsFunc)
end

-- compute the enchantment def for a recipe; nil leaves the template untouched.
-- ctx.modified takes a core.magic.enchantments.createRecordDraft input table.
-- opts: {record, recordId, recordType, qualityMult, touches, isPreview, snapshotIngredients, craftData}
function computeCraftedEnchantment(recipe, opts)
	local recordType = opts.recordType or recipe.type
	local recordId = opts.recordId or recipe.id
	local record = opts.record or (types[recordType] and types[recordType].records[recordId])
	if not record then return nil end
	local ctx = {
		base = nil,
		modified = nil,
		record = record,
		recordType = recordType,
		qualityMult = opts.qualityMult,
		touches = opts.touches,
		isPreview = opts.isPreview,
		ingredients = resolveIngredients(recipe, opts.touches, opts.snapshotIngredients),
		craftData = opts.craftData or {},
	}
	-- recipe-tied modifier runs first; false halts, otherwise chain runs.
	if recipe.enchantmentFunc then
		local entry = enchantmentModifierChain.byId(recipe.enchantmentFunc)
		if entry and entry.func(recipe, ctx) == false then
			return ctx.modified
		end
	end
	return enchantmentModifierChain.apply(recipe, ctx, recipe.enchantmentFunc)
end

-- run the finalize-craft chain once every other resolve has completed.
-- opts: {
--   touches, craftData, ingredients,
--   consumedIngredients, consumedVirtuals,
--   toolsUsed, shiftPressed, stationSnapshots, duration, resultType,
--   bundle = { resultId, count, value, qualityMult, stats, enchantment,
--              customName, expBySkill, additionalProducts },
-- }
-- returns the (possibly mutated) bundle. caller re-validates resultId.
function computeFinalizeCraft(recipe, opts)
	local base = opts.bundle
	local modified = deepcopy(base)
	local ctx = {
		base = base,
		modified = modified,
		recipe = recipe,
		touches = opts.touches,
		craftData = opts.craftData or {},
		ingredients = opts.ingredients,
		consumedIngredients = opts.consumedIngredients,
		consumedVirtuals = opts.consumedVirtuals,
		toolsUsed = opts.toolsUsed,
		shiftPressed = opts.shiftPressed,
		stationSnapshots = opts.stationSnapshots,
		duration = opts.duration,
		resultType = opts.resultType,
	}
	-- recipe-tied modifier runs first; false halts, otherwise chain runs.
	if recipe.finalizeCraftFunc then
		local entry = finalizeCraftModifierChain.byId(recipe.finalizeCraftFunc)
		if entry and entry.func(recipe, ctx) == false then
			return ctx.modified
		end
	end
	return finalizeCraftModifierChain.apply(recipe, ctx, recipe.finalizeCraftFunc)
end

-- ========================= PROFESSION SKILLS =========================
-- maps name -> skillId for progression. hidden professions are listed only
-- when invoked via openCraftingWindow(name); solo also hides others.

professionSkills = {}
professionHidden = {}
professionSolo = {}
professionPriority = {}
local professionVersions = {}

-- runtime state, cleared on window close
unlockedHidden = {}
soloProfession = nil

-- registerProfession{ name="Smithing", skillId="armorer", version=1, hidden=true, solo=true, priority=0 }
-- omitted fields keep their stored value so partial re-registers (e.g. CF_core
-- auto-register passing only name+skillId) do not clobber the rest
function registerProfession(opts)
	local name = opts.name
	local version = opts.version or 0
	local existing = professionVersions[name] or -1
	if version >= existing then
		if opts.skillId  ~= nil then professionSkills[name]   = opts.skillId  end
		if opts.hidden   ~= nil then professionHidden[name]   = opts.hidden   end
		if opts.solo     ~= nil then professionSolo[name]     = opts.solo     end
		if opts.priority ~= nil then professionPriority[name] = opts.priority end
		-- lower sorts first, matching modifier-chain priority
		professionPriority[name] = professionPriority[name] or 0
		professionVersions[name] = version
		return true
	end
	return false
end
API.registerProfession = registerProfession -- bare-used internally (CF_core auto-register)

-- framework default profession; leads the dropdown unless a pack overrides
registerProfession{ name = "Crafting", priority = -100 }

function getProfessionSkill(name)
	return professionSkills[name] or "armorer"
end

-- profession display order: priority ascending, then case-insensitive name
function compareProfessions(a, b)
	local pa = professionPriority[a] or 0
	local pb = professionPriority[b] or 0
	if pa ~= pb then return pa < pb end
	return a:lower() < b:lower()
end

-- module imports

require("scripts.CraftingFramework.ui_craftingWindowHelpers")
searchEngine = require("scripts.CraftingFramework.ui_searchEngine_1")
makeBorder = require("scripts.CraftingFramework.ui_makeborder")
craftItem = require("scripts.CraftingFramework.craftItem")
expText = require("scripts.CraftingFramework.expText")
makeDescriptionTooltip = require("scripts.CraftingFramework.ui_descriptionTooltip")
makeMouseTooltip = require("scripts.CraftingFramework.ui_mouseTooltip")
makeVirtualTooltip = require("scripts.CraftingFramework.ui_virtualTooltip")

-- def.formatCount(n) or n.." "..def.unit
function formatVirtualCount(def, n)
	if def and def.formatCount then return def.formatCount(n) end
	if def and def.unit then return tostring(n) .. " " .. def.unit end
	return tostring(n)
end

-- value or function(available, required) (optional)
function virtualName(def, available, required)
	if not def then return nil end
	if type(def.name) == "function" then return def.name(available, required) end
	return def.name
end

function virtualIcon(def, available, required)
	if not def then return nil end
	if type(def.icon) == "function" then return def.icon(available, required) end
	return def.icon
end

-- count-overlay label; nil falls back to default formatting
function virtualLabel(def, available, required)
	if not def or def.label == nil then return nil end
	if type(def.label) == "function" then return def.label(available, required) end
	return def.label
end

-- tooltip flavor text; nil hides the line
function virtualDescription(def, available, required)
	if not def or def.description == nil then return nil end
	if type(def.description) == "function" then return def.description(available, required) end
	return def.description
end


function onKeyPress(key)
	if not WINDOW.craftingWindow then return end
	local direction
	local keyCode = key.code
	if keyCode == input.KEY.DownArrow or keyCode == input.KEY.S then
		direction = 1
	elseif keyCode == input.KEY.UpArrow or keyCode == input.KEY.W then
		direction = -1
	end
	if direction then
		moveSelection(direction, true)
		moveSelectionDirection = direction
		lastSelectionMove = core.getRealTime() + 0.23
	end
	if keyCode == input.KEY.PageDown then
		scrollCraftingWindow(-math.floor(S_MAX_RECIPES / 2))
	elseif keyCode == input.KEY.PageUp then
		scrollCraftingWindow(math.floor(S_MAX_RECIPES / 2))
	end
end

function onKeyRelease(key)
	if not WINDOW.craftingWindow then return end

	moveSelectionDirection = nil
end

function handleUiModeChanged(data)
	if data.newMode == "Repair" then
		if input.isShiftPressed() then
			openCraftingWindow()
		else
			require("scripts.CraftingFramework.ui_repairButton")
		end
	elseif data.oldMode == "Repair" and repairButton then
		repairButton:destroy()
		repairButton = nil
		if craftingButtonDragHandle then
			craftingButtonDragHandle:destroy()
			craftingButtonDragHandle = nil
		end
	end
	
	if data.newMode == nil and WINDOW.craftingWindow then
		if rightClickHook then
			I.UI.setMode('Interface', { windows = S_HIDE_VANILLA_WINDOWS and {} or { 'Map', 'Stats', 'Magic', 'Inventory' } })
			rightClickHook()
		else
			destroyCraftingWindow()
		end
	end
end

function handleNotifyItem(data)
	local item = data[1]
	local count = data[2]
	local recipeId = data[3]
	local shiftPressed = data[4]
	local playPickupSound = data[5]
	local qualityMult = data[6]
	local craftData = data[7]

	if not item or count <= 0 then
		ui.showMessage("Crafting failed!")
		ambient.playSound("enchant fail", { volume = 0.9 })
		inventoryChanged = true
		return
	end

	-- remember quality so tooltips can show it later
	if qualityMult and qualityMult ~= 1 then
		saveData.craftedQuality[item.recordId] = qualityMult
	end
	
	ui.showMessage("Crafted " .. count .. " " .. item.type.record(item).name .. (count and count > 1 and "s" or ""))
	if playPickupSound then
		ambient.playSound("item bodypart up", { volume = 0.9 })
	end

	if shiftPressed and getEquipmentSlot(item) then
		if item.count == 0 then
			for _, i in pairs(types.Actor.inventory(self):getAll(item.type)) do
				if i.recordId == item.recordId and types.Item.itemData(i).condition == item.type.record(item).health then
					item = i
				end
			end
		end
		if item.count > 0 then
			local eq = types.Actor.getEquipment(self)
			eq[getEquipmentSlot(item)] = item
			types.Actor.setEquipment(self, eq)
			if I.UI.getMode() == 'Interface' then
				I.UI.setMode()
				I.UI.setMode('Interface')
			end
		end
	end
	inventoryChanged = true
end

function handleRemovedItem(data)
	local itemId = data[1]
	local count = data[2]
	inventoryChanged = true
end

function onFrame(dt)
	for _, f in pairs(onFrameFunctions) do
		f(dt)
	end

	if moveSelectionDirection and core.getRealTime() > lastSelectionMove then
		lastSelectionMove = core.getRealTime() + 0.015
		moveSelection(moveSelectionDirection)
	end

	if WINDOW.craftingWindow and (inventoryChanged or types.Actor.getEncumbrance(self) ~= lastEncumbrance) then
		lastEncumbrance = types.Actor.getEncumbrance(self)
		invalidateInventoryCache()
		updateRecipeAvailability(filterRecipes)
		refreshRecipesAndWindow()
	end
	inventoryChanged = false
end

onFrameFunctions["init"] = function()
	onFrameFunctions["init"] = nil
	professions = require("scripts.CraftingFramework.parseRecipes")
	currentProfessionName = "Crafting"
end

-- one-shot: on chargen finish transition, seed crafting_skill base from armorer
onFrameFunctions["chargenCraftingSkill"] = function()
	if saveData.finishedChargen then
		onFrameFunctions["chargenCraftingSkill"] = nil
	elseif types.Player.isCharGenFinished(self) then
		saveData.finishedChargen = true
		local stat = I.SkillFramework and I.SkillFramework.getSkillStat("crafting_skill")
		if stat then
			local armorerBase = types.NPC.stats.skills.armorer(self).base
			stat.base = armorerBase
			-- seed the snapshot too so the roguelite nerf mirror has a baseline
			saveData.armorerSnapshot = armorerBase
			saveData.craftingSeeded = true
		end
		onFrameFunctions["chargenCraftingSkill"] = nil
	end
end

-- ------------------------------ ROGUELITE NERF MIRROR ------------------------------
-- roguelite nerfs every skill base on first chargen via direct writes. we mirror
-- that delta onto crafting_skill once, when its blessing event reaches us.

local snapshotCellId

-- snapshot armorer base on cell change until nerf consumed; gate on roguelite present
onFrameFunctions["snapshotArmorer"] = function()
	if saveData.nerfApplied then
		onFrameFunctions["snapshotArmorer"] = nil
		return
	end
	if not I.Roguelite or not self.cell then return end
	local cellId = self.cell.id
	if cellId == snapshotCellId then return end
	-- skip the first cell sighting after load so a save-then-load between nerf
	-- and event doesn't overwrite the persisted pre-nerf snapshot
	if snapshotCellId and saveData.craftingSeeded then
		saveData.armorerSnapshot = types.NPC.stats.skills.armorer(self).base
	end
	snapshotCellId = cellId
end

-- routed from CF_g on Roguelite_setPlayerBlessings
local function applyRogueliteNerf()
	if saveData.nerfApplied then return end
	saveData.nerfApplied = true
	onFrameFunctions["snapshotArmorer"] = nil
	-- mid-playthrough install: seeder never ran, no baseline to diff against
	if not saveData.craftingSeeded or not saveData.armorerSnapshot then return end
	local current = types.NPC.stats.skills.armorer(self).base
	local delta = saveData.armorerSnapshot - current
	if delta <= 0 then return end
	local stat = I.SkillFramework and I.SkillFramework.getSkillStat("crafting_skill")
	if stat then
		stat.base = math.max(0, stat.base - delta)
	end
end

-- -------------------------------------------------- inventory extender button --------------------------------------------------

-- hammer icon in inventory extender's info bar; click opens crafting window.
-- pattern lifted from Disenchanting, minus drag-to-target and instant-mode.
onFrameFunctions["ie_button"] = function()
	if not I.InventoryExtender or not I.InventoryExtender.getWindow then
		return
	end
	local invWin = I.InventoryExtender.getWindow('Inventory')
	if not invWin or not invWin.infoBar or not invWin.ctx then return end
	-- got the bar, tear down this onFrame entry
	onFrameFunctions["ie_button"] = nil
	
	local ctx = invWin.ctx
	local btnSize = 28
	
	-- glow texture for hover
	local enchantFrame = ui.texture {
		path = "textures/menu_icon_equip.dds",
		size = v2(40, 40),
		offset = v2(2, 2),
	}
	
	-- hammer icon
	local icon = {
		type = ui.TYPE.Image,
		props = {
			resource = getTexture("icons/m/misc_hammer10.dds"),
			relativeSize = v2(0.91, 0.91),
			anchor = v2(0.5,0.5),
			relativePosition = v2(0.53,0.5),
			alpha = 1,
		},
	}
	
	-- glow background
	local magicBg = {
		name = "magicBg",
		type = ui.TYPE.Image,
		props = {
			resource = enchantFrame,
			relativeSize = v2(1, 1),
			alpha = 0,
		},
	}
	
	-- button container
	local btn = {
		props = { size = v2(btnSize, btnSize) },
		content = ui.content {
			magicBg,
			icon,
		},
		events = {
			focusGain = async:callback(function()
				magicBg.props.alpha = 0.7
				ctx.updateQueue[invWin.infoBar] = true
			end),
			focusLoss = async:callback(function()
				magicBg.props.alpha = 0
				ctx.updateQueue[invWin.infoBar] = true
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
				openCraftingWindow()
			end),
		},
	}
	
	invWin.infoBar.layout.userData.addInfoLayout(btn)
end

-- adds a quality row to IE tooltips for items crafted with a multiplier
function registerInventoryExtenderTooltip()
	if not I.InventoryExtender or not I.InventoryExtender.registerTooltipModifier then return end
	local IE_BASE = I.InventoryExtender.Templates and I.InventoryExtender.Templates.BASE
	I.InventoryExtender.registerTooltipModifier("CraftingFramework", function(item, layout)
		local qualityMult = saveData.craftedQuality and saveData.craftedQuality[item.recordId]
		if not qualityMult or qualityMult == 1 then return layout end
		local ok, inner = pcall(function() return layout.content.padding.content.tooltip.content end)
		if not ok or not inner then return layout end
		local percent = math.floor(qualityMult * 100 + 0.5)
		local entry = {
			name = "craftQuality",
			template = (IE_BASE and IE_BASE.textNormal) or I.MWUI.templates.textNormal,
			props = {
				text = core.getGMST("sQuality") .. ": " .. percent .. "%",
				textColor = qualityMult < 1 and util.color.rgb(1, 0.4, 0.4) or nil,
			},
		}
		-- slot above condition bar; fall back to bottom
		local pos = inner.indexOf and inner:indexOf("condition")
		if pos then
			inner:insert(pos-1, entry)
			if IE_BASE and IE_BASE.intervalV then
				inner:insert(pos, IE_BASE.intervalV(4))
			end
		else
			if IE_BASE and IE_BASE.intervalV then
				inner:add(IE_BASE.intervalV(4))
			end
			inner:add(entry)
		end
		return layout
	end)
end
table.insert(onActiveFunctions, 1, registerInventoryExtenderTooltip)

function onSave()
	return saveData
end

function onLoad(data)
	saveData = data or {}
	saveData.enabledRecipes = saveData.enabledRecipes or {}
	saveData.discoveredRecipes = saveData.discoveredRecipes or {}
	saveData.craftedQuality = saveData.craftedQuality or {}
	saveData.stats = saveData.stats or {
		version = 1,
		perSkillExp = {},
		perRecipe = {},
		perIngredient = {},
		quality = {},
		totalValue = 0,
		totalTime = 0,
	}
	saveData.stats.touches = saveData.stats.touches or {}
	-- mid-playthrough installs land here with chargen already done
	if saveData.finishedChargen == nil then
		saveData.finishedChargen = types.Player.isCharGenFinished(self)
	end
end

-- enable/reset: toggles the disabled gate (greyed but visible).
-- discover/hide: toggles the hidden gate (recipe missing from list).
-- password must match recipe.disabled / recipe.hidden, or the gate stays closed.
function enableRecipe(recipeId, password)
	saveData.enabledRecipes[recipeId..":"..password] = 1
	skillChanged = true
end
API.enableRecipe = enableRecipe -- bare-used internally (event handler)

function resetRecipe(recipeId, password)
	saveData.enabledRecipes[recipeId..":"..password] = nil
	skillChanged = true
end
API.resetRecipe = resetRecipe -- bare-used internally (event handler)

function discoverRecipe(recipeId, password)
	saveData.discoveredRecipes[recipeId..":"..password] = 1
	skillChanged = true
end
API.discoverRecipe = discoverRecipe -- bare-used internally (event handler)

function forgetRecipe(recipeId, password)
	saveData.discoveredRecipes[recipeId..":"..password] = nil
	skillChanged = true
end
API.forgetRecipe = forgetRecipe -- bare-used internally (event handler)

-- subscribe to profession-change notifications. mirrors onTouchToggled /
-- onVirtualConsumed. listeners persist for the session and fire synchronously
-- when the active profession changes via either setProfession or
-- openCraftingWindow(name). also sends the CraftingFramework_professionChanged
-- player event with the same payload.
professionChangedListeners = {}
function onProfessionChanged(fn)
	table.insert(professionChangedListeners, fn)
end
API.onProfessionChanged = onProfessionChanged -- api-only

-- fires listeners + the player event when the active profession actually
-- changes. called AFTER the window is built / refreshed so listeners can
-- read or mutate WINDOW.* elements (hide buttons, swap labels, etc.).
local function fireProfessionChanged(previous, current)
	if previous == current then return end
	local payload = { profession = current, previous = previous }
	for _, fn in ipairs(professionChangedListeners) do
		fn(payload)
	end
	self:sendEvent("CraftingFramework_professionChanged", payload)
end

function setProfession(professionName)
	if professions[professionName] then
		local previous = currentProfessionName
		currentProfessionName = professionName
		currentSubcategory = nil
		currentIndex = nil
		selectedRecipe = nil
		invalidateInventoryCache()
		wildcardPreferences = {}
		skillChanged = true
		if WINDOW.craftingWindow then
			updateRecipeAvailability(filterRecipes)
			refreshRecipeList()
			updateinfoContent()
		end
		selectedRecipe = nil
		selectedHeader = nil
		hoveredBackground = nil
		pendingHoverKey = nil
		fireProfessionChanged(previous, professionName)
		return true
	end
	return false
end
API.setProfession = setProfession -- bare-used internally (ui_craftingWindow)

-- map of every profession -> visible bool, so callers see hidden ones too.
-- visible = not hidden (or unlocked); with a solo profession active only
-- that one is visible. unordered: callers that display must sort.
function getProfessionList()
	local list = {}
	-- solo: only the externally-invoked profession is offered
	local solo = soloProfession and professions[soloProfession] and soloProfession
	for name in pairs(professions) do
		if solo then
			list[name] = name == solo
		else
			list[name] = (not professionHidden[name] or unlockedHidden[name]) and true or false
		end
	end
	return list
end
API.getProfessionList = getProfessionList -- bare-used internally (ui_craftingWindow)

-- open crafting window (defaults to current profession). passing a name is
-- external invocation: unlocks hidden, narrows list if solo.
function openCraftingWindow(professionName)
	validateRecipeSkills(professions)
	local previous = currentProfessionName
	if professionName and professions[professionName] then
		currentProfessionName = professionName
		currentSubcategory = nil
		currentIndex = nil
		selectedRecipe = nil
		if professionHidden[professionName] then
			unlockedHidden[professionName] = true
		end
		if professionSolo[professionName] then
			soloProfession = professionName
		end
	end
	-- wildcard picks do not survive a window close
	wildcardPreferences = {}
	invalidateInventoryCache()
	skillChanged = true
	updateRecipeAvailability(filterRecipes)
	require("scripts.CraftingFramework.ui_craftingWindow")
	-- fire AFTER the window is built so listeners can mutate WINDOW.* elements.
	fireProfessionChanged(previous, currentProfessionName)
	-- external invocation always hides vanilla windows
	local hide = professionName ~= nil or S_HIDE_VANILLA_WINDOWS
	-- ralt's replacers ignore the windows filter; hide directly
	if hide then
		if I.InventoryExtender then I.InventoryExtender.hide('Inventory', nil, true) end
		if I.MagicWindow then I.MagicWindow.hide(true) end
		if I.StatsWindow then I.StatsWindow.hide(true) end
	end
	I.UI.setMode('Interface', { windows = hide and {} or { 'Map', 'Stats', 'Magic', 'Inventory' } })
end
API.openCraftingWindow = openCraftingWindow -- bare-used internally (CF_p, ui_repairButton, event handler)

function onMouseWheel(vertical)
	if WINDOW.craftingWindow and vertical ~= 0 then
		if infoHasFocus then
			scrollInfoPanel(vertical)
		else
			scrollCraftingWindow(vertical, true)
		end
	end
end

-- dpad scrolling
function onControllerButtonPress(key)
	if not WINDOW.craftingWindow then return end
	if key == input.CONTROLLER_BUTTON.DPadDown or key == input.CONTROLLER_BUTTON.DPadUp then
		local direction = (key == input.CONTROLLER_BUTTON.DPadDown) and 1 or -1
		moveSelection(direction, true)
		moveSelectionDirection = direction
		lastSelectionMove = core.getRealTime() + 0.23
	end
end

-- dpad scrolling
function onControllerButtonRelease(key)
	if not WINDOW.craftingWindow then return end

	if key == input.CONTROLLER_BUTTON.DPadDown or key == input.CONTROLLER_BUTTON.DPadUp then
		moveSelectionDirection = nil
	end
end

I.SkillProgression.addSkillLevelUpHandler(function(skillId)
	skillChanged = true
end)

-- look up display name for a recordId across all item types
local function statsName(recordId)
	local recType = getItemType(recordId)
	if recType and types[recType] and types[recType].records[recordId] then
		return types[recType].records[recordId].name or recordId
	end
	return recordId
end

function printCraftStats()
	local stats = saveData and saveData.stats
	if not stats then
		ui.printToConsole("[CraftingFramework] No stats yet.", ui.CONSOLE_COLOR.Error)
		return
	end
	local function p(s) ui.printToConsole(s, ui.CONSOLE_COLOR.Info) end

	-- totals
	local totalCrafts = 0
	for _, c in pairs(stats.perRecipe) do totalCrafts = totalCrafts + c end
	p("== CraftingFramework stats ==")
	p(string.format("Total crafts: %d", totalCrafts))
	for touchLabel, count in pairs(stats.touches) do
		p(string.format("%s: %d", touchLabel, count))
	end
	p(string.format("Total time crafting: %.1f min", (stats.totalTime or 0) / 60))
	p(string.format("Total value crafted: %d gold", math.floor(stats.totalValue or 0)))

	-- exp per skill
	if next(stats.perSkillExp) then
		p("Exp gained per skill:")
		local rows = {}
		for skill, amount in pairs(stats.perSkillExp) do
			table.insert(rows, { skill, amount })
		end
		table.sort(rows, function(a, b) return a[2] > b[2] end)
		for _, r in ipairs(rows) do
			p(string.format("  %s: %.2f", r[1], r[2]))
		end
	end

	-- crafts per recipe with quality
	if next(stats.perRecipe) then
		p("Crafts per recipe (best / avg quality):")
		local rows = {}
		for rId, count in pairs(stats.perRecipe) do
			table.insert(rows, { rId, count })
		end
		table.sort(rows, function(a, b) return a[2] > b[2] end)
		for _, r in ipairs(rows) do
			local q = stats.quality[r[1]]
			local qStr = ""
			if q and q.n > 0 then
				qStr = string.format(" (best %d%%, avg %d%%)",
					math.floor(q.best * 100 + 0.5),
					math.floor((q.sum / q.n) * 100 + 0.5))
			end
			p(string.format("  %s: %d%s", statsName(r[1]), r[2], qStr))
		end
	end

	-- consumed ingredients
	if next(stats.perIngredient) then
		p("Ingredients consumed:")
		local rows = {}
		for rId, count in pairs(stats.perIngredient) do
			table.insert(rows, { rId, count })
		end
		table.sort(rows, function(a, b) return a[2] > b[2] end)
		for _, r in ipairs(rows) do
			p(string.format("  %s: %d", statsName(r[1]), r[2]))
		end
	end
end

function onConsoleCommand(mode, command, selectedObject)
	if command:match("^lua craftingframework stats") then
		printCraftStats()
		return
	end
	-- set crafting_skill base level
	local skillLvl = tonumber(command:match("^lua crafting%s+(%d+)%s*$"))
	if skillLvl then
		local stat = I.SkillFramework and I.SkillFramework.getSkillStat("crafting_skill")
		if stat then
			stat.base = skillLvl
			skillValueCache["crafting_skill"] = nil
			skillChanged = true
			ui.printToConsole("[CraftingFramework] Crafting skill set to " .. skillLvl, ui.CONSOLE_COLOR.Success)
		else
			ui.printToConsole("[CraftingFramework] Skill Framework not available", ui.CONSOLE_COLOR.Error)
		end
		return
	end
	local craftArg = command:match("^lua craft%s*(%d*)%s*$")
	if craftArg then
		local speedParam = tonumber(craftArg)
		if speedParam and speedParam > 0 then
			cheatMode = tonumber(speedParam)
		else
			cheatMode = (not cheatMode) and 3
		end
		if cheatMode then
			ui.printToConsole("[CraftingFramework] Cheatmode ON", ui.CONSOLE_COLOR.Success)
			print("[CraftingFramework] Cheatmode ON")
			core.sendGlobalEvent('CraftingFramework_getItem', { player = self, recordType = "Repair", recordId = "hammer_repair", customName = "Cheat Hammer", count = 1 })
			openCraftingWindow()
		else
			ui.printToConsole("[CraftingFramework] Cheatmode OFF", ui.CONSOLE_COLOR.Success)
			print("[CraftingFramework] Cheatmode OFF")
		end
	end
end

local function onActive()
	if I.SkillFramework then
		I.SkillFramework.addSkillLevelUpHandler(function(skillId)
			skillChanged = true
		end)
	
		-- custom crafting skill, governed by armorer's class bucket.
		-- registered on activation so it exists before parseRecipes runs on first frame
		local classFactor
		I.SkillFramework.registerSkill("crafting_skill", {
			name           = "Crafting",
			description    = "Governing Skill: Armorer",
			icon           = {
				fgr      = "icons/CraftingFramework/skill_icon.png",
				fgrColor = util.color.rgb(0, 0, 0),
			},
			attribute      = "endurance",
			specialization = I.SkillFramework.SPECIALIZATION.Combat,
			skillGain      = { [1] = 1.0 },
			startLevel     = 5,
			maxLevel       = 200,
			xpCurve = function(level)
				if not classFactor then
					local class = types.NPC.classes.record(types.NPC.record(self).class)
					local gmst = "fMiscSkillBonus"
					for _, s in ipairs(class.majorSkills) do
						if s == "armorer" then gmst = "fMajorSkillBonus" break end
					end
					if gmst == "fMiscSkillBonus" then
						for _, s in ipairs(class.minorSkills) do
							if s == "armorer" then gmst = "fMinorSkillBonus" break end
						end
					end
					classFactor = core.getGMST(gmst)
				end
				return (level + 1) * classFactor
			end,
			statsWindowProps = {
				visible    = true,
				subsection = I.SkillFramework.STATS_WINDOW_SUBSECTIONS.Crafts,
			},
		})
	end
	for i, job in pairs(onActiveFunctions) do
		job()
	end
end

-- live-state accessors, api-only
API.getCraftingState = function() return craftingState end
API.getCraftingQueue = function() return craftingQueue end
API.getCraftingWindow = function() return WINDOW.craftingWindow end
API.getGlobals = function() return _G end

return {
	engineHandlers = {
		onFrame = onFrame,
		onMouseWheel = onMouseWheel,
		onControllerButtonPress = onControllerButtonPress,
		onControllerButtonRelease = onControllerButtonRelease,
		onKeyPress = onKeyPress,
		onKeyRelease = onKeyRelease,
		onSave = onSave,
		onLoad = onLoad,
		onInit = onLoad,
		onActive = onActive,
		onConsoleCommand = onConsoleCommand,
	},
	eventHandlers = {
		UiModeChanged = handleUiModeChanged,
		CraftingFramework_notifyItem = handleNotifyItem,
		CraftingFramework_removedItem = handleRemovedItem, -- (data) {itemId, count}
		-- refresh ralt's inventory only while its window is actually visible
		CraftingFramework_refreshInventory = function()
			if not I.InventoryExtender or not I.InventoryExtender.getWindow then return end
			local win = I.InventoryExtender.getWindow('Inventory')
			if win and win:isVisible() and I.InventoryExtender.update then
				--I.InventoryExtender.update()
				win:updateData()
			end
		end,
		CraftingFramework_openCraftingWindow = openCraftingWindow, -- (profession[opt])
		CraftingFramework_destroyCraftingWindow = destroyCraftingWindow, -- ()
		-- (data) {id, percent[0..1], data[opt]} -> advance manual progress
		CraftingFramework_advanceManualCrafting = function(data)
			advanceManualCrafting(data.id, data.percent, data.data)
		end,
		-- gate toggles, password must match recipe.disabled / recipe.hidden
		CraftingFramework_enableRecipe   = function(data) enableRecipe(data.id, data.password)   end,
		CraftingFramework_resetRecipe    = function(data) resetRecipe(data.id, data.password)    end,
		CraftingFramework_discoverRecipe = function(data) discoverRecipe(data.id, data.password) end,
		CraftingFramework_hideRecipe     = function(data) forgetRecipe(data.id, data.password)   end,
		-- routed from CF_g, fires after roguelite's chargen blessings dialog
		CraftingFramework_rogueliteNerfSignal = applyRogueliteNerf,
	},
	interfaceName = "CraftingFramework",
	interface = API,
}