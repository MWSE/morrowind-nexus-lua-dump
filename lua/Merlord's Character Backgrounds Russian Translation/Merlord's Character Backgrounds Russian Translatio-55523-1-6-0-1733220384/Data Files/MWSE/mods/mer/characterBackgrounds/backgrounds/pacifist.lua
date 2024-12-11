local pacifistAmount = 5
return {
    id = "pacifist",
    name = "Пацифист",
    description = (
       "Вы посвятили свою жизнь установлению мира. Вы получаете -".. pacifistAmount..
       " ко всем боевым навыкам и +"..pacifistAmount.." ко всем прочим."
    ),
    doOnce = function()
        local combatSkills = {
            tes3.skill.axe,
            tes3.skill.block,
            tes3.skill.bluntWeapon,
            tes3.skill.conjuration,
            tes3.skill.destruction,
            tes3.skill.handToHand,
            tes3.skill.heavyArmor,
            tes3.skill.lightArmor,
            tes3.skill.longBlade,
            tes3.skill.marksman,
            tes3.skill.mediumArmor,
            tes3.skill.shortBlade,
            tes3.skill.spear,
        }
        local passiveSkills = {
            tes3.skill.acrobatics,
            tes3.skill.alchemy,
            tes3.skill.alteration,
            tes3.skill.armorer,
            tes3.skill.athletics,
            tes3.skill.enchant,
            tes3.skill.illusion,
            tes3.skill.mercantile,
            tes3.skill.mysticism,
            tes3.skill.restoration,
            tes3.skill.security,
            tes3.skill.sneak,
            tes3.skill.speechcraft,
            tes3.skill.unarmored,
        }
        for _, skill in ipairs(combatSkills) do
            tes3.modStatistic({
                reference = tes3.player,
                skill = skill,
                value = -pacifistAmount
            })
        end
        for _, skill in ipairs(passiveSkills) do
            tes3.modStatistic({
                reference = tes3.player,
                skill = skill,
                value = pacifistAmount
            })
        end
    end
}