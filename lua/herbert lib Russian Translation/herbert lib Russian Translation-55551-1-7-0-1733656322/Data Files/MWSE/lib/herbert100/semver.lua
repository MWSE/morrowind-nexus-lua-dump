--[[ NOTICE:
    This code was inspired by the semver lua library, released under the MIT license, and available at this repository: 'https://github.com/kikito/semver.lua'.
    Although, many parts of it have been altered to suite my use-case. 
    I'm not sure how closely the current version of this file resembles 'https://github.com/kikito/semver.lua', but I wanted to include this notice for transparency.
]]


local fmt = string.format
local MAJOR_MINOR_PATCH_PATTERN = "^(%d+)%.(%d+)%.(%d+)"

local log = require("herbert100.logger").new()

local SemVer_meta = {} ---@type metatable

local function traceback(...)
    return debug.traceback(string.format(...))
end

---@param str string
---@return herbert.SemVer?
local function parse(str)
    local s, e, major, minor, patch = str:find(MAJOR_MINOR_PATCH_PATTERN)
    if not (major and minor and patch) then
        log:error(traceback, 'Invalid semver string "%s": strings must be in the form \z
            <MAJOR>.<MINOR>.<PATCH>, where MAJOR, MINOR, and PATCH are whole numbers.', 
            str
        )
        return
    end
    
    local sv = {tonumber(major), tonumber(minor), tonumber(patch), prerelease = {}, build = {}}
    setmetatable(sv, SemVer_meta)

    if e == str:len() then return sv end

    local identifiers_start = str:sub(e + 1, e + 1)
    local rest = str:sub(e + 2)

    if identifiers_start == '+' then
        sv.build = rest:split("%.")
        return sv
    end
    if str:sub(e + 1, e + 1) ~= '-' then
        log:error(traceback, 'Invalid semver string "%s": prerelease identifiers must start with a hyphen!', str)
        return
    end
    
    local build_start = rest:find("+", 1, true)
    local prerelease_part, build_part = rest, nil

    if build_start then
        prerelease_part = rest:sub(1, build_start - 1)
        build_part = rest:sub(build_start + 1)
    end

    sv.prerelease = prerelease_part:split("%.")
    sv.build = build_part and build_part:split("%.")
    log:trace('Successfully parsed "%s". semver = %s', str, sv)

    return sv
end


---@class herbert.SemVer : integer[]
---@field major integer
---@field minor integer
---@field patch integer
---@field prerelease string[]
---@field build string[]
---@operator call(string|herbert.SemVer): herbert.SemVer
local SemVer = {}

function SemVer.new(p1, p2)
    local v = p2 or p1
    if type(v) == "string" then 
        return parse(v)
    end
    if getmetatable(v) == SemVer_meta then return v end
    error("invalid object passed!")
end

setmetatable(SemVer, {__call = SemVer.new}) -- make new object by calling `SemVer`

function SemVer:get_prerelease_str() return table.concat(self.prerelease, ".") end
function SemVer:get_build_str() return table.concat(self.build, ".") end

-- =============================================================================
-- METAMETHODS
-- =============================================================================

-- allow indexing the version numbers by specifing their names
local converters = {
    major = 1, MAJOR = 1, Major = 1,
    minor = 2, MINOR = 2, Minor = 2,
    patch = 3, PATCH = 3, Patch = 3,
}
---@param self herbert.SemVer
---@param k string|integer
function SemVer_meta.__index(self, k)
    local v = rawget(self, converters[k])
    if v ~= nil then return v end
    return SemVer[k]
end

---@param self herbert.SemVer
function SemVer_meta.__tostring(self)
    -- log:info("about to print %s", json.encode(self))
    local strs = {fmt("%s.%s.%s", self[1], self[2], self[3])}
    if #self.prerelease > 0 then
        strs[2] = "-"
        strs[3] = self:get_prerelease_str()
    end
    if #self.build > 0 then
        table.insert(strs, "+")
        table.insert(strs, self:get_build_str())
    end
    return #strs == 1 and strs[1] or table.concat(strs)
end

---@diagnostic disable-next-line: inject-field
function SemVer_meta.__tojson(self)
    return fmt('"%s"', self)
end

---@param v1 string|herbert.SemVer
---@param v2 string|herbert.SemVer
function SemVer_meta.__lt(v1, v2)
    v1, v2 = SemVer(v1), SemVer(v2)
    -- lexigraphical order on major, minor, patch
    for i = 1, 3 do
        if v1[i] ~= v2[i] then return v1[i] < v2[i] end
    end
    -- now check prerelease data
    local v1p, v2p = v1.prerelease, v2.prerelease
    for i = 1, math.min(#v1p, #v2p) do
        local s1, s2 = v1p[i], v2p[i]
        local n1, n2 = tonumber(s1), tonumber(s2)
        
        if n1 ~= n2 then -- at least one of `n1` and `n2` is not `nil`.
            -- if `n1` isn't a number but `n2` is, then `n2 < n1`.
            if n1 == nil then return false end
            if n2 == nil then return true end
            -- otherwise, they are both not `nil`, so compare normally
            return n1 < n2
        end
        -- compare as strings
        if s1 ~= s2 then return s1 < s2 end
    end
    if #v1p ~= #v2p then return #v1p < #v2p end
    return false
end

function SemVer_meta.__le(v1, v2) return not (v2 < v1) end

---@param v1 string|herbert.SemVer
---@param v2 string|herbert.SemVer
function SemVer_meta.__eq(v1, v2)
    v1, v2 = SemVer(v1), SemVer(v2)
    for i = 1, 3 do
        if v1[i] ~= v2[i] then return false end
    end
    local v1p, v2p = v1.prerelease, v2.prerelease
    if #v1p ~= #v2p then return false end -- different amount of prerelease data means not equal
    for i = 1, #v1p do
        if v1p[i] ~= v2p[i] then return false end
    end
    return true
end
-- major versions must match, and then `v1 < v2` for all other data
function SemVer_meta.__pow(v1, v2)
    v1, v2 = SemVer(v1), SemVer(v2)
    return v1[1] == v2[1] and v1 < v2
end

local key_order = {
    "major",
    "minor",
    "patch",
    "prerelease",
    "build"
}

-- ---@param self herbert.SemVer
-- ---@diagnostic disable-next-line: inject-field
-- function SemVer_meta.__pairs(self)
--     return coroutine.wrap(function ()
--         coroutine.yield("major", self[1])
--         coroutine.yield("minor", self[2])
--         coroutine.yield("patch", self[3])
--         coroutine.yield("prerelease", self.prerelease)
--         coroutine.yield("build", self.build)
--     end)
-- end
---@param self herbert.SemVer
---@diagnostic disable-next-line: inject-field
function SemVer_meta.__pairs(self)
    return 
        function(sv, i)
            i = i + 1
            local key = key_order[i]
            if key then
                return key, sv[key]
            end
        end,
        self,
        0
end

return SemVer