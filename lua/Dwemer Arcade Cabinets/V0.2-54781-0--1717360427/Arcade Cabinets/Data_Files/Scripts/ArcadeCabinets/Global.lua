local world = require('openmw.world')
local types = require('openmw.types')
local interfaces = require('openmw.interfaces')
local util = require('openmw.util')
local players = world.players
local ModVersion=0.2


local ArcadesPlaced={}
ArcadesPlaced[1]=0
ArcadesPlaced[2]={}
local ArcadesPlaces={
						{"Odrosal, Dwemer Training Academy",util.vector3(-257, -3150, 200),util.transform.rotateZ(0)},
						{"Arkngthand, Hall of Centrifuge",util.vector3(-991, 3236, 1535),util.transform.rotateZ(math.pi*5/4)},
						{"Galom Daeus, Observatory",util.vector3(3196, 4646, 12801),util.transform.rotateZ(math.pi*5/4)},
						{"Druscashti, Upper Level",util.vector3(1270, 214, -1215),util.transform.rotateZ(0)},
						{"Aleft",util.vector3(3172, 832, 193),util.transform.rotateZ(0.8)},
						{"Mzuleft",util.vector3(-1517, 4289, -607),util.transform.rotateZ(-1.14)},
						{"Mzahnch",util.vector3(2701, 992, 257),util.transform.rotateZ(-0.8)},
						{"Nchurdamz, Interior",util.vector3(1223, 1366, -702),util.transform.rotateZ(0)},
						{"Bthuand",util.vector3(1909, -831, -415),util.transform.rotateZ(math.pi/2)},
						{"Gnisis, Bethamez",util.vector3(-463, -2722, -191),util.transform.rotateZ(-math.pi/2)},
						{"Endusal, Kagrenac's study",util.vector3(986, -1132, -767),util.transform.rotateZ(math.pi/2)},
						{"Nchardumz",util.vector3(-594, 3505, -575),util.transform.rotateZ(-math.pi/2)},
						{"Nchardumz Lower Level",util.vector3(-339, 385, -255),util.transform.rotateZ(-math.pi/2)},
						{"Nchuleftingth, Upper Levels",util.vector3(2661, 1355, -191),util.transform.rotateZ(-0.3)},
						{"Nchardahrk",util.vector3(1434, 5755, 113),util.transform.rotateZ(0)},
					}


local function onSave()
	return{ArcadesPlaced=ArcadesPlaced,ModVersion=ModVersion}
end

local function onLoad(data)
	if data.ModVersion then
		ArcadesPlaced=data.ArcadesPlaced
		if ModVersion~=data.ModVersion then
			print("here")
			ArcadesPlaced[1]=0
			ModVersion=data.ModVersion
		end
	end
end

local function Remove(data)
	data.object:remove(data.number)
end

local function onUpdate()
	if ArcadesPlaced[1]==50 then
		if ArcadesPlaced[2] then
			for i, Arcade in pairs(ArcadesPlaced[2]) do
				Arcade.enabled=false
			end
		end
		for i, place in pairs(ArcadesPlaces) do
			ArcadesPlaced[2][i]=world.createObject("ArcadeCabinet"..math.random(0,2),1)
			ArcadesPlaced[2][i]:teleport(place[1],place[2],{rotation=place[3],onGround=true})
		end

		ArcadesPlaced[1]=ArcadesPlaced[1]+1
	elseif ArcadesPlaced[1]<50 then
		ArcadesPlaced[1]=ArcadesPlaced[1]+1
	end
end

return {
	eventHandlers = {Remove=Remove},
	engineHandlers = {
        onUpdate = onUpdate,
		onSave=onSave,
		onLoad=onLoad,

	},
}