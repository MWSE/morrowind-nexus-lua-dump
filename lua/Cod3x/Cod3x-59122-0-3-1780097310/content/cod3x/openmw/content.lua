---@meta

-- This file was mechanically drafted from files/lua_api/openmw/content.lua.
-- It uses LuaLS/LLS annotations and stub bodies only; runtime behavior is provided by OpenMW.
-- OpenMW script contexts: load

---Allows for manipulation of the data loaded from content files while the game is first started.
---Records can be created and deleted using this package as if a content file had done so.
---@class openmw.content
local content = {}

---@class openmw.content.ActivatorContent
local ActivatorContent = {}

---@class openmw.content.BookContent
local BookContent = {}

---@class openmw.content.DoorContent
local DoorContent = {}

---@class openmw.content.EnchantmentContent
local EnchantmentContent = {}

---@class openmw.content.GMSTContent
local GMSTContent = {}

---@class openmw.content.GlobalContent
local GlobalContent = {}

---@class openmw.content.IngredientContent
local IngredientContent = {}

---@class openmw.content.LightContent
local LightContent = {}

---@class openmw.content.LockpickContent
local LockpickContent = {}

---@class openmw.content.MagicEffectContent
local MagicEffectContent = {}

---@class openmw.content.MiscContent
local MiscContent = {}

---@class openmw.content.PotionContent
local PotionContent = {}

---@class openmw.content.ProbeContent
local ProbeContent = {}

---@class openmw.content.RepairContent
local RepairContent = {}

---@class openmw.content.SoundContent
local SoundContent = {}

---@class openmw.content.SpellContent
local SpellContent = {}

---@class openmw.content.StaticContent
local StaticContent = {}


---@type openmw.core.SpellRange
content.RANGE = nil

---@type openmw.content.ActivatorContent
content.activators = nil

---A mutable list of all openmw.types.ActivatorRecords.
---content.activators.records.MyActivator = { mwscript = 'float', model = 'meshes/w/w_chitin_arrow.nif', name = 'Quest marker' }
---@type openmw.types.ActivatorRecord[]
ActivatorContent.records = nil

---@type openmw.content.BookContent
content.books = nil

---A mutable list of all openmw.types.BookRecords.
---content.books.records.MyBook = { template = content.books.records['bk_lustyargonianmaid'], text = content.books.records['bk_BoethiahPillowBook'].text }
---@type openmw.types.BookRecord[]
BookContent.records = nil

---@type openmw.content.DoorContent
content.doors = nil

---A mutable list of all openmw.types.DoorRecords.
---content.doors.records.MyDoor = { template = content.doors.records['door_dwrv_double00'], mwscript = 'blockedDoor', name = 'Overly Heavy Dwemer Door' }
---@type openmw.types.DoorRecord[]
DoorContent.records = nil

---@type openmw.content.EnchantmentContent
content.enchantments = nil

---@type openmw.core.EnchantmentType
EnchantmentContent.TYPE = nil

---A mutable list of all openmw.core.Enchantments.
---content.enchantments.records.MyEnchantment = { type = content.enchantments.TYPE.CastOnUse, charge = 1, cost = 1, effects = { { id = 'FortifySkill', affectedSkill = 'enchant', duration = 5, magnitudeMin = 50, magnitudeMax = 100 } } }
---@type openmw.core.Enchantment[]
EnchantmentContent.records = nil

---@type openmw.content.GMSTContent
content.gameSettings = nil

---Returns a table containing all fallback values defined in `openmw.cfg`.
---@return table
function GMSTContent.getFallbacks() end

---A mutable list of all game settings.
---content.gameSettings.records.fJumpAcrobaticsBase = 1024
---@type table<string, any>
GMSTContent.records = nil

---@type openmw.content.GlobalContent
content.globals = nil

---A mutable list of all global mwscript variables.
---content.globals.records.MyVariable = 42
---@type table<string, number>
GlobalContent.records = nil

---@type openmw.content.IngredientContent
content.ingredients = nil

---A mutable list of all openmw.types.IngredientRecords.
---Note that ingredient effects only have the `id`, `affectedAttribute`, and `affectedSkill` properties.
---content.ingredients.records.MyIngredient = { template = content.ingredients.records['ingred_ectoplasm_01'], name = 'Soylent', effects = { { id = 'vampirism' } } }
---@type openmw.types.IngredientRecord[]
IngredientContent.records = nil

---@type openmw.content.LightContent
content.lights = nil

---A mutable list of all openmw.types.LightRecords.
---content.lights.records.MyLight = { template = content.lights.records['torch'], duration = -1, name = 'Infinite Torch' }
---@type openmw.types.LightRecord[]
LightContent.records = nil

---@type openmw.content.LockpickContent
content.lockpicks = nil

---A mutable list of all openmw.types.LockpickRecords.
---content.lockpicks.records.MyLockpick = { template = content.lockpicks.records['skeleton_key'], name = 'Digipick' }
---@type openmw.types.LockpickRecord[]
LockpickContent.records = nil

---@type openmw.content.MagicEffectContent
content.magicEffects = nil

---A mutable list of all openmw.core.MagicEffects.
---content.magicEffects.records.MyMagicEffect = { template = content.magicEffects.records['summonscamp'], name = 'Summon Nothing' }
---@type openmw.core.MagicEffect[]
MagicEffectContent.records = nil

---@type openmw.content.MiscContent
content.miscs = nil

---A mutable list of all openmw.types.MiscellaneousRecords.
---content.miscs.records.MyMisc = { template = content.miscs.records['gold_001'], mwscript = 'BILL_MarksSpiritSummon', weight = 5 }
---@type openmw.types.MiscellaneousRecord[]
MiscContent.records = nil

---@type openmw.content.PotionContent
content.potions = nil

---A mutable list of all openmw.types.PotionRecords.
---content.potions.records.MyPotion = { template = content.potions.records['p_dispel_s'], name = 'Too Strong', effects = { { id = 'FireDamage', duration = 10, range = content.RANGE.Self, magnitudeMin = 100 } } }
---@type openmw.types.PotionRecord[]
PotionContent.records = nil

---@type openmw.content.ProbeContent
content.probes = nil

---A mutable list of all openmw.types.ProbeRecords.
---content.probes.records.MyProbe = { template = content.probes.records['probe_bent'], quality = 5, name = 'Alien Probe' }
---@type openmw.types.ProbeRecord[]
ProbeContent.records = nil

---@type openmw.content.RepairContent
content.repairs = nil

---A mutable list of all openmw.types.RepairRecords.
---content.repairs.records.MyRepair = { template = content.repairs.records['hammer_repair'], name = 'Hammer Time' }
---@type openmw.types.RepairRecord[]
RepairContent.records = nil

---@type openmw.content.SpellContent
content.spells = nil

---@type openmw.core.SpellType
SpellContent.TYPE = nil

---A mutable list of all openmw.core.Spells.
---content.spells.records.MySpell = { name = 'Enchantment?', type = content.spells.TYPE.Spell, cost = 1000, starterSpellFlag = true, isAutocalc = true, effects = { { id = 'FortifyAttribute', affectedAttribute = 'intelligence', duration = 5, magnitudeMin = 5, magnitudeMax = 10 } } }
---@type openmw.core.Spell[]
SpellContent.records = nil

---@type openmw.content.StaticContent
content.statics = nil

---A mutable list of all openmw.types.StaticRecords.
---content.statics.records.MyStatic = { model = 'meshes/b/B_N_Wood Elf_M_Head_02.nif' }
---@type openmw.types.StaticRecord[]
StaticContent.records = nil

---@type openmw.content.SoundContent
content.sounds = nil

---A mutable list of all openmw.core.SoundRecords.
---content.sounds.records.MySound = { template = content.sounds.records['MournDayAmb'], fileName = 'sound/fx/funny.wav' }
---@type openmw.core.SoundRecord[]
SoundContent.records = nil

return content
