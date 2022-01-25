local function attackShrine(e)
    local currentJ = tes3.getJournalIndex{ id = 'ss20_main' }
    if currentJ  == 40 then
        tes3.updateJournal {
            id =  'ss20_main',
            index = 50
        }
    elseif currentJ == 45 then
        tes3.updateJournal {
            id =  'ss20_main',
            index = 55
        }
    end
end
event.register("cellChanged", attackShrine)
