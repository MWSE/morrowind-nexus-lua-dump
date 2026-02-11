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
    l10n = MOD_NAME,
    name = "Nearby Doors",
	description = "Nearby Doors 1.1 by Denying Product\n" ..
				  "Shows nearby doors on the GUI\n" ..
				  "You can adjust max doors, size, and placement"
}

I.Settings.registerGroup {
    key = "SettingsPlayer" .. MOD_NAME,
    l10n = MOD_NAME,
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

local doorTexts = {}
local parentUI = nil

local UPDATE_INTERVAL = 0.25
local timeSinceLastUpdate = 0

local arrowTextures = {}
for i = 0, 7 do
    arrowTextures[i] = ui.texture { path = "textures/DenyingProduct/doorArrow/arrow-"..i..".dds" }
end

local shopColor   = util.color.rgb(1, 0.824, 0.294)
local magicColor  = util.color.rgb(0.294, 0.725, 1)
local fightColor  = util.color.rgb(1, 0.675, 0.294)
local templeColor = util.color.rgb(0.294, 1, 0.584)
local redColor    = util.color.rgb(1, 0.294, 0.294)
local innColor    = util.color.rgb(0.561, 0.294, 1)
local doorPatterns = {
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

------------------------------------------------------------
-- Utility
------------------------------------------------------------
local function getArrowIndex(playerPos, playerYawDeg, targetPos)
    local dir = targetPos - playerPos
    local angleToTarget = math.deg(math.atan2(dir.x, dir.y))
    if angleToTarget < 0 then angleToTarget = angleToTarget + 360 end
    local relative = angleToTarget - playerYawDeg
    if relative < 0 then relative = relative + 360 end
    return math.floor((relative + 22.5) / 45) % 8
end

local function clearUIFrom(line)
    for i = line+1, maxDoors do
        local dest, arrow = doorTexts[i].dest, doorTexts[i].arrow
        if dest.layout.props.text ~= "" then
            dest.layout.props.text = ""
            dest:update()
        end
        if arrow.layout.props.resource ~= nil then
            arrow.layout.props.resource = nil
            arrow:update()
        end
    end
end

local function buildUI()
	local screenSize = ui.screenSize()
	local arrowSize = 24 * uiScale
	local hSizePerElement = arrowSize / screenSize.y
	local WSizePerElement = arrowSize / screenSize.x
	
	local content = {}

	doorTexts = {}

	for i = 1, maxDoors do
		doorTexts[i] = {}

		-- Text
		doorTexts[i].dest = ui.create({
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
		table.insert(content, doorTexts[i].dest)

		-- Arrow (always to the right of text)
		doorTexts[i].arrow = ui.create({
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
		table.insert(content, doorTexts[i].arrow)
	end
	
	-- ONE parent for everything
	parentUI = ui.create({
		layer = "HUD",
		props = {
			size = util.vector2 (screenSize.x, screenSize.y),
            anchor = util.vector2(1, 1),
			relativePosition = util.vector2(
				(screenSize.x - pixelFromRight) / screenSize.x,
				(screenSize.y - pixelFromBottom) / screenSize.y
			)
		},
        content = ui.content(content)
	})
	
end

local function applySettings()
	
	print ("DenyingProduct - NearbyDoors - Updating Settings")

	-- Destroy all existing UI elements
	if parentUI then
		parentUI:destroy()
	end
    doorTexts = {}

    maxDoors    = playerSettings:get("maxDoors") or 3
	pixelFromRight  = playerSettings:get("pixelFromRight") or 80
	pixelFromBottom = playerSettings:get("pixelFromBottom") or 35
	uiScale = playerSettings:get("uiScale") or 1.0

	buildUI()
end

buildUI()

------------------------------------------------------------
-- Update function
------------------------------------------------------------
local function onUpdate(dt)
    
	timeSinceLastUpdate = timeSinceLastUpdate + dt
    if timeSinceLastUpdate < UPDATE_INTERVAL then return end
    timeSinceLastUpdate = 0
	
    -- Clear UI indoors
    if not self.cell.isExterior then
        clearUIFrom(0)
        return
    end
	
	-- Only apply settings once if anything changed
	local newMaxDoors     = playerSettings:get("maxDoors") or 3
	local newpixelFromRight  = playerSettings:get("pixelFromRight") or 80
	local newpixelFromBottom = playerSettings:get("pixelFromBottom") or 35
	local newuiScale = playerSettings:get("uiScale") or 1
	if newMaxDoors ~= maxDoors or newpixelFromRight ~= pixelFromRight or newpixelFromBottom ~= pixelFromBottom or newuiScale ~= uiScale then
		applySettings()
	end

	
    local playerPos = self.position
    local playerYawDeg = math.deg(camera.getYaw() or 0)
    if playerYawDeg < 0 then playerYawDeg = playerYawDeg + 360 end

    -- Top-N closest teleport doors
    local doorsList = {}
    for _, obj in ipairs(nearby.doors) do
        if types.Door.objectIsInstance(obj) and types.Door.isTeleport(obj) then
            local dist = (obj.position - playerPos):length()
            if #doorsList < maxDoors then
                doorsList[#doorsList+1] = {door=obj, dist=dist}
            else
                local maxIdx, maxDist = 1, doorsList[1].dist
                for i=2,#doorsList do
                    if doorsList[i].dist > maxDist then
                        maxDist, maxIdx = doorsList[i].dist, i
                    end
                end
                if dist < maxDist then doorsList[maxIdx] = {door=obj, dist=dist} end
            end
        end
    end

    local seen = {}
    local line = 0
    for _, d in ipairs(doorsList) do
        local full = tostring(types.Door.destCell(d.door) or "")
        local destCell = (full:match(",%s*(.*)") or full)
            :gsub("[%(%)]", "")
            :gsub("^%s*[Ii]nterior", "")
            :gsub("^%s+", "")
		if destCell:find("sys::default") then
			destCell = "Unknown"
		end
		
        if destCell ~= "" and not seen[destCell] then
            seen[destCell] = true
            line = line + 1
            if line > maxDoors then break end

            local destText, arrowImage = doorTexts[line].dest, doorTexts[line].arrow

			local color = util.color.rgb(1,1,1)
			local lower = string.lower(destCell)
			for _, entry in ipairs(doorPatterns) do
				if lower:find(entry.keyword, 1, true) then
					color = entry.color
					break
				end
			end

			--get dest color and text
            if destText.layout.props.text ~= destCell or destText.layout.props.textColor ~= color then
                destText.layout.props.text = destCell
                destText.layout.props.textColor = color
                destText:update()
            end

			--get arrow direction
            local arrowIndex = getArrowIndex(playerPos, playerYawDeg, d.door.position)

			--get color and alpha
			local minDist, maxDist = 300, 1000
			local t = math.max(0, math.min((d.dist - minDist) / (maxDist - minDist), 1))
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
    end

    -- Clear unused rows
    clearUIFrom(line)
end

return {
    engineHandlers = {
        onUpdate = onUpdate
    }
}
