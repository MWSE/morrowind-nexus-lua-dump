--[[ Replacer - Echange MC items for 'vanilla' statics
 Part of Morrowind Crafting 3.0 - Toccatta and Drac, Dec 2021  ]]

local configPath = "Morrowind_Crafting_3"
local config = mwse.loadConfig(configPath)

local replace_list = require("Morrowind_Crafting_3.Replacer.recipes")
local mc = require("Morrowind_Crafting_3.mc_common")

local function singleDigit(pos)
    local num, idx, ln, str, tmp
    str = tostring(pos.x + pos.y + pos.z)
    ln = string.len(str)
    num = 1
    for idx = 1, ln, 1 do
        tmp = tonumber(string.sub(str, idx, idx))
        if (tmp == nil) then tmp = 0 end -- non-digit characters = 0
        if (tmp >= 0) and (tmp <= 9) then
            num = num + tmp
            if num>9 then
                num = num - 9
            end
        end
    end
    return num    
end

local function OnCellChanged(e)
    local thing, staticID, replaceID, item, xT, yT, zT, zR, xR, yR, newObj, newScale, abandoned, thingCheck
    local cell=tes3.getPlayerCell()

    abandoned = false
    for item in cell:iterateReferences(tes3.objectType.light) do
        if (item.baseObject.id == "mc_abandonedMarker") then
            abandoned = true
            break
        end
    end

    for item in cell:iterateReferences() do -- tes3.objectType.static
        for index, x in ipairs(replace_list) do
            thing = nil
            thing = item
            if thing then
                if thing.disabled ~= true then
			        staticID = thing.baseObject.id
                    replaceID = replace_list[index].newId
                    if ( abandoned == false) and (replace_list[index].altId == nil) then
                        replaceID = replaceID.."erm"
                    end
                    newScale = thing.scale
                    if (staticID == replace_list[index].id) then -- We have a match; replace old static with new item
                        if (singleDigit(thing.position) > 6) and (replace_list[index].altId ~= nil) then
                            replaceID = replace_list[index].altId
                        end
                        thingCheck = tes3.getObject(replaceID)
                        if (thingCheck ~= nil) and (staticID ~= replaceID) then
                            newObj = tes3.createReference{
                                object = replaceID,
                                position = thing.position:copy(),
                                orientation = thing.orientation:copy(),
                                cell = thing.cell,
                                scale = newScale
                            }
                            xT = newObj.position.x + replace_list[index].xtOffset
                            yT = newObj.position.y + replace_list[index].ytOffset
                            zT = newObj.position.z + replace_list[index].ztOffset
                            xR = math.rad(math.deg(newObj.orientation.x) + replace_list[index].xrOffset)
                            yR = math.rad(math.deg(newObj.orientation.y) + replace_list[index].yrOffset)
                            zR = math.rad(math.deg(newObj.orientation.z) + replace_list[index].zrOffset)
                            newObj.orientation = tes3vector3.new(xR, yR, zR)
                            newObj.position = tes3vector3.new(xT, yT, zT)
                            if (x.scale ~= nil) then
                                newObj.scale = x.scale * newScale
                            end
                            newObj:updateSceneGraph()
                            item:delete()
                        else
                            if staticID ~= replaceID then
                                mwse.log("[MC3 Init] Invalid ID, cannot replace \""..thing.id.."\" with \""..replaceID.."\"")
                            end
                        end
                    end
                end
            end
        end
    end

end
event.register("cellChanged", OnCellChanged)