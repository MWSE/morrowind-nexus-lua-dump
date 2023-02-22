local onion = require("sb_onion.interop")

function startswith(string, start)
    return string.sub(string, 1, string.len(start)) == start
end

local admScarfIDs = {}

-- the scarf slot used by OAAB
local oaabScarf = onion.addSlot {
    id   = "oaab_scarf",
    data = { "Scarf", tes3.activeBodyPart.head }
}

local function initializedCallback(e)
    --- @param object tes3armor
    for _, object in pairs(tes3.dataHandler.nonDynamicData.objects) do
        -- if armor has an ID beginning with "ADMScarf" and has the name "Scarf"
        if (startswith(object.id, "ADMScarf") and object.objectType == tes3.objectType.armor and object.name:find("Scarf")) then
            -- add the armor to our list
            table.insert(admScarfIDs, object.id)
            -- register the armor as a scarf, rigged to the mobile (layer)
            onion.register(
                {
                    id = object.id,
                    slot = oaabScarf
                },
                onion.mode.layer
            )
        end
    end
end

event.register("initialized", initializedCallback, { priority = onion.offsetValue + 1 })
