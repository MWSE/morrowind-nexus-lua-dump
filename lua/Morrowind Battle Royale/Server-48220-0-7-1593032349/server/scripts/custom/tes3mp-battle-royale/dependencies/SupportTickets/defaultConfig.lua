return {
    ticketManagementRank = 1,
    ticketsPerPage = 11,
    saveDateString = true,
    dateFormat = "%y/%m/%d %H:%M",
    GUI = {
        ok = "Ok",
        createTicket = {
            nameLabel = "Input a short description",
            textLabel = "Input a detailed description",
            confirmLabel = "Ticket was successfully created!"
        },
        showAdminTicket = {
            buttons = {
                close = "Close ticket",
                open = "Open ticket",
                back = "Back"
            },
            label = {
                open = "Open ticket \"%s\" by %s at %s\n %s",
                closed = "Closed ticket \"%s\" by %s at %s\n %s"
            },
            alerts = {
                closed = "Ticket closed!",
                open = "Ticket open!"
            }
        },
        showPlayerTicket = {
            buttons = {
                close = "Close ticket",
                back = "Back"
            },
            label = {
                open = "Open ticket \"%s\" at %s\n %s",
                closed = "Closed ticket \"%s\" at %s\n %s"
            },
            alerts = {
                closed = "Ticket closed!",
            }
        },
        renderTickets = {
            rows = {
                open = "O %s %s",
                closed = "X %s %s"
            },
            buttons = {
                previous = "-==Previous page==-",
                next = "-==Next page==-",
                first = "-==First Page==-",
                last = "-==Last Page==-"
            }
        },
        showPlayerTickets = {
            alerts = {
                noTickets = "No tickets found for %s!",

            },
            label = "%s's tickets %d/%d"
        },
        showOpenTickets = {
            alerts = {
                noTickets = "No open tickets!",
                emptyPage = "No open tickets on this page!",

            },
            label = "Open tickets %d/%d"
        }
    }
}