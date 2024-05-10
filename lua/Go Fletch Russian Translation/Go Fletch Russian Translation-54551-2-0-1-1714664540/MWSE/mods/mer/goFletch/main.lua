local configPath = "go_fletch"
local registerRecipes = require("mer.goFletch.registerRecipes")
local config = mwse.loadConfig(configPath)
if (config == nil) then
	config = {
        fletchFromInventory = false,
        dontShowAgain = false
    }
end


--INITIALISE SKILLS--
local skillModule = include("OtherSkills.skillModule")

--Initialise Recipes



local function noSkillsMessage(e)
    if e.button == 0 then
        os.execute("start https://www.nexusmods.com/morrowind/mods/46034")
    elseif e.button == 1 then
        config.dontShowAgain = true
        mwse.saveConfig(configPath, config)
    end
end

local charGen
local function checkCharGen()
    if charGen.value == -1 then
        if ( not skillModule ) and ( not config.dontShowAgain ) then
            tes3.messageBox({
                message = "Для работы с Оперением требуется установить модуль навыков!",
                buttons = { "Перейти на страницу модуля навыков Nexus", "Не показывать снова", "Отмена"},
                callback = noSkillsMessage
            })
        end
        event.unregister("simulate", checkCharGen)
        local agilBase = tes3.mobilePlayer.attributes[tes3.attribute.agility + 1].base
        local startingSkill = math.remap(agilBase, 0, 100, 10, 20)

        local fletchingDescription = (
            "Владение навыком оперение позволяет создавать стрелы, болты и дротики из подручных материалов. Уровень развития влияет на возможность изготавливать зачарованные стрелы."
        )
        skillModule.registerSkill(
            "fletching",
            {
                name = "Оперение",
                icon = "Icons/fletching/skill.dds",
                value = startingSkill,
                attribute =  tes3.attribute.agility,
                description = fletchingDescription,
                specialization = tes3.specialization.stealth
            }
        )
    end
end
local function onSkillsReady()
    charGen = tes3.findGlobal("CharGenState")
    event.unregister("simulate", checkCharGen)
    event.register("simulate", checkCharGen)
end
event.register("OtherSkills:Ready", onSkillsReady)


-- local function fletchTooltip(e)
--     if e.object.id == "mer_fletch_kit" then
--         e.tooltip:findChild(tes3ui.registerID("HelpMenu_uses")).visible = false
--         e.tooltip:findChild(tes3ui.registerID("HelpMenu_qualityCondition")).visible = false
--     end
-- end

-- event.register("uiObjectTooltip", fletchTooltip)

local function initialised()
    mwse.log("Registering Fletching Recipes")
    registerRecipes()
end

event.register("initialized", initialised)



--------------------------------------------
--MCM
--------------------------------------------

local function registerMCM()
    local  sideBarDefault = (
        "Мод Оперение добавляет в игру новый навык \"Оперение\", " ..
        "используя современные возможности MWSE и модуля ремесла, " ..
        "чтобы полностью интегрировать его в оригинальный пользовательский интерфейс. \n\n" ..
        "Приобретите приспособление для изготовления оперения у различных кузнецов и " ..
        "торговцев оружием, установите его и активируйте, чтобы открыть " ..
        "меню изготовления оперения. Выберите, что нужно изготовить: стрелы, болты " ..
        "или дротики. \n\n" ..
        "Ваш навык владения оперением расположен в меню статистики в разделе " ..
        "\"Другие навыки\". Ваш навык будет варьироваться от 10 до 20 " ..
        "в зависимости от ловкости."
    )
    local function addSideBar(component)
        component.sidebar:createInfo{ text = sideBarDefault}
        local hyperlink = component.sidebar:createCategory("Авторы: ")
        hyperlink:createHyperLink{
            text = "Программирование: Merlord",
            exec = "start https://www.nexusmods.com/users/3040468?tab=user+files",
        }
        hyperlink:createHyperLink{
            text = "Моделирование: Remiros",
            exec = "start https://www.nexusmods.com/morrowind/users/899234?tab=user+files",
        }
    end

    local  fletchFromInventoryDescription = (
        "Если эта функция включена, вы можете получить доступ к меню изготовления, экипировав " ..
        "станцию оперения в вашем инвентаре. Когда функция отключена, вы можете " ..
        "активировать станцию только после того, как разместите ее на поверхности."
    )


    local template = mwse.mcm.createTemplate("Оперение")
    template:saveOnClose(configPath, config)
    local page = template:createSideBarPage{}
    addSideBar(page)

    page:createOnOffButton{
        label = "Оперение из инвентаря",
        variable = mwse.mcm.createTableVariable{
            id = "fletchFromInventory",
            table = config
        },
        description = fletchFromInventoryDescription
    }

    template:register()
end

event.register("modConfigReady", registerMCM)