local I = require("openmw.interfaces")

-- this is an example/template on how to add more workstations to your game

local stations = {{
    id = "fargoth", -- record id of the object to be considered as a workstation, any game object is valid
    name = "Workbench", -- name that will be displayed
    tool = "prong" -- the type of tool that can be used for this workstation, the pattern used to match either record id or name of the object
}, {
    id = "furn_com_rm_table_04", -- the table with hrisskar's note in the census office in seyda neen
    name = "Worktable", -- for objects that already have a name tooltip, it's better to use an empty string
    tool = "hammer"
}}

for _, station in pairs(stations) do
    -- I.PracticalRepair_eqnx.addStation(station)
end

-- then you need to include this file in your omwscripts file under GLOBAL
-- e.g
-- GLOBAL: scripts/practical_repair/addWorkstations.lua
