local message = {
    Bone = {
        "You hear bones break under your weapon's mighty blows!",
        "That opponent's arm shouldn't hold a weapon. It should hold a bandage!" },
    Knockdown = {
        "A thrust to the stomach knocks the wind out of your opponent!",
        "Knocked down! And now, put an end to your enemy's misery." },
    Shield = {
        "How will this fool stand a chance against you without a helmet, now?",
        "No more hiding behind helmets, weakling!" },
    Slam = {
        "All tremble around your powerful Bash.",
        "A massive shockwave shatters your enemies' convictions!" },
    Knockout = {
        "Your victim is knocked unconscious by such a terrible blow. Unconscious or dead.",
        "Looks like this one's a beautiful sleeper. Forever." }
}


local list = {}
local mod = { bone = 0, knock = 0, knockout = 0, slam = 0, bash = 0 }
list.treshold = { bone = 10, knock = 30, slam = 50, bash = 70, knockout = 90 }
local myTimer
function list.damage(type, target)
    local cf = mwse.loadConfig("Combat Enhanced", { mb = false, deadlyHit = 100 })
    local skill = tes3.mobilePlayer.bluntWeapon.current
    for name, value in pairs(list.treshold) do
        if skill < value then
            mod[name] = -1
        end
    end
    if type == tes3.physicalAttackType.thrust then
        mod.bone = 0
        mod.knockout = 0
        mod.slam = 1
        if mod.bash == 2 then mod.bash = mod.bash + 1 else mod.bash = 0 end
        if mod.knock == 2 then
            tes3.playAnimation { reference = target, group = tes3.animationGroup.knockDown, loopCount = 4 }
            tes3.playSound({ mixChannel = tes3.soundMix.master, reference = target, soundPath =
            "MWE\\MWE_BluntKnockdown.wav" })
            if cf.mb then
                tes3.messageBox { message = table.choice(message.Knockdown) }
            end
            mod.knock = 0
        else
            mod.knock = 0
        end
    elseif type == tes3.physicalAttackType.chop then
        mod.knock = 1
        if mod.bone == 1 then mod.bone = mod.bone + 1 else mod.bone = 0 end
        if mod.slam == 3 then
            local equippedArmor = tes3.getEquippedItem({ actor = target, objectType = tes3.objectType.armor, slot = tes3.armorSlot.helmet })
            if not equippedArmor or not equippedArmor.itemData then
                mod.slam = 0
                return
            end
            equippedArmor.itemData.condition = 0
            tes3.playSound({ mixChannel = tes3.soundMix.master, reference = target, soundPath =
            "MWE\\MWE_BluntDisarmShield.wav" })
            if cf.mb then
                tes3.messageBox { message = table.choice(message.Shield) }
            end
        end
        mod.slam = 0
        if mod.bash == 3 then
            tes3.applyMagicSource { reference = target, name = "Paralyze", target = target, bypassResistances = true, effects = {
                {
                    id = tes3.effect.paralyze,
                    min = 1,
                    max = 1,
                    duration = 10
                }
            } }
            tes3.playSound({ mixChannel = tes3.soundMix.master, reference = target, soundPath = "MWE\\MWE_BluntSlam.wav" })
            if cf.mb then
                tes3.messageBox { message = table.choice(message.Slam) }
            end
        end
        mod.bash = 0
        if mod.knockout < 2 then
            mod.knockout = mod.knockout + 1
        elseif mod.knockout == 4 then
            mod.knockout = 0
            tes3.setStatistic({ reference = target, name = "fatigue", current = (0 - (2 * skill)), limit = false })
            tes3.playSound({ mixChannel = tes3.soundMix.master, reference = target, soundPath =
            "MWE\\MWE_BluntKnockOut.wav" })
            if cf.mb then
                tes3.messageBox { message = table.choice(message.Knockout) }
            end
        else
            mod.knockout = 0
        end
    elseif type == tes3.physicalAttackType.slash then
        if mod.knockout == 2 or mod.knockout == 3 then mod.knockout = mod.knockout + 1 else mod.knockout = 0 end
        if mod.bash < 2 then mod.bash = mod.bash + 1 else mod.bash = 1 end
        if mod.slam == 1 or mod.slam == 2 then mod.slam = mod.slam + 1 else mod.slam = 0 end
        if mod.knock == 1 then mod.knock = mod.knock + 1 else mod.knock = 0 end
        if mod.bone == 2 then
            tes3.modStatistic({ reference = target, name = "strenght", current = -20, limit = true })
            tes3.playSound({ mixChannel = tes3.soundMix.master, reference = target, soundPath =
            "MWE\\MWE_BluntBoneBreak.wav" })
            if cf.mb then
                tes3.messageBox { message = table.choice(message.Bone) }
            end
            mod.bone = 0
        else
            mod.bone = 1
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
    bone = [[Bone Break
Slash, Chop, Slash
Damages the opponent's weapons skills.]],
    knock = [[KnockDown
Chop, Slash, Thrust
A strong thrust to the opponent's hip that knocks them down.]],
    slam = [[Slam
Thrust, Slash, Slash, Chop
Breaks your enemy's helmet.]],
    bash = [[Stun
Slash, Slash, Thrust, Chop
Temporarily paralyzes the enemy and does extra damage.]],
    knockout = [[KnockOut
Chop, Chop, Slash, Slash, Chop
Finishing move that knocks the enemy unconscious.]]
}
return list
