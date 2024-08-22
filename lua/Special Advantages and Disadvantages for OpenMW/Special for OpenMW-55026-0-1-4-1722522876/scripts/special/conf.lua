local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local assert = _tl_compat and _tl_compat.assert or assert; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; maxDifficultyPoints = 50
maxPaddingPoints = 20
maxValidDifficultyPoints = maxDifficultyPoints - maxPaddingPoints
reputationCost = 2

Special = {}






























function Special:new(special)
   assert(special)
   local self = setmetatable(special, { __index = Special })
   return self
end

function Special:copy()
   local copy = Special:new()
   copy.id = self.id
   copy.name = self.name
   copy.group = self.group
   copy.abilityId = self.abilityId
   copy.abilityIdAtNight = self.abilityIdAtNight
   copy.abilityIdWhenOutside = self.abilityIdWhenOutside
   copy.abilityIdWhenInside = self.abilityIdWhenInside
   local phobiaOf = self.phobiaOf
   if type(phobiaOf) == "table" then
      for _, phobia in ipairs(phobiaOf) do
         table.insert(copy.phobiaOf, phobia)
      end
   end
   copy.cost = self.cost
end

advantages = {}
advantagesById = {}
advantagesByAbilityId = {}
disadvantages = {}
disadvantagesById = {}
disadvantagesByAbilityId = {}


function addSpecial(special)
   if special.cost >= 0 then
      table.insert(advantages, special)
      advantagesById[special.id] = special
      if special.abilityId then
         advantagesByAbilityId[special.abilityId] = special
      end
   else
      table.insert(disadvantages, special)
      disadvantagesById[special.id] = special
      if special.abilityId then
         disadvantagesByAbilityId[special.abilityId] = special
      end
   end
end

local function percentageToNounAndGroup(percentage)
   if percentage == 100 then return { 'immunity', 'Resistance' }
   elseif percentage == 75 then return { 'high resistance', 'Resistance' }
   elseif percentage == 50 then return { 'resistance', 'Resistance' }
   elseif percentage == 25 then return { 'low resistance', 'Resistance' }
   elseif percentage == -25 then return { 'small weakness', 'Weakness' }
   elseif percentage == -50 then return { 'weakness', 'Weakness' }
   elseif percentage == -75 then return { 'great weakness', 'Weakness' }
   elseif percentage == -100 then return { 'critical weakness', 'Weakness' }
   else error('Unknown percentage ' .. tostring(percentage))
   end
end

local function firstToUpper(str)
   return (str:gsub("^%l", string.upper))
end

local function spacesToUnderscores(str)
   return (str:gsub(" +", "_"))
end

for _, element in ipairs({ 'fire', 'frost', 'shock', 'poison' }) do
   for absoluteCost, absolutePercentage in pairs({ [40] = 100,
[30] = 75,
[20] = 50,
[10] = 25, }) do
      for cost, percentage in pairs({ [absoluteCost] = absolutePercentage,
[-absoluteCost] = -absolutePercentage, }) do
         local nounAndGroup = percentageToNounAndGroup(percentage)
         local noun = nounAndGroup[1]
         local id = spacesToUnderscores(noun) .. '_to_' .. element
         local abilityId = 'special_' .. id
         local name = firstToUpper(noun) .. ' to ' .. firstToUpper(element)
         local description = tostring(percentage) .. '% ' .. nounAndGroup[2] .. ' to ' .. firstToUpper(element) .. '.'
         local group = { nounAndGroup[2], firstToUpper(element) }
         addSpecial({
            id = id,
            name = name,
            description = description,
            group = group,
            abilityId = abilityId,
            cost = cost,
         })
      end
   end
end

for absoluteCost, absolutePercentage in pairs({ [40] = 75,
[30] = 50,
[20] = 25, }) do
   for cost, percentage in pairs({ [absoluteCost] = absolutePercentage,
[-absoluteCost] = -absolutePercentage, }) do
      local nounAndGroup = percentageToNounAndGroup(percentage)
      local noun = nounAndGroup[1]
      local id = spacesToUnderscores(noun) .. '_to_magicka'
      local abilityId = 'special_' .. id
      local name = firstToUpper(noun) .. ' to magicka'
      local description = tostring(percentage) .. '% ' .. nounAndGroup[2] .. ' to Magicka.'
      local group = { nounAndGroup[2], 'Magicka' }
      addSpecial({
         id = id,
         name = name,
         description = description,
         group = group,
         abilityId = abilityId,
         cost = cost,
      })
   end
end

addSpecial({
   id = 'robust',
   name = 'Robust',
   description = '+10 Endurance.',
   group = { 'Attribute' },
   abilityId = 'special_robust',
   cost = 20,
})

addSpecial({
   id = 'fragile',
   name = 'Fragile',
   description = '-10 Endurance.',
   group = { 'Attribute' },
   abilityId = 'special_fragile',
   cost = -20,
})

addSpecial({
   id = 'strong',
   name = 'Strong',
   description = '+10 Strength.',
   group = { 'Attribute' },
   abilityId = 'special_strong',
   cost = 20,
})

addSpecial({
   id = 'weak',
   name = 'Weak',
   description = '-10 Strength.',
   group = { 'Attribute' },
   abilityId = 'special_weak',
   cost = -20,
})

addSpecial({
   id = 'agile',
   name = 'Agile',
   description = '+10 Agility.',
   group = { 'Attribute' },
   abilityId = 'special_agile',
   cost = 20,
})

addSpecial({
   id = 'Clumsy',
   name = 'Clumsy',
   description = '-10 Agility.',
   group = { 'Attribute' },
   abilityId = 'special_clumsy',
   cost = -20,
})

addSpecial({
   id = 'fast',
   name = 'Fast',
   description = '+10 Speed.',
   group = { 'Attribute' },
   abilityId = 'special_fast',
   cost = 20,
})

addSpecial({
   id = 'slow',
   name = 'Slow',
   description = '-10 Speed.',
   group = { 'Attribute' },
   abilityId = 'special_slow',
   cost = -20,
})

addSpecial({
   id = 'charismatic',
   name = 'Charismatic',
   description = '+10 Charisma.',
   group = { 'Attribute' },
   abilityId = 'special_charismatic',
   cost = 20,
})

addSpecial({
   id = 'uncharismatic',
   name = 'Uncharismatic',
   description = '-10 Charisma.',
   group = { 'Attribute' },
   abilityId = 'special_uncharismatic',
   cost = -20,
})

addSpecial({
   id = 'intelligent',
   name = 'Intelligent',
   description = '+10 Intelligence.',
   group = { 'Attribute' },
   abilityId = 'special_intelligent',
   cost = 20,
})

addSpecial({
   id = 'stupid',
   name = 'Stupid',
   description = '-10 Intelligence.',
   group = { 'Attribute' },
   abilityId = 'special_stupid',
   cost = -20,
})

addSpecial({
   id = 'resolute',
   name = 'Resolute',
   description = '+10 Willpower.',
   group = { 'Attribute' },
   abilityId = 'special_resolute',
   cost = 20,
})

addSpecial({
   id = 'irresolute',
   name = 'Irresolute',
   description = '-10 Willpower.',
   group = { 'Attribute' },
   abilityId = 'special_irresolute',
   cost = -20,
})

addSpecial({
   id = 'lucky',
   name = 'Lucky',
   description = '+10 Luck.',
   group = { 'Attribute' },
   abilityId = 'special_lucky',
   cost = 20,
})

addSpecial({
   id = 'unlucky',
   name = 'Unlucky',
   description = '-10 Luck.',
   group = { 'Attribute' },
   abilityId = 'special_unlucky',
   cost = -20,
})

addSpecial({
   id = 'regenerative',
   name = 'Regenerative',
   description = 'Regenerates 1 health per second.',
   group = { 'Trait' },
   abilityId = 'special_regenerative',
   cost = 20,
})

addSpecial({
   id = 'relentless',
   name = 'Relentless',
   description = 'Regenerates 4 fatigue per second.',
   group = { 'Trait' },
   abilityId = 'special_relentless',
   cost = 20,
})

addSpecial({
   id = 'recharging',
   name = 'Recharging',
   description = 'Regenerates 1 magicka per second.',
   group = { 'Trait' },
   abilityId = 'special_recharging',
   cost = 20,
})

for _, skill in ipairs({ 'Heavy Armor',
'Medium Armor',
'Spear',
'Acrobatics',
'Armorer',
'Axe',
'Blunt Weapon',
'Long Blade',
'Block',
'Light Armor',
'Marksman',
'Sneak',
'Athletic',
'HandToHand',
'Short Blade',
'Unarmored',
'Illusion',
'Mercantile',
'Speechcraft',
'Alchemy',
'Conjuration',
'Enchant',
'Security',
'Alteration',
'Destruction',
'Mysticism',
'Restoration', }) do
   local idPostfix = spacesToUnderscores(skill:lower())

   local id = 'proficient_in_' .. idPostfix
   addSpecial({
      id = id,
      name = 'Proficient in ' .. skill,
      description = skill .. ' +20.',
      group = { 'Proficiency' },
      abilityId = 'special_' .. id,
      cost = 20,
   })

   id = 'inept_at_' .. idPostfix
   addSpecial({
      id = id,
      name = 'Inept at ' .. skill,
      description = skill .. ' -100.',
      group = { 'Ineptness' },
      abilityId = 'special_' .. id,
      cost = -5,
   })
end

addSpecial({
   id = 'shadowborn',
   name = 'Shadowborn',
   description = 'Chameleon 20.',
   group = { 'Trait' },
   abilityId = 'special_shadowborn',
   cost = 20,
})

addSpecial({
   id = 'dodger',
   name = 'Dodger',
   description = 'Sanctuary 20.',
   group = { 'Trait' },
   abilityId = 'special_dodger',
   cost = 20,
})




addSpecial({
   id = 'phobia_of_ash_creatures',
   name = 'Phobia of Ash Creatures',
   description = 'Applies a -20 to all skills whenever close to and looking at an Ash enemy.',
   group = { 'Phobia' },
   phobiaOf = { 'ascended_sleeper', 'dagoth', 'ash', 'corprus' },
   cost = -30,
})


for _, beastAndMatch in ipairs({
      { 'alit', { 'alit' } },
      { 'cliff racer', { 'cliff.*racer' } },
      { 'dreugh', { 'dreugh' } },
      { 'guar', { 'guar' } },
      { 'kagouti', { 'kagouti' } },
      { 'mudcrab', { 'mudcrab' } },
      { 'netch', { 'netch' } },
      { 'nix-hound', { 'nix.*hound' } },
      { 'rat', { 'rat' } },
      { 'shalk', { 'shalk' } },
      { 'slaughterfish', { 'slaughterfish' } },
      { 'kwama', { 'kwama', 'scrib' } },
   }) do
   addSpecial({
      id = 'phobia_of_' .. spacesToUnderscores(beastAndMatch[1]),
      name = 'Phobia of ' .. firstToUpper(beastAndMatch[1]),
      description = 'Applies a -20 to all skills whenever close to and looking at a ' .. beastAndMatch[1] .. '.',
      group = { 'Phobia', 'Beast' },
      phobiaOf = beastAndMatch[2],
      cost = -2,
   })
end


addSpecial({
   id = 'phobia_of_daedra',
   name = 'Phobia of all Daedra',
   description = 'Applies a -20 to all skills whenever close to and looking at a daedra.',
   group = { 'Phobia' },
   phobiaOf = { 'atronach', 'clannfear', 'daedroth', 'dremora', 'golden.*saint', 'hunger', 'ogrim', 'scamp', 'winged.*twilight' },
   cost = -40,
})

for _, daedraAndMatch in ipairs({
      { 'atronach', { 'atronach' } },
      { 'clannfear', { 'clannfear' } },
      { 'daedroth', { 'daedroth' } },
      { 'dremora', { 'dremora' } },
      { 'golden saint', { 'golden.*saint' } },
      { 'hunger', { 'hunger' } },
      { 'ogrim', { 'ogrim' } },
      { 'scamp', { 'scamp' } },
      { 'winged twilight', { 'winged.*twilight' } },
   }) do
   addSpecial({
      id = 'phobia_of_' .. spacesToUnderscores(daedraAndMatch[1]),
      name = 'Phobia of ' .. firstToUpper(daedraAndMatch[1]),
      description = 'Applies a -20 to all skills whenever close to and looking at a ' .. daedraAndMatch[1] .. '.',
      group = { 'Phobia', 'Daedra' },
      phobiaOf = daedraAndMatch[2],
      cost = -5,
   })
end


addSpecial({
   id = 'phobia_of_dwemer_constructs',
   name = 'Phobia of Dwemer Constructs',
   description = 'Applies a -20 to all skills whenever close to and looking at a dwemer construct.',
   group = { 'Phobia' },
   phobiaOf = { 'centurion' },
   cost = -20,
})


addSpecial({
   id = 'phobia_of_ghosts',
   name = 'Phobia of Ghosts',
   description = 'Applies a -20 to all skills whenever close to and looking at a ghost.',
   group = { 'Phobia', 'Undead' },
   phobiaOf = { 'ghost', 'wraith', 'gateway.*haunt', 'ancestor.*guardian', 'ancestor.*wisewoman', 'dahrik.*mezalf' },
   cost = -10,
})

addSpecial({
   id = 'phobia_of_boneundead',
   name = 'Phobia of Bone Undead',
   description = 'Applies a -20 to all skills whenever close to and looking at a bonelord, a bonewalker or any other bone undead.',
   group = { 'Phobia', 'Undead' },
   phobiaOf = { 'bonelord', 'bonewalker', 'wolf.*bone' },
   cost = -10,
})

addSpecial({
   id = 'phobia_of_skeletons',
   name = 'Phobia of Skeletons',
   description = 'Applies a -20 to all skills whenever close to and looking at a skeleton.',
   group = { 'Phobia', 'Undead' },
   phobiaOf = { 'skeleton', 'worm.*lord' },
   cost = -10,
})

addSpecial({
   id = 'phobia_of_liches',
   name = 'Phobia of Liches',
   description = 'Applies a -20 to all skills whenever close to and looking at a lich.',
   group = { 'Phobia', 'Undead' },
   phobiaOf = { 'lich' },
   cost = -10,
})

addSpecial({
   id = 'phobia_of_draugr',
   name = 'Phobia of Draugr',
   description = 'Applies a -20 to all skills whenever close to and looking at a draugr.',
   group = { 'Phobia', 'Undead' },
   phobiaOf = { 'draugr' },
   cost = -10,
})



addSpecial({
   id = 'night_person',
   name = 'Night Person',
   description = '+10 to Agility, Intelligence, Willpower and Charisma at night between 6pm and 6am.',
   group = { 'Trait' },
   abilityIdAtNight = 'special_night_person',
   cost = 10,
})

addSpecial({
   id = 'good_natured',
   name = 'Good Natured',
   description = '-10 to all combat skills and +5 to every other skill. Combat skills are: Spear Axe, BluntWeapon, LongBlade, Marksman, HandToHand, ShortBlade, Mysticism and Destruction.',
   group = { 'Trait' },
   abilityId = 'special_good_natured',
   cost = 0,
})

addSpecial({
   id = 'small_frame',
   name = 'Small Frame',
   description = '+10 to Agility and -10 to Endurance.',
   group = { 'Trait' },
   abilityId = 'special_small_frame',
   cost = 0,
})

addSpecial({
   id = 'claustrophobia',
   name = 'Claustrophobia',
   description = '+10 to all skills when outside and -10 to all skills when not outside.',
   group = { 'Trait' },
   abilityIdWhenInside = 'special_claustrophobia_inside',
   abilityIdWhenOutside = 'special_claustrophobia_outside',
   cost = 0,
})

AdvantagesDisadvantages = {}







function AdvantagesDisadvantages:new()
   local self = setmetatable({}, { __index = AdvantagesDisadvantages })
   self.maxHp = 0
   self.advantages = {}
   self.disadvantages = {}
   self.reputation = {}
   return self
end

function AdvantagesDisadvantages:copy()
   local copy = AdvantagesDisadvantages:new()
   copy.maxHp = self.maxHp
   for _, special in ipairs(self.advantages) do
      table.insert(copy.advantages, special:copy())
   end
   for _, special in ipairs(self.disadvantages) do
      table.insert(copy.disadvantages, special:copy())
   end
   for factionId, reputationModifier in pairs(self.reputation) do
      copy.reputation[factionId] = reputationModifier
   end
end

function AdvantagesDisadvantages:isNotEmpty()
   return self.maxHp ~= 0 or #self.advantages ~= 0 or #self.disadvantages ~= 0
end

function AdvantagesDisadvantages:cost()
   local cost = self.maxHp
   for _, advantage in ipairs(self.advantages) do
      cost = cost + advantage.cost
   end
   for _, disadvantage in ipairs(self.disadvantages) do
      cost = cost + disadvantage.cost
   end
   for _, reputation in pairs(self.reputation) do
      if reputation < 0 then
         cost = cost - reputationCost
      elseif reputation > 0 then
         cost = cost + reputationCost
      end
   end
   return cost
end

function AdvantagesDisadvantages:availableAdvantages()
   local notAvailableAdvantages = {}
   for _, advantage in ipairs(self.advantages) do
      notAvailableAdvantages[advantage.id] = true
   end
   local availableAdvantages = {}
   for _, advantage in ipairs(advantages) do
      if not notAvailableAdvantages[advantage.id] then
         table.insert(availableAdvantages, advantage)
      end
   end
   return availableAdvantages
end

function AdvantagesDisadvantages:availableDisadvantages()
   local notAvailableDisadvantages = {}
   for _, disadvantage in ipairs(self.disadvantages) do
      notAvailableDisadvantages[disadvantage.id] = true
   end
   local availableDisadvantages = {}
   for _, advantage in ipairs(disadvantages) do
      if not notAvailableDisadvantages[advantage.id] then
         table.insert(availableDisadvantages, advantage)
      end
   end
   return availableDisadvantages
end
