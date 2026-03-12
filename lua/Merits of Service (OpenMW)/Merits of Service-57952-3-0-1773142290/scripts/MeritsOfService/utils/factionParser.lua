local core = require("openmw.core")

local shortenings = {
    ["Order of Itinerant Priests"] = "Itinerant Priests",
}

local factions = {}

-- populate factions
for _, record in ipairs(core.factions.records) do
    -- dummy faction filter
    if #record.attributes == 2
        and record.attributes[1] == "strength"
        and record.attributes[2] == "strength"
    then
        goto continue
    end

    if record.attributes[1] or record.skills[1] then
        factions[record.name] = {
            attributes = record.attributes or {},
            skills = record.skills or {}
        }

        -- edgecases
        -- duplicating entries just in case mod authors screw up on their end
        if string.find(record.name, "Great House") then
            -- register "house redoran" too
            factions[string.gsub(record.name, "^%S+%s*", "", 1)] = {
                attributes = record.attributes or {},
                skills = record.skills or {}
            }
        elseif shortenings[record.name] then
            factions[shortenings[record.name]] = {
                attributes = record.attributes or {},
                skills = record.skills or {}
            }
        end
    end

    ::continue::
end

return factions
