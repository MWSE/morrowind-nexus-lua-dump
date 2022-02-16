local common = require("York.Extradimensional Pockets.common")
local config = require("York.Extradimensional Pockets.mcm")
local messageBox = require("York.Extradimensional Pockets.MessageBox")

--Effect Id Claiming
tes3.claimSpellEffectId("pocket", 701)

-- Including the magicka expanded framework
local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
if (framework == nil) then
    local function warning()
        tes3.messageBox(
            "[POCKET: ERROR] Magicka Expanded framework is not installed!"
            .. " You will need to install it to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end

local containers = {}

local spellIds = {
	extradimensionalPockets = "ExtradimensionalPockets"
}
local distributions = {
	["Malven Romori"] = {
        spellIds.extradimensionalPockets
    },
	["Minnibi Selkin-Adda"] = {
        spellIds.extradimensionalPockets
    },
	["Salver Lleran"] = {
        spellIds.extradimensionalPockets
    },
	["Lalatia Varian"] = {
        spellIds.extradimensionalPockets
    },
	["Ervona Barys"] = {
        spellIds.extradimensionalPockets
    },
	["Felen Maryon"] = {
        spellIds.extradimensionalPockets
    },
	["Uvele Berendas"] = {
        spellIds.extradimensionalPockets
    }
}
--[[
	["Name Here"] = {
        spellIds.extradimensionalPockets
    },
	
]]



local function onLoad(e)
	if not tes3.player.data.pocket then
		tes3.player.data.pocket = {}
	end
	if(e.newGame)then
		tes3.player.data.pocket.containers = {}
	else
		--old json file loading for back compatability with old versions of mod.
		backJson = json.loadfile("Pockets"..e.filename)
		if (backJson and not tes3.player.data.pocket.containers) then
			tes3.player.data.pocket.containers = backJson
		end
	end
	if (not tes3.player.data.pocket.containers) then
		tes3.player.data.pocket.containers = {}
	end
	containers = tes3.player.data.pocket.containers
end


event.register("loaded", onLoad)


local function onPocketTick(e)
	if (not e:trigger()) then
		return
	end
	
	--using e.sourceInstance.source gets the spell that was cast
	containerRef = tes3.getReference(containers[e.sourceInstance.source.id])
	if(not containerRef) then
		pocketsSize = table.size(containers)
		local tempName
		if e.sourceInstance.sourceType == tes3.magicSourceType.spell then
			tempName = e.sourceInstance.source.name
		elseif e.sourceInstance.sourceType == tes3.magicSourceType.enchantment then
			tempName = e.sourceInstance.item.name
		else
			tempName = e.sourceInstance.source.id
		end
		
		tes3.createObject({
			objectType = tes3.objectType.container,
			id = "YK_PT_Pocket" .. tostring(pocketsSize),
			name = tempName,
			e.sourceInstance.source.name,
			mesh = "ME\\RES\\merchantCrate.nif",
			capacity = e.effectInstance.magnitude
		})
		containers[e.sourceInstance.source.id] = "YK_PT_Pocket" .. tostring(pocketsSize)
		
		containerID = containers[e.sourceInstance.source.id]
		containerRef = tes3.createReference({
		object = tes3.getObject(containerID),
		position = tes3.player.position:copy(),
		orientation = tes3.player.orientation:copy(),
		cell = tes3.getPlayerCell()
		})
	end
    timer.delayOneFrame(
        function() 
			tes3.player:activate(containerRef)
        end,
        timer.real
    )
	e.effectInstance.state = tes3.spellState.retired
end

local function addPocketEffects()
	framework.effects.conjuration.createBasicEffect({
  -- Base information.
  id = tes3.effect.pocket,
  name = "Pocket",
  description = "Opens a pocket in the plane of Oblivion allowing you to store items in the void. Duration determines the size of the pocket.",
  -- Basic dials.
  baseCost = 5.0,
  -- Various flags.
  allowEnchanting = true,
  allowSpellmaking = true,
  canCastTarget = false,
  canCastTouch = false,
  canCastSelf = true,
  hasNoMagnitude = false,
  hasNoDuration = true,
  nonRecastable = false,
  -- Graphics/sounds. left as defaults
  -- Required callbacks.
  onTick = onPocketTick,
 })
end

event.register("magicEffectsResolved", addPocketEffects)

local function registerSpells()
	framework.spells.createBasicSpell({
		id = spellIds.extradimensionalPockets,
		name = "Extradimensional Pockets",
		effect = tes3.effect.pocket,
		range = tes3.effectRange.self,
		min = 50,
		max = 50
	})
	for npcId, distributionSpellIds in pairs(distributions) do
        local npc = tes3.getObject(npcId)
        if (npc) then
            if (type(distributionSpellIds) ~= "table") then
                local spell = tes3.getObject(distributionSpellIds)
                if (spell) then
                    npc.spells:add(spell)
                end
            else
                for _, spellId in pairs(distributionSpellIds) do
                    local spell = tes3.getObject(spellId)
                    if (spell) then
                        npc.spells:add(spell)
                    end
                end
            end
        end
    end
end

event.register("MagickaExpanded:Register", registerSpells)


local function onInit()
	print("[POCKET: INFO] Initialized Pocket")
end
--[[
tree of menuset values


MenuSetValues
-focusable
-PartNonDragMenu_main
--MenuSetValues_NameLayout
---null
---null
--MenuSetValues_RangeLayout
---null
--MenuSetValues_MagnitudeLayout
---null
---null
---null
---null
--MenuSetValues_DurationLayout
---null
---null
--MenuSetValues_AreaLayout
---null
---null
--null "buttons"
---MenuSetValues_OkButton
---MenuSetValues_Deletebutton
---MenuSetValues_Cancelbutton
]]
local function limitSpellmaking(e)
	--common.info("first children")
	--childs = common.findAllChildren(e.element)
	--common.info("second children")
	--child2 = common.findAllChildrenTab(childs)
	--common.info("thrid children")
	--child3 = common.findAllChildrenTab(child2)
	--common.info("fourth children")
	--child4 = common.findAllChildrenTab(child3)
	--common.info("fifth children")
	--child5 = common.findAllChildrenTab(child4)
	local NameLayout = e.element:findChild(tes3ui.registerID("MenuSetValues_NameLayout"))
	local isPocket = false
	for i,j in pairs(NameLayout.children) do
		if j.text == "Pocket" then
			isPocket = true
		end
	end
	
	if isPocket then
		local magLowSlider = e.element:findChild(tes3ui.registerID("MenuSetValues_MagLowSlider"))
		local magHigh = e.element:findChild(tes3ui.registerID("MenuSetValues_MagHigh"))
		local magHighSlider = e.element:findChild(tes3ui.registerID("MenuSetValues_MagHighSlider"))
		magHigh.visible = false
		magHighSlider.visible = false
		magLowSlider:registerBefore("PartScrollBar_changed", function(e) 
			magHighSlider.widget.current = magLowSlider.widget.current
			magHighSlider:triggerEvent("PartScrollBar_changed")
		end)
	end
end

local function panicButtonPushed(e)
	common.info("Panic Button Pushed")
	local tempButtons = {}
	local tempAll = {}
	for _,inventory in pairs(containers) do
		local ref = tes3.getReference(inventory)
		table.insert(tempAll,ref)
	end
	table.insert(tempButtons,{
		text = "all inventories",
		callback = function() 
			for _,ref in pairs(tempAll) do 
				for i, stack in pairs(ref.object.inventory) do
					tes3.transferItem{from=ref, to=tes3.player, item=stack.object, count=stack.count, playSound=true}
				end
			end 
		end
	})
	for _,ref in pairs(tempAll) do 
		table.insert(tempButtons, {
			text = ref.object.name,
			callback = function() 
				for i,stack in pairs(ref.object.inventory) do
					tes3.transferItem{from=ref, to=tes3.player, item=stack.object, count=stack.count, playSound=true}
				end
			end
		})
	end
	table.insert(tempButtons,{text = "Cancel",callback = function() return end})
	
	messageBox{
		message = "Which inventory would you like to remove all items from?",
		buttons = tempButtons
	}
	common.info("After button successfully")
end

event.register("York:PocketPanic", panicButtonPushed)
event.register("uiActivated", limitSpellmaking, {filter = "MenuSetValues"})
event.register("initialized", onInit)