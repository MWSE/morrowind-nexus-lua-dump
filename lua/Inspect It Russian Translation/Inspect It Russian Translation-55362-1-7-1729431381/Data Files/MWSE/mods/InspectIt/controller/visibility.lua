local base = require("InspectIt.controller.base")

---@class Visibility : IController
---@field visibility {[integer] : boolean}
local this = {}
setmetatable(this, { __index = base })

---@type Visibility
local defaults = {
    visibility = {},
}

local menus = {
    tes3ui.registerID("MenuAlchemy"), --
    -- tes3ui.registerID("MenuAttributes"), --
    -- tes3ui.registerID("MenuAttributesList"), -- Enchanting/spellmaking effect attribute
    tes3ui.registerID("MenuBarter"), --
    -- tes3ui.registerID("MenuBirthSign"), --
    -- tes3ui.registerID("MenuBook"), --
    -- tes3ui.registerID("MenuChooseClass"), --
    -- tes3ui.registerID("MenuClassChoice"), --
    -- tes3ui.registerID("MenuClassMessage"), --
    -- tes3ui.registerID("MenuConsole"), --
    tes3ui.registerID("MenuContents"), -- Container/NPC inventory
    -- tes3ui.registerID("MenuDialog"), --
    tes3ui.registerID("MenuEnchantment"), --
    -- tes3ui.registerID("MenuInput"), --
    -- tes3ui.registerID("MenuInputSave"), --
    tes3ui.registerID("MenuInventory"), -- Player inventory
    tes3ui.registerID("MenuInventorySelect"), -- Item selector
    -- tes3ui.registerID("MenuJournal"), --
    tes3ui.registerID("MenuMagic"), -- Spell/enchanted item selector
    -- tes3ui.registerID("MenuMagicSelect"), --
    tes3ui.registerID("MenuMap"), --
    -- tes3ui.registerID("MenuMapNoteEdit"), --
    -- tes3ui.registerID("MenuMessage"), --
    -- tes3ui.registerID("MenuMulti"), -- Status bars, current weapon/magic, active effects and minimap
    -- tes3ui.registerID("MenuName"), --
    -- tes3ui.registerID("MenuQuick"), -- Quick keys
    tes3ui.registerID("MenuRepair"), --
    -- tes3ui.registerID("MenuRestWait"), --
    -- tes3ui.registerID("MenuSave"), --
    -- tes3ui.registerID("MenuScroll"), --
    tes3ui.registerID("MenuServiceRepair"), --
    tes3ui.registerID("MenuServiceSpells"), --
    -- tes3ui.registerID("MenuServiceTraining"), --
    -- tes3ui.registerID("MenuServiceTravel"), --
    -- tes3ui.registerID("MenuSetValues"), -- Enchanting/spellmaking effect values
    -- tes3ui.registerID("MenuSkills"), --
    -- tes3ui.registerID("MenuSkillsList"), -- Enchanting/spellmaking effect skill
    -- tes3ui.registerID("MenuSpecialization"), --
    tes3ui.registerID("MenuSpellmaking"), --
    tes3ui.registerID("MenuStat"), -- Player attributes, skills, factions etc.
    -- tes3ui.registerID("MenuSwimFillBar"), --
    -- tes3ui.registerID("MenuTimePass"), --
    -- tes3ui.registerID("MenuTopic"), --
}

---@return Visibility
function this.new()
    local instance = base.new(defaults)
    setmetatable(instance, { __index = this })
    ---@cast instance Visibility

    return instance
end

---@param self Visibility
---@param params Activate.Params
function this.Activate(self, params)
    tes3ui.suppressTooltip(true)
    for _, menu in ipairs(menus) do
        local element = tes3ui.findMenu(menu)
        if element and element.visible == true then
            self.logger:debug("[Activate] Menu %s visibility %s to false", element.name, tostring(element.visible))
            element.visible = false
            self.visibility[menu] = true
        else
            self.visibility[menu] = false
        end
    end
end

---@param self Visibility
---@param params Deactivate.Params
function this.Deactivate(self, params)
    tes3ui.suppressTooltip(false)
    if not params.menuExit then
        for menu, value in pairs(self.visibility) do
            if value then
                local element = tes3ui.findMenu(menu)
                if element then
                    self.logger:debug("[Deactivate] Menu %s visibility %s to true", element.name, tostring(element.visible))
                    element.visible = true
                end
            end
        end
    end
end

---@param self Visibility
function this.Reset(self)
    self.visibility = {}
end

return this
