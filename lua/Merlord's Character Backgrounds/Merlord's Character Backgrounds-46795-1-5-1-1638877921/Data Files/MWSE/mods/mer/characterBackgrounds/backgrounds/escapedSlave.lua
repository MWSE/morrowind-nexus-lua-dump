local TESTMODE = false
local escapedSlaveInterruptChance = TESTMODE and 1.0 or 0.20
local currentSlaver
local slaverDoAttack

local function getData()
    local data = tes3.player.data.merBackgrounds or {
    }
    return data
end

return {
    id = "escapedSlave",
    name = "Escaped Slave",
    description = (
        "You are the property of a wealthy slaver, but you managed to escape... at least for now. " ..
        "Your former owner does not tolerate such disobedience, and has sent a team of headhunters to " ..
        "track you down and kill you, lest the other slaves get any flase hope about ever being free. \n\n" ..

        "Requirements: Khajiit or Argonian only."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        local isSlaveRace = ( race == "Argonian" or race == "Khajiit" )
        return not isSlaveRace
    end,
    doOnce = function(data)
        data.escapedSlave = data.escapedSlave or {
            slaversKilled = 0,
            slavers = {
                { id = "mer_bg_headhunter_01", list = "mer_bg_headhunterList_01", hasFought = false},
                { id = "mer_bg_headhunter_02", list = "mer_bg_headhunterList_02", hasFought = false},
                { id = "mer_bg_headhunter_03", list = "mer_bg_headhunterList_03", hasFought = false},
                { id = "mer_bg_headhunter_04", list = "mer_bg_headhunterList_04", hasFought = false},
                { id = "mer_bg_headhunter_05", list = "mer_bg_headhunterList_05", hasFought = false},
                { id = "mer_bg_slavemaster", list = "mer_bg_slavemasterList", hasFought = false},
            }
        }
        tes3.addItem{
            reference = tes3.player,
            item = "slave_bracer_left",
        }
        tes3.addItem{
            reference = tes3.player,
            item = "slave_bracer_right",
        }
        timer.delayOneFrame(function()
            tes3.mobilePlayer:equip{ item = "slave_bracer_left", playSound = false }
            tes3.mobilePlayer:equip{ item = "slave_bracer_right", playSound = false }
        end)
    end,
    callback = function()


        local function calcRestInterrupt(e)
            local data = getData()
            if data.currentBackground == "escapedSlave" then
                local rand = math.random()
                if rand < escapedSlaveInterruptChance then
                    for _, slaver in ipairs(data.escapedSlave.slavers) do
                        local validSlaver = (
                            slaver.hasFought ~= true and
                            tes3.getObject(slaver.id).level <= tes3.player.object.level
                        )
                        if validSlaver then
                            currentSlaver = slaver
                            slaverDoAttack = true
                            e.count = 1
                            e.hour = math.random(1, 3)
                            break
                        end
                    end

                end
            end
        end

        local function restInterrupt(e)
            local data = getData()
            if data.currentBackground == "escapedSlave" then
                if slaverDoAttack and currentSlaver then
                    slaverDoAttack = false
                    currentSlaver.hasFought = true
                    e.creature = tes3.getObject(currentSlaver.list)
                end
            end
        end

        event.unregister("calcRestInterrupt", calcRestInterrupt)
        event.register("calcRestInterrupt", calcRestInterrupt)
        event.unregister("restInterrupt", restInterrupt)
        event.register("restInterrupt", restInterrupt)
    end

}