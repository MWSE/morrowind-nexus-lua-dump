json = require "jsonStorage"

path = "D:\\"
local scriptAnalyzer = loadfile(path.."ql_scriptAnalyzer.lua")()
paths = {
(path.."morrowind.json"),--
(path.."tribunal.json"),
(path.."bloodmoon.json"),
(path.."tamriel_data.json"),
(path.."tr_mainland.json"),
(path.."tr_factions.json"),
(path.."Morrowind Rebirth [Main].json"),
(path.."Cyr_Main.json"),
}
scripts = {}
containerScripts = {}

items = {}
local types = {}
local i = 0

local function log(...)
    local args = {...}
    local result = ""
    
    for i, v in ipairs(args) do
        if i > 1 then result = result .. "\t" end
        result = result .. tostring(v)
    end
    
    print(result)
end

local containers = {}


local countOnActivateScripts = 0

for _, path in pairs(paths) do
	esp = json.loadTable(path)
	print(path)
	for a,b in pairs(esp) do
		--if b.data then
		
			local typ = b.type:lower()
			if typ == "container" then
				if type(b.container_flags) == "string" and b.container_flags ~="" then
					if (b.container_flags):lower():find("organic") then
						containers[b.id:lower()] = b.inventory
					end
				elseif type(b.container_flags) == "table" then
					for c,d in pairs(b.container_flags) do
						if d~=0 then
							containers[b.id:lower()] = b.inventory
							break
						end
					end
				elseif b.container_flags and b.id:find("rock") then
					containers[b.id:lower()] = b.inventory
				end
				--print([..b.id..] = [[..b.text..]],)
				--for c,d in pairs(b) do
				--
				--	print(c,d)
				--end
			end
		--end
	end
end

for a,b in pairs(containers) do
	if not a:lower():find("flora") then
		log('["'..a..'"] = {')
		for c,d in pairs(b) do
			log('\t{'..d[1]..", "..d[2]..'},')
		end
		log("},")
	end
end


--print(filteredOnActivateScripts.." / "..countOnActivateScripts.." scripts")
--local export = "return {\n"
--for a,b in pairs(blacklist) do
--	export = export..'["'..a..'"] =  {pass = false, script = [['..b..']]},\n'
--	--export = export..'["'..a..'"] = true,\n'
--end
--for a,b in pairs(whitelist) do
--	export = export..'["'..a..'"] = {pass = true, script = [['..b..']]},\n'
--	--export = export..'["'..a..'"] = false,\n'
--end
--export = export .."}"
--
--local file = io.open(path.."ql_script_db.lua", "w") 
--file:write(export)
--file:close()