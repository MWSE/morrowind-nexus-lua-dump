return {
    {
        key = 'i_MaxPockets',
        renderer = 'number',
        name = 'ConfigPocketMaxPockets',
        description = 'ConfigPocketMaxPocketsDesc',
        argument = {
            integer = true,
            min = 0,
        },
        default = 5,
    },
    {
        key = 'f_CapacityMultiplier',
        renderer = 'number',
        name = 'ConfigPocketCapacityMultiplier',
        description = 'ConfigPocketCapacityMultiplierDesc',
        argument = {
            min = 0.0,
        },
        default = 1.0,
    },
}