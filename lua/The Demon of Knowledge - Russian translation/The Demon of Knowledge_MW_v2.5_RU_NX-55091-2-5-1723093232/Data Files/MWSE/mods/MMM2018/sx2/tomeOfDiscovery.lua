--[[
	"Touch of the Oracle" (dumb name)
	
		When equipped, reveals secrets in Apocrypha
		- Hidden paths
		- Secret messages
		- Enemy weaknesses
]]--
local debug = false
local function debugMessage(string)
	if debug then
		tes3.messageBox(string)
		print("[Demon of Knowledge: DEBUG] " .. string)
	end
end
------------------------------------------------------------------------------------------

local common = require("MMM2018.sx2.common")

local id_visionMenu = tes3ui.registerID("Hermes:visionMenu")
local id_visionMenuHeading = tes3ui.registerID("Hermes:visionMenuHeading")


local function getCreatureData()
	return mwse.loadConfig("mmm2018/sx2/creatureData")
end

local function revealSecrets()
	debugMessage("Reveal secrets!")
	for ref in tes3.getPlayerCell():iterateReferences(tes3.objectType.activator) do
		for indicator, indicatorId in pairs(common.indicatorIds) do
			if indicatorId == ref.object.id then
				debugMessage("Indicator ID : " .. indicatorId)
				if mwscript.hasItemEquipped({reference = tes3.player, item = common.itemIds.Oracle }) then
					mwscript.enable{ reference = ref }
				else
					mwscript.disable{ reference = ref }
				end
			end
		end
	end
end


local creatureVisionOn
local function checkVision()
	
	local menu
	local currentCreature
	local currentCreatureType
	local targetName
	if mwscript.hasItemEquipped({reference = tes3.player, item = common.itemIds.Oracle }) and not tes3.menuMode() then
	
		--Check target for creature Vision
		local result = tes3.rayTest{
			position = tes3.getCameraPosition(),
			direction = tes3.getCameraVector(),
		}		
		--local distanceToTarget = tes3.player.position:distance(result.intersection)
		--Looking at something different
		if result and result.reference then --and result.reference ~= lastRef then
			currentCreature = result.reference
			
			--is a creature
			if result.reference.object.objectType == tes3.objectType.creature then
				local creatures = getCreatureData().creatures
				targetName = result.reference.object.name
				
				
				for i, creature in ipairs(creatures) do
					if targetName:find(creature.prefix) then
						currentCreatureType = creature
						break
					end
				end

				if currentCreatureType then
					--ACTIVATE CREATURE VISION
					creatureVisionOn = true
				end
			else 
				creatureVisionOn = false
			end
		end		
	else 
		creatureVisionOn = false
	end
	
	menu = tes3ui.findMenu(id_visionMenu)
	if creatureVisionOn and not menu then
		menu = tes3ui.createMenu{id = id_visionMenu, fixedFrame = true}
		menu.text = "Creature Vision"
		menu.minWidth = 100
		menu.minHeight = 50
		menu.width = 600
		menu.height = 800
		menu.positionX = 200
		menu.absolutePosAlignY  = 0.05
		menu.flowDirection = "top_to_bottom"
		menu.childAlignX = 0.5	
		
		local heading = menu:createLabel{ id=id_visionMenuHeading, text = ( currentCreature.object.name )}
		heading.autoHeight = true		
		heading.autoWidth = true
		heading.color = tes3ui.getPalette("header_color")		
		
		local description = menu:createLabel{ text = currentCreatureType.description }
		description.autoHeight = true		
		description.autoWidth = true	
	end
	if menu and not creatureVisionOn then
		debugMessage("Menu = " .. ( menu and "true" or "false") .. ", vision: " .. ( creatureVisionOn and "true" or "false" ) )
		menu:destroy() 
	end
end


local function loaded()

	secretsTimer = timer.start{ type = timer.simulate, duration = 0.2, iterations = -1, callback = revealSecrets }

end
event.register("cellChanged", revealSecrets)
event.register("loaded", loaded)
event.register( "enterFrame", checkVision )



