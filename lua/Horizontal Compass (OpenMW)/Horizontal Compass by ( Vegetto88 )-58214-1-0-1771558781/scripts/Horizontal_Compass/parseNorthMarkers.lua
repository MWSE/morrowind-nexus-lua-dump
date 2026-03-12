json = require "jsonStorage"

path = "D:\\"

local vanillaSuffix = ""

paths = {
	--path.."morrowind"..vanillaSuffix..".json",
	--path.."tribunal"..vanillaSuffix..".json",
	--path.."bloodmoon"..vanillaSuffix..".json",
	--path.."tamriel_data.json",
	--path.."OAAB_Data.json",
	------path.."SpellTomes.json",
	--path.."tr_mainland.json",
	--path.."Starwind Enhanced.json",
	--path.."StarwindRemasteredPatch.json",
	--path.."StarwindRemasteredV1.15.json",
	--path.."tr_factions.json",
	path.."Morrowind Rebirth [Main].json",
	--path.."Cyr_Main.json",
	--path.."Sky_Main.json",
}

local esps = {}

for _, path in pairs(paths) do
	print(path)
	local esp = json.loadTable(path)
	table.insert(esps, esp)
end
--{
--       "mast_index": 0,
--       "refr_index": 24883,
--       "id": "NorthMarker",
--       "temporary": true,
--       "translation": [
--         -17.770737,
--         -147.68979,
--         -47.99994
--       ],
--       "rotation": [
--         0.0,
--         0.0,
--         3.1000001
--       ]
--     }

-- for exporting
local myModHeader
local export = {}
local QE = {}
-- check every esp
for _, esp in pairs(esps) do
	-- for exporting
	if not myModHeader then
		myModHeader = esp[1] --grab a random mod header
		table.insert(export, myModHeader) --put it into our export
	end
	
	-- check all the records of each esp
	for i, record in pairs(esp) do
		local typ = record.type:lower() --lower case type
		
		if typ == "cell" and record.data.flags:lower():find(("IS_INTERIOR"):lower()) then
			
			for _, ref in pairs(record.references) do
				--print(ref.id)
				if ref.id:lower() == "northmarker" then
					QE[record.name:lower()] = ref.rotation[3]
					break
				end
			end
		end
	end
end
for a,b  in pairs(QE) do
	print('["'..a..'"] = '..b..",")
end
---- for exporting
--myModHeader.description = ""
--myModHeader.version = 1.0
--myModHeader.author = ""
--myModHeader.file_type = "Esp"
--myModHeader.num_objects = #export - 1
--
--json.saveTable(export, path.."newPlugin.json", true)