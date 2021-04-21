-- Collect light/plant/rock information needed by main.lua

local DEBUG = 0

-------------------------------------------------

local PlantId={"flora_bc_mushroom_01","flora_bc_mushroom_02",
		"flora_bc_mushroom_03","flora_bc_mushroom_04","flora_bc_mushroom_05",
		"flora_bc_mushroom_06","flora_bc_mushroom_07","flora_bc_mushroom_08",
		"flora_bc_podplant_01","flora_bc_podplant_02","flora_bc_podplant_03",
		"flora_bc_podplant_04","cavern_spore00","egg_kwama00"}
local PlantOffset={46,55,42,48,47,53,67,67,74,74,71,51,45,100}
local PlantType={1,1,1,1,1,1,1,1,1,1,1,1,1,2}

local LightId={"bc mushroom 256","bc mushroom 177","bc mushroom 128",
					"bc mushroom 64","eggsack_glow_256"}
local LightRadius={256,177,128,64,256}
local LightType={1,1,1,1,2}

local OreRockId={"rock_ebony_","rock_glass_","rock_adam_"}
local OreRockType={101,102,103}

local OreLightId={"ebony light","green light_256","green light_128",
								"emerald light","adamantium"}
local OreLightRadius={128,400,256,64,128}
local OreLightType={101,102,102,102,103}

-------------------------------------------------
-- Useful debug and error routines
local function ERROR_text(...)
	local str=string.match(debug.traceback("",2),"GHLighting\\([%w\\%.]*:%d*)")
	mwse.log("[GHL] Error: %s  (%s)",string.format(...),str)
end

local function DEBUG_text(ilev,...)
	if (DEBUG < ilev) then return end
	mwse.log(...)
end


--====================== Utility routines ==================--
local function SortUniq(val0)
-- Return sorted table with repeats removed
--
	if (val0 == nil) or (#val0 == 0) then
		return {}
	end
--
	local val1={}
	val1=table.copy(val0)
	table.sort(val1)
	local val2={}
	for i=1,#val1 do
		if (val1[i] ~=val1[i+1]) then
			val2[#val2+1]=val1[i]
		end
	end
--
	return val2
end

local function table_exec(sCode,Par0,tPars)
-- My swiss army knife for tables (high overhead, but compact)
-- Example 1: numeric arg. 2, no arg. 3, OUT[]
--		local dist_map=table_exec("OUT[i]={ilig=i,ipla=i}",#pla)
--		"for i=1,#pla" calculate "OUT[i]={ilig=i,ipla=i}" and return OUT
-- Example 2: table arg. 2, parameters passed in arg. 3, if/then/end
--		table_exec("if(v.i > 0) then n[k]=r[v.i] end",nears2,{n=nears,r=remap})
--		"for k,v in pairs(nears2)" do "if(v.j > 0) then n[k]=r[v.i] end"
--			where "n" and "r" are local copies of "near" and "remap"
--
	local sLocal="local OUT,i={},0\n"
	if (tPars and next(tPars)) then
		local sPars={}
		for key,val in pairs(tPars) do
			sPars[#sPars+1]=key
		end
		sLocal=sLocal.."\tlocal "..table.concat(sPars,",")..
				"=tPars."..table.concat(sPars,",tPars.").."\n"
	end
--
	local sLoop="\tfor k,v in pairs(IN) do\n\t\ti=i+1\n"
	if (type(Par0) == 'number') then
		sLoop="\tfor i=1,IN do\n"
	end
--
	local str="return function(IN,tPars)\n"..sLocal..sLoop..
				"\t\t"..sCode.."\n\tend\n".."\treturn OUT\nend"
--
	local maker,err=load(str)
	if (maker) then
		local ok,func=pcall(maker)
		if ok then
			local ok,out=pcall(func,Par0,tPars)
			if ok then
				return out
			end
			ERROR_text("table_exec: func() run error %s",out)
		else
			ERROR_text("table_exec: maker() run error %s",func)
		end
	else
		ERROR_text("table_exec: maker() compile error %s", err)
	end
	mwse.log("code = %s", str)
	assert(false)
--
end

local function table_append(tab, tab2)
	local tab_out=table.copy(tab)
	table.move(tab2,1,#tab2, #tab_out+1,tab_out)
	return tab_out
end


--====================== Debug information routines ==================--
local function DEBUG_lig_ixrt(lev,str,lights)
	if (DEBUG < lev) then return end
--
	local lref=table_exec("OUT[i]=v.ref",lights)
	local lxyz=table_exec("OUT[i]=v.xyz",lights)
	local ltyp=table_exec("OUT[i]=v.typ",lights)
	local lrad=table_exec("OUT[i]=v.rad",lights)
--
	local nref=#(lref or {})
	local nxyz=#(lxyz or {})
	local nrad=#(lrad or {})
	local ntyp=#(ltyp or {})
	local num=math.max(nref,nxyz,nrad,ntyp)
--
	for i=1,num do
		local tmp=string.format("%s: lights(%2d)",str,i)
		if (nref > 0) then tmp=tmp .. string.format(" %-20s" ,lref[i].id) end
		if (nxyz > 0) then tmp=tmp .. string.format(" %-30s" ,lxyz[i]) end
		if (nrad > 0) then tmp=tmp .. string.format("  R=%3d",lrad[i]) end
		if (ntyp > 0) then tmp=tmp .. string.format(" [%d]"  ,ltyp[i]) end
		mwse.log(tmp)
	end
--
	if (num == 0) then mwse.log("%s: lights() <none>",str) end
end

local function DEBUG_lig_xxr(lev,str,lights)
	if (DEBUG < lev) then return end
--
	local lref=table_exec("OUT[i]=v.ref",lights)
	local lxyz=table_exec("OUT[i]=v.xyz",lights)
	local lrad=table_exec("OUT[i]=v.rad",lights)
	for i=1,#lights do
		mwse.log("%s: lights(%2d) %-30s => %-30s  R=%3d",str,i,lref[i].position,lxyz[i],lrad[i])
	end
--
	if (#lights == 0) then mwse.log("%s: lights() <none>",str) end
end

local function DEBUG_pla_ipxt(lev,str,plants)
	if (DEBUG < lev) then return end
--
	for i=1,#plants do
		mwse.log("%s: plants(%2d) %-20s %-30s => %-30s [%d]",str,i,
				plants[i].ref.id,plants[i].ref.position,plants[i].xyz,plants[i].typ)
	end
--
	if (#plants == 0) then mwse.log("%s: plants() <none>",str) end
end

local function DEBUG_dist_map(lev,str,dist_map)
	if (DEBUG < lev) then return end
--
	for i,d in ipairs(dist_map) do
		mwse.log("%s: dmap(%2d) L=%2d  P=%2d  D=%3d",str,i,d.ilig,d.ipla,d.dist)
	end
--
	if (#dist_map == 0) then mwse.log("%s: dmap() <none>",str) end
end

local function DEBUG_clumps(lev,str,cutoff,dist_map)
	if (DEBUG < lev) then return end
--
	mwse.log("%s: cutoff %d",str,cutoff)
    for i,v in ipairs(dist_map) do
		mwse.log("%s: dmap(%2d) P1=%2d  P2=%2d  D=%3d",str,i,v.ilig,v.ipla,v.dist)
	end
--
	if (#dist_map == 0) then mwse.log("%s: dmap() <none>",str) end
end

local function DEBUG_near_light(lev,str,near_light)
	if (DEBUG < lev) then return end
--
	for i,nr in ipairs(near_light) do
		mwse.log("%s: near_light(P=%2d) L=%2d  D=%3d",str,i,nr.ilig,nr.dist)
	end
--
	if (#near_light == 0) then mwse.log("%s: near_light() <none>",str) end
end

local function DEBUG_bad(lev,str,bads)
	if (DEBUG < lev) then return end
--
	for i=1,#bads do
		mwse.log("%s: bad_xyz(%2d) %2d %-30s [%d]",str,i,bads[i].ipla,bads[i].xyz,bads[i].typ)
	end
--
	if (#bads == 0) then mwse.log("%s: bad_xyz() <none>",str) end
end

local function DEBUG_final(lev,str,plants,lights)
	if (DEBUG < lev) then return end
--
	for i,p in ipairs(plants) do
		mwse.log("%s: plants(%2d) %-20s %-30s [%d] L=%2d",str,i,p.ref.id,p.xyz,p.typ,p.ilig)
	end
--
	for i,l in ipairs(lights) do
		local str2=""
		if l.ref.fake then str2=" new" end
		mwse.log("%s: lights(%2d) %-20s %-30s [%d]%s",str,i,l.ref.id,l.xyz,l.typ,str2)
	end
end

local function DEBUG_summary(lev,str,lights,plants)
	if (DEBUG < lev) then return end
--
	for imode=1,2 do
--
		local smode,types
		if (imode == 1) then
			smode="lights"
			types=table_exec("OUT[i]=v.typ",lights)
		else
			smode="plants"
			types=table_exec("OUT[i]=v.typ",plants)
		end
		local utypes=SortUniq(types)
		local nsum=table_exec("OUT[i]=0",#utypes)
--
		for _,ltyp in ipairs(types) do
			for it,t in ipairs(utypes) do
				if (ltyp == t) then
					nsum[it]=nsum[it]+1
				end
			end
		end
--
		local tmp=table_exec("OUT[i]=string.format(\"%s[%s]\",n[i],t[i])",#nsum,{n=nsum,t=utypes})
		if (#nsum == 0) then tmp={"<none>"} end
		mwse.log("%s: %s by type %s ",str,smode,table.concat(tmp," "))
--
	end
--
end


--===================== Lower level routines without debug info ==================--
local function MyGetActiveCells()			--<< TEMPORARY WORKAROUND
--
	local cell = tes3.mobilePlayer.cell
	local cells={}
	if cell.isInterior then
		cells[1]=cell
	else
		local x0,y0=cell.gridX,cell.gridY
		for x=x0-1,x0+1 do
			for y=y0-1,y0+1 do
				cells[#cells+1]=tes3.getCell({x=x,y=y})
			end
		end
	end
--
	return cells
end

local function GetCellPlants()
-- Find plant/rock containers with glow lights within active cells
	local plants,plantsO={},{}				-- "O" denotes ore version
	local xyz=tes3vector3.new()
	local Rxyz=tes3matrix33.new()
--
--	local cells=tes3.getActiveCells()
	local cells=MyGetActiveCells()		--<< TEMPORARY WORKAROUND
--
	for i,cell in ipairs(cells) do
		for ref in cell:iterateReferences(tes3.objectType.container) do
			local sId=ref.baseObject.id:lower()
-- Try to find a glow plant
			if ref.object.organic then 
				local inum=table.find(PlantId,sId)
				if ( inum and (not ref.disabled) and (not ref.deleted) ) then
					xyz.x, xyz.y, xyz.z=0, 0, PlantOffset[inum] * ref.scale
					Rxyz:fromEulerXYZ( ref.orientation.x, ref.orientation.y, ref.orientation.z )
					plants[#plants+1]={ref=ref,xyz=ref.position+Rxyz*xyz,typ=PlantType[inum]}
				end
			end
-- Try to find a glow rock
			if (sId:sub(1,5) == "rock_") then
				sId=sId:gsub("^(rock_%w+_)%w+","%1")
				local inum=table.find(OreRockId,sId)
				if ( inum and (not ref.disabled) and (not ref.deleted) ) then
					plantsO[#plantsO+1]={ref=ref,xyz=ref.position,typ=OreRockType[inum]}
				end
			end
--
		end
	end
--
	return plants,plantsO
--
end

local function GetCellLights()
-- Find glow lights for plant/rock containers within within active cells
	local lights,lightsO={},{}				-- "O" denotes ore version
--
--	local cells=tes3.getActiveCells()
	local cells=MyGetActiveCells()		--<< TEMPORARY WORKAROUND
--
--
	for i,cell in ipairs(cells) do
		for ref in cell:iterateReferences(tes3.objectType.light) do
			local sId=ref.baseObject.id:lower()
-- Try to find a glow plant light
			local inum=table.find(LightId,sId)
			if ( inum and (not ref.disabled) and (not ref.deleted) ) then
				lights[#lights+1]={ref=ref,xyz=ref.position:copy(),
						typ=LightType[inum],rad=LightRadius[inum]}
			end
-- Try to find a glow ore light
			local inum=table.find(OreLightId,sId)
			if ( inum and (not ref.disabled) and (not ref.deleted) ) then
				lightsO[#lightsO+1]={ref=ref,xyz=ref.position:copy(),
						typ=OreLightType[inum],rad=LightRadius[inum]}
			end
--
		end
	end
--
	return lights,lightsO
--
end

local function MakeDistMap(lights,plants,cutoff)
-- Make table of light & plant indices and distances from the light
-- to the adjusted plant position. Limit distances to < cutoff.
-- If types given, plants & lights must be the same type.
	local dist_map={}
    for ilig=1,#lights do
        for ipla=1,#plants do
			if (lights[ilig].typ == plants[ipla].typ) then
				local dist=(lights[ilig].xyz):distance(plants[ipla].xyz)
				if (dist < cutoff) then
					dist_map[#dist_map+1]={ilig=ilig, ipla=ipla, dist=dist}
				end
			end
		end
    end
	return dist_map
end

local function MakeDistMapNoType(lights,plants,cutoff)
-- As for MakeDistMap but types are ignored
	local dist_map={}
    for ilig=1,#lights do
        for ipla=1,#plants do
			local dist=(lights[ilig].xyz):distance(plants[ipla].xyz)
            if (dist < cutoff) then
				dist_map[#dist_map+1]={ilig=ilig, ipla=ipla, dist=dist}
			end
        end
    end
	return dist_map
end

local function UpdateDistMap(dist_map,lights,plants)
-- Update the distances in dist_map, but not the indices or type
--
	local dist_map2=table.copy(dist_map)
--
	for i=1,#dist_map2 do
        ilig=dist_map2[i].ilig
        ipla=dist_map2[i].ipla
        dist_map2[i].dist=(lights[ilig].xyz):distance(plants[ipla].xyz)
    end
--
	return dist_map2
end

local function CalcNearLight(dist_map,nplants,cutoff,lights)
-- Create a list, indexed by plant number, containing the index of
-- the nearest light (or zero if none are within cutoff distance)
-- and that distance.
--
	local near_lights=table_exec("OUT[i]={ilig=0, dist=1e9}",nplants)
--
	if lights then
		local lig_rad=table_exec("OUT[i]=v.rad",lights)
		for i,dmap in ipairs(dist_map) do
			if ( dmap.dist < math.min(cutoff*lights[dmap.ilig].rad,
									near_lights[dmap.ipla].dist) ) then
				near_lights[dmap.ipla]={ilig=dmap.ilig, dist=dmap.dist} 
			end
		end
	else
		for i,dmap in ipairs(dist_map) do
			if (dmap.dist < cutoff) and (dmap.dist < near_lights[dmap.ipla].dist) then
				near_lights[dmap.ipla]={ilig=dmap.ilig, dist=dmap.dist} 
			end
		end
	end
--
	return near_lights
--
end

local function CalcCentredLights(near_lights,lights,plants)
-- For each light, move light to the centre of near plants
--
-- Zero the arrays
	local nsum=table_exec("OUT[i]=0",#lights)
	local sum=table_exec("OUT[i]=tes3vector3:new()",#lights)
-- Sum plant positions with the same near light
    for ipla=1,#near_lights do
        local ilig=near_lights[ipla].ilig
        if (ilig > 0) then
            nsum[ilig]=nsum[ilig]+1
            sum[ilig]=sum[ilig]+plants[ipla].xyz
        end
    end
--
-- For each light, calculate average plant XYZ or use light's XYZ if nsum=0
	local ave_xyz={}
	for i=1,#lights do
		if (nsum[i] == 0) then
			ave_xyz[i]=lights[i].xyz
		else
			ave_xyz[i]=sum[i] *(1.0/nsum[i])
		end
	end
--
	table_exec("v.xyz=x[i]",lights,{x=ave_xyz})
	return lights
--
end

local function RemoveUnusedLights(near_light,dist_map,lights)
-- Removes lights without a near_light, and remap dist_map[] and near_light[]
--
-- Create sparse boolean table of used lights
	local used=table_exec("if (v.ilig > 0) then OUT[v.ilig]=true end",near_light)
--
-- Create string containing the unused indices
	local unused=table_exec("if (not u[i]) then OUT[#OUT+1]=i end",#lights,{u=used})
	local str=table.concat(unused,",")
	if (str == "") then str="<none>" end
--
-- Remap lights[] to avoid unused ones
	local remap=table_exec("OUT[k]=i",used)
	local lights=table_exec("OUT[v]=l[k]",remap,{l=lights})
-- Remap dist_map[] & near_light[] to avoid unused lights
	table_exec("if(v.ilig > 0) then v.ilig=r[v.ilig] end",dist_map,{r=remap})
	dist_map=table_exec("if v.ilig then OUT[#OUT+1]=v; end",dist_map)
	table_exec("if(v.ilig > 0) then n[k].ilig=r[v.ilig] end",
								table.copy(near_light),{n=near_light,r=remap})
--
	return near_light,dist_map,lights,str
end


local function RemoveUnusedPlants(plants)
-- Removes plants without a nearest light
--
-- Create sparse boolean table of used plants
	local used=table_exec("if (v.ilig > 0) then OUT[i]=true end",plants)
--
-- Create string containing the unused indices
	local unused=table_exec("if (not u[k]) then OUT[#OUT+1]=k end",#plants,{u=used})
	local str=table.concat(unused,",")
	if (str == "") then str="<none>" end
--
-- Remap plants[] to avoid unused ones
	local remap=table_exec("OUT[k]=i",used)
	local plants=table_exec("OUT[v]=p[k]",remap,{p=plants})
--
	return plants,str
end


--===================== Higher level routines with debug info ==================--

local function FindPlantClumps(plants,cutoff)
-- Try to find multiple bad plants within cutoff distance apart.
-- Returns the averaged positions of these "clumps".
-- Actual clumps can be larger than cutoff in diameter.
--
-- Create distance map between pairs of plants within cutoff units
	local dist_map=MakeDistMap(plants,plants,cutoff)
	dist_map=table_exec("if(v.ilig < v.ipla) then OUT[#OUT+1]=v end",dist_map)
	DEBUG_clumps(6,"FindPlantClumps",cutoff,dist_map)
--
-- Loop over plants, adding averaged positions to new_xyz[]
	local new_xyz={}
    for ipla1=1,#plants do
-- Create a list of bad-plants near ipla1, starting with ipla1
        local near_list={ipla1}
-- Extend near_list[] by adding plants near to any already in near_list[]
-- Four iterations should be plenty
        for iter=1,4 do
-- For each plant in near_list[]:
            for ibad=1,#near_list do
                ipla2=near_list[ibad]
-- Search for plants connected to the near plant:
                for imap=1,#dist_map do
					local inew = 0
                    if (dist_map[imap].ilig == ipla2) then
						inew=dist_map[imap].ipla
                    elseif (dist_map[imap].ipla == ipla2) then
						inew=dist_map[imap].ilig
                    end
-- If found, add new plant to near list, and zero its dist_map[] indices
                    if (inew > 0) then
						near_list[#near_list+1]=inew
                        dist_map[imap].ilig=0
                        dist_map[imap].ipla=0
                    end
                end
            end
-- Remove repeats of the same plant, and any zeroes
            near_list[#near_list+1]=0
            near_list=SortUniq(near_list)
			table.remove(near_list,1)
        end
--
-- Add average position of clumps (not single plants) to new_xyz[]
		if (#near_list > 1) then
			local ave=plants[near_list[1]].xyz
			for i=2,#near_list do
				ave=ave+plants[near_list[i]].xyz
			end
			new_xyz[#new_xyz+1]=ave *(1/#near_list)
			DEBUG_text(6,"FindPlantClumps: near_list(P1=%2d) P2=%s",ipla1,table.concat(near_list,", "))
		end
--
    end
--
	for i=1,#new_xyz do
		DEBUG_text(6,"FindPlantClumps: new_xyz(%2d) %27s",i,new_xyz[i])
	end
--
-- Return new_xyz in a lights[] table
	local lights=table_exec("OUT[i]={xyz=v}",new_xyz)
	return lights
--
end

local function CalcMultiLights(plants,radius)
-- Find new light positions for multiple bad plants
--
-- Find possible light positions centred on "clumps" of plants
	local lights=FindPlantClumps(plants,1.9*radius)
	DEBUG_lig_ixrt(5,"CalcMultiLights 1",lights)
--
-- Create dist_map ignoring plant/light types
	local dist_map=MakeDistMapNoType(lights,plants,radius)
	DEBUG_dist_map(5,"CalcMultiLights 1",dist_map)
--
-- Make a list of the plant types
	local types=SortUniq( table_exec("OUT[i]=v.typ",plants) )
	local str=table.concat(types," ")
	if (#plants == 0) then str="<none>"; end
	DEBUG_text(5,"CalcMultiLights 1: Plant types %s",str)
-- Use the first plant type for the possible lights
	table_exec("v.typ=t",lights,{t=types[1]})
-- Duplicate lights for all other plant types
	local nlights=#lights
	for ityp=2,#types do
		for i=1,nlights do
			lights[#lights+1]={typ=types[ityp],xyz=lights[i].xyz,rad=radius}
		end
	end
-- Set all rad values to radius
	table_exec("v.rad=r",lights,{r=radius})
	DEBUG_lig_ixrt(5,"CalcMultiLights 2",lights)
-- Create dist_map while enforcing plant/light types
	dist_map=MakeDistMap(lights,plants,radius)
	DEBUG_dist_map(5,"CalcMultiLights 2",dist_map)
-- Calculate nearest lights from new dist_map
	local near_light=CalcNearLight(dist_map,#plants,radius)
	DEBUG_near_light(5,"CalcMultiLights 2",near_light)
--
-- Remove lights not in near_light[]
	near_light,dist_map,lights,str=RemoveUnusedLights(near_light,dist_map,lights)
	DEBUG_text(5,"CalcMultiLights 3: Ignored light(s) %s",str)
--
-- Set light XYZ to the centre of the near plants
    lights=CalcCentredLights(near_light,lights,plants)
    dist_map=UpdateDistMap(dist_map,lights,plants)
	DEBUG_lig_ixrt(5,"CalcMultiLights 4",lights)
	DEBUG_dist_map(5,"CalcMultiLights 4",dist_map)
--
	return dist_map,lights
--
end

local function CalcSingleLights(plants,radius)
-- Setup light positions to illuminate individual plants
--
	local lights=table_exec("OUT[i]={xyz=v.xyz,typ=v.typ,rad=r}",plants,{r=radius*0.25})
	local dist_map=table_exec("OUT[i]={ilig=i,ipla=i,dist=0.0}",#plants)
	DEBUG_lig_ixrt(5,"CalcSingleLights",lights)
	DEBUG_dist_map(5,"CalcSingleLights",dist_map)
--
	return dist_map,lights
--
end

local function FindUnmatched(near_light,plants)
-- Find all "unmatched" plants, i.e. ones without a nearest light
--
    local bads={}
    for ipla=1,#near_light do
        if (near_light[ipla].ilig == 0) then
            bads[#bads+1]={ipla=ipla,xyz=plants[ipla].xyz:copy(),typ=plants[ipla].typ}
        end
    end
	DEBUG_bad(5,"FindUnmatched",bads)
--
	return bads
--
end

local function MakeNewLights(plants,dist_map, Passed_Function,radius)
--
-- Find nearest light (if within 0.8*radius) for each plant
	local near_light=CalcNearLight(dist_map,#plants,0.8*radius)
	DEBUG_near_light(4,"MakeNewLights",near_light)
--
-- Find all "bad" plants unmatched by a nearest light
	local bads=FindUnmatched(near_light,plants)
--
-- Find light positions that illuminate multiple/single bad plants
	local dist_map2,lights2=Passed_Function(bads,radius)
--
-- Save id for light type in lights2[].ref.id, and set lights2[].ref.fake=true
	for i=1,#lights2 do
		lights2[i].ref={}
		local inum=table.find(LightType,lights2[i].typ)
		lights2[i].ref.id=LightId[inum]
		lights2[i].ref.fake=true
	end
--
	return lights2,dist_map2,bads

end

local function AddNewLights(lights,plants,dist_map,radius)
-- Find light positions for all plants without a nearest light
--
	local lights2,dist_map2,bads
	for iter=1,3 do
		DEBUG_text(2,"AddNewLights: Multi Lights %s",iter)
		lights2,dist_map2,bads=MakeNewLights(plants,dist_map, CalcMultiLights,radius)
		DEBUG_text(2,"AddNewLights: #bads,#new-lights %s,%s",#bads,#lights2)
		DEBUG_lig_ixrt(4,"AddNewLights",lights2)
		if (#lights2 == 0) then break end
-- Update/add the new lights to dist_map and lights
		dist_map2=table_exec( "OUT[k]={ilig=n+v.ilig,ipla=b[v.ipla].ipla,dist=v.dist}",
														dist_map2,{b=bads,n=#lights} )
		dist_map=table_append(dist_map,dist_map2)
		lights=table_append(lights,lights2)
	end
--
	DEBUG_text(2,"AddNewLights: Single Lights")
	lights2,dist_map2,bads=MakeNewLights(plants,dist_map, CalcSingleLights,radius)
	DEBUG_text(2,"AddNewLights: #bads, #new-lights %s,%s",#bads,#lights2)
	DEBUG_lig_ixrt(4,"AddNewLights",lights2)
--
-- Update/add the new lights to dist_map and lights
	dist_map2=table_exec( "OUT[k]={ilig=n+v.ilig,ipla=b[v.ipla].ipla,dist=v.dist}",
													dist_map2,{b=bads,n=#lights} )
	dist_map=table_append(dist_map,dist_map2)
	lights=table_append(lights,lights2)
--
	DEBUG_lig_ixrt(4,"AddNewLights 2",lights2)
	DEBUG_dist_map(4,"AddNewLights 2",dist_map)
--
	return lights,dist_map

end

local function MoveOldLights(dist_map,lights,plants)
-- Move lights to optimally illuminate plants
--
	if (#lights == 0) then
		DEBUG_text(4,"MoveOldLights: No lights to optimise")
		return lights,dist_map
	end
--
-- Calculate near lights for plants using distance of 1.2*light-radius
	local near_light=CalcNearLight(dist_map,#plants,1.2,lights)
	DEBUG_near_light(4,"MoveOldLights 1",near_light)
-- Use averaged near plant positions for optimised light position
	lights=CalcCentredLights(near_light,lights,plants)
	DEBUG_lig_xxr(4,"MoveOldLights 1",lights)
-- Update distances using new light positions
	dist_map=UpdateDistMap(dist_map,lights,plants)
	DEBUG_dist_map(4,"MoveOldLights 1",dist_map)
--
-- Repeat for smaller distance of 0.8*lights-radius
	local near_light=CalcNearLight(dist_map,#plants,0.8,lights)
	DEBUG_near_light(4,"MoveOldLights 2",near_light)
-- Average near plant positions for new light position
	lights=CalcCentredLights(near_light,lights,plants)
	DEBUG_lig_xxr(4,"MoveOldLights 2",lights)
-- Update distances using new light positions
	dist_map=UpdateDistMap(dist_map,lights,plants)
	DEBUG_dist_map(4,"MoveOldLights 2",dist_map)
-- Physically move lights to new positions
	table_exec("v.ref.position=v.xyz",lights)
--
	return lights,dist_map
end

local function ConnPlantLights(radius)
-- Connect glow plants/rocks and lights via a distance map
	local plants,plantsO=GetCellPlants()
	local lights,lightsO=GetCellLights()
-- Create dist_map while enforcing plant/light types
	local dist_map=MakeDistMap(lights,plants,2.0*radius)
	local dist_mapO=MakeDistMap(lightsO,plantsO,2.0*radius)
-- Find nearest lights from new dist_map (double distance for ore)
	local near_light=CalcNearLight(dist_map,#plants,radius)
	local near_lightO=CalcNearLight(dist_mapO,#plantsO,2.0*radius)
--
	DEBUG_pla_ipxt(4,"ConnPlantLights (plants)",plants)
	DEBUG_lig_ixrt(4,"ConnPlantLights (plants)",lights)
	DEBUG_dist_map(4,"ConnPlantLights (plants)",dist_map)
	DEBUG_near_light(4,"ConnPlantLights (plants)",near_light)
-- Remap tables to remove any lights not in near_light[]
	near_light,dist_map,lights,str=RemoveUnusedLights(near_light,dist_map,lights)
	DEBUG_text(3,"ConnPlantLights (plants): Ignored light(s) %s",str)
--
	DEBUG_pla_ipxt(4,"ConnPlantLights (ore)",plantsO)
	DEBUG_lig_ixrt(4,"ConnPlantLights (ore)",lightsO)
	DEBUG_dist_map(4,"ConnPlantLights (ore)",dist_mapO)
	DEBUG_near_light(4,"ConnPlantLights (ore)",near_lightO)
-- Remap tables (ore version)
	near_lightO,dist_mapO,lightsO,str=RemoveUnusedLights(near_lightO,dist_mapO,lightsO)
	DEBUG_text(3,"ConnPlantLights (ore): Ignored light(s) %s",str)
--
	return lights,plants,dist_map,lightsO,plantsO,dist_mapO
--
end


--=================== Global Main Routine =================--
function SetupPlantLights()
--
	local radius=256.0
	DEBUG_text(1,"\nSetupPlantLights Start")
--
-- Get all glow lights and plants/rocks in current cells, and make distance maps
-- NB: Glowing ore lists have a trailing O
	local lights,plants,dist_map,lightsO,plantsO,dist_mapO = ConnPlantLights(radius)
	DEBUG_summary(1,"SetupPlantLights (plants)",lights,plants)
	DEBUG_summary(1,"SetupPlantLights (ore)",lightsO,plantsO)
--
-- Move lights to optimally illuminate plants
	lights,dist_map=MoveOldLights(dist_map,lights,plants)
--
-- Add new light positions to illuminate unmatched plants
	lights,dist_map=AddNewLights(lights,plants,dist_map,radius)
	DEBUG_summary(1,"SetupPlantLights",lights,plants)
--
-- Get nearest light to each plant within radius(double for ore) distance
	near_light=CalcNearLight(dist_map,#plants,radius)
	near_lightO=CalcNearLight(dist_mapO,#plantsO,2*radius)
--
-- Append mining ore tables to the main tables (dist_map no longer needed)
	table_exec( "if(v.ilig>0) then v.ilig=n+v.ilig end", near_lightO,{n=#lights} )
	plants=table_append(plants,plantsO)
	lights=table_append(lights,lightsO)
	near_light=table_append(near_light,near_lightO)
--
-- Rebuild tables for main.lua
	plants=table_exec("OUT[i]={ref=v.ref,ilig=n[i].ilig,xyz=v.xyz,typ=v.typ}",plants,{n=near_light})
	lights=table_exec("OUT[i]={ref=v.ref,xyz=v.xyz,typ=v.typ}",lights)
	DEBUG_final(3,"SetupPlantLights",plants,lights)
--
-- Remove any unused plants/rocks
	plants,str=RemoveUnusedPlants(plants)
	local nremove=#plants
	DEBUG_text(2,"SetupPlantLights: Ignored plant(s) %s",str)
--
	DEBUG_summary(1,"SetupPlantLights",lights,plants)
	DEBUG_text(1,"SetupPlantLights Finish")
	return plants,lights
--
end
