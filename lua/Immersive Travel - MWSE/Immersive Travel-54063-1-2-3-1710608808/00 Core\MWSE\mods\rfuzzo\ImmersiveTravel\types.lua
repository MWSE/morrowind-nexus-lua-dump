-- /////////////////////////////////////////////////////////////////////////////////////////
-- ////////////// CLASSES

---@class PositionRecord
---@field x number The x position
---@field y number The y position
---@field z number The z position

---@class ServiceData
---@field class string The npc class name
---@field mount string The mount
---@field override_npc string[]? register specific npcs with the service
---@field override_mount table<string,string[]>? register specific mounts with the service
---@field routes table<string, string[]>? routes
---@field ground_offset number DEPRECATED: editor marker offset

---@class Slot
---@field position PositionRecord slot
---@field animationGroup string[]?
---@field animationFile string?
---@field handle mwseSafeObjectHandle?
---@field node niNode?

---@class HiddenSlot
---@field position PositionRecord slot
---@field handles mwseSafeObjectHandle[]?

---@class Clutter
---@field position PositionRecord slot
---@field orientation PositionRecord? slot
---@field id string? reference id
---@field mesh string? reference id
---@field handle mwseSafeObjectHandle?
---@field node niNode?

---@class MountData
---@field sound string[] The mount sound id
---@field loopSound boolean The mount sound id
---@field mesh string The mount mesh path
---@field offset number The mount offset to ground
---@field sway number The sway intensity
---@field speed number forward speed
---@field turnspeed number turning speed
---@field hasFreeMovement boolean turning speed
---@field slots Slot[]
---@field guideSlot Slot?
---@field hiddenSlot HiddenSlot?
---@field clutter Clutter[]?
---@field idList string[]?
---@field scale number?
---@field minSpeed number?
---@field maxSpeed number?
---@field changeSpeed number?
---@field freedomtype string? -- flying, boat, ground
---@field accelerateAnimation string? -- animation to play while accelerating. slowing
---@field forwardAnimation string? -- walk animation
---@field materials CraftingFramework.MaterialRequirement[]? -- recipe materials for crafting the mount
---@field nodeName string? -- niNode, slots are relative tho this
---@field nodeOffset PositionRecord? -- position of the nodeName relative to sceneNode

---@class ReferenceRecord
---@field cell tes3cell The cell
---@field position tes3vector3 The reference position
