local self=require('openmw.self')
local types = require('openmw.types')
local nearby=require('openmw.nearby')
local util = require('openmw.util')
local core = require('openmw.core')
local anim = require('openmw.animation')
Player=nil

--[[
local BulletCase={}
BulletCase.Timer=0
BulletCase.SounceOnce=true
BulletCase.DoOnce=true

if self.recordId=="bulletcase" then
    BulletCase.DoOnce=false
    anim.playQueued(self,"bulletanim",{loops=0})
end
]]--


local function Activate(data)
    print("activator")
    core.sendGlobalEvent("LocalVariableCheck",{Object=self,Player=data.actor,Variable="crowbarvalue"})
    core.sendGlobalEvent("LocalVariableCheck",{Object=self,Player=data.actor,Variable="blowtorch"})
    core.sendGlobalEvent("LocalVariableCheck",{Object=self,Player=data.actor,Variable="hacpuzzle"})
    Player=data.actor
end


local function onUpdate(dt)
    if Player then
        core.sendGlobalEvent("LocalVariableCheck",{Object=self,Player=Player,Variable="electricalpanelpuzzle"})
    end
end


return {
    eventHandlers = {onActivated=Activate},
	engineHandlers = {
        --onActivated=Activate,------marche pas avec  MWscript "if onactivate==1"-> besoin de 'interfaces.Activation.addHandlerForObject'
        onUpdate = onUpdate
        



	}
}
