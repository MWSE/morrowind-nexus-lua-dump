----	OMW patch to duplicate MWSE interop environment
local I = require("openmw.interfaces")
local function include()	return I.SSQN		end
local tes3 = { event={} }	local event = { register = function(_, fn)	fn()	end }
----	End patch


----	Start: standard MWSE SSQN interop script


local ssqn = include("SSQN.interop") --Must come before function calls

local function init()
    if (ssqn) then

	-- add commands to register an SSQN icon

    	-- ssqn.registerQIcon("PC_m1_AFP01","\\Icons\\pc\\q\\PC_m1_AFP.dds")
    	-- ssqn.registerQIcon("PC_m1_AFP02","\\Icons\\pc\\q\\PC_m1_AFP.dds")

        -- add commands to block a journal ID from showing banner notifications

        -- ssqn.blockQBanner("PC_m1_Anv_GoldenrodBR")
        -- ssqn.blockQBanner("PC_m1_Anv_GoldenrodDR")

    end
end

event.register(tes3.event.initialized, init)


