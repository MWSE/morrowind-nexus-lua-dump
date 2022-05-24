--[[ Twist rope from mc_coarsefiber.
	Part of Morrowind Crafting 3
	Toccatta and Drac ]]--

local configPath = "Morrowind_Crafting_3"
local config = mwse.loadConfig(configPath)

local this = {}
local spininfo, batchCount, fiberCount
local mc = require("Morrowind_Crafting_3.mc_common")

function this.init()
	this.id_menu = tes3ui.registerID("cordage_wheel_lua")
	this.id_single = tes3ui.registerID("cordage_wheel_button_1")
	this.id_multi = tes3ui.registerID("cordage_wheel_button_multi")
	this.id_cancel = tes3ui.registerID("cordage_wheel_button_cancel")
end

function this.qtySlider()
	tes3ui.enterMenuMode()
	config = mwse.loadConfig(configPath)
    this.id_SliderMenu = tes3ui.registerID("qtySlider")
    local testItem = "Slider" 
	local sliderMenu = tes3ui.createMenu{ id = this.id_SliderMenu, fixedFrame = true }
	passValue = -1
    sliderMenu.alpha = 0.75
	sliderMenu.text = "Ropemaking"
	sliderMenu.width = 550
	sliderMenu.height = 250
	sliderMenu.minWidth = 550
	sliderMenu.minHeight = 120
	batchCount = math.floor( mwscript.getItemCount({ reference = "player", item = "mc_coarsefiber" }) / 20 )
	local hBlock = sliderMenu:createBlock()
	hBlock.widthProportional = 1.0
    hBlock.heightProportional = 1.0
	hBlock.childAlignX = 0.5 
	hBlock.flowDirection = "top_to_bottom"
	local label = hBlock:createLabel({ text = "Twisting Rope" })
	label.color = tes3ui.getPalette("header_color")
	local label = hBlock:createLabel({ text = "" }) -- spacer
	
	local mBlock = sliderMenu:createBlock()
	mBlock.widthProportional = 1.0
    mBlock.height = 30
	mBlock.childAlignX = -1.0
	mBlock.childAlignY = 1.0
	local label = mBlock:createLabel({ text = "Number to make: " })
	local label = mBlock:createLabel({ text = "" })
	if config.tasktime == true then
		if (batchCount > 240) then
			local label = mBlock:createLabel({ text = "Maximum 240 ropes per day." })
			batchCount = 240
		end
	end

    local pBlock = sliderMenu:createBlock()
    pBlock.widthProportional = 1.0
    pBlock.height = 40
	pBlock.autoHeight = true
    pBlock.childAlignX = 0.5
	pBlock.flowDirection = "left_to_right"
	
	local slider = pBlock:createSlider({ id = "sliderUID", current = batchCount, max = batchCount, step = 1, jump = 5 })
	slider.widthProportional = 1.5
    pBlock.childAlignY = 0.6
	passValue = batchCount
    local sNumber = pBlock:createLabel({ text = " ("..string.format("%5.0f", batchCount)..")" })
    sNumber.widthProportional = 1.0
    sNumber.height = 24
    local sOK = pBlock:createButton({ text = " OK "})
    sOK.widthProportional = .5
    local sCancel = pBlock:createButton({ text = "Cancel" })
	sCancel.widthProportional = 1.0

    slider:register("PartScrollBar_changed", function(e)
        --testItem = slider:getPropertyInt("PartScrollBar_current") + 1 --params.min
        sNumber.text = string.format(" (%5.0f", slider:getPropertyInt("PartScrollBar_current"))..")"
        passValue = slider:getPropertyInt("PartScrollBar_current")
        end) 
    sCancel:register("mouseClick",
        function()
            tes3ui.leaveMenuMode()
            sliderMenu:destroy()
			passValue = 0
            return false
        end
        )
    sOK: register("mouseClick", 
        function()
            tes3ui.leaveMenuMode()
            sliderMenu:destroy()
			this.makeRope(passValue)
        end
        )
    -- Final setup
    sliderMenu:updateLayout()
    tes3ui.enterMenuMode(this.id_SliderMenu)
end

function this.makeRope(batchCount)
	local usedfiber
	usedfiber = batchCount * 20
	if batchCount >= 1 then
		tes3.removeItem({ reference = tes3.player, item = "mc_coarsefiber", count = usedfiber, playSound = false })
		tes3.addItem({ reference = tes3.player, item = "mc_Rope", count = batchCount, playSound = false })
		tes3.messageBox({ message = "You make " .. batchCount .. " ropes." })
		tes3.playSound({ sound = "enchant success", volume = 1.0, pitch = 0.9 })
		tes3ui.leaveMenuMode()
		if config.tasktime == true then
			mc.timePass(0.1 * batchCount) -- 6 minutes to twist a rope
		end
	end
end
	
local function mc_cordagewheel_p_activate(e)
	if (e.activator == tes3.player) then
		if ( e.target.object.id == "mc_Cordagewheel_p" ) then
			if mc.uninstalling() == false then
				this.qtySlider()
				return false
			end
		elseif (e.target.object.id == "mc_Cordagewheel_perm" ) then
			this.qtySlider()
			return false	
		end
   end
end
event.register("activate", mc_cordagewheel_p_activate)