local interop = require("mer.RealisticRepair.interop")

local stations = {
    { id = "furn_anvil00", name = "Наковальня", toolIdPattern = "[Мм]олот"  },
    { id = "furn_t_fireplace_01", name = "Кузница", toolIdPattern = "[Кк]лещи"   },
    { id = "furn_de_forge_01", name = "Кузница", toolIdPattern = "[Кк]лещи" },
    { id = "furn_de_bellows_01", name = "Кузница", toolIdPattern = "[Кк]лещи" },
    { id = "Furn_S_forge", name = "Кузница", toolIdPattern = "[Кк]лещи" },
}
for _, newStation in ipairs(stations) do
    interop.addStation(newStation)
end