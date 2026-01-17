local log = mwse.Logger.new()
-- houses many utility functions used by the mod, as well as information about which objects get what animations
---@class herbert.AC.common
local common = {
    -- checks if two references intersect each other
    ---@param ref1 tes3reference
    ---@param ref2 tes3reference
    ---@param max_padding tes3vector3? additional padding for the `max` vector. this will be added to `max`.
    ---@param min_padding tes3vector3? additional padding for the `min` vector. this will be subtracted from `min`.
    intersects = function(ref1, ref2, max_padding, min_padding)
        local bb1, bb2 = ref1.object.boundingBox, ref2.object.boundingBox
        if not bb1 or not bb2 then
            return false
        end
        local bb1min = bb1.min + ref1.position
        local bb1max = bb1.max + ref1.position
        local bb2min = bb2.min + ref2.position
        local bb2max = bb2.max + ref2.position
        if max_padding then
            bb1max = bb1max + max_padding
        end
        if min_padding then
            bb1min = bb1min - min_padding
        end
        return
            bb1max.x >= bb2min.x and bb2max.x >= bb1min.x and bb1max.y >= bb2min.y and
            bb2max.y >= bb1min.y and bb1max.z >= bb2min.z and bb2max.z >= bb1min.z
    end
    ,

    -- a list of object types that should be checked when looking for moveable objects
    ---@type tes3.objectType[]
    obj_types_to_check = {
        tes3.objectType.activator,
        tes3.objectType.alchemy,
        tes3.objectType.apparatus,
        tes3.objectType.armor,
        tes3.objectType.book,
        tes3.objectType.clothing,
        tes3.objectType.container,
        tes3.objectType.ingredient,
        tes3.objectType.light,
        tes3.objectType.lockpick,
        tes3.objectType.miscItem,
        tes3.objectType.probe,
        tes3.objectType.repairItem,
        tes3.objectType.static,
        tes3.objectType.weapon,
    },
    gh_installed = tes3.isLuaModActive("graphicHerbalism"), ---@type boolean

    -- a table containing predefined animations, indexed by the type of container the animation is for
    ---@type table<string, herbert.AC.Animation_Info>
    animation_info = nil,

    -- a table that takes in the id of an object and spits out the type of animation to use
    animation_info_by_mesh_key = nil, ---@type table<string, herbert.AC.Animation_Info>
}

do                                                                               -- initialize animations and container types
    local Animation_Info = require("herbert100.animated containers.Animation_Info") --- @type herbert.AC.Animation_Info

    common.animation_info = {
        basket = Animation_Info.new { sound_id = "basket", check_collisions = true },

        barrel = Animation_Info.new { sound_id = "barrel", check_collisions = true },

        cauldron = Animation_Info.new {
            sound_id = "cauldron",
            open_time = 1.0,
            check_collisions = true,
        },

        chest = Animation_Info.new { sound_id = "chest", check_collisions = true },

        chest_small = Animation_Info.new { sound_id = "smallChest", check_collisions = true },

        chest_dwemer = Animation_Info.new {
            sound_id = "dw_chest",
            open_time = 1.0,
            check_collisions = true,
        },

        closet = Animation_Info.new { sound_id = "closet" },

        closet_dwemer = Animation_Info.new { sound_id = "dw_closet", open_time = 1.0 },

        crate = Animation_Info.new { sound_id = "crate", check_collisions = true },

        cupboard = Animation_Info.new { sound_id = "cupboard" },

        daedric = Animation_Info.new {
            sound_id = "daed",
            open_time = 1.0,
            check_collisions = true,
        },

        drawer = Animation_Info.new { sound_id = "drawer" },

        drawer_dunmer = Animation_Info.new { sound_id = "drawer_de" },

        drawer_dwemer = Animation_Info.new { sound_id = "dw_drawer", open_time = 1.0 },

        keg = Animation_Info.new { sound_id = "keg", check_collisions = true },

        kollop = Animation_Info.new { sound_id = "kollop" },

        pot = Animation_Info.new { sound_id = "pot" },

        sack = Animation_Info.new { sound_id = "sack" },

        urn = Animation_Info.new { sound_id = "urn", check_collisions = true },
    }

    common.animation_info_by_mesh_key = {
        ['anim_daedric_chest'] = common.animation_info.daedric,
        ['anim_barrel_01'] = common.animation_info.barrel,
        ['anim_barrel_norivet'] = common.animation_info.barrel,
        ['anim_barrel_02'] = common.animation_info.barrel,
        ['anim_crate_01'] = common.animation_info.crate,
        ['anim_crate_02'] = common.animation_info.crate,
        ['anim_cratelogo'] = common.animation_info.crate,
        ['anim_basket'] = common.animation_info.basket,
        ['anim_cauldron'] = common.animation_info.cauldron,
        ['anim_chest_small_01'] = common.animation_info.chest_small,
        ['anim_chest_small_02'] = common.animation_info.chest_small,
        ['anim_chest10'] = common.animation_info.chest,
        ['anim_com_chest_01'] = common.animation_info.chest,
        ['anim_com_chest_02'] = common.animation_info.chest,
        ['anim_de_chest_01'] = common.animation_info.chest,
        ['anim_de_chest_02'] = common.animation_info.chest,
        ['anim_de_closet_02'] = common.animation_info.closet,
        ['anim_de_closet_01'] = common.animation_info.closet,
        ['anim_com_closet_01'] = common.animation_info.closet,
        ['anim_com_drawers_01'] = common.animation_info.drawer,
        ['anim_de_drawers_01'] = common.animation_info.drawer,
        ['anim_de_table_02'] = common.animation_info.drawer_dunmer,
        ['anim_de_table_01'] = common.animation_info.drawer_dunmer,
        ['anim_de_drawers_02'] = common.animation_info.drawer_dunmer,
        ['anim_de_desk_01'] = common.animation_info.drawer_dunmer,
        ['anim_dw_barrel_02'] = common.animation_info.keg,
        ['anim_dw_barrel_01'] = common.animation_info.keg,
        ['anim_dw_table'] = common.animation_info.drawer_dwemer,
        ['anim_dw_drawers'] = common.animation_info.drawer_dwemer,
        ['anim_dw_desk'] = common.animation_info.drawer_dwemer,
        ['anim_dw_cabinet'] = common.animation_info.drawer_dwemer,
        ['anim_dwrv_chest10'] = common.animation_info.chest_dwemer,
        ['anim_dwrv_chest00'] = common.animation_info.chest_dwemer,
        ['anim_dw_closet'] = common.animation_info.closet_dwemer,
        ['anim_hutch'] = common.animation_info.closet,
        ['anim_cupboard'] = common.animation_info.closet,
        ['anim_pot'] = common.animation_info.pot,
        ['anim_sack_01'] = common.animation_info.sack,
        ['anim_sack_02'] = common.animation_info.sack,
        ['anim_sack_03'] = common.animation_info.sack,
        ['anim_urn_01'] = common.animation_info.urn,
        ['anim_urn_02'] = common.animation_info.urn,
        ['anim_urn_03'] = common.animation_info.urn,
        ['anim_urn_04'] = common.animation_info.urn,
        ['anim_urn_05'] = common.animation_info.urn,
    }
    -- if tes3.isLuaModActive("graphicHerbalism") then
    common.animation_info_by_mesh_key['anim_kollop_01gh'] =
        common.animation_info.kollop
    common.animation_info_by_mesh_key['anim_kollop_02gh'] =
        common.animation_info.kollop
    common.animation_info_by_mesh_key['anim_kollop_03gh'] =
        common.animation_info.kollop
    -- else
    common.animation_info_by_mesh_key['anim_kollop_01'] =
        common.animation_info.kollop
    common.animation_info_by_mesh_key['anim_kollop_02'] =
        common.animation_info.kollop
    common.animation_info_by_mesh_key['anim_kollop_03'] =
        common.animation_info.kollop
    -- end
end

--- for internal use only (unless you know what you're doing)
---@param mesh string mesh name
---@return string mesh_key to use when indexing `animation_info_by_mesh`
function common._get_mesh_key(mesh)
    local _, index = string.find(mesh, "^.*\\") -- index is the location of the last "\" in the string
    -- this is the part of the string that comes after the last "\", excluding the ".nif" at the end
    -- the `lower` function makes sure it's in lowercase letters.
    return mesh:sub((index or 0) + 1, -5):lower()
    -- example: if `mesh == "AC\\Anim_CupBoard.nif"`, then this function would return "anim_cupboard"
end

common.pickupable = {
    [tes3.objectType.alchemy] = true,
    [tes3.objectType.armor] = true,
    [tes3.objectType.weapon] = true,
    [tes3.objectType.book] = true,
    [tes3.objectType.ingredient] = true,
    [tes3.objectType.clothing] = true,
    [tes3.objectType.ammunition] = true,
    [tes3.objectType.lockpick] = true,
    [tes3.objectType.probe] = true,
    [tes3.objectType.apparatus] = true,
    [tes3.objectType.miscItem] = true,
    [tes3.objectType.repairItem] = true,
}

---@param ref tes3reference
function common.is_pickupable(ref)
    return common.pickupable[ref.object.objectType] or ref.object.objectType ==
        tes3.objectType.light and ref.object.canCarry or false
end

-- returns the animation information for a container with the specified reference
---@param ref tes3reference
---@return herbert.AC.Animation_Info
function common.get_animation(ref)
    return common.animation_info_by_mesh_key[common._get_mesh_key(ref.object.mesh)]
    -- old implementation below
    -- local _, name = ref.object.mesh:match("(.-)([^\\]+)$")
    -- log:trace(logmsg_get_animation, ref, name)
    -- return common.animation_info_by_mesh_key[name:lower():sub(1, -5)]
end

do -- set meshes to replace
    local config = require("herbert100.animated containers.config")

    common.meshes_to_replace = {
        ['o\\contain_crate_01.nif'] = 'AC\\Anim_Crate_01.nif',
        ['o\\contain_crate_02.nif'] = 'AC\\Anim_Crate_02.nif',
        ['o\\contain_chest_small_01.nif'] = 'AC\\anim_chest_small_01.nif',
        ['o\\contain_chest_small_02.nif'] = 'AC\\anim_chest_small_02.nif',
        ['o\\contain_couldron10.nif'] = 'AC\\Anim_Cauldron.nif',
        ['o\\contain_pot_01.nif'] = 'AC\\Anim_Pot.nif',
        ['o\\contain_com_basket_01.nif'] = 'AC\\Anim_Basket.nif',
        ['o\\contain_com_chest_01.nif'] = 'AC\\anim_com_chest_01.nif',
        ['o\\contain_com_chest_02.nif'] = 'AC\\anim_com_chest_02.nif',
        ['o\\contain_com_closet_01.nif'] = 'AC\\Anim_com_Closet_01.nif',
        ['o\\contain_com_cupboard_01.nif'] = 'AC\\Anim_CupBoard.nif',
        ['o\\contain_com_drawers_01.nif'] = 'AC\\Anim_com_drawers_01.nif',
        ['o\\contain_com_hutch_01.nif'] = 'AC\\Anim_Hutch.nif',
        ['o\\contain_com_sack_01.nif'] = 'AC\\Anim_sack_01.nif',
        ['o\\contain_com_sack_02.nif'] = 'AC\\Anim_sack_02.nif',
        ['o\\contain_com_sack_03.nif'] = 'AC\\Anim_sack_03.nif',
        ['o\\contain_urn_01.nif'] = 'AC\\Anim_Urn_01.nif',
        ['o\\contain_urn_02.nif'] = 'AC\\Anim_Urn_02.nif',
        ['o\\contain_urn_03.nif'] = 'AC\\Anim_Urn_03.nif',
        ['o\\contain_urn_04.nif'] = 'AC\\Anim_Urn_04.nif',
        ['o\\contain_urn_05.nif'] = 'AC\\Anim_Urn_05.nif',

        ['o\\contain_barrel_01.nif'] = config.barrel_rivet and 'AC\\Anim_Barrel_01.nif' or
            'AC\\Anim_Barrel_noRivet.nif',

        ['o\\contain_barrel10.nif'] = 'AC\\Anim_Barrel_02.nif',
        ['o\\contain_de_chest_01.nif'] = 'AC\\anim_de_chest_01.nif',
        ['o\\contain_de_chest_02.nif'] = 'AC\\anim_de_chest_02.nif',
        ['o\\contain_de_closet_01.nif'] = 'AC\\Anim_de_Closet_01.nif',
        ['o\\contain_de_closet_02.nif'] = 'AC\\Anim_de_Closet_02.nif',
        ['o\\contain_de_desk_01.nif'] = 'AC\\Anim_de_desk_01.nif',
        ['o\\contain_de_drawers_01.nif'] = 'AC\\Anim_de_drawers_01.nif',
        ['o\\contain_de_drawers_02.nif'] = 'AC\\Anim_de_drawers_02.nif',
        ['o\\contain_de_table_01.nif'] = 'AC\\Anim_de_table_01.nif',
        ['o\\contain_de_table_02.nif'] = 'AC\\Anim_de_table_02.nif',
        ['o\\contain_dwrv_barrel00.nif'] = 'AC\\Anim_Dw_Barrel_01.nif',
        ['o\\contain_dwrv_barrel10.nif'] = 'AC\\Anim_Dw_Barrel_02.nif',
        ['o\\contain_dwrv_chest00.nif'] = 'AC\\anim_dwrv_chest00.nif',
        ['o\\contain_dwrv_chest10.nif'] = 'AC\\anim_dwrv_chest10.nif',
        ['o\\contain_dwrv_closet00.nif'] = 'AC\\Anim_Dw_Closet.nif',
        ['o\\contain_dwrv_desk00.nif'] = 'AC\\Anim_Dw_Desk.nif',
        ['o\\contain_dwrv_drawers00.nif'] = 'AC\\Anim_Dw_Drawers.nif',
        ['o\\contain_dwrv_table00.nif'] = 'AC\\Anim_Dw_Table.nif',
        ['o\\contain_de_crate_logo.nif'] = 'AC\\Anim_CrateLogo.nif',
        ['f\\furn_dwrv_cabinet00.nif'] = 'AC\\Anim_Dw_Cabinet.nif',
        ['o\\contain_chest10.nif'] = 'AC\\anim_chest10.nif',
    }
    if tes3.isLuaModActive("graphicHerbalism") then
        common.meshes_to_replace['f\\furn_shell00.nif'] = 'AC\\anim_kollop_01gh.nif'
        common.meshes_to_replace['f\\furn_shell10.nif'] = 'AC\\anim_kollop_02gh.nif'
        common.meshes_to_replace['f\\furn_shell20.nif'] = 'AC\\anim_kollop_03gh.nif'
    else
        common.meshes_to_replace['f\\furn_shell00.nif'] = 'AC\\anim_kollop_01.nif'
        common.meshes_to_replace['f\\furn_shell10.nif'] = 'AC\\anim_kollop_02.nif'
        common.meshes_to_replace['f\\furn_shell20.nif'] = 'AC\\anim_kollop_03.nif'
    end

    ---@type tes3container
    local unique = tes3.getObject('com_chest_Daed_crusher')
    -- unique levitating chest in Forgotten Vaults of Anudnabia
    if unique then
        ---@diagnostic disable-next-line: undefined-field
        common.meshes_to_replace[unique.model:lower()] = 'AC\\anim_daedric_chest.nif'
    end
end

local old_interop_priority = 999999999

local logmsgs = {
    add_old_interop_data = function(info, new_mesh, old_mesh)
        return [[adding old interop data...
    old mesh: %q
    new mesh: %q
    priority: %s
    animation info: %s
    ]], old_mesh, new_mesh, old_interop_priority, info
    end
    ,
    ---@param data herbert.AC.interop.add_custom_mesh_replacement.params
    add_new_interop_data = function(data)
        return [[adding custom mesh replacement
    old mesh: %q
    new mesh: %q
    priority: %s
    animation info: %s]], data.old_mesh, data.new_mesh, data.priority,
            data.animation_info
    end
    ,
    error_anim_str_bad = function(data)
        return "problem encountered when doing custom mesh replacements for %s.\z
            \n\tThe animation information for the specified key %q does not exist!",
            data.old_mesh, data.animation_info
    end
    ,

    warn_anim_info_not_cls = function(data)
        return "invalid input encountered when parsing mesh replacement for %q.\n\t\z
            animation info was a table, but not an instance of the `Animation_Info` class.\n\t\z
            trying to convert it manually, but this may cause problems.",
            data.old_mesh
    end
    ,
}

local function add_old_interop_data()
    --[[ format is
        KEY: old mesh path
        VALUE:
            1: new mesh path
            2: open animation group
            3: close animation group
            4: open animation length (seconds)
            5: close animation length (seconds)
            6: open sound
            7: close sound
            8: container height (for disable items check). In the original mod, 0 meant dont check collision and > 0 meant to use that number when checking for collision
                in the rewrite, numbers >0 will be converted to true, and numbers == 0 will be converted to false
    ]]

    local old_interop = include("MWCA.interop")
    if not old_interop then
        return
    end

    local priority = old_interop_priority

    log("adding old interop data")
    local interop = require("herbert100.animated containers.interop")
    local Animation_Info = require("herbert100.animated containers.Animation_Info")

    for old_mesh, data in pairs(old_interop) do
        local new_mesh, open_group, close_group, open_time, close_time, open_sound,
        close_sound, height = table.unpack(data)
        local info = Animation_Info.new {
            open_group = open_group,
            close_group = close_group,
            close_sound = close_sound,
            open_sound = open_sound,
            close_time = close_time,
            open_time = open_time,
            check_collisions = height and height > 0 or false,
        }
        -- set the priority really high so the new interop structure takes precedence
        interop.add_custom_mesh_replacement {
            animation_info = info,
            new_mesh = new_mesh,
            old_mesh = old_mesh,
            priority = priority,
        }
        log:trace(logmsgs.add_old_interop_data, info, new_mesh, old_mesh)
    end
    -- dont need this anymore
    log("clearing old interop table now that everything has been added.")
    table.clear(old_interop)
end


function common.add_interop_data()
    add_old_interop_data()
    local interop = require("herbert100.animated containers.interop")

    local Animation_Info = require("herbert100.animated containers.Animation_Info")

    -- =============================================================================
    -- NEW INTEROP
    -- =============================================================================

    -- sort by priority
    table.sort(interop.custom_mesh_replacements, function(a, b)
        return a.priority > b.priority
    end
    )

    local log_cfg = require("herbert100.animated containers.config").log_settings

    for _, data in ipairs(interop.custom_mesh_replacements) do
        if log_cfg.log_add_interop_data then
            log:trace(logmsgs.add_new_interop_data, data)
        end

        local anim_info
        if type(data.animation_info) == "string" then
            anim_info = common.animation_info[data.animation_info]
            if not anim_info then
                log:error(logmsgs.error_anim_str_bad, data)
                goto next_mesh
            end
        elseif getmetatable(data.animation_info) == Animation_Info then
            anim_info = data.animation_info
        else
            log:warn(logmsgs.warn_anim_info_not_cls, data)
            anim_info = Animation_Info.new(data.animation_info)
        end

        local index = table.find(common.animation_info, anim_info)

        if not index then
            index = #common.animation_info + 1
            common.animation_info[index] = anim_info
        end

        -- get the animation info for the corresponding index
        -- this has the effect of not creating duplicate entries containing the same data (if the index was found)
        anim_info = common.animation_info[index]

        -- add the mesh to the list of meshes to replace
        common.meshes_to_replace[data.old_mesh] = data.new_mesh

        -- associate the specified animation info to the new mesh
        local mesh_key = common._get_mesh_key(data.new_mesh)
        common.animation_info_by_mesh_key[mesh_key] = anim_info

        ::next_mesh::
    end
    -- dont need this anymore
    table.clear(interop.custom_mesh_replacements)
end

-- replaces the meshes of objects, so that they use the animated meshes instead.
-- you can change how meshes can replaced by altering the `interop.custom_meshes_to_replace` table.
function common.replace_meshes()
    local to_replace = common.meshes_to_replace
    local inspect = include('inspect')
    log:trace("replacing meshes with to_replace = %s",
        inspect and inspect.inspect or json.encode, to_replace)

    -- replace objects
    for obj in tes3.iterateObjects(tes3.objectType.container) do
        ---@cast obj tes3container
        local old_name = obj.model:lower()
        local new_name = to_replace[old_name]
        if new_name then
            log:trace("replacing model of %q\n\told: %q\n\tnew: %q", obj.id, obj.model,
                new_name)
            ---@diagnostic disable-next-line: inject-field
            obj.model = new_name
        end
    end
end

function common.initialize()
    log("adding interop data")
    common.add_interop_data()
    log("added interop data, now going to replace meshes")
    common.replace_meshes()
end

return common
