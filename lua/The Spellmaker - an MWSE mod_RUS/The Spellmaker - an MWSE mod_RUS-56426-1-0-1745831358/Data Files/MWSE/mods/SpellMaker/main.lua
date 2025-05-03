local isCustomSpellmaking = false
local mcost = 0
local cf = mwse.loadConfig("Spammer's Spellmaker", {key = {keyCode = tes3.scanCode.b, isShiftDown = false, isAltDown = false, isControlDown = false}})

local function keyupd()
    local keyupdate = cf.key.keyCode
end
local function keyDown()
    if tes3ui.menuMode() then return end

    local p = tes3.mobilePlayer
    if (p.conjuration.type~=0 and p.mysticism.type~=0 and p.illusion.type~=0 and p.alteration.type~=0 and p.destruction.type~=0 and p.restoration.type~=0) then
        tes3.messageBox("Ваших знаний в области магии недостаточно для создания заклинаний.")
        return
    end

    if ((p.conjuration.type + p.mysticism.type + p.illusion.type + p.alteration.type + p.destruction.type + p.restoration.type) > 8) then
        tes3.messageBox("Ваших знаний в области магии недостаточно для создания заклинаний.")
        return
    end

    isCustomSpellmaking = true
    tes3.findGMST("fSpellMakingValueMult").value = 0
    tes3.showSpellmakingMenu({serviceActor=p, useDialogActor=false})
    local menu = tes3ui.findMenu("MenuSpellmaking")
	if menu then
		menu:register(tes3.uiEvent.destroy,
			function()
				isCustomSpellmaking = false
				tes3.findGMST("fSpellMakingValueMult").value = fSpellMakingValueMult
                local effectFilter = menu:findChild("PartScrollPane_pane")
                    for _, child in pairs(effectFilter.children) do
                    child.visible = true
                    end
			end
		)
	end
end



local function cost(e)
    if isCustomSpellmaking then
        local costm = e.spell.magickaCost
        tes3.modStatistic({reference=tes3.mobilePlayer, name="magicka", current=(-5*costm)})
        tes3.modStatistic({reference=tes3.mobilePlayer, name="fatigue", current=(-3*costm)})
    end
end

local function magickacost(mc)
 mcost = mc.spellPointCost
end

local function spellBlocking(eventData)
	if isCustomSpellmaking then
		local menu = tes3ui.findMenu("MenuSpellmaking")
		if menu then
            -- All this below is new.
            local effectFilter = menu:findChild("PartScrollPane_pane")
            -- local someElement = someMenu:findChild("IdOfTheUiElementContainingTheEffects")
                    for _, child in pairs(effectFilter.children) do
                    child.visible = false -- need to have some if logic here when you want it to be invisible
                    local magicEffect = child:getPropertyObject("MenuSpellmaking_Effect")
                        if ((tes3.mobilePlayer.conjuration.current >= 30) and (magicEffect.skill == tes3.skill.conjuration) and (tes3.mobilePlayer.conjuration.type < 2)) then
                            child.visible = true
                        elseif ((tes3.mobilePlayer.conjuration.current >= 50) and (magicEffect.skill == tes3.skill.conjuration) and (tes3.mobilePlayer.conjuration.type == 2)) then
                            child.visible = true
                        end
                        if ((tes3.mobilePlayer.alteration.current >= 30) and (magicEffect.skill == tes3.skill.alteration) and (tes3.mobilePlayer.alteration.type < 2)) then
                            child.visible = true
                        elseif ((tes3.mobilePlayer.alteration.current >= 50) and (magicEffect.skill == tes3.skill.alteration) and (tes3.mobilePlayer.alteration.type == 2)) then
                            child.visible = true
                        end
                        if ((tes3.mobilePlayer.destruction.current >= 30) and (magicEffect.skill == tes3.skill.destruction) and (tes3.mobilePlayer.destruction.type < 2)) then
                            child.visible = true
                        elseif ((tes3.mobilePlayer.destruction.current >= 50) and (magicEffect.skill == tes3.skill.destruction) and (tes3.mobilePlayer.destruction.type == 2)) then
                            child.visible = true
                        end
                        if ((tes3.mobilePlayer.illusion.current >= 30) and (magicEffect.skill == tes3.skill.illusion) and (tes3.mobilePlayer.illusion.type < 2)) then
                            child.visible = true
                        elseif ((tes3.mobilePlayer.illusion.current >= 50) and (magicEffect.skill == tes3.skill.illusion) and (tes3.mobilePlayer.illusion.type == 2)) then
                            child.visible = true
                        end
                        if ((tes3.mobilePlayer.mysticism.current >= 30) and (magicEffect.skill == tes3.skill.mysticism) and (tes3.mobilePlayer.mysticism.type < 2)) then
                            child.visible = true
                        elseif ((tes3.mobilePlayer.mysticism.current >= 50) and (magicEffect.skill == tes3.skill.mysticism) and (tes3.mobilePlayer.mysticism.type == 2)) then
                            child.visible = true
                        end
                        if ((tes3.mobilePlayer.restoration.current >= 30) and (magicEffect.skill == tes3.skill.restoration) and (tes3.mobilePlayer.restoration.type < 2)) then
                            child.visible = true
                        elseif ((tes3.mobilePlayer.restoration.current >= 50) and (magicEffect.skill == tes3.skill.restoration) and (tes3.mobilePlayer.restoration.type == 2)) then
                            child.visible = true
                        end
                    end
         --       effectFilter.visible = false
           -- local result = tes3uiElement:createVerticalScrollPane
             --   result.positionX = 0
               -- result.positionY = 0
                --result.scrollbarVisible = true
       --         result.borderAllSides = 0
         --       result.width = 178
           --     result.height = 179
             --   for _, spell in pairs(tes3.player.object.spell.iterator) do
             --   local Eff, Effsc = spell.effects, spell.effects.skill
              --  end
            --I stopped here. Going to sleep now.
			local buyButton = menu:findChild("MenuSpellmaking_Buybutton")
                buyButton.width = 64
                buyButton.text = "Создать"
			    buyButton:registerBefore(tes3.uiEvent.mouseClick,
				function(mouseClickEventData)
					if (5*mcost > (tes3.mobilePlayer.magicka.current)) then
						tes3.messageBox("У вас недостаточно магической энергии для создания заклинания.")
						return false -- this will prevent the regular mouseclick event from being run
					elseif (3*mcost > (tes3.mobilePlayer.fatigue.current)) then
						tes3.messageBox("Создание заклинания для вас слишком утомительно.")
						return false -- this will prevent the regular mouseclick event from being run
					end
				end
			)
		end
	end
end

local function reset(e)
    local menu = tes3ui.findMenu("MenuSpellmaking")
    if e.mobile ~= tes3.mobilePlayer then
        isCustomSpellmaking = false
        tes3.findGMST("fSpellMakingValueMult").value = 20
        local magprice = menu:findChild("MenuSpellmaking_PriceLabel")
        magprice.text = "Цена:"
        local fatprice = menu:findChild("MenuSpellmaking_PriceValueLabel")
        fatprice.visible = true
        local menu = tes3ui.findMenu("MenuSpellmaking")
		if menu then
            local effectFilter = menu:findChild("PartScrollPane_pane")
                    for _, child in pairs(effectFilter.children) do
                    child.visible = true
                    end
        end
    else
        local magprice = menu:findChild("MenuSpellmaking_PriceLabel")
        magprice.text = string.format("Маг: %d Уст: %d", 5*mcost, 3*mcost)
        local fatprice = menu:findChild("MenuSpellmaking_PriceValueLabel")
        fatprice.visible = false
    end
end

local function registerModConfig()	
    local template = mwse.mcm.createTemplate("Создание заклинаний")		
    template:saveOnClose("Spammer's Spellmaker", cf) template:register()		
    local page = template:createPage({label="Добро пожаловать в меню настроек мода 'Создание заклинаний'"})
    page:createKeyBinder{label = "Новая кнопка для создания заклинаний. Вам необходимо перезагрузить игру для вступления изменений в силу.",
    allowCombinations = false, variable = mwse.mcm.createTableVariable{id = "key", table = cf, defaultSetting = {keyCode = tes3.scanCode.b, isShiftDown = false, isAltDown = false, isControlDown = false}}}
end

event.register("modConfigReady", registerModConfig)

local function initialized()
    event.register(tes3.event.uiActivated, spellBlocking, {filter="MenuSpellmaking"})
    event.register(tes3.event.spellCreated, cost)
    event.register(tes3.event.calcSpellmakingPrice, reset)
    event.register(tes3.event.calcSpellmakingSpellPointCost, magickacost)
    event.register(tes3.event.keyDown, keyDown, { filter = cf.key.keyCode })
    event.register(tes3.event.simulate, keyupd)
    print("Spammer's SpellMaking : Initialized!")
end

event.register("initialized", initialized)