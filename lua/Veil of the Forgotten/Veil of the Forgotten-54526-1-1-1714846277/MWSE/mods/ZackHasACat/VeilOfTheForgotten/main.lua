local spokenToActor
local idToRelease
local thrownHit = false
local settings = require("ZackHasACat.VeilOfTheForgotten.settings")
local function getValue(id)
    if not tes3.player.data.votf then
        tes3.player.data.votf = {}
    end
    return tes3.player.data.votf[id]
end
local function setValue(id, value)
    if not tes3.player.data.votf then
        tes3.player.data.votf = {}
    end
    tes3.player.data.votf[id] = value
end
local function isThrowableOrb(id)
    if id == "zhac_ball_01" then
        return true
    elseif id == "zhac_ball_02" then
        return true
    elseif getValue(id) then
        return true
    end
    return false
end
local function actorCanBeCaptured(actor)
    local percentage = actor.mobile.health.current / actor.mobile.health.base
    local sett = settings.healthCaptureThreshold
    if not sett then
        sett = 0.5
    end
    if actor.data.isControlled then
        return true
    end
    return percentage <= sett
end

local function pacifyRef(refId)
    local obj = tes3.getReference(refId)
    obj.mobile.fight = 0
    obj.mobile.hello = 0
    obj.mobile.alarm = 0
    obj.mobile:stopCombat(true)
    obj.data.isControlled = true
    tes3.setAIFollow({ reference = obj, target = tes3.player })
end
local function uiObjectTooltipCallback(e)
    if e.object and getValue(e.object.id) then
        local idcheck = getValue(e.object.id)
        if idcheck then
            local obj = tes3.getReference(idcheck)
            e.tooltip:createLabel { text = "Occupant: " .. obj.object.name }
        end
    end
end
event.register(tes3.event.uiObjectTooltip, uiObjectTooltipCallback)
local function projectileHitEscape(point, weapon)
    if not weapon.id then
        return
    end
    idToRelease = getValue(weapon.id)
    if idToRelease then
        local obj = tes3.getReference(idToRelease)
        tes3.positionCell { reference = obj, position = point, cell = tes3.player.cell }


        timer.start({
            duration = 0.3,
            callback = function()
                pacifyRef(idToRelease)
            end
        })
        if obj.baseObject.id:lower() == "tr_m2_darvon golaren" then
            tes3.addItem { reference = tes3.player, item = "zhac_ball_02", playSound = false }
        else
            tes3.addItem { reference = tes3.player, item = "zhac_ball_01", playSound = false }
        end
        return true
    else
        return false
    end
end
local function makeDoll()
    
end
local function projectileHitActorCallback(e)
    local weapon = e.firingWeapon
    if e.firingReference.baseObject.id ~= "player" or not weapon then
        return
    end
    if weapon.id == "zhac_ball_01" or (weapon.id == "zhac_ball_02" and e.target.baseObject.id:lower() == "tr_m2_darvon golaren") then
        local canBeCapt = actorCanBeCaptured(e.target)
        if not canBeCapt then
            tes3.messageBox("You must weaken this target before they may be captured.")
            return
        end
        print("projectileHitActorCallback")
        local newObject = weapon:createCopy()
        if e.target.baseObject.id:lower() == "tr_m2_darvon golaren" then
            if tes3.getJournalIndex({ id = "ZHAC_MorianaQ_1" }) < 70 then
                tes3.updateJournal({ id = "ZHAC_MorianaQ_1", index = 70 })
            end
            setValue("darvonItem", newObject.id)
        end
        if not settings.dropAtFeet then
            tes3.addItem { reference = tes3.player, item = newObject, playSound = false }
        else
            tes3.createReference({
                object = newObject,
                position = e.target.position,
                cell = e.target
                    .cell,
                orientation = e.target.orientation
            })
        end
        setValue(newObject.id, e.target.id)
        tes3.positionCell { reference = e.target, position = tes3vector3.new(0, 0, 0), cell = "zhac_ballstorage" }
        thrownHit = true
    elseif (weapon.id == "zhac_ball_02" and e.target.baseObject.id:lower() ~= "tr_m2_darvon golaren") then
        tes3.messageBox("This globe is not attuned to this person.")
    elseif getValue(weapon.id) then
        local action = projectileHitEscape(e.target.position, weapon)
        if action then
            thrownHit = true
        end
    end
end
event.register(tes3.event.projectileHitActor, projectileHitActorCallback)
local function infoFilterCallback(e)
    -- This early check will make sure our function
    -- isn't executing unnecesarily
    if (not e.passes) then
        return
    end

    if e.dialogue.id:lower() ~= "greeting 2" and e.reference.data.isControlled then
        -- Make sure to only block the greeting (Hello) lines
        return false
    end
end
event.register(tes3.event.infoFilter, infoFilterCallback)
local function projectileHitObjectCallback(e)
    local point = e.position
    local weapon = e.firingWeapon

    if e.firingReference.baseObject.id ~= "player" then
        return
    end
    local action = projectileHitEscape(point, weapon)
    if action then
        thrownHit = true
    end

    --thrownHit = true
end
event.register(tes3.event.projectileHitObject, projectileHitObjectCallback)

event.register(tes3.event.projectileHitTerrain, projectileHitObjectCallback)
local function makeIntoDoll(target)
    
    local id = getValue(target.baseObject.id)
    local obj = tes3.getReference(id)
    tes3.addSpell({ reference = obj, spell = "zhac_standability" })
    local modifiedOrientation = tes3vector3.new(0, 0,  tes3.player.orientation.z - 180)
    local modifiedPosition = tes3vector3.new(target.position.x, target.position.y, target.position.z + 10)
    tes3.positionCell({ reference = obj, position =modifiedPosition, cell = target.cell, orientation = modifiedOrientation})
    obj.scale = 0.1
    --obj.mobile.activeAI = false
    return false
end
local function unmakeIntoDoll(target)
    
    local id = getValue(target.baseObject.id)
    local obj = tes3.getReference(id)
    --obj.mobile.activeAI = true
    tes3.removeSpell({ reference = obj, spell = "zhac_standability" })
    tes3.positionCell { reference = obj, position = tes3vector3.new(0, 0, 0), cell = "zhac_ballstorage" }
    obj.scale = 1
    return false
end
local function activateCallback(e)
    if e.target.object.id == "zhac_crystal_01" and tes3.getJournalIndex({ id = "ZHAC_MorianaQ_1" }) == 30 then
        tes3.messageBox({
            message =
            "As you touch the globe, the world goes dark.\n\nYou see a dark landscape. Red Mountain is in the distance, smoking far more than it currently does.\nYou notice two fighters in the ruins of the city of Vivec. You recognize one as Moriana. They are struggling hard to fight each other, using fire, shock, all sorts of magic.\n\nFinally, you see Moriana struck down. It all goes black, and you awake.",
            buttons = { "OK" }
        })

        tes3.updateJournal({ id = "ZHAC_MorianaQ_1", index = 40 })
        return false
    elseif e.target.object.id:lower() == ("T_Com_CrystalBallStand_01"):lower() and tes3.mobilePlayer.readiedWeapon and isThrowableOrb(tes3.mobilePlayer.readiedWeapon.object.id) then
        if tes3.menuMode() then
            return
        end
        local moveMe = tes3.mobilePlayer.readiedWeapon.object.id
        tes3.removeItem { reference = tes3.player, item = moveMe, playSound = false,count = 1 }
        tes3.createReference({
            object = moveMe,
            position = e.target.position,
            cell = e.target.cell,
            orientation = e.target.orientation
        })

        return false
    elseif e.target.data and e.target.data.isControlled == true then
        tes3.setGlobal("zhac_speakingto_controlled", 1)
        spokenToActor = e.target
        timer.start({
            duration = .5,
            callback = function()
                tes3.setGlobal("zhac_speakingto_controlled", 0)
            end
        })
    elseif e.target.baseObject.id == "zhac_shrinelady" then
        local val  = 0
        local item = getValue("darvonItem")
        if item and tes3.getItemCount { reference = tes3.player, item = item } > 0 then
            val = 1
        end
        tes3.setGlobal("zhac_votf_carrydar", val)
    elseif getValue(e.target.baseObject.id) then
        if tes3.menuMode() then
            unmakeIntoDoll(e.target)
            return
        else
            makeIntoDoll(e.target)
            return false
        end
    end
end
event.register("menuEnter", function(e)
    local npcMobile = e.menu:getPropertyObject("PartHyperText_actor")
    if not (npcMobile and npcMobile.reference) then return end
    local isNpc = npcMobile.reference.baseObject.objectType == tes3.objectType.npc

    if isNpc and npcMobile.reference.data.isControlled == true then
        local companionShareElement = e.menu:findChild("MenuDialog_service_companion")
        companionShareElement.visible = true
    end
end, { filter = "MenuDialog", priority = 100 })
event.register(tes3.event.activate, activateCallback)

local function referenceActivatedCallback(e)
    if e.reference.object.id == "zhac_marker_compshare" then
        e.reference:delete()

        tes3.showContentsMenu { reference = spokenToActor }
    elseif e.reference.object.id == "zhac_marker_compshare" then
            e.reference:delete()
    
            tes3.showContentsMenu { reference = spokenToActor }
    elseif e.reference.object.id == "zhac_marker_removedarv" then
        local remId = getValue("darvonItem")
        tes3.removeItem { reference = tes3.player, item = remId, playSound = false }
    end
end

local function onAttackStart(e)
    local mobile = e.reference.mobile
    if not mobile then return end
    if not mobile.readiedWeapon then return end
    if e.reference ~= tes3.player then return end

    local weapon = mobile.readiedWeapon.object --[[@as tes3weapon]]
    if isThrowableOrb(weapon.id) then
        thrownHit = false
    end
end
local function projectileExpireCallback(e)
    if e.firingReference.baseObject.id ~= "player" then
        return
    end
    if not e.firingWeapon or not isThrowableOrb(e.firingWeapon.id) then
        return
    end
    timer.start({
        duration = 0.5,
        callback = function()
            if not thrownHit then
                tes3.addItem { reference = tes3.player, item = e.firingWeapon.id, playSound = true }
            end
        end
    })
end
event.register(tes3.event.projectileExpire, projectileExpireCallback)

event.register(tes3.event.attackStart, onAttackStart)
event.register(tes3.event.referenceActivated, referenceActivatedCallback)
