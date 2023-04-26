local cwsconfig = mwse.loadConfig("Configurable Weapon Stats", 
{showmsg = true, 
	cwsactivated = true,
	globalspeed = 100,
	globalreach = 100,
	globaldmg = 100,
	shortbladespeed = 100, --0
	shortbladereach = 100,
	shortbladedmg = 100,
	longbladespeed = 100, --1
	longbladereach = 100,
	longbladedmg = 100,
	twohlongbladespeed = 100, --2
	twohlongbladereach = 100,
	twohlongbladedmg = 100,
	bluntspeed = 100, --3
	bluntreach = 100,
	bluntdmg = 100,
	twohcbluntspeed = 100, --4
	twohcbluntreach = 100,
	twohcbluntdmg = 100,
	twohwbluntspeed = 100, --5
	twohwbluntreach = 100,
	twohwbluntdmg = 100,
	spearspeed = 100, --6
	spearreach = 100,
	speardmg = 100,
	onehaxespeed = 100, --7
	onehaxereach = 100,
	onehaxedmg = 100,
	twohaxespeed = 100, --8
	twohaxereach = 100,
	twohaxedmg = 100,
	marksmanbowspeed = 100, --9
	marksmancrossbowspeed = 100, --10
	marksmanthrowspeed = 100 --11
})

local function updateweaponstats(e)
		if cwsconfig.showmsg then 
			tes3.messageBox( "Configurable Weapon Stats Initialized" )	
		end
		if cwsconfig.cwsactivated then
			for weapon in tes3.iterateObjects(tes3.objectType.weapon) do			
				-- Short Blades --
				if weapon.type == 0 then
					weapon.speed = ((weapon.speed * cwsconfig.shortbladespeed)/100)
					weapon.reach = ((weapon.reach * cwsconfig.shortbladereach)/100)
					weapon.thrustMin = ((weapon.thrustMin * cwsconfig.shortbladedmg)/100)
					weapon.thrustMax = ((weapon.thrustMax * cwsconfig.shortbladedmg)/100)
					weapon.chopMin = ((weapon.chopMin * cwsconfig.shortbladedmg)/100)
					weapon.chopMax = ((weapon.chopMax * cwsconfig.shortbladedmg)/100)
					weapon.slashMin = ((weapon.slashMin * cwsconfig.shortbladedmg)/100)
					weapon.slashMax = ((weapon.slashMax * cwsconfig.shortbladedmg)/100)
				end
				-- Longblades --
				if weapon.type == 1 then
					weapon.speed = ((weapon.speed * cwsconfig.longbladespeed)/100)
					weapon.reach = ((weapon.reach * cwsconfig.longbladereach)/100)
					weapon.thrustMin = ((weapon.thrustMin * cwsconfig.longbladedmg)/100)
					weapon.thrustMax = ((weapon.thrustMax * cwsconfig.longbladedmg)/100)
					weapon.chopMin = ((weapon.chopMin * cwsconfig.longbladedmg)/100)
					weapon.chopMax = ((weapon.chopMax * cwsconfig.longbladedmg)/100)
					weapon.slashMin = ((weapon.slashMin * cwsconfig.longbladedmg)/100)
					weapon.slashMax = ((weapon.slashMax * cwsconfig.longbladedmg)/100)
				end
				-- 2H Longblades --
				if weapon.type == 2 then
					weapon.speed = ((weapon.speed * cwsconfig.twohlongbladespeed)/100)
					weapon.reach = ((weapon.reach * cwsconfig.twohlongbladereach)/100)
					weapon.thrustMin = ((weapon.thrustMin * cwsconfig.twohlongbladedmg)/100)
					weapon.thrustMax = ((weapon.thrustMax * cwsconfig.twohlongbladedmg)/100)
					weapon.chopMin = ((weapon.chopMin * cwsconfig.twohlongbladedmg)/100)
					weapon.chopMax = ((weapon.chopMax * cwsconfig.twohlongbladedmg)/100)
					weapon.slashMin = ((weapon.slashMin * cwsconfig.twohlongbladedmg)/100)
					weapon.slashMax = ((weapon.slashMax * cwsconfig.twohlongbladedmg)/100)
				end
				-- 1H Blunts --
				if weapon.type == 3 then
					weapon.speed = ((weapon.speed * cwsconfig.bluntspeed)/100)
					weapon.reach = ((weapon.reach * cwsconfig.bluntreach)/100)
					weapon.thrustMin = ((weapon.thrustMin * cwsconfig.bluntdmg)/100)
					weapon.thrustMax = ((weapon.thrustMax * cwsconfig.bluntdmg)/100)
					weapon.chopMin = ((weapon.chopMin * cwsconfig.bluntdmg)/100)
					weapon.chopMax = ((weapon.chopMax * cwsconfig.bluntdmg)/100)
					weapon.slashMin = ((weapon.slashMin * cwsconfig.bluntdmg)/100)
					weapon.slashMax = ((weapon.slashMax * cwsconfig.bluntdmg)/100)
				end
				-- 2H Blunts --
				if weapon.type == 4 then
					weapon.speed = ((weapon.speed * cwsconfig.twohcbluntspeed)/100)
					weapon.reach = ((weapon.reach * cwsconfig.twohcbluntreach)/100)
					weapon.thrustMin = ((weapon.thrustMin * cwsconfig.twohcbluntdmg)/100)
					weapon.thrustMax = ((weapon.thrustMax * cwsconfig.twohcbluntdmg)/100)
					weapon.chopMin = ((weapon.chopMin * cwsconfig.twohcbluntdmg)/100)
					weapon.chopMax = ((weapon.chopMax * cwsconfig.twohcbluntdmg)/100)
					weapon.slashMin = ((weapon.slashMin * cwsconfig.twohcbluntdmg)/100)
					weapon.slashMax = ((weapon.slashMax * cwsconfig.twohcbluntdmg)/100)
				end
				-- 2H Staffs --
				if weapon.type == 5 then
					weapon.speed = ((weapon.speed * cwsconfig.twohwbluntspeed)/100)
					weapon.reach = ((weapon.reach * cwsconfig.twohwbluntreach)/100)
					weapon.thrustMin = ((weapon.thrustMin * cwsconfig.twohwbluntdmg)/100)
					weapon.thrustMax = ((weapon.thrustMax * cwsconfig.twohwbluntdmg)/100)
					weapon.chopMin = ((weapon.chopMin * cwsconfig.twohwbluntdmg)/100)
					weapon.chopMax = ((weapon.chopMax * cwsconfig.twohwbluntdmg)/100)
					weapon.slashMin = ((weapon.slashMin * cwsconfig.twohwbluntdmg)/100)
					weapon.slashMax = ((weapon.slashMax * cwsconfig.twohwbluntdmg)/100)
				end
				-- Spears --
				if weapon.type == 6 then
					weapon.speed = ((weapon.speed * cwsconfig.spearspeed)/100)
					weapon.reach = ((weapon.reach * cwsconfig.spearreach)/100)
					weapon.thrustMin = ((weapon.thrustMin * cwsconfig.speardmg)/100)
					weapon.thrustMax = ((weapon.thrustMax * cwsconfig.speardmg)/100)
					weapon.chopMin = ((weapon.chopMin * cwsconfig.speardmg)/100)
					weapon.chopMax = ((weapon.chopMax * cwsconfig.speardmg)/100)
					weapon.slashMin = ((weapon.slashMin * cwsconfig.speardmg)/100)
					weapon.slashMax = ((weapon.slashMax * cwsconfig.speardmg)/100)
				end
				-- 1H Axes --
				if weapon.type == 7 then
					weapon.speed = ((weapon.speed * cwsconfig.onehaxespeed)/100)
					weapon.reach = ((weapon.reach * cwsconfig.onehaxereach)/100)
					weapon.thrustMin = ((weapon.thrustMin * cwsconfig.onehaxedmg)/100)
					weapon.thrustMax = ((weapon.thrustMax * cwsconfig.onehaxedmg)/100)
					weapon.chopMin = ((weapon.chopMin * cwsconfig.onehaxedmg)/100)
					weapon.chopMax = ((weapon.chopMax * cwsconfig.onehaxedmg)/100)
					weapon.slashMin = ((weapon.slashMin * cwsconfig.onehaxedmg)/100)
					weapon.slashMax = ((weapon.slashMax * cwsconfig.onehaxedmg)/100)
				end
				-- 2H Axes --
				if weapon.type == 8 then
					weapon.speed = ((weapon.speed * cwsconfig.twohaxespeed)/100)
					weapon.reach = ((weapon.reach * cwsconfig.twohaxereach)/100)
					weapon.thrustMin = ((weapon.thrustMin * cwsconfig.twohaxedmg)/100)
					weapon.thrustMax = ((weapon.thrustMax * cwsconfig.twohaxedmg)/100)
					weapon.chopMin = ((weapon.chopMin * cwsconfig.twohaxedmg)/100)
					weapon.chopMax = ((weapon.chopMax * cwsconfig.twohaxedmg)/100)
					weapon.slashMin = ((weapon.slashMin * cwsconfig.twohaxedmg)/100)
					weapon.slashMax = ((weapon.slashMax * cwsconfig.twohaxedmg)/100)
				end
				-- Bows --
				if weapon.type == 9 then
					weapon.speed = ((weapon.speed * cwsconfig.marksmanbowspeed)/100)
				end
				-- Crossbows --
				if weapon.type == 10 then
					weapon.speed = ((weapon.speed * cwsconfig.marksmancrossbowspeed)/100)
				end
				-- Throws --
				if weapon.type == 11 then
					weapon.speed = ((weapon.speed * cwsconfig.marksmanthrowspeed)/100)
				end
				
				-- Global Modifier --
					weapon.speed = ((weapon.speed * cwsconfig.globalspeed)/100)
					weapon.reach = ((weapon.reach * cwsconfig.globalreach)/100)
					weapon.thrustMin = ((weapon.thrustMin * cwsconfig.globaldmg)/100)
					weapon.thrustMax = ((weapon.thrustMax * cwsconfig.globaldmg)/100)
					weapon.chopMin = ((weapon.chopMin * cwsconfig.globaldmg)/100)
					weapon.chopMax = ((weapon.chopMax * cwsconfig.globaldmg)/100)
					weapon.slashMin = ((weapon.slashMin * cwsconfig.globaldmg)/100)
					weapon.slashMax = ((weapon.slashMax * cwsconfig.globaldmg)/100)
			
			end
		else 
			if cwsconfig.showmsg then 
				tes3.messageBox("Configurable Weapon Stats Master Switch is OFF") 
			end
		end
				
end		
event.register("initialized", updateweaponstats)


local function registerModConfig()	
local template = mwse.mcm.createTemplate("Configurable Weapon Stats")	
template:saveOnClose("Configurable Weapon Stats", cwsconfig)	
template:register()

local var = mwse.mcm.createTableVariable	
local page = template:createPage()
page:createInfo{ text = "Master Switch" }
page:createYesNoButton{label = "Configurable Weapon Stats Activated", variable = var{id = "cwsactivated", table = cwsconfig}}
page:createInfo{ text = "ALL CHANGES TO THE SETTINGS REQUIRES GAME RESTART TO TAKE EFFECT" }
page:createInfo{ text = "Global Setting" }
page:createSlider{label = "Global speed multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id = "globalspeed", table = cwsconfig}}
page:createSlider{label = "Global range multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id = "globalreach", table = cwsconfig}}
page:createSlider{label = "Global damage multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id = "globaldmg", table = cwsconfig}}
page:createInfo{ text = "Short Blades Setting" }
page:createSlider{label = "Short Blade speed multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="shortbladespeed", table = cwsconfig}}
page:createSlider{label = "Short Blade reach multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="shortbladereach", table = cwsconfig}}
page:createSlider{label = "Short Blade damage multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="shortbladedmg", table = cwsconfig}}
page:createInfo{ text = "Long Blades Setting" }
page:createSlider{label = "Long Blade speed multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="longbladespeed", table = cwsconfig}}
page:createSlider{label = "Long Blade reach multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="longbladereach", table = cwsconfig}}
page:createSlider{label = "Long Blade damage multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="longbladedmg", table = cwsconfig}}
page:createInfo{ text = "Two-Handed Long Blades Setting" }
page:createSlider{label = "Two-Handed Long Blade speed multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="twohlongbladespeed", table = cwsconfig}}
page:createSlider{label = "Two-Handed Long Blade reach multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="twohlongbladereach", table = cwsconfig}}
page:createSlider{label = "Two-Handed Long Blade damage multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="twohlongbladedmg", table = cwsconfig}}
page:createInfo{ text = "One-Handed Blunts Setting" }
page:createSlider{label = "One-Handed Blunt speed multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="bluntspeed", table = cwsconfig}}
page:createSlider{label = "One-Handed Blunt reach multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="bluntreach", table = cwsconfig}}
page:createSlider{label = "One-Handed Blunt damage multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="bluntdmg", table = cwsconfig}}
page:createInfo{ text = "Two-Handed Blunts Setting" }
page:createSlider{label = "Two-Handed Blunt speed multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="twohcbluntspeed", table = cwsconfig}}
page:createSlider{label = "Two-Handed Blunt reach multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="twohcbluntreach", table = cwsconfig}}
page:createSlider{label = "Two-Handed Blunt damage multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="twohcbluntdmg", table = cwsconfig}}
page:createInfo{ text = "Two-Handed Wide Bluns Setting" }
page:createSlider{label = "Two-Handed Wide Blunt speed multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="twohwbluntspeed", table = cwsconfig}}
page:createSlider{label = "Two-Handed Wide Blunt reach multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="twohwbluntreach", table = cwsconfig}}
page:createSlider{label = "Two-Handed Wide Blunt damage multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="twohwbluntdmg", table = cwsconfig}}
page:createInfo{ text = "Spears Setting" }
page:createSlider{label = "Spear speed multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="spearspeed", table = cwsconfig}}
page:createSlider{label = "Spear reach multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="spearreach", table = cwsconfig}}
page:createSlider{label = "Spear damage multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="speardmg", table = cwsconfig}}
page:createInfo{ text = "One-Handed Axes Setting" }
page:createSlider{label = "One-Handed Axe speed multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="onehaxespeed", table = cwsconfig}}
page:createSlider{label = "One-Handed Axe reach multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="onehaxereach", table = cwsconfig}}
page:createSlider{label = "One-Handed Axe damage multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="onehaxedmg", table = cwsconfig}}
page:createInfo{ text = "Two-Handed Axes Setting" }
page:createSlider{label = "Two-Handed Axe speed multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="twohaxespeed", table = cwsconfig}}
page:createSlider{label = "Two-Handed Axe reach multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="twohaxereach", table = cwsconfig}}
page:createSlider{label = "Two-Handed Axe damage multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="twohaxedmg", table = cwsconfig}}
page:createInfo{ text = "Bows Setting" }
page:createSlider{label = "Bow speed multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="marksmanbowspeed", table = cwsconfig}}
page:createInfo{ text = "Crossbows Setting" }
page:createSlider{label = "Crossbow speed multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="marksmancrossbowspeed", table = cwsconfig}}
page:createInfo{ text = "Thorwing weapons Setting" }
page:createSlider{label = "Thorwing weapon speed multiplier", min = 1, max = 200, step = 1, jump = 5, variable = var{id ="marksmanthrowspeed", table = cwsconfig}}
page:createInfo{ text = "Debugging" }
page:createYesNoButton{label = "Debug Messages", variable = var{id = "showmsg", table = cwsconfig}}
end		
event.register("modConfigReady", registerModConfig)