local core = require("openmw.core")
local errors = {}
if core.API_REVISION < 51 then
    table.insert(errors, 'This mod requires OpenMW 0.49.0 or newer')
end
if not core.contentFiles.has("OAAB_Data.esm") then
	table.insert(errors, "OAAB_Data.esm is not installed")
end
if not core.contentFiles.has("Tamriel_Data.esm") then
	table.insert(errors, "Tamriel_Data.esm is not installed")
end
if #errors > 0 then
    print("Abandoned Flat Containers ERROR:")
	for _, err in pairs(errors) do
        print(err)
    end
    error("Abandoned Flat Containers cannot load due to the above error or errors!")
end
