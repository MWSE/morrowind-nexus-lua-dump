-- Imports -----------------------------------------------
local UI = require("OtherSkills.UI")
local Skill = require("OtherSkills.components.Skill")
local SkillModifier = require("OtherSkills.components.SkillModifier")
local util = require("OtherSkills.util")
local logger = util.createLogger("SkillsModule")
local config = require("OtherSkills.config")
require("OtherSkills.MCM")
-----------------------------------------------------------

--- Interop file for Skills Module.
--- This is the only file that should be required by other mods.
---@class SkillsModule
---@field skills table<string, SkillsModule.Skill>
local SkillsModule = {
    skills = Skill.getAll()
}

---Register a skill
---@param params SkillsModule.Skill.constructorParams
---@return SkillsModule.Skill
function SkillsModule.registerSkill(params)
    params.apiVersion = 2
    return Skill:new(params)
end

---Register a skill base modifier
---@param params SkillsModule.BaseModifier
function SkillsModule.registerBaseModifier(params)
    SkillModifier.registerBaseModifier(params)
end

---Register a skill base modifier for a class
---@param params SkillsModule.ClassModifier
function SkillsModule.registerClassModifier(params)
    SkillModifier.registerClassModifier(params)
end

---Register a skill base modifier for a race
---@param params SkillsModule.RaceModifier
function SkillsModule.registerRaceModifier(params)
    SkillModifier.registerRaceModifier(params)
end

---Register a skill fortify or drain effect
---@param params SkillsModule.FortifyEffect
function SkillsModule.registerFortifyEffect(params)
    SkillModifier.registerFortifyEffect(params)
end

---Get a skill by its id
function SkillsModule.getSkill(id)
    return Skill.get(id)
end

---Log skill ids in alphabetical order to the console
function SkillsModule.listIds()
    local sortedSkills = Skill.getSorted()
    for _, skill in ipairs(sortedSkills) do
        tes3ui.log(skill)
        logger:info(skill)
    end
end

----------------------------------------
-- Event Handling
----------------------------------------
event.register("loaded", function(e)
    --Trigger deprecated ready event
    event.trigger("OtherSkills:Ready")
end)

event.register("SkillsModule:UpdateSkillsList", UI.updateSkillList)
--entering stat menu
event.register("menuEnter", UI.updateSkillList)
--entering stat review menu
event.register("uiActivated", UI.updateSkillList, { filter = "MenuStatReview" } )
--Scroll pane updated
event.register("uiRefreshed", UI.updateSkillList, {filter = "MenuStat_scroll_pane" } )
--Choose class menu
event.register("uiActivated", UI.addSkillsToClassMenu, { filter = "MenuChooseClass", priority = 150 })
event.register("UIEXP:sandboxConsole", function(e)
    e.sandbox.SkillsModule = SkillsModule
end)

return SkillsModule