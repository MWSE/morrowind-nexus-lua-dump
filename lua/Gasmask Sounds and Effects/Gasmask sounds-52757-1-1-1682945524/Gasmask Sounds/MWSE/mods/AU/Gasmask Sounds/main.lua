local mod = { name = "Gasmask Sounds", ver = "1.0" }
local cf = require("AU.Gasmask Sounds.config")

--[[
Find Gasmasks
--]]

-- find all clothing and armor items
local function getNotGasMasks()
    local notMask = {}
	
	local itemTypes = { 
		[tes3.objectType.armor] = true,
		[tes3.objectType.clothing] = true
	}	
	
	for itemType, _ in pairs(itemTypes)do
		for obj in tes3.iterateObjects(itemType) do
			notMask[obj.id:lower()] = true
		end
	end
	
    local list = {}
	
    for id in pairs(notMask) do
        list[#list+1] = id
    end
    
    table.sort(list)
    return list
end 

--[[
Gasmasks sounds
--]]

--Check if gas mask is already equipped on game load
local function gasMaskCheck()
    for _, item in ipairs(tes3.player.object.equipment) do
        if cf.gasmasks[item.object.id:lower()] then
            tes3.playSound({
                reference = tes3.player,
                soundPath = "\\AU\\gasmask_sound.wav",
                volume = (cf.volume/100),
                loop = true,
            })
            return
        end
    end
end
event.register("loaded", gasMaskCheck, { priority = 10 })

-- when gasmask is equipped
local function onMaskEquipped(e)
    if (e.reference ~= tes3.player or not cf.onOff) then
        return
    end

    if cf.gasmasks[e.item.id:lower()] then
        tes3.messageBox("You have equipped a gasmask.")
		tes3.playSound({
            reference = e.reference,
            soundPath = "\\AU\\gasmask_sound.wav",
			volume = (cf.volume/100),
            loop = true,
        })
    end
end
event.register("equipped", onMaskEquipped)

-- when gasmask is unequipped
local function onMaskUnequipped(e)
    if e.reference ~= tes3.player then
        return
    end

    if cf.gasmasks[e.item.id:lower()] then
        tes3.messageBox("You have unequipped a gasmask.")
        tes3.removeSound({
            reference = e.reference,
            soundPath = "\\AU\\gasmask_sound.wav" ,
        })
    end
end
event.register("unequipped", onMaskUnequipped)

--[[
MCM Menu
--]]

local function registerModConfig()

    local template = mwse.mcm.createTemplate(mod.name)
    template:saveOnClose(mod.name, cf)
    template:register()

	-- front page
	local page = template:createSideBarPage({ label = "\"" .. mod.name .. "\" Settings" })
	page.sidebar:createInfo{ text = "Welcome to " .. mod.name .. " Configuration Menu.\n\nMod revised by:" }
	page.sidebar:createHyperLink{ text = "ActuallyUlysses", url = "https://www.nexusmods.com/users/27648985?tab=user+files" }

	-- mod ON/OFF switch
	local category = page:createCategory("Mod switch:")
	category:createOnOffButton{
		label = "On/Off",
		description = "If set to OFF, you will no longer hear your character breathing through gas mask. [Default: ON]",
		variable = mwse.mcm.createTableVariable { id = "onOff", table = cf },
	}

	-- volume slider
	local category2 = page:createCategory("Gas mask volume:")
	local subcat = category2:createCategory("")
	subcat:createSlider{
		label = "Volume",
		description = "You can change gas mask breathing sound volume by moving this slider [Default: 90]",
		min = 0,
		max = 100,
		step = 1,
		jump = 1,
		variable = mwse.mcm.createTableVariable { id = "volume", table = cf },
	}


	-- gasmask list
    template:createExclusionsPage{
        label = "Gasmasks",
        leftListLabel = "Gasmasks",
        rightListLabel = "Not Gasmasks",
        description = "Here you can mark items as gasmasks.",
        variable = mwse.mcm.createTableVariable { 
			id = "gasmasks", 
			table = cf 
		},
        filters = { 
			{ 
				label = "Gasmasks", 
				callback = getNotGasMasks, 
			} 
		},
    }
end
event.register("modConfigReady", registerModConfig)

--[[
MWSE.log print
--]]

local function initialized()
    print("[" .. mod.name .. ", by ActuallyUlysses] " .. mod.ver .. " Initialized!")
end
event.register("initialized", initialized)