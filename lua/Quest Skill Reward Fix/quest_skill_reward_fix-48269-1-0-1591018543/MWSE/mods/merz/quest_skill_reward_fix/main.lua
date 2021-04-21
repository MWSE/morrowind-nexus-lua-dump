local mod = '[Quest Skill Reward Fix]'
local version = '1.0'

local function OutOfDate()
    local msg = 'MWSE is out of date! Update to use this mod.'
    tes3.messageBox(mod .. '\n' .. msg)
    mwse.log(mod .. ' ' .. msg)
end

if mwse.buildDate == nil or mwse.buildDate < 20200530 then
    event.register('initialized', OutOfDate)
    return
end

local quests = require('merz.quest_skill_reward_fix.quests')
local config = require('merz.quest_skill_reward_fix.config')
local skills = {}

local function OnInfoResponse(e)
    -- Save all the current skill values. This will let us compare them after the response is processed to see if any
    -- skill increases were awarded.
    local mp = tes3.mobilePlayer
    for i = 1, #mp.skills do
        skills[i] = mp.skills[i].base
    end
end
event.register('infoResponse', OnInfoResponse)

local function OnPostInfoResponse(e)
    local mp = tes3.mobilePlayer
    local is_reward = false
    local increases = {}
    -- We remove all the increases for all increased skills before adding them back later. This ensures that player
    -- data are consistent when the events fire below.
    for i = 1, #skills do
        if mp.skills[i].base > skills[i] then
            -- Quest reward detected.
            is_reward = true
            -- Save and remove increase so that we can add it back incrementally below.
            increases[i] = mp.skills[i].base - skills[i]
            mp.skills[i].base = skills[i]
        end
    end
    if is_reward then
        local is_quest_match = false
        if not config.generic_enabled then
            -- Check the vanilla quests for a match.
            local info_id
            for actor, ids in pairs(quests) do
                if actor == e.info.actor.id then
                    -- e.info.id is read from a file, so only load once.
                    info_id = info_id or e.info.id
                    for _, id in pairs(ids) do
                        if id == info_id then
                            is_quest_match = true
                            break
                        end
                    end
                    if is_quest_match then
                        break
                    end
                end
            end
        end
        for i, increase in pairs(increases) do
            if config.generic_enabled or is_quest_match then
                local iLevelupMult, iLevelupMultAttribute
                local skill_type = mp.skills[i].type
                -- Use the appropriate GMSTs.
                if skill_type == tes3.skillType.major then
                    iLevelupMult = tes3.findGMST(tes3.gmst.iLevelupMajorMult).value
                    iLevelupMultAttribute = tes3.findGMST(tes3.gmst.iLevelupMajorMultAttribute).value
                elseif skill_type == tes3.skillType.minor then
                    iLevelupMult = tes3.findGMST(tes3.gmst.iLevelupMinorMult).value
                    iLevelupMultAttribute = tes3.findGMST(tes3.gmst.iLevelupMinorMultAttribute).value
                else -- minor skill
                    iLevelupMult = 0
                    iLevelupMultAttribute = tes3.findGMST(tes3.gmst.iLevelupMiscMultAttriubte).value
                end
                while increase > 0 do
                    -- Treat each increase as a separate event. This matches what happens in the game: every
                    -- skillRaised event corresponds to a single increase.
                    increase = increase - 1
                    -- Update player data. Note that we do not update levelupsPerSpecialization. The game only updates
                    -- those values when skills increase via progress. levelupsPerSpecialization does not appear to be
                    -- used by the game for anything, so its implementation is probably unfinished.
                    local a = tes3.getSkill(i - 1).attribute + 1
                    mp.levelupsPerAttribute[a] = mp.levelupsPerAttribute[a] + iLevelupMultAttribute
                    mp.levelUpProgress = mp.levelUpProgress + iLevelupMult
                    mp.skills[i].base = mp.skills[i].base + 1
                    event.trigger('skillRaised', { skill = i - 1, level = mp.skills[i].base, source = 'quest' })
                end
            else
                -- Quest reward, but it's not vanilla and the generic handling is disabled, so restore skill values.
                mp.skills[i].base = mp.skills[i].base + increase
            end
        end
        -- This will show up in the dialogue instead of in a separate pop up. We could delay it until the dialogue window
        -- is closed, but it's possible to raise mercantile or speechcraft without leaving dialogue. If either of those
        -- trigger the level up message and we delay this one, this one will show up too late.
        if (config.generic_enabled or is_quest_match)
            and mp.levelUpProgress >= tes3.findGMST(tes3.gmst.iLevelupTotal).value then
            tes3.messageBox(tes3.findGMST(tes3.gmst.sLevelUpMsg).value)
        end
    end
end
event.register('postInfoResponse', OnPostInfoResponse)

local function OnInitialized()
    mwse.log(mod .. ' Initialized Version ' .. version)
end
event.register('initialized', OnInitialized)

local function SetupMenu()
    local template = mwse.mcm.createTemplate({ name = 'Quest Reward Skill Fix' })
    template:saveOnClose('quest_skill_reward_fix', config)
    template:register()
    local preferences = template:createSideBarPage({ label = 'Preferences' })
    local toggles = preferences:createCategory({ label = 'Options' })
    toggles:createOnOffButton({
        label = 'Generic Quest Skill Reward Detection',
        description = 'Detects and fixes non-vanilla quests that award skill increases.',
        variable = mwse.mcm:createTableVariable({
            id = 'generic_enabled',
            table = config
        })
    })
end
event.register('modConfigReady', SetupMenu)