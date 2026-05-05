local async = require("openmw.async")
local camera = require("openmw.camera")
local core = require("openmw.core")
local input = require("openmw.input")
local self = require("openmw.self")
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local vfs = require("openmw.vfs")

local settings = require("scripts.action-camera-swap.settings")

local dofName = "acs_dof"
local dofPath = "Shaders/" .. dofName .. ".omwfx"
local pp = require("openmw.postprocessing")
local dofShader
if vfs.fileExists(dofPath) then dofShader = pp.load(dofName) end

local hasStats = false
local inFirstPerson = camera.getMode() == camera.MODE.FirstPerson
local interior1st = false
local swapping = false

local TO_FIRST_DELAY = .1
local TO_THIRD_DELAY = .3

if not (core.API_REVISION >= 70) then
	ui.showMessage("OpenMW 0.49 or newer is required to use Action Camera Swap! The mod will not exit, unable to start...")
    error("OpenMW 0.49 or newer is required to use Action Camera Swap! The mod will not exit, unable to start...")
end

-- Support for Morrowind Interiors Project
-- https://www.nexusmods.com/morrowind/mods/52237
-- This is how I generated the below table:
-- for cell in (grep -A1 type:\ Cell MorrowindInteriorsProject.yaml | grep name:\ \" | grep -v MIP, | awk -F\" '{ print $2 }'); echo [\"$cell\"] = true,; end
local mipExteriorInteriors = {
    -- Morrowind
    ["Caldera, Canodia Felannus' House"] = true,
    ["Caldera, Elmussa Damori's House"] = true,
    ["Caldera, Falanaamo: Clothier"] = true,
    ["Caldera, Ghorak Manor"] = true,
    ["Caldera, Irgola: Pawnbroker"] = true,
    ["Caldera, Shenk's Shovel"] = true,
    ["Caldera, Valvius Mevureius' House"] = true,
    ["Caldera, Verick Gemain: Trader"] = true,
    ["Gnisis, Arvs-Drelen"] = true,
    ["Gnisis, Barracks"] = true,
    ["Gnisis, Madach Tradehouse"] = true,
    ["Gnisis, Temple"] = true,
    ["Maar Gan, Andus Tradehouse"] = true,
    ["Maar Gan, Garry's Hut"] = true,
    ["Molag Mar, Redoran Stronghold"] = true,
    ["Molag Mar, St. Veloth's Hostel"] = true,
    ["Molag Mar, Temple"] = true,
    ["Pelagiad, Ahnassi's House"] = true,
    ["Pelagiad, Dralas Gilu's House"] = true,
    ["Pelagiad, Halfway Tavern"] = true,
    ["Pelagiad, Mebestien Ence: Trader"] = true,
    ["Pelagiad, Uulernil : Armorer"] = true,
    ["Sadrith Mora, Dirty Muriel's Cornerclub"] = true,
    -- TR
    ["Almas Thirr, Danse Orani's House"] = true,
    ["Almas Thirr, Feldil Vulunith: Armorer"] = true,
    ["Almas Thirr, Hall of Tribute"] = true,
    ["Almas Thirr, Ivrea Llothro's House"] = true,
    ["Almas Thirr, Morag Tong Guildhall"] = true,
    ["Almas Thirr, Nelos Llothri's House"] = true,
    ["Almas Thirr, Plaza"] = true,
    ["Almas Thirr, Ralis Nalor's House"] = true,
}
local haveMIP = core.contentFiles.has("MorrowindInteriorsProject.ESP")

local quickKeys = {
    [input.ACTION.QuickKey1] = true,
    [input.ACTION.QuickKey2] = true,
    [input.ACTION.QuickKey3] = true,
    [input.ACTION.QuickKey4] = true,
    [input.ACTION.QuickKey5] = true,
    [input.ACTION.QuickKey6] = true,
    [input.ACTION.QuickKey7] = true,
    [input.ACTION.QuickKey8] = true,
    [input.ACTION.QuickKey9] = true,
    [input.ACTION.QuickKey10] = true
}

local function msg(str)
    if settings.showMessages() then
        print(string.format("[%s]: %s", settings.MOD_NAME, str))
    end
end

local function isQuickKeyPressed(id) return quickKeys[id] end

local function isExterior()
    local thisCell = self.cell
    if haveMIP and mipExteriorInteriors[thisCell.name] then
        return false
    end
    return thisCell.isExterior or thisCell:hasTag("QuasiExterior")
end

local function dof()
    if not settings.dofOn() or dofShader == nil then return end

    if inFirstPerson or (not inFirstPerson and not settings.dofSwap()) then
        if not dofShader:isEnabled() then
            msg("Enabling DoF shader")
            local chainNum = settings.dofChainNum() - 1
            if chainNum == -1 then
                dofShader:enable()
            else
                dofShader:enable(chainNum)
            end
        end
    elseif settings.dofSwap() then
        if dofShader:isEnabled() then
            msg("Disabling DoF shader")
            dofShader:disable()
        end
    end
end

local function toFirst()
    swapping = false
    if not inFirstPerson then
        msg("Setting 1st person camera")
        camera.setMode(camera.MODE.FirstPerson)
        inFirstPerson = true
    end
    dof()
end

local toFirstCallback = async:registerTimerCallback(
    "acs_swapToFirstPerson", toFirst
)

local function toFirstAsync()
    if swapping then return end
    swapping = true
    async:newSimulationTimer(TO_FIRST_DELAY, toFirstCallback)
end

local function toThird()
    swapping = false
    if inFirstPerson then
        msg("Setting 3rd person camera")
        camera.setMode(camera.MODE.ThirdPerson)
        inFirstPerson = false
    end
    dof()
end

local toThirdCallback = async:registerTimerCallback(
    "acs_swapToThirdPerson", toThird
)

local function toThirdAsync()
    if swapping then return end
    swapping = true
    async:newSimulationTimer(TO_THIRD_DELAY, toThirdCallback)
end

local function spellWeaponSwap()
    local cb, delay
    if self.type.stance(self) ~= self.type.STANCE.Nothing then
        cb = toFirstCallback
        -- Just a slight delay gives the impression of a swap animation
        delay = TO_FIRST_DELAY
    else
        if not isExterior() then return end
        cb = toThirdCallback
        -- There needs to be a bit more of a delay when
        -- swapping to 3rd person to avoid seeing a snap
        delay = TO_THIRD_DELAY
    end
    async:newSimulationTimer(delay, cb)
end

local function onInputAction(id)
    if not hasStats or not settings.modEnabled() then return end
    if interior1st then return end

    if
        id == input.ACTION.ToggleSpell
        or id == input.ACTION.ToggleWeapon
    then
        spellWeaponSwap()
        return
    end

    -- Quick keys don't trigger the ToggleSpell or ToggleWeapon
    -- actions, so scan for their usage as well.
    if isQuickKeyPressed(id) then spellWeaponSwap() end
end

local function onLoad(data)
    if data then
        hasStats = data.hasStats
        interior1st = data.interior1st
    end
end

local function onSave()
    return {
        hasStats = hasStats,
        interior1st = interior1st,
        version = settings.scriptVersion
    }
end

local function onUpdate()
    if not hasStats and self.type.isCharGenFinished(self) then
        hasStats = true
    elseif not hasStats then
        return
    end

    if not settings.modEnabled() or I.UI.getMode() then
        return
    end

    local camMode = camera.getMode()
    local exterior = isExterior()
    local currentStance = self.type.stance(self)
    local inThird = camMode == camera.MODE.ThirdPerson
        or camMode == camera.MODE.Preview
    local inFirst = camMode == camera.MODE.FirstPerson
    local inCombatStance = currentStance == self.type.STANCE.Spell
        or currentStance == self.type.STANCE.Weapon
    local nothingStance = currentStance == self.type.STANCE.Nothing

    if not exterior and inFirst and not interior1st then
        interior1st = true
    end

    local wantFirst = inCombatStance or (not exterior and settings.always1stIndoors())
    local wantThird = nothingStance and (exterior or not settings.always1stIndoors())

    if wantFirst and inThird then
        toFirstAsync()
        if not exterior then interior1st = true end
    elseif wantThird and inFirst and (exterior or interior1st) then
        toThirdAsync()
        interior1st = false
    end
end

return {
    engineHandlers = {
        onInputAction = onInputAction,
        onLoad = onLoad,
        onSave = onSave,
        onUpdate = onUpdate
    },
    interfaceName = settings.MOD_NAME,
    interface = {
        version = 3,
        Always1stIndoors = function() return settings.always1stIndoors() end,
        DoFOn = function() return settings.dofOn() end,
        DoFSwap = function() return settings.dofSwap() end,
        DoFChainNum = function() return settings.dofChainNum() end,
        DoFBaseBlurRadius = function() return settings.dofBaseBlurRadius() end,
        DoFBlurFalloff = function() return settings.dofBlurFalloff() end,
        DoFMaxBlurRadius = function() return settings.dofMaxBlurRadius() end,
        ModEnabled = function() return settings.modEnabled() end,
    }
}
