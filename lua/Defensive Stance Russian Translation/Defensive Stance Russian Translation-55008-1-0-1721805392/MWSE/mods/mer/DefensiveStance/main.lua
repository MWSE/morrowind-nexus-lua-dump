local configPath = "defensive_stance"

local config = mwse.loadConfig(configPath)
if (config == nil) then
	config = { 
        enabled = true,
        blockMultiplier = 2.0,
        speedMultiplier = 0.5    
    }
end 


local function hasShield()

    return tes3.getEquippedItem{
        actor = tes3.player, 
        objectType = tes3.objectType.armor,
        slot = tes3.armorSlot.shield
    }

end

local function getData()
    tes3.player.data.defensiveStance = tes3.player.data.defensiveStance or {
        active = false,
        boost = nil
    }

    return tes3.player.data.defensiveStance
end


local function calcMoveSpeed(e)
    if not config.enabled then return end 

    if e.reference == tes3.player then
        local isSneaking = e.mobile.isSneaking
        
        if isSneaking and hasShield() then
            e.speed = e.speed * config.speedMultiplier
        end
    end
end
event.register("calcMoveSpeed", calcMoveSpeed)

local function simulate(e)
    local isSneaking = tes3.mobilePlayer.isSneaking
    local data = getData()

    if isSneaking and hasShield() then
        if not data.active then
            if not config.enabled then return end 
            data.active = true

            data.boost = tes3.mobilePlayer.block.base * ( config.blockMultiplier - 1.0)
            tes3.modStatistic({
                reference = tes3.player,
                skill = tes3.skill.block,
                value = data.boost
            })
        end
    else

        if data.active then
            data.active = false

            tes3.modStatistic({
                reference = tes3.player,
                skill = tes3.skill.block,
                value = -data.boost
            })
        end
    end
end

event.register("simulate", simulate)



------------------------------------------------------------
--MCM
------------------------------------------------------------


local function registerMCM()
    local  sideBarDefault = (
        "Когда вы приседаете с экипированным щитом, ваш блок увеличивается, а скорость уменьшается. "
    )
    local function addSideBar(component)
        component.sidebar:createInfo{ text = sideBarDefault}
        
        component.sidebar:createHyperLink{
            text = "Автор: Merlord",
            exec = "start https://www.nexusmods.com/users/3040468?tab=user+files",
            postCreate = (
                function(self)
                    self.elements.outerContainer.borderAllSides = self.indent
                    self.elements.outerContainer.alignY = 1.0
                    self.elements.outerContainer.layoutHeightFraction = 1.0
                    self.elements.info.layoutOriginFractionX = 0.5
                end
            ),
        }
    end


    local template = mwse.mcm.createTemplate("Защитная стойка")
    template:saveOnClose(configPath, config)
    local page = template:createSideBarPage{}
    addSideBar(page)

    page:createOnOffButton{
        label = "Включить защитную стойку",
        variable = mwse.mcm.createTableVariable{
            id = "enabled", 
            table = config
        },
        description = "Включить этот мод."
    }

    page:createTextField{
        label = "Множитель скорости",
        description = "Определяет, насколько снижается ваша скорость, когда вы находитесь в защитной стойке. ",
        variable = mwse.mcm.createTableVariable{
            id = "speedMultiplier",
            numbersOnly = true,
            table = config
        }
    }

    page:createTextField{
        label = "Множитель защиты",
        description = "Определяет, насколько увеличивается ваша защита, когда вы находитесь в защитной стойке. ",
        variable = mwse.mcm.createTableVariable{
            id = "blockMultiplier",
            numbersOnly = true,
            table = config
        }
    }

    template:register()
end

event.register("modConfigReady", registerMCM)