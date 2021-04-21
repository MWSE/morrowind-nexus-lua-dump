--[[
-- MWSE Staff Skill
-- by inpv, 2020

-- when a staff weapon is equipped, a dedicated staff skill is used
-- requires MWSE and Skills Module
]]

--[[ DATA ]]
local configPath = "staffskill"
local config = mwse.loadConfig(configPath)

local skillModule = require("OtherSkills.skillModule")
local matchList = {
    "staff",
    "stick",
    "crosier",
    "stanchion",
    "TR_m1_SSOW_cursed_i62",
    "TR_m1_q_TT_7_Reward"
} -- add your desired staff weapon ids here

local skills = {}
skills.skillStartValue = 20
skills.skillStatus = "inactive"

if (config == nil) then
	config = { enabled = true, skillGain = 1 }
end

--[[ HELPER FUNCTIONS ]]
local function checkEquipped() -- check if the equipped weapon is a staff
    local staffEquipped

    for i, match in ipairs(matchList) do
        if tes3.mobilePlayer.readiedWeapon == nil then staffEquipped = false
        elseif string.find(tes3.mobilePlayer.readiedWeapon.object.id, match) then
            staffEquipped = true
            break
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
        if checkEquipped() then
            skills.skillStatus = "active"
        else
            skills.skillStatus = "inactive"
        end
    end

    if tes3.player.data.StaffSkill == nil then
        tes3.player.data.StaffSkill = {skillStatus = "inactive"} -- create the table
    end

    tes3.player.data.StaffSkill.skillStatus = skills.skillStatus -- store the state between saves
    skillModule.updateSkill("MSS:Staff", {active = tes3.player.data.StaffSkill.skillStatus}) -- apply changes on load
end

--in game events
local function onEquipped(e) -- display the skill

    for i, match in ipairs(matchList) do
        if string.find(e.item.id, match) then
            skills.skillStatus = "active"
            tes3.player.data.StaffSkill.skillStatus = skills.skillStatus -- store the state between saves
            skillModule.updateSkill("MSS:Staff", {active = tes3.player.data.StaffSkill.skillStatus}) -- apply changes
            break
        end
    end
end

local function onUnequipped(e) -- hide the skill

    for i, match in ipairs(matchList) do
        if string.find(e.item.id, match) then
            skills.skillStatus = "inactive"
            tes3.player.data.StaffSkill.skillStatus = skills.skillStatus -- store the state between saves
            skillModule.updateSkill("MSS:Staff", {active = tes3.player.data.StaffSkill.skillStatus}) -- apply changes
            break
        end
    end
end

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
        event.register("equipped", onEquipped)
        event.register("unequipped", onUnequipped)
        event.register("exerciseSkill", onExerciseSkill)
        event.register("calcHitChance", onCalcHitChance)
    end
end

event.register("initialized", onInitialized)

--[[ MCM ]]
local function registerModConfig()
    local mcm = require("mcm.mcm")

    local sidebarDefault = (
        "Whenever a staff weapon is equipped, a dedicated Endurance-based Staff skill is used. Includes all staves from the vanilla game, expansions and Tamriel Rebuilt by default."
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
        description = "Turn this mod on or off [requires game restart]."
    }

    page:createSlider{
        label = "Skill gain base value",
        description = ("The base amount of skill progress the character gains on a successful staff hit."),
        min = 1,
        max = 5,
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
