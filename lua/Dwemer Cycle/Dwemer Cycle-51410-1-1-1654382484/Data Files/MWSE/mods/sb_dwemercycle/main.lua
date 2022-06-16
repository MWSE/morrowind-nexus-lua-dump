local zero = require("sb_dwemercycle.zero")
local helmet = require("sb_dwemercycle.helmet")
local effects = require("sb_dwemercycle.effects")
local compass = require("sb_dwemercycle.compass")
local achievements = require("sb_dwemercycle.achievements")
local utils = require("sb_dwemercycle.utils")
local ui = require("sb_dwemercycle.ui")
local mcm = require("sb_dwemercycle.mcm")
local m = --[[627.2 / 9.8]] 69.99125109

mcm.init()

local animTogglePlayer = 0
local animToggleCycle = 0
local collisionCheck = false

local function animToggle(reference, toggle)
    if (reference == zero.getReference()) then
        if (animToggleCycle ~= toggle) then
            --print(zero.getReference().object.id)
            --print(toggle)
            tes3.cancelAnimationLoop { reference = zero.getReference() }
            tes3.playAnimation { reference = zero.getReference(), group = toggle == 1 and tes3.animationGroup.walkForward or tes3.animationGroup.idle, loopCount = -1 }
            --tes3.playAnimation{ reference = tes3.mobilePlayer.firstPersonReference, group = --[[toggle == 1 and tes3.animationGroup.walkForward or]] tes3.animationGroup.idle, loopCount = -1 }
            animToggleCycle = toggle
        end
    elseif (reference == tes3.player) then
        if (animTogglePlayer ~= toggle) then
            --print(tes3.player.object.id)
            --print(toggle)
            tes3.cancelAnimationLoop { reference = tes3.player }
            tes3.cancelAnimationLoop { reference = tes3.mobilePlayer.firstPersonReference }
            tes3.playAnimation { reference = tes3.player, group = toggle == 1 and tes3.animationGroup.walkForward or tes3.animationGroup.idle, loopCount = -1 }
            tes3.playAnimation { reference = tes3.mobilePlayer.firstPersonReference, group = toggle == 1 and tes3.animationGroup.walkForward or tes3.animationGroup.idle, loopCount = -1 }
            animTogglePlayer = toggle
        end
    end
end

local function activateCallback(e)
    if (--[[e.activator == tes3.player and]] e.target == zero.getReference()) then
        if (zero.isMounted() == nil) then
            zero.initMount()
            ui.showBars()
            ui.updateIcon1(zero.getGear())
            ui.updateIcon2(zero.getLightOnOff())
        else
            zero.toggleMount(m)
            ui.toggleBars(zero.isMounted())
            ui.updateIcon1(zero.getGear())
            ui.updateIcon2(zero.getLightOnOff())
        end
    end
end

local function simulateCallback(e)
    if (zero.getReference() and zero.getReference().sceneNode and zero.getMobile() and zero.isMounted() ~= nil) then
        if (tes3.mobilePlayer.inJail and zero.isMounted()) then
            zero.toggleMount(m, true)
        end
        if (zero.getMobile().position.z) then
            local waterLevel = zero.getMobile().cell.isInterior == false and 0 or (zero.getMobile().cell.hasWater and zero.getMobile().cell.waterLevel or nil)
            if (waterLevel) then
                if (zero.getMobile().position.z < waterLevel - 64) then
                    if (tes3.getSoundPlaying { sound = "Machinery", reference = zero.getReference() }) then
                        tes3.removeSound { sound = "Machinery", reference = zero.getReference() }
                    end
                    zero.destroy(m)
                    return
                elseif (zero.getMobile().position.z < waterLevel) then
                    if (tes3.getSoundPlaying { sound = "Machinery", reference = zero.getReference() } == false) then
                        tes3.playSound { sound = "Machinery", reference = zero.getReference(), loop = true, volume = 0.75 }
                    end
                    tes3.adjustSoundVolume { sound = "Machinery", reference = zero.getReference(), volume = ((waterLevel - zero.getMobile().position.z) / 64) * 0.75 }
                else
                    if (tes3.getSoundPlaying { sound = "Machinery", reference = zero.getReference() }) then
                        tes3.removeSound { sound = "Machinery", reference = zero.getReference() }
                    end
                end
            end
        end
        local vel = 0
        zero.applyDrag(zero.getGear(), e.delta, m)
        if (zero.isMounted() == true) then
            tes3.mobilePlayer.position = zero.getMobile().position
            zero.getReference().sceneNode.rotation = tes3.player.sceneNode.rotation
            --zero.getReference().orientation = tes3vector3.new(0, 0, tes3.getPlayerEyeVector().y)
            if ((utils.getKeyHold(tes3.keybind.forward) or tes3.mobilePlayer.autoRun) and collisionCheck == false) then
                zero.applyAcc(zero.getGear(), e.delta, m)
            end
            if (utils.getKeyHold(tes3.keybind.back)) then
                zero.applyBrake(e.delta, m)
            end
            if (utils.getKeyPress(tes3.keybind.readyMagic)) then
                zero.toggleLight()
                ui.updateIcon2(zero.getLightOnOff())
            end
            --if (utils.getKeyPress(tes3.keybind.jump) and (zero.getMobile().isFalling == false and zero.getMobile().isJumping == false)) then
            --    zero.getMobile().velocity.z = 128
            --end
            if (utils.getKeyPress(tes3.keybind.run)) then
                zero.increaseGear()
                ui.updateIcon1(zero.getGear())
            elseif (utils.getKeyPress(tes3.keybind.sneak)) then
                zero.decreaseGear()
                ui.updateIcon1(zero.getGear())
            end
            tes3.mobilePlayer.weaponReady = false
            tes3.mobilePlayer.castReady = false
            tes3.mobilePlayer.isRunning = false
            tes3.mobilePlayer.isSneaking = false
            --local playerFirstPersonNode = tes3.mobilePlayer.firstPersonReference.sceneNode
            --local nodeRot = playerFirstPersonNode.rotation:invert()
            --nodeRot:fromEulerXYZ(nodeRot:toEulerXYZ().x, 0, 0)
            --playerFirstPersonNode.children[1].rotation = nodeRot
            --print("Gear : " .. tostring(zero.getReference().data["gear"]))
            --print((tes3.mobilePlayer.forceRun and "Run : " or "Walk : ") .. tostring(tes3.mobilePlayer.forceRun))
            --print((tes3.mobilePlayer.alwaysRun and "Run : " or "Walk : ") .. tostring(tes3.mobilePlayer.alwaysRun))
            --print((tes3.mobilePlayer.autoRun and "Run : " or "Walk : ") .. tostring(tes3.mobilePlayer.autoRun))
            --print((tes3.mobilePlayer.isWalking and "Run : " or "Walk : ") .. tostring(tes3.mobilePlayer.isWalking))
            --print((tes3.mobilePlayer.isRunning and "Run : " or "Walk : ") .. tostring(tes3.mobilePlayer.isRunning))
            --print("Shift : " .. tostring(tes3.worldController.inputController:isKeyReleasedThisFrame(tes3.worldController.inputController.inputMaps[tes3.keybind.run + 1].code)))
            vel = tes3.getPlayerEyeVector()
            vel.z = 0
            vel = vel:normalized() * (zero.getVelKilometers() / m >= 0.16 and zero.getVel() or 0)
        else
            vel = zero.getReference().sceneNode.rotation:transpose().y * (zero.getVelKilometers() / m >= 0.16 and zero.getVel() or 0)
            ui.hideBars()
        end
        if (zero.getReference().sceneNode:getObjectByName(zero.getLight()["headlight"]).enabled ~= zero.getLightOnOff()) then
            local lights = zero.getLight()
            for _, light in pairs(lights) do
                zero.getReference().sceneNode:getObjectByName(light).enabled = zero.getLightOnOff()
            end
        end
        --zero.getMobile().velocity = tes3.player.sceneNode.rotation:transpose().y * zero.getMobile().velocity
        --zero.getMobile().velocity = tes3vector3.new(y.x, y.y, -m)
        zero.getMobile().velocity.x = vel.x * zero.getMobile().speed.normalized
        zero.getMobile().velocity.y = vel.y * zero.getMobile().speed.normalized
        --print(zero.getVel())
        --print(zero.getSpeedLimit(zero.getGear()) * m)
        --print(zero.getVelMiles())
        --print(zero.getSpeedLimitMiles(zero.getGear()) * m)
        ui.updateSpeed(zero.getVelMiles(), zero.getSpeedLimitMiles(3) * m, string.format("%.3f",
                (zero.getVelKilometers() / m >= 0.16 and
                        (mcm.config.units == 1 and zero.milesPerHour(zero.getGear(), m) or zero.kilometersPerHour(zero.getGear(), m))
                        or 0)) ..
                (mcm.config.units == 1 and " mph" or " kph"))
        ui.updateFuel(zero.getMobile().magicka.current, zero.getMobile().magicka.base, string.format("%.3f",
                zero.getMobile().magicka.normalized *
                        (mcm.config.units == 1 and math.round(zero.getSpeedLimitMiles(1)) or zero.getSpeedLimitKilometers(1))) ..
                (mcm.config.units == 1 and " mi/gal" or " km/L"))
        --zero.getMobile().position.z = zero.getMobile().position.z + (-m * e.delta)
        --print(m)
        --print(m*e.delta)
        --print(m/e.delta)
        --print(m*9.8)
        --print(m*9.8*e.delta)
        --print((m*9.8)/e.delta)
        --zero.getReference().position = zero.getReference().position + (tes3vector3.new(y.x, y.y, 0) * e.delta)
        if (zero.getVelKilometers() / m >= 0.16) then
            if (tes3.getSoundPlaying { sound = "forcefield", reference = zero.getReference() } == false) then
                tes3.playSound { sound = "forcefield", reference = zero.getReference(), loop = true, volume = 0.75 }
            end
            tes3.adjustSoundVolume { sound = "forcefield", reference = zero.getReference(), volume = (zero.getVel() / (zero.getSpeedLimit(3) * m)) * 0.75 }
            animToggle(zero.getReference(), 1)
            --tes3.playAnimation({ reference = zero.getReference(), group = tes3.animationGroup.walkForward })
            if (zero.isMounted()) then
                animToggle(tes3.player, zero.getVelKilometers() / m <= 1.6 and -1 or 1)
            end
        else
            if (tes3.getSoundPlaying { sound = "forcefield", reference = zero.getReference() }) then
                tes3.removeSound { sound = "forcefield", reference = zero.getReference() }
            end
            animToggle(zero.getReference(), -1)
            animToggle(tes3.player, -1)
            --tes3.playAnimation({ reference = zero.getReference(), group = tes3.animationGroup.idle })
            --if (zero.isMounted()) then
            --    tes3.playAnimation({ reference = tes3.player, group = tes3.animationGroup.idle })
            --end
        end
        --zero.updateAnimationSpeed(m)
        --tes3.setAnimationTiming{reference = zero.getReference(), timing = (zero.getMobile().velocity.y or 0) / m}
        --print("K : " .. tostring(tes3.getAnimationTiming{ reference = zero.getReference() }[1]))
        --print("  : " .. tostring(tes3.getAnimationTiming{ reference = zero.getReference() }[2]))
        --print("  : " .. tostring(tes3.getAnimationTiming{ reference = zero.getReference() }[3]))
        --print("Q : " .. tostring(tes3.getAnimationTiming{ reference = zero.getReference() }))
        --print(tes3.getAnimationTiming({ reference = zero.getReference() })[1])
        --print(tes3.getAnimationTiming({ reference = zero.getReference() })[2])
        --print(tes3.getAnimationTiming({ reference = zero.getReference() })[3])
        --print("Anim : " .. (zero.getMobile().velocity.y or 0) / m)
    else
        ui.hideBars()
    end
end

local function keyCallback(e)
    if (zero.getReference() and zero.isMounted() and tes3.hasCodePatchFeature(tes3.codePatchFeature.swiftCasting) and e.keyCode == tes3.keybind.readyMagicMCP) then
        return false
    end
end

local function playGroupCallback(e)
    if (zero.getReference() and zero.isMounted() and (e.reference == tes3.player or e.reference == tes3.mobilePlayer.firstPersonReference)) then
        if (e.group ~= tes3.animationGroup.idle and e.group ~= tes3.animationGroup.walkForward) then
            return false
        end
    end
end

local function collisionCallback(e)
    if (e.reference == zero.getReference() and collisionCheck == false) then
        if (e.target and e.target.script and e.target.script.id == "lava") then
            zero.destroy(m)
            return
        end
        if (e.target and (zero.isMounted() == false and e.target == tes3.player or e.target ~= tes3.player) and e.target.mobile) then
            if (zero.getVelKilometers() / m >= 2) then
                local activeEffects = zero.getMobile():getActiveMagicEffects { effect = tes3.effect.fortifyAttack }
                local fullEffect = 0
                ---@param activeEffect tes3activeMagicEffect
                for _, activeEffect in ipairs(activeEffects) do
                    fullEffect = fullEffect + activeEffect.magnitude
                end
                e.target.mobile:applyDamage { damage = ((zero.getVelKilometers() / m) * zero.getMobile().strength.normalized) + (zero.getMobile().strength.normalized * fullEffect), applyArmor = true, applyDifficulty = true, playerAttack = true }
                tes3.playSound { reference = e.target, sound = "Body Fall Medium" }
                if (e.target.mobile.health.current > 0) then
                    if (e.target.mobile.actorType == tes3.actorType.npc) then
                        tes3.triggerCrime { criminal = tes3.mobilePlayer, type = tes3.crimeType.attack, value = 100, victim = e.target.mobile }
                    end
                    tes3.playAnimation { reference = e.target, group = tes3.animationGroup.knockDown }
                    if (zero.isMounted() == false and e.target == tes3.player) then
                        tes3.playAnimation { reference = tes3.player, group = tes3.animationGroup.knockDown }
                        tes3.playAnimation { reference = tes3.mobilePlayer.firstPersonReference, group = tes3.animationGroup.knockDown }
                    end
                elseif (e.target.mobile.actorType == tes3.actorType.npc) then
                    tes3.triggerCrime { criminal = tes3.mobilePlayer, type = tes3.crimeType.killing, value = 1000, victim = e.target.mobile }
                end
            elseif (zero.getVelKilometers() / m > 0) then
                local anim = math.random(1, 5)
                tes3.playSound { reference = e.target, sound = "Body Fall Small" }
                tes3.playAnimation { reference = e.target, group = tes3.animationGroup["hit" .. tostring(anim)] }
                if (zero.isMounted() == false and e.target == tes3.player) then
                    tes3.playAnimation { reference = tes3.player, group = tes3.animationGroup["hit" .. tostring(anim)] }
                    tes3.playAnimation { reference = tes3.mobilePlayer.firstPersonReference, group = tes3.animationGroup["hit" .. tostring(anim)] }
                end
            end
            tes3.mobilePlayer.autoRun = false
            zero.setVel(0)
            collisionCheck = true
            timer.start { type = timer.real, duration = 2, callback = function()
                collisionCheck = false
            end }
        end
    end
end

local function damageCallback(e)
    if (e.reference == zero.getReference()) then
        zero.getMobile().health.base = 5000
        zero.getMobile().health.current = 5000
        return false
    elseif (e.reference == tes3.player and e.mobile.health.current - e.damage <= 0) then
        if (zero.isMounted()) then
            zero.toggleMount(0, true)
        end
    end
end

local function mobileDeactivatedCallback(e)
    if (e.reference == zero.getReference() and zero.getMobile()) then
        zero.getReference().data["state"] = { zero.getMobile().magicka.current, zero.getMobile().magicka.base, zero.getReference().sceneNode.rotation:toEulerXYZ() }
    end
end

local function mobileActivatedCallback(e)
    if (e.reference == zero.getReference() and zero.getReference().data["state"]) then
        zero.getMobile().magicka.current = zero.getReference().data["state"][1]
        zero.getMobile().magicka.base = zero.getReference().data["state"][2]
        local xyz = zero.getReference().data["state"][3]
        zero.getReference().sceneNode.rotation:fromEulerXYZ(xyz.x, xyz.y, xyz.z)
    end
end

local function saveCallback(e)
    if (zero.getReference() and zero.getMobile()) then
        zero.getReference().data["state"] = { zero.getMobile().magicka.current, zero.getMobile().magicka.base, zero.getReference().sceneNode.rotation:toEulerXYZ() }
    end
end

local function loadedCallback(e)
    --tes3.player.data["lastState"] = {isRunning = tes3.mobilePlayer.isRunning, isSneaking = tes3.mobilePlayer.isSneaking}
    if (e.newGame == false) then
        timer.start { type = timer.real, duration = 0.1, callback = function()
            if (zero.getReference()) then
                if (zero.isMounted()) then
                    zero.toggleMount(0)
                    ui.showBars()
                    ui.updateIcon1(zero.getGear())
                    ui.updateIcon2(zero.getLightOnOff())
                end
                if (zero.getReference().sceneNode and zero.getReference().data["state"]) then
                    zero.getMobile().magicka.current = zero.getReference().data["state"][1]
                    zero.getMobile().magicka.base = zero.getReference().data["state"][2]
                    local xyz = zero.getReference().data["state"][3]
                    zero.getReference().sceneNode.rotation:fromEulerXYZ(xyz.x, xyz.y, xyz.z)
                end
            else
                ui.hideBars()
            end
        end }
    else
        timer.start { type = timer.real, duration = 0.1, callback = ui.hideBars }
    end
end

local function initializedCallback(e)
    event.register("activate", activateCallback, { filter = zero.getReference() })
    event.register("simulate", simulateCallback)
    event.register("key", keyCallback)
    event.register("playGroup", playGroupCallback)
    event.register("collision", collisionCallback--[[, { filter = zero.getReference() }]])
    event.register("damage", damageCallback)
    event.register("mobileDeactivated", mobileDeactivatedCallback)
    event.register("mobileActivated", mobileActivatedCallback)
    event.register("save", saveCallback)
    event.register("loaded", loadedCallback)
    helmet.init()
    effects.init()
    ui.init()
end
event.register("initialized", initializedCallback)
