local function getData()
    local data = tes3.player.data.merBackgrounds or {}
    data.tracker = data.tracker or {
        buffed = false,
    }
    return data
end

local function modSpeed(value)
    tes3.modStatistic({
        reference = tes3.player,
        attribute = tes3.attribute.speed,
        value = value
    })
end

return {
    id = "tracker",
    name = "Tracker",
    description = (
        "As a seasoned tracker, you can read signs and disturbances left by animals to find their location. " ..
        "You also know the lay of the land, and can move quickly through uneven terrain. You gain a " ..
        "100pt Detect Animal ability, and gain 10 Speed when out in the wilderness."
    ),
    doOnce = function()
        --add tracker ability
        tes3.addSpell{
            reference = tes3.player,
            spell = "mer_bg_tracker_a"
        }
    end,

    callback = function()


        local function cellChanged(e)
            local data = getData()
            if data.currentBackground == "tracker" then
                --In town
                if e.cell.restingIsIllegal then
                    --remove buff
                    if data.tracker.buffed then
                        data.tracker.buffed = false
                        modSpeed(-10)
                    end
                else
                --Not in town

                    --outside
                    if not e.cell.isInterior then
                        --add buff
                        if not data.tracker.buffed then
                            data.tracker.buffed = true
                            modSpeed(10)
                        end
                    else
                        if data.tracker.buffed then
                            data.tracker.buffed = false
                            modSpeed(-10)
                        end
                    end
                end
            else
                --remove buff
                if data.tracker and data.tracker.buffed then
                    data.tracker.buffed = false
                    modSpeed(-10)
                end
            end
        end

        event.unregister("cellChanged", cellChanged)
        event.register("cellChanged", cellChanged)
    end
}