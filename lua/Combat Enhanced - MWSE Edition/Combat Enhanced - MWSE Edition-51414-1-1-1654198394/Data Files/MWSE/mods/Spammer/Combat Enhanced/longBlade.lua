
local message = {
	Cut = {
		"Your opponent is weakened by this Cut!",
		"Small cuts add up to the damage!"},
	ShockWave = {
		"Shockwave !",
		"A powerful blow knocks everything down on its path!"},
	Blade = {
		"Your enemy suffers immensely as your blade breaks theirs!",
		"You twist your blade cruelly and destroy your ennemy blade!."},
	Disarm = {
		"With a flick of your wrist, you disarm your enemy!",
		"Your foe's weapon falls to the ground! What a clumsy fool."},
	Dismember = {
		"Your butchered opponent falls down, with their head dismembered.",
		"You have cut a head off. What are you going to do with it?"}
}

local list = {}
local blood = require("Spammer\\Combat Enhanced\\bloody")
local mod = {cut = 0, shock = 0, dismember = 0, bbreak = 0, disarm = 0}
list.treshold =  {cut = 10, shock = 30, bbreak = 50, disarm = 70, dismember = 90}
local myTimer
function list.damage(type, target)
    local cf = mwse.loadConfig("Combat Enhanced")
    local skill = tes3.mobilePlayer.longBlade.current
    for name,value in pairs(list.treshold) do
        if skill < value then
            mod[name] = -1
        end
    end
    if type == tes3.physicalAttackType.thrust then
        if mod.cut < 2 then mod.cut = mod.cut+1 else mod.cut = 1 end
        if mod.dismember < 2 then mod.dismember = mod.dismember+1 else mod.dismember = 1 end
        if mod.disarm == 0 then mod.disarm = mod.disarm+1 else mod.disarm = 1 end
        if mod.bbreak == 3 then
            if target.readiedWeapon and target.readiedWeapon.itemData then
                target.readiedWeapon.itemData.condition = 0
                tes3.playSound({mixChannel = tes3.soundMix.master,  reference = target, soundPath = "MWE\\MWE_LongBladeBladeBreak.wav"})
                if cf.mb then
                    tes3.messageBox{message = table.choice(message.Blade)}
                end
            end
            mod.bbreak = 0
        else
            mod.bbreak = 0
        end
        if mod.shock == 2 then
            tes3.playAnimation{reference = target, group = tes3.animationGroup.knockOut, loopCount = 4}
            tes3.playSound({mixChannel = tes3.soundMix.master,  reference = target, soundPath = "MWE\\MWE_LongBladeShockwave.wav"})
            if cf.mb then
                tes3.messageBox{message = table.choice(message.ShockWave)}
            end
            mod.shock = 0
        else
            mod.shock = 0
        end
    elseif type == tes3.physicalAttackType.chop then
        mod.cut = 0
        mod.shock = 0
        if mod.bbreak == 1 or mod.bbreak == 2 then mod.bbreak = mod.bbreak+1 else mod.bbreak = 0 end
        if mod.disarm == 1 or mod.disarm == 2 then mod.disarm = mod.disarm+1 else mod.disarm = 0 end
        if mod.dismember == 2 then
            mod.dismember = mod.dismember+1
        elseif mod.dismember == 4 then
            if (target.object.objectType == tes3.objectType.npc) and (target.mobile.health.normalized <= 0.2) then
                for _,layer in pairs(tes3.activeBodyPartLayer) do
                    local activePart = target.bodyPartManager:getActiveBodyPart(layer, tes3.activeBodyPart.head)
                    if activePart and activePart.node then
                        timer.delayOneFrame(function()
                            if activePart.node then activePart.node.appCulled = true end
                        end)
                        if activePart.bodyPart and (layer == tes3.activeBodyPartLayer.base) then
                            local head = tes3.createObject({objectType = tes3.objectType.miscItem, getIfExists = false, mesh = activePart.bodyPart.mesh, name = "Beheaded Head", icon = "MWE\\MWE_BeheadIcon.tga", weight = 2})
                            tes3.setSourceless(head)
                            if head then
                                local ref = tes3.createReference({object = head, cell = target.cell, position = target.position})
                                blood.addDecal(ref.sceneNode)
                                head = nil
                            end
                        elseif activePart.bodyPart and (layer ~= tes3.activeBodyPartLayer.base) then
                            local head = tes3.createObject({objectType = tes3.objectType.container, getIfExists = false, mesh = activePart.bodyPart.mesh, name = "Beheaded Head", icon = "MWE\\MWE_BeheadIcon.tga", weight = 2})
                            tes3.setSourceless(head)
                            if head then
                                local ref = tes3.createReference({object = head, cell = target.cell, position = target.position})
                                ref:clone()
                                blood.addDecal(ref.sceneNode)
                                head = nil
                                local helmet = tes3.getEquippedItem({actor = target, objectType = tes3.objectType.armor, slot = tes3.armorSlot.helmet})
                                    if helmet then
                                    tes3.transferItem({from = target, to = ref, item = helmet.object, itemData = helmet.itemData, limitCapacity = false, playSound = false})
                                    helmet = nil
                                end
                            end
                        end
                    end
                    local activePart2 = target.bodyPartManager:getActiveBodyPart(layer, tes3.activeBodyPart.hair)
                    if activePart2 and activePart2.node then
                        timer.delayOneFrame(function()
                            activePart2.node.appCulled = true
                        end)
                    end
                end
                if not target.data.spa_ce_dismembered then target.data.spa_ce_dismembered = {} end
                table.insert(target.data.spa_ce_dismembered, tes3.activeBodyPart.head)
                table.insert(target.data.spa_ce_dismembered, tes3.activeBodyPart.hair)
                if cf.mb then
                    tes3.messageBox{message = table.choice(message.Dismember)}
                end
                tes3.setStatistic({reference = target, name = "health", current = 0})
            end
            tes3.playSound({mixChannel = tes3.soundMix.master,  reference = target, soundPath = "MWE\\MWE_LongBladeDismember.wav"})
            mod.dismember = 0
        else
            mod.dismember = 0
        end
    elseif type == tes3.physicalAttackType.slash then
        if mod.dismember == 3 then mod.dismember = mod.dismember+1 else mod.dismember = 0 end
        if mod.bbreak == 0 then mod.bbreak = mod.bbreak+1 else mod.bbreak = 1 end
        if mod.shock == 1 then mod.shock = mod.shock+1 else mod.shock = 1 end
        if mod.disarm == 3 then
            if target.readiedWeapon and target.readiedWeapon.object then
                tes3.dropItem({reference = target, item = target.readiedWeapon.object, itemData = target.readiedWeapon.itemData or nil})
                tes3.playSound({mixChannel = tes3.soundMix.master,  reference = target, soundPath = "MWE\\MWE_LongBladeDisarm.wav"})
                if cf.mb then
                    tes3.messageBox{message = table.choice(message.Disarm)}
                end
                mod.disarm = 0
            end
        else
            mod.disarm = 0
        end
        if mod.cut == 2 then
            tes3.modStatistic({reference = target, name = "strength", current = -10, limit = true})
            tes3.playSound({mixChannel = tes3.soundMix.master,  reference = target, soundPath = "MWE\\MWE_LongBladeCut.wav"})
            if cf.mb then
                tes3.messageBox{message = table.choice(message.Cut)}
            end
            mod.cut = 0
        else
            mod.cut = 0
        end
    end
    if myTimer then
        myTimer:reset()
    else
        myTimer = timer.start({duration = cf.slider, iterations = 1, callback = function()
            for name,combo in pairs(mod) do
                if combo ~= 0 then mod[name] = 0 end
            end
            myTimer = nil
        end})
    end
end

list.def = {cut = [[Cut
Sequence: Thrust, Thrust, Slash
Description: A deep cut that saps the opponent's strength.]],
            shock = [[ShockWave
Sequence: Slash, Slash, Thrust
Description: Powerful thrust that knocks the enemy in front of you to the ground.]],
            bbreak = [[BladeBreak
Sequence: Slash, Chop, Chop, Thrust
Description: Breaks your enemy's weapon.]],
            disarm = [[Disarm
Sequence: Thrust, Chop, Chop, Slash
Description: Knocks opponent's weapon out of their hand.]],
            dismember = [[Decapitate
Sequence: Thrust, Thrust, Chop, Slash, Chop
Description: Finishing move that takes off the opponent's head.]]
        }
return list