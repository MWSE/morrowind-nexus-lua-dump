local effects = {}
effects.fire = {}
effects.frost = {}
effects.lightning = {}

effects.fire.hit = { 
    vfx = 'VFX_DestructHit',
    mesh = 'kurp\\s\\a\\fire_zap.nif',
    node = nil,
    sound = 'destruction hit' 
}

effects.fire.shield = {
    vfx = 'VFX_DestructHit',
    mesh = 'kurp\\s\\a\\fire_crack.nif',
    node = nil,
    sound = nil 
}

effects.frost.hit = { 
    vfx = 'VFX_FrostHit',
    mesh = 'kurp\\s\\a\\frost_zap.nif',
    node = nil,
    sound = 'frost_hit' 
}

effects.frost.shield = {
    vfx = 'VFX_FrostHit',
    mesh = 'kurp\\s\\a\\frost_crack.nif',
    node = nil,
    sound = nil 
}

effects.lightning.hit = { 
    vfx = 'VFX_LightningHit',
    mesh = 'kurp\\s\\a\\shock_zap.nif',
    node = nil,
    sound = 'shock hit' 
}

effects.lightning.shield = {
    vfx = 'VFX_LightningHit',
    mesh = 'kurp\\s\\a\\shock_crack.nif',
    node = nil,
    sound = nil 
}

local function PlayEffects(reference, effect)
    local scene_node = reference.sceneNode
    local node = scene_node:getObjectByName(effect.vfx)

    if not node then
        if not effect.node then
            effect.node = tes3.loadMesh(effect.mesh)
        end
        node = effect.node:clone()
        if reference.object.race and reference.object.race.weight and reference.object.race.height then
            local height, weight
            if reference.object.female then
                weight = reference.object.race.weight.female
                height = reference.object.race.height.female
            else
                weight = reference.object.race.weight.male
                height = reference.object.race.height.male
            end

            local weightMod = 1 / weight
            local heightMod = 1 / height

            local r = node.rotation
            local s = tes3vector3.new(weightMod, weightMod, heightMod)
            node.rotation = tes3matrix33.new(r.x * s, r.y * s, r.z * s)
        end

        scene_node:attachChild(node, true)
        node:update({controllers=true})
        node:updateNodeEffects()
    end

    node.appCulled = false
    timer.start({ 
        iterations = 1, 
        duration = 3,
        type = timer.simulate,
        callback = function ()
            node.appCulled = true
        end
    })

    if effect.sound then
        tes3.playSound({ sound = effect.sound, reference = reference })
    end

end

local function OnShieldDamage(e)
    if e.source == 'shield' then
        local attacker = e.attacker.reference
        local target = e.reference
        local effect = e.activeMagicEffect
        local element = ''
        
        if effect.effectId == tes3.effect.fireShield then
            element = 'fire'
            PlayEffects(target, effects.fire.hit)
            PlayEffects(attacker, effects.fire.shield)
        elseif effect.effectId == tes3.effect.frostShield then
            element = 'frost'
            PlayEffects(target, effects.frost.hit)
            PlayEffects(attacker, effects.frost.shield)
        elseif effect.effectId == tes3.effect.lightningShield then
            element = 'lightning'
            PlayEffects(target, effects.lightning.hit)
            PlayEffects(attacker, effects.lightning.shield)
        end

        mwse.log(target.id .. ' was hit by ' .. attacker.id .. "'s " .. element .. ' shield.')

    end
end

event.register('damaged', OnShieldDamage)