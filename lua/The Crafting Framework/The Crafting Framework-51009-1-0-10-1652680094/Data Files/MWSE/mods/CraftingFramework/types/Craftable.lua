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
---@field materialsRecovery number
---@field maxSteepness number
---@field resultAmount number
---@field recoverEquipmentMaterials boolean
---@field destroyCallback function
---@field placeCallback function
---@field craftCallback function
---@field mesh string
---@field previewMesh string
---@field rotationAxis craftingFrameworkRotationAxis
---@field previewScale number
---@field previewHeight number

---@class craftingFrameworkCraftable
---@field id string This is the unique identifier used internally by the Crafting Framework to identify this `craftable`.
---@field name string The name of the craftable displayed in the menu. If not set, it will use the name of the craftable object
---@field placedObject string If the object being placed is different from the object that is picked up by the player, use `id` for the held object id and `placedObject` for the id of the object that is placed in the world
---@field uncarryable boolean Treats the crafted item as uncarryable even if the object type otherwise would be carryable. This will make the object be crafted immediately into the world and remove the Pick Up button from the menu. Not required if the crafted object is already uncarryable, such as a static or activator
---@field additionalMenuOptions craftingFrameworkMenuButtonData[] A list of additional menu options that will be displayed in the craftable menu
---@field soundId string Provide a sound ID (for a sound registered in the CS) that will be played when the craftable is crafted
---@field soundPath string Provide a custom sound path that will be played when an craftable is crafted
---@field soundType craftingFrameworkCraftableSoundType Determines the crafting sound used, using sounds from the framework or added by interop. These include: "fabric", "wood", "leather", "rope", "straw", "metal" and "carve."
---@field materialRecovery number The percentage of materials used to craft the item that will be recovered. Overrides the default amount set in the Crafting Framework MCM
---@field maxSteepness number The max angle a crafted object will be oriented to while repositioning
---@field resultAmount number The amount of the item to be crafted
---@field recoverEquipmentMaterials boolean When set to true, and the craftable is an armor or weapon item, equipping it when it has 0 condition will destroy it and salvage its materials
---@field destroyCallback function Custom function called after a craftable has been destroyed
---@field placeCallback function Custom function called after a craftable has been placed
---@field craftCallback function Custom function called after a craftable has been crafted
---@field previewMesh string This is the mesh override for the preview pane in the crafting menu. If no mesh is present, the 3D model of the associated item will be used.
---@field rotationAxis craftingFrameworkRotationAxis **Default "z"** Determines about which axis the preview mesh will rotate around. Defaults to the z axis.
---@field previewScale number **Default 1** Determines the scale of the preview mesh.
---@field previewHeight number **Default 1** Determines the height of the mesh in the preview window.
craftingFrameworkCraftable = {}

---comment
---@param reference tes3reference
function craftingFrameworkCraftable:activate(reference) end

---comment
---@param reference tes3reference
function craftingFrameworkCraftable:swap(reference) end

---comment
---@param reference tes3reference
---@return craftingFrameworkMenuButtonData[] menuButtons
function craftingFrameworkCraftable:getMenuButtons(reference) end

---comment
---@param reference tes3reference
function craftingFrameworkCraftable:position(reference) end

---Transfers all the items from crafted container to the player's inventory. Shows a message if some items were transfered.
---@param reference tes3reference
function craftingFrameworkCraftable:recoverItemsFromContainer(reference) end

---This will add the item to player's inventory. If the item is a container, its contents will be added to the player's inventory.
---@param reference tes3reference
function craftingFrameworkCraftable:pickUp(reference) end

---comment
---@param materialsUsed table<string, number>
---@param materialRecovery number
---@return string|nil recoverMessage A message that tells the player what materials were recovered. If no materials were recovered, returns nil.
function craftingFrameworkCraftable:recoverMaterials(materialsUsed, materialRecovery) end

---This will completely remove the provided `reference` from the game world. It will clean up after itself:
---
--- - The reference will be disabled and deleted after a frame.
---
--- - The reference's contents will be added to the player if applicable.
---
--- - A deconstruction sound will be played.
---
--- - Some materials may be recovered, depending on the settings.
---
--- - The player will be notified by a message.
---
--- - If this craftable object has `:destroyCallback()`, it will be executed.
---@param reference tes3reference
function craftingFrameworkCraftable:destroy(reference) end

---comment
---@return string name
function craftingFrameworkCraftable:getName() end

---comment
---@return string name In the format: "`itemName x resultAmount`".
function craftingFrameworkCraftable:getNameWithCount() end

---comment
function craftingFrameworkCraftable:playCraftingSound() end

---comment
function craftingFrameworkCraftable:playDeconstructionSound() end

---comment
---@param materialsUsed table<string, number>
function craftingFrameworkCraftable:craft(materialsUsed) end

---comment
---@param materialsUsed table<string, number>
function craftingFrameworkCraftable:place(materialsUsed) end


---@class Craftable
---@field registeredCraftables table<string, craftingFrameworkCraftable>
Craftable = {}

---comment
---@param id string
---@return craftingFrameworkCraftable craftable
function Craftable.getCraftable(id) end

---comment
---@param id string
---@return craftingFrameworkCraftable craftable
function Craftable.getPlacedCraftable(id) end

---This method registers a new craftable object.
---@param data craftingFrameworkCraftableData
---@return craftingFrameworkCraftable
function Craftable:new(data) end

---comment
function Craftable:registerEvents() end
