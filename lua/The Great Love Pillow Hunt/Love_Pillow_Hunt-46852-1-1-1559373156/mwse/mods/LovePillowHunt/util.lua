local util = {}

--MessageBox where each button can be assign its own callback
function util.messageBox(params)
    --[[
        message = ""
        Button = { text, callback }
    ]]
    local message = params.message
    local buttons = params.buttons

    local function callback(e)
        --get button from 0-indexed MW param
        local button = buttons[e.button + 1]
        if button.callback then
            timer.delayOneFrame(
                function()
                    button.callback()
                end
            )
        end
    end

    --Make list of strings to insert into buttons
    local buttonStrings = {}
    for _, button in ipairs(buttons) do
        table.insert(buttonStrings, button.text)
    end

    tes3.messageBox(
        {
            message = message,
            buttons = buttonStrings,
            callback = callback
        }
    )
end

function util.hourToString(time)
    local gameTime = time or tes3.getGlobal('GameHour')
    local formattedTime

    local isPM = false
    if gameTime > 12 then
        isPM = true
        gameTime = gameTime - 12
    end

    local hourString
    if gameTime < 10 then
        hourString = string.sub(gameTime, 1, 1)
    else
        hourString = string.sub(gameTime, 1, 2)
    end

    local minuteTime = (gameTime - hourString) * 60
    local minuteString
    if minuteTime < 10 then
        minuteString = string.sub(minuteTime, 1, 1)
    else
        minuteString = string.sub(minuteTime, 1, 2)
    end
    formattedTime = string.format('%d hours %d minutes remaining', hoursString, minuteString)
    return formattedTime
end

--Fades out, passes time then runs callback when finished
function util.fadeTimeOut(hoursPassed, secondsTaken, callback)
    local function fadeTimeIn()
        tes3.runLegacyScript({command = 'EnablePlayerControls'})
        callback()
    end

    tes3.fadeOut({duration = 0.5})
    tes3.runLegacyScript({command = 'DisablePlayerControls'})
    --Halfway through, advance gamehour
    local iterations = 10
    timer.start(
        {
            type = timer.real,
            iterations = iterations,
            duration = (secondsTaken / iterations),
            callback = (function()
                local gameHour = tes3.findGlobal('gameHour')
                gameHour.value = gameHour.value + (hoursPassed / iterations)
            end)
        }
    )
    --All the way through, fade back in
    timer.start(
        {
            type = timer.real,
            iterations = 1,
            duration = secondsTaken,
            callback = (function()
                local fadeBackTime = 1
                tes3.fadeIn({duration = fadeBackTime})
                timer.start(
                    {
                        type = timer.real,
                        iterations = 1,
                        duration = fadeBackTime,
                        callback = fadeTimeIn
                    }
                )
            end)
        }
    )
end

--Get current time in hours
function util.getNow()
    return (tes3.worldController.daysPassed.value * 24) + tes3.worldController.hour.value
end

--Check if the reference is underwater
function util.getUnderWater(reference)
    local cell = tes3.getPlayerCell()
    if cell.hasWater then
        local waterLevel = cell.waterLevel or 0
        local itemLevel = reference.position.z
        if itemLevel < waterLevel then
            return true
        end
    end
    return false
end

--Recursively prints the children of an element to the logs
local tabCount = tabCount or 0
function util.printElementTree(e)
    tabCount = tabCount + 1
    for i = 1, #e.children do
        local child = e.children[i]
        local printString = ''
        for i = 1, tabCount do
            printString = '  ' .. printString
        end
        printString = printString .. '- ' .. child.name .. ', ID: ' .. child.id
        mwse.log(printString)
        printElementTree(child)
        tabCount = tabCount - 1
    end
end

return util
