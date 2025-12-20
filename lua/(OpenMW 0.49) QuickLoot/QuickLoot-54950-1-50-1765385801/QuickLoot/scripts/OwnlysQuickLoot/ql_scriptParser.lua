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


local countOnActivateScripts = 0

for _, path in pairs(paths) do
	esp = json.loadTable(path)
	for a,b in pairs(esp) do
		--if b.data then
			local type = b.type:lower()
			if type == "script" then
				--print([..b.id..] = [[..b.text..]],)
				--for c,d in pairs(b) do
				--
				--	print(c,d)
				--end
				if b.text:lower():find("onactivate") then
					countOnActivateScripts=countOnActivateScripts+1
					--print('['..b.id..'] = [['..b.text..']],')
					scripts[b.id] = b.text
					
				end
			elseif b.script and b.script ~= "" then
				if (type == "container" or type == "creature" or type == "npc") then
					containerScripts[b.script] = (containerScripts[b.script] or 0) + 1
				else
					--print(type)
				end
			end
		--end
	end
end


--print("},")
local function canQuickloot(scriptName, scriptText)
    if scriptText then
        local safe, reason = scriptAnalyzer.isSafeToQuickloot(scriptText)
        if not safe then
            -- Log or show why we're not quicklooting
            log(scriptName..": " .. reason)
            return false
        end
    end
    return true
end


local blacklist = {}
local whitelist = {}

local filteredOnActivateScripts = 0
for a,b in pairs(scripts) do
	if containerScripts[a] then
		if not canQuickloot(a,b) then
			blacklist[a] = b
			filteredOnActivateScripts = filteredOnActivateScripts + 1
		else
			whitelist[a] = b
		end
	end
end

print(filteredOnActivateScripts.." / "..countOnActivateScripts.." scripts")
local export = "return {\n"
for a,b in pairs(blacklist) do
	export = export..'["'..a..'"] =  {pass = false, script = [['..b..']]},\n'
	--export = export..'["'..a..'"] = true,\n'
end
for a,b in pairs(whitelist) do
	export = export..'["'..a..'"] = {pass = true, script = [['..b..']]},\n'
	--export = export..'["'..a..'"] = false,\n'
end
export = export .."}"

local file = io.open(path.."ql_script_db.lua", "w") 
file:write(export)
file:close()