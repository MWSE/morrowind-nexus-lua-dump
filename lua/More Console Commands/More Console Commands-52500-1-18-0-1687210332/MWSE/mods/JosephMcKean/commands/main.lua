local config = require("JosephMcKean.commands.config")
local data = require("JosephMcKean.commands.data")

local log = require("logging.logger").new({ name = "More Console Commands - main", logLevel = config.logLevel })

local modName = "More Console Commands"

--- @param e uiActivatedEventData
local function onMenuConsoleActivated(e)
	if (not e.newlyCreated) then return end

	local menuConsole = e.element
	local input = menuConsole:findChild("UIEXP:ConsoleInputBox")
	if not input then return end
	local scriptToggleButton = input.parent.parent:findChild(-984).parent
	if config.defaultLuaConsole then
		local toggleText = scriptToggleButton.text
		if toggleText ~= "lua" then scriptToggleButton:triggerEvent("mouseClick") end
	end

	input:registerBefore("keyPress", function(k)
		if not config.leftRightArrowSwitch then return end
		local key = k.data0
		if (key == -0x7FFFFFFE) or (key == -0x7FFFFFFF) then
			-- Pressing right or left
			scriptToggleButton:triggerEvent("mouseClick")
		end
	end)
end

---@param w string
---@return string
local function unquote(w)
	local word = w
	word = word:gsub("^\"", "")
	word = word:gsub("\"$", "")
	return word
end

---@param command string
---@return string? fn
---@return string[] args
local function getArgs(command)
	local args = {} ---@type string[]
	for w in string.gmatch(command, "%S+") do table.insert(args, unquote(w)) end
	local fn = args[1] and args[1]:lower()
	if fn then table.remove(args, 1) end
	return fn, args
end

---@param fn string 
---@param args string[]
local function parseArgs(fn, args)
	if not data.commands[fn].caseSensitive then for _, arg in ipairs(args) do arg = arg:lower() end end
	if data.commands[fn].arguments then
		local errored
		local metavars = ""
		local invalidChoiceArgs = {} ---@type command.data.argument[]
		local missingMetavars = ""

		-- parsing arguments
		for _, argument in ipairs(data.commands[fn].arguments) do
			if argument.index == 1 and argument.containsSpaces then args = { table.concat(args, " ") } end
			metavars = metavars .. argument.metavar .. " "
			-- missing args error
			if argument.required and not args[argument.index] then
				errored = true
				missingMetavars = missingMetavars .. argument.metavar .. " "
			end
			-- invalid choices error
			if argument.choices and not table.empty(argument.choices) and not table.find(argument.choices, args[argument.index]) then
				errored = true
				table.insert(invalidChoiceArgs, argument)
			end
		end

		-- printing error messages
		if errored then
			tes3ui.log("usage: %s %s", fn, metavars) -- usage: money goldcount

			-- missing args error
			if missingMetavars ~= "" then
				tes3ui.log("%s: error: the following arguments are required: %s", fn, missingMetavars)
				-- money: error: the following arguments are required: goldcount	
			end
			-- invalid choices error
			if not table.empty(invalidChoiceArgs) then
				for _, invalidChoiceArg in ipairs(invalidChoiceArgs) do
					tes3ui.log("%s: error: argument %s: invalid choice: %s (choose from %s)", fn, invalidChoiceArg.metavar, args[invalidChoiceArg.index], table.concat(invalidChoiceArg.choices, ", "))
					-- levelup: error: argument skillname: invalid choice: block (choose from bushcrafting, survival)
				end
			end
			return false
		end
	end
	return true
end

---@param alias string
---@return string?
local function getAlias(alias)
	if data.commands[alias] then
		return alias
	elseif data.aliases[alias] then
		return data.aliases[alias]
	end
	return nil
end

local function parseCommands(e)
	if e.context ~= "lua" then return end
	if not e.command then return end
	e.command = e.command:match("^`*(.+)") --[[@as string]]
	log:debug("parseCommands %s", e.command)
	if not e.command then return end
	local fnAlias, args = getArgs(e.command)
	if not fnAlias then return end
	local fn = getAlias(fnAlias)
	if not fn then return end
	local parseResult = parseArgs(fn, args)
	if parseResult then data.commands[fn].callback(args) end
	e.block = true
end

local function parseHelpCommand(e)
	if e.context ~= "lua" then return end
	if not e.command then return end
	local command = e.command:match("^`*(.+)") --[[@as string]]
	if not e.command then return end
	local fn, _ = getArgs(command)
	if fn ~= "help" then return end
	tes3ui.log("help: Show a list of available commands")
	for functionName, commandData in pairs(data.commands) do tes3ui.log("%s: %s", functionName, commandData.description) end
	e.block = true
end

event.register("initialized", function()
	event.trigger("command:register")
	for functionName, commandData in pairs(data.commands) do if commandData.aliases then for _, alias in ipairs(commandData.aliases) do data.aliases[alias] = functionName end end end
	event.register("uiActivated", onMenuConsoleActivated, { filter = "MenuConsole", priority = -9999 })
	event.register("UIEXP:consoleCommand", parseCommands)
	event.register("UIEXP:consoleCommand", parseHelpCommand, { priority = -9999 })
	event.register("UIEXP:sandboxConsole", function(e) e.sandbox.command = require("JosephMcKean.commands.interop") end)
end, { priority = -999 })

local function registerModConfig()
	local template = mwse.mcm.createTemplate(modName)
	template:saveOnClose(modName, config)

	local page = template:createPage()

	local settings = page:createCategory("Settings")
	settings:createYesNoButton({ label = "Press left right arrow to switch between lua and mwscript console", variable = mwse.mcm.createTableVariable({ id = "leftRightArrowSwitch", table = config }) })
	settings:createYesNoButton({ label = "Default to lua console", variable = mwse.mcm.createTableVariable({ id = "defaultLuaConsole", table = config }) })

	local info = page:createCategory("Available Commands")
	info:createInfo({ text = "help: Shows up available communeDeadDesc." })
	for functionName, commandData in pairs(data.commands) do info:createInfo({ text = string.format("%s: %s", functionName, commandData.description) }) end
	info:createInfo({
		text = "\nClick on the object while console menu is open to select the current reference. If nothing is selected, current reference is default to the player. \n" ..
		"For example, if nothing is selected, you type and enter money 420, the player will get 420 gold. But if fargoth is selected, fargoth will get the money instead.",
	})
	info:createInfo({ text = "\nMore detailed documentation see Docs\\More Console Commands.md or \nNexusmods page:\n" })
	info:createHyperlink{ text = "https://www.nexusmods.com/morrowind/mods/52500", exec = "https://www.nexusmods.com/morrowind/mods/52500" }

	mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)
