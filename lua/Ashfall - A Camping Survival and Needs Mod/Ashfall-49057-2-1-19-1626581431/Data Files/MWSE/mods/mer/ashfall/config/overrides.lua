local staticConfigs = require("mer.Ashfall.config.staticConfigs")
local overrides = {

    --food
    ["ingred_bread_01"] = {
        weight = 0.5,
        value = 10,
    },

    ["food_kwama_egg_01"] = {
        weight = 0.4,
        value = 2,
    },
    ["food_kwama_egg_02"] = {
        weight = 1.0,
        value = 3,
    },
    ["ingred_ash_yam_01"] = {
        weight = 0.5,
        value = 3
    },
    ["ingred_corkbulb_root_01"] = {
        weight = 0.4,
        value = 2
    },
    ["ingred_crab_meat_01"] = { 
        weight = 0.5,
        value = 2
    },
    ["ingred_hound_meat_01"] = {
        weight = 1.0,
        value = 4
    },
    ["ingred_rat_meat_01"] = {
        weight = 1.0,
        value = 2
    },
    ["ingred_scrib_jerky_01"] = {
        weight = 0.5,
        value = 10
    },
    ["ingred_scuttle_01"] = {
        weight = 0.5,
        value = 10,
    },

    --cooking equipment
    ["misc_com_bucket_metal"] = {
        name = "Bucket: Metal",
        value = 15
    },
    ["misc_com_bucket_01"] = {
        name = "Bucket: Wood",
        value = 15
    },
    ["misc_com_iron_ladle"] = {
        weight = 1,
        value = 5
    }
}

--add bottles from bottle data
for id, config in pairs(staticConfigs.bottleList) do
    overrides[id] = config
end

return overrides