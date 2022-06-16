local message = {
	Hack = {
		"Keep this up : your enemy seems to grow tired."},
	Cleave = {
	"You cleave your enemy's armor piece by piece!",
	"That armor only hinders movement! Fight like a warrior, you weakling!"},
    Spin = {
	"That circular attack obliterates your opponnent's shield!.",
	"You spin round and manage to destroy your opponnent's shield!"},
	Frenzy = {
	"You enter Battle Frenzy! SMASH ALL WEAKLINGS!",
	"None can stand before you! BERSERKER!"},
	Behead = {
	"Pitiful eyes throw you a pathetic look as a puzzled head falls to the ground.",
	"A fleeting moment passes. A head falls. A master has struck."}
}
local list = {}
local blood = require("Spammer\\Combat Enhanced\\bloody")
local mod = {hack = 0, cleave = 0, behead = 0, spin = 0, frenzy = 0}
list.treshold =  {hack = 10, cleave = 30, spin = 50, frenzy = 70, behead = 90}
local myTimer
function list.damage(type, target)
    local cf = mwse.loadConfig("Combat Enhanced")
    local skill = tes3.mobilePlayer.axe.current
    for name,value in pairs(list.treshold) do
        if skill < value then
            mod[name] = -1
        end
    end
    if type == tes3.physicalAttackType.thrust then
        mod.hack = 0
        mod.behead = 1
        mod.frenzy = 0
        mod.cleave = 0
        if mod.spin == 1 then mod.spin = mod.spin+1 else mod.spin = 0 end
    elseif type == tes3.physicalAttackType.chop then
        mod.spin = 1
        if mod.hack == 2 then
            tes3.modStatistic({reference = target, name = "fatigue", current = (0-(skill)), limit = false})
            tes3.playSound({mixChannel = tes3.soundMix.master, reference = target, soundPath = "MWE\\MWE_AxeHack.wav"})
            if cf.mb then
                tes3.messageBox{message = table.choice(message.Hack)}
            end
            mod.hack = 0
        else mod.hack = 1 end
        if mod.cleave == 1 then mod.cleave = mod.cleave+1 else mod.cleave = 0 end
        if mod.behead == 1 or mod.behead == 2 then mod.behead = mod.behead+1 else mod.behead = 0 end
        if mod.frenzy == 3 then
            mod.frenzy = 0
            local equippedArmor = tes3.getEquippedItem({ actor = target, objectType = tes3.objectType.armor, slot = tes3.armorSlot.cuirass })
            if not equippedArmor or not equippedArmor.itemData then return end
            equippedArmor.itemData.condition = 0
            tes3.playSound({mixChannel = tes3.soundMix.master, reference = target, soundPath = "MWE\\MWE_AxeCleave.wav"})
            if cf.mb then
                tes3.messageBox{message = table.choice(message.Cleave)}
            end
        elseif mod.frenzy > 0 then mod.frenzy = mod.frenzy+1 end
    elseif type == tes3.physicalAttackType.slash then
        mod.frenzy = 1
        if mod.hack == 1 then mod.hack = mod.hack+1 else mod.hack = 0 end
        if mod.cleave == 2 then
            mod.cleave = 0
            tes3.playSound({mixChannel = tes3.soundMix.master, reference = target, soundPath = "MWE\\MWE_AxeCleave2.wav"})
            if cf.mb then
                tes3.messageBox{message = table.choice(message.Frenzy)}
            end
            tes3.playAnimation{reference = target, group = tes3.animationGroup.knockOut, loopCount = 4}
        elseif mod.cleave == 1 then mod.cleave = 0 else mod.cleave = 1 end
        if mod.spin == 3 then
            mod.spin = 0
            local equippedArmor = tes3.getEquippedItem({ actor = target, objectType = tes3.objectType.armor, slot = tes3.armorSlot.shield })
            if not equippedArmor or not equippedArmor.itemData then return end
            equippedArmor.itemData.condition = 0
            tes3.playSound({mixChannel = tes3.soundMix.master, reference = target, soundPath = "MWE\\MWE_AxeSpin.wav"})
            if cf.mb then
                tes3.messageBox{message = table.choice(message.Spin)}
            end
        elseif mod.spin == 2 then mod.spin = mod.spin+1 else mod.spin = 0 end
        if mod.behead < 3 then mod.behead = 0
        elseif mod.behead == 3 then mod.behead = mod.behead+1
        else
            mod.behead = 0
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
                            local helmet = tes3.getEquippedItem({actor = target, objectType = tes3.objectType.armor, slot = tes3.armorSlot.helmet})
                            if helmet then
                                local ref = tes3.dropItem({reference = target, item = helmet.object, itemData = helmet.itemData})
                                blood.addDecal(ref.sceneNode)
                                helmet = nil
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
                    tes3.messageBox{message = table.choice(message.Behead)}
                end
                tes3.setStatistic({reference = target, name = "health", current = 0})
            end

            tes3.playSound({mixChannel = tes3.soundMix.master,  reference = target, soundPath = "MWE\\MWE_AxeBehead.wav"})
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

list.def = {hack = [[Hack
Sequence: Chop, Slash, Chop
Description: Quick blows to tire out the opponent and make their attack slower.]],
            cleave = [[Cleave
Sequence: Slash, Chop, Slash
Description: High damage attack that can knock out the enemy.]],
            spin = [[Shield Break
Sequence: Chop, Thrust, Slash, Slash
Description: Breaks your enemy's shield.]],
            frenzy = [[Frenzy
Sequence: Slash, Chop, Chop, Chop
Description: Damages the enemy's Cuirass.]],
            behead = [[Behead
Sequence: Thrust, Chop, Chop, Slash, Slash
Description: Finishing move that takes off the opponent's head.]]
        }
return list