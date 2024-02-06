
local Container = require("herbert100.animated containers.Container") ---@type herbert.AC.Container
local config = require("herbert100.animated containers.config") ---@type herbert.AC.config
local log = require("herbert100.logger").new(require("herbert100.animated containers.defns")) .. "interop"

local pk = require("herbert100.animated containers.defns").persistent_data_keys

-- here you will most likely find all the functions and tables you need in order to interact with this mod.
-- this includes things like opening and closing containers, as well as changing how meshes are replaced.
---@class herbert.AC.interop
local interop = {

    --- Checks if a container can be opened, and then opens it if appropriate.
    -- **NOTE:** this function only checks animated container related things when determining if something can be opened; 
    -- it does not check for locks, traps, ownership, etc.
    -- In other words, this function *assumes* you have a good reason to try to open this container.
    -- **NOTE:** For more advanced behavior/logic, you will have to import the `Container` class and use its fields and methods.
    ---@param ref tes3reference Reference to the `tes3container` you want to open.
    ---@param show_contents_menu boolean? Should the contents menu be shown after the animation finishes? Default: `false`.
    -- **WARNING:** it's possible to open the menus for locked/trapped containers via this parameter. Handle this accordingly.
    -- **NOTE:** this setting will only take effect if the player has their config set to open content menus when animations finish. 
    -- You can't use this function to override that behavior.
    ---@return boolean opened Whether the open animation for this container was played. (i.e., whether it could be opened)
    try_to_open = function(ref, show_contents_menu)
        local container = Container.new(ref)
        log("trying to open %s", container or ref)

        if container and container:can_open() then
            container:open(show_contents_menu)
            return true
        end
        return false
    end,

    --- Checks if a container can be closed, and then closes it if appropriate.
    -- **NOTE:** For more advanced behavior/logic, you will have to import the `Container` class and use its fields and methods.
    ---@param ref tes3reference Reference to the `tes3container` to close.
    ---@param check_auto_close boolean? This parameter lets you specify whether you're trying to close this container as a result of a state change rather than a choice made by the player.
    -- The purpose of this parameter is to let your mod play nicely with the "auto close containers" setting in the MCM.
    -- If a user has that setting disabled, then this function will won't ever close containers when `check_auto_close = true`.
    -- **Example:** in my QuickLoot mod, I set this parameter to `true` when trying to close containers as a result of a QuickLoot menu being destroyed.
    ---@return boolean closed whether the container was closed
    try_to_close = function(ref, check_auto_close)
        -- check here so that we dont have to make a new container object
        if check_auto_close and not config.auto_close then
            log("did not close %s because of config settings", ref.object.name)
            return false
        end

        local container = Container.new(ref, {check_for_collisions=false})
        log("trying to close %s", container or ref)

        if container and container:can_close() then 
            container:close() 
            return true
        end

        return false
    end,

    --- This will try to open a container. If that doesn't work, it will try to close a container.
    ---@param ref tes3reference reference to the container to open
    ---@param show_contents_menu boolean? Should the contents menu be shown after the animation finishes? 
    -- **WARNING:** it's possible to open the menus for locked/trapped containers via this parameter. Handle this accordingly.
    -- **NOTE:** this setting will only take effect if the player has their config set to open content menus when animations finish. 
    -- You can't use this function to override that behavior.
    ---@param check_auto_close boolean? This parameter lets you specify whether you're trying to close this container as a result of a state change rather than a choice made by the player.
    -- The purpose of this parameter is to let your mod play nicely with the "auto close containers" setting in the MCM.
    -- If a user has that setting disabled, then this function will won't ever close containers when `check_auto_close = true`.
    -- **Example:** in my QuickLoot mod, I set this parameter to `true` when trying to close containers as a result of a QuickLoot menu being destroyed.
    ---@return boolean changed Whether the container was toggled. This will be `true` if: the container was open and now it's closed, or the contaienr was closed and now it's open.
    try_to_toggle = function(ref, show_contents_menu, check_auto_close)
        log("toggling container status")
        local container = Container.new(ref)
        if not container then return false end

        if container:can_open() then
            container:open(show_contents_menu)
            return true
        elseif container:can_close(check_auto_close) then            
            container:close()
            return true
        end
        return false
    end,

    --- get the state of the container. maps to values in the `defns.container_state` table.
    ---@param ref tes3reference
    ---@return herbert.AC.defns.container_state state
    get_container_state = function(ref)
        return ref.data[pk.container_state] or 1
    end,

   
    -- mesh replacements. consider using the `add_custom_mesh_replacement` when interacting with this table
    ---@type herbert.AC.interop.add_custom_mesh_replacement.params[]
    custom_mesh_replacements = {},
}

-- parameters for the `add_custom_mesh_replacement` function
---@class herbert.AC.interop.add_custom_mesh_replacement.params
---@field old_mesh string the string representing the old mesh
---@field new_mesh string mesh to replace old mesh with
---@field animation_info string|herbert.AC.Animation_Info the animation info to use when replacing the mesh.
--- this paramater can be one of two types:
--- 1. `CA.Animation_Info`: i.e., an instance of the `Animation_Info` class (make sure to use the `.new` function!).
--- 2. the name of an existing `Animation_Info` class (i.e., a key in the `common.animation_info` table.). in this case, the corresponding `Animation_Info` will be used.
---@field priority integer? The priority of this mesh replacement. This allows for a more predictable outcome when two mods try to replace the same mesh.
-- The replacement with the lowest priority number will win.
-- (This is so that the behavior is consistent with how the `priority` keyword is used in MWSE. i.e., higher priority things happen _first_.)

--- Add a custom mesh replacement. You should specify the old mesh, the new mesh, and information about the animation to use.
---@param p herbert.AC.interop.add_custom_mesh_replacement.params Table that holds information about the mesh you want to replace.
--[[ The following parameters are accepted:
* `old_mesh: string` The mesh you want to replace.
* `new_mesh: string` The mesh to replace the old mesh with.
* `animation_info: string|herbert.AC.Animation_Info`: Information about the animations of this mesh. If this is a `string`, then it should be a key in the `common.animation_info` table.
* `priority integer?`: The priority of this mesh replacement. This allows for a more predictable outcome when two mods try to replace the same mesh. 
 See the documentation for `Animation_Info` for more details on this parameter. It's not too bad, I promise!
 The replacement with the lowest priority number will win.
 (This is so that the behavior is consistent with how the `priority` keyword is used in MWSE. i.e., higher priority things _happen first_.)
]]
interop.add_custom_mesh_replacement = function (p)
    p.priority = p.priority or 0
    table.insert(interop.custom_mesh_replacements, p)
end


return interop