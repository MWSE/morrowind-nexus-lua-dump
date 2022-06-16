local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("Craftable")
local Positioner = require("CraftingFramework.controllers.Positioner")
local config = require("CraftingFramework.config")

---@class craftingFrameworkCraftable
local Craftable = {
    schema = {
        name = "Craftable",
        fields = {
            id = { type = "string", required = true },
            name = { type = "string", required = false },
            placedObject = { type = "string", required = false },
            uncarryable = { type = "boolean", required = false },
            additionalMenuOptions = { type = "table", required = false },
            soundId = { type = "string", required = false },
            soundPath = { type = "string", required = false },
            soundType = { type = "string", required = false },
            materialRecovery = { type = "number", required = false},
            maxSteepness = { type = "number", required = false},
            resultAmount = { type = "number", required = false},
            recoverEquipmentMaterials = { type = "boolean", required = false},
            destroyCallback = { type = "function", required = false },
            placeCallback = { type = "function", required = false },
            craftCallback = { type = "function", required = false },
            mesh = { type = "string", required = false},
            previewMesh = { type = "string", required = false},
            rotationAxis = { type = "string", required = false},
            previewScale = { type = "number", required = false},
            previewHeight = { type = "number", required = false, default = 0}
        }
    },
    constructionSounds = {
        fabric = {
            "craftingFramework\\craft\\Fabric1.wav",
            "craftingFramework\\craft\\Fabric2.wav",
            "craftingFramework\\craft\\Fabric3.wav",
            "craftingFramework\\craft\\Fabric4.wav",
        },
        wood = {
            "craftingFramework\\craft\\Wood1.wav",
            "craftingFramework\\craft\\Wood2.wav",
            "craftingFramework\\craft\\Wood3.wav",
        },
        leather = {
            "craftingFramework\\craft\\Leather1.wav",
            "craftingFramework\\craft\\Leather2.wav",
            "craftingFramework\\craft\\Leather3.wav",
        },
        rope = {
            "craftingFramework\\craft\\Rope1.wav",
            "craftingFramework\\craft\\Rope2.wav",
            "craftingFramework\\craft\\Rope3.wav",
        },
        straw = {
            "craftingFramework\\craft\\Straw1.wav",
            "craftingFramework\\craft\\Straw2.wav",
        },
        metal = {
            "craftingFramework\\craft\\Metal1.wav",
            "craftingFramework\\craft\\Metal2.wav",
            "craftingFramework\\craft\\Metal3.wav",
        },
        carve = {
            "craftingFramework\\craft\\Carve1.wav",
            "craftingFramework\\craft\\Carve2.wav",
        },
        default = {
            "craftingFramework\\craft\\Fabric1.wav",
            "craftingFramework\\craft\\Fabric2.wav",
            "craftingFramework\\craft\\Fabric3.wav",
            "craftingFramework\\craft\\Fabric4.wav",
        }
    },
    deconstructionSounds = {
        "craftingFramework\\craft\\Deconstruct1.wav",
        "craftingFramework\\craft\\Deconstruct2.wav",
        "craftingFramework\\craft\\Deconstruct3.wav",
    },

}


Craftable.registeredCraftables = {}
Craftable.craftablesIdexedByPlacedObject = {}
--Static functions

---@param id string
---@return craftingFrameworkCraftable craftable
function Craftable.getCraftable(id)
    return Craftable.registeredCraftables[id:lower()]
end

---@param id string
---@return craftingFrameworkCraftable craftable
function Craftable.getPlacedCraftable(id)
    id = id:lower()
    return Craftable.craftablesIdexedByPlacedObject[id]
end

function Craftable:isCarryable()
    if self.uncarryable then return false end
    local unCarryableTypes = {
        [tes3.objectType.light] = true,
        [tes3.objectType.container] = true,
        [tes3.objectType.static] = true,
        [tes3.objectType.door] = true,
        [tes3.objectType.activator] = true,
        [tes3.objectType.npc] = true,
        [tes3.objectType.creature] = true,
    }
    local placedObject = tes3.getObject(self.id)
    if placedObject then
        if placedObject.canCarry then
            return true
        end
        local objType = placedObject.objectType

        if unCarryableTypes[objType] then
            return false
        end
        return true
    end
end

function Craftable:getPlacedObjectId()
    if self.placedObject then
        return self.placedObject
    else
        if not self:isCarryable() then
            return self.id
        end
    end
end

---@param data craftingFrameworkCraftableData
---@return craftingFrameworkCraftable
function Craftable:new(data)
    Util.validate(data, Craftable.schema)
    data.id = data.id:lower()
    --for pre-1.0.5 compatibility
    if data.mesh then
        data.previewMesh = data.mesh
        data.mesh = nil
    end
    ---@type craftingFrameworkCraftable
    local craftable = setmetatable(data, self)
    self.__index = self


    local placedObjectId = craftable:getPlacedObjectId()
    if placedObjectId then
        local existingCraftable = Craftable.registeredCraftables[craftable.id]
        if existingCraftable then
            logger:warn("Found existing craftable %s, merging", craftable.id)
            logger:debug("existing.placedObject: %s", existingCraftable.placedObject)
            logger:debug("craftable.placedObject: %s", craftable.placedObject)
            --merge
            table.copymissing(craftable, existingCraftable)
        end
        Craftable.registeredCraftables[craftable.id] = craftable
        Craftable.craftablesIdexedByPlacedObject[placedObjectId:lower()] = craftable
    end
    return craftable
end


function Craftable:activate(reference)
    Util.messageBox{
        message = self:getName(),
        buttons = self:getMenuButtons(reference),
        doesCancel = true,
        callbackParams = { reference = reference }
    }
end

function Craftable:swap(reference)
    local ref = tes3.createReference{
        object = self:getPlacedObjectId(),
        position = reference.position:copy(),
        orientation = reference.orientation:copy(),
        cell = reference.cell
    }
    ref.data.crafted = true
    ref.data.positionerMaxSteepness = self.maxSteepness
    Util.deleteRef(reference)
end


---@param reference tes3reference
---@return craftingFrameworkMenuButtonData[] menuButtons
function Craftable:getMenuButtons(reference)
	---@type craftingFrameworkMenuButtonData[]
    local menuButtons = {}
    if self.additionalMenuOptions then
        for _, option in ipairs(self.additionalMenuOptions) do
            table.insert(menuButtons, {
                text = option.text,
                enableRequirements = function()
                    if option.enableRequirements then
                        local isEnabled = option.enableRequirements({
                            reference = reference
                        })
                        return isEnabled
                    end
                    return true
                end,
                showRequirements = function()
                    if option.showRequirements then
                        local show = option.showRequirements({
                            reference = reference
                        })
                        return show
                    end
                    return true
                end,
                tooltip = option.tooltip,
                tooltipDisabled = option.tooltipDisabled,
                callback = function()
                    option.callback({
                        reference = reference
                    })
                end
            })
        end
    end
	---@type craftingFrameworkMenuButtonData[]
    local defaultButtons = {
        {
            text = "Open",
            showRequirements = function()
                return reference.object.objectType == tes3.objectType.container
            end,
            callback = function()
                timer.delayOneFrame(function()
                    reference.data.allowActivate = true
                    tes3.player:activate(reference)
                    reference.data.allowActivate = nil
                end)
            end
        },
        {
            text = "Position",
            callback = function()
                self:position(reference)
            end
        },
        {
            text = "Pick Up",
            showRequirements = function()
                return self:isCarryable()
            end,
            callback = function()
                self:pickUp(reference)
            end
        },
        {
            text = "Destroy",
            showRequirements = function()
                return not self:isCarryable()
            end,
            callback = function()
                Util.messageBox{
                    message = string.format("Destroy %s?", self:getName()),
                    buttons = {
                        {
                            text = "Yes",
                            callback = function()
                                self:destroy(reference)
                            end
                        },

                    },
                    doesCancel = true
                }

            end
        }
    }

    for _, button in ipairs(defaultButtons) do
        table.insert(menuButtons, button)
    end
    return menuButtons
end

function Craftable:position(reference)
    timer.delayOneFrame(function()
        -- Put those hands away.
        if (tes3.mobilePlayer.weaponReady) then
            tes3.mobilePlayer.weaponReady = false
        elseif (tes3.mobilePlayer.castReady) then
            tes3.mobilePlayer.castReady = false
        end
        Positioner.togglePlacement{ target = reference }
    end)
end

function Craftable:recoverItemsFromContainer(reference)
    --if container, move to player inventory
    if reference.baseObject.objectType == tes3.objectType.container then
        local itemList = {}
        for stack in tes3.iterate(reference.object.inventory.iterator) do
            table.insert(itemList, stack)
        end
        for _, stack in ipairs(itemList) do
            tes3.transferItem{ from = reference, to = tes3.player, item = stack.object, count = stack.count, updateGUI  = false, playSound = false }
        end
        tes3ui.forcePlayerInventoryUpdate()
        if #itemList > 0 then
            tes3.messageBox("Contents of %s added to inventory.", self:getName())
        end
    end
end

function Craftable:pickUp(reference)
    self:recoverItemsFromContainer(reference)
    tes3.addItem{ reference = tes3.player, item = self.id }
    Util.deleteRef(reference)
end

---@param materialsUsed table<string, number>
---@return string|nil recoverMessage A message that tells the player what materials were recovered. If no materials were recovered, returns nil.
function Craftable:recoverMaterials(materialsUsed, materialRecovery)
    local recoverMessage = "You recover the following materials:"
    local didRecover = false
    for id, count in pairs(materialsUsed) do
        local item = tes3.getObject(id)
        materialRecovery = materialRecovery or self.materialRecovery or config.mcm.defaultMaterialRecovery
        local recoveryRatio = materialRecovery / 100
        local recoveredCount = math.floor(count * math.clamp(recoveryRatio, 0, 1) )
        if item and recoveredCount > 0 then
            didRecover = true
            recoverMessage = recoverMessage .. string.format("\n- %s x%d", item.name, recoveredCount )
            tes3.addItem{
                reference = tes3.player,
                item = item,
                count = recoveredCount,
                playSound = false,
                updateGUI = false
            }
        end
    end
    tes3ui.forcePlayerInventoryUpdate()
    if didRecover then
        return recoverMessage
    end
end

function Craftable:destroy(reference)
    self:recoverItemsFromContainer(reference)
    self:playDeconstructionSound()
    local destroyMessage = string.format("%s has been destroyed.", self:getName())
    --check if materials are recovered
    if reference.data.materialsUsed  then
        local recoverMessage = self:recoverMaterials(reference.data.materialsUsed, reference.data.materialRecovery)
        if recoverMessage then
            destroyMessage = destroyMessage .. "\n" .. recoverMessage
        end
    end
    tes3.messageBox(destroyMessage)

    reference.sceneNode.appCulled = true
    tes3.positionCell{
        reference = reference,
        position = { 0, 0, 0, },
    }
    reference:disable()
    timer.delayOneFrame(function()
        mwscript.setDelete{ reference = reference}
    end)
    if self.destroyCallback then
        self:destroyCallback()
    end
end

function Craftable:getName()
    return self.name or tes3.getObject(self.id) and tes3.getObject(self.id).name or "[unknown]"
end

function Craftable:getNameWithCount()
    return string.format("%s%s", self:getName(),
        self.resultAmount and string.format(" x%d", self.resultAmount) or ""
    )
end

function Craftable:playCraftingSound()
    if self.soundType then
        local soundPick = table.choice(self.constructionSounds[self.soundType])
        if soundPick then
            tes3.playSound{ soundPath = soundPick}
            return
        end
    end
    if self.soundId then
        tes3.playSound{ sound = self.soundId }
    elseif self.soundPath then
        tes3.playSound{ soundPath = self.soundPath }
    else
        local soundPick = table.choice(self.constructionSounds.default)
        tes3.playSound{ soundPath = soundPick }
    end
end

function Craftable:playDeconstructionSound()
    local soundPick = table.choice(self.deconstructionSounds)
    tes3.playSound{soundPath = soundPick }
end

function Craftable:craft(materialsUsed)
    if not self:isCarryable() then
        self:position(self:place(materialsUsed))
    else
        local item = tes3.getObject(self.id)
        if item then
            local count = self.resultAmount or 1
            tes3.addItem{
                reference = tes3.player,
                item = item, playSound = false,
                count = count,
            }
            if count == 1 and item.maxCondition and self.recoverEquipmentMaterials then
                local itemData = tes3.addItemData{
                    to = tes3.player,
                    item = item,
                }
                itemData.data.materialsUsed = materialsUsed
                itemData.data.materialRecovery = self.materialRecovery
            end
            tes3.messageBox("You successfully crafted %s%s.",
                item.name,
                self.resultAmount and string.format(" x%d", self.resultAmount) or ""
            )
        end
    end
    self:playCraftingSound()
    if self.craftCallback then
        self:craftCallback()
    end
end

function Craftable:place(materialsUsed)
    local eyeOri = tes3.getPlayerEyeVector()
    local eyePos = tes3.getPlayerEyePosition()
    local ray = tes3.rayTest{
        position = tes3.getPlayerEyePosition(),
        direction = tes3.getPlayerEyeVector(),
        ignore = { tes3.player}
    }
    local rayDist = ray and ray.intersection and math.min(ray.distance -5, 200) or 0
    local position = eyePos + eyeOri * rayDist

    local ref = tes3.createReference{
        object = self:getPlacedObjectId(),
        cell = tes3.player.cell,
        orientation = tes3.player.orientation:copy() + tes3vector3.new(0, 0, math.pi),
        position = position
    }
    ref.data.crafted = true
    ref.data.positionerMaxSteepness = self.maxSteepness
    ref.data.materialsUsed = materialsUsed
    ref.data.materialRecovery = self.materialRecovery
    ref:updateSceneGraph()
    ref.sceneNode:updateNodeEffects()
    if self.placeCallback then
        self:placeCallback()
    end
    return ref
end

return Craftable