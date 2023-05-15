local interop = {}

interop.data = require("sb_tatau.data")
interop.slots = interop.data.slots

---Register a new wearable.
---@param tattoo tattoo
---@return string
function interop:register(tattoo)
    self.data.tattooProps[tattoo.id] = {
        id     = tattoo.id,
        slot   = tattoo.slot,
        mPaths = tattoo.mPaths,
        fPaths = tattoo.fPaths,
    }
    return tattoo.id
end

function interop:registerAll()
    pcall(function()
        mwse.log("[Tatau - Layered Tattoos]:")
        ---@param k string
        ---@param v tattoo
        for k, v in pairs(self.data.tattooProps) do
            self.data.tattoos[k] = { ["m"] = {},["f"] = {} }
            for race, path in pairs(v.mPaths) do
                self.data.tattoos[k]["m"][race] = niSourceTexture.createFromPath("textures\\" .. path)
                self.data.tattoos[k]["m"][race].name = (v.id .. "_" .. v.slot)
            end
            for race, path in pairs(v.fPaths) do
                self.data.tattoos[k]["f"][race] = niSourceTexture.createFromPath("textures\\" .. path)
                self.data.tattoos[k]["f"][race].name = (v.id .. "_" .. v.slot)
            end
            mwse.log("    - Registered tattoo: \"%s\" as \"%s\" on slot \"%s\"", k, (v.id .. "_" .. v.slot),
                self.data.tattooSlots[v.slot][1])
        end
    end)
end

---@param child niNode
local function childLoop(child)
    if (child.children) then
        ---@param ch niNode
        for _, ch in ipairs(child.children) do
            if (ch) then
                if (ch.texturingProperty) then
                    ch.texturingProperty = ch.texturingProperty:clone()
                end
                childLoop(ch)
            end
        end
    end
end

---@param ref tes3reference
function interop:prepare(ref)
    childLoop(ref.sceneNode)
    ref.sceneNode:updateProperties()
end

--- --- ---

---@param node niNode
---@param tattooTexture niSourceTexture
---@return boolean
local function setDecal(node, tattooTexture)
    local success = false
    for _, value in ipairs(node.children) do
        if (value.name == "Bip01") then
            for _, value2 in ipairs(value.children) do
                if (value2.texturingProperty) then
                    if (value2.texturingProperty.canAddDecal) then
                        local isPresent = false
                        for _, t in ipairs(value2.texturingProperty.maps) do
                            if (t and t.texture and t.texture.name == tattooTexture.name) then
                                isPresent = true
                                break
                            end
                        end
                        if (isPresent == false) then
                            value2.texturingProperty:addDecalMap(tattooTexture)
                            success = true
                        end
                    end
                    break
                end
            end
        elseif (value.texturingProperty) then
            if (value.texturingProperty.canAddDecal) then
                local isPresent = false
                for _, t in ipairs(value.texturingProperty.maps) do
                    if (t and t.texture and t.texture.name == tattooTexture.name) then
                        isPresent = true
                        break
                    end
                end
                if (isPresent == false) then
                    value.texturingProperty:addDecalMap(tattooTexture)
                    success = true
                end
            end
            break
        end
    end
    node:updateProperties()
    return success
end

---@param node niNode
---@param tattooTexture niSourceTexture
---@return boolean
local function remDecal(node, tattooTexture)
    local success = false
    for _, value in ipairs(node.children) do
        if (value.name == "Bip01") then
            for _, value2 in ipairs(value.children) do
                if (value2.texturingProperty) then
                    if (value2.texturingProperty.canAddDecal) then
                        for i, t in ipairs(value2.texturingProperty.maps) do
                            if (t and t.texture and t.texture.name == tattooTexture.name) then
                                value2.texturingProperty:removeDecalMap(i)
                                success = true
                                break
                            end
                        end
                    end
                    break
                end
            end
        elseif (value.texturingProperty) then
            if (value.texturingProperty.canAddDecal) then
                for i, t in ipairs(value.texturingProperty.maps) do
                    if (t and t.texture and t.texture.name == tattooTexture.name) then
                        value.texturingProperty:removeDecalMap(i)
                        success = true
                        break
                    end
                end
            end
            break
        end
    end
    node:updateProperties()
    return success
end

---@param node niNode
---@param tattooTexture niSourceTexture
---@return boolean
local function togDecal(node, tattooTexture)
    local success = false
    for _, value in ipairs(node.children) do
        if (value.name == "Bip01") then
            for _, value2 in ipairs(value.children) do
                if (value2.texturingProperty) then
                    if (value2.texturingProperty.canAddDecal) then
                        local isPresent = false
                        for i, t in ipairs(value2.texturingProperty.maps) do
                            if (t and t.texture and t.texture.name == tattooTexture.name) then
                                isPresent = true
                                value2.texturingProperty:removeDecalMap(i)
                                success = true
                                break
                            end
                        end
                        if (isPresent == false) then
                            value2.texturingProperty:addDecalMap(tattooTexture)
                            success = true
                        end
                    end
                    break
                end
            end
        elseif (value.texturingProperty) then
            if (value.texturingProperty.canAddDecal) then
                local isPresent = false
                for i, t in ipairs(value.texturingProperty.maps) do
                    if (t and t.texture and t.texture.name == tattooTexture.name) then
                        isPresent = true
                        value.texturingProperty:removeDecalMap(i)
                        success = true
                        break
                    end
                end
                if (isPresent == false) then
                    value.texturingProperty:addDecalMap(tattooTexture)
                    success = true
                end
            end
            break
        end
    end
    node:updateProperties()
    return success
end

---@param ref tes3reference
---@param tattooID string
---@return boolean
function interop:applyTattoo(ref, tattooID)
    local tattooProp = self.data.tattooProps[tattooID]
    local tattooObj = self.data.tattoos[tattooID]
    local bodyNode = ref.bodyPartManager:getActiveBodyPart(tes3.activeBodyPartLayer.base,
        self.data.tattooSlots[tattooProp.slot][2]).node
    if (bodyNode) then
        if (ref.baseObject.female and tattooObj["f"]) then
            return setDecal(bodyNode,
                (tattooObj["f"][ref.object.race.id] or tattooObj["f"][""] or tattooObj["m"][ref.object.race.id] or tattooObj["m"][""]))
        else
            return setDecal(bodyNode, tattooObj["m"][ref.object.race.id] or tattooObj["m"][""])
        end
    else
        return false
    end
end

---@param ref tes3reference
---@param tattooID string
---@return boolean
function interop:removeTattoo(ref, tattooID)
    local tattooProp = self.data.tattooProps[tattooID]
    local tattooObj = self.data.tattoos[tattooID]
    local bodyNode = ref.bodyPartManager:getActiveBodyPart(tes3.activeBodyPartLayer.base,
        self.data.tattooSlots[tattooProp.slot][2]).node
    if (bodyNode) then
        if (ref.baseObject.female and tattooObj["f"]) then
            return remDecal(bodyNode,
                (tattooObj["f"][ref.object.race.id] or tattooObj["f"][""] or tattooObj["m"][ref.object.race.id] or tattooObj["m"][""]))
        else
            return remDecal(bodyNode, tattooObj["m"][ref.object.race.id] or tattooObj["m"][""])
        end
    else
        return false
    end
end

---@param ref tes3reference
---@param tattooID string
---@return boolean
function interop:toggleTattoo(ref, tattooID)
    local tattooProp = self.data.tattooProps[tattooID]
    local tattooObj = self.data.tattoos[tattooID]
    local bodyNode = ref.bodyPartManager:getActiveBodyPart(tes3.activeBodyPartLayer.base,
        self.data.tattooSlots[tattooProp.slot][2]).node
    if (bodyNode) then
        if (ref.baseObject.female and tattooObj["f"]) then
            return togDecal(bodyNode,
                (tattooObj["f"][ref.object.race.id] or tattooObj["f"][""] or tattooObj["m"][ref.object.race.id] or tattooObj["m"][""]))
        else
            return togDecal(bodyNode, tattooObj["m"][ref.object.race.id] or tattooObj["m"][""])
        end
    else
        return false
    end
end

--- --- ---

return interop
