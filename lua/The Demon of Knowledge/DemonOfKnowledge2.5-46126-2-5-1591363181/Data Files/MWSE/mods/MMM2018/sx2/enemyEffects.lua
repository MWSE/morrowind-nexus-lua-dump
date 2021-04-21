
local debug = false
local function debugMessage(string)
	if debug then
		tes3.messageBox(string)
		mwse.log("[Demon of Knowledge: DEBUG] " .. string)
	end
end

local common = require("MMM2018.sx2.common")
--[[ 
	Enemy effects
	Enemies have unique effects based on prefix
	on cell load: check enemies, look at prefixes, assign effect
]]--




--Deathword summon------------------------------------------------------------------------------
local function summonDeathwords(e)
	tes3.messageBox("summoning")
	tes3.runLegacyScript({ command = "PlaceAtMe " .. common.itemIds.summonedPapernado.. " 1 200 0", reference = e.caster})
	tes3.runLegacyScript({ command = "PlaceAtMe " .. common.itemIds.summonedPapernado.. " 1 200 1", reference = e.caster})
	tes3.runLegacyScript({ command = "PlaceAtMe " .. common.itemIds.summonedPapernado.. " 1 200 2", reference = e.caster})
end
local function applySummon(e)
	tes3.messageBox("Apply Summon")
	e.resistedPercent = 0
end
------------------------------------------------------------------------------------------------

--Blink spell-----------------------------------------------------------------------------------
local function castBlink(e) 
	if e.caster == e.target then return end
	
	if e.effectInstance.state == tes3.spellState.beginning then
		debugMessage("Casting blink")
		local newx
		local newy
		local newz
		if e.source == tes3.getObject(common.spellIds.Blink01) then
			debugMessage("teleport behind target")
			--teleport behind target
			newx = e.target.position.x - ( 100 * math.sin(e.target.orientation.z) )
			newy = e.target.position.y - ( 100 * math.cos(e.target.orientation.z) )
			newz = e.target.position.z
		elseif e.source == tes3.getObject(common.spellIds.Blink02) then
			debugMessage("teleport away from target")
			--teleport away from target
			local randDist = math.random(300, 500)
			newx = e.target.position.x + ( randDist * math.sin(e.target.orientation.z) )
			newy = e.target.position.y +( randDist * math.cos(e.target.orientation.z) )
			newz = e.target.position.z
		end
		mwscript.position({ reference = e.caster, x = newx, y = newy, z = newz, rotation = e.caster.orientation.z })
	end
end
------------------------------------------------------------------------------------------------


local function activatePapernado(e)
	if ( e.target.object.id == "sx2_papernado_01" )
	or ( e.target.object.id == "sx2_papernado_02" )
	or ( e.target.object.id == "sx2_papernado_static" )
	or ( e.target.object.id == "sx2_papernado" )
	then
		if not e.target.data.takenScroll then
			e.target.data.takenScroll = true
			print( tes3.gmst.sNotifyMessage60 )
			--Random chance to get regular paper
			tes3.playSound({reference=e.target, sound="Scroll"})
			if math.random(100) < ( 10 + ( tes3.getMobilePlayer().luck.current / 10 ) ) then
				local scrollList = mwse.loadConfig("mmm2018/sx2/scrolls").skillScrollIds
				local chosenScroll = scrollList[ math.random( #scrollList ) ]
				--"Scroll has been added to your inventory"
				tes3.messageBox( tes3.getGMST(tes3.gmst.sNotifyMessage60).value , tes3.getObject(chosenScroll).name )
				mwscript.addItem({ reference = tes3.player, item = chosenScroll })
			else
				--"Paper has been added to your inventory"
				tes3.messageBox( tes3.getGMST(tes3.gmst.sNotifyMessage60).value , "Paper" )	
				mwscript.addItem({ reference = tes3.player, item = "sc_paper plain" })
			end
		end
	end
end


local function initialize()

	--Deathword summon
	local deathwordSpell = tes3.getObject( common.spellIds.Deathword ) or "nothing"
	event.register( "spellResist", applySummon, { filter = deathwordSpell } )
	event.register( "spellCasted", summonDeathwords, { filter = deathwordSpell } )
	
	--Blink Spell
	local blinkSpell_01 = tes3.getObject( common.spellIds.Blink01 ) or "nothing"
	local blinkSpell_02 = tes3.getObject( common.spellIds.Blink02 ) or "nothing"
	event.register( "spellTick", castBlink, { filter = blinkSpell_01 } )
	event.register( "spellTick", castBlink, { filter = blinkSpell_02 } )
	
	--papernado Scroll
	event.register("activate", activatePapernado)
end

event.register("Hermes:Initialized", initialize)