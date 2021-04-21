--[[
    Magicka Based Skill Progression:
    MWSE LUA Edition
    v1.0.1
    by JaceyS
    Original by HotFusion4
]]--
local defaultConfig = {
    enableMBSP = true,
    skillExpPerMagicka = 0.2,
    schoolSkills = {
        [tes3.magicSchool.alteration] = tes3.skill.alteration,
        [tes3.magicSchool.conjuration] = tes3.skill.conjuration,
        [tes3.magicSchool.destruction] = tes3.skill.destruction,
        [tes3.magicSchool.illusion] = tes3.skill.illusion,
        [tes3.magicSchool.mysticism] = tes3.skill.mysticism,
        [tes3.magicSchool.restoration] = tes3.skill.restoration
    },
    logging = false,
}

local config = mwse.loadConfig("Magicka Based Skill Progression", defaultConfig)

local function onSpellCasted(e)
    if (e.caster ~= tes3.player) then
        return
    end
    if (config.enableMBSP) then
        if config.logging then tes3ui.logToConsole("Player has cast a spell.") end
        local school = e.expGainSchool
        if config.logging then tes3ui.logToConsole("Raw school: " .. e.expGainSchool) end
        if config.logging then if config.schoolSkills[school] then tes3ui.logToConsole("Gain school is " .. tes3.skillName[config.schoolSkills[e.expGainSchool]]) else tes3ui.logToConsole("School not found") end end
        e.expGainSchool = nil
        if (config.schoolSkills[school]) then
            tes3.mobilePlayer:exerciseSkill(config.schoolSkills[school], e.source.magickaCost * config.skillExpPerMagicka)
            if config.logging then tes3ui.logToConsole("Adding " .. e.source.magickaCost * config.skillExpPerMagicka .. "exp to ".. tes3.skillName[config.schoolSkills[school]]) end
        end
    end
end

event.register("spellCasted", onSpellCasted)



local function registerMCM()
    local template = mwse.mcm.createTemplate("Magicka Based Skill Progression")
    template:saveOnClose("Magicka Based Skill Progression", config)
    template.headerImagePath = "MWSE/mods/Magicka Based Skill Progression/Magicka Based Skill Progression Logo.tga"

    local page = template:createSideBarPage()
    page.label = "Settings"
    page.description = "Magicka Based Skill Progression: MWSE-Lua Edition, v1.0"

    local category = page:createCategory("Settings")

    category:createYesNoButton({
        label = "Enable/Disable",
        description = "Toggle the functionality of the mod on and off.",
        variable = mwse.mcm:createTableVariable{id = "enableMBSP", table = config}
    })
    local skillExpPerMagickaField = category:createTextField()
    skillExpPerMagickaField.numbersOnly = true
    skillExpPerMagickaField.label = "Skill Experience per Magicka"
    skillExpPerMagickaField.description = "The amount of skill experience to give per magicka. Casting a spell in vanilla gives 1 skill XP. Default of 0.2 gives 1 skill XP per 5 Magicka spent."
    skillExpPerMagickaField.variable = mwse.mcm:createTableVariable{id = "skillExpPerMagicka", table = config}

    category:createYesNoButton({
        label = "Logging",
        description = "Logs mod actions to the console, for debugging.",
        variable = mwse.mcm:createTableVariable{id = "logging", table = config}
    })

    mwse.mcm.register(template)
end



event.register("modConfigReady", registerMCM)