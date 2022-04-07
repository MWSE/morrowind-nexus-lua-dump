--First, let's define some variables

local isCustomSpellmaking = false --Will be used to make sure the changes we apply do not interfer with vanilla spellmaking
local mcost = 0 --Will be used to calculate the magicka/fatigue cost of our custom created spells
local cf = mwse.loadConfig("Spammer's Spellmaker", {key = {keyCode = tes3.scanCode.b, isShiftDown = false, isAltDown = false, isControlDown = false}, maz = 4, maj = 30, mis = 50, mag = 5, fat = 3}) --This is for the MCM, the default values

--Now, the meaty part

local function keybindTest(b, e)
	return (b.keyCode == e.keyCode) and (b.isShiftDown == e.isShiftDown) and (b.isAltDown == e.isAltDown) and (b.isControlDown == e.isControlDown)
end --This part here, together with the one just below, will allow the keybinding to be refreshed midgame. Don't ask how it works, I just copied it from somewhere else. But it works.

local function keyDown(e)
    if not (keybindTest(cf.key, e)) then return end --This is for the keybinding to be shifted midgame. Works together with the function above
    if tes3ui.menuMode() then return end --To make sure the spellmaking menu does not randomely pop when you're using the console or searching something in your inventory

    local p = tes3.mobilePlayer -- I was too lazy to type tes3[...] 7 times lol

    if ((p.conjuration.type + p.mysticism.type + p.illusion.type + p.alteration.type + p.destruction.type + p.restoration.type) > (12-cf.maz)) then
        tes3.messageBox("You do not qualify for Spellmaking.") return --The filter part. This prevents the player from using the custom spellmaking if he does not meet the major/minor school requirements.
    end

    isCustomSpellmaking = true
    tes3.showSpellmakingMenu({serviceActor=p, useDialogActor=false}) --Pops the spellmaking menu
    local menu = tes3ui.findMenu("MenuSpellmaking")
	if menu then    --This part below reverts every changes we made to the spellmaking menu, to be sure that they do not interfer with the vanilla spellmaking.
		menu:register(tes3.uiEvent.destroy,
			function()
				isCustomSpellmaking = false
                local effectFilter = menu:findChild("PartScrollPane_pane")
                    for _, child in pairs(effectFilter.children) do
                    child.visible = true
                    end
			end
		)
	end
end

--The part below drains the player magicka/fatigue after he succesfully created his spell. It's the cost.
local function cost(e)
    if isCustomSpellmaking then
        local costm = e.spell.magickaCost
        tes3.modStatistic({reference=tes3.mobilePlayer, name="magicka", current=(-(cf.mag)*costm)})
        tes3.modStatistic({reference=tes3.mobilePlayer, name="fatigue", current=(-(cf.fat)*costm)})
    end
end

local function magickacost(mc)
 mcost = mc.spellPointCost
end

local function spellBlocking(eventData)
	if isCustomSpellmaking then
		local menu = tes3ui.findMenu("MenuSpellmaking")
		if menu then
            local effectFilter = menu:findChild("PartScrollPane_pane")
            -- local someElement = someMenu:findChild("IdOfTheUiElementContainingTheEffects")
                    for _, child in pairs(effectFilter.children) do
                    child.visible = false -- need to have some if logic here when you want it to be invisible
                    local magicEffect = child:getPropertyObject("MenuSpellmaking_Effect")
                        if ((tes3.mobilePlayer.conjuration.current >= cf.maj) and (magicEffect.skill == tes3.skill.conjuration) and (tes3.mobilePlayer.conjuration.type < 2)) then
                            child.visible = true
                        elseif ((tes3.mobilePlayer.conjuration.current >= cf.mis) and (magicEffect.skill == tes3.skill.conjuration) and (tes3.mobilePlayer.conjuration.type == 2)) then
                            child.visible = true
                        end
                        if ((tes3.mobilePlayer.alteration.current >= cf.maj) and (magicEffect.skill == tes3.skill.alteration) and (tes3.mobilePlayer.alteration.type < 2)) then
                            child.visible = true
                        elseif ((tes3.mobilePlayer.alteration.current >= cf.mis) and (magicEffect.skill == tes3.skill.alteration) and (tes3.mobilePlayer.alteration.type == 2)) then
                            child.visible = true
                        end
                        if ((tes3.mobilePlayer.destruction.current >= cf.maj) and (magicEffect.skill == tes3.skill.destruction) and (tes3.mobilePlayer.destruction.type < 2)) then
                            child.visible = true
                        elseif ((tes3.mobilePlayer.destruction.current >= cf.mis) and (magicEffect.skill == tes3.skill.destruction) and (tes3.mobilePlayer.destruction.type == 2)) then
                            child.visible = true
                        end
                        if ((tes3.mobilePlayer.illusion.current >= cf.maj) and (magicEffect.skill == tes3.skill.illusion) and (tes3.mobilePlayer.illusion.type < 2)) then
                            child.visible = true
                        elseif ((tes3.mobilePlayer.illusion.current >= cf.mis) and (magicEffect.skill == tes3.skill.illusion) and (tes3.mobilePlayer.illusion.type == 2)) then
                            child.visible = true
                        end
                        if ((tes3.mobilePlayer.mysticism.current >= cf.maj) and (magicEffect.skill == tes3.skill.mysticism) and (tes3.mobilePlayer.mysticism.type < 2)) then
                            child.visible = true
                        elseif ((tes3.mobilePlayer.mysticism.current >= cf.mis) and (magicEffect.skill == tes3.skill.mysticism) and (tes3.mobilePlayer.mysticism.type == 2)) then
                            child.visible = true
                        end
                        if ((tes3.mobilePlayer.restoration.current >= cf.maj) and (magicEffect.skill == tes3.skill.restoration) and (tes3.mobilePlayer.restoration.type < 2)) then
                            child.visible = true
                        elseif ((tes3.mobilePlayer.restoration.current >= cf.mis) and (magicEffect.skill == tes3.skill.restoration) and (tes3.mobilePlayer.restoration.type == 2)) then
                            child.visible = true
                        end
                    end
			local buyButton = menu:findChild("MenuSpellmaking_Buybutton")
                buyButton.width = 64
                buyButton.text = "Create"
			    buyButton:registerBefore(tes3.uiEvent.mouseClick,
				function(mouseClickEventData)
					if ((cf.mag)*mcost > (tes3.mobilePlayer.magicka.current)) then
						tes3.messageBox("You don't have enough Magicka to create this spell.")
						return false -- this will prevent the regular mouseclick event from being run
					elseif ((cf.fat)*mcost > (tes3.mobilePlayer.fatigue.current)) then
						tes3.messageBox("Creating this spell would tire you out too much.")
						return false -- this will prevent the regular mouseclick event from being run
					end
				end
			)
		end
	end
end

local function reset(e)
    local menu = tes3ui.findMenu("MenuSpellmaking")
    if menu then
        if e.mobile ~= tes3.mobilePlayer then
            isCustomSpellmaking = false
            local magprice = menu:findChild("MenuSpellmaking_PriceLabel")
            magprice.text = "Price:"
            local fatprice = menu:findChild("MenuSpellmaking_PriceValueLabel")
            fatprice.visible = true
            local effectFilter = menu:findChild("PartScrollPane_pane")
                    for _, child in pairs(effectFilter.children) do
                    child.visible = true
                    end
        else
            e.price = 0
            local magprice = menu:findChild("MenuSpellmaking_PriceLabel")
            magprice.text = string.format("Mgk: %d Ftg: %d", (cf.mag)*mcost, (cf.fat)*mcost)
            local fatprice = menu:findChild("MenuSpellmaking_PriceValueLabel")
            fatprice.visible = false
        end
    end
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate("Spammer's Spellmaker")
    template:saveOnClose("Spammer's Spellmaker", cf) template:register()
    local page = template:createSideBarPage({label="Welcome to the spellmaker's configuration menu."})
    local category1 = page:createCategory("Configure Key:")
    category1:createKeyBinder{label = "Remap Key", description = "New Spellmaking key. Can be a combination (Alt-B, Ctrl-U, Shift-X, etc).", allowCombinations = true, variable = mwse.mcm.createTableVariable{id = "key", table = cf, restartRequired = false, defaultSetting = {keyCode = tes3.scanCode.b, isShiftDown = false, isAltDown = false, isControlDown = false}}}
    local category2 = page:createCategory("Configure Magic School Level Requirements:")
    category2:createSlider{label = "Acces Requirements", description = "Permissiveness of the Spellmaking filter. If set to 0, you will be able to use the self spellmaking even if all your magical schools are miscellanious. If set to 10, you won't be able to use it at all if ALL your major skills are not magical schools. Default is 4.", min = 0, max = 10, step = 1, jump = 2, variable = mwse.mcm.createTableVariable{id = "maz", table = cf}}
    category2:createSlider{label = "Major/Minor Skills", description = "Minimum level for Major/Minor school's spells to show on the spellmaking window. Default is 30.", min = 0, max = 100, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "maj", table = cf}}
    category2:createSlider{label = "Miscellanious Skills", description = "Minimum level for Miscellanious school's spells to show on the spellmaking window. Default is 50.", min = 0, max = 100, step = 1, jump = 10, variable = mwse.mcm.createTableVariable{id = "mis", table = cf}}
    page:createCategory("Configure Magicka and Fatigue Cost Multipliers:")
    page:createSlider{label = "Magicka Cost Multiplier", description = "The multiplier used to calculate the magicka cost of the spellmaking. Default is 5.", min = 0, max = 10, step = 1, jump = 1, variable = mwse.mcm.createTableVariable{id = "mag", table = cf}}
    page:createSlider{label = "Fatigue Cost Multiplier", description = "The multiplier used to calculate the fatigue cost of the spellmaking. Default is 3.", min = 0, max = 10, step = 1, jump = 1, variable = mwse.mcm.createTableVariable{id = "fat", table = cf}}
end

event.register("modConfigReady", registerModConfig)

local function initialized()
    event.register(tes3.event.uiActivated, spellBlocking, {filter="MenuSpellmaking"})
    event.register(tes3.event.spellCreated, cost)
    event.register(tes3.event.calcSpellmakingPrice, reset)
    event.register(tes3.event.calcSpellmakingSpellPointCost, magickacost)
    event.register(tes3.event.keyDown, keyDown)
    print("Spammer's SpellMaking : Initialized!")
end

event.register("initialized", initialized)