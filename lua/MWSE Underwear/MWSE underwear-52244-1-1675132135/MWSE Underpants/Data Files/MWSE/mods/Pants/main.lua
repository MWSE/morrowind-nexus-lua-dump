local function distributePants(e)
	if e.reference.object.objectType ~= tes3.objectType.npc then 
		return
	end
	
	tes3.player.data.pants = tes3.player.data.pants or {}
	tes3.player.data.pants.distributed = tes3.player.data.pants.distributed or {}
	
	e.reference.data.pants = e.reference.data.pants or {}
	e.reference.data.pants.distributed = e.reference.data.pants.distributed or {}
	
	local distributed = e.reference.data.pants.distributed
	local race = e.reference.object.race.id
	local ref = e.reference
	local armor = ref.object.equipment
	
	if ( distributed ~= true ) then
	
			-- Do not give beasts underpants
		if ( race == "Argonian" ) then
			e.reference.data.pants.distributed = true
			return
		end
		
		if ( race == "Khajiit") then
			e.reference.data.pants.distributed = true
			return
		end
		
			-- Do not give naked people underpants
		if ( #armor < 1 ) then
			e.reference.data.pants.distributed = true
			return
		end
		
		if ( ref.object.female ) then
			tes3.addItem({reference=ref, item="lak_e_bra", count=1})
			tes3.addItem({reference=ref, item="lak_e_panties", count=1})
		else
			tes3.addItem({reference=ref, item="lak_e_underpants", count=1})
		end
		e.reference.data.pants.distributed = true
	end
	
end

local function initialized()

	print("[MWSE Underpants: INFO] MWSE Underpants Initialized")
	event.register(tes3.event.mobileActivated, distributePants)
	
end

event.register(tes3.event.initialized, initialized)