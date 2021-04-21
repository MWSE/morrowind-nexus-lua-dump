local prefix = '[Skill Increase GMST Test]'
local function log(s, ...)
    mwse.log(prefix .. ' ' .. s, ...)
end

local function messageBox(s, ...)
    if type(s) == 'string' then
        s = prefix .. '\n' .. s
    elseif type(s) == 'table' then
        if s.message ~= nil then
            s.message = prefix .. '\n' .. s.message
        end
    end
    tes3.messageBox(s, ...)
end

local mp
local cache = { }
local iLevelupMajorMult, iLevelupMinorMult
local iLevelupMajorMultAttribute, iLevelupMinorMultAttribute, iLevelupMiscMultAttriubte
local tests = {}
tests.book = { major = false, minor = false, misc = false }
tests.training = { major = false, minor = false, misc = false }
tests.progress = { major = false, minor = false, misc = false }

local function onLoaded()
    mp = tes3.mobilePlayer
    cache.levelUpProgress = mp.levelUpProgress
    cache.levelupsPerAttribute = { }
    for i = 1, #mp.attributes do
        cache.levelupsPerAttribute[i] = mp.levelupsPerAttribute[i]
    end
end

local function onSkillRaised(e)
    local attribute = tes3.getSkill(e.skill).attribute
    local index = attribute + 1
    local skillIndex = e.skill + 1
    local skillType

    for name, id in pairs(tes3.skillType) do
        if mp.skills[skillIndex].type == id then
            skillType = name
        end
    end

    local attributeInc = mp.levelupsPerAttribute[index] - cache.levelupsPerAttribute[index]
    cache.levelupsPerAttribute[index] = mp.levelupsPerAttribute[index]
    local levelupInc = mp.levelUpProgress - cache.levelUpProgress
    cache.levelUpProgress = mp.levelUpProgress
    local passed = true
    log('Starting test...')
    log('%s [%s] raised by %s.', tes3.skillName[e.skill], skillType, e.source)
    tests[e.source][skillType] = true

    if skillType == 'major' then
        if attributeInc ~= iLevelupMajorMultAttribute or levelupInc ~= iLevelupMajorMult then
            passed = false
        end
        log('%s level ups +%d -- iLevelupMajorMultAttribute = %d', tes3.attributeName[attribute], attributeInc,
            iLevelupMajorMultAttribute)
        log('Level progress +%d -- iLevelupMajorMult = %d',  levelupInc, iLevelupMajorMult)
    elseif skillType == 'minor' then
        if attributeInc ~= iLevelupMinorMultAttribute or levelupInc ~= iLevelupMinorMult then
            passed = false
        end
        log('%s level ups +%d -- iLevelupMinorMultAttribute = %d', tes3.attributeName[attribute], attributeInc,
            iLevelupMinorMultAttribute)
        log('Level progress +%d -- iLevelupMinorMult = %d',  levelupInc, iLevelupMinorMult)
    else
        if attributeInc ~= iLevelupMiscMultAttriubte then passed = false end
        log('%s level ups +%d -- iLevelupMiscMultAttriubte = %d', tes3.attributeName[attribute], attributeInc,
            iLevelupMiscMultAttriubte)
    end

    if passed then
        messageBox('Test passed (%s). See log for details.', e.source)
        log('Test passed.')
    else
        messageBox('Test failed (%s). See log for details.', e.source)
        log('Test failed.')
    end

    -- We track all the tests, but we only care about book and training, major and minor; the others are not affected.
    if tests.book.major and tests.book.minor and tests.training.major and tests.training.minor then
        local msg = 'All tests complete.'
        messageBox(msg)
        log(msg)
    end
end

local function onInitialized()
    local esp = 'skill_increase_gmst_test.esp'
    if tes3.isModActive(esp) then
        event.register('skillRaised', onSkillRaised)
        event.register('loaded', onLoaded)
        iLevelupMajorMultAttribute = tes3.findGMST(tes3.gmst.iLevelupMajorMultAttribute).value
        iLevelupMinorMultAttribute = tes3.findGMST(tes3.gmst.iLevelupMinorMultAttribute).value
        iLevelupMiscMultAttriubte = tes3.findGMST(tes3.gmst.iLevelupMiscMultAttriubte).value
        iLevelupMajorMult = tes3.findGMST(tes3.gmst.iLevelupMajorMult).value
        iLevelupMinorMult = tes3.findGMST(tes3.gmst.iLevelupMinorMult).value
        local gmst_fix = include('merz.skill_increase_gmst_fix.interop')
        if gmst_fix and gmst_fix.is_patched then log('GMST patch enabled.')
        else log('GMST patch disabled.') end
    else
        local message = esp .. ' must be loaded. Test disabled.'
        log(message)
        messageBox(message)
    end
end

event.register('initialized', onInitialized)