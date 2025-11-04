-- local o = require('scripts.HitKillFeedback.settings').o



-- From: https://lospec.com/palette-list/aap-64

local colors = {
        health = 'df3e23',
        fatigue = '23674e',
        magicka = '249fde',

        fire = 'f9a31b',
        shock = 'fffc40',
        frost = 'e3e6ff',
        poison = '9cdb43',

        miss = 'b3b9d1',
}


local elemental = {
        firedamage = true,
        shockdamage = true,
        frostdamage = true,
        poison = true,
}

-- local effectColor = {
--         firedamage = colors.fire,
--         shockdamage = colors.shock,
--         frostdamage = colors.frost,
--         poison = colors.poison,

--         absorbhealth = colors.health,
--         drainhealth = colors.health,
--         damagehealth = colors.health,

--         absorbmagicka = colors.magicka,
--         drainmagicka = colors.magicka,
--         damagemagicka = colors.magicka,

--         absorbfatigue = colors.fatigue,
--         drainfatigue = colors.fatigue,
--         damagefatigue = colors.fatigue,
-- }

local damageEffects = {

        firedamage = 'firedamage',
        shockdamage = 'shockdamage',
        frostdamage = 'frostdamage',
        poison = 'poison',

        absorbhealth = 'absorbhealth',
        drainhealth = 'drainhealth',
        damagehealth = 'damagehealth',

        absorbmagicka = 'absorbmagicka',
        drainmagicka = 'drainmagicka',
        damagemagicka = 'damagemagicka',

        absorbfatigue = 'absorbfatigue',
        drainfatigue = 'drainfatigue',
        damagefatigue = 'damagefatigue',



        -- drainattribute = 'drainattribute',
        -- drainskill = 'drainskill',
        -- damageattribute = 'damageattribute',
        -- damageskill = 'damageskill',
        -- absorbattribute = 'absorbattribute',
        -- absorbskill = 'absorbskill',


        -- disintegrateweapon = 'disintegrateweapon',
        -- disintegratearmor = 'disintegratearmor',


        --- ###################################################
        --- ###################################################

        -- swiftswim = 'swiftswim',
        -- waterwalking = 'waterwalking',
        -- shield = 'shield',
        -- fireshield = 'fireshield',
        -- lightningshield = 'lightningshield',
        -- frostshield = 'frostshield',
        -- burden = 'burden',
        -- feather = 'feather',
        -- jump = 'jump',
        -- levitate = 'levitate',
        -- slowfall = 'slowfall',
        -- lock = 'lock',
        -- open = 'open',
        -- weaknesstofire = 'weaknesstofire',
        -- weaknesstofrost = 'weaknesstofrost',
        -- weaknesstoshock = 'weaknesstoshock',
        -- weaknesstomagicka = 'weaknesstomagicka',
        -- weaknesstocommondisease = 'weaknesstocommondisease',
        -- weaknesstoblightdisease = 'weaknesstoblightdisease',
        -- weaknesstocorprusdisease = 'weaknesstocorprusdisease',
        -- weaknesstopoison = 'weaknesstopoison',
        -- weaknesstonormalweapons = 'weaknesstonormalweapons',
        -- invisibility = 'invisibility',
        -- chameleon = 'chameleon',
        -- light = 'light',
        -- sanctuary = 'sanctuary',
        -- nighteye = 'nighteye',
        -- charm = 'charm',
        -- paralyze = 'paralyze',
        -- silence = 'silence',
        -- blind = 'blind',
        -- sound = 'sound',
        -- calmhumanoid = 'calmhumanoid',
        -- calmcreature = 'calmcreature',
        -- frenzyhumanoid = 'frenzyhumanoid',
        -- frenzycreature = 'frenzycreature',
        -- demoralizehumanoid = 'demoralizehumanoid',
        -- demoralizecreature = 'demoralizecreature',
        -- rallyhumanoid = 'rallyhumanoid',
        -- rallycreature = 'rallycreature',
        -- dispel = 'dispel',
        -- soultrap = 'soultrap',
        -- telekinesis = 'telekinesis',
        -- mark = 'mark',
        -- recall = 'recall',
        -- divineintervention = 'divineintervention',
        -- almsiviintervention = 'almsiviintervention',
        -- detectanimal = 'detectanimal',
        -- detectenchantment = 'detectenchantment',
        -- detectkey = 'detectkey',
        -- spellabsorption = 'spellabsorption',
        -- reflect = 'reflect',
        -- curecommondisease = 'curecommondisease',
        -- cureblightdisease = 'cureblightdisease',
        -- curecorprusdisease = 'curecorprusdisease',
        -- curepoison = 'curepoison',
        -- cureparalyzation = 'cureparalyzation',
        -- restoreattribute = 'restoreattribute',
        -- restorehealth = 'restorehealth',
        -- restoremagicka = 'restoremagicka',
        -- restorefatigue = 'restorefatigue',
        -- restoreskill = 'restoreskill',
        -- fortifyattribute = 'fortifyattribute',
        -- fortifyhealth = 'fortifyhealth',
        -- fortifymagicka = 'fortifymagicka',
        -- fortifyfatigue = 'fortifyfatigue',
        -- fortifyskill = 'fortifyskill',
        -- fortifymaximummagicka = 'fortifymaximummagicka',
        -- resistfire = 'resistfire',
        -- resistfrost = 'resistfrost',
        -- resistshock = 'resistshock',
        -- resistmagicka = 'resistmagicka',
        -- resistcommondisease = 'resistcommondisease',
        -- resistblightdisease = 'resistblightdisease',
        -- resistcorprusdisease = 'resistcorprusdisease',
        -- resistpoison = 'resistpoison',
        -- resistnormalweapons = 'resistnormalweapons',
        -- resistparalysis = 'resistparalysis',
        -- removecurse = 'removecurse',
        -- turnundead = 'turnundead',
        -- summonscamp = 'summonscamp',
        -- summonclannfear = 'summonclannfear',
        -- summondaedroth = 'summondaedroth',
        -- summondremora = 'summondremora',
        -- summonancestralghost = 'summonancestralghost',
        -- summonskeletalminion = 'summonskeletalminion',
        -- summonbonewalker = 'summonbonewalker',
        -- summongreaterbonewalker = 'summongreaterbonewalker',
        -- summonbonelord = 'summonbonelord',
        -- summonwingedtwilight = 'summonwingedtwilight',
        -- summonhunger = 'summonhunger',
        -- summongoldensaint = 'summongoldensaint',
        -- summonflameatronach = 'summonflameatronach',
        -- summonfrostatronach = 'summonfrostatronach',
        -- summonstormatronach = 'summonstormatronach',
        -- fortifyattack = 'fortifyattack',
        -- commandcreature = 'commandcreature',
        -- commandhumanoid = 'commandhumanoid',
        -- bounddagger = 'bounddagger',
        -- boundlongsword = 'boundlongsword',
        -- boundmace = 'boundmace',
        -- boundbattleaxe = 'boundbattleaxe',
        -- boundspear = 'boundspear',
        -- boundlongbow = 'boundlongbow',
        -- boundcuirass = 'boundcuirass',
        -- boundhelm = 'boundhelm',
        -- boundboots = 'boundboots',
        -- boundshield = 'boundshield',
        -- boundgloves = 'boundgloves',
        -- corprus = 'corprus',
        -- vampirism = 'vampirism',
        -- summoncenturionsphere = 'summoncenturionsphere',
        -- stuntedmagicka = 'stuntedmagicka',
        -- extraspell = 'extraspell', ???
        -- sundamage = 'sundamage', ???

}



local c = {
        damageEffects = damageEffects,
        effectColor = {
                firedamage = colors.fire,
                shockdamage = colors.shock,
                frostdamage = colors.frost,
                poison = colors.poison,

                absorbhealth = colors.health,
                drainhealth = colors.health,
                damagehealth = colors.health,

                absorbmagicka = colors.magicka,
                drainmagicka = colors.magicka,
                damagemagicka = colors.magicka,

                absorbfatigue = colors.fatigue,
                drainfatigue = colors.fatigue,
                damagefatigue = colors.fatigue,

                miss = colors.miss
        },
        -- effectColor = effectColor,
        elemental = elemental,
        -- colors = {},
}

function UpdateColors(settings)
        -- c.colors.fire = '#' .. settings.fireDmgColor.value:asHex()
        -- c.colors.frost = '#' .. settings.frostDmgColor.value:asHex()
        -- c.colors.shock = '#' .. settings.shockDmgColor.value:asHex()
        -- c.colors.poison = '#' .. settings.poisonDmgColor.value:asHex()
        -- c.colors.health = '#' .. settings.healthDmgColor.value:asHex()
        -- c.colors.fatigue = '#' .. settings.fatigueDmgColor.value:asHex()
        -- c.colors.magicka = '#' .. settings.magickaDmgColor.value:asHex()
        -- c.colors.miss = '#' .. settings.missColor.value:asHex()
        local fire = settings.fireDmgColor.value:asHex()
        local frost = settings.frostDmgColor.value:asHex()
        local shock = settings.shockDmgColor.value:asHex()
        local poison = settings.poisonDmgColor.value:asHex()
        local health = settings.healthDmgColor.value:asHex()
        local fatigue = settings.fatigueDmgColor.value:asHex()
        local magicka = settings.magickaDmgColor.value:asHex()
        local miss = settings.missColor.value:asHex()

        c.effectColor = {
                firedamage = fire,
                shockdamage = shock,
                frostdamage = frost,
                poison = poison,
                absorbhealth = health,
                drainhealth = health,
                damagehealth = health,
                absorbmagicka = magicka,
                drainmagicka = magicka,
                damagemagicka = magicka,
                absorbfatigue = fatigue,
                drainfatigue = fatigue,
                damagefatigue = fatigue,
                miss = miss,
        }



        -- print('NEW COLORS: ')
        -- for i, v in pairs(colors) do
        --         print(i, v)
        -- end
end

return { c = c, UpdateColors = UpdateColors }
