local MDIR = "Simple Progress Bars"

local i18n = require(MDIR .. ".lib.i18n").init(MDIR)
local mod = require(MDIR .. ".lib.mod").init(MDIR)
local log = require(MDIR .. ".lib.log").init(MDIR)

log.debug("Initialized with logging level " .. mod.config.logLevel)
log.info("Loaded version " .. mod.version)

local mcm = require(MDIR .. ".mcm")
local cache = require(MDIR .. ".lib.cache")

local barBlock = {}
local configCache = {}


local function createUIBlock(e)
	if not mod.config.enabled then
		return
	end
	if not e.newlyCreated then
		return
	end

	barBlock.parent = e.element
	barBlock.container = barBlock.parent:createBlock()
	
	barBlock.container.autoWidth = true
	barBlock.container.autoHeight = true
	barBlock.container.flowDirection = "top_to_bottom"
	barBlock.container.absolutePosAlignX = 0.5
	barBlock.container.absolutePosAlignY = 0.5

	log.info("Bars UI initialized")
end


function drawBarLabel (data)
	local text = i18n(data.name)
	local trim = (mod.config.testLabelLength or 75) / 10
	local length = math.floor(mod.config.width / trim)
	if (string.len(text) > length) then
		return string.sub(text, 1, length - 1) .. "..."
	else
		return text
	end
end

local function drawBarGraphic (data)
	local completed = math.min(data.cur / data.max, 1)
	local labelText = drawBarLabel(data)

	local item = barBlock.container:createBlock()
	local item1st = item:createBlock()
	local item2nd = item:createBlock()
	local label = item1st:createLabel{text = labelText}
	local bar = item2nd:createRect()
	local icon = item2nd:createImage{path = data.icon}
	local timer = item2nd:createLabel{text = data.timer or ""}
	local fill = bar:createFillBar()

	item1st.height = 0
	item1st.autoWidth = true

	item2nd.height = mod.barheight + 2
	item2nd.autoWidth = true

	item.height = mod.barheight + mod.config.padding + 2
	item.autoWidth = true
	item.flowDirection = "top_to_bottom"
	item.paddingBottom = mod.config.padding
	item.paddingTop = 0
	item.borderAllSides = 0

	if (mod.config.layout ~= "COMPACT" and mod.config.layout ~= "MIN") then
		item.height = item.height + 15
		item1st.height = 15
	end

	if (data.item) or (data.skill) then
		item:register("help", function (e)
			tes3ui.createTooltipMenu{
				item = data.item,
				itemData = data.itemData,
				skill = data.skill,
			}
		end)
	elseif (data.text) or (data.title) or (data.note) then
		item:register("help", function (e)
			local tooltip = tes3ui.createTooltipMenu()
			local layout = tooltip:createBlock()
			if (data.title) then
				local header = layout:createLabel{text = i18n(data.title)}
				header.color = tes3ui.getPalette("header_color")
				header.borderBottom = 4
			end
			if (data.text) then
				local text = layout:createLabel{text = i18n(data.text)}
				text.wrapText = true
			end
			if (data.note) then
				local note = layout:createLabel{text = i18n(data.note)}
				note.color = tes3ui.getPalette("focus_color")
				note.wrapText = true
			end
			layout.flowDirection = "top_to_bottom"
			layout.autoHeight = true
			layout.width = 400
			layout.borderAllSides = 10
		end)
	end

	bar.height = mod.barheight
	bar.width = mod.config.width
	bar.borderAllSides = 2
	bar.flowDirection = "top_to_bottom"
	bar.alpha = 0.6
	bar.color = {0.0, 0.0, 0.0}
	bar.paddingAllSides = 0

	icon.height = mod.barheight
	icon.width = mod.barheight
	icon.scaleMode = true
	icon.borderTop = 2
	icon.borderAllSides = 0
	icon.paddingAllSides = 0

	if (mod.config.layout == "MIN" or mod.config.layout == "LABELED") then
		icon.height = 0
		icon.width = 0
	end

	if (not mod.config.showTime) then
		timer.text = ""
	end

	fill.width = mod.config.width
	fill.height = mod.barheight
	fill.widget.showText = true 
	fill.widget.max = data.max
	fill.widget.current = data.cur
	if (data.reverseColors) then
		fill.widget.fillColor = {0.2+0.8*completed, 1-0.8*completed, 0}
	else
		fill.widget.fillColor = {1-completed, 0.6*completed, 0}
	end
end

local function updateUIBlock ()
	barBlock.container.absolutePosAlignX = mod.config.xposition / 1000
	barBlock.container.absolutePosAlignY = mod.config.yposition / 1000
	barBlock.container:destroyChildren()

	local list = table.keys(mod.config.values)
	table.sort(list)

	for _,listName in pairs(list) do
		local val = mcm.values[listName] or {}
		local bar = cache.data[val.id]

		if (not bar and mod.config.logTicks) then
			log:info(" [".. cache.tick .."] No bar data at " .. val.id)
		end
		if not (mod.config.testExclusive and mod.config.testBarShow)
		   and (bar and bar.shown) then
			drawBarGraphic(bar)
		end
	end

	if (mod.config.testBarShow) then
		drawBarGraphic(cache.data["test"])
	end

	barBlock.container:getTopLevelMenu():updateLayout()
end

local function runUpdate ()
	if (not tes3ui.menuMode()) then
		cache.tick = cache.tick + 1
	end

	local updated = cache.update()

	for id,val in pairs(mod.config) do
		local isTable = type(val) == "table"
		if updated or (not tes3ui.menuMode()) then break end
		if (not isTable and configCache[id] ~= val) or
		   (isTable and #table.keys(val) ~= configCache[id]) then
			if (configCache[id] ~= nil) then
				log:debug("[".. cache.tick .."] Force redraw due to " .. id)
				updated = true
			end
			configCache[id] = val
			if isTable then configCache[id] = #table.keys(val) end
		end
	end

	if updated then
		if mod.config.logTicks then
			log:info(" [".. cache.tick .."] Redrawing bars")
		end
		updateUIBlock()
	end
end

local function updatingLoop ()
	if not mod.config.enabled then
		return
	end
	
	log.info("Launching update sequence")
	runUpdate()
	timer.start({
		duration = 1,
		iterations = -1,
		type = timer.real,
		callback = runUpdate
	})
end

mcm.dumpCache = function()
	local safeVals = {}
	for id,i in pairs(cache.data) do
		safeVals[id] = {}
		for k,v in pairs(i) do
			safeVals[id][k] = v
		end
		if i.itemData then safeVals[id].itemData = ":userdata" end
	end
	log:info("Dump cache: tick [" .. cache.tick .. "]")
	log:info("Cache: " .. json.encode(safeVals))
	log:info("Config: " .. json.encode(configCache))
	log:info("Timers: " .. json.encode(cache.timer))
end

event.register("modConfigReady", mcm.registerConfig)
event.register("uiActivated", createUIBlock, { filter = "MenuMulti" })
event.register("loaded", updatingLoop)
