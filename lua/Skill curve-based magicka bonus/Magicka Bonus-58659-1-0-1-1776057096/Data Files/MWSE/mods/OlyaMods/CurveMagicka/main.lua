local SPELL_ID = "magica_sum_bonus"

local function skills_sum_of_dear_player()
    local player = tes3.mobilePlayer
    if not player then return 0 end

    local skills = {
        tes3.skill.alteration,
        tes3.skill.conjuration,
        tes3.skill.destruction,
        tes3.skill.illusion,
        tes3.skill.mysticism,
        tes3.skill.restoration
    }

    local summ = 0
    for _, id in ipairs(skills) do
        summ = summ + player:getSkillValue(id)
    end

    return summ
end

local function bonus_calc()
    local player = tes3.player
    if not player or not player.object or not player.object.class then return 0 end

    local Summ = skills_sum_of_dear_player()
    local res = 0
    local SpEc = player.object.class.specialization

    if SpEc == tes3.specialization.magic then
        res = 520 * (Summ / 600) ^ 1.2
    elseif SpEc == tes3.specialization.stealth then
        res = 500 * (Summ / 600) ^ 1.45
    elseif SpEc == tes3.specialization.combat then
        res = 460 * (Summ / 600) ^ 2.10
    end

    return math.floor(res)
end

local function createpassivespell()
    local spell = tes3.getObject(SPELL_ID)
    if spell then return spell end

    spell = tes3.createObject({
        objectType = tes3.objectType.spell,
        id = SPELL_ID,
        name = "Magicka bonus for your skills",
        castType = tes3.spellType.ability
    })

    local effect = spell.effects[1]
    effect.id = tes3.effect.fortifyMagicka
    effect.min = 0
    effect.max = 0
    effect.duration = 0
    effect.radius = 0

    return spell
end

local function f1()
    local player = tes3.player
    if not player then return player end

    local spelll = createpassivespell()
    if not spelll then return spelll end

    if tes3.hasSpell({ reference = player, spell = spelll }) then
        tes3.removeSpell({ reference = player, spell = spelll })
    end
end

local function f2()
    local spelll = createpassivespell()
    if not spelll then return spelll end

    local power = bonus_calc()
    local effect = spelll.effects[1]

    effect.min = power
    effect.max = power
end

local function f3()
    local player = tes3.player
    if not player then return player end

    local spelll = createpassivespell()
    if not spelll then return spelll end

    if not tes3.hasSpell({ reference = player, spell = spelll }) then
        tes3.addSpell({ reference = player, spell = spelll })
    end
end

local function holytimer()
    timer.start({
        type = timer.simulate,
        duration = 0.03,
        callback = function()
            f1()
            timer.start({
                type = timer.simulate,
                duration = 0.03,
                callback = function()
                    f2()
                    timer.start({
                        type = timer.simulate,
                        duration = 0.03,
                        callback = function()
                            f3()
                        end
                    })
                end
            })
        end
    })
end -- xD

local lastskillsum = 0

local function changes()
    local currentSum = skills_sum_of_dear_player()
    if currentSum ~= lastskillsum then
        lastskillsum = currentSum
        holytimer()
    end
end

local magic_skills = {
    [tes3.skill.alteration] = true, 
    [tes3.skill.conjuration] = true,
    [tes3.skill.destruction] = true, 
    [tes3.skill.illusion] = true,
    [tes3.skill.mysticism] = true, 
    [tes3.skill.restoration] = true
}

event.register("initialized", function()
   createpassivespell()
end)

local skills_timer

event.register("loaded", function()
    if skills_timer then
        skills_timer:cancel()
    end

    local player = tes3.player
    if not player then return player end

    local mobile = player.mobile

    local spelll = createpassivespell()
    if not spelll then return spelll end

    local power = bonus_calc()
    local mpB = mobile.magicka.base
    local mpC = mobile.magicka.current
    local correctMP = 0

    local correctMP = mpB + power
    local percent = mpC / mpB

    if tes3.hasSpell({ reference = player, spell = spelll }) then
        tes3.setStatistic({
            reference = player,
            name = "magicka",
            base = correctMP
        })
    end

    mobile.magicka.current = correctMP * percent

    timer.start({
        type = timer.real,
        duration = 0.001,
        callback = function()
            timer.start({
                type = timer.real,
                duration = 0.001,
                callback = function()
                    holytimer()
                end
            })
        end
    })

    skills_timer = timer.start({
        iterations = -1,
        duration = 0.5,
        callback = function()
            changes()
        end
    })
end)

event.register("menuExit", function()
    changes()
end)

event.register("skillRaised", function(e)
    if magic_skills[e.skill] then
        changes()
    end
end)

event.register("journal", function(e)
    if e.topic.id == "A1_1_FindSpymaster" and e.index == 1 then
        timer.start({
            type = timer.simulate,
            duration = 2.5,
            callback = function()
                holytimer()
                timer.start({
                    type = timer.simulate,
                    duration = 2.5,
                    callback = function()
                        holytimer()
                    end
                })
            end
        })
    end
end)
-- by Olya F.