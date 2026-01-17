local REGIONS = {
    Morrowind = {
        Vvardenfell = {
            ['Western Vvardenfell'] = {
                ['ascadian isles region'] = true,
                ['bitter coast region'] = true,
                ['west gash region'] = true,
            },
            ['Vvardenfell Ashlands'] = {
                ['ashlands region'] = true,
                ['molag mar region'] = true,
                ['red mountain region'] = true,
            },
            ['Eastern Vvardenfell'] = {
                ['azura\'s coast region'] = true,
                ['grazelands region'] = true,
            },
            ['Northern Vvardenfell'] = {
                ['sheogorad'] = true,
            },
        },
        ['Mainland Morrowind'] = {
            ['Deshaan District'] = {

            },
            ['Mournhold District'] = {
                ['aanthirin region'] = true,
                ['alt orethan region'] = true,
                ['lan orethan region'] = true,
                ['mephalan vales region'] = true,
                ['nedothril region'] = true,
                ['old ebonheart region'] = true,
                ['sacred lands region'] = true,
                ['sundered scar region'] = true,
            },
            ['Narsis District'] = {
                ['othreleth woods region'] = true,
                ['shipal-shin region'] = true,
                ['thirr valley region'] = true,
            },
            ['Telvannis District'] = {
                ['boethiah\'s spine region'] = true,
                ['dagon urul region'] = true,
                ['molag ruhn region'] = true,
                ['molagreahd region'] = true,
                ['telvanni isles region'] = true,
            },
            ['Velothis District'] = {
                ['armun ashlands region'] = true,
                ['clambering moor region'] = true,
                ['roth roryn region'] = true,
                ['velothi mountains region'] = true,
            },
        },
        Solstheim = {
            ['Solstheim Island'] = {
                ['brodir grove region'] = true,
                ['felsaad coast region'] = true,
                ['hirstaang forest region'] = true,
                ['isinfier plains region'] = true,
                ['moesring mountains region'] = true,
                ['thirsk region'] = true,
            }
        }
    },
    Cyrodiil = {
        Colovia = {
            ['Kingdom of Anvil'] = {
                ['gold coast region'] = true, -- internal ID for Strident Coast region
                ['dasek marsh region'] = function(x, y)
                    return x <= -110
                end,
            },
            ['Kingdom of Sutch'] = {
                ['gilded hills region'] = true, -- internal ID for Brennan Bluffs Region
            },
            ['Kingdom of Kvatch'] = {
                ['dasek marsh region'] = function(x, y)
                    return x > -110 and x <= -97
                end,
            },
            ['Kingdom of Skingrad'] = {
                ['dasek marsh region'] = function(x, y)
                    return x > -97
                end,
            }
        },
        Nibenay = {

        },
        Abecean = {
            ['Kingdom of Anvil'] = {
                ['stirk isle region'] = true,
            },
            ['Uninhabited'] = {
                ['abecean sea region'] = true,
            }
        }
    },
    Skyrim = {
        ['Western Skyrim'] = {
            ['The Reach'] = {
                ['druadach highlands region'] = true,
                ['lorchwuir heath region'] = true,
                ['midkarth region'] = true,
                ['sundered hills region'] = true,
                ['vorndgad forest region'] = true,
            },
            ['Haafinheim'] = {
                ['falkheim region'] = true,
            }
        },
    },
    Hammerfell = {
        ['Eastern Hammerfell'] = {
            ['Republic of Dragonstar'] = {
                ['druadach highlands region'] = function(x, y)
                    return x <= -117 and y <= 10
                end,
            }
        }
    }
}

local REGIONS_LOOKUP = {}
do
    -- Map each region to the hierarchy: Province -> Territory -> District -> Region
    for province, territories in pairs(REGIONS) do
        for territory, districts in pairs(territories) do
            for district, regions in pairs(districts) do
                for region, condition in pairs(regions) do
                    REGIONS_LOOKUP[region] = REGIONS_LOOKUP[region] or {}
                    table.insert(REGIONS_LOOKUP[region], {
                        province = province,
                        territory = territory,
                        district = district,
                        condition = condition, -- This can be a function or a boolean
                    })
                end
            end
        end
    end

    for _, hierarchy in pairs(REGIONS_LOOKUP) do
        table.sort(hierarchy, function(a, b)
            local a_is_func = type(a.condition) == "function"
            local b_is_func = type(b.condition) == "function"
            
            if a_is_func and not b_is_func then
                return true -- Functions should come first, so more specific conditions are prioritized over fallbacks
            end

            return false
        end)
    end
end

return REGIONS_LOOKUP