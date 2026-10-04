local inPlane = false
local restoreRadar = false
local stallWarning = false
local altitudeWarning = false
local retractableGear = false
local wasInAir = false
local wasTargeted = false
local hasVtol = false
local currentColor = "green"
local currentIsHelicopter = false

-- HUD Telemetry Thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(inPlane and 33 or 250)
        
        if inPlane then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            
            local telemetryIsHelicopter = GetVehicleClass(veh) == 15
            currentIsHelicopter = telemetryIsHelicopter
            
            local pos = GetEntityCoords(veh)
            local speed = GetEntitySpeed(veh)
            local altitude = GetEntityHeightAboveGround(veh)
            local rawAlt = altitude
            local indicatorSpeed = speed * 1.943844
            local verticalSpeed = GetEntityVelocity(veh).z * 0.06
            
            local rotation = GetEntityRotation(veh, 2)
            local direction = math.floor(rotation[3])
            if direction < 0 then direction = direction * -1 else direction = 360 - direction end
            if direction == 360 then direction = 0 end
            if direction < 0 then direction = direction + 360 end

            local gear = 0
            local gearWorks = true
            if not currentIsHelicopter then
                gear = GetLandingGearState(veh)
                gearWorks = IsPlaneLandingGearIntact(veh)
            end
            
            local vtol = 0.0
            if hasVtol and not currentIsHelicopter then
                vtol = GetPlaneVtolDirection(veh)
            end

            local hasWeapon, weapon = GetCurrentPedVehicleWeapon(ped)
            local weaponType = "none"
            if hasWeapon then
                for k, v in pairs(Config.Weapons or {}) do
                    if k == weapon then 
                        weaponType = v 
                        break 
                    end
                end
            end

            local targetDist = 0
            local hasLock, target = GetVehicleLockOnTarget(veh)
            local targetPos, visible_target, x_target, y_target
            
            local homingRadius = GetOffsetFromEntityInWorldCoords(veh, 0.0, -320.0, 0.0)
            local homingEnd = GetOffsetFromEntityInWorldCoords(veh, 0.0, -10.0, 0.0)
            local incoming = IsProjectileInArea(homingRadius.x, homingRadius.y, homingRadius.z, homingEnd.x, homingEnd.y, homingEnd.z, false)
            
            if not wasTargeted and incoming then
                wasTargeted = true
                SendNUIMessage({ action = "missile", mode = "start" })
            elseif wasTargeted and not incoming then
                wasTargeted = false
                SendNUIMessage({ action = "missile", mode = "end" })
            end
            
            local targetLocked = (hasLock == true or hasLock == 1)
            if targetLocked and target and target ~= 0 and DoesEntityExist(target) then
                targetPos = GetEntityCoords(target)
                local targetDistanceMeters = #(pos - targetPos)
                visible_target, x_target, y_target = World3dToScreen2d(targetPos.x, targetPos.y, targetPos.z)
                
                if targetDistanceMeters >= 1000.0 then
                    targetDist = string.format("%.1f KM", targetDistanceMeters / 1000.0)
                else
                    targetDist = string.format("%d M", math.floor(targetDistanceMeters + 0.5))
                end
            else
                targetPos = GetOffsetFromEntityInWorldCoords(veh, 0.0, 150.0, 0.0)
                visible_target, x_target, y_target = World3dToScreen2d(targetPos.x, targetPos.y, targetPos.z)
            end
            
            if Config.StallWarning then
                if altitude > 80 and speed < 20.0 and vtol ~= 1.0 then
                    if not stallWarning then
                        SendNUIMessage({ action = "stall", mode = "start" })
                    end
                    stallWarning = true
                else
                    if stallWarning then
                        SendNUIMessage({ action = "stall", mode = "end" })
                    end
                    stallWarning = false
                end
            end
            
            if Config.AltitudeWarning then
                if wasInAir then
                    if altitude <= 2 and speed < 10.0 then
                        wasInAir = false
                    end
                    if altitude <= (Config.AltitudeWarningHeigth or 50) and speed > 50.0 and (gear == 4 or gear == 1 or not retractableGear) then
                        if not altitudeWarning then
                            SendNUIMessage({ action = "altitude", mode = "start" })
                        end
                        altitudeWarning = true
                    else
                        if altitudeWarning then
                            SendNUIMessage({ action = "altitude", mode = "end" })
                        end
                        altitudeWarning = false
                    end
                elseif altitude > 100 then
                    wasInAir = true
                end
            end

            -- Conversions
            if Config.Speed == "kilometers" then speed = math.floor(speed * 3.6)
            elseif Config.Speed == "miles" then speed = math.floor(speed * 2.236936)
            elseif Config.Speed == "knots" then speed = math.floor(speed * 1.944) end
            
            if Config.Altitude == "feet" then altitude = math.floor(altitude * 3.2808399)
            else altitude = math.floor(altitude) end
            
            if altitude < 0 then altitude = 0 end
            
            if gear == 0 then gear = "DEPLOYED"
            elseif gear == 1 then gear = "RETRACTING"
            elseif gear == 3 then gear = "DEPLOYING"
            elseif gear == 4 then gear = "RETRACTED" end
            
            if not gearWorks then gear = "MALFUNCTION" end
            if not retractableGear then gear = "STATIC" end
            
            if vtol == 0.0 then vtol = "INACTIVE"
            elseif vtol == 1.0 then vtol = "ACTIVE"
            else vtol = "SWITCHING" end
            
            SendNUIMessage({
                action = "update",
                yaw = direction,
                pitch = rotation[1],
                roll = rotation[2],
                speed = speed,
                altitude = altitude,
                rawAlt = rawAlt,
                indicatorSpeed = indicatorSpeed,
                indicatorAltitude = rawAlt,
                verticalSpeed = verticalSpeed,
                gear = gear,
                hasVtol = hasVtol,
                vtol = vtol,
                hasLock = targetLocked,
                x_target = x_target,
                y_target = y_target,
                targetDist = targetDist,
                hasWeapon = hasWeapon,
                weaponType = weaponType,
                isHelicopter = telemetryIsHelicopter,
                aircraftType = telemetryIsHelicopter and "helicopter" or "plane"
            })
        end
    end
end)

-- Validation & Visibility Thread
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(150)
        local ped = PlayerPedId()
        local vehicle = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or 0
        local shouldShow = false
        local selectedConfig = nil

        -- Manage the Minimap based on the new setting
        if vehicle ~= 0 and Config.DisableMinimap == false then
            DisplayRadar(true)
        end

        if vehicle ~= 0 and not IsEntityDead(ped) then
            -- RESTRICTION: Only driver (-1) and front passenger (0) seats
            local isDriver = GetPedInVehicleSeat(vehicle, -1) == ped
            local isPassenger = GetPedInVehicleSeat(vehicle, 0) == ped

            if isDriver or isPassenger then
                local vehicleClass = GetVehicleClass(vehicle)
                
                -- RESTRICTION: Only Planes (16) and Helicopters (15)
                local isSupportedPlane = Config.AllPlanes ~= false and (IsPedInAnyPlane(ped) or vehicleClass == 16)
                local isSupportedHelicopter = Config.AllHelicopters ~= false and (IsPedInAnyHeli(ped) or vehicleClass == 15)

                if isSupportedPlane or isSupportedHelicopter then
                    shouldShow = true
                    
                    local model = GetEntityModel(vehicle)
                    for _, vehicleConfig in ipairs(Config.Vehicles or {}) do
                        if model == GetHashKey(vehicleConfig.model) then
                            selectedConfig = vehicleConfig
                            break
                        end
                    end

                    if not selectedConfig then
                        selectedConfig = {
                            color = isSupportedHelicopter and (Config.DefaultHelicopterColor or "green") or (Config.DefaultPlaneColor or "green"),
                            retractableGear = DoesVehicleHaveLandingGear(vehicle) or true,
                            vtol = false
                        }
                    end
                end
            end
        end

        -- State Handling
        if shouldShow and not inPlane then
            restoreRadar = not IsRadarHidden()
            inPlane = true
            currentColor = selectedConfig.color or "green"
            currentIsHelicopter = IsPedInAnyHeli(ped) or GetVehicleClass(vehicle) == 15
            retractableGear = not currentIsHelicopter and selectedConfig.retractableGear == true
            hasVtol = selectedConfig.vtol == true
            
            if Config.DisableMinimap then
                DisplayRadar(false)
            end

            if not currentIsHelicopter then
                EnableStallWarningSounds(vehicle, false)
            end
            
            if (Config.OnlyFirstPerson and GetFollowVehicleCamViewMode() == 4) or not Config.OnlyFirstPerson then
                SendNUIMessage({
                    action = "show",
                    color = currentColor,
                    isHelicopter = currentIsHelicopter,
                    aircraftType = currentIsHelicopter and "helicopter" or "plane"
                })
            end
        elseif shouldShow and inPlane then
            currentIsHelicopter = IsPedInAnyHeli(ped) or GetVehicleClass(vehicle) == 15
            retractableGear = not currentIsHelicopter and selectedConfig.retractableGear == true
            hasVtol = not currentIsHelicopter and selectedConfig.vtol == true
        elseif not shouldShow and inPlane then
            inPlane = false
            stallWarning = false
            altitudeWarning = false
            wasTargeted = false
            wasInAir = false
            currentIsHelicopter = false
            
            SendNUIMessage({ action = "hide" })
            SendNUIMessage({ action = "stall", mode = "end" })
            SendNUIMessage({ action = "altitude", mode = "end" })
            SendNUIMessage({ action = "missile", mode = "end" })
            
            if restoreRadar then DisplayRadar(true) end
        end
    end
end)

-- First-person toggle watcher
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(inPlane and 0 or 250)
        if inPlane and Config.OnlyFirstPerson then
            if IsControlJustReleased(2, 0) then -- INPUT_NEXT_CAMERA
                Citizen.Wait(100)
                if GetFollowVehicleCamViewMode() == 4 then
                    SendNUIMessage({
                        action = "show",
                        color = currentColor,
                        isHelicopter = currentIsHelicopter,
                        aircraftType = currentIsHelicopter and "helicopter" or "plane"
                    })
                else
                    SendNUIMessage({ action = "hide" })
                end
            end
        end
    end
end)