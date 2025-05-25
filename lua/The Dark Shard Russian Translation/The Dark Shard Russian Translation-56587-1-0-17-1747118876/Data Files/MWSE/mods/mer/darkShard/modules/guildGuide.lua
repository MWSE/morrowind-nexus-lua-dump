local common = require("mer.darkShard.common")
local logger = common.createLogger("guildGuide")
local Quest = require("mer.darkShard.components.Quest")
local Teleporter = require("mer.darkShard.components.Teleporter")
local Scream = require("mer.darkShard.components.Scream")
local CometEffect = require("mer.darkShard.components.CometEffect")

local function getRandomChar(capital)
    local russianLetters = {'а','б','в','г','д','е','ж','з','и','й','к','л','м','н','о','п','р','с','т','у','ф','х','ц','ч','ш','щ','ъ','ы','ь','э','ю','я'}
    local russianCapitals = {'А','Б','В','Г','Д','Е','Ж','З','И','К','Л','М','Н','О','П','Р','С','Т','У','Ф','Х','Ц','Ч','Ш','Щ','Ы','Э','Ю','Я'}
    if capital then
        return russianCapitals[math.random(#russianCapitals)]
    else
        return russianLetters[math.random(#russianLetters)]
    end
end

local function generateRandomText(length, capitalCase)
    local text = ""
    for i=1, length do
        text = text .. getRandomChar(capitalCase and i == 1)
    end
    return text
end


local function getRandomMessage(lastWord)
    return string.format("%s, %s %s - %s",
        generateRandomText(8, true),
        generateRandomText(7, true),
        generateRandomText(5, true),
        lastWord)
end

---@param e uiActivatedEventData
event.register(tes3.event.uiActivated, function(e)
    local mainQuest = Quest.quests.afq_main
    local atToShardStage = mainQuest:isAfter(mainQuest.stages.toShard)
    if mainQuest:isFinished() then
        logger:debug("Main quest already finished")
        return
    end

    local nightCondition = CometEffect.conditions.isNightTime
    if nightCondition.getEffectStrength() <= 0 and not atToShardStage then
        logger:debug("Not night time")
        return
    end

    if not tes3.player.cell.isInterior then
        logger:debug("Not in interior, wrong travel service")
        return
    end

    logger:debug("Adding strange text to travel service menu")
    local menu = e.element
    local list = menu:findChild("MenuServiceTravel_ServiceList")

    --Get last word from previous element label
    local lastWord = list:getContentElement().children[#list.children].children[1].text:match("(%d+зол)%s*$")

    local labelText
    if atToShardStage then
        labelText = "Темный осколок - 0зол"
    else
        labelText = getRandomMessage(lastWord)
    end

    local block = list:createBlock{ id = "DarkShard:StrangeText_block"}
    block.autoHeight = true
    block.autoWidth = true
    local label = block:createTextSelect{ id = "DarkShard:StrangeText_label", text = labelText}
    label.borderAllSides = 0
    label.width = 231
    label.height = 18
    --label.font = 2

    label:register("mouseClick", function()
        logger:debug("Teleporting to destination")
        menu:destroy()
        tes3ui.leaveMenuMode()

        local dialogMenu = tes3ui.findMenu("MenuDialog")
        if dialogMenu then
            dialogMenu:destroy()
        end

        timer.delayOneFrame(function()
            local destination
            if atToShardStage then
                destination = {
                    id = "DarkShard",
                    position = tes3vector3.new(-11, -3849, 2059),
                    orientation = tes3vector3.new(0, 0, math.rad(23)),
                    cell = "Dark Shard",
                }
            end
            tes3.saveGame({ file = "autosave" })
            Teleporter.teleportToDestination{
                forceAirborn = not atToShardStage,
                destination = destination,
                callback = function()
                    tes3ui.leaveMenuMode()
                    tes3.worldController.weatherController:switchImmediate(tes3.weather.clear)
                    Quest.quests.afq_main:advance()
                    tes3.addTopic{ topic = "смертельное падение"}
                    timer.start{
                        duration = 0.2,
                        callback = function()
                            local dialogMenu = tes3ui.findMenu("MenuDialog")
                            if dialogMenu then
                                dialogMenu:destroy()
                            end
                            if not atToShardStage then
                                Scream.play()
                            end
                        end
                    }
                end
            }
        end)
    end)

    list.widget:contentsChanged()
    --menu:updateLayout()

end, { filter = "MenuServiceTravel"})