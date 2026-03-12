-- This PathPointsTriggers is configure to run with MorrowindRailShooter.omwaddon

local self = require('openmw.self')
local nearby = require('openmw.nearby')
local input = require('openmw.input')
local ui = require('openmw.ui')
local util = require('openmw.util')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local core = require('openmw.core')
local camera = require('openmw.camera')
local async = require('openmw.async')
local ambient = require('openmw.ambient')

local PathPointsTriggers={}

PathPointsTriggers[1]=function()
	ambient.playSoundFile("Music/Battle/MW battle 4.mp3",{loop=true})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="nix-hound",Cell=self.cell.name,Position=util.vector3(math.sin(self.rotation:getYaw())*800, math.cos(self.rotation:getYaw())*900, 0) + self.position})
	FoesToKill=1
	end
PathPointsTriggers[2]=function()
	core.sendGlobalEvent("RSCreateFoe",{RecordId="cliff racer",Cell=self.cell.name,Position=util.vector3(math.sin(self.rotation:getYaw())*900, math.cos(self.rotation:getYaw())*900, 200) + self.position})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="cliff racer",Cell=self.cell.name,Position=util.vector3(math.sin(self.rotation:getYaw())*1100, math.cos(self.rotation:getYaw())*800, 250) + self.position})
	FoesToKill=2
	end
PathPointsTriggers[3]=function()
	core.sendGlobalEvent("RSCreateFoe",{RecordId="rat",Cell=self.cell.name,Position=util.vector3(math.sin(self.rotation:getYaw())*300, math.cos(self.rotation:getYaw())*400, 0) + self.position})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="rat",Cell=self.cell.name,Position=util.vector3(math.sin(self.rotation:getYaw())*400, math.cos(self.rotation:getYaw())*500, 0) + self.position})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="cliff racer",Cell=self.cell.name,Position=util.vector3(math.sin(self.rotation:getYaw())*1000, math.cos(self.rotation:getYaw())*900, 200) + self.position})
	FoesToKill=3
	end
PathPointsTriggers[4]=function()
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_stalker",Cell=self.cell.name,Position=util.vector3(math.sin(self.rotation:getYaw())*600, math.cos(self.rotation:getYaw())*800, 0) + self.position})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_stalker",Cell=self.cell.name,Position=util.vector3(math.sin(self.rotation:getYaw())*300, math.cos(self.rotation:getYaw())*100, 0) + self.position})
	FoesToKill=2
	end
PathPointsTriggers[5]=function()
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_stalker",Cell=self.cell.name,Position=util.vector3(-6500,129347,705)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_stalker",Cell=self.cell.name,Position=util.vector3(-6520,129347,705)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_stalker",Cell=self.cell.name,Position=util.vector3(-6510,129347,705)})
	FoesToKill=3
	end
PathPointsTriggers[6]=function()
	core.sendGlobalEvent("RSCreateFoe",{RecordId="atronach_frost",Cell=self.cell.name,Position=util.vector3(-8623,128768,832)})
	FoesToKill=1
	end
PathPointsTriggers[7]=function()
	core.sendGlobalEvent("RSCreateFoe",{Boss=true, RecordId="vavran reni",Cell=self.cell.name,Position=util.vector3(-10900,129000,730)})
	FoesToKill=1
	end
PathPointsTriggers[8]=function()
	CurrentPathPoint=CurrentPathPoint+1
	end
PathPointsTriggers[9]=function()
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_stalker",Cell=self.cell.name,Position=util.vector3(-12030,127000,1370)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_stalker",Cell=self.cell.name,Position=util.vector3(-11500,127000,1370)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_stalker",Cell=self.cell.name,Position=util.vector3(-11000,127000,1370)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_lame",Cell=self.cell.name,Position=util.vector3(-12030,126800,1370)})
	FoesToKill=4
	end
PathPointsTriggers[10]=function()
	local DoorRay=nearby.castRay(camera.getPosition(),camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5,0.5))*camera.getBaseViewDistance(),{ignore=self})
	DoorRay.hitObject:activateBy(self)
	CurrentPathPoint=CurrentPathPoint+1
	end
PathPointsTriggers[11]=function()
	CurrentPathPoint=CurrentPathPoint+1
	end
PathPointsTriggers[12]=function()
	core.sendGlobalEvent("RSCreateFoe",{RecordId="ash_zombie",Cell=self.cell.name,Position=util.vector3(-1730,6615,-1880)})
	FoesToKill=1
	end
PathPointsTriggers[13]=function()
	CurrentPathPoint=CurrentPathPoint+1
	end
PathPointsTriggers[14]=function()
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_stalker",Cell=self.cell.name,Position=util.vector3(-2357,6862,-1920)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_lame",Cell=self.cell.name,Position=util.vector3(-2316,6862,-1920)})
	FoesToKill=2
	end
PathPointsTriggers[15]=function()
	CurrentPathPoint=CurrentPathPoint+1
	end
PathPointsTriggers[16]=function()
	core.sendGlobalEvent("RSCreateFoe",{RecordId="ash_zombie",Cell=self.cell.name,Position=util.vector3(-1537,7444,-1898)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="ash_zombie",Cell=self.cell.name,Position=util.vector3(-1274,7284,-1898)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_lame",Cell=self.cell.name,Position=util.vector3(-1464,7366,-1898)})
	FoesToKill=3
	end
PathPointsTriggers[17]=function()
	CurrentPathPoint=CurrentPathPoint+1
	end
PathPointsTriggers[18]=function()
	core.sendGlobalEvent("RSCreateFoe",{RecordId="ash_ghoul",Cell=self.cell.name,Position=util.vector3(-1894,7269,-1920)})
	FoesToKill=1
	end
PathPointsTriggers[19]=function()
	CurrentPathPoint=CurrentPathPoint+1
	end
PathPointsTriggers[20]=function()
	CurrentPathPoint=CurrentPathPoint+1
	end
PathPointsTriggers[21]=function()
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_stalker",Cell=self.cell.name,Position=util.vector3(-2257,7762,-1920)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_stalker",Cell=self.cell.name,Position=util.vector3(-2336,7762,-1920)})
	FoesToKill=2
	end
PathPointsTriggers[22]=function()
	CurrentPathPoint=CurrentPathPoint+1
	end
PathPointsTriggers[23]=function()
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_stalker",Cell=self.cell.name,Position=util.vector3(-2039,8054,-1920)})
	FoesToKill=1
	end
PathPointsTriggers[24]=function()
	CurrentPathPoint=CurrentPathPoint+1
end
PathPointsTriggers[25]=function()
	CurrentPathPoint=CurrentPathPoint+1
	end
PathPointsTriggers[26]=function()
	core.sendGlobalEvent("RSCreateFoe",{RecordId="ash_ghoul",Cell=self.cell.name,Position=util.vector3(-1839,8671,-1920)})
	FoesToKill=1
	end
PathPointsTriggers[27]=function()
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_stalker",Cell=self.cell.name,Position=util.vector3(-605,8542,-1920)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_stalker",Cell=self.cell.name,Position=util.vector3(-655,8542,-1920)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_stalker",Cell=self.cell.name,Position=util.vector3(-693,8542,-1920)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_stalker",Cell=self.cell.name,Position=util.vector3(-693,8484,-1920)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_lame",Cell=self.cell.name,Position=util.vector3(-605,8484,-1920)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_lame",Cell=self.cell.name,Position=util.vector3(-655,8484,-1920)})
	FoesToKill=6
	end
PathPointsTriggers[28]=function()
	core.sendGlobalEvent("RSCreateFoe",{RecordId="corprus_lame",Cell=self.cell.name,Position=util.vector3(-1139,8325,-1920)})
	FoesToKill=1
	end
PathPointsTriggers[29]=function()
	local DoorRay=nearby.castRay(camera.getPosition(),camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5,0.5))*camera.getBaseViewDistance(),{ignore=self})
	DoorRay.hitObject:activateBy(self)
	CurrentPathPoint=CurrentPathPoint+1
	end

PathPointsTriggers[30]=function()
	core.sendGlobalEvent("RSCreateFoe",{RecordId="ash_ghoul",Cell=self.cell.name,Position=util.vector3(3243,6559,128)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="ash_zombie",Cell=self.cell.name,Position=util.vector3(3151,7233,128)})
	FoesToKill=2
	end
PathPointsTriggers[31]=function()
	CurrentPathPoint=CurrentPathPoint+1
	end
PathPointsTriggers[32]=function()
	CurrentPathPoint=CurrentPathPoint+1
	end
PathPointsTriggers[33]=function()
	for i=1,15 do
		core.sendGlobalEvent("RSCreateFoe",{RecordId="ash_ghoul",Cell=self.cell.name,Position=util.vector3(2278+i,4816+i,90)})
	end
	for i=1,15 do
		core.sendGlobalEvent("RSCreateFoe",{RecordId="ash_ghoul",Cell=self.cell.name,Position=util.vector3(1386+i,4823+i,90)})
	end
	FoesToKill=3
	end
PathPointsTriggers[34]=function()
	CurrentPathPoint=CurrentPathPoint+1
	end
PathPointsTriggers[35]=function()
	CurrentPathPoint=CurrentPathPoint+1
	end
PathPointsTriggers[36]=function()
	CurrentPathPoint=CurrentPathPoint+1
	end
PathPointsTriggers[37]=function()
	local DoorRay=nearby.castRay(camera.getPosition(),camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5,0.5))*camera.getBaseViewDistance(),{ignore=self})
	DoorRay.hitObject:activateBy(self)
	CurrentPathPoint=CurrentPathPoint+1
	end
PathPointsTriggers[38]=function()
	CurrentPathPoint=CurrentPathPoint+1
	end
PathPointsTriggers[39]=function()
	core.sendGlobalEvent("RSCreateFoe",{RecordId="ash_zombie",Cell=self.cell.name,Position=util.vector3(-320,8690,-1920)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="ash_zombie",Cell=self.cell.name,Position=util.vector3(-320,8743,-1920)})
	FoesToKill=2
	end
PathPointsTriggers[40]=function()
	CurrentPathPoint=CurrentPathPoint+1
	end
PathPointsTriggers[41]=function()
	core.sendGlobalEvent("RSCreateFoe",{RecordId="ash_ghoul",Cell=self.cell.name,Position=util.vector3(137,8342,-1920)})
	FoesToKill=1
	end
PathPointsTriggers[42]=function()
	local IgnoreList={}
	for i, actor in pairs(nearby.actors) do
		table.insert(IgnoreList,actor)
	end
	local DoorRay=nearby.castRay(camera.getPosition(),camera.getPosition()+camera.viewportToWorldVector(util.vector2(0.5,0.5))*camera.getBaseViewDistance(),{ignore=IgnoreList})
	DoorRay.hitObject:activateBy(self)
	CurrentPathPoint=CurrentPathPoint+1
	end
PathPointsTriggers[43]=function()
	ambient.stopSoundFile("Music/Battle/MW battle 4.mp3")
	ambient.playSoundFile("Music/Battle/MW battle 8.mp3",{loop=true})
	core.sendGlobalEvent("RSCreateFoe",{Boss=true,RecordId="boss1",Cell=self.cell.name,Position=util.vector3(132,7584,-1920)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="boss1creatures",Cell=self.cell.name,Position=util.vector3(290,7560,-1880)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="boss1creatures",Cell=self.cell.name,Position=util.vector3(-130,7560,-1780)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="boss1creatures",Cell=self.cell.name,Position=util.vector3(90,7560,-1800)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="boss1creatures",Cell=self.cell.name,Position=util.vector3(190,7560,-1700)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="boss1creatures",Cell=self.cell.name,Position=util.vector3(0,7560,-1880)})
	core.sendGlobalEvent("RSCreateFoe",{RecordId="boss1creatures",Cell=self.cell.name,Position=util.vector3(50,7560,-1900)})
	FoesToKill=1
	end
PathPointsTriggers[44]=function()
	ambient.stopSoundFile("Music/Battle/MW battle 8.mp3")
	ambient.playSoundFile("sound/fx/inter/levelup.wav")
	CurrentPathPoint=CurrentPathPoint+1
	end
return (PathPointsTriggers)
