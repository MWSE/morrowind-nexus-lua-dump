---@meta

-- This file was mechanically drafted from files/lua_api/openmw/markup.lua.
-- It uses LuaLS/LLS annotations and stub bodies only; runtime behavior is provided by OpenMW.
-- OpenMW script contexts: global|menu|local|player|load

---Allows to work with markup languages.
---@class openmw.markup
local markup = {}

---Convert YAML data to a Lua object
---Otherwise, type deduction works according to YAML 1.2 [Core Schema](https://yaml.org/spec/1.2.2/#103-core-schema).
----- prints 1
---print(result["x"])
---@param inputData string Data to decode. It has such limitations: 1. YAML format of [version 1.2](https://yaml.org/spec/1.2.2) is used. 2. Map keys should be scalar values (strings, booleans, numbers). 3. YAML tag system is not supported. 4. If a scalar is quoted, it is treated like a string. 5. Circular dependencies between YAML nodes are not allowed. 6. Lua 5.1 does not have integer numbers - all numeric scalars use a #number type (which use a floating point). 7. Integer scalars numbers values are limited by the "int" range. Use floating point notation for larger number in YAML files.
---@return any Lua object (can be table or scalar value).
function markup.decodeYaml(inputData) end

---Load a YAML file from the VFS to Lua object. Conventions are the same as in markup.decodeYaml.
---local result = markup.loadYaml('test.yaml');
----- prints 1
---print(result["x"])
---@param fileName string YAML file path in the VFS.
---@return any Lua object (can be table or scalar value).
function markup.loadYaml(fileName) end

return markup
