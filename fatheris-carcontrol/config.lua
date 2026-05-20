Config = {}

-- 'esx' 'qb'  
Config.Framework = 'esx'

Config.Keys = { -- Keybinds
    OpenMenu    = 'G',
    SignalLeft  = 'LEFT',
    SignalRight = 'RIGHT',
}

-- Set false to disable a feature entirely (hides it from UI too)
Config.Features = {
    Engine   = true,
    Seatbelt = true,
    Cruise   = true,
    Hazard   = true,
    Doors    = true,
    Windows  = true,
    Neons    = true,
    Signals  = true, 
}

Config.Seatbelt = {
    BlockExit = true, -- prevent exiting vehicle while seatbelt is on
}

Config.Cruise = {
    MinSpeed = 20.0, -- minimum km/h to enable cruise
}

Config.Signals = {
    AutoOffMs = 5000, -- auto turn off after ms, 0 = never
}