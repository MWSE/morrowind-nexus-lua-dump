local sb_achievements = require("sb_achievements.interop")
local success, macModule = pcall(require, "MAC.playerData")
local pData
if success then
    pData = macModule
else
    pData = {
        colours = {
            bronze  = { 255 / 255, 140 / 255, 20 / 255 },
            silver  = { 200 / 255, 200 / 255, 255 / 255 },
            gold    = { 203 / 255, 190 / 255, 53 / 255 },
            plat    = { 200 / 255, 240 / 255, 200 / 255 }
        }
    }
end

local function init()
    local iconPath = "Icons\\INTA\\"
    local cats = {
        main = sb_achievements.registerCategory("Главные задания"),
        side = sb_achievements.registerCategory("Побочные задания")
    }
    sb_achievements.registerAchievement {
        id        = "INTABottom",
        category  = cats.side,
        condition = function()
            ---@param activator tes3activator
            for activator in tes3.player.cell:iterateReferences(tes3.objectType.activator) do
                if (activator.baseObject.id == "INTA_07_WayShrineVA_01" and (activator.position:distance(tes3.player.position) < 4096)) then
                    return true
                end
            end
            return false
        end,
        icon      = iconPath .. "ic_v_mq.dds",
        colour    = pData.colours.bronze,
        title     = "Ниже некуда", desc = "Доберитесь до дна Бездны.",
    }
    sb_achievements.registerAchievement {
        id        = "INTABottomChallenge",
        category  = cats.side,
        condition = function()
            ---@param activator tes3activator
            for activator in tes3.player.cell:iterateReferences(tes3.objectType.activator) do
                if (activator.baseObject.id == "INTA_07_WayShrineVA_01" and (activator.position:distance(tes3.player.position) < 4096)) then
                    for _, spell in pairs(tes3.player.object.spells) do
                        if spell.castType == tes3.spellType.curse then
                            return false
                        end
                    end
                    return true
                end
            end
            return false
        end,
        icon      = iconPath .. "ic_v_challenge.dds",
        colour    = pData.colours.gold,
        title     = "Проклятья не существует", desc = "Доберитесь до дна Бездны... не попав под действие Проклятья!",
        configDesc = sb_achievements.configDesc.groupHidden
    }
    sb_achievements.registerAchievement {
        id        = "INTAWayshrine",
        category  = cats.side,
        condition = function()
            if (tes3.getGlobal("INTA_WayShrine_01") > 0 and
                tes3.getGlobal("INTA_WayShrine_02") > 0 and
                tes3.getGlobal("INTA_WayShrine_03") > 0 and
                tes3.getGlobal("INTA_WayShrine_04") > 0 and
                tes3.getGlobal("INTA_WayShrine_05") > 0 and
                tes3.getGlobal("INTA_WayShrine_06") > 0 and
                tes3.getGlobal("INTA_WayShrine_07") > 0) then
                return true
            end
            return false
        end,
        icon      = iconPath .. "ic_v_shrine.dds",
        colour    = pData.colours.gold,
        title     = "Общественный транспорт", desc = "Активируйте все Путевые святилища в Бездне.",
        configDesc = sb_achievements.configDesc.groupHidden
    }
end

local function initializedCallback(e)
    init()
end
event.register("initialized", initializedCallback, { priority = sb_achievements.priority + 1 })