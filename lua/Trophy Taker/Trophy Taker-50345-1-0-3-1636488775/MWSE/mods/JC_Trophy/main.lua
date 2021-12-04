local config = require ("JC_Trophy.trophies_config")

local this = {}

function this.hasKey(tab, key)
    return tab[key]~=nil
end

local function hasValue (tab, val)
    for key, value in pairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

function this.init()
    this.id_menu = tes3ui.registerID("example:MenuTakeTrophy")
    this.id_ok = tes3ui.registerID("trophy:MenuTakeTrophy_Ok")
    this.id_cancel = tes3ui.registerID("trophy:MenuTakeTrophy_Cancel")
	this.trophies = {
	}
	this.raceTrophies = {
	['Orc'] = "TT_skull_orc",
	['T_Els_Cathay'] = "TT_skull_khajiit",
	['T_Els_Suthay'] = "TT_skull_khajiit",
	['T_Els_Cathay-raht'] = "TT_skull_khajiit",
	['Khajiit'] = "TT_skull_khajiit",
	['Argonian'] = "TT_skull_argonian",
	['Redguard'] = "TT_skull_man",
	['Nord'] = "TT_skull_man",
	['Imperial'] = "TT_skull_man",
	['T_Sky_Reachman'] = "TT_skull_man",
	['Breton'] = "TT_skull_man",
	['High Elf'] = "TT_skull_mer",
	['T_Pya_SeaElf'] = "TT_skull_mer",
	['Wood Elf'] = "TT_skull_mer",
	['Dark Elf'] = "TT_skull_mer",
	['T_Els_Ohmes-raht'] = "TT_skull_mer",
	['T_Els_Ohmes'] = "TT_skull_mer",
	}
	this.humanTrophies = {
	[1] = "TT_eye",
	[2] = "TT_brain",
	}

	
	
	print("[Trophy Taker: INFO] Trophy Taker Initialized")
	
	
	
end

event.register("uiObjectTooltip", function(e)
    local name = e.itemData and e.itemData.data.trophyName
    local label = e.tooltip:findChild("HelpMenu_name")
    if label and name then
        label.text = name
    end
end)


function this.addItemAsName(item, name)


	local item = tes3.getObject(item)

	tes3.addItem{
		reference = tes3.player,
		item = item,
		count = 1,
	}
	
	local itemData = tes3.addItemData{
		to = tes3.player,
		item = item,
		updateGUI = true
	}
	itemData.data.trophyName = name
	
	return

end

function this.createWindow()
	-- Return if window is already open
    if (tes3ui.findMenu(this.id_menu) ~= nil) then
        return
    end
	
	local menu = tes3ui.createMenu{ id = this.id_menu, fixedFrame = true }

	menu.autoWidth = true
	
	menu.alpha = 0.7
	
	local input_label = menu:createLabel{ id = tes3ui.registerID("TrophyLabel"), text = "Take trophy" }
	input_label.borderBottom = 5
	
	local trophies_block = menu:createThinBorder{ id = tes3ui.registerID("TrophyBlock"), }
    trophies_block.width = 300
    trophies_block.height = 96
    trophies_block.childAlignX = 0.0
    trophies_block.childAlignY = 0.0	
	
	local button_block = menu:createBlock{ id = tes3ui.registerID("TrophyButtons"), }
    button_block.widthProportional = 1.0  -- width is 100% parent width
    button_block.autoHeight = true
    button_block.childAlignX = 1.0  -- right content alignment
	
	local button_cancel = button_block:createButton{ id = this.id_cancel, text = tes3.findGMST("sCancel").value }
	local ref = nil
    local t = tes3.getPlayerTarget()
    if (t) then
		ref = t
        t = t.object.baseObject or t.object -- Select actor base object

        if (t.name) then
            this.item = t
		end
    end
	
	if (this.item.objectType == tes3.objectType.npc and tes3.getPlayerTarget().isDead and (not hasValue(ref.tempData, "trophyTaken") or not config.trophyLimit)) then
		for object, trophy in pairs(this.humanTrophies) do
				local trophy_image = trophies_block:createImage{ id = tes3ui.registerID(object..trophy), path =  "icons\\" .. tes3.getObject(trophy).icon }
				trophy_image.width = 32
				trophy_image.borderAllSides = 8
				trophy_image:register("mouseClick", function() this.addItemAsName(trophy,(this.item.name .. '\'s ' .. tes3.getObject(trophy).name))
				trophy_image:destroy()
				table.insert(ref.tempData,"trophyTaken")
				tes3ui.leaveMenuMode()
				menu:destroy()
				return
				end)
		end
		local trophy_skull = trophies_block:createImage{ id = tes3ui.registerID(TrophySkull), path =  "icons\\" .. tes3.getObject(this.raceTrophies[this.item.race.id]).icon }
		trophy_skull.width = 32
		trophy_skull.borderAllSides = 8
		trophy_skull:register("mouseClick", function() this.addItemAsName(this.raceTrophies[this.item.race.id],(this.item.name .. '\'s ' .. tes3.getObject(this.raceTrophies[this.item.race.id]).name))
		trophy_skull:destroy()
		table.insert(ref.tempData,"trophyTaken")
		tes3ui.leaveMenuMode()
		menu:destroy()
		return
		end)
	elseif (this.item.objectType == tes3.objectType.creature and tes3.getPlayerTarget().isDead and (not hasValue(ref.tempData, "trophyTaken") or not config.trophyLimit)) then
		for _, name in ipairs(config.humanCreaturesName) do
			if (string.match(this.item.name:lower(), name) or string.match(this.item.mesh:lower(), name) or string.match(this.item.id:lower(), name)) then
				local human_skull = trophies_block:createImage{ id = tes3ui.registerID(TrophySkull), path =  "icons\\" .. tes3.getObject("misc_skull00").icon }
				human_skull.width = 32
				human_skull.borderAllSides = 8
				human_skull:register("mouseClick", function() this.addItemAsName("misc_skull00",(this.item.name .. '\'s ' .. tes3.getObject("misc_skull00").name))
				human_skull:destroy()
				table.insert(ref.tempData,"trophyTaken")
				tes3ui.leaveMenuMode()
				menu:destroy()	
				return
				end)
			break
			end
		end
		for name, value in pairs(config.nameLinks) do
			if (string.match(this.item.mesh:lower(), name) or string.match(this.item.name:lower(), name) or string.match(this.item.id:lower(), name)) then
				--if( tes3.getObject(creaturetrophy)) then
					for _, creaturetrophy in ipairs(config.creatureTrophies[value]) do
						local trophy_item = trophies_block:createImage{ id = tes3ui.registerID(creaturetrophy), path =  "icons\\" .. tes3.getObject(creaturetrophy).icon }
						trophy_item.width = 32
						trophy_item.borderAllSides = 8
						trophy_item:register("mouseClick", function() this.addItemAsName(creaturetrophy,(this.item.name .. '\'s ' .. tes3.getObject(creaturetrophy).name))
						trophy_item:destroy()
						table.insert(ref.tempData,"trophyTaken")
						tes3ui.leaveMenuMode()
						menu:destroy()	
						return
						end)
					end
				--end
			break
			end
		end
	end
	
	button_cancel:register("mouseClick", this.onCancel)
	menu:updateLayout()
	tes3ui.enterMenuMode(this.id_menu)
	

end

-- Cancel button callback.
function this.onCancel(e)
    local menu = tes3ui.findMenu(this.id_menu)

    if (menu) then
        tes3ui.leaveMenuMode()
        menu:destroy()
    end
end

function this.onCommand(e)
    local t = tes3.getPlayerTarget()
    if (t) then
		local ref = t
        t = t.object.baseObject or t.object -- Select actor base object
		
		
        if (t.name) and (t.objectType == tes3.objectType.npc or t.objectType == tes3.objectType.creature) and ref.isDead and (not hasValue(ref.tempData, "trophyTaken") or not config.trophyLimit) then
            this.item = t
            this.createWindow()
        end
    end
end

function this.onSelect(e)
	tes3.additem{
		reference = tes3.player,
		
	}
end



event.register("initialized", this.init) --3.
event.register("key", this.onCommand, {filter = tes3.scanCode.n})



