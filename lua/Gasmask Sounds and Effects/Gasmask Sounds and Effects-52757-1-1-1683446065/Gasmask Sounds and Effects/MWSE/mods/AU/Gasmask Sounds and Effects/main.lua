local mod = { name = "Gasmask Sounds and Effects", ver = "1.0" }
local cf = require("AU.Gasmask Sounds and Effects.config")

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
Gasmasks effects
--]]

local gasMaskProtectionBlight
local gasMaskProtectionDisease
local gasMaskProtectionPoison

--create Blight Resistance effect
local function createGasMaskSpellBlight()
	gasMaskProtectionBlight = tes3.createObject({
        objectType = tes3.objectType.spell,
        id = "au_gasmask_effect_blight",
        name = "Aether Scrubber",
        castType = 1,
        effects = {
            {
                id = tes3.effect.resistBlightDisease,
                min = cf.blightMag,
                max = cf.blightMag
            }
        }
    })
end

--create Comon disease resistance effect
local function createGasMaskSpellDisease()
	gasMaskProtectionDisease = tes3.createObject({
        objectType = tes3.objectType.spell,
        id = "au_gasmask_effect_disease",
        name = "Aether Scrubber",
        castType = 1,
        effects = {
            {
                id = tes3.effect.resistCommonDisease,
                min = cf.diseaseMag,
                max = cf.diseaseMag
            }
        }
    })
end

--create  Poison resistance effect
local function createGasMaskSpellPoison()
	gasMaskProtectionPoison = tes3.createObject({
        objectType = tes3.objectType.spell,
        id = "au_gasmask_effect_poison",
        name = "Aether Scrubber",
        castType = 1,
        effects = {
            {
                id = tes3.effect.resistPoison,
                min = cf.poisonMag,
                max = cf.poisonMag
            }
        }
    })
end
event.register("loaded", createGasMaskSpellBlight)
event.register("loaded", createGasMaskSpellDisease)
event.register("loaded", createGasMaskSpellPoison)

--[[
Update gas mask effects
--]]

--update Blight Resistance effect
local function updateGasMaskSpellBlight()
    if gasMaskProtectionBlight ~= nil then
        for _, effect in ipairs(gasMaskProtectionBlight.effects) do
            -- update resistance values
            if effect.id == tes3.effect.resistBlightDisease then
                effect.min = cf.blightMag;
                effect.max = cf.blightMag;
            end
        end
    end
end

--update Common Disease Resistance effect
local function updateGasMaskSpellDisease()
    if gasMaskProtectionDisease ~= nil then
        for _, effect in ipairs(gasMaskProtectionDisease.effects) do
            -- update resistance values
           if effect.id == tes3.effect.resistCommonDisease then
                effect.min = cf.diseaseMag;
                effect.max = cf.diseaseMag;
            end
        end
    end
end

local function updateGasMaskSpellPoison()
    if gasMaskProtectionPoison ~= nil then
        for _, effect in ipairs(gasMaskProtectionPoison.effects) do
            -- update resistance values
            if effect.id == tes3.effect.resistPoison then
                effect.min = cf.poisonMag;
                effect.max = cf.poisonMag;
            end
        end
    end
end

event.register("menuExit", updateGasMaskSpellBlight)
event.register("menuExit", updateGasMaskSpellDisease)
event.register("menuExit", updateGasMaskSpellPoison)

--[[
Gasmasks add sound and effect
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
event.register("loaded", gasMaskCheck)

-- when gasmask is equipped
local function onMaskEquipped(e)
    if (e.reference ~= tes3.player or not cf.onOff) then
        return
    end

    if cf.gasmasks[e.item.id:lower()] then
        tes3.messageBox("You have equipped a gasmask.")
	-- add blight resistance
		if cf.enableBlight and (cf.blightMag > 0) then
			tes3.addSpell({
				reference = e.reference,
				spell = "au_gasmask_effect_blight",
				})
		end
	-- add common disease resistance
		if cf.enableDisease and (cf.diseaseMag > 0) then
			tes3.addSpell({
				reference = e.reference,
				spell = "au_gasmask_effect_disease",
			})
		end
	-- add poison resistance
		if cf.enablePoison and (cf.poisonMag > 0) then
			tes3.addSpell({
				reference = e.reference,
				spell = "au_gasmask_effect_poison",
			})
		end		
	-- play sound
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
	-- remove effects
		tes3.removeSpell({
			reference = e.reference,
			spell = "au_gasmask_effect_blight",
			})
		tes3.removeSpell({
			reference = e.reference,
			spell = "au_gasmask_effect_disease",
			})
		tes3.removeSpell({
			reference = e.reference,
			spell = "au_gasmask_effect_poison",
			})
	-- remove sound
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
	category2:createSlider{
		label = "Volume",
		description = "You can change gas mask breathing sound volume by moving this slider [Default: 90]",
		min = 0,
		max = 100,
		step = 1,
		jump = 1,
		variable = mwse.mcm.createTableVariable { id = "volume", table = cf },
	}

	local effectCategory = page:createCategory{
		label = "Effects",
		description = "Change the effects that full helmets add to the wearer."
		.. "\n\n"
		.. "Changing these options requires a restart for the changes to come to effect."
	}

	-- MCM resist common disease
	effectCategory:createOnOffButton{
		label = "Resist Common Disease",
		description = "Enable the Resist Common Disease effect on full helmets."
			.. "\n\n"
			.. "Default: On\n"
			.. "Changing this option requires a restart for the changes to come to effect.",
		variable = mwse.mcm.createTableVariable{
			id = "enableDisease",
			table = cf
		}
	}

	effectCategory:createSlider{
		label = "Magnitude",
		description = "Change the magnitude for the Resist Common Disease effect."
			.. "\n\n"
			.. "Default: 10\n"
			.. "Changing this option requires a restart for the changes to come to effect.",
		max = 100,
		min = 0,
		step = 1,
		jump = 5,
		variable = mwse.mcm.createTableVariable{
			id = "diseaseMag",
			table = cf
		}
	}


	-- MCM resist blight
	effectCategory:createOnOffButton{
		label = "Resist Blight Disease",
		description = "Enable the Resist Blight Disease effect on full helmets."
			.. "\n\n"
			.. "Default: On\n"
			.. "Changing this option requires a restart for the changes to come to effect.",
		variable = mwse.mcm.createTableVariable{
			id = "enableBlight",
			table = cf
		}
	}

	effectCategory:createSlider{
		label = "Magnitude",
		description = "Change the magnitude for the Resist Blight Disease effect."
			.. "\n\n"
			.. "Default: 10\n"
			.. "Changing this option requires a restart for the changes to come to effect.",
		max = 100,
		min = 0,
		step = 1,
		jump = 5,
		variable = mwse.mcm.createTableVariable{
			id = "blightMag",
			table = cf
		}
	}


	-- MCM resist posion
	effectCategory:createOnOffButton{
		label = "Resist Poison",
		description = "Enable the Resist Poison effect on full helmets."
			.. "\n\n"
			.. "Default: On\n"
			.. "Changing this option requires a restart for the changes to come to effect.",
		variable = mwse.mcm.createTableVariable{
			id = "enablePoison",
			table = cf
		}
	}

	effectCategory:createSlider{
		label = "Magnitude",
		description = "Change the magnitude for the Resist Poison effect."
			.. "\n\n"
			.. "Default: 10\n"
			.. "Changing this option requires a restart for the changes to come to effect.",
		max = 100,
		min = 0,
		step = 1,
		jump = 5,
		variable = mwse.mcm.createTableVariable{
			id = "poisonMag",
			table = cf
		}
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