local ChargenMenu = require("mer.chargenScenarios.component.ChargenMenu")
local upbringing = require("ring.DaggerfallStyleBackgrounds.upbringing")
local ui = require("ring.DaggerfallStyleBackgrounds.ui")
local data

-- ChargenScenarios

local function onStart()
    data = upbringing.initData()
    tes3.player.data.Upbringing = upbringing.current
    tes3.player.data.knownNPCs = {}
    for _,bonus in ipairs(data.environment.options[tes3.player.data.Upbringing.environment.name].bonuses) do
        tes3.setStatistic({
            reference = tes3.mobilePlayer,
            attribute = bonus.attribute,
            base = tes3.mobilePlayer.attributes[bonus.attribute+1].base + bonus.value
        })
    end
    tes3.setStatistic({
        reference = tes3.mobilePlayer,
        skill = tes3.player.data.Upbringing.majorSkill.value,
        base = tes3.mobilePlayer.skills[upbringing.current.majorSkill.value+1].base + 5
    })
    if tes3.player.data.Upbringing.socialClass.value ~= 0 then
        tes3.addItem{
            reference = tes3.mobilePlayer,
            item = "gold_001",
            count = tes3.player.data.Upbringing.socialClass.value
        }
    end
    local fatherRaceObject = tes3.findRace(upbringing.current.fatherRace.value)
    ---@cast fatherRaceObject tes3race
    local validAttributes = {}
    for i,bonus in ipairs(fatherRaceObject.baseAttributes) do
        if bonus.male >= 50 then
            validAttributes[i] = true
        else
            validAttributes[i] = false
        end
    end
    local loop = true
    local attribute
    local skill
    while loop do
        local roll = math.random(#fatherRaceObject.baseAttributes+1)
        if validAttributes[roll] == true then
            tes3.setStatistic({
                reference = tes3.mobilePlayer,
                attribute = roll,
                base = tes3.mobilePlayer.attributes[roll].base + 5
            })
            attribute = tes3.attributeName[roll]
            loop = false
        end
    end
    local skillRoll = math.random(#fatherRaceObject.skillBonuses+1)
    tes3.setStatistic({
        reference = tes3.mobilePlayer,
        skill = fatherRaceObject.skillBonuses[skillRoll].skill,
        base = tes3.mobilePlayer.skills[fatherRaceObject.skillBonuses[skillRoll].skill].base + 5
    })
    skill = tes3.getSkillName(fatherRaceObject.skillBonuses[skillRoll].skill)
    tes3.messageBox("Your father was a %s with a natural talent for %s and abnormally high %s.", fatherRaceObject.name, skill, attribute)
    tes3.addJournalEntry{
        text = upbringing.flavorText(true)
    }
end

---@type ChargenScenarios.ChargenMenu.config
local menu = {
    id = "charaterUpbringing",
    name = "Upbringing",
    priority = 101,
    buttonLabel = "Upbringing",
    getButtonValue = function()
        return "Choose"
    end,
    createMenu = function (self)
        ui.createMenu(function () self:okCallback() end)
    end,
    validate = function ()
        return (tes3.player.object.class == upbringing.currentClass) and (tes3.player.object.race == upbringing.currentRace)
    end,
    getTooltip = function()
        return {
            header = "Upbringing",
            description = "Define your character's upbringing."
        }
    end,
    onStart = onStart
}

ChargenMenu.register(menu)

-- Functions

---Open the upbringing menu if the player has not chosen an upbringing yet.
---@param e loadedEventData
local function onLoaded(e)
    if tes3.player.data.Upbringing then
        upbringing.current = tes3.player.data.Upbringing
        upbringing.currentClass = tes3.player.object.class
        upbringing.currentRace = tes3.player.object.race
        return
    end
    if (not e.newGame) and (not tes3.player.data.Upbringing) then
        ui.createMenu(function ()
            tes3ui:leaveMenuMode()
            onStart()
        end)
    end
end

---@param e activateEventData
local function onActivate(e)
    if e.activator ~= tes3.player then return end
    if e.target.objectType ~= tes3.objectType.npc then return end
    if not e.target.data.spokenTo then
        local dispositionMod
        local target = e.target.object
        if target.race.id == upbringing.current.province.value then
            dispositionMod = 10
        elseif target.race.id == upbringing.current.fatherRace.value then
            dispositionMod = 5
        end
        target.baseDisposition = target.baseDisposition + dispositionMod
        e.target.data.spokenTo = true
        tes3.messageBox("[You feel a sense of kinship with %s.]", e.target.object.name)
    end
end

-- Events

event.register(tes3.event.loaded, onLoaded)
event.register(tes3.event.activate, onActivate)