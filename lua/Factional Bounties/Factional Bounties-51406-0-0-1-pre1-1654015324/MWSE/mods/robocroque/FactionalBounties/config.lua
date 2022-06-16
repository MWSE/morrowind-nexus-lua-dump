local this = {}
-- TODO: make values configurable via MCM

this.debugMode = false

this.minimumAlarmToReportCrime = {
    ['attack'] = 5,
    ['killing'] = 5,
    ['stealing'] = 15,
    ['pickpocket'] = 15,
    ['theft'] = 15,
    ['trespass'] = 20,
}

this.minimumDispositionHit = 5

return this