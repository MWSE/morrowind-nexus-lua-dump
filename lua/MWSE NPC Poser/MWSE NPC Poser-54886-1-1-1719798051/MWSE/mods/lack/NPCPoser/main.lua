local confPath = "lack_NPCPoser_config"
local configDefault = {
	hotkey = tes3.scanCode.u,
}

local config = mwse.loadConfig(confPath, configDefault)

local nifs = {
"VA_sitting.nif",
"anim_aliballet.nif",
"anim_aliroman.nif",
"anim_Aliroman2.NIF",
"anim_alitecno.nif",
"anim_ballerina.nif",
"anim_ballet.nif",
"anim_blueballet2.nif",
"anim_bodybuilding.nif",
"anim_breakdance.nif",
"anim_cradledance.nif",
"anim_dance.nif",
"anim_dance2.nif",
"anim_dancemovemusic.nif",
"anim_dancetechno.nif",
"anim_dancetechnoshort.nif",
"anim_dancingboylong.nif",
"anim_diveroll.nif",
"anim_drinkshotatbar.nif",
"anim_DrinkShotAtBar2.NIF",
"anim_drunk0x2.nif",
"anim_drunk0x4.nif",
"anim_drunk0xX.nif",
"anim_dynamicdance.nif",
"anim_dynamic_1.nif",
"anim_dynamic_2.nif",
"anim_dynamic_3.nif",
"anim_f_sleeping.nif",
"anim_gestureset_01.nif",
"anim_gestureset_02.nif",
"anim_gestureset_03.nif",
"anim_gestureset_04.nif",
"anim_gestureset_05.nif",
"anim_gestureset_06.nif",
"anim_gestureset_07.nif",
"anim_gestureset_08.nif",
"anim_gestureset_09.nif",
"anim_gestureset_10.nif",
"anim_gestureset_11.nif",
"anim_gestureset_12.nif",
"anim_girlsitdrinktea.nif",
"anim_hopping_01.nif",
"anim_horizondance.nif",
"anim_hugkiss_female.nif",
"anim_hugkiss_female2x.nif",
"anim_hugkiss_female_01.nif",
"anim_hugkiss_female_01a.nif",
"anim_hugkiss_female_02.nif",
"anim_hugkiss_female_02a.nif",
"anim_hugkiss_female_02x.nif",
"anim_hugkiss_male.nif",
"anim_hugkiss_male_01.nif",
"anim_hugkiss_male_01a.nif",
"anim_hugkiss_male_02.nif",
"anim_hugkiss_male_02a.nif",
"anim_indiandance.nif",
"anim_johnny.nif",
"anim_johnny1.nif",
"anim_johnny4.nif",
"anim_jumpdance.nif",
"anim_karate.nif",
"anim_kickdance.nif",
"anim_lydownside_f_Br.nif",
"anim_lydownside_male_Br.nif",
"anim_lydown_female_02a.nif",
"anim_lydown_female_02c.nif",
"anim_lydown_male_02a.NIF",
"anim_lydown_male_02b.NIF",
"anim_lydown_male_02c.nif",
"anim_lyingdown_02.NIF",
"anim_milldance.nif",
"anim_monkeydance.nif",
"anim_multidance_01.nif",
"anim_m_sleeping.nif",
"anim_pose_set_a.nif",
"anim_pose_set_t.nif",
"anim_pose_set_y.nif",
"anim_praybuddism.nif",
"anim_praycross.nif",
"anim_rocknroll.nif",
"anim_rocknrolla.nif",
"anim_roundaboutdance.nif",
"anim_s1_liedown1b.nif",
"anim_s1_sit01a.nif",
"anim_s1_sit23a.nif",
"anim_salutdance.NIF",
"anim_salutmarchedance.nif",
"anim_sexy0x2.nif",
"anim_sexy0x4.nif",
"anim_sexydanceloop.nif",
"anim_sexydance_fnb.nif",
"anim_sexydance_long.nif",
"anim_sexydance_longa.nif",
"anim_sexydance_short.nif",
"anim_sexyslowwalk0x2.nif",
"anim_sexyslowwalk0x4.nif",
"anim_sidemarchedance.nif",
"anim_sitpleading.nif",
"anim_sitthreatening.nif",
"anim_slap_01.nif",
"anim_sleeping.nif",
"anim_sleeping2x.nif",
"anim_stopdance.nif",
"anim_stretchdance.nif",
"anim_swingdance.nif",
"anim_synda.nif",
"anim_synda1.nif",
"anim_synda2.nif",
"anim_synda2x.nif",
"anim_synda3.nif",
"anim_synda4.nif",
"anim_yoohoodance.nif",
"base_anim.nif"
}

local keybindButton
local currIdle = 8 --Current Idle
local currIndex = #nifs

local function animate(e)
	local p

	if tes3.menuMode() then
		return
	end
	
	local rayhit = tes3.rayTest {position = tes3.getPlayerEyePosition(), direction = tes3.getPlayerEyeVector(), ignore = {tes3.player}};

	if rayhit and rayhit.reference then	
		if rayhit.reference.object.objectType == tes3.objectType.npc then
			p = rayhit.reference
			p.data.NPCPoser = p.data.NPCPoser or {}
			p.data.NPCPoser.posing = p.data.NPCPoser.posing or {}
		else
			return
		end
	else
		return
	end
	
	if ( e.isShiftDown and ( p.data.NPCPoser.posing == true ) ) then -- Cycle idles
		currIdle = ( currIdle + 1 ) % 9
		tes3.messageBox("Idle %s", currIdle)
		local animNif = "lp\\" .. nifs[currIndex + 1]
		tes3.loadAnimation({ reference = p, file = animNif })
		tes3.playAnimation({ reference = p, group = currIdle})
		return
	end
	
	if ( e.isAltDown and not e.isControlDown ) then
		currIndex = currIndex + 1
		currIndex = currIndex % #nifs
		tes3.messageBox("Current selected animation: %s", nifs[currIndex + 1])
		return
	end
	
	if ( e.isAltDown and e.isControlDown) then
		currIndex = currIndex - 1
		currIndex = currIndex % #nifs
		tes3.messageBox("Current selected animation: %s", nifs[currIndex + 1])
		return
	end
	
	if ( p.data.NPCPoser.posing == true ) then
		tes3.loadAnimation({ reference = p}) -- Reset to default
		p.data.NPCPoser.posing = false
		tes3.messageBox("Stop posing %s", p.object.name)
		tes3.playAnimation({ reference = p, group = tes3.animationGroup.idle1})
		return
	else
		tes3.messageBox("Pose %s", p.object.name)
		p.data.NPCPoser.posing = true
	end
	local animNif = "lp\\" .. nifs[currIndex + 1]
	tes3.loadAnimation({ reference = p, file = animNif })
	tes3.playAnimation({ reference = p, group = currIdle})

end

local function assignHotkey(e)
	event.unregister(tes3.event.keyDown, animate, { filter = config.hotkey } )
	config.hotkey = e.keyCode
	
	event.register(tes3.event.keyDown, animate, { filter = config.hotkey } )
	local buttonName = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey).value
	tes3.messageBox('animate hotkey is now "%s"', buttonName);
	keybindButton.buttonText = buttonName
	event.unregister(tes3.event.keyDown, assignHotkey)
	keybindButton:setText(buttonName)
end

local function initialized()

	event.register(tes3.event.keyDown, animate, { filter = config.hotkey } )
	
	print("[NPC Poser] NPC Poser Initialized")
end

event.register(tes3.event.initialized, initialized)

local function registerModConfig()

    local mcm = mwse.mcm
    local template = mcm.createTemplate("NPC Poser")
    template:saveOnClose(confPath, config)

    local page = template:createSideBarPage{
        sidebarComponents = {
            mcm.createInfo{ 
			text = "Pose your friends\nControls:\nUse the hotkey to assign an animation nif to the NPC\nWith an NPC in your crosshair, you can press alt with the hotkey to cycle through animation nifs\ncombine alt with control to reverse cycle\nCombine shift with the hotkey to cycle idles from 1-9\nMany nifs only have special idles at higher values\nUse hotkey on posing NPC to reset them"},
        }
    }
		
	local category2 = page:createCategory("Keybind for making an npc pose")
	
	keybindButton = category2:createButton({
	
        buttonText = tes3.findGMST(tes3.gmst.sKeyName_00 + config.hotkey).value;
        description = "Choose animate hotkey.",
        callback = function(self)
			tes3.messageBox("Press a key.")
            event.register(tes3.event.keyDown, assignHotkey)
        end
    })

    mcm.register(template)
end

event.register("modConfigReady", registerModConfig)