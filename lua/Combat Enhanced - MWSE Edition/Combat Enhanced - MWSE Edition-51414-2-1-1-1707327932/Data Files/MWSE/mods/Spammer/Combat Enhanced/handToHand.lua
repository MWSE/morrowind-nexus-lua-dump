local message = {
    breakNose = {
        "That's one punch your opponent's nose will remember!",
        "Pow! You just knocked your foe silly!"
    },
    gougeEyes = {
        "What a horrible mess! You gouged your opponent's eyes out!!!",
        "Thumbs in eye sockets are not recommended for fine eyesight. Well done...",
    },
    uppercut = {
        "Uppercut! You send your adversary flying!",
        "You land such a powerful blow that your enemy is blown away!",
    },
    stun = {
        "Your enemy cannot move! Take advantage of this stunning move!",
        "The vital organs have been touched. Your foe is helpless now.",
    },
    snapNeck = {
        "A limp body falls to the ground. That neck snapped like a twig!",
        "Life is but a fleeting moment. Only now, with a broken neck, has your foe realized that.",
    }
}
local list = {}
local blood = require("Spammer\\Combat Enhanced\\bloody")
local mod = { breakNose = 0, gougeEyes = 0, snapNeck = 0, uppercut = 0, stun = 0 }
list.treshold = { breakNose = 10, gougeEyes = 30, uppercut = 50, stun = 70, snapNeck = 90 }
local myTimer

---@param type integer
---@param target tes3reference
---@return number|nil
function list.damage(type, target)
    local cf = mwse.loadConfig("Combat Enhanced", { mb = false, deadlyHit = 100 })
    local skill = tes3.mobilePlayer.handToHand.current
    for name, value in pairs(list.treshold) do
        if skill < value then
            mod[name] = -1
        end
    end
    if type == tes3.physicalAttackType.thrust then
        mod.gougeEyes = 0

        if (mod.breakNose == 0) then
            mod.breakNose = 1
        elseif (mod.breakNose == 2) then
            tes3.playSound({ mixChannel = tes3.soundMix.master, reference = target, soundPath =
            "MWE\\MWE_UnarmedbreakNose.wav" })
            if cf.mb then
                tes3.messageBox { message = table.choice(message.breakNose) }
            end
            tes3.playAnimation { reference = target, group = tes3.animationGroup.sneakBack, loopCount = 0 }
            mod.breakNose = 0
            return 1.5
        else
            mod.breakNose = 1
        end

        if (mod.stun == 0) then
            mod.stun = 1
        elseif (mod.stun == 3) then
            tes3.applyMagicSource { reference = target, name = "Paralyze", target = target, bypassResistances = true, effects = {
                {
                    id = tes3.effect.paralyze,
                    min = 1,
                    max = 1,
                    duration = 10
                }
            } }
            tes3.playSound({
                mixChannel = tes3.soundMix.master,
                reference = target,
                soundPath =
                "MWE\\MWE_UnarmedStun.wav"
            })
            if cf.mb then
                tes3.messageBox { message = table.choice(message.stun) }
            end
            mod.stun = 0
            return 2
        else
            mod.stun = 1
        end

        if (mod.uppercut == 2) then
            mod.uppercut = 3
        else
            mod.uppercut = math.min(mod.uppercut, 0)
        end

        if mod.snapNeck == 4 then
            if (target.mobile.health.normalized <= (cf.deadlyHit / 100)) then
                target.mobile:kill()
            else
                target.mobile:applyDamage { applyArmor = true, playerAttack = true, applyDifficulty = true, damage = skill }
            end
            tes3.playSound({
                mixChannel = tes3.soundMix.master,
                reference = target,
                soundPath =
                "MWE\\MWE_UnarmedSnapNeck.wav"
            })
            if cf.mb then
                tes3.messageBox { message = table.choice(message.snapNeck) }
            end
        end
        mod.snapNeck = 0
    elseif type == tes3.physicalAttackType.chop then
        if (mod.gougeEyes == 2) then
            local activpart = target.bodyPartManager and target.bodyPartManager:getActiveBodyPart(tes3.activeBodyPartLayer.base, tes3.activeBodyPart.head)
            if activpart and activpart.node then blood.addDecal(activpart.node) end
            tes3.applyMagicSource { reference = target, target = target, name = "Blind", bypassResistances = true, effects = {
                {
                    id = tes3.effect.blind,
                    min = 100,
                    max = 100,
                    duration = 100
                }
            } }
            tes3.playSound({
                mixChannel = tes3.soundMix.master,
                reference = target,
                soundPath =
                "MWE\\MWE_UnarmedGougeEyes.wav"
            })
            if cf.mb then
                tes3.messageBox { message = table.choice(message.gougeEyes) }
            end
            mod.gougeEyes = 0
            return 1.5
        else
            mod.gougeEyes = 0
        end

        if (mod.uppercut == 3) then
            tes3.playAnimation { reference = target, loopCount = 2, group = tes3.animationGroup.knockOut }
            tes3.playSound({
                mixChannel = tes3.soundMix.master,
                reference = target,
                soundPath =
                "MWE\\MWE_UnarmedUppercut.wav"
            })
            if cf.mb then
                tes3.messageBox { message = table.choice(message.uppercut) }
            end
            mod.uppercut = 0
            return 2
        else mod.uppercut = 0
        end

        if (mod.stun == 1) or (mod.stun == 2) then
            mod.stun = mod.stun + 1
        else
            mod.stun = 0
        end

        if mod.snapNeck <= 1 then
            mod.snapNeck = mod.snapNeck + 1
        else
            mod.snapNeck = 1
        end

        if mod.breakNose == 1 then
            mod.breakNose = 2
        else 
            mod.breakNose = 0
        end

    elseif type == tes3.physicalAttackType.slash then
        mod.breakNose = 0
        mod.stun = 0

        if (mod.gougeEyes < 2) then
            mod.gougeEyes = mod.gougeEyes + 1
        else
            mod.gougeEyes = 1
        end

        if (mod.uppercut < 2) then
            mod.uppercut = mod.uppercut + 1
        else
            mod.uppercut = 1
        end
        
        if (mod.snapNeck == 2) or (mod.snapNeck == 3) then
            mod.snapNeck = mod.snapNeck + 1
        else
            mod.snapNeck = 0
        end
    end
    if myTimer then
        myTimer:reset()
    else
        myTimer = timer.start({
            duration = cf.slider,
            iterations = 1,
            callback = function()
                for name, combo in pairs(mod) do
                    if combo ~= 0 then mod[name] = 0 end
                end
                myTimer = nil
            end
        })
    end
end

list.def = {
    breakNose = [[Break Nose
Thrust, Chop, Thrust
Causes heavy damage and drains extra fatigue.]],
    gougeEyes = [[Gouge Eyes
Slash, Slash, Chop
Blinds the opponent and does extra damage.]],
    uppercut = [[Uppercut
Slash, Slash, Thrust, Chop
Knocks the opponent backwards and down and does extra damage.]],
    stun = [[Stun
Thrust, Chop, Chop, Thrust
Temporarily paralyzes the enemy and does extra damage.]],
    snapNeck = [[Snap Neck
Chop, Chop, Slash, Slash, Thrust
Finishing move that breaks the opponent's neck.]]
}


return list

