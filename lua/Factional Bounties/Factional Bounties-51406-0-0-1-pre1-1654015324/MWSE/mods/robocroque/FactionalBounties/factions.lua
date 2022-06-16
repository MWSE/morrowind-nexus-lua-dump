if factionalBounties == nil then
    factionalBounties = {}
end

if factionalBounties.factions == nil then
    factionalBounties.factions = {
        ['Great House Redoran'] = {
            tracksOwnCrimes = false,
            affiliatedFaction = 'Imperial Legion'
        },
        ['Thieves Guild'] = {
            tracksOwnCrimes = true
        },
        ['Temple'] = {
            tracksOwnCrimes = false,
            affiliatedFaction = 'Imperial Legion'
        },
        ['Imperial Cult'] = {
            tracksOwnCrimes = false,
            affiliatedFaction = 'Imperial Legion'
        },
        ['Imperial Knights'] = {
            tracksOwnCrimes = false,
            affiliatedFaction = 'Imperial Legion'
        },
        ['Great House Hlaalu'] = {
            tracksOwnCrimes = false,
            affiliatedFaction = 'Imperial Legion'
        },
        ['Great House Telvanni'] = {
            tracksOwnCrimes = false
        },
        ['Fighters Guild'] = {
            tracksOwnCrimes = false,
            affiliatedFaction = 'Imperial Legion'
        },
        ['Morag Tong'] = {
            tracksOwnCrimes = true
        },
        ['Ashlanders'] = {
            tracksOwnCrimes = false
        },
        ['Blades'] = {
            tracksOwnCrimes = false,
            affiliatedFaction = 'Imperial Legion'
        },
        ['Quarra Clan'] = {
            tracksOwnCrimes = true
        },
        ['Aundae Clan'] = {
            tracksOwnCrimes = true
        },
        ['Berne Clan'] = {
            tracksOwnCrimes = true
        },
        ['Camonna Tong'] = {
            tracksOwnCrimes = true
        },
        ['Imperial Legion'] = {
            tracksOwnCrimes = false
        },
        ['Mages Guild'] = {
            tracksOwnCrimes = false,
            affiliatedFaction = 'Imperial Legion'
        },
        ['Sixth House'] = {
            tracksOwnCrimes = true
        },
        ['Census and Excise Office'] = {
            tracksOwnCrimes = false,
            affiliatedFaction = 'Imperial Legion'
        },
        ['Twin Lamps'] = {
            tracksOwnCrimes = true
        },
        ['Nerevarine'] = {
            tracksOwnCrimes = true
        },
        ['Talos Cult'] = {
            tracksOwnCrimes = false,
            affiliatedFaction = 'Imperial Legion'
        },
        ['East Empire Company'] = {
            tracksOwnCrimes = false,
            affiliatedFaction = 'Imperial Legion'
        },
        ['Skaal'] = {
            tracksOwnCrimes = true
        },
        ['Royal Guard'] = {
            tracksOwnCrimes = false,
            affiliatedFaction = 'Imperial Legion'
        },
        ['Dark Brotherhood'] = {
            tracksOwnCrimes = true
        },
        ['Hands of Almalexia'] = {
            tracksOwnCrimes = true
        }
    }    
end

return factionalBounties.factions
