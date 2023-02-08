---@meta

---@alias craftingFrameworkCraftableSoundType
---| '"fabric"'
---| '"wood"'
---| '"leather"'
---| '"rope"'
---| '"straw"'
---| '"metal"'
---| '"carve"'

---@class craftingFrameworkCraftableData
---@field id string **Required.**
---@field name string The name of the craftable
---@field placedObject string
---@field uncarryable boolean
---@field additionalMenuOptions craftingFrameworkMenuButtonData[]
---@field soundId string
---@field soundPath string
---@field soundType craftingFrameworkCraftableSoundType
---@field materialRecovery number
---@field maxSteepness number
---@field resultAmount number
---@field recoverEquipmentMaterials boolean
---@field destroyCallback function
---@field placeCallback function
---@field positionCallback function
---@field craftCallback function
---@field mesh string
---@field previewMesh string
---@field rotationAxis craftingFrameworkRotationAxis
---@field previewScale number
---@field previewHeight number
---@field noResult boolean

---@class craftingFrameworkCraftable : craftingFrameworkCraftableData
craftingFrameworkCraftable = {}