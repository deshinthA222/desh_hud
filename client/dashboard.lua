-- ================= VEHICLE DASHBOARD =================
-- Polls vehicle data and sends to NUI dashboard
-- Features: Speed, RPM, Fuel, Temp, Gear, Indicators, Warnings

local showDashboard = true
local updateInterval = 100
local lastVehicle = 0
local lastCoords = nil
local odometerKm = 0.0
local odometerKey = nil
local lastOdometerSave = 0
local seatbeltOn = false
local hudSettingsOpen = false
local trackedLightVehicle = 0
local trackedLightMode = 0 -- 0=off, 1=low beam, 2=high beam
local lightInputActive = false

-- Capture the headlight key every frame so the 100 ms dashboard poll cannot
-- miss a quick press. This also supplies the LOW state on artifacts where
-- GetVehicleLightsState only reports OFF/HIGH reliably.
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(lightInputActive and 10 or 150)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            lightInputActive = true
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= trackedLightVehicle then
                trackedLightVehicle = veh
                trackedLightMode = 0
            end
            if IsControlJustPressed(0, 74) then -- INPUT_VEH_HEADLIGHT
                -- Requested H-key order: OFF -> HIGH -> LOW -> OFF.
                if trackedLightMode == 0 then
                    trackedLightMode = 2
                elseif trackedLightMode == 2 then
                    trackedLightMode = 1
                else
                    trackedLightMode = 0
                end
            end
        else
            lightInputActive = false
            trackedLightVehicle = 0
            trackedLightMode = 0
        end
    end
end)

RegisterCommand('hudsettings', function()
    hudSettingsOpen = not hudSettingsOpen
    SetNuiFocus(hudSettingsOpen, hudSettingsOpen)
    SendNUIMessage({ action = hudSettingsOpen and 'openHudSettings' or 'closeHudSettings' })
end, false)

RegisterNUICallback('closeHudSettings', function(_, cb)
    hudSettingsOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeHudSettings' })
    cb('ok')
end)

RegisterCommand('togglehudseatbelt', function()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then return end

    local veh = GetVehiclePedIsIn(ped, false)
    local vehicleClass = GetVehicleClass(veh)
    if vehicleClass == 8 or vehicleClass == 13 or vehicleClass == 14 or vehicleClass == 15 or vehicleClass == 16 then
        return
    end

    seatbeltOn = not seatbeltOn
    SendNUIMessage({ action = 'seatbeltUpdate', enabled = seatbeltOn, visible = true })
end, false)

RegisterKeyMapping('togglehudseatbelt', 'Toggle Seatbelt (HUD icon only)', 'keyboard', 'B')

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(updateInterval)
        
        if not showDashboard then goto continue end

        local ped = PlayerPedId()
        if not IsPedInAnyVehicle(ped, false) then
            seatbeltOn = false
            SendNUIMessage({ action = 'dashboardHide' })
            SendNUIMessage({ action = 'seatbeltUpdate', enabled = false, visible = false })
            goto continue
        end

        local veh = GetVehiclePedIsIn(ped, false)

        -- Aircraft and boats use their own HUDs; keep the road dashboard hidden.
        local vehicleClass = GetVehicleClass(veh)
        if IsPedInAnyPlane(ped) or vehicleClass == 14 or vehicleClass == 15 then
            SendNUIMessage({ action = 'dashboardHide' })
            goto continue
        end

        SendNUIMessage({ action = 'dashboardShow' })

        -- Speed conversion
        local speed = GetEntitySpeed(veh) * 3.6 -- m/s to km/h
        
        -- RPM (0-8000, some vehicles may exceed)
        local rpm = math.floor(GetVehicleCurrentRpm(veh) * 10000)
        
        -- Fuel (0-100%)
        local fuel = GetVehicleFuelLevel(veh)
        
        -- Temperature (simplified: 50-110°C based on engine health)
        local engineHealth = GetVehicleEngineHealth(veh)
        local temp = 50 + (100 - (engineHealth / 10)) * 0.6
        
        -- Gear (N, 1, 2, 3, 4, 5, 6, R)
        local gear = GetVehicleCurrentGear(veh)
        local gearDisplay = 'N'
        if gear == 0 then
            gearDisplay = GetEntitySpeedVector(veh, true).y < -0.1 and 'R' or 'N'
        elseif gear > 0 then
            gearDisplay = tostring(gear)
        end
        
        -- Engine running
        local engineRunning = GetIsVehicleEngineRunning(veh)
        
        -- Indicators & Lights
        -- Do not derive the displayed mode from GTA daytime-running lights:
        -- several vehicles report LOW even while the driver selected OFF.
        -- The H-key state machine is the single source of truth for this icon.
        local lowbeamOn = trackedLightMode == 1
        local highbeamsOn = trackedLightMode == 2
        local indicatorState = GetVehicleIndicatorLights(veh)
        local leftIndicator = indicatorState == 2 or indicatorState == 3
        local rightIndicator = indicatorState == 1 or indicatorState == 3
        local hazard = leftIndicator and rightIndicator
        
        -- Doors
        local doorsOpen = {}
        for i = 0, 5 do
            if GetVehicleDoorAngleRatio(veh, i) > 0.1 then
                doorsOpen[tostring(i)] = true
            else
                doorsOpen[tostring(i)] = false
            end
        end
        
        -- Seatbelt (cars only, not bikes)
        local seatbelt = seatbeltOn
        local abs = false
        
        -- Engine check light (based on engine health < 80%)
        local engineCheck = engineHealth < 800
        
        -- Battery warning (rare in GTA, always false for now)
        local battery = false
        
        -- Oil pressure warning (engine health < 60%)
        local oil = engineHealth < 600
        
        -- Odometer (distance traveled, approximation)
        local currentCoords = GetEntityCoords(veh)
        if lastVehicle ~= veh then
            seatbeltOn = false
            lastVehicle = veh
            lastCoords = currentCoords
            local plate = GetVehicleNumberPlateText(veh) or tostring(veh)
            plate = plate:gsub('^%s+', ''):gsub('%s+$', ''):gsub('[^%w%-_]', '')
            odometerKey = 'fighterjet_odo_' .. plate
            odometerKm = GetResourceKvpFloat(odometerKey) or 0.0
        elseif lastCoords then
            local travelled = #(currentCoords - lastCoords)
            if travelled > 0.01 and travelled < 100.0 then
                odometerKm = odometerKm + (travelled / 1000.0)
            end
            lastCoords = currentCoords
        end

        local now = GetGameTimer()
        if odometerKey and now - lastOdometerSave >= 5000 then
            SetResourceKvpFloat(odometerKey, odometerKm)
            lastOdometerSave = now
        end
        
        -- Night mode check (game time 18:00-06:00)
        local hour = GetClockHours()
        local nightMode = (hour >= 18 or hour < 6)
        
        -- Rain mode check
        local rainMode = GetRainLevel() > 0
        
        -- Send all data to NUI
        SendNUIMessage({
            action = 'dashboardUpdate',
            speed = speed,
            rpm = rpm,
            fuel = fuel,
            temp = temp,
            gear = gearDisplay,
            engineRunning = engineRunning,
            engineHealth = engineHealth / 10, -- 0-100 scale
            bodyHealth = GetVehicleBodyHealth(veh) / 10, -- 0-100 scale
            leftIndicator = leftIndicator,
            rightIndicator = rightIndicator,
            highbeam = highbeamsOn,
            lowbeam = lowbeamOn,
            hazard = hazard,
            seatbelt = seatbelt,
            abs = abs,
            engineCheck = engineCheck,
            battery = battery,
            oil = oil,
            odometer = odometerKm,
            doorsOpen = doorsOpen
        })
        SendNUIMessage({ action = 'seatbeltUpdate', enabled = seatbeltOn, visible = true })
        
        -- Update night/rain mode
        SendNUIMessage({
            action = 'setNightMode',
            enabled = nightMode
        })
        
        SendNUIMessage({
            action = 'setRainMode',
            enabled = rainMode
        })

        ::continue::
    end
end)

-- Optional: Toggle dashboard visibility with command
RegisterCommand('toggledash', function()
    showDashboard = not showDashboard
    if showDashboard then
        TriggerEvent('chat:addMessage', { args = { 'Dashboard', 'Enabled' } })
    else
        SendNUIMessage({ action = 'dashboardHide' })
        TriggerEvent('chat:addMessage', { args = { 'Dashboard', 'Disabled' } })
    end
end, false)
