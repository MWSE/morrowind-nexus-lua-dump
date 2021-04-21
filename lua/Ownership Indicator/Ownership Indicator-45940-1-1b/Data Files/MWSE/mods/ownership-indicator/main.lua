local config = json.loadfile("config/pg_ownership_config")
if not config then
	config = {
		autoHide = false,
		useTex = true,
		crosshairScale = 1.0,
		indicatorScale = 1.0
	}
end

-- Save people deleting their config.
if config.indicatorScale == nil then
	config.indicatorScale = 1.0
end

local function onInitialized()
	print("[pg-ownership]: Initialized ownership indicator.")
end
event.register("initialized", onInitialized)

local function onLoaded(e)
	-- Hide the crosshair.We hide the niTriShape instead of the main niNode,
	-- because Bethesda appCull the main node to hide it in the menu.
	tes3.worldController.nodeCursor.children[1].appCulled = true
end
event.register("loaded", onLoaded)

local crosshair = {}
local function createCrosshair()
	if crosshair.parent == nil then
		return
	end

	crosshair.main = crosshair.parent:createBlock()
	crosshair.main.layoutOriginFractionX = 0.5
	crosshair.main.layoutOriginFractionY = 0.5
	crosshair.main.autoWidth = true
	crosshair.main.autoHeight = true

	local defaultTex = "textures/target_default.dds"
	if lfs.attributes("data files/textures/target.dds") then
		defaultTex = "textures/target.dds"
	end
	crosshair.default = crosshair.main:createImage({ path = defaultTex })
	crosshair.default.scaleMode = true
	crosshair.default.width = 32 * config.crosshairScale
	crosshair.default.height = 32 * config.crosshairScale


	local stealTex = "textures/ownership_indicator.dds"
	local stealColor = {1.0, 1.0, 1.0}
	if not config.useTex then
		stealTex = defaultTex
		stealColor = {1.0, 0.1, 0.1}
	end
	crosshair.steal = crosshair.main:createImage({ path = stealTex })
	crosshair.steal.color = stealColor
	crosshair.steal.visible = false
	crosshair.steal.scaleMode = true
	crosshair.steal.width = 32 * config.indicatorScale
	crosshair.steal.height = 32 * config.indicatorScale

	crosshair.main:updateLayout()
end

local function onMenuMultiCreated(e)
	if not e.newlyCreated then
		return
	end
	crosshair = {}
	crosshair.parent = e.element
	createCrosshair()
end
event.register("uiActivated", onMenuMultiCreated, { filter = "MenuMulti" })

local function setCrosshair(e)
	crosshair.default.visible = false
	crosshair.steal.visible = false

	if e == crosshair.default and tes3.worldController.cursorOff then
		return
	end

	e.visible = true
end

local function updateIndicator(target)
	setCrosshair(crosshair.default)
	if target ~= nil then
		-- Don't show the indicator for doors! and things that are pretending to be doors
		if target.object.objectType == tes3.objectType.door or string.find(target.object.name, '[Dd]oor') then
			return
		end
		if target.object.objectType == tes3.objectType.activator and not ( string.find(target.object.name, '[Bb]ed') or string.find(target.object.name, '[Ss]leep') ) then
			return
		end

		local owner = tes3.getOwner(target)
		if owner ~= nil then
			if owner.objectType == tes3.objectType.npc then
				-- Check it's not a rented bed.
				local globalVar = target.attachments.variables.requirement
				if globalVar == nil or globalVar.value ~= 1 then
					setCrosshair(crosshair.steal)
				end
			-- Factions may allow the player to use their items, if they're a member of adequate rank
			elseif owner.objectType == tes3.objectType.faction then
				if not owner.playerJoined or target.attachments.variables.requirement > owner.playerRank then
					setCrosshair(crosshair.steal)
				end
			end
		-- Pickpocketing (living) people is always bad.
		elseif target.object.objectType == tes3.objectType.npc and tes3.mobilePlayer.isSneaking and target.mobile.health.current > 0 then
			setCrosshair(crosshair.steal)
		end
	end
end

local function onActivationTargetChanged(e)
	updateIndicator(e.current)
end
event.register("activationTargetChanged", onActivationTargetChanged)

local hideTime = 0
local prevSneaking
local function onSimulate(e)
	crosshair.main.visible = true

	if prevSneaking ~= tes3.mobilePlayer.isSneaking then
		updateIndicator(tes3.getPlayerTarget())
	end
	prevSneaking = tes3.mobilePlayer.isSneaking

	if tes3.mobilePlayer.is3rdPerson then
		crosshair.main.visible = false
	end

	if config.autoHide then
		if tes3.getPlayerTarget() == nil and not tes3.mobilePlayer.castReady and ( not tes3.mobilePlayer.weaponReady or tes3.mobilePlayer.readiedWeapon == nil or not tes3.mobilePlayer.readiedWeapon.object.isRanged) then
			hideTime = hideTime + e.delta
			if hideTime > 1.5 then
				crosshair.main.visible = false
			end
		else
			hideTime = 0
		end
	end
end
event.register("simulate", onSimulate)

local function menuUpdate(e)
	crosshair.main.visible = not e.menuMode

	if e.menuMode == false then
		updateIndicator(tes3.getPlayerTarget())
	end
end
event.register("menuEnter", menuUpdate)
event.register("menuExit", menuUpdate)


--ModConfig

local modConfig = {}

function modConfig.onCreate(container)
	local pane = container:createThinBorder{}
	pane.layoutWidthFraction = 1.0
	pane.layoutHeightFraction = 1.0
	pane.paddingAllSides = 12
    pane.flowDirection = "top_to_bottom"

    local header = pane:createLabel{ text = "Ownership Indicator\nversion 1.1b" }
	header.color = tes3ui.getPalette("header_color")
    header.borderBottom = 25

	-- Description and credits

    local txt = pane:createLabel{}
    txt.wrapText = true
    txt.height = 1
    txt.layoutWidthFraction = 1.0
    txt.layoutHeightFraction = -1.0
    txt.borderBottom = 25
    txt.text = "Adds an ownership indicator when you're about to steal something, or break the law.\n\nThanks to Yacoby for creating the original MGE XE plugin.\nSpecial thanks to NullCascade, Hrnchamd, and Greatness7.\n\nCreated by Petethegoat."
	
	-- Crosshair Autohide

	local hideBlock = pane:createBlock()
	hideBlock.flowDirection = "left_to_right"
    hideBlock.layoutWidthFraction = 1.0
	hideBlock.height = 32

	local hideLabel = hideBlock:createLabel({ text = "Autohide Crosshair:" })

	local hideButton = hideBlock:createButton({ text = config.autoHide and tes3.getGMST(tes3.gmst.sYes).value or tes3.getGMST(tes3.gmst.sNo).value })
	hideButton.width = 64
	hideButton.layoutOriginFractionX = 1.0
	hideButton.borderRight = 6
	hideButton:register("mouseClick", function(e)
		config.autoHide = not config.autoHide
		hideButton.text = config.autoHide and tes3.getGMST(tes3.gmst.sYes).value or tes3.getGMST(tes3.gmst.sNo).value
	end)
	
	-- Use icon or colorize crosshair

	local iconBlock = pane:createBlock()
	iconBlock.flowDirection = "left_to_right"
    iconBlock.layoutWidthFraction = 1.0
	iconBlock.height = 32

	local iconLabel = iconBlock:createLabel({ text = "Use Ownership Indicator Texture:" })

	local iconButton = iconBlock:createButton({ text = config.useTex and tes3.getGMST(tes3.gmst.sYes).value or tes3.getGMST(tes3.gmst.sNo).value })
	iconButton.width = 64
	iconButton.layoutOriginFractionX = 1.0
	iconButton.borderRight = 6
	iconButton:register("mouseClick", function(e)
		config.useTex = not config.useTex
		iconButton.text = config.useTex and tes3.getGMST(tes3.gmst.sYes).value or tes3.getGMST(tes3.gmst.sNo).value
	end)
	
	-- Crosshair Scale

	local scaleBlock = pane:createBlock()
	scaleBlock.flowDirection = "left_to_right"
    scaleBlock.layoutWidthFraction = 1.0
	scaleBlock.height = 32

	local scaleLabel = scaleBlock:createLabel({ text = string.format("Crosshair Scale: %.1fX", config.crosshairScale) })

	local scaleSlider = scaleBlock:createSlider({ current = (config.crosshairScale * 10) - 5, max = 15, step = 1})
	scaleSlider.width = 256
	scaleSlider.layoutOriginFractionX = 1.0
	scaleSlider.borderRight = 6
	scaleSlider:register("PartScrollBar_changed", function(e)
		config.crosshairScale = (scaleSlider:getPropertyInt("PartScrollBar_current") + 5) / 10
        scaleLabel.text = string.format("Crosshair Scale: %.1fX", config.crosshairScale)
	end)

	-- Indicator Scale
	
	local scale2Block = pane:createBlock()
	scale2Block.flowDirection = "left_to_right"
    scale2Block.layoutWidthFraction = 1.0
	scale2Block.height = 32

	local scale2Label = scale2Block:createLabel({ text = string.format("Indicator Scale: %.1fX", config.indicatorScale) })

	local scaleSlider2 = scale2Block:createSlider({ current = (config.indicatorScale * 10) - 5, max = 15, step = 1})
	scaleSlider2.width = 256
	scaleSlider2.layoutOriginFractionX = 1.0
	scaleSlider2.borderRight = 6
	scaleSlider2:register("PartScrollBar_changed", function(e)
		config.indicatorScale = (scaleSlider2:getPropertyInt("PartScrollBar_current") + 5) / 10
        scale2Label.text = string.format("Indicator Scale: %.1fX", config.indicatorScale)
	end)

    pane:updateLayout()
end

function modConfig.onClose(container)
	json.savefile("config/pg_ownership_config", config, { indent = true })

	if crosshair.main ~= nil then
		createCrosshair()
	end
end

local function registerModConfig()
	mwse.registerModConfig("Ownership Indicator", modConfig)
end
event.register("modConfigReady", registerModConfig)
