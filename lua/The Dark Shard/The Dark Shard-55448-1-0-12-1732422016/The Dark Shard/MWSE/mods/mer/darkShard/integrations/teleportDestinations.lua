local Teleporter = require("mer.darkShard.components.Teleporter")
local destinations = {
    {
        id = "lakeAmaya",
        position = tes3vector3.new(11203, -41310, 10000),
        orientation = tes3vector3.new(0, 0, -0.25),
    }
}

for _, data in ipairs(destinations) do
    Teleporter.registerDestination(data)
end