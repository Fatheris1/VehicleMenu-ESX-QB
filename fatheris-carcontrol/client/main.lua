local isMenuOpen      = false
local seatbeltOn      = false
local cruiseControlOn = false
local hazardOn        = false
local signalLeft      = false
local signalRight     = false
local signalLeftTimer  = 0
local signalRightTimer = 0
local smoothTemp      = 20.0

local ESX    = nil
local QBCore = nil

Citizen.CreateThread(function()
    if Config.Framework == 'esx' then
        while ESX == nil do
            if GetResourceState('es_extended') == 'started' then
                if exports['es_extended'] and exports['es_extended'].getSharedObject then
                    ESX = exports['es_extended']:getSharedObject()
                else
                    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
                end
            end
            Citizen.Wait(500)
        end
    elseif Config.Framework == 'qb' then
        while QBCore == nil do
            if GetResourceState('qb-core') == 'started' then
                QBCore = exports['qb-core']:GetCoreObject()
            end
            Citizen.Wait(500)
        end
    end
end)

local function getVehicle()
    return GetVehiclePedIsIn(PlayerPedId(), false)
end

Citizen.CreateThread(function()
    if not Config.Features.Seatbelt then return end
    while true do
        Citizen.Wait(0)
        local vehicle = getVehicle()
        if vehicle ~= 0 then
            if seatbeltOn and Config.Seatbelt.BlockExit then
                DisableControlAction(0, 75, true)
            end
        elseif seatbeltOn then
            seatbeltOn = false
            SendNUIMessage({ type = 'updateSeatbelt', status = false })
        end
    end
end)

local function setSignal(left, right)
    signalLeft  = left
    signalRight = right
    local vehicle = getVehicle()
    if vehicle ~= 0 then
        SetVehicleIndicatorLights(vehicle, 1, left)
        SetVehicleIndicatorLights(vehicle, 0, right)
    end
    SendNUIMessage({ type = 'signal', left = left, right = right })
end

Citizen.CreateThread(function()
    if not Config.Features.Signals then return end
    while true do
        Citizen.Wait(200)
        local now = GetGameTimer()

        if Config.Signals.AutoOffMs > 0 then
            if signalLeft  and signalLeftTimer  > 0 and now > signalLeftTimer  then
                setSignal(false, false)
                signalLeftTimer = 0
            end
            if signalRight and signalRightTimer > 0 and now > signalRightTimer then
                setSignal(false, false)
                signalRightTimer = 0
            end
        end

        if hazardOn and (signalLeft or signalRight) then
            signalLeft  = false
            signalRight = false
            SendNUIMessage({ type = 'signal', left = false, right = false })
        end
    end
end)

Citizen.CreateThread(function()
    local idleTarget  = 95.0
    local driveTarget = 82.0
    local offTarget   = 20.0
    local riseRate    = 0.0008
    local coolRate    = 0.0003

    while true do
        Citizen.Wait(100)
        local vehicle = getVehicle()

        if vehicle ~= 0 then
            local speed  = GetEntitySpeed(vehicle) * 3.6
            local target = GetIsVehicleEngineRunning(vehicle)
                and (speed > 10.0 and driveTarget or idleTarget)
                or offTarget
            local rate   = target > smoothTemp and riseRate or coolRate
            smoothTemp   = smoothTemp + (target - smoothTemp) * rate
        else
            smoothTemp = smoothTemp + (offTarget - smoothTemp) * coolRate
        end

        if isMenuOpen then
            SendNUIMessage({ type = 'updateTemp', temp = smoothTemp })
        end
    end
end)

local function openMenu()
    local vehicle = getVehicle()
    if vehicle == 0 then return end

    isMenuOpen = true
    SetNuiFocus(true, true)

    local doors, windows, neons = {}, {}, {}
    for i = 0, 5 do doors[i]   = GetVehicleDoorAngleRatio(vehicle, i) > 0.0 end
    for i = 0, 3 do windows[i] = not IsVehicleWindowIntact(vehicle, i) end
    for i = 0, 3 do neons[i]   = IsVehicleNeonLightEnabled(vehicle, i) end

    SendNUIMessage({
        type  = 'toggleMenu',
        state = true,
        data  = {
            features   = Config.Features,
            engine     = GetIsVehicleEngineRunning(vehicle),
            seatbelt   = seatbeltOn,
            cruise     = cruiseControlOn,
            hazard     = hazardOn,
            engineTemp = smoothTemp,
            model      = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
            plate      = GetVehicleNumberPlateText(vehicle):match("^%s*(.-)%s*$"),
            doors      = doors,
            windows    = windows,
            neons      = neons,
        }
    })
end

local function closeMenu()
    isMenuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'toggleMenu', state = false })
end

RegisterKeyMapping('openvehmenu', 'Open vehicle control menu', 'keyboard', Config.Keys.OpenMenu)
RegisterKeyMapping('signalleft',  'Left turn signal',          'keyboard', Config.Keys.SignalLeft)
RegisterKeyMapping('signalright', 'Right turn signal',         'keyboard', Config.Keys.SignalRight)

-- Call me back :)
RegisterCommand('openvehmenu', function()
    if isMenuOpen then closeMenu() else openMenu() end
end, false)

RegisterCommand('signalleft', function()
    if not Config.Features.Signals or getVehicle() == 0 then return end
    if signalLeft then
        setSignal(false, false)
        signalLeftTimer = 0
    else
        setSignal(true, false)
        signalLeftTimer = Config.Signals.AutoOffMs > 0 and (GetGameTimer() + Config.Signals.AutoOffMs) or 0
    end
end, false)

RegisterCommand('signalright', function()
    if not Config.Features.Signals or getVehicle() == 0 then return end
    if signalRight then
        setSignal(false, false)
        signalRightTimer = 0
    else
        setSignal(false, true)
        signalRightTimer = Config.Signals.AutoOffMs > 0 and (GetGameTimer() + Config.Signals.AutoOffMs) or 0
    end
end, false)

RegisterNUICallback('closeMenu', function(_, cb)
    closeMenu()
    cb('ok')
end)

RegisterNUICallback('toggleEngine', function(_, cb)
    local vehicle = getVehicle()
    if not Config.Features.Engine or vehicle == 0 then cb({}) return end
    local on = GetIsVehicleEngineRunning(vehicle)
    SetVehicleEngineOn(vehicle, not on, false, true)
    cb({ status = not on })
end)

RegisterNUICallback('toggleSeatbelt', function(_, cb)
    if not Config.Features.Seatbelt then cb({}) return end
    seatbeltOn = not seatbeltOn
    cb({ status = seatbeltOn })
end)

RegisterNUICallback('toggleCruise', function(_, cb)
    local vehicle = getVehicle()
    if not Config.Features.Cruise or vehicle == 0 then cb({}) return end

    cruiseControlOn = not cruiseControlOn

    if cruiseControlOn then
        local speed = GetEntitySpeed(vehicle) * 3.6
        if speed < Config.Cruise.MinSpeed then
            cruiseControlOn = false
            cb({ status = false })
            return
        end
        SetVehicleMaxSpeed(vehicle, GetEntitySpeed(vehicle))
    else
        SetVehicleMaxSpeed(vehicle, 500.0)
    end

    cb({ status = cruiseControlOn })
end)

RegisterNUICallback('toggleDoor', function(data, cb)
    local vehicle = getVehicle()
    if not Config.Features.Doors or vehicle == 0 then cb({}) return end
    local idx  = data.doorIndex
    local open = GetVehicleDoorAngleRatio(vehicle, idx) > 0.0
    if open then SetVehicleDoorShut(vehicle, idx, false)
    else SetVehicleDoorOpen(vehicle, idx, false, false) end
    cb({ open = not open })
end)

RegisterNUICallback('toggleWindow', function(data, cb)
    local vehicle = getVehicle()
    if not Config.Features.Windows or vehicle == 0 then cb({}) return end
    local idx    = data.windowIndex
    local intact = IsVehicleWindowIntact(vehicle, idx)
    if intact then RollDownWindow(vehicle, idx) else RollUpWindow(vehicle, idx) end
    cb({ open = intact })
end)

RegisterNUICallback('toggleNeon', function(data, cb)
    local vehicle = getVehicle()
    if not Config.Features.Neons or vehicle == 0 then cb({}) return end
    local idx = data.neonIndex
    local on  = IsVehicleNeonLightEnabled(vehicle, idx)
    SetVehicleNeonLightEnabled(vehicle, idx, not on)
    cb({ status = not on })
end)

RegisterNUICallback('toggleHazard', function(_, cb)
    local vehicle = getVehicle()
    if not Config.Features.Hazard or vehicle == 0 then cb({}) return end
    hazardOn = not hazardOn
    SetVehicleIndicatorLights(vehicle, 1, hazardOn)
    SetVehicleIndicatorLights(vehicle, 0, hazardOn)
    SendNUIMessage({ type = 'signal', left = hazardOn, right = hazardOn })
    cb({ hazard = hazardOn })
end)