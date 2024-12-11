local config = require('mer.characterBackgrounds.config')
return {
    id = "ratKing",
    name = "Крысиный король",
    description = (
        "В младенченстве вас выбросили в канализацию, где вас вырастили крысы. " ..
        "Вы привязаны к этим пушистым созданиям, и любое из них готово следовать за вами " ..
        "куда угодно. Кроме того, в дикой местности " ..
        "вы можете призвать на помощь стаю крыс (не более 1 раза в сутки). " ..
        "Жизнь среди приятелей-грызунов наделила вас " ..
        "сильным запахом (-20 к привлекательности)."
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            attribute = tes3.attribute.personality,
            value = -20
        })
    end,
    callback = function()
        local getData = function()
            local data = tes3.player.data.merBackgrounds or {}
            data.ratKing = data.ratKing or {
                lastSummonHour = 0
            }
            return data
        end

        local function getIsRat(ref)
            local id = string.lower(ref.object.id)
            return (
                string.sub(id, 1, 3) == "rat"
                or
                ref.name == "Rat"
            )
        end

        local function calmRat(ref)
            if getIsRat(ref) then
                local objType
                if (ref.object.isInstance) then
                    objType = ref.object.baseObject.objectType
                else
                    objType = ref.object.objectType
                end
                if objType == tes3.objectType.creature then
                    --Calm straight away
                    ref.mobile.fight = 0
                    --Follow when it gets close
                    if ref.position:distance(tes3.player.position) < 600 then
                        if not ref.data.ratFollower then
                            ref.data.ratFollower = true
                            tes3.setAIFollow{ reference = ref, target = tes3.player}
                        end
                    end
                end
            end
        end

        local function mobileActivated(e)
            local data = getData()
            if data.currentBackground == "ratKing" then
                calmRat(e.reference)
            end
        end

        local function checkForRats()
            local data = getData()
            if data.currentBackground == "ratKing" then
                for _, cell in pairs( tes3.getActiveCells() ) do
                    for creature in cell:iterateReferences(tes3.objectType.creature) do
                        calmRat(creature)
                    end
                end
            end
        end

        local function combatStarted(e)
            local data = getData()
            if data.currentBackground == "ratKing" then
                --Rats only summoned in the wilderness
                local cell = tes3.getPlayerCell()
                if cell.restingIsIllegal or cell.isInterior then return end

                --avoid infinite loops
                local isRat = (
                    string.sub(string.lower(e.target.object.id), 1, 3) == "rat" or
                    string.sub(string.lower(e.actor.object.id), 1, 3) == "rat"
                )
                if isRat then
                    return
                end

                local currentHours = ( tes3.worldController.daysPassed.value * 24 ) + tes3.worldController.hour.value

                data.ratKing.lastSummonHour = data.ratKing.lastSummonHour or 0
                if currentHours >= ( data.ratKing.lastSummonHour + config.mcm.ratKingInterval ) then
                    if math.random() < ( config.mcm.ratKingChance / 100 ) then
                        tes3.messageBox("Стая крыс пришла вам на помощь!")
                        local ratCount = math.random(3, 5)
                        local command = string.format("PlaceAtPC rat %d 100 1", ratCount)
                        ---@diagnostic disable-next-line
                        tes3.runLegacyScript{ command = command }
                        data.ratKing.lastSummonHour = currentHours
                    end
                end
            end
        end

        checkForRats()
        timer.start{
            type = timer.simulate,
            duration = 0.5,
            iterations = -1,
            callback = checkForRats
        }

        event.unregister("mobileActivated", mobileActivated)
        event.register("mobileActivated", mobileActivated)

        event.unregister("combatStarted", combatStarted)
        event.register("combatStarted", combatStarted)
    end
}