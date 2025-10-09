json = require "jsonStorage"

path = "D:\\\\"
paths = {
(path.."morrowind.json"), --
(path.."tribunal.json"),
(path.."bloodmoon.json"),
(path.."tamriel_data.json"),
(path.."tr_mainland.json"),
(path.."tr_factions.json"),
--(path.."Morrowind Rebirth [Main].json"),
(path.."Cyr_Main.json"),
}


local esps = {}

for _, path in pairs(paths) do
	print(path)
	local esp = json.loadTable(path)
	table.insert(esps, esp)
end


local books={}

-- create db of all books in the game
for _, esp in pairs(esps) do
	for a,b in pairs(esp) do
		local typ = b.type:lower()
		if typ == "book" then
		--print(b.id)
			books[b.id] = false
		end
	end
end

-- Note what books are referenced by scripts
for _, esp in pairs(esps) do
	for a,b in pairs(esp) do
		local typ = b.type:lower()
		if typ == "script" then
			for c,d in pairs(books) do
				if b.text:find(c) then
					--print(c)
					books[c] = true
				end
			end
		end
	end
end

local occurances = {}

-- Initialize occurances table
for book, bool in pairs(books) do
	if bool then
		occurances[book:lower()] = 0
	end
end

print("count books in all cells...")
for _, esp in pairs(esps) do
	for a,b in pairs(esp) do
		local typ = b.type:lower()
		if typ == "cell" then
			for _, ref in pairs(b.references) do
				if occurances[ref.id:lower()] then
					occurances[ref.id:lower()] = occurances[ref.id:lower()] + 1
				end
			end
		end
		if typ == "container" or typ == "creature" or typ == "npc" then
			for _, ref in pairs(b.inventory) do
				if occurances[ref[2]:lower()] then
					occurances[ref[2]:lower()] = occurances[ref[2]:lower()] + 1
				end
			end
		end
	end
end

for book, count in pairs(occurances) do
	print(book, count)
end
print("-----------------")
print("-----------------")
print("-----------------")
print("-----------------")
print("-----------------")
for book, count in pairs(occurances) do
	if count <= 5 then
		print(book)
	end
end