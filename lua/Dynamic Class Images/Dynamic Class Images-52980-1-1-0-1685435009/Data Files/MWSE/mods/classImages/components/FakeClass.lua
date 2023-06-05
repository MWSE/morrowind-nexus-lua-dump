
local FakeClass = {}

local function getSkillFromValue(skillName)
    local start = tes3.gmst.sSkillBlock
    local finish = tes3.gmst.sSkillHandtohand
    for i = start, finish, 1 do
        local gmst = tes3.findGMST(i)
        if gmst and gmst.value == skillName then
            return i - start
        end
    end
end

local function getAttributeFromValue(attributeName)
    local start = tes3.gmst.sAttributeStrength
    local finish = tes3.gmst.sAttributeLuck
    for i = start, finish, 1 do
        local gmst = tes3.findGMST(i)
        if gmst and gmst.value == attributeName then
            return i - start
        end
    end
end

local function getSpecialistionFromValue(specName)
    local start = tes3.gmst.sSpecializationCombat
    local finish = tes3.gmst.sSpecializationStealth
    for i = start, finish, 1 do
        local gmst = tes3.findGMST(i)
        if gmst and gmst.value == specName then
            local specialisationIndex = i - start
            return specialisationIndex
        end
    end
end

return function()
    --if custom class menu is open, then get from there, otherwise use player.class
    local createClassMenu = tes3ui.findMenu("MenuCreateClass")
    if createClassMenu and createClassMenu.visible == true then
        ---@type tes3class
        local class = {
            id = "fake_class",
            name = createClassMenu:findChild("MenuCreateClass_NameSpace").text,
            description = "",
            majorSkills  = {
                [1] = getSkillFromValue(createClassMenu:findChild("MenuCreateClass_MajorSkillOne").text),
                [2] = getSkillFromValue(createClassMenu:findChild("MenuCreateClass_MajorSkillTwo").text),
                [3] = getSkillFromValue(createClassMenu:findChild("MenuCreateClass_MajorSkillThree").text),
                [4] = getSkillFromValue(createClassMenu:findChild("MenuCreateClass_MajorSkillFour").text),
                [5] = getSkillFromValue(createClassMenu:findChild("MenuCreateClass_MajorSkillFive").text),
            },
            minorSkills = {
                [1] = getSkillFromValue(createClassMenu:findChild("MenuCreateClass_MinorSkillOne").text),
                [2] = getSkillFromValue(createClassMenu:findChild("MenuCreateClass_MinorSkillTwo").text),
                [3] = getSkillFromValue(createClassMenu:findChild("MenuCreateClass_MinorSkillThree").text),
                [4] = getSkillFromValue(createClassMenu:findChild("MenuCreateClass_MinorSkillFour").text),
                [5] = getSkillFromValue(createClassMenu:findChild("MenuCreateClass_MinorSkillFive").text),
            },
            attributes = {
                [1] = getAttributeFromValue(createClassMenu:findChild("MenuCreateClass_AttributeOne").text),
                [2] = getAttributeFromValue(createClassMenu:findChild("MenuCreateClass_AttributeTwo").text),
            },
            specialization = getSpecialistionFromValue(createClassMenu:findChild("MenuCreateClass_Special").text),
        }
        return class
    end
    return tes3.player.baseObject.class
end