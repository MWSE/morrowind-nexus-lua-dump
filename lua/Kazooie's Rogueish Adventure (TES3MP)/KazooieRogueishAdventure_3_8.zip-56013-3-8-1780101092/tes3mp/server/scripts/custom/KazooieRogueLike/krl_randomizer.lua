local function convert_to_array(stringOrArray)
    local array = stringOrArray

    if type(array) == "string" then
        array = krl_split(stringOrArray, "[^%s%p]+")
    end

    return krl_array(array).shallow_copy()
end

local function randomize_skills(pid, playerClass)
    local minorSkills = convert_to_array(playerClass.minorSkills)
    local majorSkills = convert_to_array(playerClass.majorSkills)

    local skill_names = {}

    for skill_name, _ in pairs(Players[pid].data.skills) do
        table.insert(skill_names, skill_name)
    end

    local random_skill_list = {}

    for skill_name, skill in pairs(Players[pid].data.skills) do
        local increased_skill = krl_array(skill).shallow_copy()
        increased_skill.base = increased_skill.base + 5

        table.insert(random_skill_list, {
            was_minor = krl_array(minorSkills).has(skill_name),
            was_major = krl_array(majorSkills).has(skill_name),
            skill = increased_skill
        })
    end

    local shuffled_skills = krl_array(random_skill_list).shuffle()
    local newMajorSkills = ""
    local newMinorSkills = ""

    for i, skill_name in pairs(skill_names) do
        local random_skill = shuffled_skills[i]
        Players[pid].data.skills[skill_name] = random_skill.skill

        if random_skill.was_major then
            newMajorSkills = newMajorSkills..skill_name..", "
        elseif random_skill.was_minor then
            newMinorSkills = newMinorSkills..skill_name..", "
        end
    end

    Players[pid].data.customClass.minorSkills = string.sub(newMinorSkills, 1, #newMinorSkills - 2)
    Players[pid].data.customClass.majorSkills = string.sub(newMajorSkills, 1, #newMajorSkills - 2)
end

local function randomize_attributes(pid, playerClass)
    local majorAttributes = convert_to_array(playerClass.majorAttributes)

    local attribute_names = {}

    for attribute_name, _ in pairs(Players[pid].data.attributes) do
        table.insert(attribute_names, attribute_name)
    end

    local random_attribute_list = {}

    for attribute_name, attribute in pairs(Players[pid].data.attributes) do
        local increased_attribute = krl_array(attribute).shallow_copy()
        increased_attribute.base = increased_attribute.base + 5

        table.insert(random_attribute_list, {
            was_major = krl_array(majorAttributes).has(attribute_name),
            attribute = increased_attribute
        })
    end

    local shuffled_attributes = krl_array(random_attribute_list).shuffle()
    local newMajorAttributes = ""

    for i, attribute_name in pairs(attribute_names) do
        local random_attribute = shuffled_attributes[i]
        Players[pid].data.attributes[attribute_name] = random_attribute.attribute

        if random_attribute.was_major then
            newMajorAttributes = newMajorAttributes..attribute_name..", "
        end
    end

    Players[pid].data.customClass.majorAttributes = string.sub(newMajorAttributes, 1, #newMajorAttributes - 2)
end

function KRL_RandomizeSkills(pid)
    local playerClass = KRL_GetPlayerClass(pid)

    if not Players[pid].data.customClass or not Players[pid].data.customClass.name then
        Players[pid].data.customClass = {
            name = "Random",
            specialization = playerClass.specialization,
            description = "Randomly generated class."
        }

        Players[pid].data.character.class = "custom"
    end

    randomize_skills(pid, playerClass)
    randomize_attributes(pid, playerClass)
end

function KRL_MinmaxSkills(pid)
    local playerClass = KRL_GetPlayerClass(pid)
    local majorSkills = convert_to_array(playerClass.majorSkills)
    local minorSkills = convert_to_array(playerClass.minorSkills)

    for skill_name, skill in pairs(Players[pid].data.skills) do
        local skill_id = tes3mp.GetSkillId(skill_name)
        local skill_base = tes3mp.GetSkillBase(pid, skill_id)
        local new_value = 0

        if krl_array(majorSkills).has(skill_name) then
            new_value = skill_base + 3
        elseif krl_array(minorSkills).has(skill_name) then
            new_value = skill_base - 3
        end

        tes3mp.SetSkillBase(pid, skill_id, new_value)
    end

    tes3mp.SendSkills(pid)
end
