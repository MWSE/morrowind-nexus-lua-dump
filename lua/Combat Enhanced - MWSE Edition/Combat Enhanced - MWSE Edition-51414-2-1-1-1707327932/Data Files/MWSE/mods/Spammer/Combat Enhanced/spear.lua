local message = {
    Gore = {
        "This terrible thrust has disoriented your foe, who keeps falling down." },
    Offbalance = {
        "With this Thrust, you feel like the next strikes will bite deeper into your victim...",
        "Who will dare fight your blood-hungry weapon? Who can withstand its deeper and deeper wounds?" },
    Sweep = {
        "One swift circular motion sweeps your enemy down!",
        "An unexpected move, but effective nonetheless. They fall like leaves." },
    Quickthrust = {
        "Thrust faster, harder, and do not let go this flurry of blows!",
        "Keep up the good work : It seems that you have reached an optimal thrusting rythm." },
    Impale = {
        "You impale your enemy with such force that your spear remains stuck through!",
        "Your weapon plows through. It is time for your foe to start a new journey... To the other side." }

}

local list = {}
local mod = { gore = 0, offb = 0, sweep = 0, quik = 0, impale = 0 }
list.treshold = { gore = 10, offb = 30, sweep = 50, quik = 70, impale = 90 }
local myTimer

function list.damage(type, target)
    local cf = mwse.loadConfig("Combat Enhanced", { mb = false, deadlyHit = 100 })
    local skill = tes3.mobilePlayer.spear.current
    for name, value in pairs(list.treshold) do
        if skill < value then
            mod[name] = -1
        end
        --debug.log(name.." ="..mod[name]+1)
    end
    if type == tes3.physicalAttackType.thrust then
        if mod.gore == 2 then
            tes3.playSound({ mixChannel = tes3.soundMix.master, reference = target, soundPath = "MWE\\MWE_SpearGore.wav" })
            mod.gore = 0
            tes3.modStatistic({ reference = target, name = "speed", current = -10, limit = true })
            tes3.modStatistic({ reference = target, name = "agility", current = -10, limit = true })
            if cf.mb then
                tes3.messageBox { message = table.choice(message.Gore) }
            end
        else
            mod.gore = 1
        end
        if mod.offb == 2 then
            mod.offb = 0
            tes3.modStatistic({ reference = target, name = "endurance", current = -10, limit = true })
            tes3.playSound({ mixChannel = tes3.soundMix.master, reference = target, soundPath =
            "MWE\\MWE_SpearOffBalance.wav" })
            if cf.mb then
                tes3.messageBox { message = table.choice(message.Offbalance) }
            end
        else
            mod.offb = 0
        end
        if mod.quik == 3 then
            if not tes3.mobilePlayer.readiedWeapon or not tes3.mobilePlayer.readiedWeapon.object then
                mod.quik = 0
                return
            end
            tes3.mobilePlayer.readiedWeapon.object.speed = tes3.mobilePlayer.readiedWeapon.object.speed * 5
            timer.start({
                duration = cf.slider,
                iterations = 1,
                callback = function()
                    tes3.mobilePlayer.readiedWeapon.object.speed = tes3.mobilePlayer.readiedWeapon.object.speed / 5
                end
            })
            tes3.playSound({ mixChannel = tes3.soundMix.master, reference = target, soundPath =
            "MWE\\MWE_SpearQuickthrust.wav" })
            if cf.mb then
                tes3.messageBox { message = table.choice(message.Quickthrust) }
            end
        elseif mod.quik == 1 or mod.quik == 2 then
            mod.quik = mod.quik + 1
        else
            mod.quik = 0
        end
        if mod.sweep == 1 then mod.sweep = mod.sweep + 1 else mod.sweep = 0 end
        if mod.impale == 4 and (target.mobile.health.normalized <= (cf.deadlyHit / 100)) then
            mod.impale = 0
            target.mobile:kill()
            tes3.playSound({
                mixChannel = tes3.soundMix.master,
                reference = target,
                soundPath =
                "MWE\\MWE_SpearImpale.wav"
            })
            if cf.mb then
                tes3.messageBox { message = table.choice(message.Impale) }
            end
        elseif mod.impale == 4 then
            tes3.playSound({
                mixChannel = tes3.soundMix.master,
                reference = target,
                soundPath =
                "MWE\\MWE_SpearImpale.wav"
            })
            target.mobile:applyDamage { applyArmor = true, playerAttack = true, applyDifficulty = true, damage = skill }
        elseif mod.impale == 3 or mod.impale == 2 then
            mod.impale = mod.impale + 1
        else
            mod.impale = 0
        end
    elseif type == tes3.physicalAttackType.chop then
        if mod.impale == 1 then mod.impale = mod.impale + 1 else mod.impale = 0 end
        mod.gore = 0
        mod.quik = 0
        mod.sweep = 1
        if mod.offb < 2 then mod.offb = mod.offb + 1 else mod.offb = 0 end
    elseif type == tes3.physicalAttackType.slash then
        if mod.gore == 1 then mod.gore = mod.gore + 1 else mod.gore = 0 end
        mod.quik = 1
        mod.impale = 1
        mod.offb = 0
        if mod.sweep == 3 then
            tes3.playAnimation { reference = target, group = tes3.animationGroup.knockOut, loopCount = 4 }
            tes3.playSound({ mixChannel = tes3.soundMix.master, reference = target, soundPath = "MWE\\MWE_SpearSweep.wav" })
            if cf.mb then
                tes3.messageBox { message = table.choice(message.Sweep) }
            end
            mod.sweep = 0
        elseif mod.sweep == 2 then
            mod.sweep = mod.sweep + 1
        else
            mod.sweep = 0
        end
    end
    if myTimer then
        myTimer:reset()
    else
        myTimer = timer.start({
            duration = cf.slider,
            iterations = 1,
            callback = function()
                for name, _ in pairs(mod) do
                    mod[name] = 0
                end
                myTimer = nil
            end
        })
    end
end

list.def = {
    gore = [[Gore
Thrust, Slash, Thrust
A strong thrust to the opponent's hip that slows them and makes them fall down more often.]],
    offb = [[Hamp Hit
Chop, Chop, Thrust
A thrust to the stomach that knocks the wind out of your opponent.]],
    sweep = [[Sweep
Chop, Thrust, Slash, Slash
Damages and knocks the enemy down.]],
    quik = [[QuickThrust
Slash, Thrust, Thrust, Thrust
Increases weapon speed for a few seconds as long as you keep thrusting.]],
    impale = [[Impale
Slash, Chop, Thrust Thrust, Thrust
Finishing move with a spear through the opponent's body.]]
}
return list
