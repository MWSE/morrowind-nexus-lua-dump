local activeeffects = {}
local secs = 0

local schooltoskill = {
    [tes3.magicSchool.alteration] = tes3.skill.alteration,
    [tes3.magicSchool.conjuration] = tes3.skill.conjuration,
    [tes3.magicSchool.destruction] = tes3.skill.destruction,
    [tes3.magicSchool.illusion] = tes3.skill.illusion,
    [tes3.magicSchool.mysticism] = tes3.skill.mysticism,
    [tes3.magicSchool.restoration] = tes3.skill.restoration
}

local function fatigue()
    local player = tes3.mobilePlayer
    if not player then return nil end

    local c = player.fatigue.current
    local b = player.fatigue.base

    if b <= 0 then return 0 end

    return math.max(0, c) / b
end

local function att()
    local player = tes3.mobilePlayer
    if not player then return nil end

    return {
        i = player.intelligence.current,
        w = player.willpower.current,
        l = player.luck.current,
        e = player.endurance.current
    }
end

local function clock()
    return secs
end

local function curva2(x, res, maxduration, power)
    if x < 0 then
        x = 0
    end

    local a = res 
    local value = a - a * (x / maxduration)^power
    
    return value
end

local function summc()
    local summ = 0
    local curenttime = clock()

    for i = #activeeffects, 1, -1 do
        local effect = activeeffects[i]
        local x = curenttime - effect.starttime

        if x >= effect.maxduration then
            table.remove(activeeffects, i)
        else
            local y = curva2(x, effect.res, effect.maxduration, effect.power)
            summ = summ + y
        end
    end

    return summ
end

local function analyzespell(spell, mobile)
    local schoolsfound = {}
    local hasschools = false

    for i = 1, 8 do
        local effect = spell.effects[i]
        if effect and effect.id >= 0 then
            local school = effect.object.school
            if school and schooltoskill[school] then
                schoolsfound[school] = true
                hasschools = true
            end
        end
    end

    if not hasschools then return nil, 0 end

    local maxSkill = -1
    local minSkill = 9999
    local bestSchool = nil

    for schoolId, _ in pairs(schoolsfound) do
        local skillId = schooltoskill[schoolId]
        local skillValue = mobile:getSkillValue(skillId) or 0

        if skillValue > maxSkill then
            maxSkill = skillValue
            bestSchool = schoolId
        end
        if skillValue < minSkill then
            minSkill = skillValue
        end
    end

    local diff = maxSkill - minSkill

    return bestSchool, diff
end

local function neweffect(id)
    local player = tes3.player
    local mobile = player.mobile
    if not player or not mobile or not player.object or not player.object.class then return end

    local atts = att()
    if not atts then return end

    local Id = schooltoskill[id]
    local skillvalue = mobile:getSkillValue(Id) or 0

    local spec = player.object.class.specialization
    if not spec then return end

    local w = atts.w
    local l = atts.l
    local e = atts.e

    local res = 0

    if spec == tes3.specialization.magic then
        res = 6 * (2 - (skillvalue * 0.3 + w * 0.5 + e * 0.45 + l * 0.3) / 155)
    elseif spec == tes3.specialization.stealth then
        res = 6 * (2.125 - (skillvalue * 0.2 + w * 0.4 + e * 0.35 + l * 0.6) / 155)
    elseif spec == tes3.specialization.combat then
        res = 6 * (2.333 - (skillvalue * 0.1 + w * 0.3 + e * 0.25 + l * 0.9) / 155)
    end

    local par = (spec == tes3.specialization.magic and { dur = 7.15, pow = 2.75 }) or
                (spec == tes3.specialization.stealth and { dur = 7.5, pow = 3.33 }) or
                (spec == tes3.specialization.combat and { dur = 8, pow = 3.66 })

    if not par then return end

    table.insert(activeeffects, {
        starttime = secs,
        maxduration = par.dur,
        power = par.pow,
        res = res
    })
end

local function formul_of_curva(spellcost, best, schooldiff)
    local player = tes3.player
    local mobile = player.mobile
    if not player or not mobile then return 0 end

    local atts = att()
    if not atts then return 0 end

    local f = fatigue()
    if not f then return 0 end

    local summ = summc()

    local i = atts.i
    local w = atts.w
    local e = atts.e

    local skillId = schooltoskill[best]
    local skillvalue = mobile:getSkillValue(skillId) or 0

    local base = 60 * (((skillvalue * 0.95 + w * 0.45 + i * 0.5 + e * 0.1) / 200) * (0.05 + f * 0.95))

    local multifruct = 0
    if schooldiff > 0 then
        multifruct = 60 * ((schooldiff / 120) ^ 0.875)
    end

    local abc = math.max(0, base - multifruct - summ)

    local bs = mobile.birthsign
    if bs and bs.id == "Wombburned" then
        abc = abc * 0.6
    end

    local res = ((spellcost / 100) * 60) * (abc / 60) ^ (1 / 2.25)

    return math.floor(res + 0.5)
end

local function castfail(e)
    local player = tes3.player
    if not player then return end

    local mobile = player.mobile

    if not e or (e.caster ~= player and e.caster ~= mobile) then return end

    local spell = e.source or e.spell
    if not spell or not spell.magickaCost or spell.magickaCost <= 0 then return end

    local best, diff = analyzespell(spell, mobile)
    if not best then return end

    local cost = spell.magickaCost
    local calc = formul_of_curva(cost, best, diff)

    neweffect(best)

    if calc > 0 then
        tes3.modStatistic({
            reference = player,
            name = "magicka",
            current = calc
        })
        tes3.messageBox("Refunded %d of %d spell cost.", calc, cost)
    end
end

event.register(tes3.event.spellCastedFailure, castfail)

event.register(tes3.event.simulate, function(e)
    secs = secs + e.delta
end)

event.register(tes3.event.loaded, function()
    activeeffects = {}
    secs = 0
end)
-- by Olya F.