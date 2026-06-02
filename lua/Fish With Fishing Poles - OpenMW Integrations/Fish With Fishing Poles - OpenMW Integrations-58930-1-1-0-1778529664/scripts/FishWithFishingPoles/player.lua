local core = require('openmw.core')
local self = require('openmw.self')
local I = require('openmw.interfaces')
local util = require('openmw.util')
local ui = require('openmw.ui')

local l10n = core.l10n('FishWithFishingPoles')

local MAX_CAST_COUNT = 5000

local skillId = 'fwfp_fishing'
local useTypes = {
    CastRod = 1,
}

local function statToCastCount()
    local stat = I.SkillFramework.getSkillStat(skillId)
    if not stat then return 0 end

    local level = stat.modified
    local addXp = stat.progress * (level + 1)
    local castCount = level * (level + 1) / 2 + addXp
    return util.round(math.min(castCount, MAX_CAST_COUNT))
end

if I.SkillFramework then
    I.SkillFramework.registerSkill(skillId, {
        name = l10n('Skill_Fishing'),
        description = l10n('Skill_Fishing_Desc'),
        icon = {
            fgr = 'icons/skillframework/fwfp_fishing.dds',
        },
        attribute = 'endurance',
        specialization = I.SkillFramework.SPECIALIZATION.Stealth,
        skillGain = {
            [useTypes.CastRod] = 1.0,
        },
        modIntegration = {
            statsWindow = {
                subsection = I.SkillFramework.STATS_WINDOW_SUBSECTIONS.Nature,
            }
        }
    })
else
    local err = 'ERROR (Fish With Fishing Poles): Skill Framework is not installed, or is loaded after this mod. The skill will not function.'
    if I.UI.showInteractiveMessage then
        I.UI.showInteractiveMessage(err)
    else
        ui.showMessage(err)
    end
    return
end

I.SkillFramework.registerRaceModifier(skillId, 'argonian', 10)
I.SkillFramework.registerRaceModifier(skillId, 'redguard', 10)
I.SkillFramework.registerRaceModifier(skillId, 'nord', 5)
I.SkillFramework.registerRaceModifier(skillId, 't_hr_riverfolk', 5)
I.SkillFramework.registerRaceModifier(skillId, 't_pya_seaelf', 10)
I.SkillFramework.registerRaceModifier(skillId, 't_yne_ynesai', 10)

I.SkillFramework.registerClassModifier(skillId, 'scout', 5)
I.SkillFramework.registerClassModifier(skillId, 't_glb_fisherman', 15)
I.SkillFramework.registerClassModifier(skillId, 't_glb_naturalist', 5)
I.SkillFramework.registerClassModifier(skillId, 't_glb_sailor', 5)
I.SkillFramework.registerClassModifier(skillId, 't_glb_scout', 5)
I.SkillFramework.registerClassModifier(skillId, 'ab_sailor', 5)

I.SkillFramework.registerSkillBook('bk_fishystick', skillId)

I.SkillFramework.addSkillStatChangedHandler(function(id)
    if id == skillId then
        core.sendGlobalEvent('FWFP_AdjustGlobal', {
            player = self,
            value = statToCastCount(),
        })
    end
end)

return {
    engineHandlers = {
        onConsoleCommand = function(command, str)
            if str:match("^lua fishing") then
                local level = str:match("^lua fishing%s+(%d+)")
                if level then
                    I.SkillFramework.getSkillStat(skillId).base = tonumber(level)
			        ui.printToConsole("Fishing skill set to " .. level, ui.CONSOLE_COLOR.Success)
                end
                return true
            end
        end,
    },
    eventHandlers = {
        FWFP_StartFishing = function()
            I.SkillFramework.skillUsed(skillId, { useType = useTypes.CastRod })
        end,
    }
}