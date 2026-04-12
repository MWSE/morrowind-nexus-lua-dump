----	OMW patch to fake the MWSE api calls so this script can be run from the iconlists folder
local M = {}
local interop = { registerQIcon = function(id, path)	M[id] = path	end }
local function include()	return interop		end
local tes3 = { event={} }
local event = { register = function(_, fn)	fn()	end }
----

local ssqn = include("SSQN.interop")

local function init()
    if (ssqn) then
        ssqn.registerQIcon("AGB_Mist_Dorans","\\Icons\\agb\\q\\DOD_Dorans.dds")
		ssqn.registerQIcon("AGB_Mist_Idols","\\Icons\\agb\\q\\DOD_Clav.dds")
		ssqn.registerQIcon("AGB_Mist_Justice","\\Icons\\agb\\q\\DOD_Justice.dds")
		ssqn.registerQIcon("AGB_Mist_Love","\\Icons\\agb\\q\\DOD_Love.dds")
		ssqn.registerQIcon("AGB_Mist_MQ","\\Icons\\agb\\q\\DOD.dds")
    end
end

event.register(tes3.event.initialized, init)

----	OMW patch to return icon table to main SSQN script
return M