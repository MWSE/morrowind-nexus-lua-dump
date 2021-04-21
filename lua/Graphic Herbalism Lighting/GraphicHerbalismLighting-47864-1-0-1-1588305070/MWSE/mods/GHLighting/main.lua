-- Main routine for Graphic Herbalism Lighting [GHL]

local DEBUG = 0

-- Info for glow-plants/rocks and glow-lights in active cells
local Plants={}
local Lights={}

-- To communicate from OnContClosed() to UpdatePlantGlow()
local ClosedPlantIndex

require("GHLighting.PlantLights")
require("GHLighting.InitCells")


-------------------------------------------------
-- Useful error and debug routines

local function ERROR_text(...)
	local str=string.match(debug.traceback("",2),"GHLighting\\([%w\\%.]*:%d*)")
	mwse.log("[GHL] Error: %s  (%s)",string.format(...),str)
end

local function DEBUG_text(ilev,...)
	if (DEBUG < ilev) then return end
	mwse.log(...)
end

local frame_timer,frame_count
local function DoTiming2(ref)
	frame_count=frame_count+1
	mwse.log("DoTiming%d: Time = %d ms",frame_count,-1e3*frame_timer.timeLeft)
	if (frame_count < 6) then
		frame_timer=timer.delayOneFrame( DoTiming2 )
	end
end
local function DoTiming(ref)
	frame_count=1
	mwse.log("DoTiming%d: Time = %d ms",frame_count,-1e3*frame_timer.timeLeft)
	frame_timer=timer.delayOneFrame( DoTiming2 )
end


----------------------------------------------------------
-- Change the light output of pulsing lights

local PulseSlowVal,PulseFastVal=0.70,0.70
local PulseSlowGrad,PulseFastGrad=1.2,2.7
local PulseLightTimer
local PulseDebugTime=0.0
--
local function DoPulseLights()
--
-- Generate the slow and fast pulse values
	local dTime=-PulseLightTimer.timeLeft
	PulseSlowVal=PulseSlowVal + dTime*PulseSlowGrad
	if ((PulseSlowGrad > 0) and (PulseSlowVal > 0.95)) or
	   ((PulseSlowGrad < 0) and (PulseSlowVal < 0.30)) then
		PulseSlowGrad=-PulseSlowGrad
	end
--
	PulseFastVal=PulseFastVal + dTime*PulseFastGrad
	if ((PulseFastGrad > 0) and (PulseFastVal > 0.95)) or
	   ((PulseFastGrad < 0) and (PulseFastVal < 0.30)) then
		PulseFastGrad=-PulseFastGrad
	end
--
-- Apply pulse values to any pulsing lights
	for ilig,lig in ipairs(Lights) do
		if lig.ref.light then
			if lig.ref.object.pulsesSlowly then
				lig.ref.light.dimmer=lig.int * PulseSlowVal
			elseif lig.ref.object.pulses then
				lig.ref.light.dimmer=lig.int * PulseFastVal
			end
		end
	end
--
-- Potentially, output debug information every second
	PulseDebugTime=PulseDebugTime+dTime
	if (PulseDebugTime > 1.0) then
		PulseDebugTime=0.0
		for ilig,lig in ipairs(Lights) do
			if lig.ref.light then
				if (lig.ref.object.pulses or lig.ref.object.pulsesSlowly) then
					DEBUG_text(5,"DoPulseLights(L=%s): int=%.2f, dimmer=%.2f",
											ilig,lig.int,lig.ref.light.dimmer)
				end
			end
		end
	end
--
-- Run this routine again in the next frame
	PulseLightTimer=timer.delayOneFrame( DoPulseLights )
--
end


-------------------------------------------------
-- Change the light output of non-pulsing lights

local function UpdateSceneLight(ilig)
	local lig=Lights[ilig]
--
-- If using a "fake" reference, create a real one
	if lig.ref.fake then
		local cell = tes3.mobilePlayer.cell
		lig.ref=tes3.createReference( {object=lig.ref.id,position=lig.xyz,cell=cell} )
		DEBUG_text(3,"UpdateSceneAll: Created reference for light(%d)",ilig)
	end
--
-- Make sure dynamic-lighting is on
	if (not lig.ref.light.isDynamic) then
		lig.ref:setDynamicLighting()
	end
--
-- Update position, dimmer(if not pulsing), and radius of light
	lig.ref.position=lig.xyz
	if not (lig.ref.light.pulsesSlowly or lig.ref.light.pulses) then
		lig.ref.light.dimmer=lig.int
	end
	lig.ref.light:setAttenuationForRadius(lig.rad)
-- Update lighting on screen, and set reference not to be put in a save file
	lig.ref:updateLighting()
	lig.ref.modified=false
--
	return lig
end

local function UpdateSceneAll()
-- Create/modify the "rendering light" for all objects in Lights[]
--
	for ilig,lig in ipairs(Lights) do
		Lights[ilig]=UpdateSceneLight(ilig)
	end
--
end


-------------------------------------------------
-- Calculate the glow light intensities, radius, xyz

local function CalcGlowLight(ilig)
--
	if (not Lights[ilig]) then
		ERROR_text("Invalid Lights index=%s",ilig)
		return
	end
--
	local lig_ref=Lights[ilig].ref
	local lig_typ=Lights[ilig].typ
	local lig_xyz=Lights[ilig].xyz
	local lig_int,lig_rad
--
-- Sum plant/ore xyz, and count unpicked and total plants
	local ntotal,nunpick=0,0
	local sum_xyz=tes3vector3:new()
	for _,pla in ipairs(Plants) do
		if (pla.ilig == ilig) then
			ntotal=ntotal+1
			if (not pla.ref.isEmpty) then
				nunpick=nunpick+1
				sum_xyz=sum_xyz+pla.xyz
			end
		end
	end
--
-- In case ntotal=0 (?!?), nothing to do
	if (ntotal == 0) then
		ERROR_text("ntotal = 0")
		return
	end
--
-- Move light position to average plant (not ore) position
	if (lig_typ < 100) and (nunpick > 0) then
		lig_xyz=sum_xyz * (1.0/nunpick)
	end
--
-- Estimate light radius and intensity
	local cell=tes3.getPlayerCell()
	local ore_rad=128+128*ntotal
	if (lig_typ == 1) and cell.isInterior then
		int_mult,lig_rad = 0.2,64			-- plant, interior
	elseif (lig_typ == 1) then
		int_mult,lig_rad = 0.5,256			-- plant, exterior
	elseif (lig_typ == 2) then
		int_mult,lig_rad = 0.5,128			-- kwama eggsack
	elseif (lig_typ == 101) then
		int_mult,lig_rad = 0.3,ore_rad		-- ebony
	elseif (lig_typ == 102) then
		int_mult,lig_rad = 0.5,ore_rad		-- glass
	elseif (lig_typ == 103) then
		int_mult,lig_rad = 2.0,ore_rad		-- adamantine
	else
		ERROR_text("Unknown light type=%s",lig_typ)
	end
	lig_int=int_mult * (150/lig_rad)^1.5 * nunpick / ntotal^0.5
--
-- Save results in Lights[]
	Lights[ilig].xyz=lig_xyz
	Lights[ilig].int=lig_int
	Lights[ilig].rad=lig_rad
	DEBUG_text(4,"CalcGlowLight(L=%s): unpick/total=%d/%d, (rad,int)=(%3d,%.2f) xyz=%s",
									ilig,nunpick,ntotal,lig_rad,lig_int,lig_xyz)
--
end

local function UpdateSingleGlow()
--
	local ipla=ClosedPlantIndex		-- from OnContClosed()
	local ilig=Plants[ipla].ilig
	DEBUG_text(2,"UpdateSingleGlow: plant=%s, light=%s ",ipla,ilig)
--
------ So it works without GHerb, though unreliably!
----	local ref=Plants[ipla].ref
----	if (#ref.object.inventory == 0) then
----		ref.isEmpty=true
----	end
------
-- Calculate new intensity/radius/xyz
	CalcGlowLight(ilig)
--
-- Implement the change to the scene for this light
	Lights[ilig]=UpdateSceneLight(ilig)
--
	DEBUG_text(3,"UpdateSingleGlow(L=%s): (rad,int)=(%3d,%.2f) xyz=%s",
					ilig,Lights[ilig].rad,Lights[ilig].int,Lights[ilig].xyz)
end

local function UpdateAllGlows()
--
	DEBUG_text(2,"\nUpdateAllGlows: Start(%s lights)",#Lights)
	for ilig,lig in ipairs(Lights) do
		CalcGlowLight(ilig)
	end
	DEBUG_text(2,"UpdateAllGlows: Finish\n")
--
end


----------------------------------------------------------
-- Service the events

local function OnContClosed(ev)
--
    local ref=ev.reference
    if ref.object.organic or (ref.id:sub(1,5) == "rock_") then
-- Get index of the plant/rock
		local pla_idx
		for i,pla in ipairs(Plants) do
			if (pla.ref == ref) then
				pla_idx=i
				break
			end
		end
-- If one of ours, update the plant/rock glow next frame
-- NB: Delay needed as isEmpty is invalid in this frame
		if pla_idx then
			ClosedPlantIndex=pla_idx
			timer.delayOneFrame( UpdateSingleGlow )
		end
	end
--
end

local function OnCellChanged(ev)
--
	if (DEBUG > 0) then
		local cell=(tes3.mobilePlayer).cell
		mwse.log("\nOnCellChanged: Start in Cell=%s (%s,%s)",cell.id,cell.gridX,cell.gridY)
	end
--
-- Change glow light references for ore rocks (InitCells.lua)
    InitCellRefs()
--
-- Get info on glowing plants/rocks/lights (PlantsLights.lua)
	Plants,Lights=SetupPlantLights()
--
-- Change the light intensities according to Plants[] & Lights[]
	UpdateAllGlows()
--
-- Delay 1 frame and do scene update for all lights
	timer.delayOneFrame( UpdateSceneAll )
--
	if (DEBUG > 0) then
		mwse.log("OnCellChanged: Start DoTiming() timer")
		frame_timer=timer.delayOneFrame( DoTiming )
		mwse.log("OnCellChanged: Finish")
	end
--
end

local function OnGameLoaded()
--
-- Make sure pulsing lights timer is running
	PulseLightTimer=timer.delayOneFrame( DoPulseLights )
	DEBUG_text(1,"OnGameLoaded: Start DoPulseLights timer")
--
end


local function OnInitialized(ev)
--
-- Reset plants/lights on cell change and resting
	event.register("cellChanged", OnCellChanged)
	event.register("calcRestInterrupt", OnCellChanged)
--
--
	event.register("loaded", OnGameLoaded)
--
-- Use "container closed" instead of "activate" for "plant harvesting"
    event.register("containerClosed",OnContClosed)
--
	mwse.log("[GHL] Graphic Herbalism Lighting v0.99 initialized")
--
end
event.register("initialized", OnInitialized)
