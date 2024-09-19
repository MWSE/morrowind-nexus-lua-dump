local interop = require("mer.characterBackgrounds.interop")
local common = require("mer.characterBackgrounds.common")
local logger = common.createLogger("Child of Nature")

local onCellChanged
local background = interop.addBackground{
    id = "childOfNature",
    name = "Child of Nature",
    description = (
        "You feel most at home out in the wilderness, as far from other people as possible. " ..
        "You get +5 to all skills while outdoors in the wild, and -5 to all skills while " ..
        "in civilisation (towns, settlements etc). "
    ),
    onLoad = function()
        onCellChanged{ cell = tes3.getPlayerCell()}
    end
}
if not background then return end

local function modSkills(value)
    logger:debug("Modding skills by %s", value)
    for _, skill in pairs(tes3.skill) do
        tes3.modStatistic{
            reference = tes3.player,
            skill = skill,
            value = value
        }
    end
end

local function inWilderness()
    local cell = tes3.getPlayerCell()
    if cell.isInterior then return false end
    if cell.restingIsIllegal then return false end
    return true
end

onCellChanged = function(e)
    if interop.isActive("childOfNature") then
        logger:debug("Cell Changed")
        if inWilderness() then
            logger:debug("- Not in town")
            if background.data.debuffed then
                logger:debug("- Removing debuff")
                background.data.debuffed = false
                modSkills(5)
            end
            if not background.data.buffed then
                logger:debug("- Adding buff")
                background.data.buffed = true
                modSkills(5)
            end
        else
            logger:debug("- In town")
            if background.data.buffed then
                logger:debug("- Removing buff")
                background.data.buffed = false
                modSkills(-5)
            end
            if not background.data.debuffed then
                logger:debug("- Adding debuff")
                background.data.debuffed = true
                modSkills(-5)
            end
        end
    else --Background not selected, remove any effects
        if background.data.debuffed then
            logger:debug("- No longer active, removing debuff")
            background.data.debuffed = false
            modSkills(5)
        end
        if background.data.buffed then
            logger:debug("- No longer active, removing buff")
            background.data.buffed = false
            modSkills(-5)
        end
    end
end

event.register("cellChanged", onCellChanged)

