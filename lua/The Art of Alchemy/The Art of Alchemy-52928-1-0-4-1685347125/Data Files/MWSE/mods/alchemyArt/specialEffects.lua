local this = {}

this.alchemySuccess = function(reference, alchemy)
    local spell = tes3.createObject{id="AA_AlchemySuccess", objectType=tes3.objectType.spell}
    for i, effect in ipairs(spell.effects) do
        spell.effects[i] = alchemy.effects[i]
    end
    tes3.cast{reference = reference, spell=spell, target = reference}
end

local mortarPestleMeshes = {
    ["m\\misc_mortarpestle_a_01.nif"] = {
        mortar = "AA\\AA_app_A_mortar.nif",
        pestle = "AA\\AA_app_A_pestle.nif"
    },
    ["m\\misc_mortarpestle_01.nif"] = {
        mortar = "AA\\AA_app_J_Mortar.nif",
        pestle = "AA\\AA_app_J_Pestle.nif"
    },
    ["m\\misc_mortarpestle_m_01.nif"] = {
        mortar = "AA\\AA_app_M_Mortar.nif",
        pestle = "AA\\AA_app_M_Pestle.nif"
    },
    ["m\\misc_mortarpestle_g_01.nif"] = {
        mortar = "AA\\AA_app_G_Mortar.nif",
        pestle = "AA\\AA_app_G_Pestle.nif"
    },
    ["m\\misc_mortarpestle_s_01.nif"] = {
        mortar = "AA\\AA_app_S_Mortar.nif",
        pestle = "AA\\AA_app_S_Pestle.nif"
    },
}

this.mortarAnimationBegin = function(reference)
    --reference:disable()
    tes3.setVanityMode{toogle = true, checkVanityDisabled = false}
    --tes3.setPlayerControlState()
    local mesh = string.lower(reference.object.mesh)
    local mortarMesh = mortarPestleMeshes[mesh] and mortarPestleMeshes[mesh].mortar or mesh
    local pestleMesh = mortarPestleMeshes[mesh] and mortarPestleMeshes[mesh].pestle or nil
    tes3.loadAnimation{reference = tes3.player, file = "am\\AM_Alchemist.nif"}
	tes3.playAnimation({ reference = tes3.player, group = tes3.animationGroup.idle9})
	local node = tes3.loadMesh(mortarMesh)
	node = node:clone()
    node.name = "AA_MortarNode"
	node.scale = 0.7
    local coords = {24, 0, -1.5}
    if mesh == "m\\misc_mortarpestle_a_01.nif" then
        coords[3] = coords[3] + 4
    elseif mesh == "m\\misc_mortarpestle_01.nif" then
        coords[3] = coords[3] + 4.5
    elseif mesh == "m\\misc_mortarpestle_s_01.nif" then
        coords[3] = coords[3] - 2
    end
	node.translation = tes3vector3.new(table.unpack(coords))
	-- mwse.log(node.rotation)
	local rotation = {15, 15, 135}
    node.rotation = tes3matrix33.new()
    node.rotation:fromEulerXYZ((rotation[1]) / 180 * 3.14, (rotation[2]) / 180 * 3.14, (rotation[3]) / 180 * 3.14)
	-- mwse.log(node.rotation)
	local sceneNode = tes3.player.sceneNode
	local rightHand = sceneNode:getObjectByName("Bip01 R Hand")
	local parent = rightHand.parent
	parent:attachChild(node, true)
	parent:update()
	parent:updateEffects()
    if pestleMesh then
        node = tes3.loadMesh(pestleMesh)
        node = node:clone()
        node.name = "AA_PestleNode"
        node.scale = 0.7
        local coords = {24, -3, 0}
        node.translation = tes3vector3.new(table.unpack(coords))
        local rotation = {15, 105, -25}
        node.rotation = tes3matrix33.new()
        node.rotation:fromEulerXYZ((rotation[1]) / 180 * 3.14, (rotation[2]) / 180 * 3.14, (rotation[3]) / 180 * 3.14)
        local sceneNode = tes3.player.sceneNode
        local leftHand = sceneNode:getObjectByName("Bip01 L Hand")
        local parent = leftHand.parent
        parent:attachChild(node, true)
        parent:updateEffects()
    end
end

this.mortarAnimationEnd = function(reference)
    reference:enable()
    tes3.loadAnimation{reference = tes3.player}
	tes3.playAnimation{ reference = tes3.player, group = tes3.animationGroup.idle}
    tes3.setVanityMode{toggle = true, checkVanityDisabled = false}
    --tes3.setPlayerControlState{enable = true}

    local sceneNode = tes3.player.sceneNode
	local rightHand = sceneNode:getObjectByName("Bip01 R Hand")
	local parent = rightHand.parent

    local node = parent:getObjectByName("AA_MortarNode")
    if node then
        parent:detachChild(node)
    end

	parent:update()
	parent:updateEffects()
end

local apparatusFireId = "Light_Fire"

this.addCalcinatorFire = function(reference)
    local position = reference.position
    tes3.createReference{object = apparatusFireId, position = position, orientation = reference.orientation, scale = 0.5, cell = reference.cell}
end

this.removeCalcinatorFire = function(reference)
    local position = reference.position:copy()
    for ref in reference.cell:iterateReferences(tes3.objectType.light) do
        if ref.id == apparatusFireId then
            if ref.position.x == position.x and ref.position.y == position.y and ref.position.z == position.z then
                ref:disable()
                ref:delete()
                break
            end
        end
    end
end

this.addRetortFire = function(reference)
    local position = reference.position:copy()
    position.z = position.z - 4
    tes3.createReference{object = apparatusFireId, position = position, orientation = reference.orientation, scale = 0.3, cell = reference.cell}
end

this.removeRetortFire = function(reference)
    local position = reference.position:copy()
    position.z = position.z - 4
    for ref in reference.cell:iterateReferences(tes3.objectType.light) do
        if ref.id == apparatusFireId then
            if ref.position.x == position.x and ref.position.y == position.y and ref.position.z == position.z then
                ref:disable()
                ref:delete()
                break
            end
        end
    end
end

return this