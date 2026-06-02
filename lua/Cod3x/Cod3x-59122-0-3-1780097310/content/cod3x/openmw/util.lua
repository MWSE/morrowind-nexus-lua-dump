---@meta

-- This file was mechanically drafted from files/lua_api/openmw/util.lua.
-- It uses LuaLS/LLS annotations and stub bodies only; runtime behavior is provided by OpenMW.
-- OpenMW script contexts: global|menu|local|player|load

---Defines utility functions and classes like 3D vectors, that don't depend on the game world.
---@class openmw.util
local util = {}

---Immutable 2D vector
---v = util.vector2(3, 4)
---v.x, v.y       -- 3.0, 4.0
---str(v)         -- "(3.0, 4.0)"
---v:length()     -- 5.0    length
---v:length2()    -- 25.0   square of the length
---v:normalize()  -- vector2(3/5, 4/5)
---v:rotate(radians)    -- rotate counterclockwise (returns rotated vector)
---v1:dot(v2)     -- dot product (returns a number)
---v1 * v2        -- dot product
---v1 + v2        -- vector addition
---v1 - v2        -- vector subtraction
---v1 * x         -- multiplication by a number
---v1 / x         -- division by a number
---v1.xx, v1.xyx  -- swizzle with standard fields
---v1.y1y, v1.x00 -- swizzle with 0/1 constant
---v1['0xy']      -- swizzle with 0/1 constant starting with 0 or 1
---@class openmw.util.Vector2
---@field x number
---@field y number
---@field xy01 string swizzle support, any combination of fields can be used to construct a new vector including the 0/1 constants
local Vector2 = {}

---Immutable 3D vector
---v = util.vector3(3, 4, 5)
---v.x, v.y, v.z  -- 3.0, 4.0, 5.0
---str(v)         -- "(3.0, 4.0, 4.5)"
---v:length()     -- length
---v:length2()    -- square of the length
---v:normalize()  -- normalized vector
---v1:dot(v2)     -- dot product (returns a number)
---v1 * v2        -- dot product (returns a number)
---v1:cross(v2)   -- cross product (returns a vector)
---v1 ^ v2        -- cross product (returns a vector)
---v1 + v2        -- vector addition
---v1 - v2        -- vector subtraction
---v1 * x         -- multiplication by a number
---v1 / x         -- division by a number
---v1.zyz, v1.yx  -- swizzle with standard fields
---v1.w1y, v1.z0z -- swizzle with 0/1 constant
---v1['0xy']      -- swizzle with 0/1 constant starting with 0 or 1
---@class openmw.util.Vector3
---@field x number
---@field y number
---@field z number
---@field xyz01 string swizzle support, any combination of fields can be used to construct a new vector including the 0/1 constants
local Vector3 = {}

---Immutable 4D vector.
---v = util.vector4(3, 4, 5, 6)
---v.x, v.y, v.z, v.w  -- 3.0, 4.0, 5.0, 6.0
---str(v)           -- "(3.0, 4.0, 5.0, 6.0)"
---v:length()       -- length
---v:length2()      -- square of the length
---v:normalize()    -- normalized vector
---v1:dot(v2)       -- dot product (returns a number)
---v1 * v2          -- dot product (returns a number)
---v1 + v2          -- vector addition
---v1 - v2          -- vector subtraction
---v1 * x           -- multiplication by a number
---v1 / x           -- division by a number
---v1.zyz, v1.wwwx  -- swizzle with standard fields
---v1.w1, v1.z000   -- swizzle with 0/1 constant
---v1['000w']       -- swizzle with 0/1 constant starting with 0 or 1
---@class openmw.util.Vector4
---@field x number
---@field y number
---@field z number
---@field w number
---@field xyzw01 string swizzle support, any combination of fields can be used to construct a new vector including the 0/1 constants
local Vector4 = {}

---Immutable box.
---@class openmw.util.Box
---@field center openmw.util.Vector3 The center of the box
---@field halfSize openmw.util.Vector3 The half sizes of the box along each axis
---@field transform openmw.util.Transform A transformation which encapsulates the boxes center pointer (translation), half sizes (scale), and rotation.
---@field vertices table Table of the 8 vertices which comprise the box, taking rotation into account
local Box = {}

---Color in RGBA format. All of the component values are in the range [0, 1].
---@class openmw.util.Color
---@field r number Red component
---@field g number Green component
---@field b number Blue component
---@field a number Alpha (transparency) component
local Color = {}

---Methods for creating #Color values from different formats.
---@class openmw.util.COLOR
local COLOR = {}

---@class openmw.util.Transform
local Transform = {}

---@class openmw.util.TRANSFORM
---@field identity openmw.util.Transform Empty transform.
local TRANSFORM = {}

---Rounds the given value to the nearest whole number.
---local util = require('openmw.util')
---local roundedValue = util.round(3.141592)
---print(roundedValue) -- prints 3
---@param value number
---@return number The rounded value.
function util.round(value) end

---Remaps the value from one range to another.
---local util = require('openmw.util')
---local newValue = util.remap(3, 0, 10, 0, 100)
---print(newValue) -- prints 30
---@param value number
---@param min number
---@param max number
---@param newMin number
---@param newMax number
---@return number The remapped value.
function util.remap(value, min, max, newMin, newMax) end

---Limits given value to the interval [`from`, `to`].
---@param value number
---@param from number
---@param to number
---@return number value `min(max(value, from), to)`.
function util.clamp(value, from, to) end

---Adds `2pi*k` and puts the angle in range `[-pi, pi]`.
---@param angle number Angle in radians
---@return number angle Angle in range `[-pi, pi]`.
function util.normalizeAngle(angle) end

---Makes a table read only.
---@param table table Any table.
---@return table The same table wrapped with read only userdata.
function util.makeReadOnly(table) end

---Makes a table read only and overrides `__index` with the strict version that throws an error if the key is not found.
---@param table table Any table.
---@return table The same table wrapped with read only userdata.
function util.makeStrictReadOnly(table) end

---Parses Lua code from string and returns as a function.
---@param code string Lua code.
---@param table table Environment to run the code in.
---@return fun(...): any The loaded code.
function util.loadCode(code, table) end

---Bitwise And (supports any number of arguments).
---@param A number First argument (integer).
---@param B number Second argument (integer).
---@return number Bitwise And of A and B.
function util.bitAnd(A, B) end

---Bitwise Or (supports any number of arguments).
---@param A number First argument (integer).
---@param B number Second argument (integer).
---@return number Bitwise Or of A and B.
function util.bitOr(A, B) end

---Bitwise Xor (supports any number of arguments).
---@param A number First argument (integer).
---@param B number Second argument (integer).
---@return number Bitwise Xor of A and B.
function util.bitXor(A, B) end

---Bitwise inversion.
---@param A number Argument (integer).
---@return number Bitwise Not of A.
function util.bitNot(A) end

---Creates a new 2D vector. Vectors are immutable and can not be changed after creation.
---@param x_ number
---@param y_ number
---@return openmw.util.Vector2
function util.vector2(x_, y_) end

---@param v openmw.util.Vector2
---@return openmw.util.Vector2 sum of the vectors
function Vector2:__add(v) end

---@param v openmw.util.Vector2
---@return openmw.util.Vector2 difference of the vectors
function Vector2:__sub(v) end

---@param k number
---@return openmw.util.Vector2 vector multiplied by a number
function Vector2:__mul(k) end

---@param k number
---@return openmw.util.Vector2 vector divided by a number
function Vector2:__div(k) end

---Length of the vector.
---@return number
function Vector2:length() end

---Square of the length of the vector.
---@return number
function Vector2:length2() end

---Normalizes vector.
---It doesn't change the original vector.
---@return openmw.util.Vector2 normalized vector
---@return number the length of the original vector
function Vector2:normalize() end

---Rotates 2D vector clockwise.
---@param angle number Angle in radians
---@return openmw.util.Vector2 Rotated vector.
function Vector2:rotate(angle) end

---Dot product.
---@param v openmw.util.Vector2
---@return number
function Vector2:dot(v) end

---Element-wise multiplication
---@param v openmw.util.Vector2
---@return openmw.util.Vector2
function Vector2:emul(v) end

---Element-wise division
---@param v openmw.util.Vector2
---@return openmw.util.Vector2
function Vector2:ediv(v) end

---Creates a new 3D vector. Vectors are immutable and can not be changed after creation.
---@param x_ number
---@param y_ number
---@param z_ number
---@return openmw.util.Vector3
function util.vector3(x_, y_, z_) end

---@param v openmw.util.Vector3
---@return openmw.util.Vector3 sum of the vectors
function Vector3:__add(v) end

---@param v openmw.util.Vector3
---@return openmw.util.Vector3 difference of the vectors
function Vector3:__sub(v) end

---@param k number
---@return openmw.util.Vector3 vector multiplied by a number
function Vector3:__mul(k) end

---@param k number
---@return openmw.util.Vector3 vector divided by a number
function Vector3:__div(k) end

---@return string
function Vector3:__tostring() end

---Length of the vector
---@return number
function Vector3:length() end

---Square of the length of the vector
---@return number
function Vector3:length2() end

---Normalizes vector.
---It doesn't change the original vector.
---@return openmw.util.Vector3 normalized vector
---@return number the length of the original vector
function Vector3:normalize() end

---Dot product.
---@param v openmw.util.Vector3
---@return number
function Vector3:dot(v) end

---Cross product.
---@param v openmw.util.Vector3
---@return openmw.util.Vector3
function Vector3:cross(v) end

---Element-wise multiplication
---@param v openmw.util.Vector3
---@return openmw.util.Vector3
function Vector3:emul(v) end

---Element-wise division
---@param v openmw.util.Vector3
---@return openmw.util.Vector3
function Vector3:ediv(v) end

---Creates a new 4D vector. Vectors are immutable and can not be changed after creation.
---@param x_ number
---@param y_ number
---@param z_ number
---@param w_ number
---@return openmw.util.Vector4
function util.vector4(x_, y_, z_, w_) end

---@param v openmw.util.Vector4
---@return openmw.util.Vector4 sum of the vectors
function Vector4:__add(v) end

---@param v openmw.util.Vector4
---@return openmw.util.Vector4 difference of the vectors
function Vector4:__sub(v) end

---@param k number
---@return openmw.util.Vector4 vector multiplied by a number
function Vector4:__mul(k) end

---@param k number
---@return openmw.util.Vector4 vector divided by a number
function Vector4:__div(k) end

---@return string
function Vector4:__tostring() end

---Length of the vector
---@return number
function Vector4:length() end

---Square of the length of the vector
---@return number
function Vector4:length2() end

---Normalizes vector.
---It doesn't change the original vector.
---@return openmw.util.Vector4 normalized vector
---@return number the length of the original vector
function Vector4:normalize() end

---Dot product.
---@param v openmw.util.Vector4
---@return number
function Vector4:dot(v) end

---Element-wise multiplication
---@param v openmw.util.Vector4
---@return openmw.util.Vector4
function Vector4:emul(v) end

---Element-wise division
---@param v openmw.util.Vector4
---@return openmw.util.Vector4
function Vector4:ediv(v) end

---Creates a new Box with a given center and half sizes. Boxes are immutable and can not be changed after creation.
---@param center openmw.util.Vector3
---@param halfSize openmw.util.Vector3 in each dimension (x, y, z)
---@return openmw.util.Box
function util.box(center, halfSize) end

---Creates a new Box from a given transformation. Boxes are immutable and can not be changed after creation.
----- Creates a 1x1x1 length box centered at the origin
---util.box(util.transform.scale(util.vector3(0.5, 0.5, 0.5)))
---@param transform openmw.util.Transform A transformation which encapsulates the boxes center pointer (translation), half sizes (scale), and rotation.
---@return openmw.util.Box
function util.box(transform) end

---Returns a Vector4 with RGBA components of the Color.
---@return openmw.util.Vector4
function Color:asRgba() end

---Returns a Vector3 with RGB components of the Color.
---@return openmw.util.Vector3
function Color:asRgb() end

---Converts the color into a HEX string.
---@return string
function Color:asHex() end

---Methods for creating #Color values from different formats.
---@type openmw.util.COLOR
util.color = nil

---Creates a Color from RGBA format
---@param r number
---@param g number
---@param b number
---@param a number
---@return openmw.util.Color
function COLOR.rgba(r, g, b, a) end

---Creates a Color from comma-separated string (in RGB or RGBA order, spaces are ignored)
---@param str string
---@return openmw.util.Color
function COLOR.commaString(str) end

---Creates a Color from RGB format. Equivalent to calling util.rgba with a = 1.
---@param r number
---@param g number
---@param b number
---@return openmw.util.Color
function COLOR.rgb(r, g, b) end

---Parses a hex color string into a Color.
---@param hex string A hex color string in RRGGBB format (e. g. "ff0000").
---@return openmw.util.Color
function COLOR.hex(hex) end

---Combine transforms (will apply in reverse order)
---@param t openmw.util.Transform
---@return openmw.util.Transform
function Transform:__mul(t) end

---Returns the inverse transform.
---@return openmw.util.Transform
function Transform:inverse() end

---Apply transform to a vector
---@param v openmw.util.Vector3
---@return openmw.util.Vector3
function Transform:apply(v) end

---Get yaw angle (radians)
---@return number
function Transform:getYaw() end

---Get pitch angle (radians)
---@return number
function Transform:getPitch() end

---Get Euler angles for XZ rotation order (pitch and yaw; radians)
---@return number pitch (rotation around X axis)
---@return number yaw (rotation around Z axis)
function Transform:getAnglesXZ() end

---Get Euler angles for ZYX rotation order (radians)
---@return number rotation around Z axis (first rotation)
---@return number rotation around Y axis (second rotation)
---@return number rotation around X axis (third rotation)
function Transform:getAnglesZYX() end

---Movement by given vector.
----- Accepts either 3 numbers or a 3D vector
---util.transform.move(x, y, z)
---util.transform.move(util.vector3(x, y, z))
---@param offset openmw.util.Vector3
---@return openmw.util.Transform
function TRANSFORM.move(offset) end

---Scale transform.
----- Accepts either 3 numbers or a 3D vector
---util.transform.scale(x, y, z)
---util.transform.scale(util.vector3(x, y, z))
---@param scaleX_ number
---@param scaleY_ number
---@param scaleZ_ number
---@return openmw.util.Transform
function TRANSFORM.scale(scaleX_, scaleY_, scaleZ_) end

---Rotation around a vector (counterclockwise if the vector points to us).
---@param angle number
---@param axis_ openmw.util.Vector3
---@return openmw.util.Transform
function TRANSFORM.rotate(angle, axis_) end

---X-axis rotation (equivalent to `rotate(angle, vector3(-1, 0, 0))`).
---@param angle number
---@return openmw.util.Transform
function TRANSFORM.rotateX(angle) end

---Y-axis rotation (equivalent to `rotate(angle, vector3(0, -1, 0))`).
---@param angle number
---@return openmw.util.Transform
function TRANSFORM.rotateY(angle) end

---Z-axis rotation (equivalent to `rotate(angle, vector3(0, 0, -1))`).
---@param angle number
---@return openmw.util.Transform
function TRANSFORM.rotateZ(angle) end

---3D transforms (scale/move/rotate) that can be applied to 3D vectors.
---Several transforms can be combined and applied to a vector using multiplication.
---Combined transforms apply in reverse order (from right to left).
---local util = require('openmw.util')
---local trans = util.transform
---local fromActorSpace = trans.move(actor.position) * trans.rotateZ(actor.rotation:getYaw())
----- rotation is applied first, movement is second
---local posBehindActor = fromActorSpace * util.vector3(0, -100, 0)
----- equivalent to trans.rotateZ(-actor.rotation:getYaw()) * trans.move(-actor.position)
---local toActorSpace = fromActorSpace:inverse()
---local relativeTargetPos = toActorSpace * target.position
---local deltaAngle = math.atan2(relativeTargetPos.y, relativeTargetPos.x)
---@type openmw.util.TRANSFORM
util.transform = nil

return util
