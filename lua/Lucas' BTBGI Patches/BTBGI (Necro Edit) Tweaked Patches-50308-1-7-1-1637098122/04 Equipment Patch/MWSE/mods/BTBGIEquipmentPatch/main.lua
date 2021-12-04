local mod = "BTBGI Equipment Patch"
local version = "1.6"

local data = require("BTBGIEquipmentPatch.data")

local function onInitialized()
    local keys = {
        ["enchCap"] = "enchantCapacity",
        ["armour"] = "armorRating",
        ["health"] = "maxCondition",
		["silver"] = "isSilver",
    }
    -- Iterate through our data table.
    for _, dataObject in ipairs(data.objects) do

        -- Get the corresponding game object.
        local object = tes3.getObject(dataObject.id)

        -- If this object exists in the game, change its stats to match our table.
        -- For each individual stat, if a stat tweak is present, apply it. Else, keep the vanilla value.
        if object then
            for k, v in pairs(dataObject) do
                if v and k ~= "id" then
                    if k == "enchantment" then
                        local enchantment = tes3.getObject(v)
                        if enchantment then
                            object.enchantment = enchantment
                        end
                    else
                        local objectKey = keys[k] or k
                        if object[objectKey] then
                            object[objectKey] = v
                        end
                    end
                end
            end
        end
    end

    mwse.log("[%s %s] Initialized.", mod, version)
end

event.register("initialized", onInitialized)