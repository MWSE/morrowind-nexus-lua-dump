--register MCM
require('LovePillowHunt.mcm')
local util = require('LovePillowHunt.util')
local vocals = require('LovePillowHunt.vocals')

local currentPillow
local skipActivate

local idPattern = 'lovepillow_'
local spellPattern = 'lovepillow_sp_'
local maxCleanliness = 100
local dirtyMin = 10
local dirtyMax = 20
local cleanLabel = '%s (%d%% clean)'

--timers
local cleanHours = 0.15
local cleanSeconds = 2
local dirtyHours = 0.5
local dirtySeconds = 4

local pillowList = {
    lovepillow_divayth = {id = 'lovepillow_divayth', spell = 'lovepillow_sp_divayth'},
    lovepillow_dratha = {id = 'lovepillow_dratha', spell = 'lovepillow_sp_dratha'},
    lovepillow_fargoth = {id = 'lovepillow_fargoth', spell = 'lovepillow_sp_fargoth'},
    lovepillow_gaenor = {id = 'lovepillow_gaenor', spell = 'lovepillow_sp_gaenor'},
    lovepillow_galbedir = {id = 'lovepillow_galbedir', spell = 'lovepillow_sp_galbedir'},
    lovepillow_jiub = {id = 'lovepillow_jiub', spell = 'lovepillow_sp_jiub'},
    lovepillow_maiq = {id = 'lovepillow_maiq', spell = 'lovepillow_sp_maiq'},
    lovepillow_mehramilo = {id = 'lovepillow_mehramilo', spell = 'lovepillow_sp_mehramilo'},
    lovepillow_vivec = {id = 'lovepillow_vivec', spell = 'lovepillow_sp_vivec'},
    lovepillow_almalexia = {id = 'lovepillow_almalexia', spell = 'lovepillow_sp_almalexia'},
    lovepillow_anhaedra = {id = 'lovepillow_anhaedra', spell = 'lovepillow_sp_anhaedra'},
    lovepillow_azura = {id = 'lovepillow_azura', spell = 'lovepillow_sp_azura'},
    lovepillow_caius = {id = 'lovepillow_caius', spell = 'lovepillow_sp_caius'},
    lovepillow_crassius = {id = 'lovepillow_crassius', spell = 'lovepillow_sp_crassius'},
    lovepillow_dagothur = {id = 'lovepillow_dagothur', spell = 'lovepillow_sp_dagothur'},
    lovepillow_tarhiel = {id = 'lovepillow_tarhiel', spell = 'lovepillow_sp_tarhiel'},
    lovepillow_habasi = { id  = 'lovepillow_habasi', spell = 'lovepillow_sp_habasi' },
    lovepillow_eydis = { id  = 'lovepillow_eydis', spell = 'lovepillow_sp_eydis' },
}

--Get config file for MCM values
local function getConfig()
    local configPath = 'love_pillow_hunt_config'
    return mwse.loadConfig(configPath)
end

--Get data for current pillow, or stack itemData
local function getData(itemData)
    if itemData then
        itemData.data.bodypillow = itemData.data.bodypillow or {cleanliness = maxCleanliness}
        return itemData.data.bodypillow
    end
    if not currentPillow then
        mwse.log('ERROR: No current pillow')
        return
    end
    currentPillow.data.bodypillow = currentPillow.data.bodypillow or {cleanliness = maxCleanliness}
    return currentPillow.data.bodypillow
end

--Make the current pillow dirty
local function dirtify(amount)
    local data = getData()
    amount = amount or math.random(dirtyMin, dirtyMax)
    data.cleanliness = math.max((data.cleanliness - amount), 0)
end

--Clean the current pillow
local function clean()
    getData().cleanliness = maxCleanliness

    --Play some splashy sounds
    tes3.playSound {sound = 'Swim Left'}
    timer.start {
        type = timer.real,
        duration = cleanSeconds / 3,
        callback = function()
            tes3.playSound {sound = 'Swim Left'}
        end
    }
    timer.start {
        type = timer.real,
        duration = cleanSeconds / 2,
        callback = function()
            tes3.playSound {sound = 'Swim Right'}
        end
    }
    

end

--Remove all pillow buffs from the player
local function removeBuffs()
    for id, pillow in pairs(pillowList) do
        mwscript.removeSpell {
            reference = tes3.player,
            spell = pillow.spell
        }
    end
end

--Pillow menu buttons
local buttons = {
    {
        text = 'Cuddle',
        callback = function()
            local cleanliness = getData().cleanliness
            if cleanliness <= 0 then
                local message = string.format('%s is too filthy!', currentPillow.object.name)
                tes3.messageBox {
                    message = message,
                    buttons = {tes3.findGMST(tes3.gmst.sOK).value}
                }
                return
            else
                --Say random dialog
                local list
                local race = tes3.player.object.race.id
                if vocals[race] then
                    if tes3.player.object.female then
                        list = vocals[race].female
                    else
                        list = vocals[race].male
                    end
                end
                if list then
                    local vocal = list[math.random(#list)]
                    local command = string.format('Say "%s" "%s"', vocal.path, vocal.text)
                    tes3.runLegacyScript {command = command}
                end

                --remove old spells
                removeBuffs()

                --Fade out to messagebox, add spell
                local hoursPassed = dirtyHours
                local secondsTaken = dirtySeconds
                local function callback()
                    local spell = tes3.getObject(pillowList[currentPillow.object.id].spell)
                    mwscript.addSpell {
                        reference = tes3.player,
                        spell = spell
                    }
                    dirtify()

                    tes3.player.data.lovepillow_buffTime = util.getNow()

                    local effect = tostring(spell.effects[1])
                    local message = string.format("You feel completely satisfied.\n(%s for %s hours)", effect, getConfig().buffDuration)
                    tes3.messageBox {
                        message = message,
                        buttons = {tes3.findGMST(tes3.gmst.sOK).value}
                    }
                end
                util.fadeTimeOut(hoursPassed, secondsTaken, callback)
            end
        end
    },
    {
        text = 'Pick Up',
        callback = function()
            skipActivate = true
            tes3.player:activate(currentPillow)
        end
    },

    {
        text = "Flip Over",
        callback = function()
            local o = currentPillow.orientation
            local m1 = tes3matrix33.new()
            m1:fromEulerXYZ(o.x, o.y, o.z)
            local m2 = tes3matrix33.new()
            m2:toRotationY(math.pi)
            m1 = m1 * m2
            currentPillow.orientation = m1:toEulerXYZ()

            tes3.playSound{ sound = "Item Misc Down" }
        end
    },

    { text = 'Cancel'}
}

--Activate the pillow
local function activate(e)
    if not getConfig().enabled then
        return
    end

    local pillow = pillowList[e.target.object.id]
    if pillow and not util.getUnderWater(e.target) then
        if skipActivate then
            skipActivate = false
        else
            if not tes3.menuMode() then
                currentPillow = e.target
                local cleanliness = getData().cleanliness
                util.messageBox {
                    message = string.format('%s (%d%% clean)', currentPillow.object.name, cleanliness),
                    buttons = buttons
                }

                return false
            end
        end
    end
end
event.register('activate', activate)

--Check if buffs have expired, and remove them
local function checkBuffs(e)
    local buffTime = tes3.player.data.lovepillow_buffTime
    if buffTime then
        if buffTime + getConfig().buffDuration < util.getNow() then
            tes3.player.data.lovepillow_buffTime = nil
            removeBuffs()
        end
    end
end
event.register('simulate', checkBuffs)

--If dropped underwater, wash the pillow
local function itemDropped(e)
    if not getConfig().enabled then
        return
    end

    if string.find(e.reference.object.id, idPattern) then
        currentPillow = e.reference
        if util.getUnderWater(e.reference) and getData().cleanliness < maxCleanliness then
            tes3ui.leaveMenuMode()
            clean()
                    
            local function callback()
                tes3.messageBox {
                    message = string.format('You clean the filth from %s', e.reference.object.name),
                    buttons = {tes3.findGMST(tes3.gmst.sOK).value},
                    callback = function()
                        timer.delayOneFrame(
                            function()
                                tes3.player:activate(currentPillow)
                            end
                        )
                    end
                }
            end
            local hoursPassed = cleanHours
            local secondsTaken = cleanSeconds

            util.fadeTimeOut(hoursPassed, secondsTaken, callback)
        end
    end
end
event.register('itemDropped', itemDropped)

--Show cleanliness in tooltip
local function uiObjectTooltip(e)
    if not getConfig().enabled then
        return
    end

    if string.find(e.object.id, idPattern) then
        local cleanliness
        if e.reference then
            currentPillow = e.reference
            cleanliness = getData().cleanliness
        elseif e.itemData then
            cleanliness  = getData(e.itemData).cleanliness
        else
            cleanliness = maxCleanliness
        end
        local label = e.tooltip:findChild(tes3ui.registerID('HelpMenu_name'))
        label.text = string.format(cleanLabel, label.text, cleanliness)
    end
end

event.register('uiObjectTooltip', uiObjectTooltip)
