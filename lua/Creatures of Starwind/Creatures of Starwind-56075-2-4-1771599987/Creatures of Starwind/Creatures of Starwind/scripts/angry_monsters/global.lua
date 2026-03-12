local Creature = require('openmw.types').Creature

local manHuntingCreatures = {
        ['guar'] = true,
['sw_sandmagone'] = true,
['t_mw_fau_yethbug_01'] = true,
['t_mw_fau_tigguar_01'] = true,
['cos_kathhound'] = true,
['t_sky_fau_raki_01'] = true,
['sw_kathhound'] = true,
['t_sky_fau_danswyrm_01'] = true,
['sw_kraytlesser'] = true,
['t_mw_fau_skrend_01'] = true,
['t_mw_fau_skylamp_01'] = true,
['sw_cancellcr'] = true,
['sw_mykal'] = true,
['sw_wyyyschokk'] = true,
['sw_kinrath'] = true,
['sw_wyyyschokkdropdown'] = true,
['sw_rakhoul1'] = true,
['sw_rakhoul6'] = true,
['sw_rakhoulpretarisb2'] = true,
['sw_rakhoultaris'] = true,
['sw_rakhoulul'] = true,
['sw_rakhoulship'] = true,

}

return {
    engineHandlers = {
        onActorActive = function(actor)
            if actor.type == Creature and manHuntingCreatures[string.lower(actor.recordId)] then
                actor:addScript('scripts/angry_monsters/man_hunting.lua')
            end
        end,
    },
}
