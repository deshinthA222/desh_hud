local isInVehicle = false;
local inPlane = false;
local restoreRadar = false;
local stallWarning = false;
local altitudeWarning = false;
local retractableGear = false;
local wasInAir = false;
local wasTargeted = false;
local hasVtol = false;
local currentColor = "green";
local currentIsHelicopter = false;

Citizen.CreateThread(function()
    DisplayRadar(true);
    while true do
        -- 30 Hz is smooth for NUI gauges and halves telemetry/native traffic.
        Citizen.Wait(inPlane and 33 or 250);
        if (inPlane) then
            local ped = GetPlayerPed(-1);
            local veh = GetVehiclePedIsIn(ped, false);
            -- Read the actual GTA vehicle class on every telemetry update.
            -- This avoids stale/serialized boolean state when switching
            -- directly between planes and helicopters.
            local telemetryIsHelicopter = GetVehicleClass(veh) == 15;
            currentIsHelicopter = telemetryIsHelicopter;
            local pos = GetEntityCoords(veh);
            local speed = GetEntitySpeed(veh);
            local altitude = GetEntityHeightAboveGround(veh);
            local rawAlt = altitude;
            local indicatorSpeed = speed * 1.943844;
            local verticalSpeed = GetEntityVelocity(veh).z * 0.06;
            local rotation = GetEntityRotation(veh, 2);
            local direction = math.floor(rotation[3]);
			if(direction < 0) then direction = direction*-1 else direction = 360-direction end
			if(direction == 360) then direction = 0 end
            local gear = 0;
            local gearWorks = true;
            if not currentIsHelicopter then
                gear = GetLandingGearState(veh);
                gearWorks = IsPlaneLandingGearIntact(veh);
            end
            local vtol = 0.0;
            local hasWeapon, weapon = GetCurrentPedVehicleWeapon(ped);
            local weaponType = "none";
            local targetDist = 0;
            local hasLock, target = GetVehicleLockOnTarget(veh);
            local targetPos;
            local visible_target, x_target, y_target;
            local homingRadius = GetOffsetFromEntityInWorldCoords(veh, 0.0, -320.0, 0.0);
            local homingEnd = GetOffsetFromEntityInWorldCoords(veh, 0.0, -10.0, 0.0);
            local incoming = IsProjectileInArea(homingRadius.x, homingRadius.y, homingRadius.z, homingEnd.x, homingEnd.y, homingEnd.z, false);
            
            if (not wasTargeted and incoming) then
                wasTargeted = true;
                SendNUIMessage({
                    action = "missile",
                    mode = "start"
                });
            elseif (wasTargeted and not incoming) then
                wasTargeted = false;
                SendNUIMessage({
                    action = "missile",
                    mode = "end"
                });
            end
            local targetLocked = (hasLock == true or hasLock == 1)
            if (targetLocked and target and target ~= 0 and DoesEntityExist(target)) then
                targetPos = GetEntityCoords(target);
                local targetDistanceMeters = Vdist(pos.x, pos.y, pos.z, targetPos.x, targetPos.y, targetPos.z)
                visible_target, x_target, y_target = World3dToScreen2d(targetPos.x, targetPos.y, targetPos.z);
                if (targetDistanceMeters >= 1000.0) then
                    targetDist = string.format("%.1f KM", targetDistanceMeters / 1000.0)
                else
                    targetDist = string.format("%d M", math.floor(targetDistanceMeters + 0.5))
                end
            else
                targetPos = GetOffsetFromEntityInWorldCoords(veh, 0.0, 150.0, 0.0);
                visible_target, x_target, y_target = World3dToScreen2d(targetPos.x, targetPos.y, targetPos.z);
            end
            if (hasWeapon) then
                for k,v in next, Config.Weapons do
                    if (k == weapon) then
                        weaponType = v;
                    end
                end
            end
            if (hasVtol and not currentIsHelicopter) then
                vtol = GetPlaneVtolDirection(veh);
            end
            if (Config.StallWarning) then
                if (altitude > 80 and speed < 20.0 and vtol ~= 1.0) then
                    if (not stallWarning) then
                        SendNUIMessage({
                            action = "stall",
                            mode = "start"
                        });
                    end
                    stallWarning = true;
                else
                    if (stallWarning) then
                        SendNUIMessage({
                            action = "stall",
                            mode = "end"
                        });
                    end
                    stallWarning = false;
                end
            end
            if (Config.AltitudeWarning) then
                if (wasInAir) then
                    if (altitude <= 2 and speed < 10.0) then
                        wasInAir = false; 
                    end
                    if (altitude <= Config.AltitudeWarningHeigth and speed > 50.0 and (gear == 4 or gear == 1 or not retractableGear)) then
                        if (not altitudeWarning) then
                            SendNUIMessage({
                                action = "altitude",
                                mode = "start"
                            });
                        end
                        altitudeWarning = true;
                    else
                        if (altitudeWarning) then
                            SendNUIMessage({
                                action = "altitude",
                                mode = "end"
                            });
                        end
                        altitudeWarning = false;
                    end
                elseif (altitude > 100) then
                    wasInAir = true;
                end
            end
            if (Config.Speed == "kilometers") then
                speed = math.floor(speed * 3.6);
            elseif (Config.Speed == "miles") then
                speed = math.floor(speed * 2.236936);
            elseif (Config.Speed == "knots") then
                speed = math.floor(speed * 1.944);
            end
            if (Config.Altitude == "feet") then
                altitude = math.floor(altitude * 3.2808399);
            else
                altitude = math.floor(altitude);
            end
            if (altitude < 0) then
                altitude = 0;
            end
            if (direction < 0) then
                direction = direction + 360;
            end
            if (gear == 0) then
                gear = "DEPLOYED";
            elseif (gear == 1) then
                gear = "RETRACTING";
            elseif (gear == 3) then
                gear = "DEPLOYING";
            elseif (gear == 4) then
                gear = "RETRACTED";
            end
            if (not gearWorks) then
                gear = "MALFUNCTION";
            end
            if (not retractableGear) then
                gear = "STATIC";
            end
            if (vtol == 0.0) then
                vtol = "INACTIVE";
            elseif (vtol == 1.0) then
                vtol = "ACTIVE";
            else
                vtol = "SWITCHING";
            end
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
            });
        end
    end
end);

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(inPlane and 0 or 250);
        if (inPlane) then
            if (Config.DisableRadar) then
                DisplayRadar(false);
            end
            if (Config.OnlyFirstPerson) then
                if (IsControlJustReleased(2, 0)) then
                    Citizen.CreateThread(function()
                        Citizen.Wait(100);
                        if (GetFollowVehicleCamViewMode() == 4) then
                            SendNUIMessage({
                                action = "show",
                                color = currentColor,
                                isHelicopter = currentIsHelicopter,
                                aircraftType = currentIsHelicopter and "helicopter" or "plane"
                            });
                        else
                            SendNUIMessage({
                                action = "hide"
                            });
                        end
                    end);
                end
            end
        end
    end
end);

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(100);
		local ped = PlayerPedId();
        local vehicle = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or 0;
        local shouldShow = false;
        local selectedConfig = nil;

        if vehicle ~= 0 and Config.DisableRadar == false then
            DisplayRadar(true);
        end

        if vehicle ~= 0 and not IsEntityDead(ped) then
            local model = GetEntityModel(vehicle);
            for _, vehicleConfig in ipairs(Config.Vehicles) do
                if model == GetHashKey(vehicleConfig.model) then
                    shouldShow = true;
                    selectedConfig = vehicleConfig;
                    break;
                end
            end

            -- Use this same flight HUD for standard/add-on planes and
            -- helicopters. Classes: 15 = helicopter, 16 = plane.
            local vehicleClass = GetVehicleClass(vehicle)
            local isSupportedPlane = Config.AllPlanes ~= false
                and (IsPedInAnyPlane(ped) or vehicleClass == 16)
            local isSupportedHelicopter = Config.AllHelicopters ~= false
                and (IsPedInAnyHeli(ped) or vehicleClass == 15)

            if not shouldShow and (isSupportedPlane or isSupportedHelicopter) then
                shouldShow = true;
                selectedConfig = {
                    color = isSupportedHelicopter
                        and (Config.DefaultHelicopterColor or "green")
                        or (Config.DefaultPlaneColor or "green"),
                    retractableGear = DoesVehicleHaveLandingGear
                        and DoesVehicleHaveLandingGear(vehicle) or true,
                    vtol = false
                };
            end
        end

        if shouldShow and not inPlane then
            restoreRadar = not IsRadarHidden();
            inPlane = true;
            isInVehicle = true;
            currentColor = selectedConfig.color or "green";
            currentIsHelicopter = IsPedInAnyHeli(ped) or GetVehicleClass(vehicle) == 15;
            retractableGear = not currentIsHelicopter and selectedConfig.retractableGear == true;
            hasVtol = selectedConfig.vtol == true;
            if not currentIsHelicopter then
                EnableStallWarningSounds(vehicle, false);
            end
            if ((Config.OnlyFirstPerson and GetFollowVehicleCamViewMode() == 4) or not Config.OnlyFirstPerson) then
                SendNUIMessage({
                    action = "show",
                    color = currentColor,
                    isHelicopter = currentIsHelicopter,
                    aircraftType = currentIsHelicopter and "helicopter" or "plane"
                });
            end
        elseif shouldShow and inPlane then
            -- Refresh the aircraft type when changing directly between a
            -- plane and helicopter without first leaving the vehicle.
            currentIsHelicopter = IsPedInAnyHeli(ped) or GetVehicleClass(vehicle) == 15;
            retractableGear = not currentIsHelicopter and selectedConfig.retractableGear == true;
            hasVtol = not currentIsHelicopter and selectedConfig.vtol == true;
            isInVehicle = true;
        elseif not shouldShow and inPlane then
            inPlane = false;
            isInVehicle = vehicle ~= 0;
            stallWarning = false;
            altitudeWarning = false;
            wasTargeted = false;
            wasInAir = false;
            currentIsHelicopter = false;
            SendNUIMessage({ action = "hide" });
            SendNUIMessage({ action = "stall", mode = "end" });
            SendNUIMessage({ action = "altitude", mode = "end" });
            SendNUIMessage({ action = "missile", mode = "end" });
            if restoreRadar then DisplayRadar(true); end
        else
            isInVehicle = vehicle ~= 0;
        end
		end
end);
