local csv         = require("scripts.MoveObjects.Utility.csv_reader")
local objectTypes = {}
for _, file in ipairs(csv.getYAMLTables("shopobjects"),true) do
  for _, subtable in ipairs(file) do
    table.insert(objectTypes, subtable)
  end
end


return {
  interfaceName = "shopobjects_data",
  interface = {
    version = 1,
    objectTypes = objectTypes,
  }
}
