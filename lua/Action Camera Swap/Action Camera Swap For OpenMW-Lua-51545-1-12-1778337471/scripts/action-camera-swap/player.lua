local async = require("openmw.async")
local camera = require("openmw.camera")
local core = require("openmw.core")
local input = require("openmw.input")
local self = require("openmw.self")
local ui = require("openmw.ui")
if core.API_REVISION <= 70 then
	ui.showMessage("OpenMW 0.49 or newer is required to use Action Camera Swap! The mod will not exit, unable to start...")
    error("OpenMW 0.49 or newer is required to use Action Camera Swap! The mod will not exit, unable to start...")
end
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
local swapping = nil

-- Support for Morrowind Interiors Project https://www.nexusmods.com/morrowind/mods/52237
-- Generated with: for cell in (grep -A1 type:\ Cell MorrowindInteriorsProject.yaml | grep name:\ \" | grep -v MIP, | awk -F\" '{ print $2 }'); echo [\"$cell\"] = true,; end
local mipCells = {}
if core.contentFiles.has("MorrowindInteriorsProject.ESP") then
    print(string.format("[%s]: Registering support for MorrowindInteriorsProject.ESP", settings.MOD_NAME))
	for cell, _ in pairs({
            ["Caldera, Canodia Felannus' House"] = true,
            ["Caldera, Elmussa Damori's House"] = true,
            ["Caldera, Falanaamo: Clothier"] = true,
            ["Caldera, Ghorak Manor"] = true,
            ["Caldera, Irgola: Pawnbroker"] = true,
            ["Caldera, Shenk's Shovel"] = true,
            ["Caldera, Valvius Mevureius' House"] = true,
            ["Caldera, Verick Gemain: Trader"] = true,
            ["Ebonheart, Six Fishes"] = true,
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
    }) do mipCells[cell] = true end
end
if core.contentFiles.has("MorrowindInteriorsProject_Bloodmoon.ESP") then
    print(string.format("[%s]: Registering support for MorrowindInteriorsProject_Bloodmoon.ESP", settings.MOD_NAME))
	for cell, _ in pairs({
            ["Raven Rock, Bar"] = true,
            ["Raven Rock, Uryn Maren's House"] = true,
            ["Skaal Village, Ice-Mane's Hut"] = true,
            ["Skaal Village, Ingmar's House"] = true,
            ["Skaal Village, Rigmor's Hut"] = true,
            ["Skaal Village, Shaman's Hut"] = true,
    }) do mipCells[cell] = true end
end
if core.contentFiles.has("MorrowindInteriorsProject_TR.ESP") then
    print(string.format("[%s]: Registering support for MorrowindInteriorsProject_TR.ESP", settings.MOD_NAME))
	for cell, _ in pairs({
            ["Almas Thirr, Danse Orani's House"] = true,
            ["Almas Thirr, Feldil Vulunith: Armorer"] = true,
            ["Almas Thirr, Hall of Tribute"] = true,
            ["Almas Thirr, Ivrea Llothro's House"] = true,
            ["Almas Thirr, Morag Tong Guildhall"] = true,
            ["Almas Thirr, Nelos Llothri's House"] = true,
            ["Almas Thirr, Plaza"] = true,
            ["Almas Thirr, Ralis Nalor's House"] = true,
    }) do mipCells[cell] = true end
end

local function msg(str)
    if not settings.showMessages() then return end
    print(string.format("[%s]: %s", settings.MOD_NAME, str))
end

local function isExterior()
    local thisCell = self.cell
    if next(mipCells) and mipCells[thisCell.name] then return false end
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
    if inFirstPerson then return end
    msg("Setting 1st person camera")
    camera.setMode(camera.MODE.FirstPerson)
    swapping = "first"
end

local function toThird()
    if not inFirstPerson then return end
    msg("Setting 3rd person camera")
    camera.setMode(camera.MODE.ThirdPerson)
    swapping = "third"
end

local function onLoad(data)
    if not data then return end
    hasStats = data.hasStats
    inFirstPerson = data.inFirstPerson
    swapping = data.swapping
end

local function onSave()
    return {
        hasStats = hasStats,
        inFirstPerson = inFirstPerson,
        swapping = swapping,
        version = settings.scriptVersion
    }
end

local function onUpdate()
    if not hasStats and self.type.isCharGenFinished(self) then hasStats = true
    elseif not hasStats then return end
    if not settings.modEnabled() or I.UI.getMode() then return end
    if swapping ~= nil then
        inFirstPerson = camera.getMode() == camera.MODE.FirstPerson
        if (swapping == "first" and inFirstPerson) or (swapping == "third" and not inFirstPerson) then
            swapping = nil
            dof()
        else return end
    end
    local exterior = isExterior()
    local currentStance = self.type.stance(self)
    local inCombatStance = currentStance == self.type.STANCE.Spell or currentStance == self.type.STANCE.Weapon
    local nothingStance = currentStance == self.type.STANCE.Nothing
    local wantFirst = inCombatStance or (not exterior and settings.always1stIndoors())
    local wantThird = nothingStance and (exterior or not settings.always1stIndoors())
    if wantFirst and not inFirstPerson then
        toFirst()
    elseif wantThird and inFirstPerson then
        toThird()
    end
end

local dofCheckCb = async:registerTimerCallback(
    "acs_dofCheck", function()
        local in1st = camera.getMode() == camera.MODE.FirstPerson
        local dofEnabled = dofShader:isEnabled()
        if in1st and not dofEnabled then
            msg("Enabling DoF shader")
            local chainNum = settings.dofChainNum() - 1
            if chainNum == -1 then
                dofShader:enable()
            else
                dofShader:enable(chainNum)
            end
        elseif settings.dofSwap() and not in1st and dofEnabled then
            msg("Disabling DoF shader")
            dofShader:disable()
        end
end)

-- In case the player manually swaps
input.registerActionHandler(
    "TogglePOV", async:callback(
        function(press)
            if not settings.dofOn() or not press then return end
            -- .2 _should_ be enough time for the camera change to process but not _too_ much time.
            async:newSimulationTimer(.2, dofCheckCb)
end))

return {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
        onUpdate = onUpdate
    },
    interfaceName = settings.MOD_NAME,
    interface = {
        version = 4,
        DoFOn = function() return settings.dofOn() end,
        DoFSwap = function() return settings.dofSwap() end,
        DoFChainNum = function() return settings.dofChainNum() end,
        DoFBaseBlurRadius = function() return settings.dofBaseBlurRadius() end,
        DoFBlurFalloff = function() return settings.dofBlurFalloff() end,
        DoFMaxBlurRadius = function() return settings.dofMaxBlurRadius() end,
        ModEnabled = function() return settings.modEnabled() end,
    }
}
