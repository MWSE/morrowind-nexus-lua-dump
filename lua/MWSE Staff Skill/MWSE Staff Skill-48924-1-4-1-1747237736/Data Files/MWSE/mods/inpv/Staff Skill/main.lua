--[[
-- MWSE Staff Skill
-- by inpv, 2020-2024

-- adds a dedicated staff skill for wide blunt 2-handed weapons
-- requires MWSE and Skills Module
]]

--[[ DATA ]]
local configPath = "staffskill"
local config = mwse.loadConfig(configPath)

local skillModule = require("OtherSkills.skillModule")

local skills = {}
skills.skillStartValue = 20
skills.skillStatus = "active"

if (config == nil) then
	config = { enabled = true, skillGain = 1 }
end

--[[ HELPER FUNCTIONS ]]
local function checkEquipped() -- check if the equipped weapon is a staff
    local staffEquipped

    if tes3.mobilePlayer.readiedWeapon == nil then
        staffEquipped = false
    else
        if tes3.mobilePlayer.readiedWeapon.object.type == 5 then
            staffEquipped = true
        else
            staffEquipped = false
        end
    end

    return staffEquipped
end

local function onSkillReady() -- create the skill

    skillModule.registerSkill(
         "MSS:Staff",
         {
             name = "Staff",
             icon = "Icons/RFD/StaffSkill/InpvStaff.dds",
             value = skills.skillStartValue,
             progress = 0,
             attribute = tes3.attribute.endurance,
             description = "This skill lets one use wide two-handed blunt weapons, namely various types of staves, more effectively.",
             specialization = tes3.specialization.stealth,
             active = skills.skillStatus
         }
     )
 end

--[[ MAIN EVENTS ]]
-- on load events
local function onLoadedSkillsModuleCheck() -- check if recent Skills Module is installed and updated
    if not skillModule then
        timer.start({
            callback = function()
                tes3.messageBox({message = "Please install Skills Module", buttons = {"Okay"} })
            end,
            type = timer.simulate,
            duration = 1.0
        })
    end

    if ( skillModule.version == nil ) or ( skillModule.version < 1.4 ) then
        timer.start({
            callback = function()
                tes3.messageBox({message = string.format("Please update Skills Module"), buttons = {"Okay"} })
            end,
            type = timer.simulate,
            duration = 1.0
        })
    end
end

local function onLoadedSetActiveSkillStatus() -- set the skill's active status based on previous saved state

    if not config.enabled then
        skills.skillStatus = "inactive"
    else
        skills.skillStatus = "active"
    end

    if tes3.player.data.StaffSkill == nil then
        tes3.player.data.StaffSkill = {skillStatus = "active"} -- create the table
    end

    tes3.player.data.StaffSkill.skillStatus = skills.skillStatus -- store the state between saves
    skillModule.updateSkill("MSS:Staff", {active = tes3.player.data.StaffSkill.skillStatus}) -- apply changes on load
end

--in game events
local function onExerciseSkill(e) -- exercise staff skill instead of blunt weapon for staves

    if e.skill == 4 and checkEquipped() then
        local hitMod = math.random(1, 5)
        local skill = skillModule.getSkill("MSS:Staff")
        skill:progressSkill(config.skillGain + hitMod)
        return false
    end
end

local function onCalcHitChance(e) -- calculating the hit chance based on custom skill

    local playerHitChance
    local targetEvasionChance

    local function calcPlayerHitChance()

        local playerLuck = tes3.mobilePlayer.luck.current
        local playerAgility = tes3.mobilePlayer.agility.current
        local weaponSkill = skillModule.getSkill("MSS:Staff").value
        local playerFatigueCurrent = tes3.mobilePlayer.fatigue.current
        local playerFatigueMax = tes3.mobilePlayer.fatigue.base
        local fortifyAttackValue = tes3.getEffectMagnitude{reference = tes3.mobilePlayer, effect = tes3.effect.fortifyAttack}
        local blindValue = tes3.getEffectMagnitude{reference = tes3.mobilePlayer, effect = tes3.effect.blind}
        playerHitChance = (weaponSkill + (playerAgility / 5) + (playerLuck / 10)) * (0.75 + (0.5 * (playerFatigueCurrent / playerFatigueMax))) + fortifyAttackValue - blindValue

        return playerHitChance
    end

    local function calcTargetEvasionChance()

        local actorLuck = e.targetMobile.luck.current
        local actorAgility = e.targetMobile.agility.current
        local actorFatigueCurrent = e.targetMobile.fatigue.current
        local actorFatigueMax = e.targetMobile.fatigue.base
        local actorSanctuaryValue = tes3.getEffectMagnitude{reference = e.targetMobile, effect = tes3.effect.sanctuary}
        targetEvasionChance = (actorAgility / 5) + (actorLuck / 10) * (0.75 + (0.5 * (actorFatigueCurrent / actorFatigueMax))) + actorSanctuaryValue

        return targetEvasionChance
    end

    if checkEquipped() then
        if e.targetMobile ~= nil and e.attackerMobile == tes3.mobilePlayer then
            e.hitChance = calcPlayerHitChance() - calcTargetEvasionChance()
        end
    end
end

local function onInitialized()

    event.register("OtherSkills:Ready", onSkillReady)
    event.register("OtherSkills:Ready", onLoadedSkillsModuleCheck)
    event.register("OtherSkills:Ready", onLoadedSetActiveSkillStatus)

    if not config.enabled then
        return
    else
        event.register("exerciseSkill", onExerciseSkill)
        event.register("calcHitChance", onCalcHitChance)
    end
end

event.register("initialized", onInitialized)

--[[ MCM ]]
local function registerModConfig()
    local mcm = require("mcm.mcm")

    local sidebarDefault = (
        "Adds a dedicated Endurance-based Staff skill for wide blunt 2-handed weapons. Supports any staves by default."
    )

    local template = mcm.createTemplate("MWSE Staff Skill")
    template:saveOnClose(configPath, config)

    local page = template:createSideBarPage{
        description = sidebarDefault
    }

    page:createOnOffButton{
        label = "Enable Staff Skill",
        variable = mcm.createTableVariable{
            id = "enabled",
            table = config,
            restartRequired = true,
        },
        description = "Turn this mod on or off [requires game restart]. On by default. When on, the skill is displayed."
    }

    page:createSlider{
        label = "Skill gain base value",
        description = ("The base amount of skill progress the character gains on a successful staff hit [default = 1]."),
        min = 1,
        max = 10,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable{
            id = "skillGain",
            table = config
        }
    }

    template:register()
end

event.register("modConfigReady", registerModConfig)
