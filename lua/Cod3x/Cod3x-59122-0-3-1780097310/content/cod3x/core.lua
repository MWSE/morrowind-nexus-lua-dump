---@meta

-- openmw.core
-- Functions and types available in local, global, and menu scripts.
-- @usage local core = require('openmw.core')

-- ============================================================
-- Magic
-- ============================================================

---@class MagicEffectId
---@field WaterBreathing number
---@field SwiftSwim number
---@field WaterWalking number
---@field Shield number
---@field FireShield number
---@field LightningShield number
---@field FrostShield number
---@field Burden number
---@field Feather number
---@field Jump number
---@field Levitate number
---@field SlowFall number
---@field Lock number
---@field Open number
---@field FireDamage number
---@field ShockDamage number
---@field FrostDamage number
---@field DrainAttribute number
---@field DrainHealth number
---@field DrainMagicka number
---@field DrainFatigue number
---@field DrainSkill number
---@field DamageAttribute number
---@field DamageHealth number
---@field DamageMagicka number
---@field DamageFatigue number
---@field DamageSkill number
---@field Poison number
---@field WeaknessToFire number
---@field WeaknessToFrost number
---@field WeaknessToShock number
---@field WeaknessToMagicka number
---@field WeaknessToCommonDisease number
---@field WeaknessToBlightDisease number
---@field WeaknessToCorprusDisease number
---@field WeaknessToPoison number
---@field WeaknessToNormalWeapons number
---@field DisintegrateWeapon number
---@field DisintegrateArmor number
---@field Invisibility number
---@field Chameleon number
---@field Light number
---@field Sanctuary number
---@field NightEye number
---@field Charm number
---@field Paralyze number
---@field Silence number
---@field Blind number
---@field Sound number
---@field CalmHumanoid number
---@field CalmCreature number
---@field FrenzyHumanoid number
---@field FrenzyCreature number
---@field DemoralizeHumanoid number
---@field DemoralizeCreature number
---@field RallyHumanoid number
---@field RallyCreature number
---@field Dispel number
---@field Soultrap number
---@field Telekinesis number
---@field Mark number
---@field Recall number
---@field DivineIntervention number
---@field AlmsiviIntervention number
---@field DetectAnimal number
---@field DetectEnchantment number
---@field DetectKey number
---@field SpellAbsorption number
---@field Reflect number
---@field CureCommonDisease number
---@field CureBlightDisease number
---@field CureCorprusDisease number
---@field CurePoison number
---@field CureParalyzation number
---@field RestoreAttribute number
---@field RestoreHealth number
---@field RestoreMagicka number
---@field RestoreFatigue number
---@field RestoreSkill number
---@field FortifyAttribute number
---@field FortifyHealth number
---@field FortifyMagicka number
---@field FortifyFatigue number
---@field FortifySkill number
---@field FortifyMaximumMagicka number
---@field AbsorbAttribute number
---@field AbsorbHealth number
---@field AbsorbMagicka number
---@field AbsorbFatigue number
---@field AbsorbSkill number
---@field ResistFire number
---@field ResistFrost number
---@field ResistShock number
---@field ResistMagicka number
---@field ResistCommonDisease number
---@field ResistBlightDisease number
---@field ResistCorprusDisease number
---@field ResistPoison number
---@field ResistNormalWeapons number
---@field ResistParalysis number
---@field RemoveCurse number
---@field TurnUndead number
---@field SummonScamp number
---@field SummonClannfear number
---@field SummonDaedroth number
---@field SummonDremora number
---@field SummonAncestralGhost number
---@field SummonSkeletalMinion number
---@field SummonBonewalker number
---@field SummonGreaterBonewalker number
---@field SummonBonelord number
---@field SummonWingedTwilight number
---@field SummonHunger number
---@field SummonGoldenSaint number
---@field SummonFlameAtronach number
---@field SummonFrostAtronach number
---@field SummonStormAtronach number
---@field FortifyAttack number
---@field CommandCreature number
---@field CommandHumanoid number
---@field BoundDagger number
---@field BoundLongsword number
---@field BoundMace number
---@field BoundBattleAxe number
---@field BoundSpear number
---@field BoundLongbow number
---@field ExtraSpell number
---@field BoundCuirass number
---@field BoundHelm number
---@field BoundBoots number
---@field BoundShield number
---@field BoundGloves number
---@field Corprus number
---@field Vampirism number
---@field SummonCenturionSphere number
---@field SunDamage number
---@field StuntedMagicka number
---@field SummonFabricant number
---@field SummonWolf number
---@field SummonBear number
---@field SummonBonewolf number
---@field SummonCreature04 number
---@field SummonCreature05 number

---@class SpellRange
---@field Self number Applied on self.
---@field Touch number On touch.
---@field Target number Ranged spell.

---@class SpellType
---@field Spell number Normal spell; must be cast and costs mana.
---@field Ability number Innate ability; always in effect.
---@field Blight number Blight disease.
---@field Disease number Common disease.
---@field Curse number Curse.
---@field Power number Power; can be used once a day.

---@class EnchantmentType
---@field CastOnce number Destroys the enchanted item on use.
---@field CastOnStrike number Cast on strike if there is enough charge.
---@field CastOnUse number Cast on use if there is enough charge.
---@field ConstantEffect number Always active when equipped.

---@class MagicEffectWithParams
---@field effect MagicEffect The full effect record.
---@field id string ID of the associated MagicEffect.
---@field affectedSkill? string Optional skill ID.
---@field affectedAttribute? string Optional attribute ID.
---@field range number
---@field area number
---@field magnitudeMin number
---@field magnitudeMax number
---@field duration number
---@field index number Index within the spell/enchantment/potion's effect list.

---@class MagicEffect
---@field id string Effect ID.
---@field icon string Effect icon path (VFS).
---@field name string Localized name.
---@field school string Skill ID of this effect's magic school.
---@field baseCost number
---@field color util.Color
---@field harmful boolean If true, elicits a hostile reaction from affected NPCs.
---@field continuousVfx boolean Whether the VFX should loop.
---@field hasDuration boolean Whether the effect has a duration.
---@field hasMagnitude boolean Whether the effect depends on a magnitude.
---@field isAppliedOnce boolean Whether applied fully on cast rather than continuously over the duration.
---@field casterLinked boolean If true, ends immediately when the caster dies or is not an actor.
---@field nonRecastable boolean If true, cannot be re-applied until it has ended (e.g. bound equipment).
---@field particle string Identifier of the particle texture.
---@field castStatic string VFX static identifier for casting.
---@field hitStatic string VFX static identifier on hit.
---@field areaStatic string VFX static identifier for AOE spells.
---@field bolt string Projectile identifier for ranged spells.
---@field castSound string Sound identifier for casting.
---@field hitSound string Sound identifier on hit.
---@field areaSound string Sound identifier for AOE spells.
---@field boltSound string Projectile sound identifier for ranged spells.

---@class Enchantment
---@field id string
---@field type EnchantmentType
---@field autocalcFlag boolean (Deprecated) Use `isAutocalc`.
---@field isAutocalc boolean If true, casting cost is computed from the effect list.
---@field cost number
---@field charge number Charge capacity (not current charge).
---@field effects MagicEffectWithParams[] Effects of the enchantment.

---@class Spell
---@field id string
---@field name string
---@field type SpellType
---@field cost number
---@field effects MagicEffectWithParams[]
---@field alwaysSucceedFlag boolean If true, ignores skill checks and always succeeds.
---@field starterSpellFlag boolean If true, can be selected as a player's starting spell.
---@field autocalcFlag boolean (Deprecated) Use `isAutocalc`.
---@field isAutocalc boolean If true, casting cost is computed from the effect list.

---@class ActiveSpellEffect
---@field index number Index within the original spell/enchantment/potion effect list.
---@field affectedSkill? string
---@field affectedAttribute? string
---@field id string Magic effect ID.
---@field name string Localized effect name.
---@field magnitudeThisFrame? number Current frame magnitude (random between min/max). Nil if no magnitude.
---@field minMagnitude? number Nil if no magnitude.
---@field maxMagnitude? number Nil if no magnitude.
---@field duration? number Total duration in seconds. Nil if not temporary.
---@field durationLeft? number Remaining duration in seconds. Nil if not temporary.

---@class ActiveSpell
---@field name string Spell or item display name.
---@field id string Record ID of the spell or item used to cast.
---@field item? GameObject Enchanted item used to cast; nil if not cast from an item, or if single-use (e.g. scroll).
---@field caster? GameObject The caster, or nil if undefined.
---@field fromEquipment boolean If true, tied to an equipped item and ends when unequipped.
---@field temporary boolean If true, will end on its own after duration or single application.
---@field affectsBaseValues boolean If true, affects base values rather than current values.
---@field stackable boolean If true, can be applied multiple times from the same source.
---@field activeSpellId number Uniquely identifies this spell within the affected actor's active spell list.
---@field effects ActiveSpellEffect[] Active effects of this spell.

---@class ActiveEffect
---@field affectedSkill? string
---@field affectedAttribute? string
---@field id string Effect ID string.
---@field name string Localized name.
---@field magnitude number Current magnitude. 0 when removed or expired.
---@field magnitudeBase number
---@field magnitudeModifier number

---@class Spells
--- Read-only list of all Spell records. May be indexed by recordId or numeric index.
---@field records Spell[]

---@class Effects
--- Map from MagicEffectId value to MagicEffect.
---@field records table<number, MagicEffect>

---@class Enchantments
--- Read-only list of all Enchantment records. May be indexed by recordId or numeric index.
---@field records Enchantment[]

---@class Magic
---@field ENCHANTMENT_TYPE EnchantmentType
---@field RANGE SpellRange
---@field EFFECT_TYPE MagicEffectId
---@field SPELL_TYPE SpellType
---@field spells Spells
---@field effects Effects
---@field enchantments Enchantments

-- ============================================================
-- Sound
-- ============================================================

---@class SoundRecord
---@field id string Sound ID.
---@field fileName string Normalized path to the sound file in VFS.
---@field volume number Raw volume (0–255).
---@field minRange number Raw minimum range (0–255).
---@field maxRange number Raw maximum range (0–255).

---@class Sound
--- Read-only list of all SoundRecords. May be indexed by recordId or numeric index.
---@field records SoundRecord[]
local Sound = {}

--- Check whether the sound system is enabled. Sound functions are no-ops when disabled.
---@return boolean
function Sound.isEnabled() end

--- Play a 3D sound attached to an object.
--- In local scripts, can only be used on self.
---@param soundId string ID of the Sound record to play.
---@param object GameObject Object to attach the sound to.
---@param options? {timeOffset: number, volume: number, pitch: number, loop: boolean}
function Sound.playSound3d(soundId, object, options) end

--- Play a 3D sound file attached to an object.
--- In local scripts, can only be used on self.
---@param fileName string Path to the sound file in VFS.
---@param object GameObject Object to attach the sound to.
---@param options? {timeOffset: number, volume: number, pitch: number, loop: boolean}
function Sound.playSoundFile3d(fileName, object, options) end

--- Stop a 3D sound attached to an object.
--- In local scripts, can only be used on self.
---@param soundId string ID of the Sound record to stop.
---@param object GameObject Object on which to stop the sound.
function Sound.stopSound3d(soundId, object) end

--- Stop a 3D sound file attached to an object.
--- In local scripts, can only be used on self.
---@param fileName string Path to the sound file in VFS.
---@param object GameObject Object on which to stop the sound.
function Sound.stopSoundFile3d(fileName, object) end

--- Check if a sound record is playing on the given object.
---@param soundId string ID of the Sound record.
---@param object GameObject
---@return boolean
function Sound.isSoundPlaying(soundId, object) end

--- Check if a sound file is playing on the given object.
---@param fileName string Path to the sound file in VFS.
---@param object GameObject
---@return boolean
function Sound.isSoundFilePlaying(fileName, object) end

--- Play an animated voiceover on an object.
--- In local scripts, can only be used on self.
---@param fileName string Path to the sound file in VFS.
---@param object GameObject Object on which to play the voiceover.
---@param text? string Subtitle text.
function Sound.say(fileName, object, text) end

--- Stop an animated voiceover on an object.
--- In local scripts, can only be used on self.
---@param object GameObject Object on which to stop the voiceover.
function Sound.stopSay(object) end

--- Check if an animated voiceover is playing on an object.
---@param object GameObject
---@return boolean
function Sound.isSayActive(object) end

-- ============================================================
-- Stats
-- ============================================================

---@class MagicSchoolData
---@field name string Human-readable name.
---@field areaSound string VFS path to area sound.
---@field boltSound string VFS path to bolt sound.
---@field castSound string VFS path to cast sound.
---@field failureSound string VFS path to failure sound.
---@field hitSound string VFS path to hit sound.

---@class AttributeRecord
---@field id string Record ID.
---@field name string Human-readable name.
---@field description string Human-readable description.
---@field icon string VFS path to the icon.

---@class SkillRecord
---@field id string Record ID.
---@field name string Human-readable name.
---@field description string Human-readable description.
---@field icon string VFS path to the icon.
---@field specialization string Either `"combat"`, `"magic"`, or `"stealth"`.
---@field school? MagicSchoolData Optional magic school data.
---@field attribute string ID of the governing attribute.
---@field skillGain table Four possible skill gain values. See `SkillProgression.SkillUseType`.

---@class Attribute
--- Read-only list of all AttributeRecords. May be indexed by recordId or numeric index.
---@field records AttributeRecord[]
local Attribute = {}

---@param recordId string
---@return AttributeRecord
function Attribute.record(recordId) end

---@class Skill
--- Read-only list of all SkillRecords. May be indexed by recordId or numeric index.
---@field records SkillRecord[]
local Skill = {}

---@param recordId string
---@return SkillRecord
function Skill.record(recordId) end

---@class Stats
---@field Attribute Attribute
---@field Skill Skill

-- ============================================================
-- Dialogue
-- ============================================================

---@class DialogueConditionOperator
---@field Equal number `==`
---@field NotEqual number `!=`
---@field Greater number `>`
---@field GreaterEqual number `>=`
---@field Less number `<`
---@field LessEqual number `<=`

---@class DialogueConditionType
---@field FacReactionLowest number Lowest faction reaction from speaker's faction to player's factions.
---@field FacReactionHighest number Highest faction reaction from speaker's faction to player's factions.
---@field RankRequirement number Whether the player can advance in the speaker's faction.
---@field Reputation number Speaker's reputation.
---@field HealthPercent number Speaker's health percentage.
---@field PcReputation number Player's reputation.
---@field PcLevel number Player's level.
---@field PcHealthPercent number Player's health percentage.
---@field PcMagicka number Player's current magicka.
---@field PcFatigue number Player's current fatigue.
---@field PcStrength number
---@field PcBlock number
---@field PcArmorer number
---@field PcMediumArmor number
---@field PcHeavyArmor number
---@field PcBluntWeapon number
---@field PcLongBlade number
---@field PcAxe number
---@field PcSpear number
---@field PcAthletics number
---@field PcEnchant number
---@field PcDestruction number
---@field PcAlteration number
---@field PcIllusion number
---@field PcConjuration number
---@field PcMysticism number
---@field PcRestoration number
---@field PcAlchemy number
---@field PcUnarmored number
---@field PcSecurity number
---@field PcSneak number
---@field PcAcrobatics number
---@field PcLightArmor number
---@field PcShortBlade number
---@field PcMarksman number
---@field PcMercantile number
---@field PcSpeechcraft number
---@field PcHandToHand number
---@field PcGender number Player's gender.
---@field PcExpelled number Whether the player has been expelled from the speaker's faction.
---@field PcCommonDisease number Whether the player has a common disease.
---@field PcBlightDisease number Whether the player has a blight disease.
---@field PcClothingModifier number Combined value of the player's outfit.
---@field PcCrimeLevel number Player's bounty.
---@field SameGender number Whether the speaker's gender matches the player's.
---@field SameRace number Whether the speaker's race matches the player's.
---@field SameFaction number Whether the player is in the speaker's faction.
---@field FactionRankDifference number Difference between player's and speaker's rank in the speaker's faction.
---@field Detected number Whether the speaker has detected the player.
---@field Alarmed number Whether the speaker was alarmed by the player's crime.
---@field Choice number The choice index.
---@field PcIntelligence number
---@field PcWillpower number
---@field PcAgility number
---@field PcSpeed number
---@field PcEndurance number
---@field PcPersonality number
---@field PcLuck number
---@field PcCorprus number Whether the player is affected by the Corprus magic effect.
---@field Weather number Checks the scriptId of the weather in the player's cell.
---@field PcVampire number Whether the player is affected by the Vampirism magic effect.
---@field Level number Speaker's level.
---@field Attacked number Whether the speaker was attacked.
---@field TalkedToPc number Whether the speaker has talked to the player before.
---@field PcHealth number Player's current health.
---@field CreatureTarget number Whether the speaker is targeting a creature.
---@field FriendHit number Times the player has hit the speaker follower.
---@field Fight number Speaker's current fight.
---@field Hello number Speaker's current hello.
---@field Alarm number Speaker's current alarm.
---@field Flee number Speaker's current flee.
---@field ShouldAttack number Whether the speaker would start combat with the player.
---@field Werewolf number Whether the speaker is in werewolf form.
---@field PcWerewolfKills number Number of werewolves killed by the player.
---@field Global number Comparison to the named global variable (`variableName`).
---@field Local number Comparison to the speaker's named local variable (`variableName`).
---@field Journal number Comparison to the player's journal index for `recordId`.
---@field Item number Number of copies of `recordId` the player is carrying.
---@field Dead number Number of dead actors of the given `recordId`.
---@field NotId number Speaker's recordId must not match `recordId`.
---@field NotFaction number Speaker's faction must not match `recordId`.
---@field NotClass number Speaker's class must not match `recordId`.
---@field NotRace number Speaker's race must not match `recordId`.
---@field NotCell number Player's cell name must not start with `cellName`.
---@field NotLocal number Comparison to the speaker's named local variable (inverted condition).

---@class DialogueInfoCondition
---@field operator DialogueConditionOperator
---@field type DialogueConditionType
---@field value number Value to compare against.
---@field recordId string Record ID used in the comparison.
---@field variableName string Name of the global or local mwscript variable.
---@field cellName string Cell name used in the comparison.

---@class DialogueRecordInfo
---@field id string Identifier within the parent DialogueRecord.
---@field text string Text for this entry.
---@field questStage? number Quest stage association (journal records only).
---@field isQuestFinished? boolean Whether this entry has the "Finished" flag (journal only).
---@field isQuestRestart? boolean Whether this entry has the "Restart" flag (journal only).
---@field isQuestName? boolean Whether this entry has the "Quest Name" flag (journal only).
---@field filterActorFaction? string Faction the speaker must be in. Non-journal only; nil means no filter.
---@field filterActorId? string Speaker ID filter. Non-journal only.
---@field filterActorRace? string Speaker race filter. Non-journal only.
---@field filterActorClass? string Speaker class filter. Non-journal only.
---@field filterActorFactionRank? number Minimum speaker rank in their faction (1-based). Non-journal only.
---@field filterPlayerCell? string Cell name prefix for the player's location. Non-journal only.
---@field filterActorDisposition? number Minimum speaker disposition (0 = no filter). Non-journal only.
---@field filterActorGender? string Speaker gender: `"male"` or `"female"`. Non-journal only.
---@field filterPlayerFaction? string Faction the player must be in. Non-journal only.
---@field filterPlayerFactionRank? number Minimum player rank in their faction (1-based). Non-journal only.
---@field sound? string Sound file path. Nil for journal records or if no sound is set.
---@field resultScript? string MWScript executed when chosen. Nil for journal records or if unset.
---@field conditions? DialogueInfoCondition[] Non-journal only.

---@class DialogueRecord
---@field id string Record identifier (lowercase).
---@field name string Same as id but with original casing preserved.
---@field questName? string Quest name (journal records only, when a "Quest Name" info entry exists).
---@field infos DialogueRecordInfo[] All info entries in order.

---@class DialogueRecords
--- Read-only list of all DialogueRecords. May be indexed by recordId (case-insensitive) or numeric index.
---@field records DialogueRecord[]

---@class Dialogue
---@field journal DialogueRecords Journal (quest) records.
---@field topic DialogueRecords Topic records.
---@field voice DialogueRecords Voice records.
---@field greeting DialogueRecords Greeting records.
---@field persuasion DialogueRecords Persuasion records.
---@field CONDITION_OPERATOR DialogueConditionOperator
---@field CONDITION_TYPE DialogueConditionType

-- ============================================================
-- Regions
-- ============================================================

---@class RegionSoundRef
---@field soundId string Sound record ID.
---@field chance number Multiplicative percentage (0–100) to play the sound.

---@class RegionRecord
---@field id string Region ID.
---@field name string Display name.
---@field mapColor util.Color Editor map colour for this region.
---@field sleepList string Leveled creature list used when sleeping outdoors here.
---@field sounds RegionSoundRef[] Ambient sound references.
---@field weatherProbabilities table<string, number> Maps weather record IDs to probability (0–100), should sum to 100.

---@class Regions
--- Read-only list of all RegionRecords.
---@field records RegionRecord[]

-- ============================================================
-- Factions
-- ============================================================

---@class FactionRank
---@field name string Rank display name.
---@field attributeValues number[] Attribute values required for this rank.
---@field primarySkillValue number Primary skill value required.
---@field favouredSkillValue number Secondary skill value required.
---@field factionReputation number Required faction reputation.
---@field factionReaction number (Deprecated) Same as `factionReputation`.

---@class FactionRecord
---@field id string
---@field name string
---@field ranks FactionRank[] All ranks in order.
---@field reactions table<string, number> Reactions of other factions to this faction.
---@field attributes string[] Attribute IDs required for rank advancement.
---@field skills string[] Skill IDs required for rank advancement.
---@field hidden boolean If true, will not appear in the player's skills menu.

---@class Factions
--- Read-only list of all FactionRecords.
---@field records FactionRecord[]

-- ============================================================
-- MWScripts
-- ============================================================

---@class MWScriptRecord
---@field id string MWScript ID.
---@field text string Script content.

---@class MWScripts
--- Read-only list of all MWScriptRecords.
---@field records MWScriptRecord[]

-- ============================================================
-- Weather
-- ============================================================

---@class TimeOfDayInterpolatorFloat
---@field sunrise number
---@field sunset number
---@field day number
---@field night number

---@class TimeOfDayInterpolatorColor
---@field sunrise util.Color
---@field sunset util.Color
---@field day util.Color
---@field night util.Color

---@class WeatherRecord
---@field recordId string
---@field scriptId number Read-only ID used in mwscript and dialogue.
---@field name string Read-only weather name.
---@field windSpeed number Affects the angle of falling rain.
---@field cloudSpeed number
---@field cloudTexture string
---@field cloudsMaximumPercent number Affects transition speed (0, 1].
---@field isStorm boolean Whether the weather is considered a storm for animation and movement.
---@field stormDirection util.Vector3
---@field glareView number Strength of sun glare [0, 1].
---@field rainSpeed number Speed at which rain falls.
---@field rainEntranceSpeed number Seconds between rain particle batch creation.
---@field rainEffect? string Nil if the weather has no rain effect.
---@field rainMaxRaindrops number Maximum rain particle batches per `rainEntranceSpeed`.
---@field rainDiameter number Area around the player to spawn rain in.
---@field rainMaxHeight number Maximum height relative to the player to spawn rain.
---@field rainMinHeight number Minimum height relative to the player to spawn rain.
---@field rainLoopSoundID string
---@field thunderSoundID string[] Record IDs of thunder sounds.
---@field ambientLoopSoundID string
---@field particleEffect? string Nil if the weather has no particle effect.
---@field distantLandFogFactor number
---@field distantLandFogOffset number
---@field sunDiscSunsetColor util.Color
---@field landFogDepth TimeOfDayInterpolatorFloat
---@field skyColor TimeOfDayInterpolatorColor
---@field ambientColor TimeOfDayInterpolatorColor
---@field fogColor TimeOfDayInterpolatorColor
---@field sunColor TimeOfDayInterpolatorColor

---@class Weather
--- Read-only list of all WeatherRecords. May be indexed by recordId or numeric index.
---@field records WeatherRecord[]
local Weather = {}

--- Get the current weather for a cell.
---@param cell Cell
---@return WeatherRecord? Nil if the cell is inactive or has no weather.
function Weather.getCurrent(cell) end

--- Get the next weather for a cell, if a transition is in progress.
---@param cell Cell
---@return WeatherRecord?
function Weather.getNext(cell) end

--- Get the current weather transition value for a cell.
---@param cell Cell
---@return number? Nil if the cell is inactive or has no weather.
function Weather.getTransition(cell) end

--- Change the weather for a region.
---@param regionId string
---@param weather WeatherRecord
function Weather.changeWeather(regionId, weather) end

--- Get the current sun light direction for a cell.
---@param cell Cell
---@return util.Vector4? Nil if the cell is inactive.
function Weather.getCurrentSunLightDirection(cell) end

--- Get the current sun visibility (accounting for weather transition) for a cell.
---@param cell Cell
---@return number? Nil if the cell is inactive or has no weather.
function Weather.getCurrentSunVisibility(cell) end

--- Get the current sun percentage (accounting for weather transition) for a cell.
---@param cell Cell
---@return number? Nil if the cell is inactive or has no weather.
function Weather.getCurrentSunPercentage(cell) end

--- Get the current wind speed (accounting for weather transition) for a cell.
---@param cell Cell
---@return number? Nil if the cell is inactive or has no weather.
function Weather.getCurrentWindSpeed(cell) end

--- Get the current storm direction (accounting for weather transition) for a cell.
---@param cell Cell
---@return util.Vector3? Nil if the cell is inactive or has no weather.
function Weather.getCurrentStormDirection(cell) end

-- ============================================================
-- ContentFiles
-- ============================================================

---@class ContentFiles
--- The current load order (list of content file names).
---@field list string[]
local ContentFiles = {}

--- Return the index of a content file in the load order, or nil if absent.
---@param contentFile string
---@return number?
function ContentFiles:indexOf(contentFile) end

--- Check if a content file is present in the load order.
---@param contentFile string
---@return boolean
function ContentFiles:has(contentFile) end

-- ============================================================
-- Land
-- ============================================================

---@class Land
local Land = {}

--- Get the terrain height at a given location.
---@param position util.Vector3
---@param cellOrId Cell|string Cell or cell ID in its exterior world space.
---@return number
function Land.getHeightAt(position, cellOrId) end

--- Get the terrain texture at a given location.
--- Returns the texture whose centre is closest to the position.
---@param position util.Vector3
---@param cellOrId Cell|string Cell or cell ID in its exterior world space.
---@return string? texturePath Texture path, or nil if not defined.
---@return string? pluginName Plugin name, or nil if retrieval failed.
function Land.getTextureAt(position, cellOrId) end

-- ============================================================
-- GameObject hierarchy
--
--   GameObject    (base: read-only fields, non-mutating methods)
--   ├── LObject   (local scripts, non-self objects — purely read-only)
--   │   └── SelfObject  (the `self` object — adds controls, AI, etc.)
--   └── GObject   (global scripts — adds writable fields and mutation methods)
-- ============================================================

---@class TeleportOptions
---@field rotation? util.Transform New rotation. If omitted, the current rotation is kept.
---@field onGround? boolean If true, adjust the destination position to ground level.

--- Ownership information for a game object.
--- `recordId`, `factionId`, and `factionRank` are settable from global and self scripts only.
---@class ObjectOwner
---@field recordId? string NPC who owns the object.
---@field factionId? string Faction who owns the object.
---@field factionRank? number Minimum rank required to pick up the object. Nil means any rank is allowed.

--- A pathgrid point in a cell's pathgrid.
---@class PathGridPoint
---@field autoGenerated boolean True if this node was automatically generated in the editor.
---@field relativePosition util.Vector3 Position relative to the cell's origin (exterior: south-west corner).
---@field connections PathGridPoint[] List of directly connected points.

--- A cell's pathgrid marking traversable paths.
---@class PathGrid
local PathGrid = {}

--- Get all points in this pathgrid.
---@return PathGridPoint[]
function PathGrid:getPoints() end

--- A cell of the game world.
---@class Cell
---@field name string Cell name (may be empty).
---@field displayName string Human-readable cell name accounting for localisation. May be empty.
---@field id string Unique record ID. Interior: cell name. Exterior: worldspace. ESM4: formID.
---@field region? string Region of the cell. Nil if none.
---@field isExterior boolean Whether this is an exterior cell. QuasiExterior is NOT counted as exterior.
---@field isQuasiExterior boolean (Deprecated) Use `hasTag("QuasiExterior")` instead.
---@field gridX number Cell grid X index (exteriors only).
---@field gridY number Cell grid Y index (exteriors only).
---@field worldSpaceId? string ID of the world space.
---@field hasWater boolean Whether the cell contains water.
---@field waterLevel? number Water level. Nil if the cell has no water.
---@field hasSky boolean Whether sky should be rendered in this cell.
---@field pathGrid? PathGrid The cell's pathgrid, if it has one.
local Cell = {}

--- Returns true if the cell has the given tag.
---@param tag string One of `"QuasiExterior"`, `"NoSleep"`.
---@return boolean
function Cell:hasTag(tag) end

--- Returns true if the cell contains the object, or if both are in any exterior of the same worldspace.
---@param object GameObject
---@return boolean
---@usage if obj1.cell:isInSameSpace(obj2) then
---    local dist = (obj1.position - obj2.position):length()
--- end
function Cell:isInSameSpace(object) end

--- Cell handle available to local scripts. Carries no additional methods over `Cell`.
---@class LCell : Cell

--- Cell handle available to global scripts. Adds `getAll`.
---@class GCell : Cell
local GCell = {}

--- Get all objects of the given type in the cell.
---@param type? any Object type table from `openmw.types`.
---@return ObjectList
---@usage local weapons = cell:getAll(types.Weapon)
function GCell:getAll(type) end

--- An inventory or container content store. Available in both local and global scripts.
---@class Inventory
local Inventory = {}

--- Count items with the given recordId.
---@param recordId string
---@return number
function Inventory:countOf(recordId) end

--- Get all items of the given type.
---@param type? any Item type table from `openmw.types`.
---@return ObjectList
function Inventory:getAll(type) end

--- Get the first item with the given recordId, or nil if not found.
---@param recordId string
---@return GameObject?
function Inventory:find(recordId) end

--- Get all items with the given recordId.
---@param recordId string
---@return ObjectList
function Inventory:findAll(recordId) end

--- Check whether the inventory has a resolved (permanent) item list.
---@return boolean
function Inventory:isResolved() end

--- Inventory available to global scripts. Adds `resolve`.
---@class WritableInventory : Inventory
local WritableInventory = {}

--- Fill levelled lists and make the inventory's contents permanent.
function WritableInventory:resolve() end

--- List of GameObjects. Behaves as an array; supports `#`, numeric indexing, `ipairs`, and `pairs`.
---@class ObjectList : GameObject[]

-- ============================================================
-- Base GameObject
-- All fields below are available on LObject, GObject, and SelfObject.
-- Fields marked "(GObject only)" are only settable from global scripts.
-- ============================================================

---@class GameObject
---@field id string Unique object instance ID (not record ID). Stable across frames; usable as a table key.
---@field contentFile? string Lowercase content file name that defines this object. Nil for dynamically created objects.
---@field enabled boolean Whether the object is enabled. **GObject**: settable. Items in containers cannot be disabled.
---@field position util.Vector3 Current world position (read-only; use `teleport` on GObject to move).
---@field scale number Current scale (read-only; use `setScale` on GObject).
---@field rotation util.Transform Current rotation (read-only; use `teleport` on GObject to change).
---@field startingPosition util.Vector3 Original position from the content file.
---@field startingRotation util.Transform Original rotation from the content file.
---@field owner ObjectOwner Ownership information. Fields are settable from global and self scripts.
---@field cell? Cell The cell the object is in. Nil during loading or when inside a container/inventory. Typed as `LCell` on LObject/SelfObject, `GCell` on GObject.
---@field parentContainer? GameObject The container or actor holding this object. Nil if in a cell.
---@field type any Object type table from `openmw.types` (e.g. `types.NPC`, `types.Weapon`).
---@field count number Stack count (>1 means a stack of identical items).
---@field recordId string Record ID in lowercase.
---@field globalVariable? string Global variable associated with this object (read-only).
local GameObject = {}

--- Returns true if the object exists and is loaded. If false, any field access will raise an error.
---@return boolean
function GameObject:isValid() end

--- Send a local event to this object's scripts.
---@param eventName string
---@param eventData any
function GameObject:sendEvent(eventName, eventData) end

--- Activate this object as if triggered by the given actor.
---@param actor GameObject The actor performing the activation.
---@usage object:activateBy(self)
function GameObject:activateBy(actor) end

--- Return the axis-aligned bounding box in world coordinates.
---@return util.Box
function GameObject:getBoundingBox() end

-- ============================================================
-- LObject
-- Used in local scripts to reference objects other than `self`.
-- All fields are read-only; mutation methods are not available.
-- ============================================================

---@class LObject : GameObject
---@field cell? LCell

-- ============================================================
-- GObject
-- Used in global scripts. Inherits all fields from GameObject
-- and adds writable fields plus all mutation methods.
-- ============================================================

---@class GObject : GameObject
---@field cell? GCell
---@field enabled boolean Whether the object is enabled (settable).
local GObject = {}

--- Set the object's scale.
---@param scale number
function GObject:setScale(scale) end

--- Attach a local script to this object.
--- The script path must be declared in a content file with the `CUSTOM` flag.
--- Cannot be used on Statics.
---@param scriptPath string Path in the OpenMW VFS.
---@param initData? table Initialisation data passed to `onInit`. Defaults to content-file init data if omitted.
function GObject:addScript(scriptPath, initData) end

--- Returns true if a script with the given path is attached to this object.
---@param scriptPath string Path in the OpenMW VFS.
---@return boolean
function GObject:hasScript(scriptPath) end

--- Remove a script that was attached via `addScript`. Cannot remove auto-started scripts.
---@param scriptPath string Path in the OpenMW VFS.
function GObject:removeScript(scriptPath) end

--- Move the object to the given cell and position.
--- Effect is deferred to the next frame. Enables the object if it was disabled.
--- Can move objects out of containers/inventories into the world.
---@param cellOrName Cell|string Destination cell, cell name, or `""` for the default exterior worldspace.
---@param position util.Vector3 New world position.
---@param options? TeleportOptions|util.Transform Optional rotation or options table.
function GObject:teleport(cellOrName, position, options) end

--- Move this object into a container or inventory. Enables the object if disabled.
---@param dest Inventory|GObject Destination inventory or container object.
---@usage item:moveInto(types.Actor.inventory(actor))
---@usage item:moveInto(container)
function GObject:moveInto(dest) end

--- Remove the object, or reduce its stack by `count`.
---@param count? number Number of items to remove. Defaults to the full stack.
function GObject:remove(count) end

--- Split a stack: reduces this stack by `count` and returns a new disabled stack with `count` items.
---@param count number Number of items to split off.
---@return GObject
---@usage money:split(50):moveInto(types.Container.content(chest))
function GObject:split(count) end

-- ============================================================
-- SelfObject
-- The object a local script is attached to. Extends LObject
-- with actor controls, AI helpers, and the ATTACK_TYPE enum.
-- Exposed as the `openmw.self` module value.
-- ============================================================

---@class ATTACK_TYPE
---@field NoAttack number
---@field Any number
---@field Chop number
---@field Slash number
---@field Thrust number

--- Mutable movement and action controls for the actor this script is attached to.
--- All fields are read/write.
---@class ActorControls
---@field movement number `+1` move forward, `-1` move backward.
---@field sideMovement number `+1` move right, `-1` move left.
---@field yawChange number Turn right (radians); negative to turn left.
---@field pitchChange number Look down (radians); negative to look up.
---@field run boolean `true` to run, `false` to walk.
---@field sneak boolean `true` to sneak.
---@field jump boolean `true` to initiate a jump.
---@field use ATTACK_TYPE Activates the readied weapon/spell. Hold to charge. Set to `ATTACK_TYPE.NoAttack` to release.

---@class SelfObject : LObject
--- The object this local script is attached to (read-only reference).
---@field object LObject
--- Movement and action controls. Available on actors only.
---@field controls ActorControls
--- Attack type constants. Use with `controls.use`.
---@field ATTACK_TYPE ATTACK_TYPE
local SelfObject = {}

--- Returns true if this object is in an active cell.
--- When inactive, `openmw.nearby` is unavailable.
---@return boolean
function SelfObject:isActive() end

--- Enable or disable the standard AI for this actor (enabled by default).
---@param v boolean
function SelfObject:enableAI(v) end

-- ============================================================
-- core module
-- ============================================================

---@class core
---@field API_REVISION number Incremented every time the Lua API changes.
---@field contentFiles ContentFiles
---@field land Land
---@field magic Magic
---@field sound Sound
---@field stats Stats
---@field dialogue Dialogue
---@field regions Regions
---@field factions Factions
---@field mwscripts MWScripts
---@field weather Weather
local core = {}

--- Terminate the game and quit to the OS. For testing purposes only.
function core.quit() end

--- Send an event to all global scripts.
--- In menu scripts, raises an error if the game is not running (see `menu.getState`).
---@param eventName string
---@param eventData any
function core.sendGlobalEvent(eventName, eventData) end

--- Simulation time in seconds since the start of the current game.
---@return number
function core.getSimulationTime() end

--- Scale of simulation time relative to real time.
---@return number
function core.getSimulationTimeScale() end

--- Game time in seconds.
---@return number
function core.getGameTime() end

--- Scale of game time relative to simulation time.
---@return number
function core.getGameTimeScale() end

--- Whether the world is currently paused.
---@return boolean
function core.isWorldPaused() end

--- Real time in seconds. The starting point is not fixed; use only for measuring intervals.
--- For Unix time use `os.time()`.
---@return number
function core.getRealTime() end

--- Duration of the last frame in seconds.
--- **Not available in global scripts.**
---@return number
function core.getRealFrameDuration() end

--- Get a game setting by name (from GMST ESM records or `openmw.cfg`).
---@param setting string Setting name.
---@return any
---@usage local skillBonus = core.getGMST('fMinorSkillBonus')
---@usage local jailMsg = core.getGMST('sNotifyMessage42')
---@usage local blood = core.getGMST('Blood_Texture_1')
function core.getGMST(setting) end

--- The game's current difficulty setting.
---@return number
function core.getGameDifficulty() end

--- Return an l10n formatting function for the given context.
--- Localisation files must be stored in VFS as `l10n/<ContextName>/<Locale>.yaml`.
--- If no translation is found for any requested locale, the message key is returned (and formatted if possible).
---@param context string l10n context name (recommended: the mod name). Must match the VFS directory.
---@param fallbackLocale? string Source locale containing default messages (default: `"en"`).
---@return fun(key: string, args?: table): string
---@usage local t = core.l10n('MyMod', 'en')
---@usage print(t('good_morning'))
---@usage print(t('you_have_arrows', { count = 5 }))
function core.l10n(context, fallbackLocale) end

--- Construct a FormId string from a content file name and a record index.
--- In ESM3 (e.g. Morrowind) FormIds reference game objects. In ESM4 (e.g. Skyrim) they also serve as record IDs.
---@param contentFile string
---@param index number
---@return string
---@usage if obj.recordId == core.getFormId('Skyrim.esm', 0x4d7da) then end
---@usage local obj = nearby.getObjectByFormId(core.getFormId('Morrowind.esm', 128964))
function core.getFormId(contentFile, index) end

return core

