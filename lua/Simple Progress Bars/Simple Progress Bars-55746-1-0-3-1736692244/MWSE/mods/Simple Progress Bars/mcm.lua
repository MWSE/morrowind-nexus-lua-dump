local MDIR = "Simple Progress Bars"

local mod = require(MDIR .. ".lib.mod")
local log = require(MDIR .. ".lib.log")
local i18n = require(MDIR .. ".lib.i18n")

local this = {}
local elem = {}


local function getListOptions (optionsID, sort)
	local options = {}
	local order = table.values(mod[optionsID])
	local keys = table.invert(mod[optionsID])
	if sort then
		table.sort(order)
	end
	for _,i in pairs(order) do
		local id, name = keys[i], i
		log.trace("Option " .. optionsID .. " " .. id .. ": " .. name)
		table.insert(options, {label = i18n(name), value = id})
	end
	return options
end

local function getListName (type, name)
	local prefix = i18n(mod.prefix[type])
	local text = i18n(name)
	return prefix .. ": " .. text
end

local function getListOption (id, type, item)
	local listName = getListName(type, item.name)
	this.values[listName] = {
		id = id,
		type = type,
		item = item
	}
end

local function getDisplayedList ()
	local list = {}
	this.values = {}

	for id,i in pairs(tes3.skill) do
		local skill = tes3.getSkill(i)
		if (skill) then
			getListOption(id, "skill", skill)
		end
	end
	for id,i in pairs(mod.armorSlots) do
		getListOption(id, "slot", i)
	end
	for id,i in pairs(mod.charStats) do
		getListOption(id, "stat", i)
	end
	
	list = table.keys(this.values)
	table.sort(list)
	return list
end


local function showHideTestBar (component)
	if (component) then
		if not elem.testBar then elem.testBar = {} end
		elem.testBar[component.label] = component
		log:debug("Component created " .. component.label)
	end
	if (not elem.testBar) then return end
	log.trace("Changing state [json]" .. json.encode(table.keys(elem.testBar)))
	for _,el in pairs(elem.testBar) do
		if not el.elements then return end
		if (mod.config.testBarShow) then
			el.elements.outerContainer.visible = true
		else
			el.elements.outerContainer.visible = false
		end
	end
end

local function showHideDebugPage (component)
	if (component) then
		local tabID = component.tabUID
		local tabsBlock = elem.template.elements.tabsBlock
		elem.debugPageTab = tabsBlock:findChild(tabID)
		log:debug("Component created " .. component.label)
	end
	log.trace("Changing state [json]" .. json.encode(elem.debugPageTab))
	if (mod.config.logLevel ~= "NONE" and mod.config.logLevel ~= "ERROR") then
		elem.debugPageTab.visible = true
	else
		elem.debugPageTab.visible = false
	end
end


local function registerMCMConfig()
	local template = mwse.mcm.createTemplate{
		name = mod.name,
		postCreate = function(component) 
			log:info("Template created")
			component.elements.outerContainer:registerAfter("destroy", function() log.info("Template destroyed") end)
		end
	}

	template:saveOnClose(mod.id, mod.config)
	template:register()
	elem.template = template

	local pageConfig = template:createSideBarPage{
		label = i18n("cfg.settings.label"),
		postCreate = function(component)
			component.sidebar.elements.innerContainer.paddingRight = 16
		end
	}

	local pageList = template:createExclusionsPage{
		label = i18n("cfg.selector.label"),
		description = i18n("cfg.selector.description"),
		leftListLabel = i18n("cfg.selector.left.label"),
		rightListLabel = i18n("cfg.selector.right.label"),
		filters = {{label = "Value list", callback = getDisplayedList}},
		variable = mwse.mcm.createTableVariable{
			id = "values",
			table = mod.config,
			converter = function(list)
				log:trace("Selected values " .. json.encode(table.keys(list)))
				local trunc = {}
				for id,enabled in pairs(list) do
					if enabled then
						trunc[id] = true
					end
				end
				return trunc
			end
		}
	}

	local pageDebug = template:createSideBarPage{
		label = i18n("cfg.debug.label"),
		postCreate = function(component)
			component.sidebar.elements.innerContainer.paddingRight = 16
		end
	}

	local catSystem = pageConfig:createCategory(i18n("cfg.settings.system.label"))
	local catAppearance = pageConfig:createCategory(i18n("cfg.settings.appearance.label"))
	local catPosition = pageConfig:createCategory(i18n("cfg.settings.position.label"))

	pageConfig.sidebar:createCategory{
		label = mod.name .. "\n" .. i18n("mod.auth.label") .. mod.author .. "\n" .. i18n("mod.vers.label") .. mod.version,
		postCreate = function(component)
			local divider = component.elements.outerContainer:createDivider()
			divider.borderAllSides = 0
			divider.borderTop = 10
			divider.borderBottom = 16
			showHideDebugPage(pageDebug)
		end
	}

	pageConfig.sidebar:createInfo(i18n("mod.info1"))
	pageConfig.sidebar:createInfo(i18n("mod.info2"))
	pageConfig.sidebar:createInfo(i18n("mod.info3"))


	catSystem:createOnOffButton({
		label = i18n("cfg.settings.enable.label"),
		description = i18n("cfg.settings.enable.description"),
		restartRequired = true,
		variable = mwse.mcm.createTableVariable({id = "enabled", table = mod.config})
	})

	catSystem:createDropdown{
		label = i18n("cfg.settings.logging.label"),
		description = i18n("cfg.settings.logging.description"),
		options = getListOptions("debugModes", true),
		variable = mwse.mcm.createTableVariable{ id = "logLevel", table = mod.config },
		callback = function(self)
			log:setLevel(self.variable.value)
			showHideDebugPage()
		end,
		postCreate = function(self)
			if (self.selectedOption) then
				log.debug("PageGeneral: Dropdown update from " .. self.selectedOption.value)
				log.debug("PageGeneral: Dropdown update to " .. log.getParam("logLevel"))
				self:selectOption(self:getOption(log.getParam("logLevel")))
			end
		end
	}

	catPosition:createSlider{
		label = i18n("cfg.settings.positionx.label"),
		description = i18n("cfg.settings.positionx.description"),
		min = 0,
		max = 1000,
		step = 1,
		jump = 100,
		variable = mwse.mcm.createTableVariable({id = "xposition", table = mod.config})
	}

	catPosition:createSlider{
		label = i18n("cfg.settings.positiony.label"),
		description = i18n("cfg.settings.positiony.description"),
		min = 0,
		max = 1000,
		step = 1,
		jump = 100,
		variable = mwse.mcm.createTableVariable({id = "yposition", table = mod.config})
	}

	catAppearance:createDropdown{
		label = i18n("cfg.settings.mode.label"),
		description = i18n("cfg.settings.mode.description"),
		options = getListOptions("layout"),
		variable = mwse.mcm.createTableVariable{ id = "layout", table = mod.config },
	}
	
	catAppearance:createYesNoButton({
		label = i18n("cfg.settings.munchkin.label"),
		description = i18n("cfg.settings.munchkin.description"),
		variable = mwse.mcm.createTableVariable({id = "showTime", table = mod.config})
	})

	catAppearance:createSlider{
		label = i18n("cfg.settings.width.label"),
		description = i18n("cfg.settings.width.description"),
		min = 50,
		max = 1000,
		step = 1,
		jump = 50,
		variable = mwse.mcm.createTableVariable({id = "width", table = mod.config})
	}

	catAppearance:createSlider{
		label = i18n("cfg.settings.padding.label"),
		description = i18n("cfg.settings.padding.description"),
		min = 0,
		max = 20,
		step = 1,
		jump = 5,
		variable = mwse.mcm.createTableVariable({id = "padding", table = mod.config})
	}

	
	local catGeneralDebug = pageDebug:createCategory(i18n("cfg.debug.general.label"))
	local catTesting = pageDebug:createCategory{
		label = i18n("cfg.debug.testing.label"),
		description = i18n("cfg.debug.testing.description"),
		postCreate = function(component)
			component.elements.outerContainer:registerAfter("destroy", function()
				log.debug("Component destroyed")
				elem.testBar = {}
			end)
		end
	}

	pageDebug.sidebar:createCategory(i18n("cfg.debug.info1") .. "\n")
	pageDebug.sidebar:createInfo(i18n("cfg.debug.info2"))
	pageDebug.sidebar:createInfo(i18n("cfg.debug.info3"))

	catGeneralDebug:createButton({
		label = i18n("cfg.debug.dump.label"),
		description = i18n("cfg.debug.dump.description"),
		buttonText = "> print()",
		callback = this.dumpCache
	})

	catGeneralDebug:createDropdown{
		label = i18n("cfg.settings.logging.label"),
		description = i18n("cfg.settings.logging.description"),
		options = getListOptions("debugModes", true),
		variable = mwse.mcm.createTableVariable{ id = "logLevel", table = mod.config },
		callback = function(self)
			log:setLevel(self.variable.value)
			showHideDebugPage()
		end,
		postCreate = function(self)
			if (self.selectedOption) then
				log.debug("PageDebug: Dropdown update from " .. self.selectedOption.value)
				log.debug("PageDebug: Dropdown update to " .. log.getParam("logLevel"))
				self:selectOption(self:getOption(log.getParam("logLevel")))
			end
		end
	}
	
	catGeneralDebug:createYesNoButton({
		label = i18n("cfg.debug.timestamp.label"),
		description = i18n("cfg.debug.timestamp.description"),
		variable = mwse.mcm.createTableVariable({id = "logTimestamps", table = mod.config}),
		callback = function(self)
			log.setParam("includeTimestamp", self.variable.value)
		end
	})
	
	catGeneralDebug:createYesNoButton({
		label = i18n("cfg.debug.logtick.label"),
		description = i18n("cfg.debug.logtick.description"),
		variable = mwse.mcm.createTableVariable({id = "logTicks", table = mod.config}),
	})

	catGeneralDebug:createDropdown{
		label = i18n("cfg.debug.output.label"),
		description = i18n("cfg.debug.output.description"),
		options = getListOptions("debugOutput"),
		variable = mwse.mcm.createTableVariable{ id = "logToConsole", table = mod.config },
		callback = function(self)
			log.setParam("logToConsole", self.variable.value)
		end
	}
	
	catTesting:createOnOffButton({
		label = i18n("cfg.debug.testbar.show"),
		description = i18n("cfg.debug.testing.description"),
		variable = mwse.mcm.createTableVariable({id = "testBarShow", table = mod.config}),
		callback = function()
			log:debug("Switching testbar: " .. json.encode(mod.config.testBarShow))
			showHideTestBar()
		end
	})
	
	catTesting:createYesNoButton({
		label = i18n("cfg.debug.testbar.hideother"),
		description = i18n("cfg.debug.testing.description"),
		variable = mwse.mcm.createTableVariable({id = "testExclusive", table = mod.config}),
		postCreate = showHideTestBar
	})
	
	catTesting:createYesNoButton({
		label = i18n("cfg.debug.testbar.revert"),
		description = i18n("cfg.debug.testing.description"),
		inGameOnly = true,
		variable = mwse.mcm.createTableVariable({id = "testRevert", table = mod.config}),
		postCreate = showHideTestBar
	})

	catTesting:createSlider{
		label = i18n("cfg.debug.testbar.value"),
		description = i18n("cfg.debug.testing.description"),
		inGameOnly = true,
		min = 0,
		max = 100,
		step = 1,
		jump = 5,
		variable = mwse.mcm.createTableVariable({id = "testValue", table = mod.config}),
		postCreate = showHideTestBar
	}

	catTesting:createSlider{
		label = i18n("cfg.debug.symbol.label"),
		description = i18n("cfg.debug.symbol.description"),
		inGameOnly = true,
		min = 25,
		max = 125,
		step = 1,
		jump = 5,
		variable = mwse.mcm.createTableVariable({id = "testLabelLength", table = mod.config})
	}
	
	log.info("MWSE config initialized")
end

this.getListName = getListName
this.getDisplayedList = getDisplayedList
this.registerConfig = registerMCMConfig

return this
