local this = {}

local decalTextures = {
    ["textures\\tr\\tr_decal_blood_04.dds"] = true,
    ["textures\\tr\\tr_decal_blood_05.dds"] = true,
    ["textures\\tr\\tr_decal_blood_06.dds"] = true,
    ["textures\\tr\\tr_decal_blood_03.dds"] = true,
    ["textures\\tr\\tr_decal_blood_07.dds"] = true,
    ["textures\\tr\\tr_decal_blood_08.dds"] = true,
    ["textures\\tr\\tr_decal_blood_12.dds"] = true,
    ["textures\\tr\\tr_decal_blood_10.dds"] = true,
    ["textures\\tr\\tr_decal_blood_11.dds"] = true,
}

for k in pairs(decalTextures) do
    decalTextures[k] = niSourceTexture.createFromPath(k)
    decalTextures[k].name = " Bleeding Injuries, by Spammer, path : [" .. k .. "]"
end

---@param sceneNode niNode
function this.addDecal(sceneNode)
    for node in table.traverse { sceneNode } do
        if node:isInstanceOfType(tes3.niType.NiTriShape) then
            local alphaProperty = node:getProperty(0x0)
            local texturingProperty = node:getProperty(0x4)
            if (alphaProperty == nil
                    and texturingProperty ~= nil
                    and texturingProperty.canAddDecal == true)
            then
                -- we have to detach/clone the property
                -- because it could have multiple users
                texturingProperty = node:detachProperty(0x4):clone()
                texturingProperty:addDecalMap(table.choice(decalTextures))
                node:attachProperty(texturingProperty)
                node:updateProperties()
                node:updateEffects()
            end
        end
    end
end


return this
