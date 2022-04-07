local confPath = "attributeCarrier"
local config = mwse.loadConfig(confPath)
if not config then
    config = { mode = 1 }
end

local attrPreLevel = {} -- USADO PARA CHECAR QUAIS ATRIBUTOS SUBIRAM
local attrUpPreLevel = {} -- USADO PARA DESCONTAR DAS VARIAVEIS QUANTOS SKILLUPS FORAM USADOS
local attribUpToDecrease = {}

-- INICIALIZA O MOD CASO SEJA A PRIMEIRA VEZ PASSANDO OS VALORES DE levelupsPerAttribute PARA AS GLOBAIS

local function inicializar(levelupsPerAttribute)
    if tes3.getGlobal("ACIsInit") ~= 1 then

        tes3.setGlobal("ACIsInit", 1)
        print(levelupsPerAttribute)

        tes3.setGlobal("ACStrength", levelupsPerAttribute[1])
        tes3.setGlobal("ACIntelligence", levelupsPerAttribute[2])
        tes3.setGlobal("ACWillpower", levelupsPerAttribute[3])
        tes3.setGlobal("ACAgility", levelupsPerAttribute[4])
        tes3.setGlobal("ACSpeed", levelupsPerAttribute[5])
        tes3.setGlobal("ACEndurance", levelupsPerAttribute[6])
        tes3.setGlobal("ACPersonality", levelupsPerAttribute[7])
        tes3.setGlobal("ACLuck", levelupsPerAttribute[8])

        print("Inicializado com sucesso!")
        return true
    else
        return false
    end
end

local function getGlobalName(g) -- RETORNA O NOME DAS GLOBAIS DO .ESP COM BASE NO INDICE DO mwse

    if g == 1 then
        return "ACStrength"
    elseif g == 2 then
        return "ACIntelligence"
    elseif g == 3 then
        return "ACWillpower"
    elseif g == 4 then
        return "ACAgility"
    elseif g == 5 then
        return "ACSpeed"
    elseif g == 6 then
        return "ACEndurance"
    elseif g == 7 then
        return "ACPersonality"
    elseif g == 8 then
        return "ACLuck"
    else
        return nil
    end

end

-- VANILLA MODE PRE LEVEL UP
local function vanillaModePre(e)

    print("PREUP--------------------------------------------- \n")
    print("You're using VANILLA MODE")

    local init__ = inicializar(tes3.mobilePlayer.levelupsPerAttribute)
    print("inicializar: " .. tostring(init__))

    for i = 1, 8, 1 do

        -- ARMAZENA OS ATRIBUTOS E OS SKILLUPS PARA COMPARAÇÃO
        attrPreLevel[i] = tes3.mobilePlayer.attributes[i].base
        attrUpPreLevel[i] = tes3.getGlobal(getGlobalName(i))

        -- VANILLA MODE
        -- EVITA QUE MAIS QUE 10 SKILLUPS SEJAM DESCONTADOS
        if tes3.mobilePlayer.levelupsPerAttribute[i] <= 10 then
            attribUpToDecrease[i] = tes3.mobilePlayer.levelupsPerAttribute[i]
        else
            attribUpToDecrease[i] = 10
        end

        print(string.sub(getGlobalName(i), 3, -1) .. string.rep(" ", 14 - #getGlobalName(i)) .. "\n\t" ..
                  "attrPreLevel: " .. attrPreLevel[i] .. "\n\t" .. 
                  "attrUpPreLevel: " .. attrUpPreLevel[i] .. "\n\t" ..
                  "tes3.mobilePlayer.levelupsPerAttribute:" .. tes3.mobilePlayer.levelupsPerAttribute[i] .. "\n\t" ..
                  "attribUpToDecrease" .. attribUpToDecrease[i])

    end

    for i = 1, 8, 1 do

    end

    print("\n---------------------------------------------PREUP\n")

end


-- VANILLA MODE POST LEVEL UP
local function vanillaModePost(e)

    print("POSTUP-------------------------------------------- \n")

    for i = 1, 8, 1 do

        if attrPreLevel[i] ~= tes3.mobilePlayer.attributes[i].base then -- CHECA SE O ATRIBUTO i SUBIU      

            if attrUpPreLevel[i] > 0 then

                if attrUpPreLevel[i] >= 10 then
                    tes3.setGlobal(getGlobalName(i), tes3.getGlobal(getGlobalName(i)) - 10)

                elseif attrUpPreLevel[i] >= 9 then
                    tes3.setGlobal(getGlobalName(i), tes3.getGlobal(getGlobalName(i)) - attribUpToDecrease[i])

                elseif attrUpPreLevel[i] >= 7 then
                    tes3.setGlobal(getGlobalName(i), tes3.getGlobal(getGlobalName(i)) - attribUpToDecrease[i])

                elseif attrUpPreLevel[i] >= 1 then
                    tes3.setGlobal(getGlobalName(i), tes3.getGlobal(getGlobalName(i)) - attribUpToDecrease[i])
                end
            end
        end

        attribUpToDecrease[i] = nil

        tes3.mobilePlayer.levelupsPerAttribute[i] = tes3.getGlobal(getGlobalName(i))

        print(string.sub(getGlobalName(i), 3, -1) .. string.rep(" ", 14 - #getGlobalName(i)) .. "\n\t" ..
                  "attrPreLevel: " .. attrPreLevel[i] .. "\n\t" .. 
                  "attrUpPreLevel: " .. attrUpPreLevel[i] .. "\n\t" ..
                  "tes3.mobilePlayer.levelupsPerAttribute:" .. tes3.mobilePlayer.levelupsPerAttribute[i] .. "\n\t" ..
                  "tes3.mobilePlayer.attributes.base= " .. tes3.mobilePlayer.attributes[i].base)
                  

        

    end

    print("\n--------------------------------------------------\n")

end


-- MINIMAL MODE PRE LEVEL UP
local function minimalModePre(e)

    print("PREUP--------------------------------------------- \n")
    print("You're using MINIMAL MODE")

    local init__ = inicializar(tes3.mobilePlayer.levelupsPerAttribute)
    print("inicializar: " .. tostring(init__))

    -- ARMAZENA OS ATRIBUTOS E OS SKILLUPS PARA COMPARAÇÃO
    for i = 1, 8, 1 do
        attrPreLevel[i] = tes3.mobilePlayer.attributes[i].base
        attrUpPreLevel[i] = tes3.mobilePlayer.levelupsPerAttribute[i]
        tes3.mobilePlayer.levelupsPerAttribute[i] = tes3.getGlobal(getGlobalName(i))

        print(string.sub(getGlobalName(i), 3, -1) .. string.rep(" ", 14 - #getGlobalName(i)) .. "\n\t" ..
                  "attrPreLevel: " .. attrPreLevel[i] .. "\n\t" .. 
                  "attrUpPreLevel: " .. attrUpPreLevel[i] .. "\n\t" ..
                  "tes3.mobilePlayer.levelupsPerAttribute:" .. tes3.mobilePlayer.levelupsPerAttribute[i])

    end

    print("\n---------------------------------------------PREUP\n")

end


-- MINIMAL MODE POST LEVEL UP
local function minimalModePost(e)

    print("POSTUP-------------------------------------------- \n")

    for i = 1, 8, 1 do

        if attrPreLevel[i] ~= tes3.mobilePlayer.attributes[i].base then -- CHECA SE O ATRIBUTO i SUBIU      

            if attrUpPreLevel[i] > 0 then

                if attrUpPreLevel[i] >= 10 then
                    tes3.setGlobal(getGlobalName(i), tes3.getGlobal(getGlobalName(i)) - 10)

                elseif attrUpPreLevel[i] >= 8 then
                    tes3.setGlobal(getGlobalName(i), tes3.getGlobal(getGlobalName(i)) - 8)

                elseif attrUpPreLevel[i] >= 5 then
                    tes3.setGlobal(getGlobalName(i), tes3.getGlobal(getGlobalName(i)) - 5)

                elseif attrUpPreLevel[i] >= 1 then
                    tes3.setGlobal(getGlobalName(i), tes3.getGlobal(getGlobalName(i)) - 1)

                end
            end
        end

        tes3.mobilePlayer.levelupsPerAttribute[i] = tes3.getGlobal(getGlobalName(i))

        print(string.sub(getGlobalName(i), 3, -1) .. string.rep(" ", 14 - #getGlobalName(i)) .. "\n\t" ..
                  "attrPreLevel: " .. attrPreLevel[i] .. "\n\t" .. 
                  "attrUpPreLevel: " .. attrUpPreLevel[i] .. "\n\t" ..
                  "tes3.mobilePlayer.levelupsPerAttribute:" .. tes3.mobilePlayer.levelupsPerAttribute[i] .. "\n\t" ..
                  "tes3.mobilePlayer.attributes.base= " .. tes3.mobilePlayer.attributes[i].base)

    end

    print("\n--------------------------------------------------\n")

end


-- ALTERNATIVE MODE PRE LEVEL UP
local function alternativeModePre(e)

    print("PREUP--------------------------------------------- \n")
    print("You're using ALTERNATIVE MODE")

    local init__ = inicializar(tes3.mobilePlayer.levelupsPerAttribute)
    print("inicializar: " .. tostring(init__))

    for i = 1, 8, 1 do

        -- ARMAZENA OS ATRIBUTOS E OS SKILLUPS PARA COMPARAÇÃO
        attrPreLevel[i] = tes3.mobilePlayer.attributes[i].base
        attrUpPreLevel[i] = tes3.getGlobal(getGlobalName(i))

        -- ALTERNATIVE MODE
        if tes3.getGlobal(getGlobalName(i)) >= 10 then
            tes3.mobilePlayer.levelupsPerAttribute[i] = 10
        elseif tes3.getGlobal(getGlobalName(i)) >= 8 then
            tes3.mobilePlayer.levelupsPerAttribute[i] = 8
        elseif tes3.getGlobal(getGlobalName(i)) >= 6 then
            tes3.mobilePlayer.levelupsPerAttribute[i] = 6
        elseif tes3.getGlobal(getGlobalName(i)) >= 4 then
            tes3.mobilePlayer.levelupsPerAttribute[i] = 4
        else
            tes3.mobilePlayer.levelupsPerAttribute[i] = 0
        end

        print(string.sub(getGlobalName(i), 3, -1) .. string.rep(" ", 14 - #getGlobalName(i)) .. "\n\t" ..
                  "attrPreLevel: " .. attrPreLevel[i] .. "\n\t" .. 
                  "attrUpPreLevel: " .. attrUpPreLevel[i] .. "\n\t" ..
                  "tes3.mobilePlayer.levelupsPerAttribute:" .. tes3.mobilePlayer.levelupsPerAttribute[i])

    end

    print("\n---------------------------------------------PREUP\n")

end


-- ALTERNATIVE MODE POST LEVEL UP
local function alternativeModePost(e)

    print("POSTUP-------------------------------------------- \n")

    for i = 1, 8, 1 do

        if attrPreLevel[i] ~= tes3.mobilePlayer.attributes[i].base then -- CHECA SE O ATRIBUTO i SUBIU      

            if attrUpPreLevel[i] > 0 then

                if attrUpPreLevel[i] >= 10 then
                    tes3.setGlobal(getGlobalName(i), tes3.getGlobal(getGlobalName(i)) - 10)

                elseif attrUpPreLevel[i] >= 8 then
                    tes3.setGlobal(getGlobalName(i), tes3.getGlobal(getGlobalName(i)) - 8)

                elseif attrUpPreLevel[i] >= 6 then
                    tes3.setGlobal(getGlobalName(i), tes3.getGlobal(getGlobalName(i)) - 6)

                elseif attrUpPreLevel[i] >= 4 then
                    tes3.setGlobal(getGlobalName(i), tes3.getGlobal(getGlobalName(i)) - 4)
                end
            end
        end

        tes3.mobilePlayer.levelupsPerAttribute[i] = tes3.getGlobal(getGlobalName(i))

        print(string.sub(getGlobalName(i), 3, -1) .. string.rep(" ", 14 - #getGlobalName(i)) .. "\n\t" ..
                  "attrPreLevel: " .. attrPreLevel[i] .. "\n\t" .. 
                  "attrUpPreLevel: " .. attrUpPreLevel[i] .. "\n\t" ..
                  "tes3.mobilePlayer.levelupsPerAttribute:" .. tes3.mobilePlayer.levelupsPerAttribute[i] .. "\n\t" ..
                  "tes3.mobilePlayer.attributes.base= " .. tes3.mobilePlayer.attributes[i].base)
    end

    print("\n--------------------------------------------------POSTUP\n")

end

-- REGISTRA CADA SKILLUP NA SUA GLOBAL CORERSPONDENTE
local function skillRaisedCallback(e)

    if not inicializar(tes3.mobilePlayer.levelupsPerAttribute) then

        if e.skill == tes3.skill.acrobatics or e.skill == tes3.skill.armorer or e.skill == tes3.skill.axe or e.skill ==
            tes3.skill.bluntWeapon or e.skill == tes3.skill.longBlade then
            tes3.setGlobal("ACStrength", tes3.getGlobal("ACStrength") + 1)
        end

        if e.skill == tes3.skill.alchemy or e.skill == tes3.skill.conjuration or e.skill == tes3.skill.enchant or
            e.skill == tes3.skill.security then
            tes3.setGlobal("ACIntelligence", tes3.getGlobal("ACIntelligence") + 1)
        end

        if e.skill == tes3.skill.alteration or e.skill == tes3.skill.destruction or e.skill == tes3.skill.mysticism or
            e.skill == tes3.skill.restoration then
            tes3.setGlobal("ACWillpower", tes3.getGlobal("ACWillpower") + 1)
        end

        if e.skill == tes3.skill.block or e.skill == tes3.skill.lightArmor or e.skill == tes3.skill.Marksman or e.skill ==
            tes3.skill.Sneak then
            tes3.setGlobal("ACAgility", tes3.getGlobal("ACAgility") + 1)
        end

        if e.skill == tes3.skill.athletics or e.skill == tes3.skill.handToHand or e.skill == tes3.skill.shortBlade or
            e.skill == tes3.skill.unarmored then
            tes3.setGlobal("ACSpeed", tes3.getGlobal("ACSpeed") + 1)
        end

        if e.skill == tes3.skill.heavyArmor or e.skill == tes3.skill.mediumArmor or e.skill == tes3.skill.spear then
            tes3.setGlobal("ACEndurance", tes3.getGlobal("ACEndurance") + 1)
        end

        if e.skill == tes3.skill.illusion or e.skill == tes3.skill.mercantile or e.skill == tes3.skill.speechcraft then
            tes3.setGlobal("ACPersonality", tes3.getGlobal("ACPersonality") + 1)
        end
    end

end
event.register(tes3.event.skillRaised, skillRaisedCallback)

-- ANTES DE CHAMAR tes3.event.levelUp
local function preLevelUpCallback(e)

    if config.mode == 1 then
        vanillaModePre(e)
    elseif config.mode == 2 then
        minimalModePre(e)
    elseif config.mode == 3 then
        alternativeModePre(e)
    elseif config.mode == 0 then
        print("disabled pre")
    else
        print("wrong mode value")
    end

end
event.register(tes3.event.preLevelUp, preLevelUpCallback)

local function levelUpCallback(e)

    if config.mode == 1 then
        vanillaModePost(e)
    elseif config.mode == 2 then
        minimalModePost(e)
    elseif config.mode == 3 then
        alternativeModePost(e)
    elseif config.mode == 0 then
        print("disabled Post")
    else
        print("wrong mode value")
    end

end
event.register(tes3.event.levelUp, levelUpCallback)

-- ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-- EasyMCM

local function getModeName(i)
    if i == 0 then
        return "Disabled"
    elseif i == 1 then
        return "Vanilla"
    elseif i == 2 then
        return "Minimal"
    elseif i == 3 then
        return "Alternative"
    else
        return "Wrong value: " .. i
    end
end

local function registerModConfig()

    local EasyMCM = require("easyMCM.EasyMCM")

    local template = EasyMCM.createTemplate("Attribute Carrier Mod")

    template:saveOnClose(confPath, config)

    local page = template:createSideBarPage{
        sidebarComponents = {EasyMCM.createInfo {
            text = "DO NOT CAHNGE IF LEVEL UP MENU IS OPEN!"
        }}
    }

    local category = page:createCategory("Attribute Mode")

    category:createButton({
        buttonText = "Vanilla Mode",
        description = "Change to Vanilla Mode",
        callback = function(self)
            config.mode = 1
            mwse.saveConfig(confPath, config)
        end
    })

    category:createButton({
        buttonText = "Minimal Mode",
        description = "Change to Minimal Mode",
        callback = function(self)
            config.mode = 2
            mwse.saveConfig(confPath, config)
        end
    })

    category:createButton({
        buttonText = "Alternative Mode",
        description = "Change to Alternative Mode",
        callback = function(self)
            config.mode = 3
            mwse.saveConfig(confPath, config)
        end
    })

--[[     category:createButton({
        buttonText = "Disable",
        description = "Disable",
        callback = function(self)
            config.mode = 0
            mwse.saveConfig(confPath, config)
        end
    }) ]]

    EasyMCM.register(template)
end

event.register("modConfigReady", registerModConfig)
