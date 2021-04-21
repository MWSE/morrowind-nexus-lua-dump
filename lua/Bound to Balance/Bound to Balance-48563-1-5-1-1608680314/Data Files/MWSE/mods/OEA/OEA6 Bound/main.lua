local configPath = "Bound_to_Balance"
local defaultConfig = {
	Govern =
		true,
	Mult =
		10,
	Friend =
		false
	}
local config = mwse.loadConfig(configPath, defaultConfig)

local function Readied(e)
	local skill
	local State

	if (e.reference.mobile.readiedWeapon == nil) then
		return
	end

	if (e.reference.baseObject.objectType == tes3.objectType.creature) and (config.Govern == true) then
		skill = e.reference.baseObject.skills[2]
		State = 1
	end

	if (config.Govern == true) and ((State == nil) or (State == 0)) then
		if (e.reference.mobile.conjuration ~= nil) then
			skill = e.reference.mobile.conjuration.current
		end
	elseif (config.Govern == false) and ((State == nil) or (State == 0)) then
		if (e.reference.mobile.willpower ~= nil) then
			skill = e.reference.mobile.willpower.current
		end
	end

	if (config.Friend == true) then
		for friend in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
			if (friend.reference.id == e.reference.baseObject.id) then
				if (config.Govern == true) then
					skill = tes3.mobilePlayer.conjuration.current
				elseif (config.Govern == false) then
					skill = tes3.mobilePlayer.willpower.current
				end
				break
			end
		end
	end

	if (skill == nil) then
		skill = 100
	end

	local w = e.reference.mobile.readiedWeapon.object

	if (w.id == "bound_battle_axe") then
		w.chopMin = math.ceil(1 * (skill / 100) * (config.Mult / 10))
		w.chopMax = math.ceil(80 * (skill / 100) * (config.Mult / 10))
		w.slashMin = math.ceil(1 * (skill / 100) * (config.Mult / 10))	
		w.slashMax = math.ceil(60 * (skill / 100) * (config.Mult / 10))	
		w.thrustMin = math.ceil(1 * (skill / 100) * (config.Mult / 10))
		w.thrustMax = math.ceil(8 * (skill / 100) * (config.Mult / 10))
	end
	if (w.id == "bound_dagger") then
		w.chopMin = math.ceil(9 * (skill / 100) * (config.Mult / 10))
		w.chopMax = math.ceil(20 * (skill / 100) * (config.Mult / 10))
		w.slashMin = math.ceil(9 * (skill / 100) * (config.Mult / 10))	
		w.slashMax = math.ceil(20 * (skill / 100) * (config.Mult / 10))	
		w.thrustMin = math.ceil(10 * (skill / 100) * (config.Mult / 10))
		w.thrustMax = math.ceil(20 * (skill / 100) * (config.Mult / 10))
	end
	if (w.id == "bound_longbow") then
		w.chopMin = math.ceil(2 * (skill / 100) * (config.Mult / 10))
		w.chopMax = math.ceil(50 * (skill / 100) * (config.Mult / 10))
	end
	if (w.id == "bound_longsword") then
		w.chopMin = math.ceil(2 * (skill / 100) * (config.Mult / 10))
		w.chopMax = math.ceil(32 * (skill / 100) * (config.Mult / 10))
		w.slashMin = math.ceil(1 * (skill / 100) * (config.Mult / 10))	
		w.slashMax = math.ceil(44 * (skill / 100) * (config.Mult / 10))	
		w.thrustMin = math.ceil(4 * (skill / 100) * (config.Mult / 10))
		w.thrustMax = math.ceil(40 * (skill / 100) * (config.Mult / 10))
	end
	if (w.id == "bound_mace") then
		w.chopMin = math.ceil(5 * (skill / 100) * (config.Mult / 10))
		w.chopMax = math.ceil(30 * (skill / 100) * (config.Mult / 10))
		w.slashMin = math.ceil(5 * (skill / 100) * (config.Mult / 10))	
		w.slashMax = math.ceil(30 * (skill / 100) * (config.Mult / 10))	
		w.thrustMin = math.ceil(1 * (skill / 100) * (config.Mult / 10))
		w.thrustMax = math.ceil(4 * (skill / 100) * (config.Mult / 10))
	end
	if (w.id == "bound_spear") then
		w.chopMin = math.ceil(2 * (skill / 100) * (config.Mult / 10))
		w.chopMax = math.ceil(9 * (skill / 100) * (config.Mult / 10))
		w.slashMin = math.ceil(2 * (skill / 100) * (config.Mult / 10))	
		w.slashMax = math.ceil(9 * (skill / 100) * (config.Mult / 10))	
		w.thrustMin = math.ceil(6 * (skill / 100) * (config.Mult / 10))
		w.thrustMax = math.ceil(40 * (skill / 100) * (config.Mult / 10))
	end
	if (w.id == "OJ_ME_BoundClaymore") then
		w.chopMin = math.ceil(1 * (skill / 100) * (config.Mult / 10))
		w.chopMax = math.ceil(60 * (skill / 100) * (config.Mult / 10))
		w.slashMin = math.ceil(1 * (skill / 100) * (config.Mult / 10))	
		w.slashMax = math.ceil(52 * (skill / 100) * (config.Mult / 10))	
		w.thrustMin = math.ceil(1 * (skill / 100) * (config.Mult / 10))
		w.thrustMax = math.ceil(36 * (skill / 100) * (config.Mult / 10))
	end
	if (w.id == "OJ_ME_BoundClub") then
		w.chopMin = math.ceil(10 * (skill / 100) * (config.Mult / 10))
		w.chopMax = math.ceil(12 * (skill / 100) * (config.Mult / 10))
		w.slashMin = math.ceil(4 * (skill / 100) * (config.Mult / 10))	
		w.slashMax = math.ceil(8 * (skill / 100) * (config.Mult / 10))	
		w.thrustMin = math.ceil(4 * (skill / 100) * (config.Mult / 10))
		w.thrustMax = math.ceil(8 * (skill / 100) * (config.Mult / 10))
	end
	if (w.id == "OJ_ME_BoundDaiKatana") then
		w.chopMin = math.ceil(1 * (skill / 100) * (config.Mult / 10))
		w.chopMax = math.ceil(60 * (skill / 100) * (config.Mult / 10))
		w.slashMin = math.ceil(1 * (skill / 100) * (config.Mult / 10))	
		w.slashMax = math.ceil(52 * (skill / 100) * (config.Mult / 10))	
		w.thrustMin = math.ceil(1 * (skill / 100) * (config.Mult / 10))
		w.thrustMax = math.ceil(30 * (skill / 100) * (config.Mult / 10))
	end
	if (w.id == "OJ_ME_BoundKatana") then
		w.chopMin = math.ceil(3 * (skill / 100) * (config.Mult / 10))
		w.chopMax = math.ceil(44 * (skill / 100) * (config.Mult / 10))
		w.slashMin = math.ceil(1 * (skill / 100) * (config.Mult / 10))	
		w.slashMax = math.ceil(40 * (skill / 100) * (config.Mult / 10))	
		w.thrustMin = math.ceil(1 * (skill / 100) * (config.Mult / 10))
		w.thrustMax = math.ceil(14 * (skill / 100) * (config.Mult / 10))
	end
	if (w.id == "OJ_ME_BoundShortsword") then
		w.chopMin = math.ceil(10 * (skill / 100) * (config.Mult / 10))
		w.chopMax = math.ceil(26 * (skill / 100) * (config.Mult / 10))
		w.slashMin = math.ceil(10 * (skill / 100) * (config.Mult / 10))	
		w.slashMax = math.ceil(26 * (skill / 100) * (config.Mult / 10))	
		w.thrustMin = math.ceil(12 * (skill / 100) * (config.Mult / 10))
		w.thrustMax = math.ceil(24 * (skill / 100) * (config.Mult / 10))
	end
	if (w.id == "OJ_ME_BoundStaff") then
		w.chopMin = math.ceil(2 * (skill / 100) * (config.Mult / 10))
		w.chopMax = math.ceil(16 * (skill / 100) * (config.Mult / 10))
		w.slashMin = math.ceil(3 * (skill / 100) * (config.Mult / 10))	
		w.slashMax = math.ceil(16 * (skill / 100) * (config.Mult / 10))	
		w.thrustMin = math.ceil(1 * (skill / 100) * (config.Mult / 10))
		w.thrustMax = math.ceil(12 * (skill / 100) * (config.Mult / 10))
	end
	if (w.id == "OJ_ME_BoundTanto") then
		w.chopMin = math.ceil(9 * (skill / 100) * (config.Mult / 10))
		w.chopMax = math.ceil(20 * (skill / 100) * (config.Mult / 10))
		w.slashMin = math.ceil(9 * (skill / 100) * (config.Mult / 10))	
		w.slashMax = math.ceil(20 * (skill / 100) * (config.Mult / 10))	
		w.thrustMin = math.ceil(9 * (skill / 100) * (config.Mult / 10))
		w.thrustMax = math.ceil(20 * (skill / 100) * (config.Mult / 10))
	end
	if (w.id == "OJ_ME_BoundWakizashi") then
		w.chopMin = math.ceil(10 * (skill / 100) * (config.Mult / 10))
		w.chopMax = math.ceil(30 * (skill / 100) * (config.Mult / 10))
		w.slashMin = math.ceil(10 * (skill / 100) * (config.Mult / 10))	
		w.slashMax = math.ceil(25 * (skill / 100) * (config.Mult / 10))	
		w.thrustMin = math.ceil(7 * (skill / 100) * (config.Mult / 10))
		w.thrustMax = math.ceil(11 * (skill / 100) * (config.Mult / 10))
	end
	if (w.id == "OJ_ME_BoundWarAxe") then
		w.chopMin = math.ceil(1 * (skill / 100) * (config.Mult / 10))
		w.chopMax = math.ceil(44 * (skill / 100) * (config.Mult / 10))
		w.slashMin = math.ceil(1 * (skill / 100) * (config.Mult / 10))	
		w.slashMax = math.ceil(24 * (skill / 100) * (config.Mult / 10))	
		w.thrustMin = math.ceil(1 * (skill / 100) * (config.Mult / 10))
		w.thrustMax = math.ceil(6 * (skill / 100) * (config.Mult / 10))
	end
	if (w.id == "OJ_ME_BoundWarhammer") then
		w.chopMin = math.ceil(1 * (skill / 100) * (config.Mult / 10))
		w.chopMax = math.ceil(70 * (skill / 100) * (config.Mult / 10))
		w.slashMin = math.ceil(1 * (skill / 100) * (config.Mult / 10))	
		w.slashMax = math.ceil(60 * (skill / 100) * (config.Mult / 10))	
		w.thrustMin = math.ceil(1 * (skill / 100) * (config.Mult / 10))
		w.thrustMax = math.ceil(4 * (skill / 100) * (config.Mult / 10))
	end
	
	State = 0
end

local function EquipAmmo(e)
	local Skill
	local State

	if (e.item.objectType ~= tes3.objectType.ammunition) then
		return
	end

	if (e.reference.baseObject.objectType == tes3.objectType.creature) and (config.Govern == true) then
		skill = e.reference.baseObject.skills[2]
		State = 1
	end

	if (config.Govern == true) and ((State == nil) or (State == 0)) then
		if (e.reference.mobile.conjuration ~= nil) then
			skill = e.reference.mobile.conjuration.current
		end
	elseif (config.Govern == false) and ((State == nil) or (State == 0)) then
		if (e.reference.mobile.willpower ~= nil) then
			skill = e.reference.mobile.willpower.current
		end
	end

	if (config.Friend == true) then
		for friend in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
			if (friend.reference.id == e.reference.baseObject.id) then
				if (config.Govern == true) then
					skill = tes3.mobilePlayer.conjuration.current
				elseif (config.Govern == false) then
					skill = tes3.mobilePlayer.willpower.current
				end
				break
			end
		end
	end

	if (skill == nil) then
		skill = 100
	end

	if (e.item.id == "merz_bound_arrow") then
		e.item.chopMin = math.ceil(10 * (skill / 100) * (config.Mult / 10))
		e.item.chopMax = math.ceil(15 * (skill / 100) * (config.Mult / 10))
	end

	State = 0
end

local function ArmorCalc(e)
	local skill
	local State

	if (e.reference == nil) then
		return
	end

	if (e.mobile == nil) then
		return
	end

	if (e.reference.baseObject.objectType == tes3.objectType.creature) and (config.Govern == true) then
		skill = e.reference.baseObject.skills[2]
		State = 1
	end

	if (config.Govern == true) and ((State == nil) or (State == 0)) then
		if (e.reference.mobile.conjuration ~= nil) then
			skill = e.reference.mobile.conjuration.current
		end
	elseif (config.Govern == false) and ((State == nil) or (State == 0)) then
		if (e.reference.mobile.willpower ~= nil) then
			skill = e.reference.mobile.willpower.current
		end
	end

	if (config.Friend == true) then
		for friend in tes3.iterate(tes3.mobilePlayer.friendlyActors) do
			if (friend.reference.id == e.reference.baseObject.id) then
				if (config.Govern == true) then
					skill = tes3.mobilePlayer.conjuration.current
				elseif (config.Govern == false) then
					skill = tes3.mobilePlayer.willpower.current
				end
				break
			end
		end
	end

	if (skill == nil) then
		skill = 100
	end

	if (e.armor.id == "bound_helm") then
		e.armorRating = math.ceil(75 * (skill / 100) * (config.Mult / 10))
	end
	if (e.armor.id ~= "bound_helm") then
		if (string.sub (e.armor.id, 1, 6) == "bound_") or (string.sub (e.armor.id, 1, 11) == "OJ_ME_Bound") then
			e.armorRating = math.ceil(80 * (skill / 100) * (config.Mult / 10))
		end
	end
	e.block = true

	State = 0
end

event.register("weaponReadied", Readied)
event.register("calcArmorRating", ArmorCalc)
event.register("equip", EquipAmmo)

----MCM
local function registerModConfig()

    local template = mwse.mcm.createTemplate({ name = "Bound To Balance" })
    template:saveOnClose(configPath, config)

    local page = template:createPage()
    page.noScroll = true
    page.indent = 0
    page.postCreate = function(self)
        self.elements.innerContainer.paddingAllSides = 10
   end

 
    local influence = page:createYesNoButton{
        label = "Should values be based on percentage of Conjuration (yes) or Willpower (no)?",
        variable = mwse.mcm:createTableVariable{
            id = "Govern",
            table = config
        }
    }

   local banner = page:createSlider{
        label = "All values are multiplied by this number divided by ten",
        variable = mwse.mcm:createTableVariable{
            id = "Mult",
            table = config
        },
	min = 1,
	max = 50,
	step = 1,
	jump = 10
    }

    local influence = page:createYesNoButton{
        label = "Have player companions use player stats?",
        variable = mwse.mcm:createTableVariable{
            id = "Friend",
            table = config
        }
    }

    mwse.mcm.register(template)
end

event.register("modConfigReady", registerModConfig)