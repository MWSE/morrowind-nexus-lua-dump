local log = require("animationBlending.log")
local easing = require("animationBlending.easing")


---@class BlendRule
---@field from string
---@field to string
---@field easing string
---@field duration number


local this = {}


--- Default blending rules.
---
---@type BlendRule[]
local defaultRules = {}


--- Per-mesh blending rules.
---
---@type table<string, BlendRule[]>
local blendingRules = {}


--- Combine two animation groups into a single key for table look ups.
---
---@param groupA tes3.animationGroup
---@param groupB tes3.animationGroup
---@return number
local function hashGroups(groupA, groupB)
    return bit.bor(bit.lshift(groupA, 8), groupB)
end


--- Get the blending rules for a given reference and animation groups.
---
---@param reference tes3reference
---@param fromGroup tes3.animationGroup
---@param toGroup tes3.animationGroup
---@return BlendRule?
function this.get(reference, fromGroup, toGroup)
    local mesh = reference.object.mesh:lower()
    local type = reference.object.objectType

    local rules = blendingRules[mesh] or {}
    local key = hashGroups(fromGroup, toGroup)

    -- Actors use the default rule if no override exists.
    if type == tes3.objectType.npc
        or type == tes3.objectType.creature
    then
        return rules[key] or defaultRules[key]
    else
        return rules[key]
    end
end


--- Check if an animation group name matches a rules pattern.
---
---@param name string
---@param pattern string
function this.matches(name, pattern)
    -- The pattern is in the form of a "groupName:keyName" string.
    local groupName, keyName = pattern:match("([^:]*):?(.*)")

    -- We currently only support the "groupName" part of the pair.
    -- If there's a "keyName" part we ignore the pattern entirely.
    if keyName ~= "" and keyName ~= "*" then
        return false
    end

    -- If the pattern is a wildcard, always consider as matching.
    if groupName == "*" then
        return true
    end

    -- Get the start/stop indices of the pattern in the given name.
    local start, stop = name:lower():find(groupName:lower():gsub("*", ""), 1, true)
    if not (start and stop) then
        return false
    end

    -- Patterns not starting with a wildcard must match from the start.
    if not groupName:startswith("*") and start ~= 1 then
        return false
    end

    -- Patterns not ending with a wildcard must match to the end.
    if not groupName:endswith("*") and stop ~= name:len() then
        return false
    end

    return true
end


--- Iterate over all animation groups matching a pattern.
---
---@param pattern string
---@return fun():tes3.animationGroup
local function matchingGroups(pattern)
    return coroutine.wrap(function()
        for name, group in pairs(tes3.animationGroup) do
            if this.matches(name, pattern) then
                coroutine.yield(group)
            end
        end
    end)
end


--- Parse the blending rules from raw yaml data.
---
---@param data BlendRule[]
---@return BlendRule[]
local function parseRules(data)
    local rules = {}

    for i, rule in ipairs(data) do
        log:assert(type(rule.to) == "string", "Invalid 'to' value in blending rule %d", i)
        log:assert(type(rule.from) == "string", "Invalid 'from' value in blending rule %d", i)
        log:assert(type(rule.easing) == "string", "Invalid 'easing' value in blending rule %d", i)
        log:assert(type(rule.duration) == "number", "Invalid 'duration' value in blending rule %d", i)
        log:assert(type(easing[rule.easing]) == "function", "Invalid 'easing' function in blending rule %d", i)

        local count = 0

        for from in matchingGroups(rule.from) do
            for to in matchingGroups(rule.to) do
                local key = hashGroups(from, to)
                rules[key] = rule
                count = count + 1
            end
        end

        if count == 0 then
            log:warn('No matching groups for { from:"%s", to:"%s" }', rule.from, rule.to)
        end
    end

    return rules
end


--- Load blending rules from a yaml file.
---
---@param path string
---@return BlendRule[]?
local function loadRules(path)
    local file = io.open(path, "r")
    if file == nil then
        return
    end

    local config = yaml.decode(file:read("*a"))
    if config == nil then
        log:warn('Decode failure on "%s"', path)
        return
    end

    if config.blending_rules == nil then
        log:warn('No "blending_rules" key in "%s"', path)
        return
    end

    local rules = parseRules(config.blending_rules)
    if rules == nil then
        log:warn('Failed to parse blending rules from "%s"', path)
        return
    end

    log:info('Loaded blending rules from "%s"', path)

    return rules
end


--- Set the blending rules for a given mesh.
---
---@param path string
---@param rules BlendRule[]
function this.setRules(path, rules)
    blendingRules[path] = parseRules(rules)
end


--- Store blending rules when a keyframe file is loaded.
---
---@param e keyframesLoadEventData
local function onKeyframesLoad(e)
    local path = e.path:lower()
    if blendingRules[path] then
        return
    end

    -- A default value to prevent re-loading on failure.
    blendingRules[path] = {}

    local dir, name = path:match("(.-)([^\\]+)%.nif$")
    local rulesPath = dir .. "x" .. name .. ".yaml"

    blendingRules[path] = loadRules("data files\\meshes\\" .. rulesPath)
end
event.register("keyframesLoad", onKeyframesLoad, { priority = 1000 })


-- Load and store the default blending rules.
do
    local rules = (
        loadRules("data files\\animations\\animation-config.yaml") -- user override path
        or loadRules("data files\\mwse\\mods\\animationBlending\\animation-config.yaml")
    )
    if rules then
        defaultRules = rules
    else
        log:warn("Failed to load default blending rules")
    end
end


return this
