do return end
local content = require('openmw.content')
local core = require('openmw.core')

-- not available: types, 
-- lua can not even be reloaded in the main menu

if content.spells then
content.spells.records.MySpell = {
    name = 'SD_ArcaneIntelligence',
    type = content.spells.TYPE.Spell,
    cost = 1,
    starterSpellFlag = true,
    isAutocalc = true,
    effects = {
        {
            id = 'FortifyAttribute',
            affectedAttribute = 'intelligence',
            duration = 1800,
            magnitudeMin = 5,
            magnitudeMax = 5,
        }
    },
}
end