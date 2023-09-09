local interop = {}

---@type table<string, table<string>>
interop.commands = {
    ["mwscript"] = {},
    ["lua"] = {}
}
---@type table<string, table<string, table<function>>>
interop.paramConfig = {
    ["mwscript"] = {},
    ["lua"] = {}
}

---@enum ConsoleType
interop.consoleType = {
    ["mwscript"] = "mwscript",
    ["lua"] = "lua"
}

---@param command string
---@param type ConsoleType
function interop:registerSuggestion(command, type)
    table.insert(self.commands[type], command)
end

---@param command string
---@param type ConsoleType
---@param parameters table<function<table>>
function interop:registerCommand(command, type, parameters)
    self.paramConfig[type][command] = parameters
    print(string.format("[Blue - Smart Console]: Registered command with (%s) parameters: %s", tostring(#parameters), command))
end

return interop
