local configFileName = "FloraAndFauna"
local configDefaults = {
    moveLumma = 0,
    lummaMovedDay = nil
}
local config = mwse.loadConfig(configFileName, configDefaults)

local moveLumma = config.moveLumma
local lummaMovedDay = config.lummaMovedDay

local function saveConfig()
    config.moveLumma = moveLumma
    config.lummaMovedDay = lummaMovedDay
    mwse.saveConfig(configFileName, config)
end

local function updatePicksManyFlowerState()
    local picksOutside = tes3.getReference("picks-many-flower")

    if not picksOutside then
        return
    end

    -- Check if player has line of sight
    local hasLOS = tes3.testLineOfSight({
        reference1 = tes3.player,
        reference2 = picksOutside
    })

    if not hasLOS then
        local hour = tes3.getGlobal("GameHour")
        local weather = tes3.getCurrentWeather().index

        if hour > 21 or hour < 6 or weather > 3 then
            tes3.positionCell({ 
                reference = picksOutside, 
                cell = "Pelagiad, Hillflower Manor", 
                position = {-167, 545, -137}, 
                orientation = tes3vector3.new(0, 0, 180)
            })
        else
            tes3.positionCell({ 
                reference = picksOutside, 
                cell = "Pelagiad", 
                position = {4512, -60417, 692}, 
                orientation = tes3vector3.new(0, 0, 120)
            })
        end
    end
end

local function updateManaibaState()
    local manaiba = tes3.getReference("manaiba yanumibaal")

    if not manaiba then
        return
    end

    -- Check if player has line of sight 113, 251, -78 240
    local hasLOS = tes3.testLineOfSight({
        reference1 = tes3.player,
        reference2 = manaiba
    })

    if not hasLOS then
        local hour = tes3.getGlobal("GameHour")
        local weather = tes3.getCurrentWeather().index

        if hour > 21 or hour < 6 or weather > 3 then
            tes3.positionCell({ 
                reference = manaiba, 
                cell = "Zainab Camp, Manaiba Yanumibaal's Yurt", 
                position = {103, 122, -78}, 
                orientation = tes3vector3.new(0, 0, 280)
            })
        else
            tes3.positionCell({ 
                reference = manaiba, 
                cell = "Zainab Camp", 
                position = {75968, 86233, 854}, 
                orientation = tes3vector3.new(0, 0, 17)
            })
        end
    end
end

local function updatelummalexiusState()
    local lummalexius = tes3.getReference("lumma lexius")

    if not lummalexius then
        return
    end

    -- Check if player has line of sight  
    local hasLOS = tes3.testLineOfSight({
        reference1 = tes3.player,
        reference2 = lummalexius
    })
    if moveLumma == 1 then
        if not hasLOS then
            local hour = tes3.getGlobal("GameHour")
            local weather = tes3.getCurrentWeather().index

            if hour > 21 or hour < 6 or weather > 3 then
                tes3.positionCell({ 
                    reference = lummalexius, 
                    cell = "Zainab Camp, Manaiba Yanumibaal's Yurt", 
                    position = {113, 251, -78}, 
                    orientation = tes3vector3.new(0, 0, 240)
                })
            else
                tes3.positionCell({ 
                    reference = lummalexius, 
                    cell = "Zainab Camp", 
                    position = {75960, 86364, 866}, 
                    orientation = tes3vector3.new(0, 0, 315)
                })
            end
        end
    else
        return
    end
end

local function moveLummaToZainab()
    local player = tes3.player
    local playerCell = player.cell and player.cell.name or ""

    local FF_Natives = tes3.getJournalIndex({ id = "FF_Natives" })
    local Lumma = tes3.getReference("lumma lexius")

    if Lumma.cell == player.cell and FF_Natives == 50 then
        if moveLumma == 1 then
            mwse.log("Lumma has already moved, skipping.")
        elseif FF_Natives == 50 then
            tes3.fadeTo({})

            timer.start({
                duration = 1.0,
                callback = function()
                    tes3.positionCell({ 
                        reference = Lumma, 
                        cell = "Zainab Camp", 
                        position = {75960, 86364, 866}, 
                        orientation = tes3vector3.new(0, 0, 315)
                    })
                    tes3.setAIWander({ 
                        reference = Lumma, 
                        idles = {60, 20, 10, 10, 0, 0, 0, 0}, 
                        range = 0, 
                        duration = 5, 
                        time = 0 
                    })
                    tes3.fadeIn({})
                end
            })

            moveLumma = 1
            lummaMovedDay = tes3.getGlobal("daysPassed")
            mwse.log("Lumma moved to Zainab Camp on day " .. lummaMovedDay)
            saveConfig()
        end
    end
end

local function moveLummaBack()
    local player = tes3.player
    local Lumma = tes3.getReference("lumma lexius")
    if not Lumma then return end
        if Lumma.cell == player.cell then
            return
        elseif player.cell and player.cell.id == "Pelagiad, Hillflower Manor" then
            tes3.fadeTo({})
            timer.start({
                duration = 1.0,
                callback = function()
                    tes3.positionCell({ 
                        reference = Lumma, 
                        cell = "Pelagiad, Hillflower Manor", -- original cell, change if needed
                        position = {-38, 308, -135},       -- original position
                        orientation = tes3vector3.new(0, 0, 315)          -- original orientation
                    })
                    tes3.setAIWander({ 
                        reference = Lumma, 
                        idles = {60, 20, 10, 10, 0, 0, 0, 0}, 
                        range = 256, 
                        duration = 5, 
                        time = 0 
                    })
                    tes3.fadeIn({})
                end
            })
            tes3.setJournalIndex({ id = "FF_Natives", index = 55 })
            tes3.messageBox({ message = "I should return to Pelagiad and speak with Lumma Lexius." })
            lummaMovedDay = nil
            moveLumma = 0
            mwse.log("Lumma returned.")
            saveConfig()
        else
            timer.start({
                duration = 1.0,
                callback = function()
                    tes3.positionCell({ 
                        reference = Lumma, 
                        cell = "Pelagiad, Hillflower Manor", -- original cell, change if needed
                        position = {-38, 308, -135},       -- original position
                        orientation = tes3vector3.new(0, 0, 315)          -- original orientation
                    })
                    tes3.setAIWander({ 
                        reference = Lumma, 
                        idles = {60, 20, 10, 10, 0, 0, 0, 0}, 
                        range = 256, 
                        duration = 5, 
                        time = 0 
                    })
                end
            })
            tes3.setJournalIndex({ id = "FF_Natives", index = 55 })
            tes3.messageBox({ message = "I should return to Pelagiad and speak with Lumma Lexius." })
            lummaMovedDay = nil
            moveLumma = 0
            mwse.log("Lumma returned.")
            saveConfig()
        end
    end

event.register("simulate", function(e)
    updatePicksManyFlowerState()
    updateManaibaState()
    updatelummalexiusState()
    moveLummaToZainab()
    if moveLumma == 1 and lummaMovedDay then
        local currentDay = tes3.getGlobal("daysPassed")
        if currentDay - lummaMovedDay >= 14 then
            moveLummaBack()
        end
    end
end)