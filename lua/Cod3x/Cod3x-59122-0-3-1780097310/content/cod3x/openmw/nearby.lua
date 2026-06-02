---@meta

-- This file was mechanically drafted from files/lua_api/openmw/nearby.lua.
-- It uses LuaLS/LLS annotations and stub bodies only; runtime behavior is provided by OpenMW.
-- OpenMW script contexts: local

---Provides read-only access to the nearest area of the game world.
---@class openmw.nearby
local nearby = {}

---@class openmw.nearby.COLLISION_TYPE
---@field World number
---@field Door number
---@field Actor number
---@field HeightMap number
---@field Projectile number
---@field Water number
---@field Default number Used by default: World+Door+Actor+HeightMap
---@field AnyPhysical number World+Door+Actor+HeightMap+Projectile+Water
---@field Camera number Objects that should collide only with camera
---@field VisualOnly number Objects that were not intended to be part of the physics world
local COLLISION_TYPE = {}

---Result of raycasting
---@class openmw.nearby.RayCastingResult
---@field hit boolean Is there a collision? (true/false)
---@field hitPos openmw.util.Vector3 Position of the collision point (nil if no collision)
---@field hitNormal openmw.util.Vector3 Normal to the surface in the collision point (nil if no collision)
---@field hitObject openmw.LObject The object the ray has collided with (can be nil)
local RayCastingResult = {}

---A table of parameters for nearby.castRay
---@class openmw.nearby.CastRayOptions
---@field ignore any An openmw.LObject or openmw.ObjectList<openmw.LObject> to ignore (specify here the source of the ray, or other objects which should not collide)
---@field collisionType number Object types to work with (see openmw.nearby.COLLISION_TYPE)
---@field radius number The radius of the ray (zero by default). If not zero then castRay actually casts a sphere with given radius. NOTE: currently `ignore` is not supported if `radius>0`.
local CastRayOptions = {}

---A table of parameters for nearby.castRenderingRay and nearby.asyncCastRenderingRay
---@class openmw.nearby.CastRenderingRayOptions
---@field ignore any A openmw.LObject or openmw.ObjectList<openmw.LObject> to ignore while doing the ray cast
local CastRenderingRayOptions = {}

---@class openmw.nearby.NAVIGATOR_FLAGS
---@field Walk number Allow agent to walk on the ground area.
---@field Swim number Allow agent to swim on the water surface.
---@field OpenDoor number Allow agent to open doors on the way.
---@field UsePathgrid number Allow agent to use predefined pathgrid imported from ESM files.
local NAVIGATOR_FLAGS = {}

---Creatures.
---height.
---@class openmw.nearby.COLLISION_SHAPE_TYPE
---@field Aabb number Axis-Aligned Bounding Box is used for NPC and symmetric
---@field RotatingBox number is used for Creatures with big difference in width and
---@field Cylinder number is used for NPC and symmetric Creatures.
local COLLISION_SHAPE_TYPE = {}

---among found;
---mesh. For interior cells it means an agent with such `agentBounds` is present on the scene. For exterior cells only
---default `agentBounds` is supported;
---navigation mesh. The status may appear when navigation mesh is not fully generated or position is outside of covered
---area;
---navigation mesh. The status may appear when navigation mesh is not fully generated or position is outside of covered
---area;
---available navigation mesh. The status may appear when navigation mesh is not fully generated or position is outside
---of covered area;
---algorithm implementation or bad navigation mesh data;
---`destination` does not exist or navigation mesh is not fully generated to provide the path;
---or bad navigation mesh data.
---coordinates.
---@class openmw.nearby.FIND_PATH_STATUS
---@field Success number Path is found.
---@field PartialPath number Last path point is not a destination but a nearest position
---@field NavMeshNotFound number Provided `agentBounds` don't have corresponding navigation
---@field StartPolygonNotFound number `source` position is too far from available
---@field EndPolygonNotFound number `destination` position is too far from available
---@field TargetPolygonNotFound number adjusted `destination` position is too far from
---@field MoveAlongSurfaceFailed number Found path couldn't be smoothed due to imperfect
---@field FindPathOverPolygonsFailed number Path over navigation mesh from `source` to
---@field InitNavMeshQueryFailed number Couldn't initialize required data due to bad input
---@field FindStraightPathFailed number Couldn't map path over polygons into world
local FIND_PATH_STATUS = {}

---A table of parameters identifying navmesh
---@class openmw.nearby.AgentBounds
---@field shapeType_ openmw.nearby.COLLISION_SHAPE_TYPE
---@field halfExtents_ openmw.util.Vector3
local AgentBounds = {}

---A table of parameters to specify relative path cost per each area type
---(default: 2).
---(default: 1).
---@class openmw.nearby.AreaCosts
---@field ground number Value >= 0, used in combination with NAVIGATOR_FLAGS.Walk (default: 1).
---@field water number Value >= 0, used in combination with NAVIGATOR_FLAGS.Swim (default: 1).
---@field door number Value >= 0, used in combination with NAVIGATOR_FLAGS.OpenDoor
---@field pathgrid number Value >= 0, used in combination with NAVIGATOR_FLAGS.UsePathgrid
local AreaCosts = {}

---A table of parameters for nearby.findPath
---values (default: NAVIGATOR_FLAGS.Walk + NAVIGATOR_FLAGS.Swim + NAVIGATOR_FLAGS.OpenDoor
---+ NAVIGATOR_FLAGS.UsePathgrid).
---distance between destination and a nearest point on the navigation mesh in addition to agent size (default: 1).
---@class openmw.nearby.FindPathOptions
---@field agentBounds openmw.nearby.AgentBounds identifies which navmesh to use.
---@field includeFlags number allowed areas for agent to move, a sum of NAVIGATOR_FLAGS
---@field areaCosts openmw.nearby.AreaCosts a table defining relative cost for each type of area.
---@field destinationTolerance number a floating point number representing maximum allowed
---@field checkpoints table an array of positions to build path over if possible.
local FindPathOptions = {}

---A table of parameters for nearby.findRandomPointAroundCircle and nearby.castNavigationRay
---values (default: NAVIGATOR_FLAGS.Walk + NAVIGATOR_FLAGS.Swim + NAVIGATOR_FLAGS.OpenDoor
---+ NAVIGATOR_FLAGS.UsePathgrid).
---@class openmw.nearby.NavMeshOptions
---@field agentBounds openmw.nearby.AgentBounds Identifies which navmesh to use.
---@field includeFlags number Allowed areas for agent to move, a sum of NAVIGATOR_FLAGS
local NavMeshOptions = {}

---A table of parameters for nearby.findNearestNavMeshPosition
---values (default: NAVIGATOR_FLAGS.Walk + NAVIGATOR_FLAGS.Swim + NAVIGATOR_FLAGS.OpenDoor
---+ NAVIGATOR_FLAGS.UsePathgrid).
---given position (default: (1 + 2 * CellGridRadius) * CellSize * (1, 1, 1) where CellGridRadius and depends on cell
---type to cover the whole active grid).
---@class openmw.nearby.FindNearestNavMeshPositionOptions
---@field agentBounds openmw.nearby.AgentBounds Identifies which navmesh to use.
---@field includeFlags number Allowed areas for agent to move, a sum of NAVIGATOR_FLAGS
---@field searchAreaHalfExtents openmw.util.Vector3 Defines AABB like area half extents around
local FindNearestNavMeshPositionOptions = {}

---List of nearby activators.
---@type openmw.ObjectList<openmw.LObject>
nearby.activators = nil

---List of nearby actors.
---@type openmw.ObjectList<openmw.LObject>
nearby.actors = nil

---List of nearby containers.
---@type openmw.ObjectList<openmw.LObject>
nearby.containers = nil

---List of nearby doors.
---@type openmw.ObjectList<openmw.LObject>
nearby.doors = nil

---Everything nearby that is derived from openmw.types.Item.
---@type openmw.ObjectList<openmw.LObject>
nearby.items = nil

---List of nearby players. Currently (since multiplayer is not yet implemented) always has one element.
---@type openmw.ObjectList<openmw.LObject>
nearby.players = nil

---Return an object by RefNum/FormId.
---Note: the function always returns openmw.LObject and doesn't validate that
---the object exists in the game world. If it doesn't exist or not yet loaded to memory),
---then `obj:isValid()` will be `false`.
---@param formId string String returned by `core.getFormId`
---@return openmw.LObject
function nearby.getObjectByFormId(formId) end

---Collision types that are used in `castRay`.
---Several types can be combined with openmw_util.util.bitOr.
---@type openmw.nearby.COLLISION_TYPE
nearby.COLLISION_TYPE = nil

---Cast a ray from one point to another and return the first collision.
---if res.hitObject and res.hitObject ~= enemy then obstacle = res.hitObject end
---})
---@param from openmw.util.Vector3 Start point of the ray.
---@param to openmw.util.Vector3 End point of the ray.
---@param options? openmw.nearby.CastRayOptions An optional table with additional optional arguments
---@return openmw.nearby.RayCastingResult
function nearby.castRay(from, to, options) end

---Cast a ray from one point to another and find the first visual intersection with anything in the scene.
---Unlike `castRay`, `castRenderingRay` can find an intersection with an object without collisions.
---To avoid threading issues, `castRenderingRay` can only be used in:
---- The `onFrame` engine handler.
---- Engine handlers for user input.
---- Callbacks provided to openmw.input.registerActionHandler
---In other cases, use `asyncCastRenderingRay` instead.
---@param from openmw.util.Vector3 Start point of the ray.
---@param to openmw.util.Vector3 End point of the ray.
---@param options? openmw.nearby.CastRenderingRayOptions An optional table with additional optional arguments
---@return openmw.nearby.RayCastingResult
function nearby.castRenderingRay(from, to, options) end

---Asynchronously cast a ray from one point to another and find the first visual intersection with anything in the scene.
---@param callback openmw.async.Callback The callback to pass the result to (should accept a single argument openmw.nearby.RayCastingResult).
---@param from openmw.util.Vector3 Start point of the ray.
---@param to openmw.util.Vector3 End point of the ray.
---@param options? openmw.nearby.CastRenderingRayOptions An optional table with additional optional arguments
function nearby.asyncCastRenderingRay(callback, from, to, options) end

---Find a path over the navigation mesh from the source to the destination with the given options. Result is unstable since navigation
---mesh generation is asynchronous.
---})
---})
---@param source openmw.util.Vector3 Initial path position.
---@param destination openmw.util.Vector3 Final path position.
---@param options? openmw.nearby.FindPathOptions An optional table with additional optional arguments.
---@return openmw.nearby.FIND_PATH_STATUS
---@return openmw.util.Vector3[]
function nearby.findPath(source, destination, options) end

---Returns a random location on the navigation mesh within the reach of the specified location.
---The location is not exactly constrained by the circle, but it limits the area.
---})
---})
---@param position openmw.util.Vector3 Center of the search circle.
---@param maxRadius number Approximate maximum search distance.
---@param options? openmw.nearby.NavMeshOptions An optional table with additional optional arguments.
---@return openmw.util.Vector3|nil
function nearby.findRandomPointAroundCircle(position, maxRadius, options) end

---Finds a nearest to the ray target position starting from the initial position with resulting curve drawn on the
---navigation mesh surface.
---})
---})
---@param from openmw.util.Vector3 Initial ray position.
---@param to openmw.util.Vector3 Target ray position.
---@param options? openmw.nearby.NavMeshOptions An optional table with additional optional arguments.
---@return openmw.util.Vector3|nil
function nearby.castNavigationRay(from, to, options) end

---Finds a nearest position on navigation mesh to the given position within given search area.
---})
---})
---})
---@param position openmw.util.Vector3 Search area center.
---@param options? openmw.nearby.FindNearestNavMeshPositionOptions An optional table with additional optional arguments.
---@return openmw.util.Vector3|nil
function nearby.findNearestNavMeshPosition(position, options) end

return nearby
