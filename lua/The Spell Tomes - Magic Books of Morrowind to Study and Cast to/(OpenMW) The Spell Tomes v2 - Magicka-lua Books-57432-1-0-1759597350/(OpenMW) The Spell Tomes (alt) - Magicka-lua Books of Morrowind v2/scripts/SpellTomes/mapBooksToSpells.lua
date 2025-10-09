json = require "jsonStorage"

path = "D:\\\\"

local esp = json.loadTable(path.."SpellTomes.json")

local scripts = {}

-- read spell ids from the scripts
for a,b in pairs(esp) do
	local typ = b.type:lower()
	if typ == "script" then
		local startPos = b.text:find([[AddSpell "]]) + #[[AddSpell "]]
		local endPos = b.text:find([["]],startPos)
		local spellName = b.text:sub(startPos,endPos-1)
		--print(startPos,endPos,spellName)
		scripts[b.id] = spellName
	end
end

-- print those spell ids for each book
for a,b in pairs(esp) do
	local typ = b.type:lower()
	if typ == "book" then
		print('["'..b.id..'"] = "'..scripts[b.script]..'",')
	end
end