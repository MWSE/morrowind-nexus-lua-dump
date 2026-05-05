local core                      = require('openmw.core')
local util                      = require('openmw.util')
local content                   = require('openmw.content')

local bookRecords = content.books.records

local enchantRecords = content.enchantments.records

local keyedRecords = {}
print(#enchantRecords)


for k,v in ipairs(bookRecords) do

  local enchantid = v.enchant
  local enchant

  if enchantid then
    enchant = enchantRecords[enchantid]
  end
  
  if enchant then
    --print(enchant)
  end
  
  local name = v.name
  
  local headerpos = string.find(v.name, "Scroll of ")
  
  local headerposalt = string.find(v.name, "Scroll")
  
  if headerpos then
    name = string.sub(v.name, 1, headerpos - 1) .. string.sub(v.name, headerpos + 10)
    
    name = name:gsub("^%l", string.upper)
  elseif headerposalt then
    name = string.sub(v.name, 1, headerposalt -1)
  end
  
  if enchant then
    content.spells.records["sp_" .. enchantid] = {
      name = name,
      type = content.spells.TYPE.Spell,
      cost = 1,
      isAutocalc = true,
      effects = enchant.effects
    }
    print("Spell Processed: " .. "sp_" .. v.id .. " " .. name)
  end
end

