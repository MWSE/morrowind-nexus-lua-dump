local self                      = require('openmw.self')
local types                     = require('openmw.types')
local core                      = require('openmw.core')
local input                     = require('openmw.input')
local async                     = require('openmw.async')
local ui                        = require('openmw.ui')
local store                     = require('openmw.storage')
local util                      = require('openmw.util')
local I                         = require('openmw.interfaces')
local ambient                   = require('openmw.ambient')
local auxUi                     = require('openmw_aux.ui')
local storage                   = require('openmw.storage')

local settings = storage.playerSection('Settings_Gabber')

local v2 = util.vector2
local rgb = util.color.rgb

function getColorFromGameSettings(colorTag)
	local result = core.getGMST(colorTag)
	if not result then
		return util.color.rgb(1,1,1)
	end
	local rgb = {}
	for color in string.gmatch(result, '(%d+)') do
		table.insert(rgb, tonumber(color))
	end
	if #rgb ~= 3 then
		print("UNEXPECTED COLOR: rgb of size=", #rgb)
		return util.color.rgb(1, 1, 1)
	end
	return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end

function mixColors(color1, color2, mult)
	local mult = mult or 0.5
	return util.color.rgb(color1.r*mult+color2.r*(1-mult), color1.g*mult+color2.g*(1-mult), color1.b*mult+color2.b*(1-mult))
end

function darkenColor(color, mult)
	return util.color.rgb(color.r*mult, color.g*mult, color.b*mult)
end

local function printTable(tab)
  for k,v in ipairs(tab) do
    print(v)
  end
end

local specialOps = {
  ["combat"] = { 
    --Warrior
    ["Combat"] = 1,
    ["Weapons"] = 1,
    ["Armor"] = 1,
    ["Nobility"] = 1,
    ["Strength"] = 1,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["magic"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 1,
    ["History"] = 1,
    ["Mysticism"] = 1,
    ["Necromancy"] = 1,
    ["Books"] = 1,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["stealth"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 1,
    ["Locks"] = 1,
    ["Fortune"] = 1,
    ["Theft"] = 1,
    ["Murder"] = 1,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
}

local attributeOps = {
  ["strength"] = { 
    --Warrior
    ["Combat"] = 1,
    ["Weapons"] = 1,
    ["Armor"] = 1,
    ["Nobility"] = 0,
    ["Strength"] = 2,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 1,
    ["Work"] = 1,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["intelligence"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 1,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 2,
    ["History"] = 2,
    ["Mysticism"] = 0,
    ["Necromancy"] = 1,
    ["Books"] = 2,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 1,
  },
  ["willpower"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 1,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 1, 
    ["Religion"] = 1,
    ["Travel"] = 0,
    ["Piety"] = 1,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["agility"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 2,
    ["Locks"] = 1,
    ["Fortune"] = 0,
    ["Theft"] = 1,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 1,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["speed"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 1,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 2,
    ["Murder"] = 1,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 1,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 1,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 1,
    ["News"] = 1,
  },
  ["endurance"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 1,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 1,
    ["Travel"] = 2,
    ["Piety"] = 1,
    ["Trade"] = 0,
    --Common
    ["Food"] = 2,
    ["Work"] = 1,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["personality"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 2,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 2,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 1,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 1,
    --Common
    ["Food"] = 1,
    ["Work"] = 0,
    ["Gossip"] = 1,
    ["Weather"] = 0,
    ["News"] = 1,
  },
  ["luck"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 1,
    ["Locks"] = 0,
    ["Fortune"] = 1,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 1,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 1,
    ["Travel"] = 0,
    ["Piety"] = 1,
    ["Trade"] = 2,
    --Common
    ["Food"] = 1,
    ["Work"] = 1,
    ["Gossip"] = 1,
    ["Weather"] = 2,
    ["News"] = 1,
  },
}

local skillOps = {
  ["longblade"] = { 
    --Warrior
    ["Combat"] = 1,
    ["Weapons"] = 1,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 1,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["bluntweapon"] = { 
    --Warrior
    ["Combat"] = 1,
    ["Weapons"] = 1,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 1,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["axe"] = { 
    --Warrior
    ["Combat"] = 1,
    ["Weapons"] = 1,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 1,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["armorer"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 1,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 1,
    --Common
    ["Food"] = 0,
    ["Work"] = 1,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["mediumarmor"] = { 
    --Warrior
    ["Combat"] = 1,
    ["Weapons"] = 0,
    ["Armor"] = 1,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["heavyarmor"] = { 
    --Warrior
    ["Combat"] = 1,
    ["Weapons"] = 0,
    ["Armor"] = 1,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["spear"] = { 
    --Warrior
    ["Combat"] = 1,
    ["Weapons"] = 1,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["block"] = { 
    --Warrior
    ["Combat"] = 1,
    ["Weapons"] = 1,
    ["Armor"] = 1,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["athletics"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 1, 
    ["Religion"] = 0,
    ["Travel"] = 2,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 1,
    ["News"] = 1,
  },
  
  ["alchemy"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 1,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 1, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["enchant"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 1,
    ["History"] = 0,
    ["Mysticism"] = 1,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 1,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["conjuration"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 1,
    ["History"] = 0,
    ["Mysticism"] = 1,
    ["Necromancy"] = 1,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["alteration"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 1,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 1,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 1,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 1,
    ["News"] = 0,
  },
  ["destruction"] = { 
    --Warrior
    ["Combat"] = 1,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 1,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["mysticism"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 1,
    ["History"] = 0,
    ["Mysticism"] = 2,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 1, 
    ["Religion"] = 1,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["restoration"] = { 
    --Warrior
    ["Combat"] = -1,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = -2,
    --Mage
    ["Magic"] = 1,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 2, 
    ["Religion"] = 2,
    ["Travel"] = 0,
    ["Piety"] = 1,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["illusion"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 1,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 1,
    ["Murder"] = 1,
    --Mage
    ["Magic"] = 1,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 1,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["unarmored"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 1,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 1,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 1,
    ["Work"] = 1,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },

  ["acrobatics"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 1,
    --Thief
    ["Crime"] = 1,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 1,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 1,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["security"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 2,
    ["Fortune"] = 1,
    ["Theft"] = 1,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["sneak"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 1,
    ["Locks"] = 0,
    ["Fortune"] = 1,
    ["Theft"] = 2,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["lightarmor"] = { 
    --Warrior
    ["Combat"] = 1,
    ["Weapons"] = 0,
    ["Armor"] = 1,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["marksman"] = { 
    --Warrior
    ["Combat"] = 1,
    ["Weapons"] = 1,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 1, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["shortblade"] = { 
    --Warrior
    ["Combat"] = 1,
    ["Weapons"] = 1,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 1,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["handtohand"] = { 
    --Warrior
    ["Combat"] = 1,
    ["Weapons"] = -1,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 1,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 1,
    ["Trade"] = 0,
    --Common
    ["Food"] = 1,
    ["Work"] = 1,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["mercantile"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 1,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = -1,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = -1,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 2,
    --Common
    ["Food"] = 1,
    ["Work"] = 0,
    ["Gossip"] = 1,
    ["Weather"] = 1,
    ["News"] = 1,
  },
  ["speechcraft"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 1,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 1,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 2,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 1,
    ["Travel"] = 1,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 2,
    ["Weather"] = 0,
    ["News"] = 1,
  },
}

local factionOps = {
  ["none"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 1,
    ["Work"] = 1,
    ["Gossip"] = 1,
    ["Weather"] = 1,
    ["News"] = 1,
  },
  ["ashlanders"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 1,
    ["Mysticism"] = 2,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 2, 
    ["Religion"] = 1,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 1,
    ["Work"] = 1,
    ["Gossip"] = 1,
    ["Weather"] = 0,
    ["News"] = 1,
  },
  ["blades"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 2,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 1,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 1,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["camonna tong"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = -2,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 2,
    ["Locks"] = 1,
    ["Fortune"] = 1,
    ["Theft"] = 1,
    ["Murder"] = 1,
    --Mage
    ["Magic"] = 0,
    ["History"] = 1,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 1,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 1,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["east empire company"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 1,
    ["Fortune"] = 2,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 1,
    ["Piety"] = 0,
    ["Trade"] = 2,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["fighters guild"] = { 
    --Warrior
    ["Combat"] = 1,
    ["Weapons"] = 1,
    ["Armor"] = 1,
    ["Nobility"] = 0,
    ["Strength"] = 1,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 1,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["hlaalu"] = { 
    --Warrior
    ["Combat"] = -1,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 1,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = -2,
    ["Locks"] = 1,
    ["Fortune"] = 2,
    ["Theft"] = -2,
    ["Murder"] = -1,
    --Mage
    ["Magic"] = 0,
    ["History"] = 1,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 1,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 2,
    --Common
    ["Food"] = 1,
    ["Work"] = 1,
    ["Gossip"] = 1,
    ["Weather"] = 1,
    ["News"] = 1,
  },
  ["imperial cult"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = -1,
    ["Locks"] = 0,
    ["Fortune"] = -1,
    ["Theft"] = -1,
    ["Murder"] = -2,
    --Mage
    ["Magic"] = 1,
    ["History"] = 1,
    ["Mysticism"] = 1,
    ["Necromancy"] = -1,
    ["Books"] = 1,
    --Priest
    ["Nature"] = 1, 
    ["Religion"] = 3,
    ["Travel"] = 0,
    ["Piety"] = 3,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["imperial knights"] = { 
    --Warrior
    ["Combat"] = 2,
    ["Weapons"] = 1,
    ["Armor"] = 1,
    ["Nobility"] = 2,
    ["Strength"] = 1,
    --Thief
    ["Crime"] = -2,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = -2,
    ["Murder"] = -2,
    --Mage
    ["Magic"] = 0,
    ["History"] = 2,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 1,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 1,
    ["Travel"] = 0,
    ["Piety"] = 1,
    ["Trade"] = 0,
    --Common
    ["Food"] = 1,
    ["Work"] = 0,
    ["Gossip"] = -1,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["imperial legion"] = { 
    --Warrior
    ["Combat"] = 2,
    ["Weapons"] = 1,
    ["Armor"] = 1,
    ["Nobility"] = 0,
    ["Strength"] = 1,
    --Thief
    ["Crime"] = -1,
    ["Locks"] = 0,
    ["Fortune"] = -1,
    ["Theft"] = -1,
    ["Murder"] = -2,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 1,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 1,
    ["Work"] = 1,
    ["Gossip"] = -1,
    ["Weather"] = -1,
    ["News"] = -1,
  },
  ["mages guild"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 2,
    ["History"] = 1,
    ["Mysticism"] = 1,
    ["Necromancy"] = 0,
    ["Books"] = 1,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 1,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["morag tong"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 1,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 3,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 1,
    ["Travel"] = 0,
    ["Piety"] = 1,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 1,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["redoran"] = { 
    --Warrior
    ["Combat"] = 2,
    ["Weapons"] = 1,
    ["Armor"] = 1,
    ["Nobility"] = 3,
    ["Strength"] = 2,
    --Thief
    ["Crime"] = -2,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = -1,
    ["Murder"] = -1,
    --Mage
    ["Magic"] = 0,
    ["History"] = 2,
    ["Mysticism"] = -1,
    ["Necromancy"] = -2,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 1,
    ["Travel"] = 0,
    ["Piety"] = 2,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = -1,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["royal guard"] = { 
    --Warrior
    ["Combat"] = 1,
    ["Weapons"] = 1,
    ["Armor"] = 1,
    ["Nobility"] = 2,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = -4,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = 0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["telvanni"] = { 
    --Warrior
    ["Combat"] = -1,
    ["Weapons"] = -1,
    ["Armor"] = -1,
    ["Nobility"] = -3,
    ["Strength"] = -1,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 1,
    --Mage
    ["Magic"] = 3,
    ["History"] = 1,
    ["Mysticism"] = 2,
    ["Necromancy"] = 2,
    ["Books"] = 2,
    --Priest
    ["Nature"] = 1, 
    ["Religion"] = -1,
    ["Travel"] = -1,
    ["Piety"] = -1,
    ["Trade"] = -1,
    --Common
    ["Food"] = 0,
    ["Work"] = -1,
    ["Gossip"] = 2,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["temple"] = { 
    --Warrior
    ["Combat"] = -1,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 0,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = -2,
    ["Locks"] = 0,
    ["Fortune"] = -1,
    ["Theft"] = -2,
    ["Murder"] = -2,
    --Mage
    ["Magic"] = 1,
    ["History"] = 1,
    ["Mysticism"] = 2,
    ["Necromancy"] = -1,
    ["Books"] = 1,
    --Priest
    ["Nature"] = 1, 
    ["Religion"] = 3,
    ["Travel"] = -1,
    ["Piety"] = 2,
    ["Trade"] = -1,
    --Common
    ["Food"] = 0,
    ["Work"] = 1,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["thieves guild"] = { 
    --Warrior
    ["Combat"] = -1,
    ["Weapons"] = -1,
    ["Armor"] = -1,
    ["Nobility"] = -2,
    ["Strength"] = -1,
    --Thief
    ["Crime"] = 2,
    ["Locks"] = 1,
    ["Fortune"] = 1,
    ["Theft"] = 2,
    ["Murder"] = -2,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = -0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 0,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 1,
    ["Weather"] = 0,
    ["News"] = 1,
  },
  
  ["court_generic"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 2,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 0,
    ["Necromancy"] = -0,
    ["Books"] = 0,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 1,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 2,
    ["Weather"] = 0,
    ["News"] = 0,
  },
  ["scholar_generic"] = { 
    --Warrior
    ["Combat"] = 0,
    ["Weapons"] = 0,
    ["Armor"] = 0,
    ["Nobility"] = 2,
    ["Strength"] = 0,
    --Thief
    ["Crime"] = 0,
    ["Locks"] = 0,
    ["Fortune"] = 0,
    ["Theft"] = 0,
    ["Murder"] = 0,
    --Mage
    ["Magic"] = 0,
    ["History"] = 0,
    ["Mysticism"] = 1,
    ["Necromancy"] = -0,
    ["Books"] = 2,
    --Priest
    ["Nature"] = 0, 
    ["Religion"] = 0,
    ["Travel"] = 1,
    ["Piety"] = 0,
    ["Trade"] = 0,
    --Common
    ["Food"] = 0,
    ["Work"] = 0,
    ["Gossip"] = 0,
    ["Weather"] = 0,
    ["News"] = 1,
  },
}

local altFactions = {
  ["t_cyr_abeceantradingcompany"] = "east empire company",
  ["t_cyr_blades"] = "blades",
  ["t_cyr_darkbrotherhood"] = "morag tong",
  ["t_cyr_fightersguild"] = "fighters guild",
  ["t_cyr_imperialcult"] = "imperial cult",
  ["t_cyr_imperiallegion"] = "imperial legion",
  ["t_cyr_imperialnavy"] = "imperial legion",
  ["t_cyr_itinerantpriests"] = "imperial cult",
  ["t_cyr_kingdomanvil"] = "imperial knights",
  ["t_cyr_magesguild"] = "mages guild",
  ["t_cyr_thievesguild"] = "thieves guild",
  ["t_cyr_vampirumorder"] = "court_generic",
  ["t_glb_archaeologicalsociety"] = "scholar_generic",
  ["t_glb_astrologicalsociety"] = "scholar_generic",
  ["t_ham_crowns"] = "court_generic",
  ["t_mw_eastempirecompany"] = "east empire company",
  ["t_mw_fightersguild"] = "fighters guild",
  ["t_mw_housedres"] = "hlaalu",
  ["t_mw_househlaalu"] = "hlaalu",
  ["t_mw_houseindoril"] = "temple",
  ["t_mw_houseredoran"] = "redoran",
  ["t_mw_housetelvanni"] = "telvanni",
  ["t_mw_imperialcult"] = "imperial cult",
  ["t_mw_imperiallegion"] = "imperial legion",
  ["t_mw_imperialnavy"] = "imperial legion",
  ["t_mw_janattasyndicate"] = "thieves guild",
  ["t_mw_magesguild"] = "mages guild",
  ["t_mw_moragtong"] = "morag tong",
  ["t_mw_shinathi"] = "ashlanders",
  ["t_mw_temple"] = "temple",
  ["t_mw_thievesguild"] = "thieves guild",
  ["t_sky_alovach"] = "ashlanders",
  ["t_sky_hunnath"] = "ashlanders",
  ["t_sky_imperialcult"] = "imperial cult",
  ["t_sky_imperiallegion"] = "imperial legion",
  ["t_sky_imperialnavy"] = "imperial legion",
  ["t_sky_kingdomreach"] = "imperial knights",
  ["t_sky_magesguild"] = "mages guild",
  ["t_sky_nourhthu"] = "ashlanders",
  ["t_sky_pachkan"] = "ashlanders",
  ["t_sky_royalhaafingarcompany"] = "east empire company",
  ["t_sky_taliesinn"] = "ashlanders",
  ["t_sky_thievesguild"] = "thieves guild",
  ["talos cult"] = "imperial cult",
  ["twin lamps"] = "temple",
}

local keywords = {
  --Warrior
  "Combat",
  "Weapons",
  "Armor",
  "Nobility",
  "Strength",
  --Thief
  "Crime",
  "Locks",
  "Fortune",
  "Theft",
  "Murder",
  --Mage
  "Magic",
  "History",
  "Mysticism",
  "Necromancy",
  "Books",
  --Priest
  "Nature", 
  "Religion",
  "Travel",
  "Piety",
  "Trade",
  --Common
  "Food",
  "Work",
  "Gossip",
  "Weather",
  "News",
}

local commPos = {
  "Yes, I agree!",
  "Very interesting.",
  "So I've heard.",
  "Yes, thank you.",
  "Very funny, tell another one!",
  "I\'ll have to remember that.",
  "Oh? Fascinating.",
  "Horrible creatures...",
  "I think I read a book about that.",
  "What a story!",
  "Indeed.",
  "I\'ve heard others say the same.",
}

local commNeg = {
  "I disagree.",
  "I don't like that.",
  "Let\'s talk about something else.",
  "Why would you say that?.",
  "Please stop.",
  "I don\'t know about that.",
  "You\'ve got to be kidding me...",
  "Not what I\'ve heard.",
  "You\'re bluffing!",
  "Not interested.",
  "Is something wrong with you?",
  "Go away.",
}

local commNone = {
  "I have no opinion.",
  "Okay...",
  "Don't know what to say about that.",
  "Never heard of it.",
  "I don\'t think I heard you.",
  "What?",
  "Did you say something?",
  "I don't know anything about that.",
  "I don't hate it.",
  "I wasn't paying attention",
  "I don\'t care",
  "Oh, uh, you too.",
}

local fontNormal = getColorFromGameSettings("FontColor_color_normal")
local fontOver = getColorFromGameSettings("FontColor_color_normal_over")
local fontPressed = getColorFromGameSettings("FontColor_color_normal_pressed")

local fontCount = getColorFromGameSettings("FontColor_color_count")

local fontMagic = getColorFromGameSettings("FontColor_color_magic")
local fontFatigue = getColorFromGameSettings("FontColor_color_fatigue")

local statusNone = "icons/s/b_tx_s_charm.dds"
local statusPos = "icons/s/b_tx_s_ftfy_attrib.dds"
local statusNeg = "icons/s/b_tx_s_dmg_attrib.dds"

local uiOpen = false;

local multiplier = 1;

local function getClassOpinion(keyword)
  
end

local function modDisposition(data)
  local posMult = settings:get("posMult")
  local negMult = settings:get("negMult")
  local critMult = settings:get("critMult")
  local fatigueMult = settings:get("fatigueMult")
  
  local actor,key,amt = data.actor, data.key, data.amt
  
  local record = types.NPC.record(actor)
  
  local name = record.name
  local class = types.NPC.classes.record(record.class)
  
  local spec = class.specialization
  local attributes = class.attributes
  local major = class.majorSkills
  local minor = class.minorSkills
  
  local personality = types.Actor.stats.attributes.personality(self).modified
  local luck = types.Actor.stats.attributes.luck(self).modified
  local speechcraft = math.min(100, types.NPC.stats.skills.speechcraft(self).modified)
  
  local crit = 0
  
  local faction = "none"
  
  if record.primaryFaction then
    faction = core.factions.records[types.NPC.record(actor).primaryFaction].id
  end
  
  if altFactions[faction] then
    faction = altFactions[faction]
  end

  if key ~= "gold" then
    
    --print(faction)
    
    amt = amt + specialOps[spec][key]
    --print(factionOps[faction][key])
    
    amt = amt + factionOps[faction][key]
    --print(factionOps[faction][key])
    
    for k,v in ipairs(attributes) do
      amt = amt + attributeOps[v][key]
      --print(attributeOps[v][key])
    end
    
    for k,v in ipairs(major) do
      amt = amt + skillOps[v][key]
      --print(skillOps[v][key])
    end
    
    for k,v in ipairs(minor) do
      amt = amt + (skillOps[v][key] * 0.5)
      --print(skillOps[v][key])
    end
    
    --print(amt)
    
    amt = math.max(-3, amt)
    amt = math.min(3, amt)
    
  end
  
  --print(personality)
  local modAmt = 0
  
  local modSymbol = "+"
  
  if key == "gold" then
    modAmt = amt
  else
    if amt < 0 then
      modAmt = amt * (math.max(1, 200 - personality + speechcraft) / 200) * negMult
      modSymbol = ""
      multiplier = 1
    elseif amt > 0 then
      modAmt = amt * (math.max(1, personality + speechcraft) / 200) * posMult
      multiplier = multiplier + 0.25
      if math.random(0,200 - personality) < luck then
        crit = 1
        modAmt = modAmt * critMult
      end
    else
      modAmt = 0
      multiplier = 1
    end
  end
  
  core.sendGlobalEvent('GAB_ModDisposition', {self = self, actor = actor, amt = modAmt*multiplier})
  
  local newIcon
  
  if amt > 0 then
    newIcon = statusPos
  elseif amt < 0 then
    newIcon = statusNeg
  else
    newIcon = statusNone
  end
  
  if key ~= "gold" then
  
    local fatigueUse = (110 - speechcraft)*fatigueMult
  
    types.Actor.stats.dynamic.fatigue(self).current = math.max( 0, (types.Actor.stats.dynamic.fatigue(self).current - fatigueUse) )
    
  end
  
  self:sendEvent('GAB_destroyUI', {})
  
  if multiplier > 1 and key ~= "gold" then
    I.SkillProgression.skillUsed("speechcraft", {skillGain = multiplier, useType = 1})
  end
  
  if types.Actor.stats.dynamic.fatigue(self).current > 0 then 
    if modAmt > 0 then
      commList = commPos
    elseif modAmt < 0 then
      commList = commNeg
    else
      commList = commNone
    end
    
    local randIndex = math.floor(math.random(1,#commList))
    
    local newComm = "\"" .. commList[randIndex] .. "\"" .. " "
    
    if modAmt ~= 0 then
      newComm = newComm .. modSymbol .. modAmt
      if multiplier > 1 then
        newComm = newComm .. " x " .. multiplier
        
        if crit == 1 then
          newComm = newComm .. " CRIT"
        end
      end
    end
  
    self:sendEvent('GAB_doPersuasion', {actor = actor, icon = newIcon, comment = newComm})
  else
    I.UI.removeMode('Dialogue')
  end
end

local function doBribe(data)
  local actor, gold = data.actor, data.gold
  
  local playerGoldObj = self.type.inventory(self):find("gold_001")
  local playerGold = 0
  
  if playerGoldObj then
    playerGold = playerGoldObj.count
  end
  
  if playerGold >= gold then
    core.sendGlobalEvent('GAB_payGold', {gold = playerGoldObj, price = gold})

    local mercantile = types.NPC.stats.skills.mercantile(self).modified
    
    local amt = (mercantile/100) * (gold/10) * 2
    
    modDisposition({actor = actor, key = "gold", amt = amt})
    
    ambient.playSound("item gold up", {volume =0.9})
  else
    ambient.playSound("enchant fail", {volume =0.9})
  end
end

local UIMain = {}

local function paddedBox(layout, template)
  return {
    template = template,
    content = ui.content {
      {
        template = I.MWUI.templates.padding,
        content = ui.content { layout },
      },
    }
  }
end

local function inBox(layout, template)
  return {
    template = template,
    content = ui.content {
      layout
    }
  }
end

local function textButton(text, size, sound, func, args)
  local box = ui.create {
    type = ui.TYPE.Container,
    props = {},
    content = ui.content {}
  }
  local flex = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = false,
      size = size,
      align = ui.ALIGNMENT.Center,
      horizontal = true,
    },
    content = ui.content {}
  }
  box.layout.content:add(flex)
  local button = {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      multiline = true,
      text = tostring(text),
      relativePosition = util.vector2(0.5,1),
      textSize = 16,
      textColor = fontNormal,
    },
  }
  flex.events = {
    focusGain = async:callback(function(data, elem)
      button.props.textColor = fontOver    

      if uiOpen then
        box:update()
      end
    end),
    focusLoss = async:callback(function(data, elem)
      button.props.textColor = fontNormal
      if uiOpen then
        box:update()
      end
    end),
    mousePress = async:callback(function(data, elem)
      button.props.textColor = fontPressed
      if uiOpen then
        box:update()
      end
    end),
    mouseRelease = async:callback(function(data, elem)
      button.props.textColor = fontNormal
      ambient.playSound(sound, {volume =0.9})
      
      func(args)
      
      if uiOpen then
        box:update()
      end
    end),
  }
  flex.content:add(button)
  return box
end

local function progressBar(amt, maximum, barSize, barColor)
  local box = ui.create {
    template = I.MWUI.templates.box,
    content = ui.content {}
  }
  
  local barFlex = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = false,
      size = barSize,
      align = ui.ALIGNMENT.Start,
      horizontal = false,
    },
    content = ui.content {}
  }
  box.layout.content:add(barFlex)
  
  local barX = barSize.x * (amt/maximum)
  
  local bar = {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture { path = 'white' },
      tileH = false,
      tileV = false,
      relativePosition = v2(0,0),
      size = v2(barX,barSize.y),
      alpha = 1,
      color = barColor,
    },
  }
  barFlex.content:add(bar)
  
  local textFlex = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = false,
      size = barSize,
      arrange = ui.ALIGNMENT.Center,
      align = ui.ALIGNMENT.Center,
      horizontal = false,
    },
    content = ui.content {}
  }
  box.layout.content:add(textFlex)
  
  local text = {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      multiline = true,
      text = amt .. '/' .. maximum,
      relativePosition = util.vector2(0.5,1),
      textSize = 16,
      textColor = fontCount,
    },
  }
  textFlex.content:add(text)
  
  return box
end

local function doPersuasion(data)

  uiOpen = true
  
  local baseTopics = settings:get("baseTopics")

  local comment = data.comment
  
  local speechcraft = math.min(100, types.NPC.stats.skills.speechcraft(self).modified)

  local numKeys = math.min(5,baseTopics + math.floor(4 * (speechcraft/100)))
  
  --print(math.floor(4 * (speechcraft/100)))
  
  local keywordsTemp = {}
  
  for k,v in ipairs(keywords) do
    table.insert(keywordsTemp, v)
  end

  local numUsedKeys = 0
  local usedKeys = {}
  
  while numUsedKeys < numKeys do
    local newKey = math.floor(math.random(1, #keywordsTemp))
    table.insert(usedKeys, keywordsTemp[newKey])
    table.remove(keywordsTemp, newKey)
    numUsedKeys = numUsedKeys + 1
  end
  
  --printTable(usedKeys)

  local actor = data.actor
  local statusIcon = data.icon

  local record = types.NPC.record(actor)

  local name = record.name
  local disp = types.NPC.getDisposition(actor, self)
  local class = types.NPC.classes.record(record.class).name
  local faction = "None"
  
  if record.primaryFaction then
    faction = core.factions.records[types.NPC.record(actor).primaryFaction].name
  end

  uiMain = ui.create {
    template = I.MWUI.templates.boxSolidThick,
    layer = 'Modal',
    type = ui.TYPE.Container,
    props = {
      anchor = v2(0.5,0.5),
      relativePosition = v2(0.5,0.5),
    },
    content = ui.content {}
  }
  
  uiPadding = ui.create {
    template = I.MWUI.templates.padding,
    type = ui.TYPE.Container,
    props = {},
    content = ui.content {}
  } 
  uiMain.layout.content:add(uiPadding)
  
  local width = 800
  
  local mainFlex = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = true,
      --size = v2(width,600),
      arrange = ui.ALIGNMENT.Center,
      align = ui.ALIGNMENT.Center,
      horizontal = false,
    },
    content = ui.content {}
  }
  uiPadding.layout.content:add(mainFlex)
  
  local spacer = ui.create {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      multiline = false,
      text = " ",
      textSize = 16
    },
  }
  
  local spacerV = ui.create {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      multiline = true,
      text = "\n",
      textSize = 8
    },
  }
  
  local mainFlexH = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = true,
      arrange = ui.ALIGNMENT.Center,
      align = ui.ALIGNMENT.Center,
      horizontal = true,
    },
    content = ui.content {}
  }
  mainFlex.content:add(mainFlexH)
  
  local mainFlexV = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = false,
      size = v2(360,150),
      arrange = ui.ALIGNMENT.Center,
      align = ui.ALIGNMENT.Center,
      horizontal = false,
    },
    content = ui.content {}
  }
  mainFlexH.content:add(paddedBox(mainFlexV, I.MWUI.templates.box))
  
  --INFO
  
  local infoSize = v2(360-8,64)
  
  local infoFlex = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = false,
      size = infoSize,
      arrange = ui.ALIGNMENT.Center,
      align = ui.ALIGNMENT.Center,
      horizontal = true,
    },
    content = ui.content {}
  }
  mainFlexV.content:add(paddedBox(infoFlex, I.MWUI.templates.box))
  
  local infoStats = {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      multiline = true,
      text = "Name: \nFaction: \nClass: ",
      relativePosition = util.vector2(0.5,1),
      textSize = 16,
      textColor = fontNormal,
    },
  }
  infoFlex.content:add(infoStats)
  
  local infoStatsData = {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      multiline = true,
      text = name .. '\n' .. faction .. '\n' .. class,
      relativePosition = util.vector2(0.5,1),
      textSize = 16,
      textColor = fontCount,
    },
  }
  infoFlex.content:add(infoStatsData)
  
  --DISPOSITION
  
  local dispSize = v2(infoSize.x-32-2,32)
  
  local dispFlexV = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = true,
      arrange = ui.ALIGNMENT.Start,
      horizontal = false,
    },
    content = ui.content {}
  }
  mainFlexV.content:add(dispFlexV)
  
  local dispText = {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      multiline = true,
      text = "Disposition:",
      relativePosition = util.vector2(0.5,1),
      textSize = 16,
      textColor = fontCount,
    },
  }
  dispFlexV.content:add(dispText)
  
  local dispFlexH = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = true,
      arrange = ui.ALIGNMENT.Center,
      horizontal = true,
    },
    content = ui.content {}
  }
  dispFlexV.content:add(dispFlexH)
  
  local dispImg = {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture { path = statusIcon },
      tileH = false,
      tileV = false,
      relativePosition = v2(0,0),
      size = v2(dispSize.y,dispSize.y),
      alpha = 1,
      color = rgb(1,1,1),
    },
  }
  
  dispFlexH.content:add(progressBar(disp, 100, dispSize, fontMagic))
  dispFlexH.content:add(spacer)
  dispFlexH.content:add(inBox(dispImg, I.MWUI.templates.box))
  
  mainFlexV.content:add(spacerV)
  
  --COMMENTS
  
  local commSize = v2(360-6,20)
  
  local commBox = ui.create {
    template = I.MWUI.templates.box,
    content = ui.content {}
  }
  mainFlexV.content:add(commBox)
  
  local commFlex = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = false,
      size = commSize,
      arrange = ui.ALIGNMENT.Center,
      align = ui.ALIGNMENT.Center,
      horizontal = true,
    },
    content = ui.content {}
  }
  commBox.layout.content:add(commFlex)
  
  local commText = {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      multiline = true,
      text = comment,
      relativePosition = util.vector2(0.5,1),
      textSize = 16,
      textColor = fontCount,
    },
  }
  commFlex.content:add(commText)
  
  mainFlexV.content:add(spacerV)
  
  --BUTTONS
  
  local buttonSound = "menu click"
  
  local buttonSize = v2(128,18)
  
  local buttonFlex = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = false,
      size = v2(140,150),
      arrange = ui.ALIGNMENT.Start,
      align = ui.ALIGNMENT.Start,
      horizontal = false,
    },
    content = ui.content {}
  }
  mainFlexH.content:add(paddedBox(buttonFlex, I.MWUI.templates.box))
  
  for k,v in ipairs(usedKeys) do
    buttonFlex.content:add(paddedBox(textButton(v, buttonSize, buttonSound, modDisposition, {actor = actor, key = v, amt = -2}), I.MWUI.templates.boxSolidThick))
    buttonFlex.content:add(spacer)
  end
  
  --FATIGUE
  
  mainFlex.content:add(spacerV)
  
  local fatigue = types.Actor.stats.dynamic.fatigue(self)
  --print(fatigue)
  
  local fatSize = v2(238,16)
  
  local fatFlexV = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = true,
      arrange = ui.ALIGNMENT.Start,
      horizontal = false,
    },
    content = ui.content {}
  }
  mainFlex.content:add(fatFlexV)
  
  local fatText = {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      multiline = true,
      text = "Fatigue:",
      relativePosition = util.vector2(0.5,1),
      textSize = 16,
      textColor = fontCount,
    },
  }
  fatFlexV.content:add(fatText)
  
  local fatFlexH = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = true,
      arrange = ui.ALIGNMENT.Center,
      horizontal = true,
    },
    content = ui.content {}
  }
  fatFlexV.content:add(fatFlexH)
  
  fatFlexH.content:add(progressBar(math.floor(fatigue.current), fatigue.base, fatSize, fontFatigue))
  
  mainFlex.content:add(spacerV)
  
  --BRIBE
  
  local bribeText = {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      multiline = true,
      text = "Bribe:",
      relativePosition = util.vector2(0.5,1),
      textSize = 16,
      textColor = fontCount,
    },
  }
  mainFlex.content:add(bribeText)
  
  local bribeFlex = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = true,
      arrange = ui.ALIGNMENT.Center,
      horizontal = true,
    },
    content = ui.content {}
  }
  mainFlex.content:add(paddedBox(bribeFlex, I.MWUI.templates.boxSolid))
  
  local bribeSize = v2(64,18)
  
  bribeFlex.content:add(paddedBox(textButton("10 gp", bribeSize, "", doBribe, {actor = actor, gold = 10}), I.MWUI.templates.boxSolidThick))
  bribeFlex.content:add(spacer)
  bribeFlex.content:add(paddedBox(textButton("100 gp", bribeSize, "",  doBribe, {actor = actor, gold = 100}), I.MWUI.templates.boxSolidThick))
  bribeFlex.content:add(spacer)
  bribeFlex.content:add(paddedBox(textButton("1000 gp", bribeSize, "",  doBribe, {actor = actor, gold = 1000}), I.MWUI.templates.boxSolidThick))
  
  
  local goldFlex = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = true,
      arrange = ui.ALIGNMENT.Start,
      horizontal = true,
    },
    content = ui.content {}
  }
  mainFlex.content:add(goldFlex)
  
  local goldText = {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      multiline = true,
      text = "Gold: ",
      relativePosition = util.vector2(0.5,1),
      textSize = 16,
      textColor = fontCount,
    },
  }
  goldFlex.content:add(goldText)
  
  local playerGoldObj = self.type.inventory(self):find("gold_001")
  local playerGold = 0
  
  if playerGoldObj then
    playerGold = playerGoldObj.count
  end
  
  local goldTextNum = {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      multiline = true,
      text = playerGold .. " gp",
      relativePosition = util.vector2(0.5,1),
      textSize = 16,
      textColor = fontCount,
    },
  }
  goldFlex.content:add(goldTextNum)
end

local function destroyUI()
  if uiOpen and uiMain then
    uiOpen = false
    uiMain:destroy()
    uiMain = {}
  end
end

local function handleResponse(data)
  local actor = data.actor
  local id = core.dialogue[data.type].records[data.recordId].id;
  
  if not (id == "idle") and not (id == "hello") and not string.find(id, "greeting") then
    destroyUI()
    if id == "- talk" then
      doPersuasion({actor = actor, icon = statusNone, comment = "\"...\""})
    end
  end
end

local function handleUiModeChanged(data)
  destroyUI()
end

return {
  engineHandlers = {
    onKeyPress = function(key)
      if key.code == input.KEY.Escape then
        destroyUI()
      end
    end,
      
    onMouseButtonPress = function(key)
      if key == 3 then
        destroyUI()
      end
    end,
  },
  eventHandlers = {
    DialogueResponse = handleResponse,
    UiModeChanged = handleUiModeChanged,
    GAB_doPersuasion = doPersuasion,
    GAB_destroyUI = destroyUI,
  },
}