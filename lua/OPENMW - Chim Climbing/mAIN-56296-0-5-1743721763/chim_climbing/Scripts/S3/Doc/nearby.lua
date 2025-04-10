---@alias ObjectList GameObject[]

---@class AgentBounds
--- Defines the bounds of an agent for navigation purposes.
---@field halfExtents util.vector3 The half extents of the agent's bounding box.
---@field shapeType COLLISION_SHAPE_TYPE The shape type of the agent's bounds.

---@class AreaCosts
--- Defines relative costs for different types of areas in navigation.
---@field door number Cost for doors (default: 2).
---@field ground number Cost for ground areas (default: 1).
---@field pathgrid number Cost for pathgrid areas (default: 1).
---@field water number Cost for water areas (default: 1).

---@class RayCastingResult
--- Represents the result of a raycasting operation.
---@field hit boolean Indicates whether there was a collision (true/false).
---@field hitNormal nil|util.vector3 The normal vector to the surface at the collision point (nil if no collision).
---@field hitObject nil|GameObject The object the ray collided with (can be nil).
---@field hitPos nil|util.vector3 The position of the collision point (nil if no collision).

---@class CastRayOptions
--- Options for the `nearby.castRay` function.
---@field collisionType nil|COLLISION_TYPE Object types to work with (see `COLLISION_TYPE`).
---@field ignore nil|ObjectList An object to ignore (e.g., the source of the ray).
---@field radius nil|number The radius of the ray (default: 0). If greater than 0, the ray becomes a sphere cast.

---@class CastRenderingRayOptions
--- Options for the `nearby.castRenderingRay` function.
---@field ignore nil|ObjectList A list of objects to ignore during the raycast.

---@class FindNearestNavMeshPositionOptions
--- Options for finding the nearest position on the navigation mesh.
---@field agentBounds nil|AgentBounds Identifies which navmesh to use.
---@field includeFlags nil|number Allowed areas for the agent to move (sum of `NAVIGATOR_FLAGS` values).
---@field searchAreaHalfExtents nil|util.vector3 Defines the search area around the given position.

---@class FindPathOptions
--- Options for pathfinding.
---@field agentBounds nil|AgentBounds Identifies which navmesh to use.
---@field areaCosts nil|AreaCosts Relative costs for each type of area.
---@field destinationTolerance nil|number Maximum allowed distance between the destination and the nearest point on the navigation mesh.
---@field includeFlags nil|number Allowed areas for the agent to move (sum of `NAVIGATOR_FLAGS` values).

---@class nearby
--- Provides utilities for interacting with nearby objects, raycasting, and navigation.
---@field COLLISION_TYPE COLLISION_TYPE Collision types that are used in `castRay`.
---@field activators ObjectList List of nearby activators.
---@field actors ObjectList List of nearby actors.
---@field containers ObjectList List of nearby containers.
---@field doors ObjectList List of nearby doors.
---@field items ObjectList Everything nearby that is derived from `openmw.types#Item`.
---@field players ObjectList List of nearby players.
---@field asyncCastRenderingRay fun(callback: fun(result: RayCastingResult), from: util.vector3, to: util.vector3) Asynchronously cast a ray from one point to another and find the first visual intersection with anything in the scene.
---@field castRay fun(from: util.vector3, to: util.vector3, options: nil|CastRayOptions): RayCastingResult Cast a ray from one point to another and return the first collision.
---@field castRenderingRay fun(from: util.vector3, to: util.vector3): RayCastingResult Cast a ray from one point to another and find the first visual intersection with anything in the scene.
---@field castNavigationRay fun(from: util.vector3, to: util.vector3, options: nil|CastRayOptions): util.vector3 Finds the nearest target position to the ray starting from the initial position with a resulting curve drawn on the navigation mesh surface.
---@field findNearestNavMeshPosition fun(position: util.vector3, options: nil|FindNearestNavMeshPositionOptions): util.vector3 Finds the nearest position on the navigation mesh to the given position within the specified search area.
---@field findPath fun(source: util.vector3, destination: util.vector3, options: nil|FindPathOptions): util.vector3[] Find a path over the navigation mesh from the source to the destination with the given options.
---@field findRandomPointAroundCircle fun(position: util.vector3, maxRadius: number, options: nil|FindNearestNavMeshPositionOptions): util.vector3 Returns a random location on the navigation mesh within the reach of the specified location.
---@field getObjectByFormId fun(formId: number): GameObject Return an object by RefNum/FormId.

---@alias COLLISION_SHAPE_TYPE
--- Shape types used for collision bounds.
---| '"Aabb"' # Axis-Aligned Bounding Box, used for NPCs and symmetric creatures.
---| '"Cylinder"' # Cylinder, used for NPCs and symmetric creatures.
---| '"RotatingBox"' # Rotating Box, used for creatures with a big difference in width and height.

---@alias COLLISION_TYPE
--- Collision types used in raycasting.
---| '"Actor"' # Collides with actors.
---| '"AnyPhysical"' # Collides with World+Door+Actor+HeightMap+Projectile+Water.
---| '"Camera"' # Collides with objects intended only for the camera.
---| '"Default"' # Collides with World+Door+Actor+HeightMap.
---| '"Door"' # Collides with doors.
---| '"HeightMap"' # Collides with height maps.
---| '"Projectile"' # Collides with projectiles.
---| '"VisualOnly"' # Collides with objects not intended to be part of the physics world.
---| '"Water"' # Collides with water.
---| '"World"' # Collides with the world.

---@alias NAVIGATOR_FLAGS
--- Flags for allowed navigation areas.
---| '"OpenDoor"' # Allow the agent to open doors.
---| '"Swim"' # Allow the agent to swim on the water surface.
---| '"UsePathgrid"' # Allow the agent to use predefined pathgrid.
---| '"Walk"' # Allow the agent to walk on the ground.
