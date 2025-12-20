local vfs = require("openmw.vfs")
local markup = require('openmw.markup')

require("scripts.MeritsOfService.utils.consts")

local factions = {}

--- Validate faction YAML structure integrity
--- @param data table       Parsed YAML table
--- @return boolean ok
--- @return string|nil err  Error message if invalid
local function validateFile(data)
    -- 1. must have name
    if type(data.name) ~= "string" or data.name == "" then
        return false, "Missing or invalid 'name'"
    end

    local hasAttrs  = type(data.attributes) == "table"
    local hasSkills = type(data.skills) == "table"

    -- 2. must have at least attributes or skills
    if not hasAttrs and not hasSkills then
        return false, "Must define at least 'attributes' or 'skills'"
    end

    -- 3. validate attributes
    if hasAttrs then
        for i, attr in ipairs(data.attributes) do
            if type(attr) ~= "string" then
                return false, ("Invalid attribute type at index %d"):format(i)
            end
            if not AttrNameToHandler[attr] then
                return false, ("Unknown attribute '%s'"):format(attr)
            end
        end
    end

    -- 4. validate skills
    if hasSkills then
        for i, skill in ipairs(data.skills) do
            if type(skill) ~= "string" then
                return false, ("Invalid skill type at index %d"):format(i)
            end
            if not SkillNameToHandler[skill] then
                return false, ("Unknown skill '%s'"):format(skill)
            end
        end
    end

    return true
end

local function parseFactions()
    for fileName in vfs.pathsWithPrefix("MoS_Factions") do
        local file = vfs.open(fileName)
        local faction = markup.decodeYaml(file:read("*all"))
        file:close()

        local validated, reason = validateFile(faction)
        if validated then
            if faction[faction.name] then
                print("Duplicate faction '" .. faction.name .. "' registered")
            end
            factions[faction.name] = {
                attributes = faction.attributes,
                skills = faction.skills
            }
        else
            error("Can't parse the " .. fileName .. ". " .. reason)
        end
    end
end

parseFactions()
return factions
