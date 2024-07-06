local base = require("InspectIt.controller.base")
local config = require("InspectIt.config")
local settings = require("InspectIt.settings")
local ori = require("InspectIt.component.orientation")
local mesh = require("InspectIt.component.mesh")
local bit = require("bit")
local zoomThreshold = 0  -- delta
local zoomDuration = 0.4 -- second
local angleThreshold = 0 -- pixel
local velocityEpsilon = 0.000001
local velocityThreshold = 0 -- pixel
local frictionRotation = 0.1     -- Attenuation with respect to velocity
local resistanceRotation = 3.0   -- Attenuation with respect to time
local frictionTranslation = 0.00001     -- Attenuation with respect to velocity
local resistanceTranslation = 9.0   -- Attenuation with respect to time
local fittingRatio = 0.5 -- Ratio to fit the screen

---@class ModelData
---@field root niNode?
---@field bounds tes3boundingBox?

-- scene graph struestue
--  - cameraRoot
--      (- Some nodes possibly added by the mod)
--          - niCamera: It can't have children. Normally it is identity, but it can be moved as we press the tab key.
--      - self.cameraJoint: It faces the same direction as niCamera. But it is not converted to y-up, it remains z-up.
--          -  self.root
--              - model node

---@class Inspector : IController
---@field root niNode? inspection root node
---@field cameraJoint niNode? camera facing node
---@field enterFrameCallback fun(e : enterFrameEventData)?
---@field activateCallback fun(e : activateEventData)?
---@field switchAnotherLookCallback fun()?
---@field switchLightingCallback fun()?
---@field toggleMirroringCallback fun()?
---@field resetPosecCallback fun()?
---@field angularVelocity tes3vector3 -- vec2 doesnt have dot
---@field velocity tes3vector3 -- vec2 doesnt have dot
---@field baseRotation tes3matrix33
---@field baseScale number
---@field zoomStart number
---@field zoomEnd number
---@field zoomTime number
---@field zoomMax number
---@field baseModel ModelData
---@field anotherModel ModelData
---@field anotherData? AnotherLookData
---@field anotherLook boolean
---@field lighting LightingType
---@field distance tes3vector3 half width, distance, half height
---@field object tes3activator|tes3alchemy|tes3apparatus|tes3armor|tes3bodyPart|tes3book|tes3clothing|tes3container|tes3containerInstance|tes3creature|tes3creatureInstance|tes3door|tes3ingredient|tes3leveledCreature|tes3leveledItem|tes3light|tes3lockpick|tes3misc|tes3npc|tes3npcInstance|tes3probe|tes3repairTool|tes3static|tes3weapon?
---@field mirrored boolean
local this = {}
setmetatable(this, { __index = base })

---@type Inspector
local defaults = {
    enterFrame = nil,
    angularVelocity = tes3vector3.new(0, 0, 0),
    velocity = tes3vector3.new(0, 0, 0),
    baseRotation = tes3matrix33.new(),
    baseScale = 1,
    zoomStart = 1,
    zoomEnd = 1,
    zoomTime = 0,
    zoomMax = 2,
    anotherData = nil,
    anotherLook = false,
    lighting = settings.lightingType.Default,
    distance = tes3vector3.new(20, 20, 20),
    mirrored = false,
    baseModel = {
    },
    anotherModel = {
    },
}

---@return Inspector
function this.new()
    local instance = base.new(defaults)
    setmetatable(instance, { __index = this })
    ---@cast instance Inspector

    return instance
end

--- Normally it is identity, but it can be moved as we press the tab key.
---@return tes3matrix33
local function CalculateCameraRelativeRotation()
    if tes3.worldController and tes3.worldController.worldCamera then
        local camera = tes3.worldController.worldCamera.cameraData.camera
        local view = tes3matrix33.new(camera.worldRight, camera.worldDirection, camera.worldUp):transpose() -- keep z-up lookat
        local baseView = tes3.worldController.worldCamera.cameraRoot.worldTransform.rotation:copy()
        local relative = baseView:transpose() * view
        return relative
    end
    return tes3matrix33.new(1, 0, 0, 0, 1, 0, 0, 0, 1)
end

---@param lighting LightingType
---@return tes3worldControllerRenderCamera|tes3worldControllerRenderTarget? camera
---@return number fovX
---@return tes3matrix33
local function GetCamera(lighting)
    local fovX = mge.camera.fov
    if tes3.worldController then
        if lighting == settings.lightingType.Constant then
            local camera = tes3.worldController.menuCamera
            if camera and camera.cameraData then
                fovX = camera.cameraData.fov
            end
            -- The menu camera does not seem to be affected by niCamera rotation
            return tes3.worldController.menuCamera, fovX, tes3matrix33.new(1, 0, 0, 0, 1, 0, 0, 0, 1)
        end
        return tes3.worldController.armCamera, fovX, CalculateCameraRelativeRotation() -- default
    end
    return nil, fovX, tes3matrix33.new(1, 0, 0, 0, 1, 0, 0, 0, 1)
end

---@param parent niNode
---@param node niNode
---@param first boolean
local function AttachChild(parent, node, first)
    -- Add to the top of the list.
    if first then
        local children = table.new(table.size(parent.children), 0)
        for _, child in ipairs(parent.children) do
            table.insert(children, child)
        end
        parent:detachAllChildren()
        parent:attachChild(node, true)
        for _, child in ipairs(children) do
            parent:attachChild(child, true)
        end
    else
        parent:attachChild(node)
    end
end

---@param node niNode
---@param add boolean
local function AddOrRemoveZBufferProperty(node, add)
    local name =  "InspectIt:NoDepth"
    local p = node:getProperty(ni.propertyType.zBuffer)
    if add then
        if not p then
            local zBufferProperty = niZBufferProperty.new()
            zBufferProperty.name = name
            zBufferProperty:setFlag(false, 0) -- test
            zBufferProperty:setFlag(false, 1) -- write
            node:attachProperty(zBufferProperty)
            node:updateProperties()
        end
    elseif p and p.name == name then
        node:detachProperty(ni.propertyType.zBuffer)
        node:updateProperties()
    end
end

---@param t number [0,1]
---@return number [0,1]
local function EaseOutQuad(t)
    local ix = 1.0 - t
    return 1.0 - ix * ix
end

---@param t number [0,1]
---@return number [0,1]
local function EaseOutCubic(t)
    local ix = 1.0 - t
    ix = ix * ix * ix
    return 1.0 - ix
end

---@param t number [0,1]
---@return number [0,1]
local function EaseOutQuart(t)
    local ix = 1.0 - t
    ix = ix * ix
    ix = ix * ix
    return 1.0 - ix
end

---@param ratio number
---@param estart number
---@param eend number
---@return number
local function Ease(ratio, estart, eend)
    local t = EaseOutCubic(ratio)
    local v = math.lerp(estart, eend, t)
    return v
end

---@param self Inspector
---@param scale number
function this.SetScale(self, scale)
    local root = self.root
    if root then
        local prev = root.scale
        local newScale = math.max(self.baseScale * scale, math.fepsilon)
        root.scale = newScale
        -- self.logger:trace("Zoom %f -> %f", prev, scale)
        mesh.RescaleParticle(root, prev / newScale)
    end
end


---@param self Inspector
---@param pickup boolean
function this.PlaySound(self, pickup)
    if config.inspection.playSound and self.object then
        -- TODO NPC says greeting, but finding the voiceline is hard.
        local volume = 0.5 -- Usually the volume is low to sound on the 3D.
        if self.object.objectType == tes3.objectType.door then
            local object = self.object ---@cast object tes3door
            local sound = pickup and object.openSound or object.closeSound
            if sound then
                sound:play(nil, volume)
            end
            return
        elseif self.object.objectType == tes3.objectType.creature then
            if config.development.experimental then
                local object = self.object ---@cast object tes3creature|tes3creatureInstance
                if object.isInstance then
                    object = object.baseObject
                end
                while object.soundCreature do
                    object = object.soundCreature
                end
                local soundGen = pickup and tes3.soundGenType.moan or tes3.soundGenType.roar
                local gen = tes3.getSoundGenerator(object.id, soundGen)
                if gen then
                    gen.sound:play(nil, volume)
                end
            end
            return
        end
        tes3.playItemPickupSound({ item = self.object.id, pickup = pickup })
    end
end

---@param self Inspector
---@param e enterFrameEventData
function this.OnEnterFrame(self, e)
    if settings.OnOtherMenu() then
        -- pause
        return
    end
    local root = self.root
    if root then
        -- tes3ui.captureMouseDrag may be better?

        local wc = tes3.worldController
        local ic = wc.inputController

        -- scale
        local zoom = ic.mouseState.z
        if math.abs(zoom) > zoomThreshold then
            zoom = zoom * 0.001 * config.input.sensitivityZ * (config.input.inversionZ and -1 or 1)
            -- self.logger:trace("Wheel: %f, wheel velocity %f", ic.mouseState.z, zoom)
            -- update current zooming
            local scale = Ease(self.zoomTime / zoomDuration, self.zoomStart, self.zoomEnd)
            self.zoomStart = scale
            local limit = math.max(self.zoomMax / self.baseScale, 1)
            self.zoomEnd = math.clamp(self.zoomEnd + zoom, 0.5, limit)
            self.zoomTime = 0
        end

        if self.zoomTime < zoomDuration then
            self.zoomTime = math.min(self.zoomTime + e.delta, zoomDuration)
            local scale = Ease(self.zoomTime / zoomDuration, self.zoomStart, self.zoomEnd)

            self:SetScale(scale)
        end

        if ic:isMouseButtonDown(0) then -- left click
            -- rotate
            local zAngle = ic.mouseState.x
            local xAngle = ic.mouseState.y

            if math.abs(zAngle) <= angleThreshold then
                zAngle = 0
            end
            if math.abs(xAngle) <= angleThreshold then
                xAngle = 0
            end
            zAngle = zAngle * wc.mouseSensitivityX * config.input.sensitivityX * (config.input.inversionX and -1 or 1)
            xAngle = xAngle * wc.mouseSensitivityY * config.input.sensitivityY * (config.input.inversionY and -1 or 1)
            -- self.logger:trace("Mouse %f, %f, Angular velocity %f, %f", ic.mouseState.x, ic.mouseState.y, zAngle, xAngle)

            self.angularVelocity.z = zAngle
            self.angularVelocity.x = xAngle
        elseif ic:isMouseButtonDown(2) then -- middle click
            -- translate
            local modifier = self.distance.y * 0.5
            local horizontal = ic.mouseState.x * modifier
            local vertical = ic.mouseState.y * -modifier
            if math.abs(horizontal) <= velocityThreshold then
                horizontal = 0
            end
            if math.abs(vertical) <= velocityThreshold then
                vertical = 0
            end
            -- need inversion? another sensitivity and inversion config?
            horizontal = horizontal * wc.mouseSensitivityX * config.input.sensitivityX * (config.input.inversionX and -1 or 1)
            vertical = vertical * wc.mouseSensitivityY * config.input.sensitivityY * (config.input.inversionY and -1 or 1)
            self.velocity.x = horizontal
            self.velocity.z = vertical
        end

        if self.angularVelocity:dot(self.angularVelocity) > velocityEpsilon then
            local zAxis = tes3vector3.new(0, 0, 1) -- Y
            local xAxis = tes3vector3.new(1, 0, 0)

            local zRot = niQuaternion.new()
            local xRot = niQuaternion.new()

            zRot:fromAngleAxis(self.angularVelocity.z, zAxis)
            xRot:fromAngleAxis(self.angularVelocity.x, xAxis)

            local q = niQuaternion.new()
            q:fromRotation(root.rotation:copy())

            local dest = zRot * xRot * q
            local m = tes3matrix33.new()
            m:fromQuaternion(dest)
            root.rotation = m:copy()

            -- No basis in physics.
            self.angularVelocity = self.angularVelocity:lerp(self.angularVelocity * frictionRotation,
                math.clamp(e.delta * resistanceRotation, 0, 1))
        end
        if self.velocity:dot(self.velocity) > velocityEpsilon then
            -- center vs corners
            local dest = root.translation:copy() + self.velocity:copy()
            dest.x = math.clamp(dest.x, -self.distance.x, self.distance.x)
            dest.z = math.clamp(dest.z, -self.distance.z, self.distance.z)
            root.translation = dest
            self.velocity = self.velocity:lerp(self.velocity * frictionTranslation,
                math.clamp(e.delta * resistanceTranslation, 0, 1))
        end
        -- local euler = root.rotation:toEulerXYZ():copy()
        -- tes3.messageBox(string.format("%f, %f, %f", math.deg(euler.x), math.deg(euler.y), math.deg(euler.z)))

        -- TODO play controllers, but those does not work.
        -- updateTime = updateTime  + e.delta
        -- root:update({ controllers = true })
        root:update()
    end
end

---@param self Inspector
--- @param e activateEventData
function this.OnActivate(self, e)
    -- block picking up items
    self.logger:trace("Block to Activate")
    e.block = true
end

---@param self Inspector
function this.SwitchAnotherLook(self)
    self.logger:debug("Switch another look")
    local root = self.root
    if root and self.anotherData and self.anotherData.data and self.anotherData.type ~= nil then
        local another = self.anotherModel

        if self.anotherData.type == settings.anotherLookType.BodyParts then
            if not another.root then

                local data = self.anotherData.data ---@cast data BodyPartData

                -- base
                self.logger:debug("Load base anim id: %s, mesh: %s, sourceMod: %s", tes3.player.object.id, tes3.player.object.mesh, settings.GetSourceMod(tes3.player.object))
                if not tes3.player.object.mesh or not tes3.getFileExists(string.format("Meshes\\%s", tes3.player.object.mesh)) then
                    self.logger:error("Missing base anim id: %s, mesh: %s, sourceMod: %s", tes3.player.object.id, tes3.player.object.mesh, settings.GetSourceMod(tes3.player.object))
                    return
                end
                -- remaining any state with cache?
                local root = tes3.loadMesh(tes3.player.object.mesh, false) --[[@as niNode]]

                -- remove unnecessary nodes
                mesh.CleanMesh(root)

                -- -- reset
                root.translation = tes3vector3.new(0,0,0)
                root.scale = 1
                root:update() -- transform

                another.root = root

                local bp = require("InspectIt.component.bodypart")
                for _, part in ipairs(data.parts) do
                    bp.BuildBodyPart(part, root)
                end

                -- rotate to base object relative
                local orientation = ori.GetBodyPartOrientation(self.object)
                local rot = tes3matrix33.new()
                rot:fromEulerXYZ(math.rad(orientation.x), math.rad(orientation.y), math.rad(orientation.z))
                another.root.rotation = self.baseRotation:copy():transpose() * rot:copy()

                -- TODO apply race width, height scaling if need
                another.root:update()

                local bounds = mesh.CalculateBounds(another.root)
                another.bounds = bounds
                local offset =  (bounds.max + bounds.min) * -0.5
                self.logger:debug("another bounds: %s", bounds)
                self.logger:debug("another offset: %s", offset)
                self.logger:trace("%s", mesh.Dump(another.root))
                another.root.translation = offset:copy()
            end

            if self.anotherLook then
                self.logger:debug("Body parts to Item")
                root:detachChild(self.anotherModel.root)
                root:attachChild(self.baseModel.root)
            else
                self.logger:debug("Item to Body parts")
                root:detachChild(self.baseModel.root)
                root:attachChild(self.anotherModel.root)
            end

            self.anotherLook = not self.anotherLook
            -- Rotation is not a problem in the relative orientation.
            -- But if the scales are in similar proportions, relative scales are fine, but if they aren't, I guess they're may be cliped...
            -- So adjust the appropriate scale and zoom amount
            -- This doesn't have to be computed for each time, just have double the data.
            -- There are also multiple cameras, so the number of cameras increases for the combination.
            self:AdjustScale(self.lighting, self.anotherLook)

            root:updateEffects()
            root:update()
            self:PlaySound(self.anotherLook)

            -- notify disabling mirroring option
            local payload = { another = self.anotherLook } ---@type ChangedAnotherLookEventData
            event.trigger(settings.changedAnotherLookEventName, payload)
        end

        if self.anotherData.type == settings.anotherLookType.WeaponSheathing then

            if not another.root then
                local data = self.anotherData.data ---@cast data WeaponSheathingData
                self.logger:debug("Load weapon sheathing mesh: %s", data.path)
                if not data.path or not tes3.getFileExists(string.format("Meshes\\%s", data.path)) then
                    self.logger:error("Missing weapon sheathing mesh: %s", data.path)
                    return
                end
                another.root = tes3.loadMesh(data.path, true):clone() --[[@as niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode]]

                -- use base offet, no adjust centering
                local offset = (self.baseModel.bounds.max + self.baseModel.bounds.min) * -0.5
                another.root.translation = offset:copy()
            end

            if self.anotherLook then
                self.logger:debug("Sheathed Weapon")
                root:detachChild(self.anotherModel.root)
                root:attachChild(self.baseModel.root)
            else
                self.logger:debug("Drawn Weapon")
                root:detachChild(self.baseModel.root)
                root:attachChild(self.anotherModel.root)
            end

            self.anotherLook = not self.anotherLook

            -- apply same scale for particle
            local scale = Ease(self.zoomTime / zoomDuration, self.zoomStart, self.zoomEnd)
            self:SetScale(scale)
            root:updateEffects()
            root:update()
            self:PlaySound(not self.anotherLook)
        end

        if self.anotherData.type == settings.anotherLookType.Book and self.anotherData.data.text then
            -- Currently, when there is no lighting, it is rendered after menus and is in front of the book menu, which is disturbing, so it should be hidden in some way.

            root.flags = bit.bor(root.flags, 0x1)     -- hidden flags
            root:update()
            self.logger:debug("Hide the object for book menu")
            local menu = nil ---@type tes3uiElement?

            if self.anotherData.data.type == tes3.bookType.book then
                self.logger:debug("Show book menu")
                tes3ui.showBookMenu(self.anotherData.data.text)
                menu = tes3ui.findMenu("MenuBook")
            elseif self.anotherData.data.type == tes3.bookType.scroll then
                self.logger:debug("Show scroll menu")
                tes3ui.showScrollMenu(self.anotherData.data.text)
                menu = tes3ui.findMenu("MenuScroll")
            end

            if menu then
                -- Return to visibility when book/scroll is closed
                menu:registerAfter(tes3.uiEvent.destroy, -- or close mouseClick
                    function(_)
                        if self.root then
                            self.root.flags = bit.band(self.root.flags, bit.bnot(0x1))
                            self.root:update()
                            self.logger:debug("Show again the object for book menu")
                        end
                    end)
            else
                self.logger:error("Not find book/scroll menu")
                -- revert
                root.flags = bit.band(root.flags, bit.bnot(0x1))
                root:update()
            end
        end
    end

end

---@param self Inspector
---@param bounds tes3boundingBox
---@param distance number
---@param nearPlaneDistance number
---@return number limitScale
function this.CalculateZoomMax(self, bounds, distance, nearPlaneDistance)
    -- zoom limitation
    local extents = (bounds.max - bounds.min) * 0.5 -- * self.baseScale
    self.logger:debug("bounds extents %s", extents)
    local halfLength = extents:length()
    -- halfLength = math.max(extents.x, extents.y, extents.z, 0)
    -- Offset because it is clipped before the near clip for some reason.
    local clipOffset = 3
    -- I would expect the near to be the same even if the camera is different, and it is.
    local limitScale = math.max(distance - (nearPlaneDistance + clipOffset), nearPlaneDistance) / math.max(halfLength, math.fepsilon)
    self.logger:debug("halfLength %f, limitScale %f (%f)", halfLength, limitScale, limitScale / self.baseScale)
    return limitScale -- relative scale, apply base scale after
    -- self.zoomMax = math.max(limitScale / self.baseScale, 1)
    -- self.zoomMax = 2
end

---@param self Inspector
---@param lighting LightingType
---@param anotherLook boolean
function this.AdjustScale(self, lighting, anotherLook)
    local camera, fovX, _ = GetCamera(lighting)
    if camera then
        -- recalculate base scale, fov changed
        -- but different perspective due to changes in angle of view will occur.
        local cameraData = camera.cameraData
        local bounds = self.baseModel.bounds
        if anotherLook then
            bounds = self.anotherModel.bounds
        end
        if bounds then
            local baseScale, distanceWidth, distanceHeight = self:ComputeFittingScale(bounds, cameraData, self.distance.y, fovX, fittingRatio)
            self.baseScale = baseScale

            self.zoomMax = self:CalculateZoomMax(bounds, self.distance.y, cameraData.nearPlaneDistance)

            -- rescale limit
            -- Or always use the camera with the widest field of view of those you plan to use.
            local limit = math.max(self.zoomMax / self.baseScale, 1)
            self.zoomEnd = math.clamp(self.zoomEnd, 0.5, limit)

            local scale = Ease(self.zoomTime / zoomDuration, self.zoomStart, self.zoomEnd)
            self:SetScale(scale)

            -- clamp translation
            local root = self.root
            if root then
                local dest = root.translation:copy()
                dest.x = dest.x / self.distance.x  -- to ratio
                dest.z = dest.z / self.distance.z  -- to ratio
                self.distance = tes3vector3.new(distanceWidth * 0.5, self.distance.y, distanceHeight * 0.5)
                dest.x = math.clamp(dest.x * self.distance.x, -self.distance.x, self.distance.x)
                dest.z = math.clamp(dest.z * self.distance.z, -self.distance.z, self.distance.z)
                root.translation = dest
            end
        end
    end
end

---@param self Inspector
function this.SwitchLighting(self)
    -- next type
    local lighting = self.lighting + 1
    if lighting > table.size(settings.lightingType) then -- mod, avoid floor
       lighting = 1
    end
    ---@cast lighting LightingType
    local prev = GetCamera(self.lighting)
    local next, fovX, cameraFacing = GetCamera(lighting)
    if prev and next then
        self.logger:debug("Switch lighting: %d -> %d", self.lighting, lighting)
        -- Currently the only difference in lighting is the camera

        self:AdjustScale(lighting, self.anotherLook)

        prev.cameraRoot:detachChild(self.cameraJoint)

        if lighting == settings.lightingType.Constant then
            self.cameraJoint.rotation = cameraFacing -- identity
            -- Almost UIs do not have a ZBuffer property. And for some reason the menu camera does not have it either, with depth test enabled. So Disable it.
            AddOrRemoveZBufferProperty(next.cameraRoot, true)
            AttachChild(next.cameraRoot, self.cameraJoint, true)
        else
            self.cameraJoint.rotation = cameraFacing
            AttachChild(next.cameraRoot, self.cameraJoint, false)
        end

        prev.cameraRoot:updateEffects()
        prev.cameraRoot:update()
        next.cameraRoot:updateEffects()
        next.cameraRoot:update()
        self.lighting = lighting
    else
        self.logger:error("Failed to find camera for switching lighting.")
    end
end

function this.ToggleMirroring(self)
    local model = self.baseModel.root
    if self.object and self.object.isLeftPart and model then
        if self.anotherLook then
            self.logger:warn("No mirroring is necessary.")
            return
        end
        local after = false
        if mesh.CanMirror(self.object) then
            self.logger:debug("Mirror the left part")
            -- item is Y-mirrored
            local mirror = tes3matrix33.new(
                1, 0, 0,
                0, -1, 0,
                0, 0, 1
            )
            model.rotation = mirror:copy()
            after = true
        else
            self.logger:debug("Normal the left part")
            local identity = tes3matrix33.new()
            identity:toIdentity()
            model.rotation = identity:copy()
            after = false
        end
        -- There is a situation where changing the sourceMod from config and changing the ID with the button results in the same state.
        if self.mirrored ~= after then
            -- adjust centering offset, simply flip Y
            -- no need zoom re-fitting. center point changes, but the size should remain the same.
            model.translation = tes3vector3.new(model.translation.x, -model.translation.y, model.translation.z)
            self.logger:debug("Flipped offset: %s", model.translation)
        end
        self.mirrored = after

        -- enabled no cull
        -- currently armor, cloth are always no cull
        -- local props = self.root:getProperty(ni.propertyType.stencil)
        -- if props then
        --     props.drawMode = 3 -- DRAW_BOTH
        -- end
        self.root:update()
    end
end

function this.ResetPose(self)
    self.logger:debug("Reset pose")
    local root = self.root
    if root then
        self.angularVelocity = tes3vector3.new(0, 0, 0)
        self.velocity = tes3vector3.new(0, 0, 0)
        self.zoomStart = 1
        self.zoomEnd = 1
        self.zoomTime = zoomDuration
        root.rotation = self.baseRotation:copy()
        self:SetScale(1)
        root.translation = tes3vector3.new(0, self.distance.y, 0)
        root:update()
    end
end

---@param offset number
---@return niNode
local function SetupNode(offset)
    -- local root = niNode.new()

    ---@diagnostic disable-next-line: undefined-global
    -- local root = niSortAdjustNode.new()
    -- root.sortingMode = 1 -- ni.sortAdjustMode.off

    -- Unfortunately, it is not possible to create an accumulator from MWSE, so we use the asset.
    -- If not sorted by subsort, the alpha mesh in the object may become inconsistent.
    -- NiSortAdjustNode: sortingMode = ni.sortAdjustMode.subsort, accumulator = NiAlphaAccumulator
    local root = tes3.loadMesh("InspectIt/root.nif", false)
    root.name = "InspectIt:Root"
    root.translation = tes3vector3.new(0, offset, 0)
    root.appCulled = false

    -- If transparency is included, it may not work unless it is specified on a per material.
    local zBufferProperty = niZBufferProperty.new()
    zBufferProperty.name = "InspectIt:DepthTestWrite"
    zBufferProperty:setFlag(true, 0) -- test
    zBufferProperty:setFlag(true, 1) -- write
    root:attachProperty(zBufferProperty)
    -- No culling on the back face because the geometry of the part to be placed on the ground does not exist.
    local stencilProperty = niStencilProperty.new()
    stencilProperty.name = "InspectIt:CullFace"
    stencilProperty.drawMode = 3 -- DRAW_BOTH
    root:attachProperty(stencilProperty)
    local vertexColorProperty = niVertexColorProperty.new()
    vertexColorProperty.name = "InspectIt:emiAmbDif"
    vertexColorProperty.lighting = 1 -- ni.lightingMode.emiAmbDif
    vertexColorProperty.source = 2 -- ni.sourceVertexMode.ambDiff
    root:attachProperty(vertexColorProperty)
    local alphaProperty = niAlphaProperty.new()
    alphaProperty.name = "InspectIt:Opaque"
    alphaProperty.alphaTestRef = 0
    alphaProperty.propertyFlags = 236 -- 0x1 enable tranparency, so 0 or player reference's default(236)
    root:attachProperty(alphaProperty)
    root:updateProperties()
    -- NiMaterialProperty can't be created. If necessary, clone.
    return root
end

---@param self Inspector
---@param bounds tes3boundingBox
---@param cameraData tes3worldControllerRenderCameraData
---@param distance number
---@param fovX number
---@param ratio number
---@return number scale
---@return number width
---@return number height
function this.ComputeFittingScale(self, bounds, cameraData, distance, fovX, ratio)
    local aspectRatio = cameraData.viewportHeight / cameraData.viewportWidth
    local tan = math.tan(math.rad(fovX) * 0.5)
    local width = tan * math.max(distance, cameraData.nearPlaneDistance + 1) * 2.0
    local height = width * aspectRatio
    -- The cubes like the wooden box should be a perfect fit, but for some reason they don't match.
    -- conservative
    local screenSize = math.min(width, height) * ratio
    local size = bounds.max - bounds.min
    local boundsSize = math.max(size.x, size.y, size.z, math.fepsilon)

    -- diagonal
    -- boundsSize = size:length() -- 3d or dominant 2d
    -- screenSize = math.sqrt(width * width + height * height)

    -- moderation
    -- boundsSize = size:length() -- 3d diagonal
    -- screenSize = math.max(width, height)

    local scale = screenSize / boundsSize

    self.logger:debug("fovX: %f, MGE near: %f", fovX, mge.camera.nearRenderDistance)
    self.logger:debug("Camera near: %f, far: %f, fov: %f", cameraData.nearPlaneDistance, cameraData.farPlaneDistance,
        cameraData.fov)
    self.logger:debug("Camera viewport width: %d, height: %d", cameraData.viewportWidth, cameraData.viewportHeight)
    self.logger:debug("Distant width: %f, height: %f, fovX: %f", width, height, fovX)
    self.logger:debug("Fitting scale: %f", scale)
    return scale, width , height
end

---@param self Inspector
---@param params Activate.Params
function this.Activate(self, params)
    self.logger:debug("[Activate] Inspector")

    local object = params.object
    if not object then
        self.logger:error("No Object")
        return
    end

    -- Examine how the node remains in the effect
    if config.development.experimental then
        local src = tes3.player1stPerson.sceneNode
        if tes3.is3rdPerson() then
            src = tes3.player.sceneNode
        end
        if src then
            local total = 0
            local effects = src.effectList
            while effects do
                local pereffect = 0
                if effects.data then
                    local effect = effects.data
                    if effect:isInstanceOfType(ni.type.NiLight) then -- only light or point
                        local affects = effect.affectedNodes
                        while affects do
                            if affects.data then
                                self.logger:trace("%s", affects.data)
                                pereffect = pereffect + 1
                            end
                            affects = affects.next
                        end
                    end
                    self.logger:debug("Affected by %s: %d", effects.data, pereffect)
                end
                effects = effects.next
                total = total + pereffect
            end
            self.logger:debug("Total Affected: %d", total)
        end
    end

    local model = nil
    if params.referenceNode then
        self.logger:debug("Use reference: %s", params.referenceNode)
        model = params.referenceNode:clone() --[[@as niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode]]
        self.logger:trace("%s", mesh.Dump(model))
        -- This clone also seems to retarget skinInstance.bones and skinInstance.root by deep copying.
        -- So, retargeting like bodypart is not necessary.

        -- TODO reset animation or switching another, if need

        -- remove rotation, but including race scale
        if object.race and object.race.height and object.race.weight then
            -- or extract from rotation matrix
            -- can be done by more than just NPCs. but negative scale is difficult.
            -- row-major
            -- local x = model.rotation.x:length()
            -- local y = model.rotation.y:length()
            -- local z = model.rotation.z:length()

            local s = tes3vector2.new(object.race.weight.male, object.race.height.male)
            if object.female then
                s = tes3vector2.new(object.race.weight.female, object.race.height.female)
            end
            -- race sacale with identity
            local raceScale = tes3matrix33.new(
                s.x, 0, 0,
                0, s.x, 0,
                0, 0, s.y
            )
            model.rotation = raceScale:copy()
        else
            local identity = tes3matrix33.new()
            identity:toIdentity()
            model.rotation = identity:copy()
        end

    else
        self.logger:debug("Load id: %s, mesh: %s, sourceMod: %s", object.id, object.mesh, settings.GetSourceMod(object))
        if not object.mesh or not tes3.getFileExists(string.format("Meshes\\%s", object.mesh)) then
            self.logger:error("Missing id: %s, mesh: %s, sourceMod: %s", object.id, object.mesh, settings.GetSourceMod(object))
            return
        end
        model = tes3.loadMesh(object.mesh, true):clone() --[[@as niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode]]
        self.logger:trace("%s", mesh.Dump(model))
        -- reset
        model:clearTransforms()
    end

    -- clean
    mesh.CleanMesh(model)

    model.translation = tes3vector3.new(0,0,0)
    model.scale = 1

    -- When there are separate polygons on both sides, such as papers,
    -- without backface culling, the back side seems to appear in the foreground depending on both position.
    local backface = object.objectType ~= tes3.objectType.book and object.objectType ~= tes3.objectType.weapon
    self.mirrored = false
    if mesh.CanMirror(object) then
        self.logger:debug("Mirror the left part")
        -- item is Y-mirrored
        local mirror = tes3matrix33.new(
            1, 0, 0,
            0, -1, 0,
            0, 0, 1
        )
        model.rotation = mirror:copy()
        backface = true -- must
        self.mirrored = true
    end

    model:update() -- trailer partiles gone. but currently thoses are glitched, so its ok.
    -- self.logger:trace("%s", mesh.Dump(model))

    local bounds = mesh.CalculateBounds(model)

    -- initial scaling
    local camera, fovX, cameraFacing = GetCamera(self.lighting)
    if not camera then
        self.logger:error("Camera not found")
        return
    end

    local distance = params.offset

    -- centering
    local offset = (bounds.max + bounds.min) * -0.5
    self.logger:debug("bounds: %s", bounds)
    self.logger:debug("bounds offset: %s", offset)
    local root = SetupNode(distance)
    model.translation = offset
    root:attachChild(model)

    if backface and not self.mirrored then
        -- When there are separate polygons on both sides, such as papers,
        -- without backface culling, the back side seems to appear in the foreground depending on both position.
        -- Here for modding resources, the thickness is used to determine the thin, just as it is used to determine the paper.
        local size = bounds.max - bounds.min
        local thickness = math.min(size.x, size.y, size.z)
        if thickness < 1.5 then
            backface = false
            self.logger:debug("Enable culling backface, thickness: %f", thickness)
        end
    end

    if not backface then
        local props = root:getProperty(ni.propertyType.stencil)
        if props then
            props.drawMode = 0-- DRAW_CCW_OR_BOTH
        end
    end

    -- initial rotation
    local findKey = function(o)
        for key, value in pairs(tes3.objectType) do
            if o == value then
                return key
            end
        end
        return "unknown"
    end
    self.logger:debug("objectType: %s", findKey(object.objectType))
    local orientation = ori.GetOrientation(object, bounds)
    if orientation then
        local rot = tes3matrix33.new()
        rot:fromEulerXYZ(math.rad(orientation.x), math.rad(orientation.y), math.rad(orientation.z))
        root.rotation = root.rotation * rot:copy()
    end

    -- cloned reference is also cloned the effect list
    if not params.referenceNode then
        mesh.AttachDynamicEffect(root)
    end

    self.root = root
    self.baseModel.root = model
    self.baseModel.bounds = bounds:copy()
    self.anotherModel.bounds = bounds:copy() -- later
    self.anotherModel.root = nil
    self.anotherLook = false
    self.anotherData = params.another
    -- self.lighting = settings.lightingType.Default -- Probably more convenient to carry over previous values

    local cameraRoot = camera.cameraRoot
    local cameraData = camera.cameraData
    local scale, distanceWidth, distanceHeight = self:ComputeFittingScale(bounds, cameraData, distance, fovX, fittingRatio)
    self.distance = tes3vector3.new(distanceWidth * 0.5, distance, distanceHeight * 0.5)

    self.baseScale = root.scale
    self:SetScale(scale)

    self.angularVelocity = tes3vector3.new(0, 0, 0)
    self.velocity = tes3vector3.new(0, 0, 0)
    self.baseRotation = root.rotation:copy()
    self.baseScale = scale
    self.zoomStart = 1
    self.zoomEnd = 1
    self.zoomTime = zoomDuration

    self.zoomMax = self:CalculateZoomMax(bounds, distance,cameraData.nearPlaneDistance)

    local cameraJoint = niNode.new()
    cameraJoint.name = "InspectIt:CameraJoint"
    cameraJoint.rotation = cameraFacing
    cameraJoint:attachChild(root)
    self.cameraJoint = cameraJoint

    AttachChild(cameraRoot, self.cameraJoint, self.lighting == settings.lightingType.Constant)
    if self.lighting == settings.lightingType.Constant then
        AddOrRemoveZBufferProperty(cameraRoot, true)
    end
    cameraRoot:updateEffects()
    cameraRoot:update()

    --- subscribe events
    self.enterFrameCallback = function(e)
        self:OnEnterFrame(e)
    end
    self.activateCallback = function(e)
        self:OnActivate(e)
    end
    self.switchAnotherLookCallback = function()
        self:SwitchAnotherLook()
    end
    self.switchLightingCallback = function()
        self:SwitchLighting()
    end
    self.toggleMirroringCallback = function()
        self:ToggleMirroring()
    end
    self.resetPosecCallback = function()
        self:ResetPose()
    end
    event.register(tes3.event.enterFrame, self.enterFrameCallback)
    event.register(tes3.event.activate, self.activateCallback)
    event.register(settings.switchAnotherLookEventName, self.switchAnotherLookCallback)
    event.register(settings.switchLightingEventName, self.switchLightingCallback)
    event.register(settings.toggleMirroringEventName, self.toggleMirroringCallback)
    event.register(settings.resetPoseEventName, self.resetPosecCallback)

    -- It is better to play the sound in another controller, but it is easy to depend on the inspector's state, so run it in that.
    -- it seems it doesn't matter if the ID is not from tes3item.
    self.object = object
    self:PlaySound(true)

end

---@param self Inspector
---@param params Deactivate.Params
function this.Deactivate(self, params)
    if self.root then
        self.logger:debug("[Deactivate] Inspector")

        -- If reference is cloned, it has a dynamic effect on it, so it is detached recursively.
        -- Dynamic effect is cleaned up as the cell is unloaded without detaching it, but until then it seems to remain as an affected object.
        mesh.DetachDynamicEffect(self.root, true)
        self.root:updateEffects()

        local camera = GetCamera(self.lighting)
        if camera and self.cameraJoint then
            local cameraRoot = camera.cameraRoot
            cameraRoot:detachChild(self.cameraJoint)
            cameraRoot:updateEffects()
            cameraRoot:update()
        end
        camera = GetCamera(settings.lightingType.Constant)
        if camera then
            AddOrRemoveZBufferProperty(camera.cameraRoot, false)
        end

        event.unregister(tes3.event.enterFrame, self.enterFrameCallback)
        event.unregister(tes3.event.activate, self.activateCallback)
        event.unregister(settings.switchAnotherLookEventName, self.switchAnotherLookCallback)
        event.unregister(settings.switchLightingEventName, self.switchLightingCallback)
        event.unregister(settings.toggleMirroringEventName, self.toggleMirroringCallback)
        event.unregister(settings.resetPoseEventName, self.resetPosecCallback)
        self.enterFrameCallback = nil
        self.activateCallback = nil
        self.switchAnotherLookCallback = nil
        self.switchLightingCallback = nil
        self.toggleMirroringCallback = nil
        self.resetPosecCallback = nil

        if not params.menuExit then
            self:PlaySound(false)
        end
    end
    self.root = nil
    self.cameraJoint = nil
    self.baseModel.root = nil
    self.baseModel.bounds = nil
    self.anotherModel.root = nil
    self.anotherModel.bounds = nil
    self.anotherData = nil
    self.object = nil
end

---@param self Inspector
function this.Reset(self)
    self.root = nil
    self.cameraJoint = nil
    self.baseModel.root = nil
    self.baseModel.bounds = nil
    self.anotherModel.root = nil
    self.anotherModel.bounds = nil
    self.anotherData = nil
    self.object = nil
    self.lighting = settings.lightingType.Default
end

return this
