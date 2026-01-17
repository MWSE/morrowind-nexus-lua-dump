---@alias ObjectList GameObject[]

---@class AgentBounds
--- Defines an agent collision profile for navigation mesh queries.
---@field halfExtents util.vector3 Half-size of the agent bounds in each axis.
---@field shapeType COLLISION_SHAPE_TYPE Collision shape used for navmesh queries.

---@class AreaCosts
--- Relative traversal costs used by navmesh pathfinding.
--- Higher cost = less preferred.
---@field door number Cost for doors (default: 2)
---@field ground number Cost for ground (default: 1)
---@field pathgrid number Cost for pathgrid (default: 1)
---@field water number Cost for water (default: 1)

---@class RayCastingResult
--- Result of a raycast / spherecast query.
--- Notes:
---  • If hit == false, hitPos/hitObject/hitNormal will be nil.
---  • hitObject can be nil even when hit == true (depends on collision type / what was hit).
---@field hit boolean True if something was intersected.
---@field hitNormal nil|util.vector3 Surface normal at hit point (nil if no hit).
---@field hitObject nil|GameObject Hit object reference (nil if no object or no hit).
---@field hitPos nil|util.vector3 World-space hit position (nil if no hit).

---@class CastRayOptions
--- Options for `nearby.castRay`.
---@field collisionType nil|COLLISION_TYPE
--- Collision filter (defaults to `"Default"` if omitted; engine-defined).
---@field ignore nil|ObjectList
--- Objects to exclude from intersection tests.
--- Typically pass `{ ignore = { self.object } }` or `{ ignore = { self } }` depending on context.
---@field radius nil|number
--- Spherecast radius. Default: 0 (true raycast). If > 0, performs a swept sphere test.

---@class CastRenderingRayOptions
--- Options for rendering-ray functions (visual-only intersections).
---@field ignore nil|ObjectList Objects to exclude from intersection tests.

---@class FindNearestNavMeshPositionOptions
--- Options for finding a point on the navigation mesh.
---@field agentBounds nil|AgentBounds Identifies which navmesh/agent profile to use.
---@field includeFlags nil|number Allowed area flags (sum/bitmask of NAVIGATOR_FLAGS).
---@field searchAreaHalfExtents nil|util.vector3 Half-size of search box around the input position.

---@class FindPathOptions
--- Options for navigation pathfinding.
---@field agentBounds nil|AgentBounds Identifies which navmesh/agent profile to use.
---@field areaCosts nil|AreaCosts Relative costs per area type.
---@field destinationTolerance nil|number
--- Max allowed distance between requested destination and projected navmesh destination.
---@field includeFlags nil|number Allowed area flags (sum/bitmask of NAVIGATOR_FLAGS).

---@class nearby
--- Nearby object lists, raycasting, and navigation mesh utilities.

---@field COLLISION_TYPE COLLISION_TYPE Collision-type enum used by `castRay`.

---@field activators ObjectList Nearby activators.
---@field actors ObjectList Nearby actors.
---@field containers ObjectList Nearby containers.
---@field doors ObjectList Nearby doors.
---@field items ObjectList Nearby items (derived from `openmw.types#Item`).
---@field players ObjectList Nearby players.

---@field asyncCastRenderingRay fun(callback: fun(result: RayCastingResult), from: util.vector3, to: util.vector3): nil
--- Asynchronously casts a rendering ray (visual intersection).
--- Returns nothing; `callback(result)` is invoked later.

---@field castRay fun(from: util.vector3, to: util.vector3, options: nil|CastRayOptions): RayCastingResult
--- Cast a physics ray/sphere from `from` to `to` and return the first collision.

---@field castRenderingRay fun(from: util.vector3, to: util.vector3): RayCastingResult
--- Cast a ray against the rendered scene (visual intersection), not necessarily physics.
--- NOTE: If your engine build supports ignore lists for rendering rays, expose it here as an overload.

---@field castNavigationRay fun(from: util.vector3, to: util.vector3, options: nil|CastRayOptions): util.vector3
--- Projects movement along navmesh from `from` toward `to` and returns the nearest reachable point.

---@field findNearestNavMeshPosition fun(position: util.vector3, options: nil|FindNearestNavMeshPositionOptions): util.vector3
--- Finds nearest position on the navmesh within the given search extents.

---@field findPath fun(source: util.vector3, destination: util.vector3, options: nil|FindPathOptions): util.vector3[]
--- Returns a list of path points along navmesh from source to destination.

---@field findRandomPointAroundCircle fun(position: util.vector3, maxRadius: number, options: nil|FindNearestNavMeshPositionOptions): util.vector3
--- Returns a random reachable navmesh point near `position` within `maxRadius`.

---@field getObjectByFormId fun(formId: number): GameObject
--- Return an object by RefNum/FormId (engine-provided). Behavior if not found is engine-defined.
