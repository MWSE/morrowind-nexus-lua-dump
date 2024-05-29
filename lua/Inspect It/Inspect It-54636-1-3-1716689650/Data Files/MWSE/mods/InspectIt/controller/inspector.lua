local base = require("InspectIt.controller.base")
local config = require("InspectIt.config")
local settings = require("InspectIt.settings")
local ori = require("InspectIt.component.orientation")
local mesh = require("InspectIt.component.mesh")
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

---@class Inspector : IController
---@field root niNode?
---@field pivot niNode?
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
---@field original niNode?
---@field originalBounds tes3boundingBox?
---@field another niNode?
---@field anotherBounds tes3boundingBox?
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
    root = nil,
    pivot = nil,
    enterFrame = nil,
    angularVelocity = tes3vector3.new(0, 0, 0),
    velocity = tes3vector3.new(0, 0, 0),
    baseRotation = tes3matrix33.new(),
    baseScale = 1,
    zoomStart = 1,
    zoomEnd = 1,
    zoomTime = 0,
    zoomMax = 2,
    original = nil,
    originalBounds = nil,
    another = nil,
    anotherBounds = nil,
    anotherData = nil,
    anotherLook = false,
    lighting = settings.lightingType.Default,
    distance = tes3vector3.new(20, 20, 20),
    mirrored = false,
}

---@return Inspector
function this.new()
    local instance = base.new(defaults)
    setmetatable(instance, { __index = this })
    ---@cast instance Inspector

    return instance
end

---@param node niAmbientLight|niBillboardNode|niCamera|niCollisionSwitch|niDirectionalLight|niNode|niParticles|niPointLight|niRotatingParticles|niSortAdjustNode|niSpotLight|niSwitchNode|niTextureEffect|niTriShape
---@param func fun(node : niAmbientLight|niBillboardNode|niCamera|niCollisionSwitch|niDirectionalLight|niNode|niParticles|niPointLight|niRotatingParticles|niSortAdjustNode|niSpotLight|niSwitchNode|niTextureEffect|niTriShape)
local function foreach(node, func)
    func(node)
    if node.children then
        for _, child in ipairs(node.children) do
            if child then
                foreach(child, func)
            end
        end
    end
end

-- advanced traverser, allow nil, more info
---@param node niAmbientLight|niBillboardNode|niCamera|niCollisionSwitch|niDirectionalLight|niNode|niParticles|niPointLight|niRotatingParticles|niSortAdjustNode|niSpotLight|niSwitchNode|niTextureEffect|niTriShape?
---@param func fun(node : niAmbientLight|niBillboardNode|niCamera|niCollisionSwitch|niDirectionalLight|niNode|niParticles|niPointLight|niRotatingParticles|niSortAdjustNode|niSpotLight|niSwitchNode|niTextureEffect|niTriShape?, depth : number)
---@param depth integer?
local function traverse(node, func, depth)
    depth = depth or 0
    func(node, depth)
    if node and node.children then
        local count = #node.children
        if count == 1 and not node.children[1] then -- always allocated dummy [1]
        else
            local d = depth + 1
            for _, child in ipairs(node.children) do
                traverse(child, func, d)
            end
        end
    end
end

---@param root niAmbientLight|niBillboardNode|niCamera|niCollisionSwitch|niDirectionalLight|niNode|niParticles|niPointLight|niRotatingParticles|niSortAdjustNode|niSpotLight|niSwitchNode|niTextureEffect|niTriShape
local function DumpSceneGraph(root)
    -- TODO json format
    local str = {}
    traverse(root,
        function(node, depth)
            local indent = string.rep("    ", depth)
            if node then
                local out = string.format("%s:%s", node.RTTI.name, tostring(node.name))
                if node.translation and node.rotation and node.scale then
                    out = out .. "\n" .. indent .. string.format("  local trans %s, rot %s, scale %f", node.translation, node.rotation, node.scale)
                end
                if node.worldTransform then
                    out = out .. "\n" .. indent .. string.format("  world trans %s, rot %s, scale %f", node.worldTransform.translation, node.worldTransform.rotation, node.worldTransform.scale)
                end
                table.insert(str, indent .. "- " .. out)
            else
                table.insert(str, indent .. "- " .. "nil")
            end
        end)
    require("InspectIt.logger"):debug("\n" .. table.concat(str, "\n"))
    -- return str
end

---@param lighting LightingType
---@return tes3worldControllerRenderCamera|tes3worldControllerRenderTarget? camera
---@return number fovX
local function GetCamera(lighting)
    local fovX = mge.camera.fov
    if tes3.worldController then
        if lighting == settings.lightingType.Constant then
            local camera = tes3.worldController.menuCamera
            if camera and camera.cameraData then
                fovX = camera.cameraData.fov
            end
            return tes3.worldController.menuCamera, fovX
        end
        return tes3.worldController.armCamera, fovX -- default
    end
    return nil, fovX
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
    local prev = self.root.scale
    local newScale = math.max(self.baseScale * scale, math.fepsilon)
    self.root.scale = newScale
    -- self.logger:trace("Zoom %f -> %f", prev, scale)

    mesh.RescaleParticle(self.pivot, prev / newScale)
end


---@param self Inspector
---@param pickup boolean
function this.PlaySound(self, pickup)
    if config.inspection.playSound then
        -- TODO creature -> sound gen
        -- door, others
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

    if self.root then
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
            q:fromRotation(self.root.rotation:copy())

            local dest = zRot * xRot * q
            local m = tes3matrix33.new()
            m:fromQuaternion(dest)
            self.root.rotation = m:copy()

            -- No basis in physics.
            self.angularVelocity = self.angularVelocity:lerp(self.angularVelocity * frictionRotation,
                math.clamp(e.delta * resistanceRotation, 0, 1))
        end
        if self.velocity:dot(self.velocity) > velocityEpsilon then
            -- center vs corners
            local dest = self.root.translation:copy() + self.velocity:copy()
            dest.x = math.clamp(dest.x, -self.distance.x, self.distance.x)
            dest.z = math.clamp(dest.z, -self.distance.z, self.distance.z)
            self.root.translation = dest
            self.velocity = self.velocity:lerp(self.velocity * frictionTranslation,
                math.clamp(e.delta * resistanceTranslation, 0, 1))
        end
        -- local euler = self.root.rotation:toEulerXYZ():copy()
        -- tes3.messageBox(string.format("%f, %f, %f", math.deg(euler.x), math.deg(euler.y), math.deg(euler.z)))

        -- TODO play controllers, but those does not work.
        -- updateTime = updateTime  + e.delta
        --self.root:update({ controllers = true })
        self.root:update()
        self.root:updateEffects()
    end
end

---@param self Inspector
--- @param e activateEventData
function this.OnActivate(self, e)
    -- block picking up items
    self.logger:debug("Block to Activate")
    e.block = true
end

---@param self Inspector
function this.SwitchAnotherLook(self)
    self.logger:debug("Switch another look")
    if self.anotherData and self.anotherData.data and self.anotherData.type ~= nil then

        if self.anotherData.type == settings.anotherLookType.BodyParts then
            if not self.another then
                ---@class Socket
                ---@field name string?
                ---@field isLeft boolean?

                ---@type {[tes3.activeBodyPart] : Socket }
                local sockets = {
                    [tes3.activeBodyPart.head]          = { name = "Head", },
                    [tes3.activeBodyPart.hair]          = { name = "Head", },
                    [tes3.activeBodyPart.neck]          = { name = "Neck", },
                    [tes3.activeBodyPart.chest]         = { name = "Chest", },
                    [tes3.activeBodyPart.groin]         = { name = "Groin", },
                    [tes3.activeBodyPart.skirt]         = { name = "Groin", },
                    [tes3.activeBodyPart.rightHand]     = { name = "Right Hand", isLeft = false },
                    [tes3.activeBodyPart.leftHand]      = { name = "Left Hand", isLeft = true },
                    [tes3.activeBodyPart.rightWrist]    = { name = "Right Wrist", isLeft = false },
                    [tes3.activeBodyPart.leftWrist]     = { name = "Left Wrist", isLeft = true },
                    [tes3.activeBodyPart.shield]        = { name = "Shield Bone", },
                    [tes3.activeBodyPart.rightForearm]  = { name = "Right Forearm", isLeft = false },
                    [tes3.activeBodyPart.leftForearm]   = { name = "Left Forearm", isLeft = true },
                    [tes3.activeBodyPart.rightUpperArm] = { name = "Right Upper Arm", isLeft = false },
                    [tes3.activeBodyPart.leftUpperArm]  = { name = "Left Upper Arm", isLeft = true },
                    [tes3.activeBodyPart.rightFoot]     = { name = "Right Foot", isLeft = false },
                    [tes3.activeBodyPart.leftFoot]      = { name = "Left Foot", isLeft = true },
                    [tes3.activeBodyPart.rightAnkle]    = { name = "Right Ankle", isLeft = false },
                    [tes3.activeBodyPart.leftAnkle]     = { name = "Left Ankle", isLeft = true },
                    [tes3.activeBodyPart.rightKnee]     = { name = "Right Knee", isLeft = false },
                    [tes3.activeBodyPart.leftKnee]      = { name = "Left Knee", isLeft = true },
                    [tes3.activeBodyPart.rightUpperLeg] = { name = "Right Upper Leg", isLeft = false },
                    [tes3.activeBodyPart.leftUpperLeg]  = { name = "Left Upper Leg", isLeft = true },
                    [tes3.activeBodyPart.rightPauldron] = { name = "Right Clavicle", isLeft = false },
                    [tes3.activeBodyPart.leftPauldron]  = { name = "Left Clavicle", isLeft = true },
                    [tes3.activeBodyPart.weapon]        = { name = "Weapon Bone", }, -- the real node name depends on the current weapon type.
                    [tes3.activeBodyPart.tail]          = { name = "Tail" },
                }

                self.another = niNode.new()
                local data = self.anotherData.data ---@cast data BodyPartsData

                -- ground
                self.logger:debug("Load base mesh : %s", tes3.player.object.mesh)
                local root = tes3.loadMesh(tes3.player.object.mesh, true):clone()--[[@as niNode]]
                if not root then
                    self.logger:error("Failed to load: %s", tes3.player.object.mesh)
                    return
                end
                -- remove unnecessary nodes
                mesh.CleanMesh(root)
                --DumpSceneGraph(root)
                -- skeletal root
                local skeletal = root:getObjectByName("Bip01") --[[@as niNode?]]
                if skeletal then
                    self.logger:trace("skeletal")
                    self.logger:trace("%s", skeletal.translation)
                    self.logger:trace("%s", skeletal.rotation)
                    self.logger:trace("%s", skeletal.scale)
                    root = skeletal
                end
                -- -- reset
                root.translation = tes3vector3.new(0,0,0)
                root.scale = 1
                root:update() -- transform

                self.another = root

                for _, part in ipairs(data.parts) do
                    local bodypart = part.part
                    local socketInfo = sockets[part.type]
                    if socketInfo then
                        self.logger:debug("Load bodypart mesh : %s", bodypart.mesh)
                        local model = tes3.loadMesh(bodypart.mesh, true):clone() --[[@as niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode]]

                        -- remove oppsite parts
                        -- TODO or try to allow just matching name
                        if socketInfo.isLeft ~= nil then
                            mesh.CleanPartMesh(model, socketInfo.isLeft)
                        end


                        local socket = root:getObjectByName(socketInfo.name) --[[@as niNode?]]
                        if socket and socket.attachChild then
                            -- self.logger:debug("socket: %s from %d", s, part.type)
                            self.logger:trace("transform: %s", socket.worldTransform.translation)
                            self.logger:trace("rotation: %s", socket.worldTransform.rotation:toEulerXYZ())
                            self.logger:trace("scale: %s", socket.worldTransform.scale)

                            -- retarget
                            foreach(model, function (node)
                                if node:isInstanceOfType(ni.type.NiTriShape) then
                                    if node.skinInstance then
                                        for index, bone in ipairs(node.skinInstance.bones) do
                                            node.skinInstance.bones[index] = root:getObjectByName(bone.name)
                                        end
                                        -- node.skinInstance.root = skeletal -- crash!
                                        self.logger:debug("skin: %s", node.name)
                                    end

                                end
                            end)

                            -- below maybe no need with skinning

                            -- resolve offset
                            local offsetNode = model:getObjectByName("BoneOffset")
                            if offsetNode then
                                tes3.messageBox(string.format("BoneOffset: %s", offsetNode.translation))
                                self.logger:debug("BoneOffset: %s", offsetNode.translation)
                                model.translation = offsetNode.translation:copy()
                            end

                            -- resolve left
                            if socketInfo.isLeft == true then
                                -- non uniform scale
                                local mirror = tes3matrix33.new(
                                    -1, 0, 0,
                                    0, 1, 0,
                                    0, 0, 1
                                )
                                local rotation = model.rotation:copy()
                                --model.rotation = rotation:copy() * mirror:copy()
                                model.rotation = mirror:copy() * rotation:copy()
                                local t = model.translation:copy()
                                model.translation = mirror:copy() * t:copy()
                                self.logger:debug("mirror part")
                            end

                            -- extract root
                            socket:attachChild(model)
                        else
                            self.logger:warn("not find socket %s, %s", socketInfo.name, model.name)
                            root:attachChild(model)
                        end
                    else
                        self.logger:error("invalid body part %s", bodypart.id)
                    end

                end
                -- TODO apply race width, height scaling if npc base
                self.another:updateEffects()
                self.another:update()

                local bounds = self.another:createBoundingBox()
                local offset =  (bounds.max + bounds.min) * -0.5
                self.logger:debug("another bounds: %s", bounds)
                self.logger:debug("another offset: %s", offset)
                self.anotherBounds = bounds:copy()
            end

            if self.anotherLook then
                self.logger:debug("Body parts")
                self.pivot:detachChild(self.another)
                self.pivot:attachChild(self.original)
            else
                self.logger:debug("Physical Item")
                self.pivot:detachChild(self.original)
                self.pivot:attachChild(self.another)
            end
            -- TODO bounds and re-centering
            self.anotherLook = not self.anotherLook
            self:PlaySound(not self.anotherLook)
        end

        if self.anotherData.type == settings.anotherLookType.WeaponSheathing then

            if not self.another then
                local data = self.anotherData.data ---@cast data WeaponSheathingData
                self.logger:debug("Load weapon sheathing mesh : %s", data.path)
                self.another = tes3.loadMesh(data.path, true):clone() --[[@as niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode]]
                if not self.another  then
                    self.logger:error("Failed to load %s", data.path)
                    return
                end
            end

            if self.anotherLook then
                self.logger:debug("Sheathed Weapon")
                self.pivot:detachChild(self.another)
                self.pivot:attachChild(self.original)
            else
                self.logger:debug("Drawn Weapon")
                self.pivot:detachChild(self.original)
                self.pivot:attachChild(self.another)
            end


            self.anotherLook = not self.anotherLook

            -- apply same scale for particle
            local scale = Ease(self.zoomTime / zoomDuration, self.zoomStart, self.zoomEnd)
            self:SetScale(scale)
            -- just swap, no adjust centering
            self.pivot:update()
            self.pivot:updateEffects()
            self:PlaySound(self.anotherLook)
        end

        if self.anotherData.type == settings.anotherLookType.Book and self.anotherData.data.text then
            if self.anotherData.data.type == tes3.bookType.book then
                self.logger:debug("Show book menu")
                tes3ui.showBookMenu(self.anotherData.data.text)
            elseif self.anotherData.data.type == tes3.bookType.scroll then
                self.logger:debug("Show scroll menu")
                tes3ui.showScrollMenu(self.anotherData.data.text)
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
    local prev = GetCamera(self.lighting)
    local next, fovX = GetCamera(lighting)
    if prev and next then
        self.logger:debug("Switch lighting: %d -> %d", self.lighting, lighting)
        -- Currently the only difference in lighting is the camera

        -- recalculate base scale, fov changed
        -- but different perspective due to changes in angle of view will occur.
        local cameraData = next.cameraData
        local bounds = self.anotherLook and self.anotherBounds or self.originalBounds
        if bounds then
            local baseScale, distanceWidth, distanceHeight = self:ComputeFittingScale(bounds, cameraData, self.distance.y, fovX, fittingRatio)
            self.baseScale = baseScale

            -- rescale limit
            -- Or always use the camera with the widest field of view of those you plan to use.
            local limit = math.max(self.zoomMax / self.baseScale, 1)
            self.zoomEnd = math.clamp(self.zoomEnd, 0.5, limit)

            local scale = Ease(self.zoomTime / zoomDuration, self.zoomStart, self.zoomEnd)
            self:SetScale(scale)

            -- clamp translation
            local dest = self.root.translation:copy()
            dest.x = dest.x / self.distance.x  -- to ratio
            dest.z = dest.z / self.distance.z  -- to ratio
            self.distance = tes3vector3.new(distanceWidth * 0.5, self.distance.y, distanceHeight * 0.5)
            dest.x = math.clamp(dest.x * self.distance.x, -self.distance.x, self.distance.x)
            dest.z = math.clamp(dest.z * self.distance.z, -self.distance.z, self.distance.z)
            self.root.translation = dest
        end

        prev.cameraRoot:detachChild(self.root)
        next.cameraRoot:attachChild(self.root) -- lighting == settings.lightingType.Constant
        prev.cameraRoot:update()
        next.cameraRoot:update()
        self.lighting = lighting
    else
        self.logger:error("Failed to find camera for switching lighting.")
    end
end


function this.ToggleMirroring(self)
    local model = self.original -- FIXME for another
    if self.object and model then
        local after = false
        if mesh.CanMirror(self.object) then
            self.logger:debug("Mirror the left part")
            -- item is Y-mirrored
            local mirror = tes3matrix33.new(
                1, 0, 0,
                0, -1, 0,
                0, 0, 1
            )
            model.rotation = mirror:copy() -- overewrite, didnt has original rotation
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
            self.pivot.translation = tes3vector3.new(self.pivot.translation.x, -self.pivot.translation.y,
                self.pivot.translation.z)
            self.logger:debug("Flipped offset")
        end
        self.mirrored = after

        -- enabled no cull
        -- currently armor, cloth are always no cull
        -- local props = self.pivot:getProperty(ni.propertyType.stencil)
        -- if props then
        --     props.drawMode = 3 -- DRAW_BOTH
        -- end
        self.pivot:update()
    end
end

function this.ResetPose(self)
    self.logger:debug("Reset pose")
    if self.root then
        self.angularVelocity = tes3vector3.new(0, 0, 0)
        self.velocity = tes3vector3.new(0, 0, 0)
        self.zoomStart = 1
        self.zoomEnd = 1
        self.zoomTime = zoomDuration
        self.root.rotation = self.baseRotation:copy()
        self:SetScale(1)
        self.root.translation = tes3vector3.new(0, self.distance.y, 0)
        self.root:update()
    end
end

---@param offset number
---@return niNode
---@return niNode
local function SetupNode(offset)

    -- doesnt work...
    -- FIXME Menu camera does not draw first with attachment at the top and sorting off.
    ---@diagnostic disable-next-line: undefined-global
    -- local pivot = niSortAdjustNode.new()
    -- pivot.sortingMode = 1 -- ni.sortAdjustMode.off

    local pivot = niNode.new() -- pivot node
    pivot.name = "InspectIt:Pivot"
    -- If transparency is included, it may not work unless it is specified on a per material.
    local zBufferProperty = niZBufferProperty.new()
    zBufferProperty.name = "InspectIt:DepthTestWrite"
    zBufferProperty:setFlag(true, 0) -- test
    zBufferProperty:setFlag(true, 1) -- write
    pivot:attachProperty(zBufferProperty)
    -- No culling on the back face because the geometry of the part to be placed on the ground does not exist.
    local stencilProperty = niStencilProperty.new()
    stencilProperty.name = "InspectIt:NoCull"
    stencilProperty.drawMode = 3 -- DRAW_BOTH
    pivot:attachProperty(stencilProperty)
    local vertexColorProperty = niVertexColorProperty.new()
    vertexColorProperty.name = "InspectIt:emiAmbDif"
    vertexColorProperty.lighting = 1 -- ni.lightingMode.emiAmbDif
    vertexColorProperty.source = 2 -- ni.sourceVertexMode.ambDiff
    pivot:attachProperty(vertexColorProperty)
    pivot.appCulled = false

    local root = niNode.new()
    root.name = "InspectIt:Root"
    root:attachChild(pivot)
    root.translation = tes3vector3.new(0, offset, 0)
    root.appCulled = false
    return root, pivot
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

    self.logger:debug("use fovX: %f, MGE near: %f", fovX, mge.camera.nearRenderDistance)
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
    local object = params.object
    if not object then
        self.logger:error("No Object")
        return
    end

    local model = nil
    if params.referenceNode then
        self.logger:debug("Use reference : %s", params.referenceNode)
        model = params.referenceNode:clone() --[[@as niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode]]
        --DumpSceneGraph(model)
        -- TODO reset animation or switching another

        -- test: need retargeting?
        --[[
        foreach(model, function(node)
            if node:isOfType(ni.type.NiTriShape) then
                if node.skinInstance then
                    for index, bone in ipairs(node.skinInstance.bones) do
                        node.skinInstance.bones[index] = model:getObjectByName(bone.name)
                    end
                end
            end
        end)
        --]]

        -- test: copy base idle pose, but left parts resetted. skin is wired?
        --[[
        local mesh = object.mesh
        self.logger:debug("Load mesh : %s", mesh)
        local skeleton = tes3.loadMesh(mesh, true):clone()
        skeleton:update()
        skeleton = skeleton:getObjectByName("Bip01")
        foreach(skeleton, function(node)
            if node:isOfType(ni.type.NiNode) then
                local dest = model:getObjectByName(node.name)
                if dest then
                    dest.translation = node.translation:copy()
                    dest.rotation = node.rotation:copy()
                    dest.scale = node.scale
                end
            end
        end)
        --]]


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
        if not tes3.getFileExists(string.format("Meshes\\%s", object.mesh)) then
            self.logger:error("Not exist mesh: %s", object.mesh)
            return
        end

        self.logger:debug("Load mesh : %s", object.mesh)
        model = tes3.loadMesh(object.mesh, true):clone() --[[@as niBillboardNode|niCollisionSwitch|niNode|niSortAdjustNode|niSwitchNode]]
        -- TODO reset rotation?
    end

    -- clean
    mesh.CleanMesh(model)
    -- DumpSceneGraph(model)

    model.translation = tes3vector3.new(0,0,0)
    model.scale = 1

    -- When there are separate polygons on both sides, such as papers,
    -- without backface culling, the back side seems to appear in the foreground depending on both position.
    local backface = object.objectType ~= tes3.objectType.book
    self.mirrored = false
    if mesh.CanMirror(object) then
        self.logger:debug("Mirror the left part")
        -- item is Y-mirrored
        local mirror = tes3matrix33.new(
            1, 0, 0,
            0, -1, 0,
            0, 0, 1
        )
        local rotation = model.rotation:copy()
        model.rotation = mirror:copy() * rotation:copy()
        backface = true -- must
        self.mirrored = true
    end

    model:update() -- trailer partiles gone. but currently thoses are glitched, so its ok.
    --DumpSceneGraph(model)

    local bounds = mesh.CalculateBounds(model)

    self.anotherData = params.another

    local distance = params.offset

    -- centering
    -- FIXME Some creatures appear to be offset off. Should skinning be considered?
    local offset = (bounds.max + bounds.min) * -0.5
    self.logger:debug("bounds max: %s", bounds.max)
    self.logger:debug("bounds min: %s", bounds.min)
    self.logger:debug("bounds offset: %s", offset)
    local root, pivot = SetupNode(distance)
    pivot.translation = offset
    pivot:attachChild(model)

    if backface and not self.mirrored then
        -- When there are separate polygons on both sides, such as papers,
        -- without backface culling, the back side seems to appear in the foreground depending on both position.
        -- Here for modding resources, the thickness is used to determine the thin, just as it is used to determine the paper.
        local size = bounds.max - bounds.min
        local thickness = math.min(size.x, size.y, size.z)
        if thickness < 1.5 then
            backface = false
            self.logger:debug("enable culling backface, thickness: %f", thickness)
        end
    end

    if not backface then
        local props = pivot:getProperty(ni.propertyType.stencil)
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
        return ""
    end
    self.logger:debug("objectType: %s", findKey(object.objectType))
    local orientation = ori.GetOrientation(object, bounds)
    if orientation then
        local rot = tes3matrix33.new()
        rot:fromEulerXYZ(math.rad(orientation.x), math.rad(orientation.y), math.rad(orientation.z))
        root.rotation = root.rotation * rot:copy()
    end

    self.root = root
    self.pivot = pivot
    self.original = model
    self.originalBounds = bounds
    self.anotherBounds = bounds -- FIXME currently same
    self.another = nil
    self.anotherLook = false
    -- self.lighting = settings.lightingType.Default -- Probably more convenient to carry over previous values

    -- initial scaling
    -- FIXME It does not work correctly while rotating the camera while holding down the tab key during TPV.
    local camera, fovX = GetCamera(self.lighting)
    if not camera then
        self.logger:error("Camera not found")
        return
    end
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

    -- zoom limitation
    local extents = (bounds.max - bounds.min) * 0.5 -- * self.baseScale
    self.logger:debug("bounds extents %s", extents)
    local halfLength = extents:length()
    -- halfLength = math.max(extents.x, extents.y, extents.z, 0)
    -- Offset because it is clipped before the near clip for some reason.
    local clipOffset = 3
    -- I would expect the near to be the same even if the camera is different, and it is.
    local limitScale = math.max(distance - (cameraData.nearPlaneDistance + clipOffset), cameraData.nearPlaneDistance) / math.max(halfLength, math.fepsilon)
    self.logger:debug("halfLength %f, limitScale %f (%f)", halfLength, limitScale, limitScale / self.baseScale)
    self.zoomMax = limitScale -- relative scale, apply base scale after
    --self.zoomMax = math.max(limitScale / self.baseScale, 1)
    -- self.zoomMax = 2

    -- local ref = tes3.createReference({ object = object, position = tes3vector3.new(0,0,0), orientation = tes3vector3.new(0,0,0) })
    -- local light = niPointLight.new()
    -- light:setAttenuationForRadius(256)
    -- light.diffuse = niColor.new(1,1,1)
    -- light.ambient = niColor.new(0,0,0)
    -- light.dimmer = 1
    -- local l = tes3.player:getOrCreateAttachedDynamicLight(light)
    -- self.root:attachChild(l.light)

    cameraRoot:attachChild(root)
    cameraRoot:update()
    cameraRoot:updateEffects()

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
        local camera = GetCamera(self.lighting)
        if camera then
            local cameraRoot = camera.cameraRoot
            cameraRoot:detachChild(self.root)
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
    self.pivot = nil
    self.root = nil
    self.original = nil
    self.originalBounds = nil
    self.another = nil
    self.anotherBounds = nil
    self.anotherData = nil
    self.object = nil
end

---@param self Inspector
function this.Reset(self)
    self.pivot = nil
    self.root = nil
    self.original = nil
    self.another = nil
    self.anotherData = nil
    self.object = nil
    self.lighting = settings.lightingType.Default
end

return this
