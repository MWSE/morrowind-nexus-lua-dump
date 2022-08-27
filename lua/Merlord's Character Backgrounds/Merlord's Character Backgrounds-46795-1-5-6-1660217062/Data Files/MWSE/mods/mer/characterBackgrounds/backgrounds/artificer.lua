local config = require('mer.characterBackgrounds.config')

local getData = function()
    local data = tes3.player.data.merBackgrounds
    return data
end

return {
    id = "artificer",
    name = "Artificer",
    description = (
        "You can sense the inner most magical properties within any object, " ..
        "giving you an innate aptitude for enchanting (+50 Enchanting). " ..
        "However, this seems to be your only outlet for magic, as you are utterly " ..
        "incapable of casting spells. "
    ),
    doOnce = function()
        tes3.modStatistic({
            reference = tes3.player,
            skill = tes3.skill.enchant,
            value = 50
        })
    end,
    callback = function()
        local function spellCast(e)
            local data = getData()
            if data.currentBackground == "artificer" then
                if e.caster == tes3.player then
                    local allowedSpells = config.exclusions
                    if not allowedSpells[e.source.name] then
                        e.castChance = 0
                    end
                end
            end
        end

        event.unregister("spellCast", spellCast)
        event.register("spellCast", spellCast)
    end
}