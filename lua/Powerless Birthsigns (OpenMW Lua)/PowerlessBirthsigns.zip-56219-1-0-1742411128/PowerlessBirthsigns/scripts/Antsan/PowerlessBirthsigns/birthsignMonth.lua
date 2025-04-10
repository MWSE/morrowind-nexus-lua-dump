local random = require("math").random
local self = require("openmw.self")
local currentMonth = require("scripts.Antsan.PowerlessBirthsigns.currentMonth")

local spells = self.type.spells

local birthSignMonth = {
   -- The Ritual, Morning Star: PB_blessed_touch_month
   ["blessed touch sign"] = 1,
   ["blessed touch sign star-cursed"] = 1,
   -- The Lover, Sun's Dawn: PB_mooncalf_month
   ["mooncalf"] = 2,
   ["mooncalf star-cursed"] = 2,
   -- The Lord, First Seed: PB_trollkin_month
   ["trollkin"] = 3,
   ["trollkin star-cursed"] = 3,
   -- The Mage, Rain's Hand: PB_fay_month
   ["fay"] = 4,
   ["fay star-cursed"] = 4,
   -- The Shadow, Second Seed: PB_moonshadow_month
   ["moonshadow sign"] = 5,
   ["moonshadow sign star-cursed"] = 5,
   -- The Steed, Midyear: PB_charioteer_month
   ["charioteer"] = 6,
   ["charioteer star-cursed"] = 6,
   -- The Apprentice, Sun's Height: PB_elfborn_month
   ["elfborn"] = 7,
   ["elfborn star-cursed"] = 7,
   -- The Warrior, Last Seed: PB_warwyrd_month
   ["warwyrd"] = 8,
   ["warwyrd star-cursed"] = 8,
   -- The Lady, Hearthfire: PB_ladys_favor_month
   ["lady's favor"] = 9,
   ["lady's favor star-cursed"] = 9,
   -- The Tower, Frostfall: PB_beggars_nose_month
   ["beggar's nose"] = 10,
   ["beggar's nose star-cursed"] = 10,
   -- The Atronach, Sun's Dusk: PB_wombburn_month
   ["wombburned"] = 11,
   ["wombburned star-cursed"] = 11,
   -- The Thief, Evening Star: PB_hara_month
   ["hara"] = 12,
   ["hara star-cursed"] = 12,
}

local birthSignAbilities = {
   -- The Ritual, Morning Star: PB_blessed_touch_month
   ["blessed touch sign"] = "PB_blessed_touch_month",
   ["blessed touch sign star-cursed"] = "PB_blessed_touch_month",
   -- The Lover, Sun's Dawn: PB_mooncalf_month
   ["mooncalf"] = "PB_mooncalf_month",
   ["mooncalf star-cursed"] = "PB_mooncalf_month",
   -- The Lord, First Seed: PB_trollkin_month
   ["trollkin"] = "PB_trollkin_month",
   ["trollkin star-cursed"] = "PB_trollkin_month",
   -- The Mage, Rain's Hand: PB_fay_month
   ["fay"] = "PB_fay_month",
   ["fay star-cursed"] = "PB_fay_month",
   -- The Shadow, Second Seed: PB_moonshadow_month
   ["moonshadow sign"] = "PB_moonshadow_month",
   ["moonshadow sign star-cursed"] = "PB_moonshadow_month",
   -- The Steed, Midyear: PB_charioteer_month
   ["charioteer"] = "PB_charioteer_month",
   ["charioteer star-cursed"] = "PB_charioteer_month",
   -- The Apprentice, Sun's Height: PB_elfborn_month
   ["elfborn"] = "PB_elfborn_month",
   ["elfborn star-cursed"] = "PB_elfborn_month",
   -- The Warrior, Last Seed: PB_warwyrd_month
   ["warwyrd"] = "PB_warwyrd_month",
   ["warwyrd star-cursed"] = "PB_warwyrd_month",
   -- The Lady, Hearthfire: PB_ladys_favor_month
   ["lady's favor"] = "PB_ladys_favor_month",
   ["lady's favor star-cursed"] = "PB_ladys_favor_month",
   -- The Tower, Frostfall: PB_beggars_nose_month
   ["beggar's nose"] = "PB_beggars_nose_month",
   ["beggar's nose star-cursed"] = "PB_beggars_nose_month",
   -- The Atronach, Sun's Dusk: PB_wombburn_month
   ["wombburned"] = "PB_wombburn_month",
   ["wombburned star-cursed"] = "PB_wombburn_month",
   -- The Thief, Evening Star: PB_hara_month
   ["hara"] = "PB_hara_month",
   ["hara star-cursed"] = "PB_hara_month",
}

local serpentSigns = {
   ["blessed touch sign star-cursed"] = true,
   ["mooncalf star-cursed"] = true,
   ["trollkin star-cursed"] = true,
   ["fay star-cursed"] = true,
   ["moonshadow sign star-cursed"] = true,
   ["charioteer star-cursed"] = true,
   ["elfborn star-cursed"] = true,
   ["warwyrd star-cursed"] = true,
   ["lady's favor star-cursed"] = true,
   ["beggar's nose star-cursed"] = true,
   ["wombburned star-cursed"] = true,
   ["hara star-cursed"] = true,
}

local serpentAbilities = {
   "PB_serpentine_agility",
   "PB_serpentine_endurance",
   "PB_serpentine_intelligence",
   "PB_serpentine_personality",
   "PB_serpentine_speed",
   "PB_serpentine_strength",
   "PB_serpentine_willpower",
}

local lastMonth = 0
local activeSerpentAbility = false
local activeBirthSignAbility = false

return {
   engineHandlers = {
      onUpdate = function(dt)
         local month = currentMonth()
         local birthSign = self.type.getBirthSign(self)
         if birthSign ~= "" then
            if month ~= lastMonth then
               print("New month!", lastMonth, month)
               local birthMonth = birthSignMonth[birthSign]
               if serpentSigns[birthSign] then
                  if activeSerpentAbility then
                     spells(self):remove(activeSerpentAbility)
                  end
                  local serpentAbility = serpentAbilities[random(7)]
                  spells(self):add(serpentAbility)
                  activeSerpentAbility = serpentAbility
               end
               print(month, birthMonth)
               if month == birthMonth then
                  print("Happy birth month!", activeBirthSignAbility)
                  if not activeBirthSignAbility then
                     print(birthSign)
                     print(birthSignAbilities)
                     local birthSignAbility = birthSignAbilities[birthSign]
                     print("Adding birthsign effect", birthSignAbility)
                     spells(self):add(birthSignAbility)
                     activeBirthSignAbility = birthSignAbility
                  end
               elseif activeBirthSignAbility then
                  spells(self):remove(activeBirthSignAbility)
                  activeBirthSignAbility = false
               end
               lastMonth = month
            end
         end
      end
   }
}
