local Util = require("CraftingFramework.util.Util")
local logger = Util.createLogger("Craftable")
local Positioner = require("CraftingFramework.components.Positioner")
local SoundType = require("CraftingFramework.components.SoundType")
local StaticActivator = require("CraftingFramework.components.StaticActivator")
local Indicator = require("CraftingFramework.components.Indicator")
local RefDropper = require("CraftingFramework.components.RefDropper")
local config = require("CraftingFramework.config")

---@class CraftingFramework.Craftable.SuccessMessageCallback.params
---@field reference tes3reference? The reference that was crafted
---@field item tes3item? The item that was crafted
---@field materialsUsed table<string, number> The materials used in the craft, with the material id as key and the amount as value
---@field resultAmount number The amount of the crafted item

---@alias CraftingFramework.Craftable.SoundType
---| '"fabric"'
---| '"wood"'
---| '"leather"'
---| '"rope"'
---| '"straw"'
---| '"metal"'
---| '"carve"'

---@class CraftingFramework.Craftable.callback.params
---@field reference tes3reference? The reference that was crafted

---@class CraftingFramework.Craftable.craftCallback.params : CraftingFramework.Craftable.callback.params
---@field item tes3item? The item that was crafted
---@field materialsUsed table<string, number> The materials used in the craft, with the material id as key and the amount as value

---@class CraftingFramework.Craftable.data : CraftingFramework.Recipe.data
---@field id string The id of the crafted Item
---@field private mesh string deprecated
---@field craftableId nil

---@class CraftingFramework.Craftable : CraftingFramework.Craftable.data
local Craftable = {
    schema = {
        name = "Craftable",
        fields = {
            id = { type = "string", required = true },
            name = { type = "string", required = false },
            placedObject = { type = "string", required = false },
            additionalMenuOptions = { type = "table", required = false },
            soundId = { type = "string", required = false },
            soundPath = { type = "string", required = false },
            soundType = { type = "string", required = false },
            materialRecovery = { type = "number", required = false},
            maxSteepness = { type = "number", required = false},
            resultAmount = { type = "number", required = false},
            scale = { type = "number", required = false, default = 1.0 },
            --Preview window
            previewMesh = { type = "string", required = false},
            rotationAxis = { type = "string", required = false},
            previewScale = { type = "number", required = false},
            previewHeight = { type = "number", required = false, default = 0},
            --callbacks
            activateCallback = { type = "function", required = false },
            destroyCallback = { type = "function", required = false },
            placeCallback = { type = "function", required = false },
            positionCallback = { type = "function", required = false },
            craftCallback = { type = "function", required = false },
            quickActivateCallback = { type = "function", required = false },
            additionalUI  = { type = "function", required = false },
            successMessageCallback = { type = "function", required = false },
            pickUp = { type = "function", required = false },
            --flags
            uncarryable = { type = "boolean", required = false },
            recoverEquipmentMaterials = { type = "boolean", required = false},
            noResult = { type = "boolean", required = false},
            craftedOnly = { type = "boolean", required = false, default = true},

            --Positioner
            placementSetting = { type = "string", required = false},
            blockPlacementSettingToggle = { type = "boolean", required = false},
            pinToWall = { type = "boolean", required = false},
            floats = { type = "boolean", required = false},
            floatOffset = { type = "number", required = false},
            --Deprecated
            mesh = { type = "string", required = false},
        }
    },
}


Craftable.registeredCraftables = {}
Craftable.craftablesIdexedByPlacedObject = {}
--Static functions

---@param id string
---@return CraftingFramework.Craftable craftable
function Craftable.getCraftable(id)
    return Craftable.registeredCraftables[id:lower()]
end

---@param id string
---@return CraftingFramework.Craftable craftable
function Craftable.getPlacedCraftable(id)
    id = id:lower()
    return Craftable.craftablesIdexedByPlacedObject[id]
end

---@param data CraftingFramework.Craftable.data
---@return CraftingFramework.Craftable
function Craftable:new(data)
    logger:debug("Registering %s, craftedOnly = %s", data.id, data.craftedOnly)
    Util.validate(data, Craftable.schema)
    data.id = data.id:lower()

    --for pre-1.0.5 compatibility
    ---@diagnostic disable
    if data.mesh then
        data.previewMesh = data.mesh
        data.mesh = nil
    end
    ---@diagnostic enable

    --Generate a placed object static if defined one doesn't exist
    if data.placedObject then
        local placedObject = tes3.getObject(data.placedObject)
        if placedObject == nil then
            logger:debug("PlacedObject %s for craftable %s does not exist, creating a static",
                data.placedObject, data.id)
            local craftedObject = tes3.getObject(data.id)
            local placedObject = tes3.createObject{
                id = data.placedObject or nil,
                objectType = tes3.objectType.static,
                name = craftedObject.name,
                mesh = craftedObject.mesh,
            }
            data.placedObject = placedObject.id
        end
    end

    ---@cast data CraftingFramework.Craftable
    local craftable = data
    setmetatable(craftable, self)
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
        local function registerStaticActivator()
            StaticActivator.register{
                objectId = placedObjectId,
                name = craftable:getName(),
                craftedOnly = craftable.craftedOnly,
                onActivate = function(reference)
                    craftable:craftableActivated(reference)
                end,
                additionalUI = craftable.additionalUI
            }
        end
        if config.initialized then
            registerStaticActivator()
        else
            event.register("initialized", function()
                registerStaticActivator()
            end)
        end
    elseif craftable.additionalUI then
        Indicator.register{
            additionalUI = craftable.additionalUI,
            objectId = craftable.id,
            craftedOnly = craftable.craftedOnly,
        }
    end

    logger:debug("Registering ref dropper with id %s and replacerId %s", craftable.id, craftable.placedObject or "nil")

    RefDropper.register{
        droppedObjectId = craftable.id,
        replacerId = craftable.placedObject,
        scale = craftable.scale,
        onDrop = function(refDropper, newRef)
            if refDropper.replacerId then
                newRef.data.crafted = true
                newRef.data.positionerMaxSteepness = craftable.maxSteepness
            end
        end
    }
    return craftable
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
    local obj = tes3.getObject(self.id)
    if obj then
        if obj.canCarry then
            return true
        end
        local objType = obj.objectType

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


function Craftable:activate(reference)
    logger:debug("Craftable:activate: %s", reference)
    --if container and no additional menu options, open container
    local isContainer = reference.baseObject.objectType == tes3.objectType.container
    if isContainer then
        reference.data.allowActivate = true
        tes3.player:activate(reference)
        reference.data.allowActivate = false
    else
        tes3ui.showMessageMenu{
            message = self:getName(),
            buttons = self:getMenuButtons(reference),
            cancels = true,
            callbackParams = { reference = reference }
        }
    end
end

function Craftable:craftableActivated(reference)
    logger:debug("craftableActivated: %s", reference)
    logger:trace("craftableActivated placedObject id: %s", self:getPlacedObjectId())
    local modifierPressed = Util.isQuickModifierDown()
    if modifierPressed and self.quickActivateCallback then
        logger:debug("quickActivateCallback: %s", require("inspect")(self.quickActivateCallback))
        self:quickActivateCallback{reference = reference}
    elseif modifierPressed and Util.canBeActivated(reference) then
        logger:debug("vanilla activate")
        reference.data.allowActivate = true
        tes3.player:activate(reference)
        reference.data.allowActivate = nil
    elseif modifierPressed and self:isCarryable() then
        logger:debug("pickUp")
        self:pickUp(reference)
    elseif (not self.activateCallback) or self:activateCallback{reference = reference} == false then
        logger:debug("activate")
        self:activate(reference)
    end
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
            text = "Открыть",
            showRequirements = function()
                local contentsMenu = tes3ui.findMenu(tes3ui.registerID("MenuContents"))
                local alreadyOpen = contentsMenu and contentsMenu.visible

                return reference.object.objectType == tes3.objectType.container
                    and not alreadyOpen
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
            text = "Переместить",
            showRequirements = function()
                return reference.data.crafted or self:isCarryable()
            end,
            callback = function()
                self:position(reference)
            end
        },
        {
            text = "Убрать",
            showRequirements = function()
                return self:isCarryable()
            end,
            callback = function()
                self:pickUp(reference)
            end
        },
        {
            text = "Разобрать",
            showRequirements = function()
                return reference.data.crafted and not self:isCarryable()
            end,
            callback = function()
                tes3ui.showMessageMenu{
                    message = string.format("Разобрать %s?", self:getName()),
                    buttons = {
                        {
                            text = "Да",
                            callback = function()
                                self:destroy(reference)
                            end
                        },

                    },
                    cancels = true
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
    local safeRef = tes3.makeSafeObjectHandle(reference)
    timer.delayOneFrame(function()
        -- Put those hands away.
        if (tes3.mobilePlayer.weaponReady) then
            tes3.mobilePlayer.weaponReady = false
        elseif (tes3.mobilePlayer.castReady) then
            tes3.mobilePlayer.castReady = false
        end
        if safeRef and safeRef:valid() then
            Positioner.startPositioning{
                target = reference,
                placementSetting = self.placementSetting,
                blockToggle = self.blockPlacementSettingToggle,
                pinToWall = self.pinToWall,
                doFloat = self.floats,
                floatOffset = self.floatOffset,
            }
        end
    end)
end

function Craftable:recoverItemsFromContainer(reference)
    --if container, move to player inventory
    if reference.baseObject.objectType == tes3.objectType.container then
        Util.forceInstance(reference)
        local itemList = {}
        for stack in tes3.iterate(reference.object.inventory.iterator) do
            table.insert(itemList, stack)
        end
        for _, stack in ipairs(itemList) do
            tes3.transferItem{ from = reference, to = tes3.player, item = stack.object, count = stack.count, updateGUI  = false, playSound = false }
        end
        tes3ui.forcePlayerInventoryUpdate()
        if #itemList > 0 then
            tes3.messageBox("Содержимое %s добавлено в инвентарь.", self:getName())
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
    local recoverMessage = "Вы извлекли следующие материалы:"
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
                item = item, ---@diagnostic disable-line: assign-type-mismatch
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
    local destroyMessage = string.format("%s был разобран", self:getName())
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
    if self.destroyCallback then
        self:destroyCallback{
            reference = reference
        }
    end
    timer.delayOneFrame(function()
        reference:delete()
    end)
end

function Craftable:getName()
    return self.name or tes3.getObject(self.id) and tes3.getObject(self.id).name or "[unknown]"
end

function Craftable:getNameWithCount()
    return string.format("%s%s", self:getName(),
        self.resultAmount and string.format(" x%d", self.resultAmount) or ""
    )
end

---@param e? { defaultSoundType?: string }
function Craftable:playCraftingSound(e)
    e = e or {}
    if self.soundType then
        logger:trace("playing sound type %s", self.soundType)
        SoundType.play(self.soundType)
    elseif self.soundId then
        logger:trace("playing sound %s", self.soundId)
        tes3.playSound{ sound = self.soundId }
    elseif self.soundPath then
        logger:trace("playing sound %s", self.soundPath)
        tes3.playSound{ reference = tes3.player, soundPath = self.soundPath }
    elseif e.defaultSoundType then
        SoundType.play(e.defaultSoundType)
    else
        SoundType.play("defaultConstruction")
    end
end

function Craftable:playDeconstructionSound()
    SoundType.play("deconstruction")
end


---@param materialsUsed table<string, number> A table of material ids and the number of each used.
function Craftable:craft(materialsUsed)
    logger:debug("Craftable:craft %s", self.id)
    local reference
    local item
    if not self.noResult then
        if not self:isCarryable() then
            reference = self:place(materialsUsed)
            self:position(reference)
        else
            item = tes3.getObject(self.id)
            if item then
                local count = self.resultAmount or 1
                tes3.addItem{
                    reference = tes3.player,
                    item = item, ---@diagnostic disable-line: assign-type-mismatch
                    playSound = false,
                    count = count,
                }
                if count == 1 and item.maxCondition and self.recoverEquipmentMaterials then
                    local itemData = tes3.addItemData{
                        to = tes3.player,
                        item = item,---@diagnostic disable-line: assign-type-mismatch
                    }
                    itemData.data.materialsUsed = materialsUsed
                    itemData.data.materialRecovery = self.materialRecovery
                end
			    local successMessage
                if self.successMessageCallback then
                    successMessage = self:successMessageCallback{
                        craftable = self,
                        reference = reference,
                        item = item, ---@diagnostic disable-line: assign-type-mismatch
                        materialsUsed = materialsUsed,
                        resultAmount = self.resultAmount
                    }
                else
                    successMessage = string.format("Вы создали %s%s.",
                        item.name,
                        self.resultAmount and string.format(" x%d", self.resultAmount) or ""
                    )
                end
                if successMessage and successMessage ~= "" then
                    tes3.messageBox(successMessage)
                end
            end
        end
    end

    if self.craftCallback then
        logger:debug("Craftable:craft %s calling callback", self.id)
        self:craftCallback{
            reference = reference,
            item = item, ---@diagnostic disable-line: assign-type-mismatch
            materialsUsed = materialsUsed
        }
    end
    logger:debug("Craftable:craft %s done", self.id)
end

function Craftable:place(materialsUsed)
    local eyeOri = tes3.getPlayerEyeVector()
    local eyePos = tes3.getPlayerEyePosition()
    local ray = tes3.rayTest{
        position = tes3.getPlayerEyePosition(),
        direction = tes3.getPlayerEyeVector(),
        ignore = { tes3.player},
        maxDistance = 200,
        accurateSkinned = true,
    }
    local rayDist = ray and ray.intersection and math.min(ray.distance -5, 200) or 200
    local position = eyePos + eyeOri * rayDist

    logger:debug("Placing %s with scale %s", self.id, self.scale)
    local reference = tes3.createReference{
        object = self:getPlacedObjectId(),
        cell = tes3.player.cell,
        ---@diagnostic disable-next-line: assign-type-mismatch
        orientation = tes3.player.orientation:copy() + tes3vector3.new(0, 0, math.pi),
        position = position,
        scale = self.scale,
    }
    reference.data.crafted = true
    reference.data.positionerMaxSteepness = self.maxSteepness
    reference.data.materialsUsed = materialsUsed
    reference.data.materialRecovery = self.materialRecovery
    reference:updateSceneGraph()
    reference.sceneNode:updateEffects()
    if self.placeCallback then
        self:placeCallback{
            reference = reference
        }
    end
    return reference
end

return Craftable