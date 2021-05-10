--[[
	Mod: Skinswapper
	Author: Bahamut
    Version: 0.1
]]--

local function getBodyTexture(ref)
    local race = ref.baseObject.race

    local bodyPartChestPath = (ref.baseObject.female and race.femaleBody.chest.mesh) or race.maleBody.chest.mesh
    local mesh = tes3.loadMesh(bodyPartChestPath)

    local triChest = mesh:getObjectByName("Tri Chest 0")
    if not triChest then
        triChest = mesh:getObjectByName("Tri Chest")
    end

    return triChest:getProperty(4)
end

local function swapBodyTexture(bodyPartNode,texture,ref)
    for _, bodyTriShape in pairs(bodyPartNode.children) do
        local material = bodyTriShape:getProperty(2)
        if material.name == "SkinSwap" then
            if not texture then
                texture = getBodyTexture(ref)
            end

            if texture then
                bodyTriShape:detachProperty(4)
                bodyTriShape:attachProperty(texture)
            end
        end
    end
end

local function getBodyTextureFP(ref)
    local race = ref.baseObject.race
    local handsId = (ref.baseObject.female and race.femaleBody.hands.id) or race.maleBody.hands.id
    handsId = string.format("%s%s", handsId, ".1st");

    handsFp = tes3.getObject(handsId)

    if handsFp then
        mwse.log(handsFp.mesh)
    end
end

local function swapBodyTextureFirstPerson(firstPersonNodeRoot, ref)
    local texture = nil;
    for _, bodyPartNode in pairs(firstPersonNodeRoot.children) do
        mwse.log(bodyPartNode.name)
        if not bodyPartNode.name == "Bip01" then
            for _, bodyTriShape in pairs(bodyPartNode.children) do
                local material = bodyTriShape:getProperty(2)
                if material then
                    if not texture then
                        texture = getBodyTextureFP(ref)
                    end

                    if texture then
                        bodyTriShape:detachProperty(4)
                        bodyTriShape:attachProperty(texture)
                    end
                end
            end
        end
    end
end

local function swapSkin(e)
    local ref = e.reference
    if ref.baseObject.objectType ~= tes3.objectType.npc then
        return
    end

    local texture = nil;

    for _, bodyPartNode in pairs(ref.sceneNode.children) do
        if not (bodyPartNode.name == "MRT" or bodyPartNode.name == "Bip01") then
            if bodyPartNode.name == "ModelRoot" then
				--doesent seem to work
                --swapBodyTextureFirstPerson(bodyPartNode, ref)
            else
                swapBodyTexture(bodyPartNode,texture, ref)
            end
        end
    end
end

event.register("bodyPartsUpdated", swapSkin)
event.register("mobileActivated", swapSkin)