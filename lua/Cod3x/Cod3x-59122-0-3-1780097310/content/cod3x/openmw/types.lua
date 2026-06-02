---@meta

-- This file was mechanically drafted from files/lua_api/openmw/types.lua.
-- It uses LuaLS/LLS annotations and stub bodies only; runtime behavior is provided by OpenMW.
-- OpenMW script contexts: global|local|player

---Defines functions for specific types of game objects.
---@class openmw.types
local types = {}

---@alias openmw.types.RecordList<T> table<integer|string, T|nil>

---@class openmw.types.RecordDraft<T>
---@field template? T Base record to copy defaults from.
local RecordDraft = {}

---@class openmw.types.BirthSigns
local BirthSigns = {}

---@class openmw.types.Classes
local Classes = {}

---@class openmw.types.Lockable
local Lockable = {}

---@class openmw.types.PlayerJournal
local PlayerJournal = {}

---@class openmw.types.Races
local Races = {}


---Common functions for Creature, NPC, and Player.
---@class openmw.types.Actor
local Actor = {}

---@class openmw.types.EQUIPMENT_SLOT
---@field Helmet number
---@field Cuirass number
---@field Greaves number
---@field LeftPauldron number
---@field RightPauldron number
---@field LeftGauntlet number
---@field RightGauntlet number
---@field Boots number
---@field Shirt number
---@field Pants number
---@field Skirt number
---@field Robe number
---@field LeftRing number
---@field RightRing number
---@field Amulet number
---@field Belt number
---@field CarriedRight number
---@field CarriedLeft number
---@field Ammunition number
local EQUIPMENT_SLOT = {}

---@class openmw.types.STANCE
---@field Nothing number Default stance
---@field Weapon number Weapon stance
---@field Spell number Magic stance
local STANCE = {}

---Map from values of EQUIPMENT_SLOT to items openmw.Object
---@class openmw.types.EquipmentTable: table<number, openmw.Object>
local EquipmentTable = {}

---Read-only list of effects currently affecting the actor.
---for _, effect in pairs(Actor.activeEffects(self)) do
---end
---local effect = Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.Telekinesis)
---if effect.magnitude ~= 0 then
---else
---end
---local effect = Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.FortifyAttribute, 'luck')
---if effect.magnitude ~= 0 then
---else
---end
---@class openmw.types.ActorActiveEffects
local ActorActiveEffects = {}

---Read-only list of spells currently affecting the actor. Can be iterated over for a list of openmw.core.ActiveSpell
---for _, spell in pairs(Actor.activeSpells(self)) do
---end
---if Actor.activeSpells(self):isSpellActive('bound longbow') then
---else
---end
---for id, params in pairs(Actor.activeSpells(self)) do
---end
---@class openmw.types.ActorActiveSpells
local ActorActiveSpells = {}

---@class openmw.types.ActiveSpellAddOptions
---@field id openmw.core.Spell|openmw.Object|openmw.types.IngredientRecord|openmw.types.PotionRecord|string A record or string record ID. Valid records are openmw.core.Spell, enchanted Item, IngredientRecord, or PotionRecord.
---@field effects integer[] Indexes of the effects to apply.
---@field name? string Name to show in the active effects UI. Defaults to the source record name.
---@field ignoreResistances? boolean If true, resistances will be ignored. Default: false.
---@field ignoreSpellAbsorption? boolean If true, spell absorption will not be applied. Default: false.
---@field ignoreReflect? boolean If true, reflects will not be applied. Default: false.
---@field caster? openmw.Object Game object that identifies the caster.
---@field item? openmw.Object Game object that identifies the specific enchanted item instance used to cast the spell.
---@field stackable? boolean If true, the spell will be able to stack.
---@field quiet? boolean If true, no messages will be printed if an Ingredient spell had no effect. Always true if the target is not the player.
local ActiveSpellAddOptions = {}

---List of spells (modifications are only allowed in global scripts or on self).
---local mySpells = types.Actor.spells(self)
---for _, spell in pairs(mySpells) do print(spell.id) end
---local mySpells = types.Actor.spells(self)
---for i = 1, #mySpells do print(mySpells[i].id) end
---local mySpells = types.Actor.spells(self)
---for _, spell in pairs(core.magic.spells.records) do
---end
---types.Actor.spells(self):add('thunder fist')
---local mySpells = types.Actor.spells(self)
---if mySpells['thunder fist'] then print('I have thunder fist') end
---@class openmw.types.ActorSpells
local ActorSpells = {}

---Values affect how much each attribute can be increased at level up, and are all reset to 0 upon level up.
---@class openmw.types.SkillIncreasesForAttributeStats
---@field agility number|nil Number of contributions to agility for the next level up.
---@field endurance number|nil Number of contributions to endurance for the next level up.
---@field intelligence number|nil Number of contributions to intelligence for the next level up.
---@field luck number|nil Number of contributions to luck for the next level up.
---@field personality number|nil Number of contributions to personality for the next level up.
---@field speed number|nil Number of contributions to speed for the next level up.
---@field strength number|nil Number of contributions to strength for the next level up.
---@field willpower number|nil Number of contributions to willpower for the next level up.
local SkillIncreasesForAttributeStats = {}

---Values affect the graphic used on the level up screen, and are all reset to 0 upon level up.
---@class openmw.types.SkillIncreasesForSpecializationStats
---@field combat number|nil Number of contributions to combat specialization for the next level up.
---@field magic number|nil Number of contributions to magic specialization for the next level up.
---@field stealth number|nil Number of contributions to stealth specialization for the next level up.
local SkillIncreasesForSpecializationStats = {}

---Value modification is delayed. Stat proxy setters are only valid for proxies obtained from `openmw.self`.
---@class openmw.types.LevelStat
---@field current number The actor's current level.
---@field progress number|nil The NPC's level progress.
---@field skillIncreasesForAttribute openmw.types.SkillIncreasesForAttributeStats|nil The NPC's attribute contributions towards the next level up. Values affect how much each attribute can be increased at level up.
---@field skillIncreasesForSpecialization openmw.types.SkillIncreasesForSpecializationStats|nil The NPC's attribute contributions towards the next level up. Values affect the graphic used on the level up screen.
local LevelStat = {}

---Value modification is delayed. Stat proxy setters are only valid for proxies obtained from `openmw.self`.
---@class openmw.types.DynamicStat
---@field base number
---@field current number
---@field modifier number
local DynamicStat = {}

---Value modification is delayed. Stat proxy setters are only valid for proxies obtained from `openmw.self`.
---@class openmw.types.AttributeStat
---@field base number The actor's base attribute value.
---@field damage number The amount the attribute has been damaged.
---@field modified number The actor's current attribute value (read-only.)
---@field modifier number The attribute's modifier.
local AttributeStat = {}

---Value modification is delayed. Stat proxy setters are only valid for proxies obtained from `openmw.self`.
---@class openmw.types.SkillStat
---@field base number The NPC's base skill value.
---@field damage number The amount the skill has been damaged.
---@field modified number The NPC's current skill value (read-only.)
---@field modifier number The skill's modifier.
---@field progress number [0-1] The NPC's skill progress.
local SkillStat = {}

---Value modification is delayed. Stat proxy setters are only valid for proxies obtained from `openmw.self`.
---@class openmw.types.AIStat
---@field base number The stat's base value.
---@field modifier number The stat's modifier.
---@field modified number The actor's current ai value (read-only.)
local AIStat = {}

---Value modification is delayed. Stat proxy setters are only valid for proxies obtained from `openmw.self`.
---@class openmw.types.ReputationStat
---@field current number Current reputation value.
local ReputationStat = {}

---@class openmw.types.DynamicStats
local DynamicStats = {}

---@class openmw.types.AIStats
local AIStats = {}

---@class openmw.types.AttributeStats
local AttributeStats = {}

---@class openmw.types.SkillStats
local SkillStats = {}

---@class openmw.types.ActorStats
---@field dynamic openmw.types.DynamicStats
---@field attributes openmw.types.AttributeStats
---@field ai openmw.types.AIStats
local ActorStats = {}

---@class openmw.types.NpcStats: openmw.types.ActorStats
---@field skills openmw.types.SkillStats
local NpcStats = {}

---@param actor openmw.Object
---@return openmw.types.ReputationStat|nil
function NpcStats.reputation(actor) end

---Functions for items that can be placed to an inventory or container
---@class openmw.types.Item
local Item = {}

---@class openmw.types.ItemData
---@field condition number|nil The item's current condition. Time remaining for lights (setting this to `-1` will make it last forever). Uses left for repairs, lockpicks and probes. Current health for weapons and armor. Can be `nil` for items without condition. Can only be changed from global scripts or on self.
---@field enchantmentCharge number|nil The item's current enchantment charge. Unenchanted items will always return a value of `nil`. Setting this to `nil` will reset the charge of the item. Can only be changed from global scripts or on self.
---@field soul string|nil The recordId of the item's current soul. Items without soul will always return a value of `nil`. Setting this to `nil` will remove the soul from the item. Can only be changed from global scripts or on self.
local ItemData = {}

---@class openmw.types.Creature: openmw.types.Actor
---@field baseType openmw.types.Actor Actor
local Creature = {}

---Creature.TYPE
---@class openmw.types.CreatureTYPE
---@field Creatures number
---@field Daedra number
---@field Undead number
---@field Humanoid number
local CreatureTYPE = {}

---@class openmw.types.CreatureAttack
---@field minDamage number Minimum attack damage.
---@field maxDamage number Maximum attack damage.
local CreatureAttack = {}

---@class openmw.types.CreatureRecord
---@field id string The record ID of the creature
---@field name string
---@field baseCreature string Record id of a base creature, which was modified to create this one
---@field model string VFS path to the creature's model
---@field mwscript string|nil MWScript on this creature (can be nil)
---@field soulValue number The soul value of the creature record
---@field type number The Creature.TYPE of the creature
---@field baseGold number The base barter gold of the creature
---@field combatSkill number The base combat skill of the creature. This is the skill value used for all skills with a 'combat' specialization
---@field magicSkill number The base magic skill of the creature. This is the skill value used for all skills with a 'magic' specialization
---@field stealthSkill number The base stealth skill of the creature. This is the skill value used for all skills with a 'stealth' specialization
---@field attack number[] A table of the 3 randomly selected attacks used by creatures that do not carry weapons. The table consists of 6 numbers split into groups of 2 values corresponding to minimum and maximum damage in that order.
---@field servicesOffered table<string, boolean> The services of the creature, in a table. Value is if the service is provided or not, and they are indexed by: Spells, Spellmaking, Enchanting, Training, Repair, Barter, Weapon, Armor, Clothing, Books, Ingredients, Picks, Probes, Lights, Apparatus, RepairItems, Misc, Potions, MagicItems, Travel.
---@field travelDestinations openmw.types.TravelDestination[] A list of TravelDestinations for this creature.
---@field canFly boolean whether the creature can fly
---@field canSwim boolean whether the creature can swim
---@field canWalk boolean whether the creature can walk
---@field canUseWeapons boolean whether the creature can use weapons and shields
---@field isBiped boolean whether the creature is a biped
---@field isAutocalc boolean If true, the actor's stats will be automatically calculated based on level and class.
---@field primaryFaction string|nil Faction ID of the NPCs default faction. Nil if no faction
---@field primaryFactionRank number|nil Faction rank of the NPCs default faction. Nil if no faction
---@field isEssential boolean whether the creature is essential
---@field isRespawning boolean whether the creature respawns after death
---@field bloodType number integer representing the blood type of the Creature. Used to generate the correct blood vfx.
local CreatureRecord = {}

---@class openmw.types.NPC: openmw.types.Actor
---@field baseType openmw.types.Actor Actor
---@field stats openmw.types.NpcStats
local NPC = {}

---Class data record
---@class openmw.types.ClassRecord
---@field id string Class id
---@field name string Class name
---@field attributes string[] A read-only list containing the specialized attributes of the class.
---@field majorSkills string[] A read-only list containing the major skills of the class.
---@field minorSkills string[] A read-only list containing the minor skills of the class.
---@field description string Class description
---@field isPlayable boolean True if the player can play as this class
---@field specialization string Class specialization. Either combat, magic, or stealth.
local ClassRecord = {}

---Race data record
---strength = types.NPC.races.records[1].attributes.strength.male
---@class openmw.types.RaceRecord
---@field id string Race id
---@field name string Race name
---@field description string Race description
---@field skills table<string, number> A map of bonus skill points by skill ID
---@field spells string[] A read-only list containing the ids of all spells inherent to the race
---@field isPlayable boolean True if the player can pick this race in character generation
---@field isBeast boolean True if this race is a beast race
---@field height openmw.types.GenderedNumber Height values
---@field weight openmw.types.GenderedNumber Weight values
---@field attributes table<string, openmw.types.GenderedNumber> A read-only table of attribute ID to base value
local RaceRecord = {}

---@class openmw.types.GenderedNumber
---@field male number Male value
---@field female number Female value
local GenderedNumber = {}

---@class openmw.types.NpcRecord
---@field id string The record ID of the NPC
---@field name string
---@field race string
---@field class string ID of the NPC's class (e.g. acrobat)
---@field model string Path to the model associated with this NPC, used for animations.
---@field mwscript string|nil MWScript on this NPC (can be nil)
---@field hair string ID of the hair body part
---@field head string ID of the head body part
---@field baseGold number The base barter gold of the NPC
---@field baseDisposition number NPC's starting disposition
---@field isMale boolean The gender setting of the NPC
---@field servicesOffered table<string, boolean> The services of the NPC, in a table. Value is if the service is provided or not, and they are indexed by: Spells, Spellmaking, Enchanting, Training, Repair, Barter, Weapon, Armor, Clothing, Books, Ingredients, Picks, Probes, Lights, Apparatus, RepairItems, Misc, Potions, MagicItems, Travel.
---@field travelDestinations openmw.types.TravelDestination[] A list of TravelDestinations for this NPC.
---@field isEssential boolean whether the NPC is essential
---@field isRespawning boolean whether the NPC respawns after death
---@field isAutocalc boolean If true, the actor's stats will be automatically calculated based on level and class.
---@field bloodType number integer representing the blood type of the NPC. Used to generate the correct blood vfx.
local NpcRecord = {}

---@class openmw.types.TravelDestination
---@field cellId string ID of the Destination cell for this TravelDestination, Can be used with openmw.world.getCellById.
---@field position openmw.util.Vector3 Destination position for this TravelDestination.
---@field rotation openmw.util.Transform Destination rotation for this TravelDestination.
local TravelDestination = {}

---@class openmw.types.Player: openmw.types.NPC
---@field baseType openmw.types.NPC NPC
local Player = {}

---@class openmw.types.OFFENSE_TYPE_IDS
---@field Theft number
---@field Assault number
---@field Murder number
---@field Trespassing number
---@field SleepingInOwnedBed number
---@field Pickpocket number
local OFFENSE_TYPE_IDS = {}

---@class openmw.types.PlayerJournalTopic
---@field id string Topic id. It's a lowercase version of name.
---@field name string Topic name. Same as id, but with upper cases preserved.
local PlayerJournalTopic = {}

---@class openmw.types.PlayerJournalTopicEntry
---@field text string Text of this topic line.
---@field actor string Name of an NPC who is recorded in the player journal as an origin of this topic line.
local PlayerJournalTopicEntry = {}

---@class openmw.types.PlayerJournalTextEntry
---@field text string Text of this journal entry.
---@field questId string|nil Quest id this journal entry is associated with. Can be nil if there is no quest associated with this entry or if journal quest sorting functionality is not available in game.
---@field day number Number of the day this journal entry was written at.
---@field month number Number of the month this journal entry was written at.
---@field dayOfMonth number Number of the day in the month this journal entry was written at.
local PlayerJournalTextEntry = {}

---@class openmw.types.PlayerQuest
---@field id string The quest id.
---@field stage number The quest stage (global and player scripts can change it). Changing the stage starts the quest if it wasn't started.
---@field started boolean Whether the quest is started.
---@field finished boolean Whether the quest is finished (global and player scripts can change it).
local PlayerQuest = {}

---String id of a CONTROL_SWITCH
---@class openmw.types.ControlSwitch
local ControlSwitch = {}

---@class openmw.types.CONTROL_SWITCH
---@field Controls openmw.types.ControlSwitch Ability to move
---@field Fighting openmw.types.ControlSwitch Ability to attack
---@field Jumping openmw.types.ControlSwitch Ability to jump
---@field Looking openmw.types.ControlSwitch Ability to change view direction
---@field Magic openmw.types.ControlSwitch Ability to use magic
---@field ViewMode openmw.types.ControlSwitch Ability to toggle 1st/3rd person view
---@field VanityMode openmw.types.ControlSwitch Vanity view if player doesn't touch controls for a long time
local CONTROL_SWITCH = {}

---Birth sign data record
---@class openmw.types.BirthSignRecord
---@field id string Birth sign id
---@field name string Birth sign name
---@field description string Birth sign description
---@field texture string Birth sign texture
---@field spells string[] A read-only list containing the ids of all spells gained from this sign.
local BirthSignRecord = {}

---@class openmw.types.Armor: openmw.types.Item
---@field baseType openmw.types.Item Item
local Armor = {}

---Armor.TYPE
---@class openmw.types.ArmorTYPE
---@field Helmet number
---@field Cuirass number
---@field LPauldron number
---@field RPauldron number
---@field Greaves number
---@field Boots number
---@field LGauntlet number
---@field RGauntlet number
---@field Shield number
---@field LBracer number
---@field RBracer number
local ArmorTYPE = {}

---@class openmw.types.ArmorRecord
---@field id string Record id
---@field name string Human-readable name
---@field model string VFS path to the model
---@field mwscript string|nil MWScript on this armor (can be nil)
---@field icon string VFS path to the icon
---@field enchant string|nil The enchantment ID of this armor (can be nil)
---@field weight number
---@field value number
---@field type number See Armor.TYPE
---@field health number
---@field baseArmor number The base armor rating of this armor
---@field enchantCapacity number
local ArmorRecord = {}

---@class openmw.types.BodyPart
local BodyPart = {}

---@class openmw.types.BodyPartRecord
---@field id string The record ID of the body part
---@field race string The id of the race of the body part
---@field model string VFS path to the model
---@field isFemale boolean Whether the body part only applies to female characters
---@field isPlayable boolean Whether the player can choose this part
---@field isVampire boolean Whether this body part is meant for vampires
---@field type string `armor`, `clothing`, or `skin`
local BodyPartRecord = {}

---@class openmw.types.Book: openmw.types.Item
---@field baseType openmw.types.Item Item
local Book = {}

---Book.SKILL
---@class openmw.types.BookSKILL
---@field acrobatics string "acrobatics"
---@field alchemy string "alchemy"
---@field alteration string "alteration"
---@field armorer string "armorer"
---@field athletics string "athletics"
---@field axe string "axe"
---@field block string "block"
---@field bluntWeapon string "bluntweapon"
---@field conjuration string "conjuration"
---@field destruction string "destruction"
---@field enchant string "enchant"
---@field handToHand string "handtohand"
---@field heavyArmor string "heavyarmor"
---@field illusion string "illusion"
---@field lightArmor string "lightarmor"
---@field longBlade string "longblade"
---@field marksman string "marksman"
---@field mediumArmor string "mediumarmor"
---@field mercantile string "mercantile"
---@field mysticism string "mysticism"
---@field restoration string "restoration"
---@field security string "security"
---@field shortBlade string "shortblade"
---@field sneak string "sneak"
---@field spear string "spear"
---@field speechcraft string "speechcraft"
---@field unarmored string "unarmored"
local BookSKILL = {}

---@class openmw.types.BookRecord
---@field id string The record ID of the book
---@field name string Name of the book
---@field model string VFS path to the model
---@field mwscript string|nil MWScript on this book (can be nil)
---@field icon string VFS path to the icon
---@field enchant string|nil The enchantment ID of this book (can be nil)
---@field text string The text content of the book
---@field weight number
---@field value number
---@field skill string The skill that this book teaches. See openmw.core.SKILL
---@field isScroll boolean
---@field enchantCapacity number
local BookRecord = {}

---@class openmw.types.Clothing: openmw.types.Item
---@field baseType openmw.types.Item Item
local Clothing = {}

---Clothing.TYPE
---@class openmw.types.ClothingTYPE
---@field Amulet number
---@field Belt number
---@field LGlove number
---@field Pants number
---@field RGlove number
---@field Ring number
---@field Robe number
---@field Shirt number
---@field Shoes number
---@field Skirt number
local ClothingTYPE = {}

---@class openmw.types.ClothingRecord
---@field id string Record id
---@field name string Name of the clothing
---@field model string VFS path to the model
---@field mwscript string|nil MWScript on this clothing (can be nil)
---@field icon string VFS path to the icon
---@field enchant string|nil The enchantment ID of this clothing (can be nil)
---@field weight number
---@field value number
---@field type number See Clothing.TYPE
---@field enchantCapacity number
local ClothingRecord = {}

---@class openmw.types.Ingredient: openmw.types.Item
---@field baseType openmw.types.Item Item
local Ingredient = {}

---@class openmw.types.IngredientRecord
---@field id string Record id
---@field name string Human-readable name
---@field model string VFS path to the model
---@field mwscript string|nil MWScript on this potion (can be nil)
---@field icon string VFS path to the icon
---@field weight number
---@field value number
---@field effects openmw.core.MagicEffectWithParams[] The ingredient effects.
local IngredientRecord = {}

---@class openmw.types.Light: openmw.types.Item
---@field baseType openmw.types.Item Item
local Light = {}

---@class openmw.types.LightRecord
---@field id string Record id
---@field name string Human-readable name
---@field model string VFS path to the model
---@field mwscript string|nil MWScript on this light (can be nil)
---@field icon string VFS path to the icon
---@field sound string VFS path to the sound
---@field weight number
---@field value number
---@field duration number
---@field radius number
---@field color openmw.util.Color
---@field isCarriable boolean True if the light can be carried by actors and appears up in their inventory.
---@field isDynamic boolean If true, the light will apply to actors and other moving objects
---@field isFire boolean True if the light acts like a fire.
---@field isFlicker boolean
---@field isFlickerSlow boolean
---@field isNegative boolean If true, the light will reduce light instead of increasing it.
---@field isOffByDefault boolean If true, the light will not emit any light or sound while placed in the world. It will still work in the inventory.
---@field isPulse boolean
---@field isPulseSlow boolean
local LightRecord = {}

---@class openmw.types.Miscellaneous: openmw.types.Item
---@field baseType openmw.types.Item Item
local Miscellaneous = {}

---@class openmw.types.MiscellaneousRecord
---@field id string The record ID of the miscellaneous item
---@field name string The name of the miscellaneous item
---@field model string VFS path to the model
---@field mwscript string|nil MWScript on this miscellaneous item (can be nil)
---@field icon string VFS path to the icon
---@field weight number
---@field value number
---@field isKey boolean
local MiscellaneousRecord = {}

---@class openmw.types.Potion: openmw.types.Item
---@field baseType openmw.types.Item Item
local Potion = {}

---@class openmw.types.PotionRecord
---@field id string Record id
---@field name string Human-readable name
---@field model string VFS path to the model
---@field mwscript string|nil MWScript on this potion (can be nil)
---@field icon string VFS path to the icon
---@field weight number
---@field value number
---@field effects openmw.core.MagicEffectWithParams[] The potion effects.
---@field isAutocalc boolean If set, the gold value should be computed based on the effect list rather than read from the value field
local PotionRecord = {}

---@class openmw.types.Weapon: openmw.types.Item
---@field baseType openmw.types.Item Item
local Weapon = {}

---Weapon.TYPE
---@class openmw.types.WeaponTYPE
---@field ShortBladeOneHand number
---@field LongBladeOneHand number
---@field LongBladeTwoHand number
---@field BluntOneHand number
---@field BluntTwoClose number
---@field BluntTwoWide number
---@field SpearTwoWide number
---@field AxeOneHand number
---@field AxeTwoHand number
---@field MarksmanBow number
---@field MarksmanCrossbow number
---@field MarksmanThrown number
---@field Arrow number
---@field Bolt number
local WeaponTYPE = {}

---@class openmw.types.WeaponRecord
---@field id string Record id
---@field name string Human-readable name
---@field model string VFS path to the model
---@field mwscript string|nil MWScript on this weapon (can be nil)
---@field icon string VFS path to the icon
---@field enchant string|nil The enchantment ID of this weapon (can be nil)
---@field isMagical boolean
---@field isSilver boolean
---@field weight number
---@field value number
---@field type number See Weapon.TYPE
---@field health number
---@field speed number
---@field reach number
---@field enchantCapacity number
---@field chopMinDamage number
---@field chopMaxDamage number
---@field slashMinDamage number
---@field slashMaxDamage number
---@field thrustMinDamage number
---@field thrustMaxDamage number
local WeaponRecord = {}

---@class openmw.types.Apparatus: openmw.types.Item
---@field baseType openmw.types.Item Item
local Apparatus = {}

---Apparatus.TYPE
---@class openmw.types.ApparatusTYPE
---@field MortarPestle number
---@field Alembic number
---@field Calcinator number
---@field Retort number
local ApparatusTYPE = {}

---@class openmw.types.ApparatusRecord
---@field id string The record ID of the apparatus
---@field name string The name of the apparatus
---@field model string VFS path to the model
---@field mwscript string|nil MWScript on this apparatus (can be nil)
---@field icon string VFS path to the icon
---@field type number The type of apparatus. See Apparatus.TYPE
---@field weight number
---@field value number
---@field quality number The quality of the apparatus
local ApparatusRecord = {}

---@class openmw.types.Lockpick: openmw.types.Item
---@field baseType openmw.types.Item Item
local Lockpick = {}

---@class openmw.types.LockpickRecord
---@field id string The record ID of the lockpick
---@field name string The name of the lockpick
---@field model string VFS path to the model
---@field mwscript string|nil MWScript on this lockpick (can be nil)
---@field icon string VFS path to the icon
---@field maxCondition number The maximum number of uses of this lockpick
---@field weight number
---@field value number
---@field quality number The quality of the lockpick
local LockpickRecord = {}

---@class openmw.types.Probe: openmw.types.Item
---@field baseType openmw.types.Item Item
local Probe = {}

---@class openmw.types.ProbeRecord
---@field id string The record ID of the probe
---@field name string The name of the probe
---@field model string VFS path to the model
---@field mwscript string|nil MWScript on this probe (can be nil)
---@field icon string VFS path to the icon
---@field maxCondition number The maximum number of uses of this probe
---@field weight number
---@field value number
---@field quality number The quality of the probe
local ProbeRecord = {}

---@class openmw.types.Repair: openmw.types.Item
---@field baseType openmw.types.Item Item
local Repair = {}

---@class openmw.types.RepairRecord
---@field id string The record ID of the repair tool
---@field name string The name of the repair tool
---@field model string VFS path to the model
---@field mwscript string|nil MWScript on this repair tool (can be nil)
---@field icon string VFS path to the icon
---@field maxCondition number The maximum number of uses of this repair tool
---@field weight number
---@field value number
---@field quality number The quality of the repair tool
local RepairRecord = {}

---@class openmw.types.Activator
local Activator = {}

---@class openmw.types.ActivatorRecord
---@field id string Record id
---@field name string Human-readable name
---@field model string VFS path to the model
---@field mwscript string|nil MWScript on this activator (can be nil)
local ActivatorRecord = {}

---@class openmw.types.Container: openmw.types.Lockable
---@field baseType openmw.types.Lockable Lockable
local Container = {}

---@class openmw.types.ContainerRecord
---@field id string Record id
---@field name string Human-readable name
---@field model string VFS path to the model
---@field mwscript string|nil MWScript on this container (can be nil)
---@field weight number capacity of this container
---@field isOrganic boolean Whether items can be placed in the container
---@field isRespawning boolean Whether the container respawns its contents
local ContainerRecord = {}

---@class openmw.types.Door: openmw.types.Lockable
---@field baseType openmw.types.Lockable Lockable
local Door = {}

---Door.STATE
---@class openmw.types.DoorSTATE
---@field Idle number The door is either closed or open (usually closed).
---@field Opening number The door is in the process of opening.
---@field Closing number The door is in the process of closing.
local DoorSTATE = {}

---@alias openmw.types.DoorState number

---@class openmw.types.DoorRecord
---@field id string Record id
---@field name string Human-readable name
---@field model string VFS path to the model
---@field mwscript string|nil MWScript on this door (can be nil)
---@field openSound string The sound id for door opening
---@field closeSound string The sound id for door closing
local DoorRecord = {}

---@class openmw.types.Static
local Static = {}

---@class openmw.types.StaticRecord
---@field id string Record id
---@field model string VFS path to the model
local StaticRecord = {}

---@class openmw.types.LevelledCreature
local LevelledCreature = {}

---@class openmw.types.LevelledCreatureRecord
---@field id string Record id
---@field chanceNone number Chance this list won't spawn anything [0-1]
---@field calculateFromAllLevels boolean Calculate from all levels <= player level, not just the closest below player
---@field creatures openmw.types.LevelledListItem[]
local LevelledCreatureRecord = {}

---@class openmw.types.LevelledListItem
---@field id string Item id
---@field level number The minimum player level at which this item can occur
local LevelledListItem = {}

---Common Actor functions for Creature, NPC, and Player.
---@type openmw.types.Actor
types.Actor = nil

---Get the total weight of everything the actor is carrying, plus modifications from magic effects.
---@param actor openmw.Object
---@return number
function Actor.getEncumbrance(actor) end

---Get the total weight that the actor can carry.
---@param actor openmw.Object
---@return number
function Actor.getCapacity(actor) end

---Get the actor's current barter gold.
---@param actor openmw.Object
---@return number
function Actor.getBarterGold(actor) end

---Set the actor's current barter gold.
---Available in global and local scripts. Can only be used on self in local scripts.
---@param actor openmw.GObject|openmw.SelfObject
---@param amount number
function Actor.setBarterGold(actor, amount) end

---Check if the given actor is dead (health reached 0, so death process started).
---@param actor openmw.Object
---@return boolean
function Actor.isDead(actor) end

---Check if the given actor's death process is finished.
---@param actor openmw.Object
---@return boolean
function Actor.isDeathFinished(actor) end

---Agent bounds to be used for pathfinding functions.
---@param actor openmw.LObject
---@return table result Agent bounds with `shapeType` and `halfExtents`.
function Actor.getPathfindingAgentBounds(actor) end

---Check if given actor is in the actors processing range.
---@param actor openmw.Object
---@return boolean
function Actor.isInActorsProcessingRange(actor) end

---Whether the object is an actor.
---@param object openmw.Object
---@return boolean
function Actor.objectIsInstance(object) end

---Actor inventory.
---@overload fun(actor: openmw.GObject): openmw.core.Inventory
---@overload fun(actor: openmw.LObject|openmw.SelfObject): openmw.core.Inventory
---@param actor openmw.LObject|openmw.GObject|openmw.SelfObject
---@return openmw.core.Inventory
function Actor.inventory(actor) end

---Available EQUIPMENT_SLOT values. Used in `Actor.getEquipment(obj)` and `Actor.setEquipment(obj, eqp)`.
---@type openmw.types.EQUIPMENT_SLOT
Actor.EQUIPMENT_SLOT = nil

---@type openmw.types.STANCE
Actor.STANCE = nil

---Returns true if the object is an actor and is able to move. For dead, paralyzed,
---or knocked down actors it returns false.
---@param object openmw.Object
---@return boolean
function Actor.canMove(object) end

---Speed of running. For dead actors it still returns a positive value.
---@param actor openmw.Object
---@return number
function Actor.getRunSpeed(actor) end

---Speed of walking. For dead actors it still returns a positive value.
---@param actor openmw.Object
---@return number
function Actor.getWalkSpeed(actor) end

---Current speed.
---@param actor openmw.Object
---@return number
function Actor.getCurrentSpeed(actor) end

---Is the actor standing on ground. Can be called only from a local script.
---@param actor openmw.LObject
---@return boolean
function Actor.isOnGround(actor) end

---Is the actor in water. Can be called only from a local script.
---@param actor openmw.LObject
---@return boolean
function Actor.isSwimming(actor) end

---Returns the current stance (whether a weapon/spell is readied), see the list of STANCE values.
---@param actor openmw.Object
---@return number
function Actor.getStance(actor) end

---Sets the current stance (whether a weapon/spell is readied), see the list of STANCE values.
---Can be used only in local scripts on self.
---@param actor openmw.SelfObject
---@param stance number
function Actor.setStance(actor, stance) end

---Returns `true` if the item is equipped on the actor.
---@param actor openmw.Object
---@param item openmw.Object
---@return boolean
function Actor.hasEquipped(actor, item) end

---Get equipment.
---Has two overloads:
---  * With a single argument: returns a table `slot` -> openmw.Object of currently equipped items.
---See EQUIPMENT_SLOT. Returns empty table if the actor doesn't have equipment slots.
---  * With two arguments: returns an item equipped to the given slot.
---@overload fun(actor: openmw.GObject): table<number, openmw.GObject>
---@overload fun(actor: openmw.GObject, slot: number): openmw.GObject|nil
---@overload fun(actor: openmw.LObject|openmw.SelfObject): table<number, openmw.LObject>
---@overload fun(actor: openmw.LObject|openmw.SelfObject, slot: number): openmw.LObject|nil
---@param actor openmw.Object
---@param slot? number Optional number of the equipment slot
---@return openmw.types.EquipmentTable|openmw.Object|nil
function Actor.getEquipment(actor, slot) end

---Set equipment.
---Keys in the table are equipment slots (see EQUIPMENT_SLOT). Each
---value can be either an object or recordId. Raises an error if
---the actor doesn't have equipment slots and table is not empty. Can be
---used only in local scripts and only on self.
---local Actor = require('openmw.types').Actor
---Actor.setEquipment(self, {}) -- unequip all
---@param actor openmw.SelfObject
---@param equipment openmw.types.EquipmentTable
function Actor.setEquipment(actor, equipment) end

---Get currently selected spell
---@param actor openmw.Object
---@return openmw.core.Spell|nil
function Actor.getSelectedSpell(actor) end

---Set selected spell
---@param actor openmw.SelfObject
---@param spell openmw.core.Spell|string|nil Spell (can be nil)
function Actor.setSelectedSpell(actor, spell) end

---Clears the actor's selected castable (spell or enchanted item)
---@param actor openmw.SelfObject
function Actor.clearSelectedCastable(actor) end

---Get currently selected enchanted item
---@param actor openmw.Object
---@return openmw.Object|nil enchanted item or nil
function Actor.getSelectedEnchantedItem(actor) end

---Set currently selected enchanted item, equipping it if applicable
---@param actor openmw.SelfObject
---@param item openmw.Object|string enchanted item
function Actor.setSelectedEnchantedItem(actor, item) end

---Return the active magic effects (ActorActiveEffects) currently affecting the given actor.
---@param actor openmw.Object
---@return openmw.types.ActorActiveEffects
function Actor.activeEffects(actor) end

---Mutation methods on this proxy are only mutable when the proxy was obtained from a GObject or SelfObject.

---Get a specific active effect on the actor.
---@param effectId string effect ID
---@param extraParam? string Optional skill or attribute ID
---@return openmw.core.ActiveEffect
function ActorActiveEffects:getEffect(effectId, extraParam) end

---Completely removes the active effect from the actor.
---@param effectId string effect ID
---@param extraParam? string Optional skill or attribute ID
function ActorActiveEffects:remove(effectId, extraParam) end

---(Note that using this function will override and conflict with all other sources of this effect. You probably want to use ActorActiveEffects.modify instead, this function is provided for mwscript parity only)
---Permanently modifies the magnitude of an active effect to be exactly equal to the provided value.
---Note that although the modification is permanent, the magnitude will not stay equal to the value if any active spells with this effects are added/removed.
---Also see the notes on ActorActiveEffects.modify
---@param value number
---@param effectId string effect ID
---@param extraParam? string Optional skill or attribute ID
function ActorActiveEffects:set(value, effectId, extraParam) end

---Permanently modifies the magnitude of an active effect by modifying it by the provided value. Note that some active effect values, such as fortify attribute effects, have no practical effect of their own, and must be paired with explicitly modifying the target stat to have any effect.
---@param value number
---@param effectId string effect ID
---@param extraParam? string Optional skill or attribute ID
function ActorActiveEffects:modify(value, effectId, extraParam) end

---Return the active spells (ActorActiveSpells) currently affecting the given actor.
---@param actor openmw.Object
---@return openmw.types.ActorActiveSpells
function Actor.activeSpells(actor) end

---Mutation methods on this proxy are only mutable when the proxy was obtained from a GObject or SelfObject.

---Get whether any instance of the specific spell is active on the actor.
---@param recordOrId openmw.core.Spell|openmw.Object|openmw.types.IngredientRecord|openmw.types.PotionRecord|string A record or string record ID. Valid records are openmw.core.Spell, enchanted Item, IngredientRecord, or PotionRecord.
---@return boolean True if spell is active, false otherwise.
function ActorActiveSpells:isSpellActive(recordOrId) end

---Remove an active spell based on active spell ID (see openmw.core.ActiveSpell.activeSpellId). Can only be used in global scripts or on self. Can only be used to remove spells with the temporary flag set (see openmw.core.ActiveSpell.temporary).
---@param id string Active spell ID.
function ActorActiveSpells:remove(id) end

---Adds a new spell to the list of active spells (only in global scripts or on self).
---Note that this does not play any related VFX or sounds.
---Note that this should not be used to add spells without durations (i.e. abilities, curses, and diseases) as they will expire instantly. Use ActorSpells.add instead.
---And may contain the following optional parameters:
----- Adds the effect of the chameleon spell to the character
---Actor.activeSpells(self):add({id = 'chameleon', effects = { 0 }})
----- Adds the effect of a standard potion of intelligence, without consuming any potions from the character's inventory.
----- Note that stackable = true to let the effect stack like a potion should.
---Actor.activeSpells(self):add({id = 'p_fortify_intelligence_s', effects = { 0 }, stackable = true})
----- Adds the negative effect of Greef twice over, and renames it to Good Greef.
---Actor.activeSpells(self):add({id = 'potion_comberry_brandy_01', effects = { 1, 1 }, stackable = true, name = 'Good Greef'})
----- Has the same effect as if the actor ate a chokeweed. With the same variable effect based on skill / random chance.
---Actor.activeSpells(self):add({id = 'ingred_chokeweed_01', effects = { 0 }, stackable = true, name = 'Chokeweed'})
----- Same as above, but uses a different index. Note that if multiple indexes are used, the randomicity is applied separately for each effect.
---Actor.activeSpells(self):add({id = 'ingred_chokeweed_01', effects = { 1 }, stackable = true, name = 'Chokeweed'})
---@param options openmw.types.ActiveSpellAddOptions A table of active spell parameters.
function ActorActiveSpells:add(options) end

---Return the spells (ActorSpells) of the given actor.
---@param actor openmw.Object
---@return openmw.types.ActorSpells
function Actor.spells(actor) end

---Add spell (only in global scripts or on self).
---@param spellOrId openmw.core.Spell|string openmw.core.Spell or string spell id
function ActorSpells:add(spellOrId) end

---Remove spell (only in global scripts or on self).
---@param spellOrId openmw.core.Spell|string openmw.core.Spell or string spell id
function ActorSpells:remove(spellOrId) end

---Remove all spells (only in global scripts or on self).
function ActorSpells:clear() end

---If true, the actor has not used this power in the last 24h. Will return true for powers the actor does not have.
---@param spellOrId openmw.core.Spell|string A openmw.core.Spell or string record ID.
---@return boolean
function ActorSpells:canUsePower(spellOrId) end

---Health (returns DynamicStat)
---@param actor openmw.Object
---@return openmw.types.DynamicStat|nil
function DynamicStats.health(actor) end

---Magicka (returns DynamicStat)
---@param actor openmw.Object
---@return openmw.types.DynamicStat|nil
function DynamicStats.magicka(actor) end

---Fatigue (returns DynamicStat)
---@param actor openmw.Object
---@return openmw.types.DynamicStat|nil
function DynamicStats.fatigue(actor) end

---Alarm (returns AIStat)
---@param actor openmw.Object
---@return openmw.types.AIStat|nil
function AIStats.alarm(actor) end

---Fight (returns AIStat)
---@param actor openmw.Object
---@return openmw.types.AIStat|nil
function AIStats.fight(actor) end

---Flee (returns AIStat)
---@param actor openmw.Object
---@return openmw.types.AIStat|nil
function AIStats.flee(actor) end

---Hello (returns AIStat)
---@param actor openmw.Object
---@return openmw.types.AIStat|nil
function AIStats.hello(actor) end

---Strength (returns AttributeStat)
---@param actor openmw.Object
---@return openmw.types.AttributeStat|nil
function AttributeStats.strength(actor) end

---Intelligence (returns AttributeStat)
---@param actor openmw.Object
---@return openmw.types.AttributeStat|nil
function AttributeStats.intelligence(actor) end

---Willpower (returns AttributeStat)
---@param actor openmw.Object
---@return openmw.types.AttributeStat|nil
function AttributeStats.willpower(actor) end

---Agility (returns AttributeStat)
---@param actor openmw.Object
---@return openmw.types.AttributeStat|nil
function AttributeStats.agility(actor) end

---Speed (returns AttributeStat)
---@param actor openmw.Object
---@return openmw.types.AttributeStat|nil
function AttributeStats.speed(actor) end

---Endurance (returns AttributeStat)
---@param actor openmw.Object
---@return openmw.types.AttributeStat|nil
function AttributeStats.endurance(actor) end

---Personality (returns AttributeStat)
---@param actor openmw.Object
---@return openmw.types.AttributeStat|nil
function AttributeStats.personality(actor) end

---Luck (returns AttributeStat)
---@param actor openmw.Object
---@return openmw.types.AttributeStat|nil
function AttributeStats.luck(actor) end

---Block (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.block(actor) end

---Armorer (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.armorer(actor) end

---Medium Armor (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.mediumarmor(actor) end

---Heavy Armor (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.heavyarmor(actor) end

---Blunt Weapon (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.bluntweapon(actor) end

---Long Blade (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.longblade(actor) end

---Axe (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.axe(actor) end

---Spear (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.spear(actor) end

---Athletics (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.athletics(actor) end

---Enchant (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.enchant(actor) end

---Destruction (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.destruction(actor) end

---Alteration (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.alteration(actor) end

---Illusion (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.illusion(actor) end

---Conjuration (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.conjuration(actor) end

---Mysticism (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.mysticism(actor) end

---Restoration (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.restoration(actor) end

---Alchemy (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.alchemy(actor) end

---Unarmored (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.unarmored(actor) end

---Security (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.security(actor) end

---Sneak (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.sneak(actor) end

---Acrobatics (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.acrobatics(actor) end

---Light Armor (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.lightarmor(actor) end

---Short Blade (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.shortblade(actor) end

---Marksman (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.marksman(actor) end

---Mercantile (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.mercantile(actor) end

---Speechcraft (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.speechcraft(actor) end

---Hand To Hand (returns SkillStat)
---@param actor openmw.Object
---@return openmw.types.SkillStat|nil
function SkillStats.handtohand(actor) end

---Level (returns LevelStat)
---@param actor openmw.Object
---@return openmw.types.LevelStat|nil
function ActorStats.level(actor) end

---The actor's stats.
---@type openmw.types.ActorStats
Actor.stats = nil

--------------------------------------------------------------------------------
---@type openmw.types.Item
types.Item = nil

---Whether the object is an item.
---@param object openmw.Object
---@return boolean
function Item.objectIsInstance(object) end

---(DEPRECATED, use itemData(item).enchantmentCharge) Get this item's current enchantment charge.
---@param item openmw.Object
---@return number|nil The charge remaining, or `nil` if the enchantment has never been used and the charge is full. Unenchanted items will always return `nil`.
function Item.getEnchantmentCharge(item) end

---Checks if the item restocks.
---Returns true if the object restocks, and false otherwise.
---@param item openmw.Object
---@return boolean
function Item.isRestocking(item) end

---(DEPRECATED, use itemData(item).enchantmentCharge) Set this item's enchantment charge.
---@param item openmw.GObject
---@param charge number|nil Can be `nil` to reset the unused state / full
function Item.setEnchantmentCharge(item, charge) end

---Whether the object is supposed to be carriable. It is true for all items except
---lights without the Carry flag. Non-carriable lights can still be put into
---an inventory with an explicit `object:moveInto` call.
---@param object openmw.Object
---@return boolean
function Item.isCarriable(object) end

---Set of properties that differentiates one item from another of the same record type; can be used by any script, but only global and self scripts can change values.
---@param item openmw.Object
---@return openmw.types.ItemData|nil
function Item.itemData(item) end

--------------------------------------------------------------------------------
---@type openmw.types.Creature
types.Creature = nil

---Creates a CreatureRecord without adding it to the world database.
---Use openmw.world.createRecord to add the record to the world.
---local creatureTable = {name = "Epic Mudcrab", template = creatureTemplate, soulValue = 500, isEssential = true}
---local recordDraft = types.Creature.createRecordDraft(creatureTable)
---local newRecord = world.createRecord(recordDraft)
---world.createObject(newRecord.id):teleport(playerCell, playerPosition)
---@param creature openmw.types.RecordDraft<openmw.types.CreatureRecord> A Lua table with CreatureRecord draft fields.
---@return openmw.types.RecordDraft<openmw.types.CreatureRecord> A strongly typed Creature record draft.
function Creature.createRecordDraft(creature) end

---A read-only list of all CreatureRecords in the world database, may be indexed by recordId.
---Implements a List of CreatureRecord.
---@type openmw.types.RecordList<openmw.types.CreatureRecord>
Creature.records = nil

---Whether the object is a creature.
---@param object openmw.Object
---@return boolean
function Creature.objectIsInstance(object) end

---@type openmw.types.CreatureTYPE
Creature.TYPE = nil

---Returns the read-only CreatureRecord of a creature
---@param objectOrRecordId openmw.Object|string
---@return openmw.types.CreatureRecord|nil
function Creature.record(objectOrRecordId) end

---@type openmw.types.NPC
types.NPC = nil

---Creates an NpcRecord without adding it to the world database.
---Use openmw.world.createRecord to add the record to the world.
---@param npc openmw.types.RecordDraft<openmw.types.NpcRecord> A Lua table with NpcRecord draft fields.
---@return openmw.types.RecordDraft<openmw.types.NpcRecord> A strongly typed NPC record draft.
function NPC.createRecordDraft(npc) end

---A read-only list of all NpcRecords in the world database, may be indexed by recordId.
---Implements a List of NpcRecord.
---@type openmw.types.RecordList<openmw.types.NpcRecord>
NPC.records = nil

---Whether the object is an NPC or a Player.
---@param object openmw.Object
---@return boolean
function NPC.objectIsInstance(object) end

---Get all factions in which NPC has a membership.
---Note: this function does not take in account an expelling state.
---for _, factionId in pairs(types.NPC.getFactions(actor)) do
---end
---@param actor openmw.Object NPC object
---@return string[] factionIds List of faction IDs.
function NPC.getFactions(actor) end

---Get rank of given NPC in given faction.
---Throws an exception if there is no such faction.
---Note: this function does not take in account an expelling state.
---print(NPC.getFactionRank(player, "mages guild");
---@param actor openmw.Object NPC object
---@param faction string Faction ID
---@return number rank Rank index (from 1), or 0 if NPC is not in faction.
function NPC.getFactionRank(actor, faction) end

---Set rank of given NPC in given faction.
---Throws an exception if there is no such faction, target rank does not exist or actor is not a member of given faction.
---For NPCs faction also should be an NPC's primary faction.
---NPC.setFactionRank(player, "mages guild", 6);
---@param actor openmw.GObject|openmw.SelfObject NPC object
---@param faction string Faction ID
---@param value number Rank index (from 1).
function NPC.setFactionRank(actor, faction, value) end

---Adjust rank of given NPC in given faction.
---Throws an exception if there is no such faction or actor is not a member of given faction.
---For NPCs faction also should be an NPC's primary faction.
---Notes:
---  * If rank should become <= 0 after modification, function set rank to lowest available rank.
---  * If rank should become > 0 after modification, but target rank does not exist, function set rank to the highest valid rank.
---NPC.modifyFactionRank(player, "mages guild", 1);
---@param actor openmw.GObject|openmw.SelfObject NPC object
---@param faction string Faction ID
---@param value number Rank index (from 1) modifier. If rank reaches 0 for player character, he leaves the faction.
function NPC.modifyFactionRank(actor, faction, value) end

---Add given actor to given faction.
---Throws an exception if there is no such faction or target actor is not player.
---Function does nothing if valid target actor is already a member of target faction.
---NPC.joinFaction(player, "mages guild");
---@param actor openmw.GObject|openmw.SelfObject NPC object
---@param faction string Faction ID
function NPC.joinFaction(actor, faction) end

---Remove given actor from given faction.
---Function removes rank data and expelling state, but keeps a reputation in target faction.
---Throws an exception if there is no such faction or target actor is not player.
---Function does nothing if valid target actor is already not member of target faction.
---NPC.leaveFaction(player, "mages guild");
---@param actor openmw.GObject|openmw.SelfObject NPC object
---@param faction string Faction ID
function NPC.leaveFaction(actor, faction) end

---Get reputation of given actor in given faction.
---Throws an exception if there is no such faction.
---print(NPC.getFactionReputation(player, "mages guild"));
---@param actor openmw.Object NPC object
---@param faction string Faction ID
---@return number reputation Reputation level, or 0 if NPC is not in faction.
function NPC.getFactionReputation(actor, faction) end

---Set reputation of given actor in given faction.
---Throws an exception if there is no such faction.
---NPC.setFactionReputation(player, "mages guild", 100);
---@param actor openmw.GObject|openmw.SelfObject NPC object
---@param faction string Faction ID
---@param value number Reputation value
function NPC.setFactionReputation(actor, faction, value) end

---Adjust reputation of given actor in given faction.
---Throws an exception if there is no such faction.
---NPC.modifyFactionReputation(player, "mages guild", 5);
---@param actor openmw.GObject|openmw.SelfObject NPC object
---@param faction string Faction ID
---@param value number Reputation modifier value
function NPC.modifyFactionReputation(actor, faction, value) end

---Expel NPC from given faction.
---Throws an exception if there is no such faction.
---Note: the expelled NPC still keeps their rank and reputation in the faction, they just get an additional flag for the given faction.
---NPC.expel(player, "mages guild");
---@param actor openmw.GObject|openmw.SelfObject NPC object
---@param faction string Faction ID
function NPC.expel(actor, faction) end

---Clear expelling of NPC from given faction.
---Throws an exception if there is no such faction.
---NPC.clearExpelled(player, "mages guild");
---@param actor openmw.GObject|openmw.SelfObject NPC object
---@param faction string Faction ID
function NPC.clearExpelled(actor, faction) end

---Check if NPC is expelled from given faction.
---Throws an exception if there is no such faction.
---local result = NPC.isExpelled(player, "mages guild");
---@param actor openmw.Object NPC object
---@param faction string Faction ID
---@return boolean isExpelled True if NPC is expelled from the faction.
function NPC.isExpelled(actor, faction) end

---Returns the current disposition of the provided NPC. This is their derived disposition, after modifiers such as personality and faction relations are taken into account.
---@param object openmw.Object
---@param player openmw.Object The player that you want to check the disposition for.
---@return number
function NPC.getDisposition(object, player) end

---Returns the current base disposition of the provided NPC. This is their base disposition, before modifiers such as personality and faction relations are taken into account.
---@param object openmw.Object
---@param player openmw.Object The player that you want to check the disposition for.
---@return number
function NPC.getBaseDisposition(object, player) end

---Set the base disposition of the provided NPC (only in global scripts or on self).
---@param object openmw.GObject|openmw.SelfObject
---@param player openmw.Object The player that you want to set the disposition for.
---@param value number Base disposition is set to this value
function NPC.setBaseDisposition(object, player, value) end

---Modify the base disposition of the provided NPC by a certain amount (only in global scripts or on self).
---@param object openmw.GObject|openmw.SelfObject
---@param player openmw.Object The player that you want to modify the disposition for.
---@param value number Base disposition modification value
function NPC.modifyBaseDisposition(object, player, value) end

---@type openmw.types.Classes
NPC.classes = nil

---A read-only list of all ClassRecords in the world database, may be indexed by recordId.
---Implements a List of ClassRecord.
---@type openmw.types.RecordList<openmw.types.ClassRecord>
Classes.records = nil

---Returns a read-only ClassRecord
---@param recordId string
---@return openmw.types.ClassRecord|nil
function Classes.record(recordId) end

---Whether the NPC or player is in the werewolf form at the moment.
---@param actor openmw.Object
---@return boolean
function NPC.isWerewolf(actor) end

---Turn an NPC or player into werewolf form or back to normal form.
---Can only be used in global scripts or on self in local scripts.
---player.type.setWerewolf(player, true)
---self.type.setWerewolf(self, false)
---@param actor openmw.GObject|openmw.SelfObject The NPC or player to transform
---@param werewolf boolean True to transform into werewolf, false to transform back to normal
function NPC.setWerewolf(actor, werewolf) end

---Returns the read-only NpcRecord of an NPC
---@param objectOrRecordId openmw.Object|string
---@return openmw.types.NpcRecord|nil
function NPC.record(objectOrRecordId) end

---@type openmw.types.Races
NPC.races = nil

---A read-only list of all RaceRecords in the world database.
---Implements a List of RaceRecord.
---@type openmw.types.RecordList<openmw.types.RaceRecord>
Races.records = nil

---Returns a read-only RaceRecord
---@param recordId string
---@return openmw.types.RaceRecord|nil
function Races.record(recordId) end

--------------------------------------------------------------------------------
---@type openmw.types.Player
types.Player = nil

---Whether the object is a player.
---@param object openmw.Object
---@return boolean
function Player.objectIsInstance(object) end

---Returns the bounty or crime level of the player
---@param player openmw.Object
---@return number
function Player.getCrimeLevel(player) end

---Sets the bounty or crime level of the player, may only be used in global scripts
---@param player openmw.GObject
---@param crimeLevel number The requested crime level
function Player.setCrimeLevel(player, crimeLevel) end

---Available OFFENSE_TYPE_IDS values. Used in `I.Crimes.commitCrime`.
---@type openmw.types.OFFENSE_TYPE_IDS
Player.OFFENSE_TYPE = nil

---Whether the character generation for this player is finished.
---@param player openmw.Object
---@return boolean
function Player.isCharGenFinished(player) end

---Whether teleportation for this player is enabled.
---@param player openmw.Object
---@return boolean
function Player.isTeleportingEnabled(player) end

---Enables or disables teleportation for this player.
---@param player openmw.GObject|openmw.SelfObject
---@param state boolean True to enable teleporting, false to disable.
function Player.setTeleportingEnabled(player, state) end

---Returns quests for the specified player, indexed by quest ID.
---stage = types.Player.quests(player)["ms_fargothring"].stage
---types.Player.quests(player)["ms_fargothring"].stage = 0
---@param player openmw.Object
---@return table<string, openmw.types.PlayerQuest|nil>
function Player.quests(player) end

---Adds a topic to the list of ones known by the player, so that it can be used in dialogue with actors who can talk about that topic.
---self.type.addTopic(self, "Some Work")
---for _, player in ipairs(world.players) do player.type.addTopic(player, "Some Unrelated Work") end
---@param player openmw.GObject|openmw.SelfObject
---@param topicId string
function Player.addTopic(player, topicId) end

---Returns PlayerJournal, which contains the read-only access to journal text data accumulated by the player.
---Not the same as openmw.core.Dialogue.journal which holds raw game records: with placeholders for dynamic variables and no player-specific info.
---local entryText = types.Player.journal(player).journalTextEntries[1].text
---local num = #types.Player.journal(player).topics["my trade"].entries
---@param player openmw.Object
---@return openmw.types.PlayerJournal
function Player.journal(player) end

---A read-only list of player's accumulated journal (quest etc.) entries (PlayerJournalTextEntry elements), ordered from oldest entry to newest.
---Implements a list iterable of PlayerJournalTextEntry.
---local firstQuestName = types.Player.journal(player).journalTextEntries[1].questId
---local num = #types.Player.journal(player).journalTextEntries
---for idx, journalEntry in pairs(types.Player.journal(player).journalTextEntries) do
---end
---@type openmw.types.PlayerJournalTextEntry[]
PlayerJournal.journalTextEntries = nil

---A read-only table of player's accumulated PlayerJournalTopics, indexed by the topic name.
---Implements a Map of PlayerJournalTopic.
---Topic name index doesn't have to be lowercase.
---@type table<string, openmw.types.PlayerJournalTopic|nil>
PlayerJournal.topics = nil

---A read-only list of player's accumulated conversation lines (PlayerJournalTopicEntry) for this topic.
---Implements a list iterable of PlayerJournalTopicEntry.
---local firstBackgroundLine = types.Player.journal(player).topics["Background"].entries[1]
---local num = #types.Player.journal(player).topics["vivec"].entries
---for idx, topicEntry in pairs(types.Player.journal(player).topics["balmora"].entries) do
---end
---@type openmw.types.PlayerJournalTopicEntry[]
PlayerJournalTopic.entries = nil

---Identifier for this topic line. Is unique only within the PlayerJournalTopic it belongs to.
---Has a counterpart in raw data game dialogue records at openmw.core.DialogueRecordInfo held by openmw.core.Dialogue.topic
---@type string
PlayerJournalTopicEntry.id = nil

---Identifier for this journal entry line. Is unique only within the PlayerJournalTextEntry it belongs to.
---Has a counterpart in raw data game dialogue records at openmw.core.DialogueRecordInfo held by openmw.core.Dialogue.journal
---@type string
PlayerJournalTextEntry.id = nil

---Sets the quest stage for the given quest, on the given player, and adds the entry to the journal, if there is an entry at the specified stage. Can only be used in global or player scripts.
---@param stage number Quest stage
---@param actor? openmw.GObject (optional) The actor who is the source of the journal entry, it may be used in journal entries with variables such as `%name(The speaker's name)` or `%race(The speaker's race)`.
function PlayerQuest:addJournalEntry(stage, actor) end

---Get state of a control switch. I.e. is the player able to move/fight/jump/etc.
---@param player openmw.Object
---@param key openmw.types.ControlSwitch Control type (see openmw.types.CONTROL_SWITCH)
---@return boolean
function Player.getControlSwitch(player, key) end

---Set state of a control switch. I.e. forbid or allow the player to move/fight/jump/etc.
---Can be used only in global or player scripts.
---@param player openmw.GObject|openmw.SelfObject
---@param key openmw.types.ControlSwitch Control type (see openmw.types.CONTROL_SWITCH)
---@param value boolean
function Player.setControlSwitch(player, key, value) end

---Values that can be used with getControlSwitch/setControlSwitch.
---@type openmw.types.CONTROL_SWITCH
Player.CONTROL_SWITCH = nil

---@param player openmw.Object
---@return string The player's birth sign
function Player.getBirthSign(player) end

---Can be used only in global scripts. Note that this does not update the player's spells.
---@param player openmw.GObject
---@param recordOrId openmw.types.BirthSignRecord|string Record or string ID of the birth sign to assign
function Player.setBirthSign(player, recordOrId) end

---@type openmw.types.BirthSigns
Player.birthSigns = nil

---A read-only list of all BirthSignRecords in the world database.
---Implements a List of BirthSignRecord.
---@type openmw.types.RecordList<openmw.types.BirthSignRecord>
BirthSigns.records = nil

---Returns a read-only BirthSignRecord
---@param recordId string
---@return openmw.types.BirthSignRecord|nil
function BirthSigns.record(recordId) end

---Send an event to menu scripts.
---@param player openmw.Object
---@param eventName string
---@param eventData any
function Player.sendMenuEvent(player, eventName, eventData) end

--------------------------------------------------------------------------------
---@type openmw.types.Armor
types.Armor = nil

---Whether the object is an Armor.
---@param object openmw.Object
---@return boolean
function Armor.objectIsInstance(object) end

---A read-only list of all ArmorRecords in the world database.
---Implements a List of ArmorRecord.
---@type openmw.types.RecordList<openmw.types.ArmorRecord>
Armor.records = nil

---@type openmw.types.ArmorTYPE
Armor.TYPE = nil

---Returns the read-only ArmorRecord of an Armor
---@param objectOrRecordId openmw.Object|string
---@return openmw.types.ArmorRecord|nil
function Armor.record(objectOrRecordId) end

---Creates an ArmorRecord without adding it to the world database, for the armor to appear correctly on the body, make sure to use a template as described below.
---Use openmw.world.createRecord to add the record to the world.
---local armorTable = {name = "Better Orcish Cuirass",template = armorTemplate,baseArmor = armorTemplate.baseArmor + 10}
---local recordDraft = types.Armor.createRecordDraft(armorTable)--Need to convert the table into the record draft
---local newRecord = world.createRecord(recordDraft)--This creates the actual record
---world.createObject(newRecord.id):moveInto(playerActor)--Create an instance of this object, and move it into the player's inventory
---@param armor openmw.types.RecordDraft<openmw.types.ArmorRecord> A Lua table with ArmorRecord draft fields.
---@return openmw.types.RecordDraft<openmw.types.ArmorRecord> A strongly typed Armor record draft.
function Armor.createRecordDraft(armor) end

---@type openmw.types.BodyPart
types.BodyPart = nil

---A read-only list of all BodyPartRecords in the world database.
---Implements a List of BodyPartRecord.
---@type openmw.types.RecordList<openmw.types.BodyPartRecord>
BodyPart.records = nil

---Whether the object is a BodyPart.
---@param object openmw.Object
---@return boolean
function BodyPart.objectIsInstance(object) end

---@type openmw.types.Book
types.Book = nil

---A read-only list of all BookRecords in the world database.
---Implements a List of BookRecord.
---@type openmw.types.RecordList<openmw.types.BookRecord>
Book.records = nil

---Whether the object is a Book.
---@param object openmw.Object
---@return boolean
function Book.objectIsInstance(object) end

---DEPRECATED, use openmw.core.Skill
---@type openmw.types.BookSKILL
Book.SKILL = nil

---Returns the read-only BookRecord of a book
---@param objectOrRecordId openmw.Object|string
---@return openmw.types.BookRecord|nil
function Book.record(objectOrRecordId) end

---Creates a BookRecord without adding it to the world database.
---Use openmw.world.createRecord to add the record to the world.
---@param book openmw.types.RecordDraft<openmw.types.BookRecord> A Lua table with BookRecord draft fields.
---@return openmw.types.RecordDraft<openmw.types.BookRecord> A strongly typed Book record draft.
function Book.createRecordDraft(book) end

---@type openmw.types.Clothing
types.Clothing = nil

---A read-only list of all ClothingRecords in the world database.
---Implements a List of ClothingRecord.
---@type openmw.types.RecordList<openmw.types.ClothingRecord>
Clothing.records = nil

---Whether the object is a Clothing.
---@param object openmw.Object
---@return boolean
function Clothing.objectIsInstance(object) end

---@type openmw.types.ClothingTYPE
Clothing.TYPE = nil

---Returns the read-only ClothingRecord of a Clothing
---@param objectOrRecordId openmw.Object|string
---@return openmw.types.ClothingRecord|nil
function Clothing.record(objectOrRecordId) end

---Creates a ClothingRecord without adding it to the world database, for the clothing to appear correctly on the body, make sure to use a template as described below.
---Use openmw.world.createRecord to add the record to the world.
---local clothingTable = {name = "Better Exquisite Robe",template = clothingTemplate,enchantCapacity = clothingTemplate.enchantCapacity + 10}
---local recordDraft = types.Clothing.createRecordDraft(clothingTable)--Need to convert the table into the record draft
---local newRecord = world.createRecord(recordDraft)--This creates the actual record
---world.createObject(newRecord.id):moveInto(playerActor)--Create an instance of this object, and move it into the player's inventory
---@param clothing openmw.types.RecordDraft<openmw.types.ClothingRecord> A Lua table with ClothingRecord draft fields.
---@return openmw.types.RecordDraft<openmw.types.ClothingRecord> A strongly typed clothing record draft.
function Clothing.createRecordDraft(clothing) end

---@type openmw.types.Ingredient
types.Ingredient = nil

---A read-only list of all IngredientRecords in the world database.
---Implements a List of IngredientRecord.
---@type openmw.types.RecordList<openmw.types.IngredientRecord>
Ingredient.records = nil

---Whether the object is an Ingredient.
---@param object openmw.Object
---@return boolean
function Ingredient.objectIsInstance(object) end

---Returns the read-only IngredientRecord of a Ingredient
---@param objectOrRecordId openmw.Object|string
---@return openmw.types.IngredientRecord|nil
function Ingredient.record(objectOrRecordId) end

---@type openmw.types.Lockable
types.Lockable = nil

---Whether the object is a Lockable.
---@param object openmw.Object
---@return boolean
function Lockable.objectIsInstance(object) end

---Returns the key record of a lockable object(door, container)
---@param object openmw.Object
---@return openmw.types.MiscellaneousRecord|nil
function Lockable.getKeyRecord(object) end

---Sets the key of a lockable object(door, container); removes it if nil is provided. Must be used in a global script.
---@param object openmw.GObject
---@param miscOrId openmw.types.MiscellaneousRecord|string|nil MiscellaneousRecord or string misc item id Record ID of the key to use.
function Lockable.setKeyRecord(object, miscOrId) end

---Returns the trap spell of a lockable object(door, container)
---@param object openmw.Object
---@return openmw.core.Spell|nil
function Lockable.getTrapSpell(object) end

---Sets the trap spell of a lockable object(door, container); removes it if nil is provided. Must be used in a global script.
---@param object openmw.GObject
---@param spellOrId openmw.core.Spell|string|nil openmw.core.Spell or string spell id Record ID for the trap to use
function Lockable.setTrapSpell(object, spellOrId) end

---Returns the lock level of a lockable object(door, container). Does not determine if an object is locked or not, if an object is locked while this is set above 0, this value will be used if no other value is specified.
---@param object openmw.Object
---@return number
function Lockable.getLockLevel(object) end

---Returns true if the lockable object is locked, and false if it is not.
---@param object openmw.Object
---@return boolean
function Lockable.isLocked(object) end

---Sets the lock level level of a lockable object(door, container);Locks if not already locked; Must be used in a global script.
---@param object openmw.GObject
---@param lockLevel? number Level to lock the object at. Optional, if not specified, then 1 will be used, or the previous level if it was locked before.
function Lockable.lock(object, lockLevel) end

---Unlocks the lockable object. Does not change the lock level, it can be kept for future use.
---@param object openmw.GObject
function Lockable.unlock(object) end

---@type openmw.types.Light
types.Light = nil

---A read-only list of all LightRecords in the world database.
---Implements a List of LightRecord.
---@type openmw.types.RecordList<openmw.types.LightRecord>
Light.records = nil

---Whether the object is a Light.
---@param object openmw.Object
---@return boolean
function Light.objectIsInstance(object) end

---Creates a LightRecord without adding it to the world database.
---Use openmw.world.createRecord to add the record to the world.
---@param light openmw.types.RecordDraft<openmw.types.LightRecord> A Lua table with LightRecord draft fields.
---@return openmw.types.RecordDraft<openmw.types.LightRecord> A strongly typed Light record draft.
function Light.createRecordDraft(light) end

---Returns the read-only LightRecord of a Light
---@param objectOrRecordId openmw.Object|string
---@return openmw.types.LightRecord|nil
function Light.record(objectOrRecordId) end

---Functions for Miscellaneous objects
---@type openmw.types.Miscellaneous
types.Miscellaneous = nil

---A read-only list of all MiscellaneousRecords in the world database.
---Implements a List of MiscellaneousRecord.
---@type openmw.types.RecordList<openmw.types.MiscellaneousRecord>
Miscellaneous.records = nil

---Whether the object is a Miscellaneous.
---@param object openmw.Object
---@return boolean
function Miscellaneous.objectIsInstance(object) end

---Returns the read-only MiscellaneousRecord of a miscellaneous item
---@param objectOrRecordId openmw.Object|string
---@return openmw.types.MiscellaneousRecord|nil
function Miscellaneous.record(objectOrRecordId) end

---(DEPRECATED, use itemData(item).soul) Returns the read-only soul of a miscellaneous item
---@param object openmw.Object
---@return string|nil
function Miscellaneous.getSoul(object) end

---Creates a MiscellaneousRecord without adding it to the world database.
---Use openmw.world.createRecord to add the record to the world.
---@param miscellaneous openmw.types.RecordDraft<openmw.types.MiscellaneousRecord> A Lua table with MiscellaneousRecord draft fields.
---@return openmw.types.RecordDraft<openmw.types.MiscellaneousRecord> A strongly typed Miscellaneous record draft.
function Miscellaneous.createRecordDraft(miscellaneous) end

---(DEPRECATED, use itemData(item).soul) Sets the soul of a miscellaneous item, intended for soul gem objects; Must be used in a global script. This function does not clear souls; use itemData(item).soul = nil when clearing is needed.
---@param object openmw.GObject
---@param soulId string Record ID for the soul of the creature to use
function Miscellaneous.setSoul(object, soulId) end

---@type openmw.types.Potion
types.Potion = nil

---A read-only list of all PotionRecords in the world database.
---Implements a List of PotionRecord.
---@type openmw.types.RecordList<openmw.types.PotionRecord>
Potion.records = nil

---Whether the object is a Potion.
---@param object openmw.Object
---@return boolean
function Potion.objectIsInstance(object) end

---Returns the read-only PotionRecord of a potion
---@param objectOrRecordId openmw.Object|string
---@return openmw.types.PotionRecord|nil
function Potion.record(objectOrRecordId) end

---Creates a PotionRecord without adding it to the world database.
---Use openmw.world.createRecord to add the record to the world.
---@param potion openmw.types.RecordDraft<openmw.types.PotionRecord> A Lua table with PotionRecord draft fields.
---@return openmw.types.RecordDraft<openmw.types.PotionRecord> A strongly typed Potion record draft.
function Potion.createRecordDraft(potion) end

---@type openmw.types.Weapon
types.Weapon = nil

---A read-only list of all WeaponRecords in the world database.
---Implements a List of WeaponRecord.
---@type openmw.types.RecordList<openmw.types.WeaponRecord>
Weapon.records = nil

---Whether the object is a Weapon.
---@param object openmw.Object
---@return boolean
function Weapon.objectIsInstance(object) end

---@type openmw.types.WeaponTYPE
Weapon.TYPE = nil

---Returns the read-only WeaponRecord of a weapon
---@param objectOrRecordId openmw.Object|string
---@return openmw.types.WeaponRecord|nil
function Weapon.record(objectOrRecordId) end

---Creates a WeaponRecord without adding it to the world database.
---Use openmw.world.createRecord to add the record to the world.
---@param weapon openmw.types.RecordDraft<openmw.types.WeaponRecord> A Lua table with WeaponRecord draft fields.
---@return openmw.types.RecordDraft<openmw.types.WeaponRecord> A strongly typed Weapon record draft.
function Weapon.createRecordDraft(weapon) end

---@type openmw.types.Apparatus
types.Apparatus = nil

---A read-only list of all ApparatusRecords in the world database.
---Implements a List of ApparatusRecord.
---@type openmw.types.RecordList<openmw.types.ApparatusRecord>
Apparatus.records = nil

---Whether the object is an Apparatus.
---@param object openmw.Object
---@return boolean
function Apparatus.objectIsInstance(object) end

---@type openmw.types.ApparatusTYPE
Apparatus.TYPE = nil

---Returns the read-only ApparatusRecord of an apparatus
---@param objectOrRecordId openmw.Object|string
---@return openmw.types.ApparatusRecord|nil
function Apparatus.record(objectOrRecordId) end

---@type openmw.types.Lockpick
types.Lockpick = nil

---A read-only list of all LockpickRecords in the world database.
---Implements a List of LockpickRecord.
---@type openmw.types.RecordList<openmw.types.LockpickRecord>
Lockpick.records = nil

---Whether the object is a Lockpick.
---@param object openmw.Object
---@return boolean
function Lockpick.objectIsInstance(object) end

---Returns the read-only LockpickRecord of a lockpick
---@param objectOrRecordId openmw.Object|string
---@return openmw.types.LockpickRecord|nil
function Lockpick.record(objectOrRecordId) end

---@type openmw.types.Probe
types.Probe = nil

---Creates a ProbeRecord without adding it to the world database.
---Use openmw.world.createRecord to add the record to the world.
---@param probe openmw.types.RecordDraft<openmw.types.ProbeRecord> A Lua table with ProbeRecord draft fields.
---@return openmw.types.RecordDraft<openmw.types.ProbeRecord> A strongly typed Probe record draft.
function Probe.createRecordDraft(probe) end

---A read-only list of all ProbeRecords in the world database.
---Implements a List of ProbeRecord.
---@type openmw.types.RecordList<openmw.types.ProbeRecord>
Probe.records = nil

---Whether the object is a Probe.
---@param object openmw.Object
---@return boolean
function Probe.objectIsInstance(object) end

---Returns the read-only ProbeRecord of a probe
---@param objectOrRecordId openmw.Object|string
---@return openmw.types.ProbeRecord|nil
function Probe.record(objectOrRecordId) end

---@type openmw.types.Repair
types.Repair = nil

---A read-only list of all RepairRecords in the world database.
---Implements a List of RepairRecord.
---@type openmw.types.RecordList<openmw.types.RepairRecord>
Repair.records = nil

---Whether the object is a Repair.
---@param object openmw.Object
---@return boolean
function Repair.objectIsInstance(object) end

---Returns the read-only RepairRecord of a repair tool
---@param objectOrRecordId openmw.Object|string
---@return openmw.types.RepairRecord|nil
function Repair.record(objectOrRecordId) end

---@type openmw.types.Activator
types.Activator = nil

---A read-only list of all ActivatorRecords in the world database.
---Implements a List of ActivatorRecord.
---@type openmw.types.RecordList<openmw.types.ActivatorRecord>
Activator.records = nil

---Whether the object is an Activator.
---@param object openmw.Object
---@return boolean
function Activator.objectIsInstance(object) end

---Returns the read-only ActivatorRecord of an activator
---@param objectOrRecordId openmw.Object|string
---@return openmw.types.ActivatorRecord|nil
function Activator.record(objectOrRecordId) end

---Creates an ActivatorRecord without adding it to the world database.
---Use openmw.world.createRecord to add the record to the world.
---@param activator openmw.types.RecordDraft<openmw.types.ActivatorRecord> A Lua table with ActivatorRecord draft fields.
---@return openmw.types.RecordDraft<openmw.types.ActivatorRecord> A strongly typed Activator record draft.
function Activator.createRecordDraft(activator) end

--------------------------------------------------------------------------------
---@type openmw.types.Container
types.Container = nil

---A read-only list of all ContainerRecords in the world database.
---Implements a List of ContainerRecord.
---@type openmw.types.RecordList<openmw.types.ContainerRecord>
Container.records = nil

---Container content.
---@overload fun(object: openmw.GObject): openmw.core.Inventory
---@overload fun(object: openmw.LObject|openmw.SelfObject): openmw.core.Inventory
---@param object openmw.LObject|openmw.GObject|openmw.SelfObject
---@return openmw.core.Inventory
function Container.content(object) end

---Creates a ContainerRecord without adding it to the world database.
---Use openmw.world.createRecord to add the record to the world.
---local containerTable = {name = "Respawning Treasure Chest", template = chestTemplate, isRespawning = true, weight = 150.0}
---local recordDraft = types.Container.createRecordDraft(containerTable)
---local newRecord = world.createRecord(recordDraft)
---world.createObject(newRecord.id):teleport(playerCell, playerPosition)
---@param container openmw.types.RecordDraft<openmw.types.ContainerRecord> A Lua table with ContainerRecord draft fields.
---@return openmw.types.RecordDraft<openmw.types.ContainerRecord> A strongly typed Container record draft.
function Container.createRecordDraft(container) end

---Container content (same as `Container.content`, added for consistency with `Actor.inventory`).
---@overload fun(object: openmw.GObject): openmw.core.Inventory
---@overload fun(object: openmw.LObject|openmw.SelfObject): openmw.core.Inventory
---@param object openmw.LObject|openmw.GObject|openmw.SelfObject
---@return openmw.core.Inventory
function Container.inventory(object) end

---Whether the object is a Container.
---@param object openmw.Object
---@return boolean
function Container.objectIsInstance(object) end

---Returns the total weight of everything in a container
---@param object openmw.Object
---@return number
function Container.getEncumbrance(object) end

---Returns the capacity of a container
---@param object openmw.Object
---@return number
function Container.getCapacity(object) end

---Returns the read-only ContainerRecord of a container
---@param objectOrRecordId openmw.Object|string
---@return openmw.types.ContainerRecord|nil
function Container.record(objectOrRecordId) end

--------------------------------------------------------------------------------
---@type openmw.types.Door
types.Door = nil

---@type openmw.types.DoorSTATE
Door.STATE = nil

---Creates a DoorRecord without adding it to the world database.
---Use openmw.world.createRecord to add the record to the world.
---@param door openmw.types.RecordDraft<openmw.types.DoorRecord> A Lua table with DoorRecord draft fields.
---@return openmw.types.RecordDraft<openmw.types.DoorRecord> A strongly typed Door record draft.
function Door.createRecordDraft(door) end

---A read-only list of all DoorRecords in the world database.
---Implements a List of DoorRecord.
---@type openmw.types.RecordList<openmw.types.DoorRecord>
Door.records = nil

---Whether the object is a Door.
---@param object openmw.Object
---@return boolean
function Door.objectIsInstance(object) end

---Whether the door is a teleport.
---@param object openmw.Object
---@return boolean
function Door.isTeleport(object) end

---Destination (only if a teleport door).
---@param object openmw.Object
---@return openmw.util.Vector3
function Door.destPosition(object) end

---Destination rotation (only if a teleport door).
---@param object openmw.Object
---@return openmw.util.Transform
function Door.destRotation(object) end

---Destination cell (only if a teleport door).
---@param object openmw.Object
---@return openmw.core.Cell|nil
function Door.destCell(object) end

---Returns the read-only DoorRecord of a door
---@param objectOrRecordId openmw.Object|string
---@return openmw.types.DoorRecord|nil
function Door.record(objectOrRecordId) end

---Gets the state of the door.
---@param object openmw.Object
---@return openmw.types.DoorState
function Door.getDoorState(object) end

---Checks if the door is fully open.
---Returns false if the door is currently opening or closing.
---@param object openmw.Object
---@return boolean
function Door.isOpen(object) end

---Checks if the door is fully closed.
---Returns false if the door is currently opening or closing.
---@param object openmw.Object
---@return boolean
function Door.isClosed(object) end

---Opens/Closes the door. Can only be used in global scripts or on self.
---@param object openmw.GObject|openmw.SelfObject
---@param openState? boolean Optional whether the door should be opened or closed. If not provided, the door will switch to the opposite state.
function Door.activateDoor(object, openState) end

---Functions for Static objects
---@type openmw.types.Static
types.Static = nil

---Creates a StaticRecord without adding it to the world database.
---Use openmw.world.createRecord to add the record to the world.
---@param static openmw.types.RecordDraft<openmw.types.StaticRecord> A Lua table with StaticRecord draft fields.
---@return openmw.types.RecordDraft<openmw.types.StaticRecord> A strongly typed Static record draft.
function Static.createRecordDraft(static) end

---A read-only list of all StaticRecords in the world database.
---Implements a List of StaticRecord.
---@type openmw.types.RecordList<openmw.types.StaticRecord>
Static.records = nil

---Whether the object is a Static.
---@param object openmw.Object
---@return boolean
function Static.objectIsInstance(object) end

---Returns the read-only StaticRecord of a Static
---@param objectOrRecordId openmw.Object|string
---@return openmw.types.StaticRecord|nil
function Static.record(objectOrRecordId) end

---@type openmw.types.LevelledCreature
types.LevelledCreature = nil

---A read-only list of all LevelledCreatureRecords in the world database.
---Implements a List of LevelledCreatureRecord.
---@type openmw.types.RecordList<openmw.types.LevelledCreatureRecord>
LevelledCreature.records = nil

---Whether the object is a LevelledCreature.
---@param object openmw.Object
---@return boolean
function LevelledCreature.objectIsInstance(object) end

---Returns the read-only LevelledCreatureRecord of a levelled creature
---@param objectOrRecordId openmw.Object|string
---@return openmw.types.LevelledCreatureRecord|nil
function LevelledCreature.record(objectOrRecordId) end

---Picks a random id from the levelled list.
---@param listRecord openmw.types.LevelledCreatureRecord The list
---@param MaxLvl number The maximum level to select entries for
---@return string An id
function LevelledCreatureRecord.getRandomId(listRecord, MaxLvl) end

return types
