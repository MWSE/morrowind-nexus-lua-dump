local SupportTickets = {}

SupportTickets.scriptName = "SupportTickets"

SupportTickets.defaultData = {
    tickets = {},
    ticketId = 1,
    playerTickets = {}
}
SupportTickets.data = DataManager.loadData(SupportTickets.scriptName, SupportTickets.defaultData)

SupportTickets.defaultConfig = require("custom.SupportTickets.defaultConfig")
SupportTickets.config = DataManager.loadConfiguration(SupportTickets.scriptName, SupportTickets.defaultConfig)

SupportTickets.openTickets = {}

SupportTickets.adminActions = {}
SupportTickets.adminActionButtons = {}

--Utility functions
SupportTickets.getPlayerName = function(pid)
    return Players[pid].data.login.name:lower()
end

SupportTickets.getDateString = function(ticket)
    local s = ticket.dateString
    if s == nil then
        s = os.date(SupportTickets.config.dateFormat, ticket.time)

        if SupportTickets.config.saveDateString then
            ticket.dateString = s
        end
    end

    return s
end

--Ticket manipulation
SupportTickets.createTicket = function (pid, name, text)
    local playerName = SupportTickets.getPlayerName(pid)

    local id = SupportTickets.data.ticketId
    SupportTickets.data.ticketId = SupportTickets.data.ticketId + 1

    local loc = Players[pid].data.location

    SupportTickets.data.tickets[id] = {
        id = id,
        name = name,
        text = text,
        time = os.time(),
        playerName = playerName,
        location = {
            cell = loc.cell,
            x = loc.posX,
            y = loc.posY,
            z = loc.posZ
        },
        open = true
    }

    SupportTickets.data.playerTickets[playerName] = SupportTickets.data.playerTickets[playerName] or {}
    table.insert( SupportTickets.data.playerTickets[playerName], id )

    table.insert( SupportTickets.openTickets, id )
end

SupportTickets.closeTicket = function(id)
    if SupportTickets.data.tickets[id] ~= nil then
        SupportTickets.data.tickets[id].open = false
    end
end


--Allow user to create a ticket
SupportTickets.showCreateTicket = function(pid, data)
    data = data or { stage = 1 }

    if data.stage == 1 then
        GuiFramework.InputDialog({
            pid = pid,
            name = "SupportTicket_InputTicketName",
            label = SupportTickets.config.GUI.createTicket.nameLabel,
            callback = SupportTickets.callbackCreateTicket,
            parameters = data
        })

    elseif data.stage == 2 then
        GuiFramework.InputDialog({
            pid = pid,
            name = "SupportTicket_InputTicketText",
            label = SupportTickets.config.GUI.createTicket.textLabel,
            callback = SupportTickets.callbackCreateTicket,
            parameters = data
        })

    elseif data.stage == 3 then
        SupportTickets.createTicket(pid, data.name, data.text)

        GuiFramework.CustomMessageBox({
            pid = pid,
            name = "SupportTicket_InputTicketConfirmation",
            label = SupportTickets.config.GUI.createTicket.confirmLabel,
            buttons = {SupportTickets.config.GUI.ok}
        })
    end
end

SupportTickets.callbackCreateTicket = function(pid, name, input, data)
    if data.stage == 1 then
        data.name = input
    elseif data.stage == 2 then
        data.text = input
    end

    data.stage = data.stage + 1

    SupportTickets.showCreateTicket(pid, data)
end


--Show one ticket to an admin
SupportTickets.showAdminTicket = function(pid, id)
    local ticket = SupportTickets.data.tickets[id]

    local label = ''
    local buttons = {}
    local returnValues = {}

    if ticket.open then
        label = string.format(
            SupportTickets.config.GUI.showAdminTicket.label.open,
            ticket.name, ticket.playerName, SupportTickets.getDateString(ticket), ticket.text
        )
        table.insert(buttons, SupportTickets.config.GUI.showAdminTicket.buttons.close)
        table.insert(returnValues, "close")
    else
        label = string.format(
            SupportTickets.config.GUI.showAdminTicket.label.closed,
            ticket.name, ticket.playerName, SupportTickets.getDateString(ticket), ticket.text
        )
        table.insert(buttons, SupportTickets.config.GUI.showAdminTicket.buttons.open)
        table.insert(returnValues, "open")
    end

    for i, buttonLabel in ipairs(SupportTickets.adminActionButtons) do
        table.insert(buttons, buttonLabel)
        table.insert(returnValues, i)
    end

    table.insert(buttons, SupportTickets.config.GUI.ok)
    table.insert(returnValues, "ok")

    GuiFramework.CustomMessageBox({
        pid = pid,
        name = "SupportTicket_AdminTicket",
        label = label,
        buttons = buttons,
        returnValues = returnValues,
        callback = SupportTickets.callbackAdminTicket,
        parameters = id
    })
end

SupportTickets.registerAdminAction = function(buttonLabel, callback)
    table.insert( SupportTickets.adminActions, callback )
    table.insert( SupportTickets.adminActionButtons, buttonLabel )
end

SupportTickets.callbackAdminTicket = function(pid, name, input, value, id)
    if type(value) == "number" then
        local callback = SupportTickets.adminActions[value]
        if callback ~= nil then
            callback(pid, SupportTickets.data.tickets[id])
        end
        return
    end
    if value == "close" then
        SupportTickets.data.tickets[id].open = false

        GuiFramework.CustomMessageBox({
            pid = pid,
            name = "SupportTicket_AdminTicketClose",
            label = SupportTickets.config.GUI.showAdminTicket.alerts.closed,
            buttons = {SupportTickets.config.GUI.showAdminTicket.buttons.back, SupportTickets.config.GUI.ok},
            returnValues = {"back", "ok"},
            callback = SupportTickets.callbackAdminTicket,
            parameters = id
        })
    elseif value == "open" then
        SupportTickets.data.tickets[id].open = true

        GuiFramework.CustomMessageBox({
            pid = pid,
            name = "SupportTicket_AdminTicketOpen",
            label = SupportTickets.config.GUI.showAdminTicket.alerts.open,
            buttons = {SupportTickets.config.GUI.showAdminTicket.buttons.back, SupportTickets.config.GUI.ok},
            returnValues = {"back", "ok"},
            callback = SupportTickets.callbackAdminTicket,
            parameters = id
        })
    elseif value == "back" then
        SupportTickets.showAdminTicket(pid, id)
    end
end

--Show one ticket to a player
SupportTickets.showPlayerTicket = function(pid, id)
    local ticket = SupportTickets.data.tickets[id]

    local label = ''
    local buttons = {}
    local returnValues = {}

    if ticket.open then
        label = string.format(
            SupportTickets.config.GUI.showPlayerTicket.label.open,
            ticket.name, ticket.playerName, SupportTickets.getDateString(ticket), ticket.text
        )
        table.insert(buttons, SupportTickets.config.GUI.showPlayerTicket.buttons.close)
        table.insert(returnValues, "close")
    else
        label = string.format(
            SupportTickets.config.GUI.showPlayerTicket.label.closed,
            ticket.name, ticket.playerName, SupportTickets.getDateString(ticket), ticket.text
        )
    end

    table.insert(buttons, SupportTickets.config.GUI.ok)
    table.insert(returnValues, "ok") 

    GuiFramework.CustomMessageBox({
        pid = pid,
        name = "SupportTicket_PlayerTicket",
        label = label,
        buttons = buttons,
        returnValues = returnValues,
        callback = SupportTickets.callbackPlayerTicket,
        parameters = id
    })
end

SupportTickets.callbackPlayerTicket = function(pid, name, input, value, id)
    if value == "close" then
        SupportTickets.data.tickets[id].open = false

        GuiFramework.CustomMessageBox({
            pid = pid,
            name = "SupportTicket_PlayerTicketClose",
            label = SupportTickets.config.GUI.showPlayerTicket.alerts.closed,
            buttons = {SupportTickets.config.GUI.showPlayerTicket.buttons.back, SupportTickets.config.GUI.ok},
            returnValues = {"back", "ok"},
            callback = SupportTickets.callbackPlayerTicket,
            parameters = id
        })
    elseif value == "back" then
        SupportTickets.showPlayerTicket(pid, id)
    end
end


--Turn a list of ticket ids into rows and return values for ListBox
SupportTickets.renderTicketList = function(ids, page)
    local n = #ids
    local totalPages = math.ceil( n * 1.0 / SupportTickets.TICKETS_PER_PAGE )

    local rows = {}
    local returnValues = {}

    local from = 1 + (page - 1) * SupportTickets.TICKETS_PER_PAGE
    local to = math.min(n, page * SupportTickets.TICKETS_PER_PAGE)

    for i = from, to do
        local id = ids[i]
        local ticket = SupportTickets.data.tickets[id]
        table.insert( rows, string.format(
            ticket.open and SupportTickets.config.GUI.renderTickets.rows.open or SupportTickets.config.GUI.renderTickets.rows.closed,
            ticket.name, SupportTickets.getDateString(ticket)
        ))
        table.insert( returnValues, id )
    end

    for i = 1, SupportTickets.TICKETS_PER_PAGE - #rows do
        table.insert( rows, "" )
        table.insert( returnValues, -1 )
    end

    --Add previous page button if necsesary
    if page > 1 then
        table.insert( rows, SupportTickets.config.GUI.renderTickets.buttons.previous )
        table.insert( returnValues, { page = page, change = -1 } )
    else
        table.insert( rows, "" )
        table.insert( returnValues, -1 )
    end

    --Add next page button if necsesary
    if page < totalPages then
        table.insert( rows, SupportTickets.config.GUI.renderTickets.buttons.next )
        table.insert( returnValues, { page = page, change = 1 } )
    else
        table.insert( rows, "" )
        table.insert( returnValues, -1 )
    end

    --Add First page button if necessary+
    if page > 1 then
        table.insert( rows, SupportTickets.config.GUI.renderTickets.buttons.first )
        table.insert( returnValues, { page = page, change = -100 } )
    else
        table.insert( rows, "" )
        table.insert( returnValues, -1 )
    end

    --Add last page button if necessary+
    if page < totalPages then
        table.insert( rows, SupportTickets.config.GUI.renderTickets.buttons.last )
        table.insert( returnValues, { page = page, change = 100 } )
    else
        table.insert( rows, "" )
        table.insert( returnValues, -1 )
    end

    return {
        rows = rows,
        returnValues = returnValues
    }
end

SupportTickets.TICKETS_PER_PAGE = SupportTickets.config.ticketsPerPage

--Show a player's ticket list
SupportTickets.showPlayerTickets = function(pid, page, playerName)
    if playerName == nil then
        playerName = SupportTickets.getPlayerName(pid)
    end

    local ids = tableHelper.shallowCopy(SupportTickets.data.playerTickets[playerName])
    if ids ~= nil then
        tableHelper.cleanNils(ids);
    end

    if ids == nil or #ids == 0 then
        GuiFramework.CustomMessageBox({
            pid = pid,
            name = "SupportTickets_PlayerTicketsWrongName",
            label = string.format(SupportTickets.config.GUI.showPlayerTickets.alerts.noTickets, playerName),
            buttons = {"OK"}
        })
        return
    end
    
    local render = SupportTickets.renderTicketList(ids, page)

    local totalPages = math.ceil( #ids * 1.0 / SupportTickets.TICKETS_PER_PAGE )

    GuiFramework.ListBox({
        pid = pid,
        name = "SupportTickets_PlayerTickets",
        label = string.format(SupportTickets.config.GUI.showPlayerTickets.label, playerName, page, totalPages),
        rows = render.rows,
        returnValues = render.returnValues,
        callback = SupportTickets.callbackPlayerTickets,
        parameters = {
            lastPage = totalPages,
            playerName = playerName
        }
    })
end

SupportTickets.callbackPlayerTickets = function(pid, name, input, value, parameters)
    local t = type(value)

    if t == 'table' then
        local page = value.page
        if value.change == 1 then
            page = page + 1
        elseif value.change == -1 then
            page = page - 1
        elseif value.change == -100 then
            page = 1
        elseif value.change == 100 then
            page = parameters.lastPage
        end

        SupportTickets.showPlayerTickets(pid, page, parameters.playerName)

    elseif t == 'number' then
        if value >= 1 and value < SupportTickets.data.ticketId then
            if Players[pid].data.settings.staffRank > SupportTickets.config.ticketManagementRank then
                SupportTickets.showAdminTicket(pid, value)
            else
                SupportTickets.showPlayerTicket(pid, value)
            end
        end
    end
end


--Show list of open tickets for admins

SupportTickets.updateOpenTickets = function()
    --Remove closed tickets
    for i = 1, #SupportTickets.openTickets do
        local id = SupportTickets.openTickets[i]
        if SupportTickets.data.tickets[id] == nil or (not SupportTickets.data.tickets[id].open) then
            SupportTickets.openTickets[i] = nil
        end
    end
    tableHelper.cleanNils(SupportTickets.openTickets)

    --Sort by time, newest first
    table.sort(SupportTickets.openTickets, function(a, b)
        local ticketA = SupportTickets.data.tickets[a]
        local ticketB = SupportTickets.data.tickets[a]

        return ticketA.time > ticketB.time
    end)

    return SupportTickets.openTickets
end

SupportTickets.showOpenTickets = function(pid, page)
    if #SupportTickets.openTickets == 0 then
        GuiFramework.CustomMessageBox({
            pid = pid,
            name = "SupportTickets_OpenTickets",
            label = SupportTickets.config.GUI.showOpenTickets.alerts.noTickets,
            buttons = {"Ok"}
        })

        return
    end

    page = page or 1

    local openTickets = SupportTickets.updateOpenTickets()

    local rows = {}
    local returnValues = {}

    local ids = {}

    for i = 1, #openTickets do
        local id = openTickets[i]
        table.insert(ids, id)
    end

    if #ids == 0 then
        GuiFramework.CustomMessageBox({
            pid = pid,
            name = "SupportTickets_OpenTickets",
            label = SupportTickets.config.GUI.showOpenTickets.alerts.emptyPage,
            buttons = {"Ok"}
        })

        return
    end

    local totalPages = math.ceil( #ids * 1.0 / SupportTickets.TICKETS_PER_PAGE )

    local render = SupportTickets.renderTicketList(ids, page, totalPages)

    
    GuiFramework.ListBox({
        pid = pid,
        name = "SupportTickets_OpenTickets",
        label = string.format(SupportTickets.config.GUI.showOpenTickets.label, page, totalPages),
        rows = render.rows,
        returnValues = render.returnValues,
        callback = SupportTickets.callbackOpenTickets,
        parameters = {
            lastPage = totalPages
        }
    })
end

SupportTickets.callbackOpenTickets = function(pid, name, input, value, parameters)
    local t = type(value)

    if t == 'table' then
        local page = value.page
        if value.change == 1 then
            page = page + 1
        elseif value.change == -1 then
            page = page - 1
        elseif value.change == -100 then
            page = 1
        elseif value.change == 100 then
            page = parameters.lastPage
        end

        SupportTickets.showOpenTickets(pid, page)

    elseif t == 'number' then
        if value >= 1 and value < SupportTickets.data.ticketId then
            SupportTickets.showAdminTicket(pid, value)
        end
    end
end


--Registering commands
customCommandHooks.registerCommand("ticket", function(pid, cmd)
    SupportTickets.showCreateTicket(pid)
end)

customCommandHooks.registerCommand("tickets", function(pid, cmd)
    if Players[pid].data.settings.staffRank > SupportTickets.config.ticketManagementRank then
        if cmd[2] == nil then
            SupportTickets.showOpenTickets(pid)
        else
            SupportTickets.showPlayerTickets(pid, 1, cmd[2])
        end
    else
        SupportTickets.showPlayerTickets(pid, 1)
    end
end)

--Handle events

customEventHooks.registerHandler("OnServerPostInit", function(eventStatus)
    for id, ticket in pairs(SupportTickets.data.tickets) do
        if ticket.open then
            table.insert( SupportTickets.openTickets, id )
        end
    end
end)

customEventHooks.registerHandler("OnServerExit", function(eventStatus)
    DataManager.saveData(SupportTickets.scriptName, SupportTickets.data)
    DataManager.saveConfiguration(SupportTickets.scriptName, SupportTickets.config)
end)

return SupportTickets