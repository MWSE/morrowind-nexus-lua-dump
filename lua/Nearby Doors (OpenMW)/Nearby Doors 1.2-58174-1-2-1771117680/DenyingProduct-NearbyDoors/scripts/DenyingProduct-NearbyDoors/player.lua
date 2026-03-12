local nearby = require('openmw.nearby')
local types = require('openmw.types')
local self = require('openmw.self')
local ui = require('openmw.ui')
local util = require('openmw.util')
local camera = require('openmw.camera')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')

local MOD_NAME = "NearbyDoors"

I.Settings.registerPage {
    key = MOD_NAME,
    l10n = "DenyingProduct" .. MOD_NAME,
    name = "Nearby Doors",
	description = "Nearby Doors 1.2 by Denying Product\n" ..
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
            key = "pixelFromRight",
            renderer = "number",
            name = "Pixel From Right",
            description = "Pixels from the right of the screen",
            default = 80,
            argument = {integer = true}
        },
        {
            key = "pixelFromBottom",
            renderer = "number",
            name = "Pixel From Bottom",
            description = "Pixels from the bottom of the screen",
            default = 35,
            argument = {integer = true}
        },
		{
			key = "uiScale",
			renderer = "number",
			name = "UI Scale",
			description = "Scale text and arrows",
			default = 1.0,
		},
    }
}

local playerSettings = storage.playerSection("SettingsPlayer" .. MOD_NAME)
local maxDoors = playerSettings:get("maxDoors") or 3
local pixelFromRight  = playerSettings:get("pixelFromRight") or 80
local pixelFromBottom = playerSettings:get("pixelFromBottom") or 35
local uiScale = playerSettings:get("uiScale") or 1.0

-- displayedDoors[1] = {
--    doorObj = OpenMW Type.Door
--    cleanDestinationName = "Caius' House"
--    distance = 12.5 Distance from player
-- }
local displayedDoors = {}          -- Currently displayed doors (keeps track of which doors occupy which UI slot)

-- doorUIElements[i] = {
--     dest  = <UI Text element>,  -- the text object displaying the door name
--     arrow = <UI Image element>  -- the arrow image object pointing toward the door
-- }
local doorUIElements = {}          -- Table of door text + arrow UI objects for each slot 


local parentUI = nil               -- The parent UI container holding all door UI elements

local UPDATE_INTERVAL = 0.25       -- Seconds between updates
local timeSinceLastUpdate = 0      -- Accumulated time since last update

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

-- Clear all UI when inside
local function clearAllUI()
    for i = 1, maxDoors do
        local slot = doorUIElements[i]
        if slot then
            -- Clear text
            if slot.dest then
                slot.dest.layout.props.text = ""
                slot.dest:update()
            end

            -- Clear arrow
            if slot.arrow then
                slot.arrow.layout.props.resource = nil
                slot.arrow:update()
            end
        end
    end

    displayedDoors = {}
end

-- Create the UI objects that will be updated later
local function buildUI()
	local screenSize = ui.screenSize()
	local arrowSize = 24 * uiScale
	local hSizePerElement = arrowSize / screenSize.y
	local WSizePerElement = arrowSize / screenSize.x
	
	local content = {}

	doorUIElements = {}

	for i = 1, maxDoors do
		doorUIElements[i] = {}

		-- Text
		doorUIElements[i].dest = ui.create({
			type = ui.TYPE.Text,
			props = {
				text = "",
				textShadow = true,
				autoSize = true,
				anchor = util.vector2(1, 1),
				relativePosition = util.vector2(
					1 - WSizePerElement,
					1 - ((i-1) * hSizePerElement)
				),
				textSize = 15 * uiScale,
				textAlignH = ui.ALIGNMENT.End,
				textAlignV = ui.ALIGNMENT.Start,
			}
		})
		table.insert(content, doorUIElements[i].dest)

		-- Arrow (always to the right of text)
		doorUIElements[i].arrow = ui.create({
			type = ui.TYPE.Image,
			props = {
				resource = arrowTextures[1],
				size = util.vector2(arrowSize, arrowSize),
				anchor = util.vector2(1, 1),
				relativePosition = util.vector2(
					1,
					1 - ((i-1) * hSizePerElement)
				),
				color = util.color.rgb(1, 1, 1),
			}
		})
		table.insert(content, doorUIElements[i].arrow)
	end
	
	-- ONE parent for everything
	parentUI = ui.create({
		layer = "HUD",
		props = {
			size = util.vector2(screenSize.x, screenSize.y),
			anchor = util.vector2(1, 1),
			relativePosition = util.vector2(
				(screenSize.x - pixelFromRight) / screenSize.x,
				(screenSize.y - pixelFromBottom) / screenSize.y
			)
		},
		content = ui.content(content)
	})
	
end

--Check for setting updates and update UI after settings is changed
local function checkForSettingChange()
    -- Only apply settings once if anything changed
    local newMaxDoors      = playerSettings:get("maxDoors") or 3
    local newPixelFromRight  = playerSettings:get("pixelFromRight") or 80
    local newPixelFromBottom = playerSettings:get("pixelFromBottom") or 35
    local newUiScale = playerSettings:get("uiScale") or 1.0

    if newMaxDoors ~= maxDoors or 
       newPixelFromRight ~= pixelFromRight or 
       newPixelFromBottom ~= pixelFromBottom or 
       newUiScale ~= uiScale then
		print ("DenyingProduct - NearbyDoors - Updating Settings")

		-- Destroy all existing UI elements
		if parentUI then
			parentUI:destroy()
		end
		doorUIElements = {}

		maxDoors    = playerSettings:get("maxDoors") or 3
		pixelFromRight  = playerSettings:get("pixelFromRight") or 80
		pixelFromBottom = playerSettings:get("pixelFromBottom") or 35
		uiScale = playerSettings:get("uiScale") or 1.0

		buildUI()
    end
end

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

--update Arrow element at i (color, alpha, and arrow direction)
local function updateDoorArrow(i, doorEntry, playerPos)
    local arrowImage = doorUIElements[i].arrow
	
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

    if arrowImage.layout.props.resource ~= arrowTextures[arrowIndex] or
       arrowImage.layout.props.alpha ~= alpha then

        arrowImage.layout.props.resource = arrowTextures[arrowIndex]
        arrowImage.layout.props.color = distColor
        arrowImage.layout.props.alpha = alpha
        arrowImage:update()
    end
end

--Update door text at i (color and text)
local function updateDoorText(i, doorEntryDestination)

    local destText = doorUIElements[i].dest


	local color = util.color.rgb(1, 1, 1)
	local lower = string.lower(doorEntryDestination)

	for _, entry in ipairs(doorPatterns) do
		if lower:find(entry.keyword, 1, true) then
			color = entry.color
			break
		end
	end


    if destText.layout.props.text ~= doorEntryDestination or
       destText.layout.props.textColor ~= color then

        destText.layout.props.text = doorEntryDestination
        destText.layout.props.textColor = color
        destText:update()
    end
end

-- for each door Slot, check if there is a door you should render. If there is get the right Text and Arrow and update it on the screen
local function renderDisplayedDoors(playerPos)
	for i = 1, maxDoors do
		local doorEntry = displayedDoors[i]
		if doorEntry then
			updateDoorText(i, doorEntry.cleanDestinationName)
			updateDoorArrow(i, doorEntry, playerPos)
		else
			-- Clear empty slots
			updateDoorText(i, "")
			local arrow = doorUIElements[i].arrow
			if arrow then
				arrow.layout.props.resource = nil
				arrow:update()
			end
		end
	end
end

local function onUpdate(dt)
    
	-- Dont run full script every frame
	timeSinceLastUpdate = timeSinceLastUpdate + dt
    if timeSinceLastUpdate < UPDATE_INTERVAL then return end
    timeSinceLastUpdate = 0

    checkForSettingChange()
	
	--clear when indoors
    if not self.cell.isExterior then
        clearAllUI()
        return
    end

    local playerPos = self.position

	-- Get closest doors
    local closeDoorList = getSortedClosestDoors(playerPos, maxDoors)
	
	-- Get doors that need to be display, take into account doors that are still in range and dont change position in layout
    displayedDoors = updateDisplayedDoors(displayedDoors, closeDoorList)
	
	-- Update the display on the screen
    renderDisplayedDoors(playerPos)

end

buildUI()

return {
    engineHandlers = {
        onUpdate = onUpdate
    }
}
