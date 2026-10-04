-- ================= VEHICLE CONTROL MENU =================

local menuOpen = false
local leftIndicatorOn = false
local rightIndicatorOn = false
local hazardOn = false
local neonOn = false
local highBeamOn = false
local windowStates = {}
local interiorLightStates = {}

local function GetCurrentVehicle()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        return GetVehiclePedIsIn(ped, false)
    end
    return nil
end

local function CloseMenu()
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeVehicleMenu' })
end

RegisterCommand('togglevehiclemenu', function()
    local veh = GetCurrentVehicle()
    if not veh then
        TriggerEvent('chat:addMessage', { args = { 'Vehicle', 'You must be in a vehicle.' } })
        return
    end

    menuOpen = not menuOpen
    SetNuiFocus(menuOpen, menuOpen)

    if menuOpen then
        SendNUIMessage({ action = 'openVehicleMenu' })

        local maxPassengers = GetVehicleMaxNumberOfPassengers(veh)
        local seats = {}
        for i = -1, math.min(maxPassengers - 1, 14) do
            table.insert(seats, i)
        end
        
        local vehicleClass = GetVehicleClass(veh)
        local isBike = vehicleClass == 8
        local isBoat = vehicleClass == 14
        local isAircraft = vehicleClass == 15 or vehicleClass == 16
        
        SendNUIMessage({ action = 'vehicleSeats', seats = seats, isBoat = isBoat, isBike = isBike, isAircraft = isAircraft })
    else
        SendNUIMessage({ action = 'closeVehicleMenu' })
    end
end, false)

RegisterKeyMapping('togglevehiclemenu', 'Toggle Vehicle Menu', 'keyboard', 'F6')

-- Close when exiting vehicle
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        if menuOpen and not GetCurrentVehicle() then
            CloseMenu()
        end
    end
end)

-- NUI Callbacks
RegisterNUICallback('vehicleAction', function(data, cb)
    local veh = GetCurrentVehicle()
    if not veh then
        cb('no_vehicle')
        return
    end

    local action = data.type
    local index = tonumber(data.index)

    if action == 'window' then
        if index == nil or index < 0 or index > 3 then
            cb('invalid_index')
            return
        end

        windowStates[veh] = windowStates[veh] or {}
        local isOpen = windowStates[veh][index] == true
        if isOpen then
            RollUpWindow(veh, index)
            windowStates[veh][index] = false
        else
            RollDownWindow(veh, index)
            windowStates[veh][index] = true
        end
    elseif action == 'door' then
        if index == nil or index < 0 or index > 5 then
            cb('invalid_index')
            return
        end
        if GetVehicleDoorAngleRatio(veh, index) > 0.1 then
            SetVehicleDoorShut(veh, index, false)
        else
            SetVehicleDoorOpen(veh, index, false, false)
        end
    elseif action == 'hood' then
        if GetVehicleDoorAngleRatio(veh, 4) > 0.1 then
            SetVehicleDoorShut(veh, 4, false)
        else
            SetVehicleDoorOpen(veh, 4, false, false)
        end
    elseif action == 'trunk' then
        if GetVehicleDoorAngleRatio(veh, 5) > 0.1 then
            SetVehicleDoorShut(veh, 5, false)
        else
            SetVehicleDoorOpen(veh, 5, false, false)
        end
    elseif action == 'seat' then
        if index and IsVehicleSeatFree(veh, index) then
            TaskWarpPedIntoVehicle(PlayerPedId(), veh, index)
        end
    elseif action == 'engine' then
        SetVehicleEngineOn(veh, not GetIsVehicleEngineRunning(veh), false, true)
    elseif action == 'leftIndicator' then
        leftIndicatorOn = not leftIndicatorOn
        rightIndicatorOn = false
        hazardOn = false
        SetVehicleIndicatorLights(veh, 1, leftIndicatorOn)
        SetVehicleIndicatorLights(veh, 0, false)
    elseif action == 'rightIndicator' then
        rightIndicatorOn = not rightIndicatorOn
        leftIndicatorOn = false
        hazardOn = false
        SetVehicleIndicatorLights(veh, 0, rightIndicatorOn)
        SetVehicleIndicatorLights(veh, 1, false)
    elseif action == 'hazard' then
        hazardOn = not hazardOn
        leftIndicatorOn = false
        rightIndicatorOn = false
        SetVehicleIndicatorLights(veh, 0, hazardOn)
        SetVehicleIndicatorLights(veh, 1, hazardOn)
    elseif action == 'highbeam' then
        highBeamOn = not highBeamOn
        SetVehicleFullbeam(veh, highBeamOn)
    elseif action == 'neon' then
        neonOn = not neonOn
        for i = 0, 3 do
            SetVehicleNeonLightEnabled(veh, i, neonOn)
        end
    elseif action == 'interiorLight' then
        interiorLightStates[veh] = not interiorLightStates[veh]
        SetVehicleInteriorlight(veh, interiorLightStates[veh])
    elseif action == 'bombBay' then
        local vehicleClass = GetVehicleClass(veh)
        if vehicleClass ~= 15 and vehicleClass ~= 16 then
            cb('not_aircraft')
            return
        end
        if AreBombBayDoorsOpen(veh) then
            CloseBombBayDoors(veh)
        else
            OpenBombBayDoors(veh)
        end
    end

    cb('ok')
end)

RegisterNUICallback('closeVehicleMenu', function(data, cb)
    CloseMenu()
    cb('ok')
end)
