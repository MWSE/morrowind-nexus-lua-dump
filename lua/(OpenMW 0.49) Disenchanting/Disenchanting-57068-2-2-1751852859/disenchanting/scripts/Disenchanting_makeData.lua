

json = require "jsonStorage"


path = "D:\\"
data = {
(path.."morrowind.json"),
(path.."tribunal.json"),
(path.."bloodmoon.json"),
}
local output = ""
local function print(s)
	output = output..s.."\n"
end
print([[[
  {
    "type": "Header",
    "flags": "",
    "version": 1.3,
    "file_type": "Esp",
    "author": "",
    "description": "",
    "num_objects": 145,
    "masters": [
      [
        "Morrowind.esm",
        80640776
      ],
      [
        "Tribunal.esm",
        6069165
      ],
      [
        "Bloodmoon.esm",
        9797295
      ]
    ]
  },]])



effects = {}
for _, path in pairs(data) do
	esp = json.loadTable(path)
	for a,b in pairs(esp) do
		if b.type:lower() == "magiceffect" then
			effects[b.effect_id] = true
		end
	end
end

local template1 = [[  {
    "type": "Spell",
    "flags": "",
    "id": "]]
	
local template2 = [[",
    "name": "]]
	
local template3 = [[",
    "effects": [
      {
        "magic_effect": "]]
		
local template4 = [[",
        "skill": "]]
		
local template5 = [[",
        "attribute": "]]

local template6 = [[",
        "range": "OnTouch",
        "area": 0,
        "duration": 1,
        "min_magnitude": 1,
        "max_magnitude": 1
      }
    ],
    "data": {
      "spell_type": "Spell",
      "cost": 1,
      "flags": "AUTO_CALCULATE"
    }
  },]]
  


for a in pairs(effects) do
	local id = "enchantdummy_"..a
	local name = "Disenchanted "..a
	if a == "FortifyAttackBonus" then
		id = "enchantdummy_".."FortifyAttack"
		name =  "Disenchanted ".."FortifyAttack"
	end
	local skill = "None"
	local attribute = "None"
	if a:lower():find("skill") then
		skill = "Block"
	end
	if a:lower():find("attribute") then
		attribute = "Agility"
	end
	print(template1..id..template2..name..template3..a..template4..skill..template5..attribute..template6)
end




template11 = [[    "effects": [
      {
        "magic_effect": "FortifySkill",
        "skill": "Enchant",
        "attribute": "None",
        "range": "OnSelf",
        "area": 0,
        "duration": 100,]]
--       "min_magnitude": 1,
--       "max_magnitude": 1
template12 = [[    }
    ],
    "data": {
      "spell_type": "Ability",
      "cost": 1,
      "flags": ""
    }
  },]]
  
  
for i=0, 7 do
	print([[  {
    "type": "Spell",
    "flags": "",
    "name": "Disenchanting Expertise ]]..math.floor(2^i)..[[",
    "id": "disenchanting_expertise_]]..math.floor(2^i)..'",')
	print(template11)
	
	print('        "min_magnitude": '..math.floor(2^i)..',')
	print('        "max_magnitude": '..math.floor(2^i))
	print(template12)
end
output = output:sub(1, -3).."\n"
print("]")
local file = io.open(path.."\\disenchanting.json", "w") 
file:write(output)
file:close()