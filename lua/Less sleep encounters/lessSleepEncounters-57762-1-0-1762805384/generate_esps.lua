json = require "jsonStorage"

suffix = "TR"

path = "D:\\"
paths = {
	(path.."morrowind.json"),
	(path.."tribunal.json"),
	(path.."bloodmoon.json"),
	(path.."tamriel_data.json"),
	(path.."tr_mainland.json"),
	(path.."tr_factions.json"),
	--(path.."Morrowind Rebirth [Main].json"),
	--(path.."Cyr_Main.json"),
}
local esps = {}

for _, path in pairs(paths) do
	print(path)
	local esp = json.loadTable(path)
	table.insert(esps, esp)
end


local chances ={
50,
33,
25,
20,
15,
10,
5,
0
}

for _, chancePct in pairs(chances) do
export_path = path.."lessSleepEncounters_"..suffix.."_"..chancePct.."%.json"

-- just a function to print stuff more conveniently:
function deepcopy(orig)     local orig_type = type(orig)     local copy     if orig_type == 'table' then         copy = {}         for orig_key, orig_value in next, orig, nil do             copy[deepcopy(orig_key)] = deepcopy(orig_value)         end         setmetatable(copy, deepcopy(getmetatable(orig)))     else         copy = orig     end     return copy end
function replace_extension(filename, old_ext, new_ext)     local pattern = old_ext:gsub("(%a)", function(c)          return "[" .. c:lower() .. c:upper() .. "]"      end)     return filename:gsub(pattern .. "$", new_ext) end
function convert(input_file, prefer_omwaddon)     local lower = input_file:lower()     local output_file          if lower:match("%.esp$") then         output_file = replace_extension(input_file, "%.esp", ".json")     elseif lower:match("%.omwaddon$") then         output_file = replace_extension(input_file, "%.omwaddon", ".json")     elseif lower:match("%.json$") then         local ext = prefer_omwaddon and ".omwaddon" or ".esp"         output_file = replace_extension(input_file, "%.json", ext)     else         print("Error: File must be .esp, .omwaddon, or .json")         return false     end          local cmd = string.format('D:\\tes3conv.exe "%s" "%s"', input_file, output_file)     print("Converting: " .. input_file .. " -> " .. output_file)          return os.execute(cmd) end



-- for exporting
local myModHeader
local export = {}
local blacklist = {
	["T_Sky_Cr_Icewraith"] = true,
}
local sleepScripts = {}

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
		
		if typ == "region" and record.sleep_creature then
			--print(record.id, typ)
			sleepScripts[record.sleep_creature] = true
		end
	end
end

for _, esp in pairs(esps) do
	-- for exporting
	if not myModHeader then
		myModHeader = esp[1] --grab a random mod header
		table.insert(export, myModHeader) --put it into our export
	end
	
	-- check all the records of each esp
	for i, record in pairs(esp) do
		local typ = record.type:lower() --lower case type
		
		if sleepScripts[record.id] and typ == "leveledcreature" and not blacklist[record.id] then
			local record = deepcopy(record)
			--print(record.id, typ)
			record.chance_none = record.chance_none or 0
			local newChance = 100 -math.floor((100-record.chance_none)*chancePct/100)
			print(record.id, tostring(record.chance_none), "->", newChance)
			if record.chance_none <= 90 or newChance == 0 then
				record.chance_none = newChance
			end
			table.insert(export, record)
		end
	end
end





-- for exporting
myModHeader.description = ""
myModHeader.version = 1.0
myModHeader.author = "Ownly"
myModHeader.file_type = "Esp"
myModHeader.num_objects = #export - 1

json.saveTable(export, export_path, true)

convert(export_path, false)

end