local interop = require("mer.RealisticRepair.interop")

local stations = {
    { id = "furn_anvil00", name = "Anvil", toolIdPattern = "hammer"  },
    { id = "furn_t_fireplace_01", name = "Forge", toolIdPattern = "prong"   },
    { id = "furn_de_forge_01", name = "Forge", toolIdPattern = "prong" },
    { id = "furn_de_bellows_01", name = "Forge", toolIdPattern = "prong" },
    { id = "Furn_S_forge", name = "Forge", toolIdPattern = "prong" },
}
for _, newStation in ipairs(stations) do
    interop.addStation(newStation)
end