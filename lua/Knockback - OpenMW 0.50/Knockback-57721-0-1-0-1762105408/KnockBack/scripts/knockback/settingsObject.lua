local o = {
        showTrail = {
                key = 'showTrail',
                name = 'Show knockback trail',
                value = true,
                default = true,
        },
        knockbackMagnitude = {
                key = 'knockbackMagnitude',
                name = 'Knockback amount',
                description = 'default = 45',
                value = 45,
                default = 45,
        },
        verticalKnockFactor = {
                key = 'verticalKnockFactor',
                name = 'Vertical knockback factor',
                description = 'default = 1 (0 - 1)',
                value = 1,
                default = 1,
                argument = {
                        min = 0,
                        max = 1,
                        integer = false,
                },
        },
        bounceAmount = {
                key = 'bounceAmount',
                name = 'Bounce amount ',
                description = 'default = 0.4 (0 - 1)',
                value = 0.4,
                default = 0.4,
                argument = {
                        min = 0,
                        max = 1,
                        integer = false,
                },
        },
        maxBounces = {
                key = 'maxBounces',
                name = 'Maximum number of bounces ',
                description = 'default = 4',
                value = 4,
                default = 4,
                argument = {
                        min = 0,
                        integer = true
                },
        },
        adjustByAttackPower = {
                key = 'adjustByAttackPower',
                name = 'Adjust knockback amount by attack power (wind up) ',
                value = true,
                default = true,
        },
}

return {
        o = o,
}
