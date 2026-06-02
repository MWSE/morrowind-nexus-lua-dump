---@meta

-- This file was mechanically drafted from files/lua_api/openmw/world.lua.
-- It uses LuaLS/LLS annotations and stub bodies only; runtime behavior is provided by OpenMW.
-- OpenMW script contexts: global

---Provides an interface to the game world for global scripts.
---@class openmw.world
local world = {}

---@class openmw.world.VFX
local VFX = {}


---Functions related to MWScript.
---@class openmw.world.MWScriptFunctions
local MWScriptFunctions = {}

---@class openmw.world.MWScriptVariables: table<string, number>
local MWScriptVariables = {}

---for _, script in ipairs(world.mwscript.getLocalScripts(object)) do
---end
---@class openmw.world.MWScript
---@field recordId string Id of the script
---@field object openmw.GObject The object the script is attached to.
---@field player openmw.GObject The player the script refers to.
---@field isRunning boolean Whether the script is currently running
---@field variables openmw.world.MWScriptVariables Local variables of the script (mutable)
local MWScript = {}

---List of currently active actors.
---@type openmw.ObjectList<openmw.GObject>
world.activeActors = nil

---List of players. Currently (since multiplayer is not yet implemented) always has one element.
---@type openmw.ObjectList<openmw.GObject>
world.players = nil

---Functions related to MWScript (see MWScriptFunctions).
---@type openmw.world.MWScriptFunctions
world.mwscript = nil

---Returns local mwscript on ``object``. Returns `nil` if the script doesn't exist or is not started.
---@param object openmw.GObject
---@param player? openmw.GObject (optional) Will be used in multiplayer mode to get the script if there is a separate instance for each player. Currently has no effect.
---@return openmw.world.MWScript|nil
function MWScriptFunctions.getLocalScript(object, player) end

---Returns mutable global variables. In multiplayer, these may be specific to the provided player.
---@param player? openmw.GObject (optional) Will be used in multiplayer mode to get the globals if there is a separate instance for each player. Currently has no effect.
---@return openmw.world.MWScriptVariables
function MWScriptFunctions.getGlobalVariables(player) end

---Returns global mwscript with given recordId. Returns `nil` if the script doesn't exist or is not started.
---Currently there can be only one instance of each mwscript, but in multiplayer it will be possible to have a separate instance per player.
---@param recordId string
---@param player? openmw.GObject (optional) Will be used in multiplayer mode to get the script if there is a separate instance for each player. Currently has no effect.
---@return openmw.world.MWScript|nil
function MWScriptFunctions.getGlobalScript(recordId, player) end

---Loads a named cell
---@param cellName string
---@return openmw.core.GCell
function world.getCellByName(cellName) end

---Loads a cell by ID provided
---@param cellId string
---@return openmw.core.GCell
function world.getCellById(cellId) end

---Loads an exterior cell by grid indices
---@param gridX number
---@param gridY number
---@param cellOrName? any (optional) other cell or cell name in the same exterior world space
---@return openmw.core.GCell
function world.getExteriorCell(gridX, gridY, cellOrName) end

---List of all cells
---@type openmw.core.GCell[]
world.cells = nil

---Simulation time in seconds.
---The number of simulation seconds passed in the game world since starting a new game.
---@return number
function world.getSimulationTime() end

---The scale of simulation time relative to real time.
---@return number
function world.getSimulationTimeScale() end

---Set the simulation time scale.
---@param scale number
function world.setSimulationTimeScale(scale) end

---Game time in seconds.
---@return number
function world.getGameTime() end

---The scale of game time relative to simulation time.
---@return number
function world.getGameTimeScale() end

---Set the ratio of game time speed to simulation time speed.
---@param ratio number
function world.setGameTimeScale(ratio) end

---Whether the world is paused.
---@return boolean
function world.isWorldPaused() end

---Pause the game starting from the next frame.
---@param tag? string (optional, empty string by default) The game will be paused until `unpause` is called with the same tag.
function world.pause(tag) end

---Remove the given tag from the list of pause tags. Resume the game starting from the next frame if the list became empty.
---@param tag? string (optional, empty string by default) Needed to undo `pause` called with this tag.
function world.unpause(tag) end

---The tags that are currently pausing the game.
---@return table
function world.getPausedTags() end

---Return an object by RefNum/FormId.
---Note: the function always returns openmw.GObject and doesn't validate that
---the object exists in the game world. If it doesn't exist or not yet loaded to memory),
---then `obj:isValid()` will be `false`.
---@param formId string String returned by `core.getFormId`
---@return openmw.GObject
function world.getObjectByFormId(formId) end

---Create a new instance of the given record.
---After creation the object is in the disabled state. Use :teleport to place to the world or :moveInto to put it into a container or an inventory.
---Note that dynamically created creatures, NPCs, and container inventories will not respawn.
---money = world.createObject('gold_001', 100)
---money:teleport(actor.cell.name, actor.position)
---money = world.createObject('gold_001', 50)
---money:moveInto(types.Actor.inventory(actor))
---potion = world.createObject('Generated:0x0', 1)
---@param recordId string Record ID. String ids that came from ESM3 content files are lower-cased. If another ID is provided, it must be provided exactly as it is, case sensitive.
---@param count? number (optional, 1 by default) The number of objects in stack
---@return openmw.GObject
function world.createObject(recordId, count) end

---Creates a custom record in the world database; string IDs that came from ESM3 content files are lower-cased.
---Eventually meant to support all records, but the current
---set of supported types is limited to:
---* openmw.types.ActivatorRecord,
---* openmw.types.ArmorRecord,
---* openmw.types.BookRecord,
---* openmw.types.ClothingRecord,
---* openmw.types.ContainerRecord,
---* openmw.types.CreatureRecord,
---* openmw.types.DoorRecord,
---* openmw.core.Enchantment,
---* openmw.types.LightRecord,
---* openmw.types.MiscellaneousRecord,
---* openmw.types.NpcRecord,
---* openmw.types.PotionRecord,
---* openmw.types.ProbeRecord,
---* openmw.core.Spell,
---* openmw.types.StaticRecord,
---* openmw.types.WeaponRecord
---@param record any A record to be registered in the database. Must be one of the supported types. The id field is not used, one will be generated for you.
---@return any A new record added to the database. The type is the same as the input's.
function world.createRecord(record) end

---@type openmw.world.VFX
world.vfx = nil

---Spawn a VFX at the given location in the world. Best invoked through the SpawnVfx global event
---local effect = core.magic.effects.records[core.magic.EFFECT_TYPE.Sanctuary]
---local pos = self.position + util.vector3(0, 100, 0)
---local model = types.Static.records[effect.castStatic].model
---core.sendGlobalEvent('SpawnVfx', {model = model, position = pos, options = { useAmbientLight = false, vfxId = "myVfx" }})
---@param model string string model path (normally taken from a record such as openmw.types.StaticRecord.model or similar)
---@param position openmw.util.Vector3
---@param options? table optional table of parameters. Can contain: * `mwMagicVfx` - Boolean that if true causes the textureOverride parameter to only affect nodes with the Nif::RC_NiTexturingProperty property set. (default: true). * `particleTextureOverride` - Name of a particle texture that should override this effect's default texture. (default: "") * `scale` - A number that scales the size of the vfx (Default: 1) * `useAmbientLight` - boolean, vfx get a white ambient light attached in Morrowind. If false don't attach this. (default: true) * `loop` - boolean, if true the effect will loop until removed (default: false). * `vfxId` - a string ID that can be used to remove the effect later, using VFX.remove. (Default: "").
function VFX.spawn(model, position, options) end

---Remove all VFX with the given vfxId. Best invoked through the RemoveVfx global event
---core.sendGlobalEvent('RemoveVfx', "myvfx")
---@param vfxId string the vfxId of the VFX to remove. Passing an empty string removes all VFX that don't have a vfxId (this includes non-scripted VFX!)
function VFX.remove(vfxId) end

---Advance the world time by a certain number of hours. This advances time, weather, and AI, but does not perform other functions associated with the passage of time, e.g., regeneration.
---@param hours number Number of hours to advance time
function world.advanceTime(hours) end

return world
