local hlib = require("herbert100")

local config = hlib.load_config() ---@type herbert.HLP.config

if type(config.study_outside_inventory) ~= "number" then
    ---@diagnostic disable-next-line: inject-field
    config.study_outside_inventory = 1
end

return config
