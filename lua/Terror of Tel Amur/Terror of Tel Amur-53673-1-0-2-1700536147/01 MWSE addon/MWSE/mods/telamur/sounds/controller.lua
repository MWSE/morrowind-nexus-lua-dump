local utils = require("telamur.utils")

---@type mwseTimer|nil
local interiorTimer

local sounds = {}
for i = 1, 10 do
    table.insert(sounds, tes3.getSound("tew_ta_int" .. i))
end
local durations = { 5, 8, 10, 12, 14, 15, 18, 20, 23, 25, 28, 30 }

local randomSound = utils.math.nonRepeatTableRNG(sounds)
local randomDuration = utils.math.nonRepeatTableRNG(durations)

local function playInteriorSound()
    tes3.playSound({
        sound = randomSound(),
        reference = tes3.player,
        volume = math.random() * 0.6 + 0.4,
        mixChannel = tes3.soundMix.effects,
    })
end

local function resolveCell()
    if (interiorTimer) and not (interiorTimer.state == timer.expired) then
        interiorTimer:cancel()
        interiorTimer = nil
    end

    local cell = tes3.getPlayerCell()
    if utils.cells.isTelAmurCell(cell) then
        interiorTimer = timer.start({
            duration = randomDuration(),
            callback = function()
                playInteriorSound()
                resolveCell()
            end
        })
    end
end
event.register(tes3.event.cellChanged, resolveCell)
