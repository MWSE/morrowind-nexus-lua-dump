local csv         = require("scripts.MoveObjects.Utility.csv_reader")
local objectTypes = {}
for _, file in ipairs(csv.getCSVTables("build")) do
  for _, subtable in ipairs(file) do
    table.insert(objectTypes, subtable)
  end
end

local function sortByIntCount(a, b)
  return tonumber(a.IntCount) < tonumber(b.IntCount)
end

table.sort(objectTypes, sortByIntCount)
return {
  interfaceName = "moveobjects_data",
  interface = {
    version = 1,
    objectTypes = objectTypes,
  }
}
