local Spinner = require("mer.darkShard.components.Spinner")

local spinners = {
    "afq_float_rock_01",
    "afq_float_rock_02",
}

for _, id in ipairs(spinners) do
    Spinner.register(id)
end