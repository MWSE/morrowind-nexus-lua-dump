local escapedSlaveInterruptChance = 0.50
local currentSlaver
local defaultSlaverList = {
    { id = "mer_bg_headhunter_01", list = "mer_bg_headhunterList_01", hasFought = false},
    { id = "mer_bg_headhunter_02", list = "mer_bg_headhunterList_02", hasFought = false},
    { id = "mer_bg_headhunter_03", list = "mer_bg_headhunterList_03", hasFought = false},
    { id = "mer_bg_headhunter_04", list = "mer_bg_headhunterList_04", hasFought = false},
    { id = "mer_bg_headhunter_05", list = "mer_bg_headhunterList_05", hasFought = false},
    { id = "mer_bg_slavemaster", list = "mer_bg_slavemasterList", hasFought = false},
}


local interop = require("mer.characterBackgrounds.interop")
local background = interop.addBackground{
    id = "escapedSlave",
    name = "Беглый раб",
    description = (
        "Вы являетесь собственностью богатого работорговца, но вам удалось сбежать... по крайней мере, на данный момент." ..
        "Ваш бывший владелец не потерпит подобного неповиновения и отправил охотников за головами" ..
        "выследить вас и убить, чтобы у других рабов не возникло даже слабой надежды на свободу. \n\n" ..

        "Требования: Только Хаджиты или Аргониане."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        local isSlaveRace = ( race == "Argonian" or race == "Khajiit" )
        return not isSlaveRace
    end,
    doOnce = function(self)
        self.data.escapedSlave = self.data.escapedSlave or {
            slaversKilled = 0,
            slavers = defaultSlaverList
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
}
if not background then return end



local function isValidSlaver(slaver)
    if background.data.testMode then
        return slaver.hasFought ~= true
    end
    return slaver.hasFought ~= true
        and tes3.getObject(slaver.id).level <= tes3.player.object.level
end


event.register("calcRestInterrupt", function(e)
    if not background:isActive() then return end
    local rand = math.random()
    if rand < escapedSlaveInterruptChance then
        for _, slaver in ipairs(background.data.slavers) do
            if isValidSlaver(slaver) then
                currentSlaver = slaver
                e.count = 1
                e.hour = math.random(1, 3)
                break
            end
        end
    end
end)

event.register("restInterrupt", function(e)
    if not background:isActive() then return end
    if currentSlaver and not currentSlaver.hasFought then
        currentSlaver.hasFought = true
        e.creature = tes3.getObject(currentSlaver.list)
    end
end)