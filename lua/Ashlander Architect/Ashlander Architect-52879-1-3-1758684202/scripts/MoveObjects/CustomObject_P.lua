-- SettlerPlayer.lua (cleaned)

-- Deps
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local util = require("openmw.util")
local v2 = util.vector2
local core = require("openmw.core")
local self = require("openmw.self")
local debug = require("openmw.debug")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local storage = require("openmw.storage")
local input = require("openmw.input")
local async = require("openmw.async")
local wasSwinging = false
local isRelease = false
local zutils = require("scripts.moveobjects.utility.player").interface
local createObjectBox

local currentText
local storedYamlDefault = "format: yaml-1.2\
notes:\
- Map keys are scalars; YAML tags not used.\
- Core Schema type deduction applies when scalars unquoted.\
- 'Lua 5.1 uses #number (floating point) for all numeric scalars.'\
- Use floating notation for values larger than int range\
Saved Items:\
  Saved Items:"
local storedYamlItemTemplate = "\
  - EditorId: <recordId>\
    Texture_Name: blank\
    Name: <name>\
    Category: Stored Objects\
    Subcategory: Stored Objects\
    Z_Offset: -0\
    Grid_Size: 0.0\
    XY_Offset: 0.0\
    DefaultDist: 500.0\
    IntCount: 90.0\
    requirements:"
  local storedYaml = storedYamlDefault
local currentRecordId
-- helpers for YAML-safe insertion
local function yaml_quote(s)
    if s == nil then return '""' end
    s = tostring(s)
    if s == "" then return '""' end
    if s:find("[\":#{}\n\r\t]") or s:match("^%s") or s:match("%s$") then
        return '"' .. s:gsub('"', '\\"') .. '"'
    end
    return s
end

local function lua_pat_escape(s)
    return (tostring(s):gsub("(%W)","%%%1"))
end

-- Append one item built from your storedYamlItemTemplate
local function generateAndStoreYaml(recordId, name)
    if not recordId or recordId == "" then
        ui.showMessage("No recordId to store.")
        return
    end
    -- prevent duplicates (simple scan)
    local quotedId = yaml_quote(recordId)
    local existsPat = "EditorId:%s*" .. lua_pat_escape(quotedId)
    if storedYaml:find(existsPat) then
        ui.showMessage(("Already saved: %s"):format(recordId))
        return
    end

    -- fill the template placeholders
    local item = storedYamlItemTemplate
    -- your template shows "<recordId?" — accept both "<recordId?>" and "<recordId>"
    item = item:gsub("<recordId>", quotedId)
    item = item:gsub("<name>", yaml_quote(name and name ~= "" and name or recordId))

    -- ensure requirements is explicitly an empty list and add flags as empty list
    if not item:find("\n%s*requirements:%s*$") then
        item = item .. "\n    requirements:"
    end
    item = item .. " []\n    flags: []\n"

    -- append under the inner "Saved Items:" line if present; otherwise just append
    if storedYaml:find("\n%s*Saved Items:%s*\n%s*%sSaved Items:%s*$") then
        -- ends right after the inner key -> just tack on the item
        storedYaml = storedYaml .. item
    else
        -- if file ends without newline, add one
        if not storedYaml:match("\n$") then storedYaml = storedYaml .. "\n" end
        storedYaml = storedYaml .. item
    end

    ui.showMessage(("Added to YAML: %s"):format(recordId))
    debug.reloadLua()
end
local function textChanged(firstField)
    currentText = firstField or ""
end
local function buttonClick()
    createObjectBox:destroy()
    I.UI.setMode()
    generateAndStoreYaml(currentRecordId,currentText)
end
local function swingAt()
    if (self.controls.use > 0 and types.Actor.stance(self) == types.Actor.STANCE.Weapon) then
        wasSwinging = true
        --  config.print("Swinging")
    else
        if (wasSwinging == true and not isRelease) then
            local swingAt = zutils.getObjInCrosshairs()
            local equip = types.Actor.getEquipment(self)
            local weapon = equip[types.Actor.EQUIPMENT_SLOT.CarriedRight]
            if (swingAt and swingAt.hitObject and weapon and weapon.type == types.Weapon) then
                local wrecord = types.Weapon.record(weapon)
                local isPickaxe = wrecord.icon == "icons\\w\\tx_miner_pick.dds"
                local isAxe = wrecord.type == types.Weapon.TYPE.AxeOneHand
                if isPickaxe then
                    currentRecordId = swingAt.hitObject.recordId
                    ui.showMessage(swingAt.hitObject.recordId)
                    createObjectBox = I.DaisyUtilsUI_AA.renderTextInput(
                        { "", "", "What is the name of this object?" },
                        "",
                        textChanged,
                        buttonClick
                    )
                    I.UI.setMode("Interface", { windows = {} })
                end
            end

            wasSwinging = false
        end
    end
end
local function onUpdate()

end
local function onFrame()
    swingAt()
end
return {
    interfaceName = "AA_CustomObject",
    interface = {getYaml = function ()
        return storedYaml
    end},
    engineHandlers = {
        onFrame = onFrame,
        onSave = function ()
            return {
                storedYaml = storedYaml
            }
        end,
        onLoad = function (data)
            if data then
                storedYaml = data.storedYaml
            end
        end
    }
}
