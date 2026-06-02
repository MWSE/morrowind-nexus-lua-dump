--1.3

local nearby = require('openmw.nearby')
local types = require('openmw.types')
local self = require('openmw.self')
local ui = require('openmw.ui')
local util = require('openmw.util')
local camera = require('openmw.camera')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local async = require("openmw.async")


local MOD_NAME = "NearbyDoors"
local playerSettings = storage.playerSection("SettingsPlayer" .. MOD_NAME)
local maxDoors = 3
local pixelFromRight  = 80
local pixelFromBottom = 35
local uiScale = 1.0
local corner = "BottomRight"

local displayedDoors = {}          -- Currently displayed doors (keeps track of which doors occupy which UI slot)
local doorUIElements = {}          -- Table of door text + arrow UI objects for each slot 
local parentUI = nil               -- The parent UI container holding all door UI elements

local screenSize = ui.screenSize()

local UPDATE_INTERVAL_DOOR_CHECK = 1       -- Seconds between updates
local timeSinceLastUpdateDoorCheck = 0      -- Accumulated time since last update

local UPDATE_INTERVAL_UI = 0.1       -- Seconds between updates
local timeSinceLastUpdateUI = 0      -- Accumulated time since last update

local arrowTextures = {}		   -- Preloaded textures for directional arrows (8 directions)
for i = 0, 7 do
    arrowTextures[i] = ui.texture { path = "textures/DenyingProduct/doorArrow/arrow-"..i..".dds" }
end

local shopColor   = util.color.rgb(1, 0.824, 0.294) -- Yellowish (shops/outfitter)
local magicColor  = util.color.rgb(0.294, 0.725, 1) -- Blue (mages, alchemy)
local fightColor  = util.color.rgb(1, 0.675, 0.294) -- Orange (fighters, weapons)
local templeColor = util.color.rgb(0.294, 1, 0.584) -- Green (temples, chapels)
local redColor    = util.color.rgb(1, 0.294, 0.294) -- Red
local innColor    = util.color.rgb(0.561, 0.294, 1) -- Purple (inns, taverns)
local doorPatterns = { -- color to use if a door contains the keyword
    {keyword = "mage", 						color = magicColor},
    {keyword = "alchemist", 				color = magicColor},
    {keyword = "apothecary", 				color = magicColor},
    {keyword = "healer", 					color = magicColor},
    {keyword = "sorcerer", 					color = magicColor},
    {keyword = "enchanter", 				color = magicColor},
    {keyword = "herbalist", 				color = magicColor},
    {keyword = "elixirs", 					color = magicColor},
    {keyword = "fighter", 					color = fightColor},
    {keyword = "smith", 					color = fightColor},
    {keyword = "armor", 					color = fightColor},
    {keyword = "weapon", 					color = fightColor},
    {keyword = "the razor hole", 			color = fightColor},
    {keyword = "tong", 						color = redColor},
    {keyword = "dres", 						color = redColor},
    {keyword = "hlaalu", 					color = shopColor},
    {keyword = "redoran", 					color = fightColor},
    {keyword = "telvanni", 					color = magicColor},
    {keyword = "indoril", 					color = templeColor},
    {keyword = "temple", 					color = templeColor},
    {keyword = "chapel", 					color = templeColor},
    {keyword = "shrine", 					color = templeColor},
    {keyword = "wise woman", 				color = templeColor},
    {keyword = "outfitter", 				color = shopColor},
    {keyword = "pawn", 						color = shopColor},
    {keyword = "trade", 					color = shopColor},
    {keyword = "clothier", 					color = shopColor},
    {keyword = "weaver", 					color = shopColor},
    {keyword = "tailor", 					color = shopColor},
    {keyword = "book", 						color = shopColor},
    {keyword = "merchandise", 				color = shopColor},
    {keyword = "goods", 					color = shopColor},
    {keyword = "wares", 					color = shopColor},
    {keyword = "pantry", 					color = shopColor},
    {keyword = "fort", 						color = fightColor},
    {keyword = "tradehouse", 				color = innColor},
    {keyword = "inn", 						color = innColor},
    {keyword = "club", 						color = innColor},
    {keyword = "cornerclub", 				color = innColor},
    {keyword = "tavern", 					color = innColor},
    {keyword = "hostel", 					color = innColor},
    {keyword = "alehouse", 					color = innColor},
    {keyword = "bar", 						color = innColor},
    {keyword = "pub", 						color = innColor},
    {keyword = "eight plates", 				color = innColor},
    {keyword = "lucky lockup", 				color = innColor},
    {keyword = "shenk's shovel", 			color = innColor},
    {keyword = "the end of the world", 		color = innColor},
    {keyword = "six fishes", 				color = innColor},
    {keyword = "tower of dusk", 			color = innColor},
    {keyword = "the pilgrim's rest", 		color = innColor},
    {keyword = "fara's hole in the wall",	color = innColor},
    {keyword = "earthly delights", 			color = innColor},
    {keyword = "plot and plaster", 			color = innColor},
    {keyword = "the covenant", 				color = innColor},
    {keyword = "the flowers of gold", 		color = innColor},
    {keyword = "the lizard's head", 		color = innColor},
    {keyword = "lokken main hall", 			color = innColor},
    {keyword = "rat in the pot", 			color = innColor},
    {keyword = "the grey lodge", 			color = innColor},
    {keyword = "the laughing goblin", 		color = innColor},
    {keyword = "underground bazaar", 		color = innColor},
    {keyword = "hostel of the crossing", 	color = innColor},
    {keyword = "limping scrib", 			color = innColor},
    {keyword = "the pious pirate", 			color = innColor},
    {keyword = "the dancing cup", 			color = innColor},
    {keyword = "the guar with no name", 	color = innColor},
    {keyword = "shalaasa's caravanserai",	color = innColor},
    {keyword = "the nest", 					color = innColor},
    {keyword = "the gentle velk", 			color = innColor},
    {keyword = "the howling noose", 		color = innColor},
    {keyword = "the queen's cutlass", 		color = innColor},
    {keyword = "silver serpent", 			color = innColor},
    {keyword = "unnamed legion bar", 		color = innColor},
    {keyword = "mjornir's meadhouse", 		color = innColor},
    {keyword = "the red drake", 			color = innColor},
    {keyword = "the leaking spore", 		color = innColor},
    {keyword = "the swallow's nest", 		color = innColor},
    {keyword = "the golden glade", 			color = innColor},
    {keyword = "pilgrim's respite", 		color = innColor},
    {keyword = "the empress katariah", 		color = innColor},
    {keyword = "legion boarding house", 	color = innColor},
    {keyword = "the moth and tiger", 		color = innColor},
    {keyword = "the salty futtocks", 		color = innColor},
    {keyword = "the avenue", 				color = innColor},
    {keyword = "the dancing jug", 			color = innColor},
    {keyword = "the strider's wake", 		color = innColor},
    {keyword = "the toiling guar", 			color = innColor},
    {keyword = "the cliff racer's rest", 	color = innColor},
    {keyword = "the glass goblet", 			color = innColor},
    {keyword = "the note in your eye", 		color = innColor},
    {keyword = "the magic mudcrab", 		color = innColor},
    {keyword = "twisted root", 				color = innColor},
    {keyword = "the howling hound", 		color = innColor},
    {keyword = "the sload's tale", 			color = innColor},
    {keyword = "the abecette", 				color = innColor},
    {keyword = "caravan stop", 				color = innColor},
    {keyword = "sailor's fulke", 			color = innColor},
    {keyword = "anchor's rest", 			color = innColor},
    {keyword = "the blind watchtower", 		color = innColor},
    {keyword = "plaza taverna", 			color = innColor},
    {keyword = "sunset hotel", 				color = innColor},
    {keyword = "dancing saber", 			color = innColor},
    {keyword = "stendarr's retreat", 		color = innColor}
}


local playerPos = util.vector3(0,0,0)

--------------------------------------------------------
-- Get Door data
--------------------------------------------------------

-- Filter teleport doors, keep the closest door for each unique destination cell, and return up to maxDoors closest destinations.
local function getSortedClosestDoors(playerPos, maxDoors)
    local closestByDest = {}
    local doorList = {}

    for _, obj in ipairs(nearby.doors) do
        if types.Door.objectIsInstance(obj) and types.Door.isTeleport(obj) then
            if obj.position and playerPos then
                local fullDest = tostring(types.Door.destCell(obj) or "")
                local destCell = (fullDest:match(",%s*(.*)") or fullDest)
                    :gsub("[%(%)]", "")
                    :gsub("^%s*[Ii]nterior", "")
                    :gsub("^%s+", "")

                if destCell ~= "" and not destCell:find("sys::default") then
                    local distance = (obj.position - playerPos):length()
                    local existing = closestByDest[destCell]

                    if not existing or distance < existing.distance then
                        closestByDest[destCell] = {
                            cleanDestinationName = destCell,
                            doorObj = obj,
                            distance = distance
                        }
                    end
                end
            end
        end
    end

    for _, data in pairs(closestByDest) do
        table.insert(doorList, data)
    end

    table.sort(doorList, function(a, b) return a.distance < b.distance end)

    if maxDoors then
        local n = math.min(maxDoors, #doorList)
        local trimmed = {}
        for i = 1, n do trimmed[i] = doorList[i] end
        doorList = trimmed
    end

    return doorList
end

-- Update the list of actual doors to display, maintain existing order on screen
local function updateDisplayedDoors(displayedDoors, closeDoorList)
    local newDisplayed = {}
    local used = {}

    -- First, try to keep doors in the same slot if they are still in closeDoorList
    for i = 1, #displayedDoors do
        local oldEntry = displayedDoors[i]
        if oldEntry then
            for _, entry in ipairs(closeDoorList) do
                if entry.doorObj == oldEntry.doorObj then
                    newDisplayed[i] = entry
                    used[entry.doorObj] = true
                    break
                end
            end
        end
    end

    -- Fill empty slots with remaining doors in order from closeDoorList
    local idx = 1
    for _, entry in ipairs(closeDoorList) do
        if not used[entry.doorObj] then
            -- Find first empty slot
            while newDisplayed[idx] do idx = idx + 1 end
            newDisplayed[idx] = entry
            used[entry.doorObj] = true
        end
    end

    return newDisplayed
end

--------------------------------------------------------
-- UI
--------------------------------------------------------

-- Create the UI objects that will be updated later
local function buildUI()

    local layerSize = ui.layers[1].size
    local openMWScale = screenSize.x / layerSize.x
	local arrowSize = 24 * uiScale
	local content = {}
	doorUIElements = {}

    local parentSize = util.vector2(layerSize.x/2, layerSize.y)

	for i = 1, maxDoors do
		doorUIElements[i] = {}

        local anchor
        local textposition
        local arrowposition
        if (corner == "BottomRight") then
            anchor = util.vector2(1, 1) 
            textposition =  util.vector2(parentSize.x-arrowSize,parentSize.y - ((i-1) * arrowSize) - 3) -- 3 to center text better
            arrowposition = util.vector2(parentSize.x,parentSize.y - ((i-1) * arrowSize))
        end
        if (corner == "TopRight") then
            anchor = util.vector2(1, 1) 
            textposition =  util.vector2(parentSize.x-arrowSize, (i * arrowSize) - 3) -- 3 to center text better
            arrowposition = util.vector2(parentSize.x,(i * arrowSize))
        end
        if (corner == "BottomLeft") then
            anchor = util.vector2(0, 1)
            textposition =  util.vector2(arrowSize,parentSize.y - ((i-1) * arrowSize) - 3) -- 3 to center text better
            arrowposition = util.vector2(0,parentSize.y - ((i-1) * arrowSize))
        end
        if (corner == "TopLeft") then
            anchor = util.vector2(0, 1)
            textposition =  util.vector2(arrowSize,(i * arrowSize) - 3) -- 3 to center text better
            arrowposition = util.vector2(0,(i * arrowSize))
        end

		-- Text
		doorUIElements[i].dest = {
			type = ui.TYPE.Text,
			props = {
				text = "" ,
				textShadow = true,
				autoSize = true,
				anchor = anchor,
				position = textposition,
				textSize = 15 * uiScale
			}
		}
		table.insert(content, doorUIElements[i].dest)

		-- Arrow (always to the right of text)
		doorUIElements[i].arrow = {
			type = ui.TYPE.Image,
			props = {
				resource = arrowTextures[1],
				size = util.vector2(arrowSize, arrowSize),
				anchor = anchor,
				position = arrowposition,
				color = util.color.rgb(1, 1, 1),
			}
		}
		table.insert(content, doorUIElements[i].arrow)
	end
	
	-- ONE parent for everything
    local parentPos
    if (corner == "BottomRight") then
        parentPos = util.vector2( screenSize.x / openMWScale - parentSize.x - pixelFromRight, screenSize.y / openMWScale - parentSize.y - pixelFromBottom )
    end
    if (corner == "BottomLeft") then
        parentPos = util.vector2(pixelFromRight, screenSize.y / openMWScale - parentSize.y - pixelFromBottom )
    end
    if (corner == "TopRight") then
        parentPos = util.vector2(screenSize.x / openMWScale - parentSize.x - pixelFromRight, pixelFromBottom )
    end
    if (corner == "TopLeft") then
        parentPos = util.vector2(pixelFromRight, pixelFromBottom )
    end
	parentUI = ui.create({
		layer = "HUD",
        --template = I.MWUI.templates.bordersThick,
		props = {
			size = parentSize,
			anchor = util.vector2(0, 0),
			position = parentPos
		},
		content = ui.content(content)
	})
	
end

local function rebuildUI()
    -- Destroy all existing UI elements
    if parentUI then
        parentUI:destroy()
    end
    doorUIElements = {}
    buildUI()
end

--update Arrow element at i (color, alpha, and arrow direction)
local function updateDoorArrowUI(i, doorEntry, playerPos)
    
    local arrowImage = doorUIElements[i].arrow

    --early exit if hiding UI
    if(doorEntry == nil )then
        if (arrowImage.props.resource ~= nil) then
            arrowImage.props.resource = nil
            return true
        else
            return false
        end
    end

	
	local playerYawDeg = math.deg(camera.getYaw() or 0)
    if playerYawDeg < 0 then
        playerYawDeg = playerYawDeg + 360
    end
	
	local dir = doorEntry.doorObj.position - playerPos
    local angleToTarget = math.deg(math.atan2(dir.x, dir.y))
    if angleToTarget < 0 then angleToTarget = angleToTarget + 360 end
    local relative = angleToTarget - playerYawDeg
    if relative < 0 then relative = relative + 360 end
    local arrowIndex = math.floor((relative + 22.5) / 45) % 8

    local minDist, maxDist = 300, 1000
	local t = math.max(0, math.min(
        (doorEntry.distance - minDist) / (maxDist - minDist),
        1
    ))

    local distColor = util.color.rgb(1, 0.824, t)
    local alpha = math.max(0.5, 1 - t)

    if arrowImage.props.resource ~= arrowTextures[arrowIndex]
    or math.abs((arrowImage.props.alpha or 0) - alpha) > 0.1
    or math.abs((arrowImage.props.color and arrowImage.props.color.b or 0) - distColor.b) > 0.1
    then
        arrowImage.props.resource = arrowTextures[arrowIndex]
        arrowImage.props.color = distColor
        arrowImage.props.alpha = alpha
        return true
    end
    return false
end

--Update door text at i (color and text)
local function updateDoorTextUI(i, doorEntryDestination)

    local destText = doorUIElements[i].dest


	local color = util.color.rgb(1, 1, 1)
    if doorEntryDestination == nil then
        doorEntryDestination = ""
    end
	local lower = string.lower(doorEntryDestination)

	for _, entry in ipairs(doorPatterns) do
		if lower:find(entry.keyword, 1, true) then
			color = entry.color
			break
		end
	end


    if destText.props.text ~= doorEntryDestination or destText.props.textColor ~= color then
        destText.props.text = doorEntryDestination
        destText.props.textColor = color
        return true
    end
    return false
end

-- for each door Slot, check if there is a door you should render. If there is get the right Text and Arrow and update it on the screen
local function updateDoorUI(playerPos)
	local changeMade = false
    
    --game resized
    local newSize = ui.screenSize()
    if newSize.x ~= screenSize.x or newSize.y ~= screenSize.y then
        screenSize = newSize
        rebuildUI()
        return
    end
    
    for i = 1, maxDoors do
		local doorEntry = displayedDoors[i]
		if doorEntry then
			changeMade = updateDoorTextUI(i, doorEntry.cleanDestinationName) or changeMade
			changeMade = updateDoorArrowUI(i, doorEntry, playerPos) or changeMade
		else
			-- Clear empty slots
			changeMade = updateDoorTextUI(i, "") or changeMade
			changeMade = updateDoorArrowUI(i, nil, nil) or changeMade
		end
	end
    if changeMade then
        parentUI:update()
    end
end

-- Clear all UI when inside
local function clearAllUI()
    local changeMade = false
    for i = 1, maxDoors do
        local slot = doorUIElements[i]
        if slot then
			changeMade = updateDoorTextUI(i, "") or changeMade
			changeMade = updateDoorArrowUI(i, nil, nil) or changeMade
        end
    end
    if(changeMade) then
        parentUI:update()
    end

    displayedDoors = {}
end

local function onUpdate(dt)
	-- Update UI
	timeSinceLastUpdateUI = timeSinceLastUpdateUI + dt
    if timeSinceLastUpdateUI > UPDATE_INTERVAL_UI then
        timeSinceLastUpdateUI = 0 
        --get player pos
        playerPos = self.position
        --clear when indoors
        if (not self.cell.isExterior) or not (I.UI.isHudVisible()) then
            clearAllUI()
            return
        else
            -- Update the display on the screen
            updateDoorUI(playerPos)
        end
    end


	-- Update Nearby Doors
	timeSinceLastUpdateDoorCheck = timeSinceLastUpdateDoorCheck + dt
    if timeSinceLastUpdateDoorCheck > UPDATE_INTERVAL_DOOR_CHECK then
        timeSinceLastUpdateDoorCheck = 0 
        --get player pos
        playerPos = self.position
        -- Get closest doors
        local closeDoorList = getSortedClosestDoors(playerPos, maxDoors)
        -- Get doors that need to be display, take into account doors that are still in range and dont change position in layout
        displayedDoors = updateDisplayedDoors(displayedDoors, closeDoorList)
    end
	
end

--------------------------------------------------------
-- Settings
--------------------------------------------------------
I.Settings.registerPage {
    key = MOD_NAME,
    l10n = "DenyingProduct" .. MOD_NAME,
    name = "Nearby Doors",
	description = "Nearby Doors 1.3 by Denying Product\n" ..
				  "Shows nearby doors on the GUI\n" ..
				  "You can adjust max doors, size, and placement"
}

I.Settings.registerGroup {
    key = "SettingsPlayer" .. MOD_NAME,
    l10n = "DenyingProduct" .. MOD_NAME,
    name = "Nearby Door Settings",
    page = MOD_NAME,
    description = "Options for Nearby Door display",
    permanentStorage = true,
    settings = {
        {
            key = "maxDoors",
            renderer = "number",
            name = "Max Doors Displayed",
            description = "How many doors to show ",
            default = 3,
            argument = {integer = true}
        },		
        {
			key = "uiScale",
			renderer = "number",
			name = "UI Scale",
			description = "Scale text and arrows",
			default = 1.0,
		},
        {
            key = "pixelFromRight",
            renderer = "number",
            name = "Pixel From Right/Left",
            description = "Pixels from the right/left of the screen",
            default = 80,
            argument = {integer = true}
        },
        {
            key = "pixelFromBottom",
            renderer = "number",
            name = "Pixel From Bottom/Top",
            description = "Pixels from the bottom/top of the screen",
            default = 35,
            argument = {integer = true}
        },
        {
            key = "corner",
            renderer = "select",
            name = "Corner",
            description = "Which corner should the UI be in",
            default = "BottomRight",
            argument = {
                l10n = "DenyingProduct" .. MOD_NAME,
                items = {
                    "BottomRight",
                    "BottomLeft",
                    "TopRight",
                    "TopLeft"
                }
            }
        }
    }
}

local function updateSettings()

    maxDoors    = playerSettings:get("maxDoors") or 3
    pixelFromRight  = playerSettings:get("pixelFromRight") or 80
    pixelFromBottom = playerSettings:get("pixelFromBottom") or 35
    uiScale = playerSettings:get("uiScale") or 1.0
    corner = playerSettings:get("corner") or "BottomRight"

    rebuildUI()
end
playerSettings:subscribe(async:callback(function(section, key) updateSettings() end))
updateSettings()

return {
    engineHandlers = {
        onUpdate = onUpdate
    }
}
