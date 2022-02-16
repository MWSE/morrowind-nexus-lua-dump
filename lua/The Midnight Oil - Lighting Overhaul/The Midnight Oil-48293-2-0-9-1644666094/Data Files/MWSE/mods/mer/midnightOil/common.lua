local this = {}
local conf = require("mer.midnightOil.config")
this.merchantContainers = {
    ["ra'virr"] = "mer_lntrn_merch",
    ["arrille"] = "mer_lntrn_merch",
    ["mebestian ence"] = "mer_lntrn_merch",
    ["alveno andules"] = "mer_lntrn_merch",
    ["dralasa nithryon"] = "mer_lntrn_merch",
    ["galtis guvron"] = "mer_lntrn_merch",
    ["goldyn belaram"] = "mer_lntrn_merch",
    ["irgola"] = "mer_lntrn_merch",
    ["clagius clanler"] = "mer_lntrn_merch",
    ["fadase selvayn"] = "mer_lntrn_merch",
    ["naspis apinia"] = "mer_lntrn_merch",
    ["tiras sadus"] = "mer_lntrn_merch",
    ["thongar"] = "mer_lntrn_merch",
    ["heifnir"] = "mer_lntrn_merch",
    ["berwen"] = "mer_lntrn_merch",
}

this.merchantClassContainers = {
    t_sky_publican = "mer_lntrn_merch",
    t_cyr_publican = "mer_lntrn_merch",
    publican = "mer_lntrn_merch",
    pawnbroker = "mer_lntrn_merch",
}

this.oil = {
    ["mer_lntrn_flask"] = true
}

this.candle = {
    ["mer_lntrn_candle"] = true
}

this.oilSource = {
    ["terrain_ashmire_02"] = true
}

this.lightPatterns = {
    "candle",
    "lantern",
    "lamp",
    "chandelier",
    "sconce",
    "streetlight",
    "torch",
    "light_spear_skull",
    "t_de_var_swimlant",
    "ab_light_delant",
    "ab_light_cavelantern",
    "ab_light_comsconsilv",
}

this.candlePatterns = {
    "candle",
    "lantern"
}

this.oilLanterns = {
    --lamps
    ["light_com_redware_lamp"] = true,
    ["light_de_buglamp_01"] = true,
    ["light_de_buglamp_01_64"] = true,
    ["light_de_buglamp_01_off"] = true,
}

this.blacklist = {}
function this.isBlacklisted(obj)
    return this.blacklist[obj.id:lower()]
end

function this.modActive()
    return conf.getConfig().enabled == true
end

function this.wasToggledToday(reference)
    return (
        reference.data and
        reference.data.dayLightManuallyToggled and
        reference.data.dayLightManuallyToggled >= tes3.worldController.daysPassed.value
    )
end

function this.setToggledDay(reference)
    reference.data.dayLightManuallyToggled = tes3.worldController.daysPassed.value
end

function this.isSwitchable(obj)
    if this.isBlacklisted(obj) then return end
    for _, pattern in ipairs(this.lightPatterns) do
        if string.find(obj.id:lower(), pattern) then
            return true
        end
    end
    return false
end

function this.isOilSource(obj)
    if this.isBlacklisted(obj) then return end
    obj = obj.baseObject or obj
    return this.oilSource[obj.id:lower()]
end

function this.isOil(obj)
    if this.isBlacklisted(obj) then return end
    obj = obj.baseObject or obj
    return this.oil[obj.id:lower()]
end

function this.isCandleLantern(obj)
    if this.isBlacklisted(obj) then return end
    if this.isCarryableLight(obj) then
        for _, pattern in ipairs(this.candlePatterns) do
            if string.find(obj.id:lower(), pattern) then
                return true
            end
        end
    end
    return false
end

function this.isCandle(obj)
    if this.isBlacklisted(obj) then return end
    obj = obj.baseObject or obj
    return this.candle[obj.id:lower()]
end

--Is an oil lantern
function this.isOilLantern(obj)
    if this.isBlacklisted(obj) then return end
    obj = obj.baseObject or obj

    local isOilLantern = (
        obj.objectType == tes3.objectType.light and
        this.oilLanterns[obj.id:lower()] == true
    )
    return isOilLantern
end

--is a carryable light
function this.isCarryableLight(obj)
    if this.isBlacklisted(obj) then
        return false
    end
    if this.blacklist[obj.id:lower()] then
        return false
    end
    return obj.objectType == tes3.objectType.light and obj.canCarry
end

function this.isLight(obj)
    if this.isBlacklisted(obj) then return end
    return  this.isCandleLantern(obj)
end

local function traverse(roots)
    local function iter(nodes)
        for _, node in ipairs(nodes or roots) do
            if node then
                coroutine.yield(node)
                if node.children then
                    iter(node.children)
                end
            end
        end
    end
    return coroutine.wrap(iter)
end

function this.removeLight(ref)
    ref:deleteDynamicLightAttachment()
    tes3.removeSound{reference=ref}
    local lightNode = ref.sceneNode
    for node in traverse{lightNode} do
        --Kill particles
        if node.RTTI.name == "NiBSParticleNode" then
            node.appCulled = true
        end
        --Kill Melchior's Lantern glow effect
        if node.name == "LightEffectSwitch" or node.name == "Glow" then
            node.appCulled = true
        end

        -- Kill materialProperty
        local materialProperty = node:getProperty(0x2)
        if materialProperty then
            if (materialProperty.emissive.r > 1e-5 or materialProperty.emissive.g > 1e-5 or materialProperty.emissive.b > 1e-5 or materialProperty.controller) then
                materialProperty = node:detachProperty(0x2):clone()
                node:attachProperty(materialProperty)

                -- Kill controllers
                materialProperty:removeAllControllers()

                -- Kill emissives
                local emissive = materialProperty.emissive
                emissive.r, emissive.g, emissive.b = 0,0,0
                materialProperty.emissive = emissive

                node:updateProperties()
            end
        end
     -- Kill glowmaps
        local texturingProperty = node:getProperty(0x4)
        local newTextureFilepath = "Textures\\tx_black_01.dds"
        if (texturingProperty and texturingProperty.maps[4]) then
        texturingProperty.maps[4].texture = niSourceTexture.createFromPath(newTextureFilepath)
        end
        if (texturingProperty and texturingProperty.maps[5]) then
            texturingProperty.maps[5].texture = niSourceTexture.createFromPath(newTextureFilepath)
        end
    end
    ref.sceneNode:update()
    ref.sceneNode:updateNodeEffects()
    ref.data.lightTurnedOff = true
    ref.modified = true
end

local function isCollisionNode(node)
    return node:isInstanceOfType(tes3.niType.RootCollisionNode)
end

function this.onLight(lightRef)
    lightRef.data.lightTurnedOff = false
    lightRef.modified = true
    if (not lightRef.object.mesh) or (string.len(lightRef.object.mesh) == 0) then
        return
    end
    local newNode = tes3.loadMesh(lightRef.object.mesh):clone()

    --[[
        Remove existing children and reattach them from the base mesh,
        to restore light properties. Ignore collision node to avoid
        crashes from collision detection.
    ]]
    for i, childNode in ipairs(lightRef.sceneNode.children) do
        if childNode and not isCollisionNode(childNode) then
            lightRef.sceneNode:detachChildAt(i)
        end
    end
    for i, childNode in ipairs(newNode.children) do
        if childNode and not isCollisionNode(childNode) then
            lightRef.sceneNode:attachChild(newNode.children[i], true)
        end
    end
    local lightNode = niPointLight.new()
    lightNode.name = "LIGHTNODE"
    if lightRef.object.color then
        lightNode.ambient = tes3vector3.new(0,0,0)
        lightNode.diffuse = tes3vector3.new(
            lightRef.object.color[1] / 255,
            lightRef.object.color[2] / 255,
            lightRef.object.color[3] / 255
        )
    else
        lightNode.ambient = tes3vector3.new(0,0,0)
        lightNode.diffuse = tes3vector3.new(255, 255, 255)
    end
    lightNode:setAttenuationForRadius(lightRef.object.radius)
    --see if there's an attachlight node to work with
    local attachLight = lightRef.sceneNode:getObjectByName("attachLight")
    local windowsGlowAttach = lightRef.sceneNode:getObjectByName("NightDaySwitch")
    attachLight = attachLight or windowsGlowAttach or lightRef.sceneNode
    attachLight:attachChild(lightNode)

    lightRef.sceneNode:update()
    lightRef.sceneNode:updateNodeEffects()
    lightRef:getOrCreateAttachedDynamicLight(lightNode, 1.0)
end



return this