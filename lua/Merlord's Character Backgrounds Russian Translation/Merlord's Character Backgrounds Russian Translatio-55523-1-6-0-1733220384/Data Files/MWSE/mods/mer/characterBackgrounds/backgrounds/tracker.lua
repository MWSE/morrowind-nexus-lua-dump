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
    name = "Следопыт",
    description = (
        "Как опытный следопыт, вы умеете находить животных по оставленным ими следам. " ..
        "Кроме того, вы понимаете характер рельефа и умеете быстро передвигаться по пересеченной местности. Вы получаете " ..
        "способность Найти животное 100 пунктов и +10 к скорости вдали от жилья."
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