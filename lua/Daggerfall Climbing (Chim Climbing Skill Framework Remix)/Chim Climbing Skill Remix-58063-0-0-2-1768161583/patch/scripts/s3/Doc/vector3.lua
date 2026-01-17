---@class util.vector3
--- Represents a 3D vector used for positions, directions, and offsets in world space.
--- Supports standard arithmetic, geometric operations, and swizzle-based construction.
---
--- Vectors are immutable: operations return new vectors rather than modifying the original.
---
--- Common uses:
---  • World positions (object locations)
---  • Directional vectors (movement, facing)
---  • Offsets and raycast endpoints
---
---@field x number X component (east–west axis)
---@field y number Y component (north–south axis)
---@field z number Z component (vertical axis)

---@field xyz01 string
--- Swizzle accessor for constructing new vectors using component reordering
--- and constants `0` and `1`.
---
--- Examples:
---  • v.xyz   → (x, y, z)
---  • v.xz0   → (x, z, 0)
---  • v.yx1   → (y, x, 1)
---  • v.zyx   → (z, y, x)

---@field __add fun(a: util.vector3, b: util.vector3): util.vector3
--- Returns the vector sum `a + b`.

---@field __sub fun(a: util.vector3, b: util.vector3): util.vector3
--- Returns the vector difference `a - b`.

---@field __mul fun(v: util.vector3, k: number): util.vector3
--- Returns the vector scaled by scalar `k`.

---@field __div fun(v: util.vector3, k: number): util.vector3
--- Returns the vector divided by scalar `k`.
--- ⚠ Division by zero is undefined.

---@field __tostring fun(v: util.vector3): string
--- Returns a human-readable string representation, e.g. "(x, y, z)".

---@field dot fun(self: util.vector3, v: util.vector3): number
--- Returns the dot product of this vector and `v`.
--- Useful for angle checks, projections, and facing tests.

---@field cross fun(self: util.vector3, v: util.vector3): util.vector3
--- Returns the cross product of this vector and `v`.
--- Result is perpendicular to both input vectors.

---@field emul fun(self: util.vector3, v: util.vector3): util.vector3
--- Returns the element-wise (Hadamard) product.
--- `(x1*x2, y1*y2, z1*z2)`

---@field ediv fun(self: util.vector3, v: util.vector3): util.vector3
--- Returns the element-wise division.
--- `(x1/x2, y1/y2, z1/z2)`
--- ⚠ Division by zero is undefined.

---@field length fun(self: util.vector3): number
--- Returns the Euclidean length (magnitude) of the vector.

---@field length2 fun(self: util.vector3): number
--- Returns the squared length of the vector.
--- Faster than `length()`; useful for comparisons.

---@field normalize fun(self: util.vector3): util.vector3
--- Returns a unit-length vector pointing in the same direction.
--- ⚠ Normalizing a zero-length vector is undefined.
