---@class GMSTName
---@field gmst number
---@field name string?

---@class PaletteColor
---@field palette string?
---@field color number[]?

---@class NameTable
---@field [tes3.physicalAttackType|tes3.effect] GMSTName

---@class ColorTable
---@field [tes3.effect] PaletteColor

---@class Drawer
---@field config Config
---@field weaponNames NameTable
---@field effectNames NameTable
---@field colors ColorTable
---@field headerColor number[]
---@field weakColor number[]
---@field idDPSLabel number
---@field idBorder number
---@field idWeaponBlock number
---@field idWeaponIcon number
---@field idWeaponLabel number
---@field idEffectBlock number
---@field idEffectIcon number
---@field idEffectLabel number
---@field idPreDivider number
---@field idPostDivider number
local Drawer = {}

---@param cfg Config?
---@return Drawer
function Drawer.new(cfg)
    local drawer = {
        config = cfg and cfg or require("longod.DPSTooltips.config").Load()
    }
    setmetatable(drawer, { __index = Drawer })
    return drawer
end

local logger = require("longod.DPSTooltips.logger")

---@param tbl table
---@param indent number?
local function PrintTable(tbl, indent)
    if not indent then
        indent = 0
    end
    for k, v in pairs(tbl) do
        local space = string.rep("    ", indent)
        local str = space .. k .. ": "
        if type(v) == "table" then
            logger:trace(str .. "{")
            PrintTable(v, indent + 1)
            logger:trace(space .. "}")
        elseif type(v) == 'boolean' then
            logger:trace(str .. tostring(v))
        else
            logger:trace(str .. v)
        end
    end
end

---@param self Drawer
function Drawer.Initialize(self)
    self.weaponNames = {
        [tes3.physicalAttackType.slash] = { gmst = tes3.gmst.sSlash, name = nil },
        [tes3.physicalAttackType.thrust] = { gmst = tes3.gmst.sThrust, name = nil },
        [tes3.physicalAttackType.chop] = { gmst = tes3.gmst.sChop, name = nil },
        [tes3.physicalAttackType.projectile] = { gmst = tes3.gmst.sAttack, name = nil },
    }
    self.effectNames = {
        [tes3.effect.fireDamage] = { gmst = tes3.gmst.sEffectFireDamage, name = nil },
        [tes3.effect.frostDamage] = { gmst = tes3.gmst.sEffectFrostDamage, name = nil },
        [tes3.effect.shockDamage] = { gmst = tes3.gmst.sEffectShockDamage, name = nil },
        [tes3.effect.poison] = { gmst = tes3.gmst.sEffectPoison, name = nil, },
        [tes3.effect.absorbHealth] = { gmst = tes3.gmst.sEffectAbsorbHealth, name = nil, },
        [tes3.effect.damageHealth] = { gmst = tes3.gmst.sEffectDamageHealth, name = nil, },
        [tes3.effect.drainHealth] = { gmst = tes3.gmst.sEffectDrainHealth, name = nil, },
        [tes3.effect.sunDamage] = { gmst = tes3.gmst.sEffectSunDamage, name = nil, },
        [tes3.effect.restoreHealth] = { gmst = tes3.gmst.sEffectRestoreHealth, name = nil, },
        [tes3.effect.fortifyHealth] = { gmst = tes3.gmst.sEffectFortifyHealth, name = nil, },
    }
    self.colors = {
        [tes3.effect.fireDamage] = { palette = tes3.palette.healthColor, color = {
            0.78431379795074, 0.23529413342476, 0.11764706671238,
        } },
        [tes3.effect.frostDamage] = { palette = tes3.palette.miscColor, color = {
            0, 0.80392163991928, 0.80392163991928,
        } },
        [tes3.effect.shockDamage] = { palette = tes3.palette.linkColor, color = {
            0.43921571969986, 0.49411767721176, 0.8117647767067,
        } },
        [tes3.effect.poison] = { palette = tes3.palette.fatigueColor, color = {
            0, 0.58823531866074, 0.23529413342476,
        } },
        [tes3.effect.absorbHealth] = { palette = nil, color = {
            247 / 255.0, 223 / 255.0, 255 / 255.0,
        } },
        [tes3.effect.damageHealth] = { palette = nil, color = {
            198 / 255.0, 65 / 255.0, 57 / 255.0,
        } },
        [tes3.effect.drainHealth] = { palette = nil, color = {
            198 / 255.0, 65 / 255.0, 57 / 255.0,
        } },
        [tes3.effect.sunDamage] = { palette = tes3.palette.bigAnswerPressedColor, color = nil },
        [tes3.effect.restoreHealth] = { palette = nil, color = {
            165 / 255.0, 178 / 255.0, 231 / 255.0,
        } },
        [tes3.effect.fortifyHealth] = { palette = nil, color = {
            165 / 255.0, 178 / 255.0, 231 / 255.0,
        } },
    }

    for _, v in pairs(self.weaponNames) do
        if v.gmst and not v.name then
            v.name = tes3.findGMST(v.gmst).value
        end
    end
    for _, v in pairs(self.effectNames) do
        if v.gmst and not v.name then
            v.name = tes3.findGMST(v.gmst).value
        end
    end
    for _, v in pairs(self.colors) do
        if v.palette and not v.color then
            v.color = tes3ui.getPalette(v.palette)
        end
    end
    PrintTable(self.weaponNames)
    PrintTable(self.effectNames)
    PrintTable(self.colors)

    self.headerColor = tes3ui.getPalette(tes3.palette.headerColor)
    self.weakColor = tes3ui.getPalette(tes3.palette.disabledColor)

    self.idDPSLabel = tes3ui.registerID("DPSTooltips_DPSLabel")
    self.idBorder = tes3ui.registerID("DPSTooltips_Border")
    self.idWeaponBlock = tes3ui.registerID("DPSTooltips_WeaponBlock")
    self.idWeaponIcon = tes3ui.registerID("DPSTooltips_WeaponIcon")
    self.idWeaponLabel = tes3ui.registerID("DPSTooltips_WeaponLabel")
    self.idEffectBlock = tes3ui.registerID("DPSTooltips_EffectBlock")
    self.idEffectIcon = tes3ui.registerID("DPSTooltips_EffectIcon")
    self.idEffectLabel = tes3ui.registerID("DPSTooltips_EffectLabel")
    self.idPreDivider = tes3ui.registerID("DPSTooltips_PreDivider")
    self.idPostDivider = tes3ui.registerID("DPSTooltips_PostDivider")
end

---@param element tes3uiElement
---@param id number
---@return tes3uiElement
local function CreateBlock(element, id)
    local block = element:createBlock { id = id }
    block.autoWidth = true
    block.autoHeight = true
    return block
end

---@param element tes3uiElement
---@param id number
---@param text string
---@return tes3uiElement
local function CreateLabel(element, id, text)
    local label = element:createLabel { text = text, id = id }
    label.wrapText = true
    return label
end

---@param self Drawer
---@param data DPSData
function Drawer.DisplayStub(self, data)
    if self.config.logLevel == "TRACE" then
        PrintTable(data)
    end
end

---@param self Drawer
---@param element tes3uiElement
---@param data DPSData
---@param id integer
---@param effect tes3.effect|tes3.physicalAttackType
function Drawer.DisplayIcons(self, element, data, id, effect)
    if self.config.showIcon and data.icons[effect] then
        for _, path in ipairs(data.icons[effect]) do
            local icon = element:createImage({
                id = id,
                path = string.format("icons\\%s", path)
            })
            icon.borderTop = 1
            icon.borderRight = 6
        end
    end
end

---@param self Drawer
---@param element tes3uiElement
---@param data DPSData
function Drawer.DisplayDPS(self, element, data)
    local text = nil
    -- need localize?
    if self.config.minmaxRange then
        text = string.format("DPS: %.1f - %.1f", data.weaponDamageRange.min + data.effectTotal,
            data.weaponDamageRange.max + data.effectTotal)
    else
        text = string.format("DPS: %.1f", data.weaponDamageRange.max + data.effectTotal)
    end
    local label = CreateLabel(element, self.idDPSLabel, text)
    label.color = self.headerColor
end

---@param self Drawer
---@param element tes3uiElement
---@param data DPSData
function Drawer.DisplayWeaponDPS(self, element, data)
    local weaponOrder = {
        tes3.physicalAttackType.chop,
        tes3.physicalAttackType.slash,
        tes3.physicalAttackType.thrust,
        tes3.physicalAttackType.projectile,
    }

    for _, k in ipairs(weaponOrder) do
        local v = data.weaponDamages[k]
        if v then
            local block = CreateBlock(element, self.idWeaponBlock)
            block.borderAllSides = 1

            -- icons
            -- TODO It would be better to consider the layout. display before or after for
            self:DisplayIcons(block, data, self.idWeaponIcon, -k)

            -- label
            local text = nil
            if self.config.minmaxRange then
                text = string.format("%s: %.1f - %.1f", self.weaponNames[k].name, v.min, v.max)
            else
                text = string.format("%s: %.1f", self.weaponNames[k].name, v.max)
            end
            local label = CreateLabel(block, self.idWeaponLabel, text)
            if self.config.coloring and not data.highestType[k] and self.weakColor then
                label.color = self.weakColor
            end
        end
    end
end

---@param self Drawer
---@param element tes3uiElement
---@param data DPSData
function Drawer.DisplayEnchantmentDPS(self, element, data)
    local effectOrder = {
        tes3.effect.fireDamage,
        tes3.effect.frostDamage,
        tes3.effect.shockDamage,
        tes3.effect.poison,
        tes3.effect.absorbHealth,
        tes3.effect.damageHealth,
        tes3.effect.drainHealth,
        tes3.effect.sunDamage,
        tes3.effect.restoreHealth,
        tes3.effect.fortifyHealth,
    }

    for _, k in ipairs(effectOrder) do
        local v = data.effectDamages[k] and data.effectDamages[k] or 0
        if (v ~= 0) or (data.icons[k] and #data.icons[k] > 0) then -- has any effects from icons
            local block = CreateBlock(element, self.idEffectBlock)
            block.borderAllSides = 1

            -- icons
            self:DisplayIcons(block, data, self.idEffectIcon, k)

            -- label
            local label = CreateLabel(block, self.idEffectLabel, string.format("%s: %.1f", self.effectNames[k].name, v))
            local col = self.colors[k]
            if self.config.coloring and col and col.color then
                label.color = col.color
            end
        end
    end
end

---@param self Drawer
---@param element tes3uiElement
---@param data DPSData
function Drawer.Display(self, element, data)
    if not data then
        return
    end

    self:DisplayStub(data)

    if not element then
        return
    end
    
    if self.config.preDivider then
        local divider = element:createDivider({id = self.idPreDivider})
        divider.widthProportional = 0.85
    end

    self:DisplayDPS(element, data)

    if self.config.breakdown then
        local frame = element:createThinBorder({ id = self.idBorder })
        frame.flowDirection = "top_to_bottom"
        frame.borderAllSides = 4
        frame.borderLeft = 6
        frame.borderRight = 6
        frame.autoWidth = true
        frame.autoHeight = true
        -- for children layout
        frame.paddingAllSides = 4
        frame.paddingLeft = 6
        frame.paddingRight = 6

        self:DisplayWeaponDPS(frame, data)
        self:DisplayEnchantmentDPS(frame, data)
        -- display non damage effect if need
    end

    if self.config.postDivider then
        local divider = element:createDivider({id = self.idPostDivider})
        divider.widthProportional = 0.85
    end

    element:updateLayout()
end

return Drawer
