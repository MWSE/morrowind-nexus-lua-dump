local message = {
	Throat = {
		"Your blade slashes that cur's throat!",
		"Now, does your foe feel like talking, or gurgling to death?"},
	Dice = {
		"You feel like your blows fall faster than usual.",
		"What's come over you? All you know is, you can hit faster!"},
	Slice = {
		"Your enemies are all affected by your razor-sharp skill!",
		"Circular hit! That should buy you some time."},
	Puncture = {
		"That must have hurt. The poor sap's bleeding to death!",
		"This deep wound is sure to keep on pouring hot blood all over the place."},
	Stab = {
		"You plunge your blade into your enemy's heart and leave it there.",
		"One stab. One heart. One down."}

}


local list = {}
local blood = require("Spammer\\Combat Enhanced\\bloody")
local mod = {throat = 0, slice = 0, stab = 0, dice = 0, puncture = 0}
list.treshold =  {throat = 10, slice = 30, dice = 50, puncture = 70,  stab = 90}
local myTimer
function list.damage(type, target)
    local cf = mwse.loadConfig("Combat Enhanced")
    local skill = tes3.mobilePlayer.shortBlade.current
    for name,value in pairs(list.treshold) do
        if skill < value then
            mod[name] = -1
        end
    end
    if type == tes3.physicalAttackType.thrust then
        mod.throat = 0
        if mod.slice < 2 then mod.slice = mod.slice+1 else mod.slice = 0 end
        if mod.dice == 1 then mod.dice = mod.dice+1 else mod.dice = 0 end
        if mod.puncture == 3 then
            tes3.playSound({mixChannel = tes3.soundMix.master,  reference = target, soundPath = "MWE\\MWE_ShortBladePuncture.wav"})
            if cf.mb then
                tes3.messageBox{message = table.choice(message.Puncture)}
            end
            timer.start({duration = 0.5, iterations = skill, callback = function(self)
                if target.mobile.isDead then
                    self.timer:cancel()
                    return
                end
                target.mobile:applyDamage({damage = 1, applyArmor = false, playerAttack = true})
            end})
            mod.puncture = 0
        elseif mod.puncture >= 1 then mod.puncture = mod.puncture+1 end
        if mod.stab == 4 then
            tes3.playSound({mixChannel = tes3.soundMix.master,  reference = target, soundPath = "MWE\\MWE_ShortBladeStab.wav"})
            if cf.mb then
                tes3.messageBox{message = table.choice(message.Stab)}
            end
            tes3.setStatistic({reference = target, name = "health", current = 0})
            mod.stab = 0
        else
            mod.stab = 0
        end
    elseif type == tes3.physicalAttackType.chop then
        if mod.throat < 2 then mod.throat = mod.throat+1 else mod.throat = 1 end
        if mod.stab == 1 then mod.stab = mod.stab+1 else mod.stab = 0 end
        mod.dice = 1
        mod.puncture = 1
        mod.slice = 0
    elseif type == tes3.physicalAttackType.slash then
        if mod.throat == 2 then
            target.data.spa_ce_silenced = true
            tes3.setStatistic({reference = target, name = "magicka", value = 1})
            tes3.playSound({mixChannel = tes3.soundMix.master,  reference = target, soundPath = "MWE\\MWE_ShortBladeThrtSlsh.wav"})
            if cf.mb then
                tes3.messageBox{message = table.choice(message.Throat)}
            end
        else mod.throat = 0 end
        if mod.slice == 2 then
            if target.object.objectType == tes3.objectType.npc then
                for _,layer in pairs(tes3.activeBodyPartLayer) do
                    local activePart = target.bodyPartManager:getActiveBodyPart(layer, tes3.activeBodyPart.leftHand)
                    if activePart and activePart.node then
                        timer.delayOneFrame(function()
                           if activePart.node then activePart.node.appCulled = true end
                        end)
                        --[[if activePart.bodyPart and (layer == tes3.activeBodyPartLayer.base) then
                            local hand = tes3.createObject({objectType = tes3.objectType.miscItem, getIfExists = false, mesh = activePart.bodyPart.mesh, name = "Chopped Down Hand", icon = "MWE\\MWE_DismemberedArmIcon.tga", weight = 1})
                            tes3.setSourceless(hand)
                            if hand then
                                local ref = tes3.createReference({object = hand, cell = target.cell, position = target.position})
                                blood.addDecal(ref.sceneNode)
                                hand = nil
                            end
                        else--]]if activePart.bodyPart and (layer ~= tes3.activeBodyPartLayer.base) then
                            local glove = (tes3.getEquippedItem{actor = target, objectType = tes3.objectType.armor, slot = tes3.armorSlot.leftGauntlet}) or (tes3.getEquippedItem{actor = target, objectType = tes3.objectType.clothing, slot = tes3.clothingSlot.leftGlove})
                            if glove then
                                local ref = tes3.dropItem{reference = target, item = glove.object, itemData = glove.itemData}
                                blood.addDecal(ref.sceneNode)
                                glove = nil
                            end
                        end
                    end
                end
                if not target.data.spa_ce_dismembered then target.data.spa_ce_dismembered = {} end
                table.insert(target.data.spa_ce_dismembered, tes3.activeBodyPart.leftHand)
                if cf.mb then
                    tes3.messageBox{message = table.choice(message.Slice)}
                end
            end
            tes3.playSound({mixChannel = tes3.soundMix.master,  reference = target, soundPath = "MWE\\MWE_ShortBladeSlice.wav"})
            tes3.playAnimation{reference = target, group = tes3.animationGroup.knockDown, loopCount = 2}
            mod.slice = 0
        else mod.slice = 0
        end
        if mod.dice == 3 then
            if not tes3.mobilePlayer.readiedWeapon or not tes3.mobilePlayer.readiedWeapon.object then
                mod.dice = 0
                return
            end
            tes3.mobilePlayer.readiedWeapon.object.speed = tes3.mobilePlayer.readiedWeapon.object.speed*5
            timer.start({duration = 5, iterations = 1, callback = function ()
                tes3.mobilePlayer.readiedWeapon.object.speed = tes3.mobilePlayer.readiedWeapon.object.speed/5
            end})
            tes3.playSound({mixChannel = tes3.soundMix.master,  reference = target, soundPath = "MWE\\MWE_ShortBladeDice.wav"})
            if cf.mb then
                tes3.messageBox{message = table.choice(message.Dice)}
            end
            mod.dice = 0
        elseif mod.dice == 2 then mod.dice = mod.dice+1 else mod.dice = 0 end
        mod.puncture = 0
        if mod.stab == 2 or mod.stab == 3 then mod.stab = mod.stab+1 else mod.stab = 1 end
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

list.def = {throat = [[Throat Cut
Sequence: Chop, Chop, Slash
Description: Silences the enemy.]],
            slice = [[Slice
Sequence: Thrust, Thrust, Slash
Description: Chops off the enemy's hand.]],
            dice = [[Dice
Sequence: Chop, Thrust, Slash, Slash
Description: Increases your weaponspeed for a few seconds.]],
            puncture = [[Puncture
Sequence: Chop, Thrust, Thrust, Thrust
Description: Punctures a vital organ, causing continuous damage.]],
            stab = [[Stab
Sequence: Slash, Chop, Slash, Slash, Thrust
Description: Finishing move with a strike straight through the heart.]]}
return list