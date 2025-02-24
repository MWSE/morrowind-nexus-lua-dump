-- glass 50
-- ebony 60
-- dwarven 30 (it is worse in the game but let's make it better so it has a reason to exist)
-- daedric 80
-- dreugh 45 (actual value: 40, should match indoril since there is no indoril material)
-- royal guard 55 (adamantium)
-- stalhrim 50

-- HPs
-- Daedric = 2400
-- Adamant = 900
-- Ebony = 1800
-- glass = 1500

-- Health ratios for slots: helm/cuirass 100%, pauldrons legs half, gloves 1/4. In vanilla this is not consistent but it is roughly around these values

--fetch config file
local confPath = "tempering_config"
local configDefault = {
	disableCap = false,
	ingredReq = 10,
	allowSoulGems = false
}

local daedricTier = { "ingred_cursed_daedras_heart_01", "ingred_Dae_cursed_diamond_01", "ingred_Dae_cursed_emerald_01", "ingred_Dae_cursed_pearl_01", "ingred_Dae_cursed_raw_ebony_01", "ingred_Dae_cursed_ruby_01" }
local adamantTier = { "ingred_adamantium_ore_01", "ingred_raw_Stalhrim_01", "mc_adamantium_ingot" } -- I will combine Stalhrim and Adamantium into one tier because the difference is small and they are both exceptionally rare
local ebonyTier = { "ingred_raw_ebony_01", "mc_ebony_ingot" }
local glassTier = { "ingred_raw_glass_01", "mc_glass_ingot" }
local scrapTier = { "ingred_scrap_metal_01", "ingred_bear_pelt", "ingred_boar_leather", "ingred_wolf_pelt", "ingred_guar_hide_01", "ingred_netch_leather_01", "ingred_kagouti_hide_01", "mc_iron_ore", "mc_silver_ore", "mc_scrap_dwemer", "mc_iron_ingot", "mc_dwemer_ingot", "mc_scrap_iron", "mc_scrap_orcish" }
local indorilTier = { "ingred_dreugh_wax_01", "mc_orichalcum_ingot", "mc_silver_ingot" }

local config = mwse.loadConfig(confPath, configDefault)

if not config then
    config = { blocked = {} }
end

local function contains(arr, x)
	for _, v in pairs(arr) do
		if v == x then return true end
	end
	return false
end

local function isReusableSoulgem(soulItem) 
	if soulItem.item and ( soulItem.item.id:lower() == "misc_soulgem_azura" or soulItem.item.id:lower() == "nc_soulgem_azurab" ) then -- Azura star and necrocraft black star
		return soulItem.item.id
	else
		return false
	end
end

local function validSoul(soulItem)

	if config.allowSoulGems then
		if soulItem.itemData and soulItem.itemData.soul and soulItem.itemData.soul.soul >= 400 then
			return true
		end
	end
	
	return false

end

local function validIngred(i)

	if contains(daedricTier, i) or contains(adamantTier, i) or contains(ebonyTier, i)
	or contains(glassTier, i) or contains(scrapTier, i) or contains(indorilTier, i) then
		return true
	else
		return false
	end

end

local function getArmorHealth(tier, item)

	local newHealth
	
	if tier >= 80 then
		newHealth = 2400
	elseif tier >= 60 then
		newHealth = 1800
	elseif tier >= 50 then
		newHealth = 1500
	else
		newHealth = 900
	end
	
	if item.object.slot >= 2 and item.object.slot <= 5 then
		newHealth = newHealth * .5 -- Pauldrons, legs, boots roughly 1/2 cuirass value
	elseif item.object.slot == 6 or item.object.slot == 7 or item.object.slot == 9 or item.object.slot == 10 then
		newHealth = newHealth * .25 -- Gloves, bracers roughly 1/4 cuirass value
	end -- cuirass, helm, shield can stay at cuirass HP
	
	return newHealth
	
end

local function temperArmor(iRef)

	local prefix
	local temperQuality

	 tes3ui.showInventorySelectMenu({
        reference = tes3.player,
        title = "Choose a material to temper the " .. iRef.object.name,
		noResultsText = "You have no valid materials to work with.",
        callback = function(e)
            if e.item then
				local toTake
				if contains(daedricTier, e.item.id) or validSoul(e) then
					temperQuality = 80
					toTake = 1
				elseif contains(adamantTier, e.item.id) then
					temperQuality = 55
					toTake = 1
				elseif ( e.count < config.ingredReq ) then
					tes3.messageBox("You need at least %s materials to temper.", config.ingredReq) 
					return
				elseif contains(ebonyTier, e.item.id) then
					temperQuality = 60
					toTake = config.ingredReq
				elseif contains(glassTier, e.item.id) then
					temperQuality = 50
					toTake = config.ingredReq
				elseif contains(scrapTier, e.item.id) then
					temperQuality = 30
					toTake = config.ingredReq
				elseif contains(indorilTier, e.item.id) then
					temperQuality = 45
					toTake = config.ingredReq
				else
					tes3.messageBox("You cannot temper armor with this material.")
					return
				end
				
				local playerSkill = tes3.mobilePlayer.armorer.current * .01
				
				if playerSkill >= 1 then
					playerSkill = 1
				end
				
				local old = iRef.object.armorRating
				local impVal = ( temperQuality - old ) * playerSkill
				local newRating = old + impVal
				
				local newHP = getArmorHealth(temperQuality, iRef)
				
				local hpImpVal = ( newHP - iRef.object.maxCondition ) * playerSkill
				
				newHP = iRef.object.maxCondition + hpImpVal
				
				if not config.disableCap then
					if iRef.object.weightClass == 0 and newRating > 50 then
						newRating = 50 -- cap light at glass tier
					elseif iRef.object.weightClass == 1 and newRating > 55 then
						newRating = 55 -- cap medium at royal guard tier
					end 
				end
				if newRating <= old or impVal < 1 then 
					tes3.messageBox("You cannot improve the item further with this material.")
					return
				end
				
				if isReusableSoulgem(e) then -- if we are taking a reusable soulgem give a new one
					tes3.addItem( { reference = tes3.player, item = isReusableSoulgem(e), count = 1, playSound = false, } )				
				end
				
                tes3.removeItem({
                    reference = tes3.mobilePlayer,
                    item = e.item,
                    itemData = e.itemData,
                    count = toTake,
					playSound = false,
                })
				
			
				local newName = iRef.object.name

				--newName = string.sub(newName, 0, 30) -- cutoff end of name if needed
				--newName = cleanOldName(test)
					
				local newItem = iRef.object:createCopy({

				})
				
				newItem.name = newName
				newItem.armorRating = newRating
				
				if ( newHP > iRef.object.maxCondition ) then
					newItem.maxCondition = newHP
				end
				
				tes3.addItem( { reference = tes3.player, item = newItem, count = 1, playSound = false, } )
				tes3.playSound({ sound = "Repair", reference = tes3.mobilePlayer, })
				tes3.messageBox("You have improved an item! Previous AR: %s New AR: %s ", old, newItem.armorRating)
				
				tes3.mobilePlayer:exerciseSkill(1, 2)
				
				iRef:delete()

            end
        end,

        filter = function(e2)
		
			if e2.item and ( validIngred(e2.item.id) or validSoul(e2)) then
				return true
			else
				return false
			end
		end--tes3.inventorySelectFilter.ingredients
    })
end

local function fortify(e)
	
	if not e.isAltDown then
		return
	end
	
	local item
	
	local rayhit = tes3.rayTest {position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = {tes3.player}};

	if rayhit and rayhit.reference then	
		if rayhit.reference.object.objectType == tes3.objectType.armor then
			item = rayhit.reference
		end
		
        local itemdata = item.attachments.variables
        if (itemdata and itemdata.owner) then
            local owner = itemdata.owner
            if (owner.objectType == tes3.objectType.faction and owner.playerJoined and owner.playerRank >= itemdata.requirement) then
                -- Player has sufficient faction rank.
            else
                tes3.messageBox{ message = "You do not own that item." }
                return
            end
        end
		
		temperArmor(item)
	end
	-- elseif rayhit and rayhit.reference then
		-- if rayhit.reference.object.objectType == tes3.objectType.weapon then
			-- item = rayhit.reference.object
		-- end
		-- temperWeapon(item)
	-- else
		-- return
	-- end

end

local function initialized()

	event.register(tes3.event.keyDown, fortify, { filter = tes3.scanCode.n } )
	
	print("[MWSE Tempering] Tempering Initialized")
end

event.register(tes3.event.initialized, initialized)


local function registerModConfig()
    --get EasyMCM
    local EasyMCM = require("easyMCM.EasyMCM")
    --create template
    local template = EasyMCM.createTemplate("Tempering")
    --Have our config file save when MCM is closed
    template:saveOnClose(confPath, config)
    --Make a page
    local page = template:createSideBarPage{
        sidebarComponents = {
            EasyMCM.createInfo{ text = "Tempering\n\nby AlandroSul\n\nControls:\nPlace an item in a work place\nHit alt n with the item in your crosshairs to target it\n\nValid tempering materials:\nRaw Ebony\nAdamantium Ore\nRaw Glass\nRaw Stalhrim\nScrap Metal\nCursed Daedric items\nLeathers and Pelts"
				.. "\nIngots, ores and scrap from Morrowind Crafting"},
        }
    }
    --Make a category inside our page
    local category = page:createCategory("Settings")

    --Make some settings
    category:createButton({
	
        buttonText = "Disable/Enable AR Type Cap",
        description = "Disable cap based on armor type. If this setting is true, you will be able to improve light armor to daedric tier quality, for example (not balanced). Disabled (default), light armor will be capped at glass tier quality.",
        callback = function(self)
            config.disableCap = not config.disableCap
			tes3.messageBox("Armor Type AR Cap Disabled: %s", config.disableCap)
        end
    })
	
    category:createButton({
	
        buttonText = "Disable/Enable Grand Soulgems for Daedric",
        description = "Enable this to use Grand Souls (400+ Golden Saint tier) to make Daedric-tier items. Sort of OP, since there is no limit on how many of these souls you can obtain",
        callback = function(self)
            config.allowSoulGems = not config.allowSoulGems
			tes3.messageBox("Soulgem use allowed: %s", config.allowSoulGems)
        end
    })
	
	category:createSlider {
    label = "Ingredients Required",
    description = "Ingredients required to temper with common materials such as scrap metal, raw glass, or raw ebony. Does not affect daedric/adamantium/stalhrim items, which only require 1 due to their rarity. 10 by default.",
    max = 100,
    min = 1,
    step = 1,
    jump = 1,
    variable = mwse.mcm:createTableVariable {
        id = "ingredReq",
        table = config
    }
}


    --Register our MCM
    EasyMCM.register(template)
end

--register our mod when mcm is ready for it
event.register("modConfigReady", registerModConfig)