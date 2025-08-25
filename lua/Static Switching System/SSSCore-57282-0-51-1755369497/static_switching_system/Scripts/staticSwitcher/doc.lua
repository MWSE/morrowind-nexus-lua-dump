---@alias MeshToSourceMap table<string, SourceMapData> Maps a new mesh to the source file which defined this replacement.
---@alias OriginalModel RecordId
---@alias ReplacedRecordId RecordId
---@alias ReplacementMap table < OriginalModel, ReplacedRecordId >
---@alias RecordId string
---@alias SzudzikCoord integer

---@class ObjectDeleteData
---@field object GameObject
---@field ticks integer number of frames before this object will be deleted
---@field removeOrDisable boolean whether or not the object will be permanently removed or just disabled. When replacing, the original objects are disabled, but when uninstalling a module the replacements are removed and the originals restored.

---@class ReplacedObjectData
---@field originalObject GameObject
---@field sourceFile string

---@class SourceMapData
---@field logString string log prefix associated with this specific mesh replacement
---@field sourceFile string the basename of the yaml file which defined this replacement

---@class ExteriorGrid
---@field x integer X coordinate of an exterior cell in which to replace objects
---@field y integer Y coordinate of an exterior cell in which to replace objects

---@class ActivatorRecord
---@field name string? human-readable name displayed for this objecdt
---@field mwscript string? recordId of the mwscript running on this object
---@field id RecordId
---@field model string? mesh displayed for the object in game. If not present (usually a light), then the record is completely ignored.

---@class GameCell
---@field name string
---@field gridX integer exterior X coordinate of the cell. Be warned this is present even for interiors and fake exteriors.
---@field gridY integer exterior Y coordinate of the cell. Be warned this is present even for interiors and fake exteriors.
---@field isExterior boolean whether or not the cell is a true exterior
---@field id string

---@class GameObject
---@field recordId RecordId
---@field type table<string, any>
---@field scale integer Object scale
---@field enabled boolean
---@field count integer
---@field cell GameCell
---@field isValid fun(self: GameObject): boolean whether or not the object is currently valid, eg teleporting or similar
---@field remove fun(self: GameObject, count: integer?) destroy the object completely
---@field position util.vector3
---@field getBoundingBox fun(): userdata
---@field teleport fun(cell: GameCell, position: util.vector3, options: table)
---@field sendEvent fun(self: GameObject, eventName: string, eventData: any)
---@field id string The unique identifier for the object.
---@field rotation integer Totally not an integer and totally not updating these docs lol

---@class SSSModule
---@field cellNameMatches string[] list of cell names which will be fuzzy-matched for a given module
---@field meshMap ReplacementMap
---@field gridIndices table<SzudzikCoord, true>
---@field logString string? prefix displayed when
---@field ignoreRecords table<string, true> list of records which this module will explicitly ignore during replacement

--- A Static Switching System module as it exists in yaml format.
--- Most fields are NOT optional, and a corresponding JsonSchema exists for them as well.
---@class SSSModuleRaw
---@field log_name string?
---@field replace_names string[] array of cell names to match replacements for
---@field exterior_cells ExteriorGrid[] array of grid indices in which a particular module will replace objects
---@field replace_meshes table<string, string> map of old meshes to new ones
---@field ignore_records string[] records to ignore when replacing with this module. Typically used for scripted objects, but maybe not.
