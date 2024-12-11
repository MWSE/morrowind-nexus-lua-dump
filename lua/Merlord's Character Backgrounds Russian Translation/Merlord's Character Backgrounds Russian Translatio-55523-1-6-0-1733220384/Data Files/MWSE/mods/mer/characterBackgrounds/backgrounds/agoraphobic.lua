local interop = require("mer.characterBackgrounds.interop")
local common = require("mer.characterBackgrounds.common")
local logger = common.createLogger("Agoraphobic")

local toggleStats
local background = interop.addBackground{
    id = "agoraphobic",
    name = "Агорафоб",
    description = (
        "Вы боитесь открытых пространств. Находясь под открытым небом, вы получаете " ..
        "-5 ко всем навыкам. Будучи под крышей, вы получаете +5 ко всем навыкам. "
    ),
    defaultData = {
        buffed = false,
        debuffed = false
    },
    doOnce = toggleStats
}
if not background then return end

---Modifies all skills by the given value
local function modSkills(value)
    for _, skill in pairs(tes3.skill) do
        tes3.modStatistic({
            reference = tes3.player,
            skill = skill,
            value = value
        })
    end
end

---Returns true if the player is outdoors
local function isOutdoors()
    return tes3.player.cell.isOrBehavesAsExterior
end

toggleStats = function()
    if background:isActive() then
        if isOutdoors() then
            --remove buff
            if background.data.buffed then
                background.data.buffed = false
                modSkills(-5)
            end
            --add debuff
            if not background.data.debuffed then
                background.data.debuffed = true
                modSkills(-5)
            end
        else
            --remove debuff
            if background.data.debuffed then
                background.data.debuffed = false
                modSkills(5)
            end
            --add buff
            if not background.data.buffed then
                background.data.buffed = true
                modSkills(5)
            end
        end
    else --Background not selected, remove any effects
        --remove debuff
        if background.data then
            if background.data.debuffed then
                logger:debug("- No longer active, removing debuff")
                background.data.debuffed = false
                modSkills(5)
            end
            --remove buff
            if background.data.buffed then
                logger:debug("- No longer active, removing buff")
                background.data.buffed = false
                modSkills(-5)
            end
        end
    end
end

event.register("cellChanged", toggleStats)