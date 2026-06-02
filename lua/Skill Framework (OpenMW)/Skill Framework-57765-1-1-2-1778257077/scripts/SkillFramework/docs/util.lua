---@meta openmw.util

---@class openmw.util
---@field color COLOR Functions to create Color objects
---@field vector2 fun(x: number, y: number): Vector2 Creates a 2D vector
---@field vector3 fun(x: number, y: number, z: number): Vector3 Creates a 3D vector
---@field vector4 fun(x: number, y: number, z: number, w: number): Vector4 Creates a 4D vector
---@field makeReadOnly fun(table: table): userdata Makes a table read-only
local util = {}

---@class Vector2: userdata A 2D vector
---@field x number X component
---@field y number Y component

---@class Vector3: userdata A 3D vector
---@field x number X component
---@field y number Y component
---@field z number Z component

---@class Vector4: userdata A 4D vector
---@field x number X component
---@field y number Y component
---@field z number Z component
---@field w number W component

---@class Color: userdata The output of a util.color function
---@field r number Red component (0-1)
---@field g number Green component (0-1)
---@field b number Blue component (0-1)
---@field a number Alpha component (0-1)
---@field asHex fun(): string Converts the color into a HEX string.
---@field asRgb fun(): Vector3 Returns a Vector3 with RGB components of the Color.
---@field asRgba fun(): Vector4 Returns a Vector4 with RGBA components of the Color.

---@class COLOR Functions to create Color objects
---@field hex fun(hex: string): Color Parses a HEX string and returns a Color object.
---@field rgb fun(r: number, g: number, b: number): Color Creates a Color object from RGB components (0-1).
---@field rgba fun(r: number, g: number, b: number, a: number): Color Creates a Color object from RGBA components (0-1).

return util