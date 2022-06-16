local common = require("securityExpertise.common")
--local LnTDLockData = include("AdituV.DetectTrap.LockData")

local config
local GUI_ID = {}


common.loadTranslation()

event.register("modConfigReady", function()
    require("securityExpertise.mcm")
	config  = require("securityExpertise.config")
end)


local function registerGUI()
	GUI_ID.parent = tes3ui.registerID("SE_Tooltip_Parent")
    GUI_ID[1] = tes3ui.registerID("SE_Tooltip_Effect1")
    GUI_ID[2] = tes3ui.registerID("SE_Tooltip_Effect2")
    GUI_ID[3] = tes3ui.registerID("SE_Tooltip_Effect3")
    GUI_ID[4] = tes3ui.registerID("SE_Tooltip_Effect4")
end

local function showTooltip(source)
	local tooltip = tes3ui.createTooltipMenu()
	tooltip.minWidth = 50
	tooltip.maxWidth = 1920
	tooltip.autoHeight = true
	tooltip.autoWidth = true
	local name = tooltip:createLabel{text=source.name}
	name.color = tes3ui.getPalette("header_color")
	tooltip.flowDirection = "top_to_bottom"
	local effects = source.effects or source.enchantment.effects
	for i, effect in ipairs(effects) do
		local magicEffect = tes3.getMagicEffect(effect.id)
		if not magicEffect then 
			break 
		end
		local block = tooltip:createBlock{id=GUI_ID[i]}
		block.autoHeight = true
		block.autoWidth = true
		block.flowDirection = "left_to_right"
		
		local image = block:createImage{path=("icons\\" .. magicEffect.icon)}
		image.wrapText = false
		image.borderLeft = 4
		local text = common.getEffectText(effect)
		local label = block:createLabel{text=text}
		label.wrapText = false
		label.borderLeft = 4
		
	end
	tooltip:updateLayout()
end

local function createTrapMenu(reference)
	local menu = tes3ui.createMenu{id = tes3ui.registerID("MenuCreateTrap"), fixedFrame = true}
	menu.width = 380
	menu.height = 560
	menu.minWidth = 380
	menu.minHeight = 560
	menu.positionX = menu.width / -2
	menu.positionY = menu.height / 2
	local prompt = menu:createLabel{id = tes3ui.registerID("MenuCreateTrap_prompt"),  text = common.dictionary.trap}
	prompt.borderAllSides = 2
	prompt.borderBottom = 4
	local scrollpane = menu:createVerticalScrollPane{id = tes3ui.registerID("MenuCreateTrap_scrollpane")}
	scrollpane.borderAllSides = 6
	for _, stack in pairs(tes3.player.object.inventory) do
		if stack.object.objectType == tes3.objectType.alchemy or ( stack.object.objectType == tes3.objectType.book and stack.object.enchantment and stack.object.enchantment.effects ) then
			local block = scrollpane:createBlock{id = tes3ui.registerID("PartHelpMenu_brick")}
			block.autoWidth = true
			block.autoHeight = true
			local image = block:createImage{id = tes3ui.registerID("MenuCreateTrap_icon_brick"), path = "icons\\" ..stack.object.icon}
			image.borderAllSides = 8
			local label = block:createLabel{id = tes3ui.registerID("MenuCreateTrap_item_brick"),  text = stack.object.name}
			label.borderAllSides = 14
			block.consumeMouseEvents = true
			block:register("help", function()
				showTooltip(stack.object)
			end)
			block:register("mouseClick", function() 
				menu:destroy()
				tes3ui.leaveMenuMode(tes3ui.registerID("MenuCreateTrap"))
				tes3.setTrap{reference=reference, spell=common.getTrapFromSource(stack.object)}
				tes3.removeItem{reference=tes3.player, item=stack.object, count=1}
				tes3.messageBox(common.dictionary.trapSet)
				tes3.playSound{sound="Disarm Trap"}
				tes3.mobilePlayer:exerciseSkill(tes3.skill.security, 3)
			end)
		end
	end
	local lowerBlock = menu:createBlock()
	lowerBlock.autoWidth = true
	lowerBlock.autoHeight = true
	local cancelButton = lowerBlock:createButton {id = tes3ui.registerID("MenuCreateTrap_cancel_button"), text = common.dictionary.cancel}
	cancelButton.borderLeft = 290
	cancelButton:register("mouseClick", function() 
		menu:destroy()
		tes3ui.leaveMenuMode(tes3ui.registerID("MenuCreateTrap"))
	end)
	tes3ui.enterMenuMode(tes3ui.registerID("MenuCreateTrap"))
end

local function onDoorSpell(e)
	--if not e.target.lockNode then return end
	tes3.setTrap{reference=e.target, spell=common.getTrapFromSource(e.source)}
	e.target:updateSceneGraph()
	--[[timer.delayOneFrame(function()
		if LnTDLockData then
			local ld = LnTDLockData.getForReference(e.target)
			ld:attemptDetectTrap()
		end
	end]]
end

local function getSecuritySuccess(mobile, quality)
	local rand = math.random(1, 100)
	local x = (mobile.security.current + 0.2*mobile.intelligence.current + 0.1*mobile.luck.current)*quality*mobile:getFatigueTerm()
	return x - rand
end

local function onTrapArm(e)
	if e.trapPresent then
		return 
	end
	if tes3.worldController.inputController:isKeyDown(tes3.scanCode.lAlt) then
		if getSecuritySuccess(e.disarmer, e.tool.quality) > 0 then
			timer.start{
				duration = 0.3	,
				callback = function()
					createTrapMenu(e.reference)
				end
			}
		else
			tes3.messageBox(common.dictionary.trapSetFailed)
			tes3.playSound{sound="Disarm Trap Fail"}
		end
	end
end

-- local function onAIActivate(e)
-- 	if e.activator == tes3.player then return end
-- 	if not e.target.lockNode then return end
-- 	if e.target.lockNode.trap then
-- 		event.trigger("trapDisarm", {disarmer=e.activator.mobile, trapPresent=true, lockData = e.target.attachments.lock, reference=e.target, tool=tes3.getObject("probe_master_01"), chance=100, toolItemData={charge = 0, conditiuon = 25, data = {}}})
-- 		e.target.lockNode.trap = nil
-- 		return false
-- 	end
--[[	if e.target.lockNode.locked then
		event.trigger("lockPick", {picker=e.activator.mobile, lockPresent=true, lockData = e.target.attachments.lock, reference=e.target, tool=tes3.getObject("pick_master_01"), chance=100, toolItemData={charge = 0, conditiuon = 25, data = {}}})
		mwse.log("Lock Pick is triggered")
		return false
	end]]
-- end

local function miscToCont(reference)
	if reference.id == "se_trap_panel_misc" then
		return "se_trap_panel_cont"
	end
end

local function contToMisc(reference)
	if reference.id == "se_trap_panel_cont" then
		return "se_trap_panel_misc"
	end
end

local function onActivate(e)
	if e.activator ~= tes3.player then
		return
	end
	
	local activationRef = e.target
	
	if not activationRef then 
		return 
	end
	
	if activationRef.lockNode and activationRef.lockNode.trap then
		return
	end
	
	local misc = contToMisc(activationRef)
	
	if not misc then 
		return
	end
	
	common.safeDelete(activationRef)
	tes3.addItem{reference=tes3.player, item=misc, count=1, playSound=true}
	return false
end

local function onItemDropped(e)
	local cont = miscToCont(e.reference)
	if cont then
		for _ = 1, e.reference.stackSize do
			local new = tes3.createReference{object = cont, position = {e.reference.position.x, e.reference.position.y, e.reference.position.z-5}, orientation = e.reference.orientation, cell=tes3.getPlayerCell()}
		end
		common.safeDelete(e.reference)
	end
end

local function onTrapStep(e)
	
	if not e.target then 
		return 
	end
	
	if config.stepTraps[e.target.id] then
		local spell = tes3.getTrap{reference=e.target}
		if spell then
			tes3.cast{reference=e.target, target=e.mobile, spell=spell, instant=true, alwaysSucceeds=true}
			tes3.setTrap{reference=e.target, spell=nil}
		end
	end
end

local locking = false

local function onLockPick(e)
	if locking then
		locking = false
		return false
	end
	-- if e.reference.lockNode.trap then
	-- 	if e.chance < 50 then
	-- 		local spell = tes3.getTrap{reference=e.reference}
	-- 		tes3.cast{reference=e.reference, target=e.picker, spell=spell, instant=true, alwaysSucceeds=true}
	-- 		tes3.setTrap{reference=e.reference, spell=nil}
	-- 	end
	-- end
end


local function rayLock()
	local eyePos = tes3.getPlayerEyePosition()
    local eyeVec = tes3.getPlayerEyeVector()

    if not (eyePos or eyeVec) then
        return
    end

    local activationDistance = tes3.getPlayerActivationDistance()

    local result = tes3.rayTest{
        position = eyePos,
        direction = eyeVec,
        ignore = { tes3.player },
        maxDistance = activationDistance,
    }

    if result and result.reference and result.reference.baseObject then
        if result.reference.baseObject.objectType == tes3.objectType.container or result.reference.baseObject.objectType == tes3.objectType.door then
			if not tes3.getLocked{reference=result.reference} and not config.stepTraps[result.reference.id] then
				local lockpick = tes3.mobilePlayer.readiedWeapon
				local lockLevel = getSecuritySuccess(tes3.mobilePlayer, lockpick.object.quality)
				if lockLevel > 0 then
					tes3.lock{reference=result.reference, level=lockLevel}
					tes3ui.refreshTooltip()
					locking = true
					tes3.messageBox(common.dictionary.lockSuccess)
					tes3.playSound{sound="Open Lock"}
					tes3.mobilePlayer:exerciseSkill(tes3.skill.security, 2)
				else
					lockpick.itemData.condition = lockpick.itemData.condition - 1
					if lockpick.itemData.condition == 0 then
						timer.start{
							duration = 0.1,
							callback = function()
								tes3.removeItem{reference=tes3.player, item = lockpick.object, itemData = lockpick.itemData}
							end
						}
					end
					tes3.messageBox(common.dictionary.lockFailed)
					tes3.playSound{sound="Open Lock Fail"}
				end
			end
        end
    end
end


local function onUseKey(e)

    -- if tes3.mobilePlayer.speechcraft.current < config.combatTalk then
    --     return
    -- end

    if tes3ui.menuMode() then
        return
    end

	if not tes3.worldController.inputController:isKeyDown(tes3.scanCode.lAlt) then
		return
	end

	if not tes3.mobilePlayer.readiedWeapon or tes3.mobilePlayer.readiedWeapon.object.objectType ~= tes3.objectType.lockpick then
		return
	end

    if (e.keyCode == tes3.getInputBinding(tes3.keybind.use).code) and (tes3.getInputBinding(tes3.keybind.use).device == 0) then
		rayLock()
    end
end

local function onUseButton(e)

    if tes3ui.menuMode() then
        return
    end

	if not tes3.worldController.inputController:isKeyDown(tes3.scanCode.lAlt) then
		return
	end

	if not tes3.mobilePlayer.readiedWeapon or tes3.mobilePlayer.readiedWeapon.object.objectType ~= tes3.objectType.lockpick then
		return
	end

	-- if tes3.mobilePlayer.speechcraft.current < config.combatTalk then
    --     return
    -- end

    if (e.button == tes3.getInputBinding(tes3.keybind.use).code) and (tes3.getInputBinding(tes3.keybind.use).device == 1) then
		rayLock()
    end
end

local function onMobileActivated(e)
	if not config.sellTrapPanels then return end
	if not config.trapMerchant[e.reference.baseObject.id:lower()] then return end
	if e.reference.data.trapsStockAdded then return end
	common.addTrapsStock(e.reference)
end

local function onInitialized(e)
	if config.modEnabled then
		mwse.log("[Security Expertise]: enabled")
		--event.register("activate", onAIActivate)
		--event.register("uiObjectTooltip", onTooltipDrawn)
		event.register("activate", onActivate)
		event.register("itemDropped", onItemDropped)
		--event.register("spellResist", onDoorSpell)
		event.register("trapDisarm", onTrapArm, {priority=200})
		event.register("lockPick", onLockPick)
		event.register("collision", onTrapStep)
		event.register("mouseButtonDown", onUseButton)
		event.register("keyDown", onUseKey)
		event.register("mobileActivated", onMobileActivated)
		common.createObjects()
	else
		mwse.log("[Security Expertise]: disabled")
	end
end

event.register("initialized", onInitialized)