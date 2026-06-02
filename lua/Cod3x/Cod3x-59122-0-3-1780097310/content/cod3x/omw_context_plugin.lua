---
--- OpenMW Lua Language Server Plugin
--- Enforces script context annotations and module availability.
---
--- Usage
--- ------
--- 1. Add to your LuaLS settings:
---      "runtime.plugin": "./content/cod3x/omw_context_plugin.lua"
---
--- 2. Near the top of each script file, declare its context:
---      ---@omw-context global | local
---    Valid values: global | local | player | menu | load | runtime | all | none
---    Use "all" for portable Lua files limited to modules available in every script context.
---    Use "runtime" for portable Lua files limited to runtime script contexts.
---    Use "none" for API-agnostic Lua files that intentionally avoid openmw.*.
---    File-level contexts are the baseline intersection context for the file.
---
--- 3. Assert narrower scoped contexts only where needed:
---      ---@omw-context-next player
---      local ui = require('openmw.ui')
---
---      ---@omw-context-begin player
---      local debug = require('openmw.debug')
---      ---@omw-context-end
---    These pragmas are author assertions.  The plugin does not attempt to prove
---    that runtime branch guards match the asserted context.
---
--- How it works
--- ------------
--- When LLS processes a file, this plugin:
---   a) caches the file text and parsed context via OnSetText
---   b) scans for ---@omw-context <ctx> or <ctx> | <ctx> in that text,
---      plus scoped override pragmas ---@omw-context-next,
---      ---@omw-context-begin, and ---@omw-context-end
---   c) ignores ---@meta files and plugin/tooling files under /cod3x/
---   d) poisons missing/invalid context annotations with an undefined global,
---   e) poisons offending require('openmw.*') and require('openmw_aux.*') calls with an undefined global,
---   f) poisons offending openmw.core/openmw.storage top-level member access with an undefined global,
---      which makes LuaLS emit its built-in undefined-global diagnostic
---   g) blocks LuaLS module resolution for the same offending modules via
---      ResolveRequire returning {}
---
--- Context semantics (matches OpenMW docs @context convention)
--- -----------------------------------------------------------
---   global  : global scripts (one per game world)
---   local   : local scripts attached to an object (excludes player extras)
---   player  : player-specific scripts (superset of local; adds camera, input, ui, …)
---   menu    : main menu scripts (no in-world access)
---   load    : content file scripts (pre-game data loading)
---   runtime : global | local | player | menu
---   all     : portable scripts using only modules available in every script context
---   none    : API-agnostic Lua files that intentionally require no openmw.* modules
---
--- Context sets use intersection semantics: a module is allowed only if it is
--- available in every concrete context in the set. "runtime" expands to
--- global | local | player | menu. "all" expands to global | local | player |
--- menu | load. "none" cannot be combined.
---
--- NOTE on LLS plugin API compatibility
--- -------------------------------------
--- LuaLS 3.18.2-dev dispatches plugin globals such as OnSetText,
--- OnTransformAst, and ResolveRequire.  It does not dispatch OnDiagnostics
--- from a returned plugin table, so this file defines global hooks directly.
---
--- TODO (future work)
--- ------------------
---   * Instead of the hardcoded AVAILABILITY table, derive it at startup
---     by reading the @context annotations from the openmw/*.lua stubs,
---     so the map stays in sync automatically as new modules are added.
---   * Extend member-level restrictions beyond top-level module members,
---     including receiver/type rules such as Cell:getAll, Inventory:resolve,
---     and local self restrictions for nested members such as core.sound.playSound3d.
---   * If future LuaLS versions expose more plugin hooks, consider adding
---     editor actions for inserting or correcting ---@omw-context annotations.
---
-- ---------------------------------------------------------------------------
-- Availability map
-- ---------------------------------------------------------------------------
-- Derived from OpenMW Lua API annotations and openmw_aux source comments.
-- Each entry maps a fully-qualified module name to the set of contexts in
-- which it is available.
--
-- "local" in OpenMW's own @context notation means "all local scripts,
-- including the player script".  We therefore list both "local" and "player"
-- for those modules.  Modules whose LDT annotation says only "player" are
-- genuinely player-exclusive (camera, input, ui…).
--

local AVAILABILITY = {
    -- Available in all script contexts
    ["openmw.async"]          = { global = true, ["local"] = true, player = true, menu = true, load = true },
    ["openmw.core"]           = { global = true, ["local"] = true, player = true, menu = true, load = true },
    ["openmw.markup"]         = { global = true, ["local"] = true, player = true, menu = true, load = true },
    ["openmw.storage"]        = { global = true, ["local"] = true, player = true, menu = true, load = true },
    ["openmw.types"]          = { global = true, ["local"] = true, player = true, menu = true, load = true },
    ["openmw.util"]           = { global = true, ["local"] = true, player = true, menu = true, load = true },
    ["openmw.vfs"]            = { global = true, ["local"] = true, player = true, menu = true, load = true },

    -- Runtime contexts only
    ["openmw.interfaces"]     = { global = true, ["local"] = true, player = true, menu = true },
    ["openmw_aux.calendar"]       = { global = true, ["local"] = true, player = true, menu = true },
    ["openmw_aux.calendarconfig"] = { global = true, ["local"] = true, player = true, menu = true },
    ["openmw_aux.time"]           = { global = true, ["local"] = true, player = true, menu = true },
    ["openmw_aux.util"]           = { global = true, ["local"] = true, player = true, menu = true },

    -- Load only
    ["openmw.content"]        = { load = true },

    -- Global only
    ["openmw.world"]          = { global = true },

    -- Local + player (not global, not menu)
    ["openmw.animation"]      = { ["local"] = true, player = true },
    ["openmw.nearby"]         = { ["local"] = true, player = true },
    ["openmw.self"]           = { ["local"] = true, player = true },

    -- Player + menu (not plain local, not global)
    ["openmw.ambient"]        = { player = true, menu = true },
    ["openmw.input"]          = { player = true, menu = true },
    ["openmw.ui"]             = { player = true, menu = true },
    ["openmw_aux.ui"]         = { player = true, menu = true },

    -- Player only
    ["openmw.camera"]         = { player = true },
    ["openmw.debug"]          = { player = true },
    ["openmw.postprocessing"] = { player = true },

    -- Menu only
    ["openmw.menu"]           = { menu = true },
}

local CONCRETE_CONTEXTS = { "global", "local", "player", "menu", "load" }
local RUNTIME_CONTEXTS = { "global", "local", "player", "menu" }
local VALID_CONTEXTS = { global = true, ["local"] = true, player = true, menu = true, load = true, runtime = true, all = true, none = true }

local CORE_MEMBER_AVAILABILITY = {
    API_REVISION = { global = true, ["local"] = true, player = true, menu = true, load = true },
    contentFiles = { global = true, ["local"] = true, player = true, menu = true, load = true },
    getFormId = { global = true, ["local"] = true, player = true, menu = true, load = true },
    getGameDifficulty = { global = true, ["local"] = true, player = true, menu = true, load = true },
    l10n = { global = true, ["local"] = true, player = true, menu = true, load = true },

    dialogue = { global = true, ["local"] = true, player = true, menu = true },
    factions = { global = true, ["local"] = true, player = true, menu = true },
    getGMST = { global = true, ["local"] = true, player = true, menu = true },
    getGameTime = { global = true, ["local"] = true, player = true, menu = true },
    getGameTimeScale = { global = true, ["local"] = true, player = true, menu = true },
    getRealTime = { global = true, ["local"] = true, player = true, menu = true },
    getSimulationTime = { global = true, ["local"] = true, player = true, menu = true },
    getSimulationTimeScale = { global = true, ["local"] = true, player = true, menu = true },
    isWorldPaused = { global = true, ["local"] = true, player = true, menu = true },
    land = { global = true, ["local"] = true, player = true, menu = true },
    magic = { global = true, ["local"] = true, player = true, menu = true },
    mwscripts = { global = true, ["local"] = true, player = true, menu = true },
    quit = { global = true, ["local"] = true, player = true, menu = true },
    regions = { global = true, ["local"] = true, player = true, menu = true },
    sendGlobalEvent = { global = true, ["local"] = true, player = true, menu = true },
    sound = { global = true, ["local"] = true, player = true, menu = true },
    stats = { global = true, ["local"] = true, player = true, menu = true },
    weather = { global = true, ["local"] = true, player = true, menu = true },

    getRealFrameDuration = { ["local"] = true, player = true, menu = true },
}

local STORAGE_MEMBER_AVAILABILITY = {
    LIFE_TIME = { global = true, ["local"] = true, player = true, menu = true, load = true },
    globalSection = { global = true, ["local"] = true, player = true, menu = true, load = true },
    playerSection = { player = true, menu = true },
    allPlayerSections = { player = true, menu = true },
    allGlobalSections = { global = true },
}

local MEMBER_AVAILABILITY = {
    ["openmw.core"] = CORE_MEMBER_AVAILABILITY,
    ["openmw.storage"] = STORAGE_MEMBER_AVAILABILITY,
}

local MISSING_CONTEXT_POISON = "__OMW_CONTEXT_ERROR_missing_omw_context_add_none_if_api_agnostic__"
local INVALID_CONTEXT_POISON = "__OMW_CONTEXT_ERROR_invalid_omw_context__"

local fileCache = {}

-- ---------------------------------------------------------------------------
-- Internal helpers
-- ---------------------------------------------------------------------------

--- Parse an OpenMW context expression.
---@param raw string
---@return table
local function parseContextExpression(raw)
    raw = raw:match("^%s*(.-)%s*$")
    local parsed = { raw = raw, invalid = false, none = false, set = {} }
    local count = 0
    local pos = 1

    while true do
        local pipeStart, pipeFinish = raw:find("|", pos, true)
        local token = (pipeStart and raw:sub(pos, pipeStart - 1) or raw:sub(pos)):match("^%s*(.-)%s*$")

        if token == "" or not VALID_CONTEXTS[token] then
            parsed.invalid = true
            return parsed
        end

        count = count + 1
        if token == "none" then
            parsed.none = true
        elseif token == "all" then
            for _, context in ipairs(CONCRETE_CONTEXTS) do
                parsed.set[context] = true
            end
        elseif token == "runtime" then
            for _, context in ipairs(RUNTIME_CONTEXTS) do
                parsed.set[context] = true
            end
        else
            parsed.set[token] = true
        end

        if not pipeStart then
            break
        end
        pos = pipeFinish + 1
    end

    if parsed.none and count > 1 then
        parsed.invalid = true
    end

    return parsed
end

--- Extract and parse the ---@omw-context value from a file's text.
--- Returns nil if the annotation is absent.
---@param text string
---@return table?
local function parseContextSet(text)
    local raw = text:match("%-%-%-%s*@omw%-context%s+([^\r\n]+)")
    if not raw then
        return nil
    end

    return parseContextExpression(raw)
end

--- Return true if a file is a LuaLS doc/meta annotation file.
---@param text string
---@return boolean
local function hasMetaAnnotation(text)
    return text:match("%-%-%-%s*@meta%f[%W]") ~= nil
end

--- Return true if context annotations should be enforced for this URI.
---@param uri string?
---@return boolean
local function isContextRequiredForUri(uri)
    if not uri or not uri:match("%.lua$") then
        return false
    end

    return uri:find("/cod3x/", 1, true) == nil
end

--- Return the line prefix before a Lua line comment, ignoring -- inside strings.
---@param line string
---@return string
local function stripLineComment(line)
    local quote = nil
    local escaped = false

    for i = 1, #line do
        local ch = line:sub(i, i)
        local nextCh = line:sub(i + 1, i + 1)

        if quote then
            if escaped then
                escaped = false
            elseif ch == "\\" then
                escaped = true
            elseif ch == quote then
                quote = nil
            end
        elseif ch == '"' or ch == "'" then
            quote = ch
        elseif ch == "-" and nextCh == "-" then
            return line:sub(1, i - 1)
        end
    end

    return line
end

--- Parse a scoped context pragma from a comment-only line.
---@param line string
---@return string?, table?
local function parseScopedContextPragma(line)
    local raw = line:match("^%s*%-%-%-%s*@omw%-context%-next%s+([^\r\n]+)")
    if raw then
        return "next", parseContextExpression(raw)
    end

    raw = line:match("^%s*%-%-%-%s*@omw%-context%-begin%s+([^\r\n]+)")
    if raw then
        return "begin", parseContextExpression(raw)
    end

    if line:match("^%s*%-%-%-%s*@omw%-context%-end%s*$") then
        return "end", nil
    end

    return nil, nil
end

--- Normalize a module name passed by LuaLS.
---@param moduleName string
---@return string
local function normalizeModuleName(moduleName)
    return (moduleName:gsub("/", "."))
end

--- Return true if a module is an OpenMW module require.
---@param moduleName string
---@return boolean
local function isOpenMwModule(moduleName)
    return moduleName == "openmw" or moduleName == "openmw_aux"
        or moduleName:match("^openmw%.") ~= nil
        or moduleName:match("^openmw_aux%.") ~= nil
end

--- Build a readable undefined global name for LuaLS to diagnose.
---@param ctx table?
---@param moduleName string
---@return string
local function poisonName(ctx, moduleName)
    local contextPart
    if not ctx then
        contextPart = "missing_context"
    elseif not ctx.invalid then
        contextPart = ctx.raw:gsub("%W", "_")
    else
        contextPart = "unknown_context_" .. ctx.raw:gsub("%W", "_")
    end

    local modulePart = moduleName:gsub("%W", "_")
    return "__OMW_CONTEXT_ERROR_" .. contextPart .. "_cannot_require_" .. modulePart .. "__"
end

--- Build a readable undefined global name for disallowed top-level module members.
---@param ctx table?
---@param moduleName string
---@param memberName string
---@return string
local function memberPoisonName(ctx, moduleName, memberName)
    local contextPart
    if not ctx then
        contextPart = "missing_context"
    elseif not ctx.invalid then
        contextPart = ctx.raw:gsub("%W", "_")
    else
        contextPart = "unknown_context_" .. ctx.raw:gsub("%W", "_")
    end

    return "__OMW_CONTEXT_ERROR_" .. contextPart .. "_cannot_use_" .. moduleName:gsub("%W", "_") .. "_" .. memberName .. "__"
end

--- Insert an undefined global for a missing or invalid context annotation.
---@param diffs table[]
---@param ctx table?
local function insertContextPoisonDiff(diffs, ctx)
    if ctx and not ctx.invalid then
        return
    end

    table.insert(diffs, {
        start = 1,
        finish = 0,
        text = "local _ = " .. (ctx and INVALID_CONTEXT_POISON or MISSING_CONTEXT_POISON) .. "\n",
    })
end

--- Return true if a require should be blocked/poisoned in this source context.
---@param ctx table?
---@param moduleName string
---@return boolean
local function shouldReject(ctx, moduleName)
    if not isOpenMwModule(moduleName) then
        return false
    end

    if moduleName == "openmw_aux" then
        return true
    end

    if not ctx or ctx.invalid then
        return true
    end

    if ctx.none then
        return true
    end

    local moduleCtxs = AVAILABILITY[moduleName]
    if not moduleCtxs then
        return false
    end

    for _, context in ipairs(CONCRETE_CONTEXTS) do
        if ctx.set[context] and not moduleCtxs[context] then
            return true
        end
    end

    return false
end

--- Return true if a top-level module member should be blocked/poisoned.
---@param ctx table?
---@param moduleName string
---@param memberName string
---@return boolean
local function shouldRejectModuleMember(ctx, moduleName, memberName)
    if not ctx or ctx.invalid or ctx.none then
        return true
    end

    local memberAvailability = MEMBER_AVAILABILITY[moduleName]
    if not memberAvailability then
        return false
    end

    local memberCtxs = memberAvailability[memberName]
    if not memberCtxs then
        return false
    end

    for _, context in ipairs(CONCRETE_CONTEXTS) do
        if ctx.set[context] and not memberCtxs[context] then
            return true
        end
    end

    return false
end

--- Return the narrowest intersection-safe openmw.core surface for this context set.
---@param ctx table?
---@return string?
local function coreSurfaceForContext(ctx)
    if not ctx or ctx.invalid or ctx.none then
        return nil
    end

    if ctx.set.load then
        return "All"
    end

    if ctx.set.global then
        return "Runtime"
    end

    if ctx.set["local"] or ctx.set.player or ctx.set.menu then
        return "FrameRuntime"
    end

    return nil
end

--- Return the narrowest intersection-safe openmw.storage surface for this context set.
---@param ctx table?
---@return string?
local function storageSurfaceForContext(ctx)
    if not ctx or ctx.invalid or ctx.none then
        return nil
    end

    if ctx.set.global and not ctx.set["local"] and not ctx.set.player and not ctx.set.menu and not ctx.set.load then
        return "Global"
    end

    if (ctx.set.player or ctx.set.menu) and not ctx.set.global and not ctx.set["local"] and not ctx.set.load then
        return "PlayerMenu"
    end

    return "All"
end

--- Return the storage section type for a storage section constructor in this context.
---@param ctx table?
---@param memberName string
---@return string?
local function storageSectionReturnTypeForContext(ctx, memberName)
    if shouldRejectModuleMember(ctx, "openmw.storage", memberName) then
        return nil
    end

    if memberName == "globalSection" then
        if ctx and not ctx.invalid and not ctx.none and ctx.set.global
            and not ctx.set["local"] and not ctx.set.player and not ctx.set.menu and not ctx.set.load then
            return "openmw.storage.MutableStorageSection"
        end

        return "openmw.storage.StorageSection"
    end

    if memberName == "playerSection" then
        return "openmw.storage.MutableStorageSection"
    end

    return nil
end

--- Return the type to inject for a local require alias in the effective context.
---@param ctx table?
---@param moduleName string
---@return string?
local function moduleAliasTypeForContext(ctx, moduleName)
    if shouldReject(ctx, moduleName) then
        return nil
    end

    if moduleName == "openmw.core" then
        local surface = coreSurfaceForContext(ctx)
        return surface and "openmw.core." .. surface or nil
    end

    if moduleName == "openmw.storage" then
        local surface = storageSurfaceForContext(ctx)
        return surface and "openmw.storage." .. surface or nil
    end

    if isOpenMwModule(moduleName) then
        return moduleName
    end

    return nil
end

--- Escape a literal string for Lua patterns.
---@param value string
---@return string
local function escapePattern(value)
    return (value:gsub("([^%w])", "%%%1"))
end

--- Match a require call starting at `pos` in `line`.
---@param line string
---@param pos integer
---@return table?
local function matchRequireAt(line, pos)
    local before = pos > 1 and line:sub(pos - 1, pos - 1) or ""
    if before:match("[%w_%.:]") then
        return nil
    end

    local rest = line:sub(pos)
    local afterKeyword = rest:sub(8, 8)
    if afterKeyword:match("[%w_]") then
        return nil
    end

    local argStart, moduleName, argFinish, callFinish = rest:match('^require%s*%(%s*()"([^"]+)"()%s*%)()')
    if moduleName then
        return {
            module = moduleName,
            start = pos + argStart - 1,
            finish = pos + argFinish - 2,
            callFinish = pos + callFinish - 2,
            paren = true,
        }
    end

    argStart, moduleName, argFinish, callFinish = rest:match("^require%s*%(%s*()'([^']+)'()%s*%)()")
    if moduleName then
        return {
            module = moduleName,
            start = pos + argStart - 1,
            finish = pos + argFinish - 2,
            callFinish = pos + callFinish - 2,
            paren = true,
        }
    end

    argStart, moduleName, argFinish = rest:match('^require%s+()"([^"]+)"()')
    if moduleName then
        return {
            module = moduleName,
            start = pos + argStart - 1,
            finish = pos + argFinish - 2,
            callFinish = pos + argFinish - 2,
            paren = false,
        }
    end

    argStart, moduleName, argFinish = rest:match("^require%s+()'([^']+)'()")
    if moduleName then
        return {
            module = moduleName,
            start = pos + argStart - 1,
            finish = pos + argFinish - 2,
            callFinish = pos + argFinish - 2,
            paren = false,
        }
    end

    return nil
end

--- Match require('module').member or require 'module'.member at `pos`.
---@param line string
---@param pos integer
---@param moduleName string
---@return table?
local function matchRequireMemberAt(line, pos, moduleName)
    local before = pos > 1 and line:sub(pos - 1, pos - 1) or ""
    if before:match("[%w_%.:]") then
        return nil
    end

    local rest = line:sub(pos)
    local afterKeyword = rest:sub(8, 8)
    if afterKeyword:match("[%w_]") then
        return nil
    end

    local modulePattern = escapePattern(moduleName)
    local memberName, memberFinish = rest:match('^require%s*%(%s*"' .. modulePattern .. '"%s*%)%s*%.%s*([%a_][%w_]*)()')
    if memberName then
        return { member = memberName, start = pos, finish = pos + memberFinish - 2 }
    end

    memberName, memberFinish = rest:match("^require%s*%(%s*'" .. modulePattern .. "'%s*%)%s*%.%s*([%a_][%w_]*)()")
    if memberName then
        return { member = memberName, start = pos, finish = pos + memberFinish - 2 }
    end

    memberName, memberFinish = rest:match('^require%s+"' .. modulePattern .. '"%s*%.%s*([%a_][%w_]*)()')
    if memberName then
        return { member = memberName, start = pos, finish = pos + memberFinish - 2 }
    end

    memberName, memberFinish = rest:match("^require%s+'" .. modulePattern .. "'%s*%.%s*([%a_][%w_]*)()")
    if memberName then
        return { member = memberName, start = pos, finish = pos + memberFinish - 2 }
    end

    return nil
end

--- Return the module name only when the RHS is exactly require('openmw'), require('openmw_aux'),
--- or a dotted OpenMW/OpenMW aux module require.
---@param code string
---@param rhsStart integer
---@return string?
local function exactOpenMwRequireRhsModule(code, rhsStart)
    local req = matchRequireAt(code, rhsStart)
    if not req or not isOpenMwModule(req.module) then
        return nil
    end

    if code:sub(req.callFinish + 1):match("^%s*$") then
        return normalizeModuleName(req.module)
    end

    return nil
end

--- Match `local alias = require('openmw.*').member ...` style declarations on one line.
---@param code string
---@return table?
local function localRequireMemberAlias(code)
    local _, _, alias, rhsStart = code:find("^%s*local%s+([%a_][%w_]*)%s*=%s*()")
    if not alias then
        return nil
    end

    for moduleName in pairs(MEMBER_AVAILABILITY) do
        local memberUse = matchRequireMemberAt(code, rhsStart, moduleName)
        if memberUse then
            return { alias = alias, module = moduleName, member = memberUse.member }
        end
    end

    return nil
end

--- Record `local alias = require('module')` style aliases from one line.
---@param code string
---@param aliases table
---@param moduleName string
local function recordModuleAliases(code, aliases, moduleName)
    local searchStart = 1
    while true do
        local _, _, alias, rhsStart = code:find("local%s+([%a_][%w_]*)%s*=%s*()", searchStart)
        if not alias then
            break
        end

        if exactOpenMwRequireRhsModule(code, rhsStart) == moduleName then
            aliases[alias] = true
        end

        searchStart = rhsStart + 1
    end
end

--- Match `local alias = require('openmw.*')` style alias declarations on one line.
---@param code string
---@return string?, string?
local function localRequireAliasModule(code)
    local _, _, alias, rhsStart = code:find("^%s*local%s+([%a_][%w_]*)%s*=%s*()")
    if not rhsStart then
        return nil
    end

    return alias, exactOpenMwRequireRhsModule(code, rhsStart)
end

--- Add type annotations before known chained require return values.
---@param diffs table[]
---@param code string
---@param lineText string
---@param previousLineText string?
---@param lineStart integer
---@param ctx table?
local function addChainedRequireTypeDiff(diffs, code, lineText, previousLineText, lineStart, ctx)
    local aliasUse = localRequireMemberAlias(code)
    if not aliasUse or aliasUse.module ~= "openmw.storage" then
        return
    end

    local typeName = storageSectionReturnTypeForContext(ctx, aliasUse.member)
    if not typeName then
        return
    end

    if previousLineText and previousLineText:match("^%s*%-%-%-%s*@type%f[%W]") then
        return
    end

    local indent = lineText:match("^(%s*)") or ""
    table.insert(diffs, {
        start = lineStart,
        finish = lineStart - 1,
        text = indent .. "---@type " .. typeName .. "\n",
    })
end

--- Add casts after openmw.* local require aliases.
--- Casts avoid assignment diagnostics against the broad raw module return type while
--- still narrowing the alias for context-aware member diagnostics and completion.
---@param diffs table[]
---@param code string
---@param lineText string
---@param previousLineText string?
---@param lineStart integer
---@param ctx table?
local function addModuleAliasTypeDiff(diffs, code, lineText, previousLineText, lineStart, ctx)
    local alias, moduleName = localRequireAliasModule(code)
    if not moduleName then
        return
    end

    local typeName = moduleAliasTypeForContext(ctx, moduleName)
    if not typeName then
        return
    end

    if previousLineText and previousLineText:match("^%s*%-%-%-%s*@type%f[%W]") then
        return
    end

    local indent = lineText:match("^(%s*)") or ""
    table.insert(diffs, {
        start = lineStart + #lineText + 1,
        finish = lineStart + #lineText,
        text = indent .. "---@cast " .. alias .. " " .. typeName .. "\n",
    })
end

--- Add poison edits for disallowed direct require('module').member uses.
---@param diffs table[]
---@param code string
---@param lineStart integer
---@param ctx table?
---@param moduleName string
local function addDirectModuleMemberDiffs(diffs, code, lineStart, ctx, moduleName)
    local searchStart = 1
    while true do
        local requireStart = code:find("require", searchStart, true)
        if not requireStart then
            break
        end

        local memberUse = matchRequireMemberAt(code, requireStart, moduleName)
        if memberUse and shouldRejectModuleMember(ctx, moduleName, memberUse.member) then
            table.insert(diffs, {
                start = lineStart + memberUse.start - 1,
                finish = lineStart + memberUse.finish - 1,
                text = memberPoisonName(ctx, moduleName, memberUse.member),
            })
            searchStart = memberUse.finish + 1
        else
            searchStart = requireStart + 7
        end
    end
end

--- Add poison edits for disallowed alias.member uses.
---@param diffs table[]
---@param code string
---@param lineStart integer
---@param ctx table?
---@param aliases table
---@param moduleName string
local function addAliasModuleMemberDiffs(diffs, code, lineStart, ctx, aliases, moduleName)
    for alias in pairs(aliases) do
        local searchStart = 1
        while true do
            local exprStart, _, memberName, memberFinish = code:find(alias .. "%s*%.%s*([%a_][%w_]*)()", searchStart)
            if not exprStart then
                break
            end

            local before = exprStart > 1 and code:sub(exprStart - 1, exprStart - 1) or ""
            if not before:match("[%w_%.:]") and shouldRejectModuleMember(ctx, moduleName, memberName) then
                table.insert(diffs, {
                    start = lineStart + exprStart - 1,
                    finish = lineStart + memberFinish - 2,
                    text = memberPoisonName(ctx, moduleName, memberName),
                })
            end

            searchStart = memberFinish
        end
    end
end

--- Scan `text` for OpenMW require calls and build poison edits.
---@param text string
---@param ctx table?
---@return table[], table
local function makePoisonDiffs(text, ctx)
    local diffs = {}
    local coreAliases = {}
    local storageAliases = {}
    local scopedAllowedModules = {}
    local overrideStack = {}
    local pendingNextOverride = nil
    local lineStart = 1
    local previousLineText = nil

    for lineText in (text .. "\n"):gmatch("([^\n]*)\n") do
        if lineText:match("^%s*%-%-") then
            local pragma, pragmaCtx = parseScopedContextPragma(lineText)
            if pragma == "next" then
                pendingNextOverride = pragmaCtx
            elseif pragma == "begin" then
                table.insert(overrideStack, pragmaCtx)
            elseif pragma == "end" and #overrideStack > 0 then
                table.remove(overrideStack)
            end
        else
            local code = stripLineComment(lineText)
            if code:match("%S") then
                local effectiveCtx = pendingNextOverride or overrideStack[#overrideStack] or ctx
                pendingNextOverride = nil
                local searchStart = 1

                addModuleAliasTypeDiff(diffs, code, lineText, previousLineText, lineStart, effectiveCtx)
                addChainedRequireTypeDiff(diffs, code, lineText, previousLineText, lineStart, effectiveCtx)

                if not shouldReject(effectiveCtx, "openmw.core") then
                    recordModuleAliases(code, coreAliases, "openmw.core")
                    addDirectModuleMemberDiffs(diffs, code, lineStart, effectiveCtx, "openmw.core")
                    addAliasModuleMemberDiffs(diffs, code, lineStart, effectiveCtx, coreAliases, "openmw.core")
                end

                if not shouldReject(effectiveCtx, "openmw.storage") then
                    recordModuleAliases(code, storageAliases, "openmw.storage")
                    addDirectModuleMemberDiffs(diffs, code, lineStart, effectiveCtx, "openmw.storage")
                    addAliasModuleMemberDiffs(diffs, code, lineStart, effectiveCtx, storageAliases, "openmw.storage")
                end

                while true do
                    local requireStart = code:find("require", searchStart, true)
                    if not requireStart then
                        break
                    end

                    local req = matchRequireAt(code, requireStart)
                    if req and shouldReject(effectiveCtx, req.module) then
                        local replacement = poisonName(effectiveCtx, req.module)
                        if not req.paren then
                            replacement = "(" .. replacement .. ")"
                        end

                        table.insert(diffs, {
                            start = lineStart + req.start - 1,
                            finish = lineStart + req.finish - 1,
                            text = replacement,
                        })
                        searchStart = req.finish + 1
                    else
                        if req and shouldReject(ctx, req.module) then
                            scopedAllowedModules[normalizeModuleName(req.module)] = true
                        end
                        searchStart = requireStart + 7
                    end
                end
            end
        end

        lineStart = lineStart + #lineText + 1
        previousLineText = lineText
    end

    return diffs, scopedAllowedModules
end

-- ---------------------------------------------------------------------------
-- File text cache
-- ---------------------------------------------------------------------------
-- ResolveRequire receives the module and source URI, not the full source text.
-- OnSetText keeps the source context cache current for resolution decisions.

-- ---------------------------------------------------------------------------
-- LLS plugin hooks
-- ---------------------------------------------------------------------------

--- Called by LLS whenever a file's text is set or updated.
--- We cache context and return poison-pill edits for invalid OpenMW requires.
---@param uri  string
---@param text string
---@return table[]?   -- nil = don't modify the text
function OnSetText(uri, text)
    if isContextRequiredForUri(uri) then
        local ctx = parseContextSet(text)
        local isMeta = hasMetaAnnotation(text)

        if isMeta then
            fileCache[uri] = { context = ctx, meta = isMeta, scopedAllowedModules = {} }
            return nil
        end

        local diffs, scopedAllowedModules = makePoisonDiffs(text, ctx)
        fileCache[uri] = { context = ctx, meta = isMeta, scopedAllowedModules = scopedAllowedModules }
        insertContextPoisonDiff(diffs, ctx)

        if #diffs > 0 then
            return diffs
        end
    elseif uri and uri:match("%.lua$") then
        fileCache[uri] = nil
    end

    return nil
end

--- Called by LLS when resolving require().
---@param rootUri string
---@param moduleName string
---@param sourceUri string
---@return table?
function ResolveRequire(rootUri, moduleName, sourceUri)
    moduleName = normalizeModuleName(moduleName)
    if not isOpenMwModule(moduleName) then
        return nil
    end

    if sourceUri and not isContextRequiredForUri(sourceUri) then
        return nil
    end

    local cached = sourceUri and fileCache[sourceUri]
    if not cached then
        return nil
    end

    if cached.meta then
        return nil
    end

    if shouldReject(cached.context, moduleName) and not (cached.scopedAllowedModules and cached.scopedAllowedModules[moduleName]) then
        return {}
    end

    return nil
end
