local radarTargets = {}
local showRadar = false
local sweepAngle = 0

RadarConfig = {
    -- The whitelist has been removed. The radar will now show for all Aircraft.
    StealthAircraft = {
        akula = true, alkonost = true, raiju = true, rogue = true,
        besra = true, havok = true, swift2 = true, seabreeze = true
    }
}

function GetAircraftCode(model)
    local codes = {
        lazer = "LAZ", hydra = "HYD", alkonost = "ALK", raiju = "RAI", strikeforce = "STF"
    }
    return codes[model] or string.upper(string.sub(model, 1, 3))
end

-- Check if in allowed aircraft (Now ALL helicopters and planes)
CreateThread(function()
    while true do
        Wait(1000)
        
        if Config.EnableAircraftRadar == false then
            showRadar = false
        else
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) then
                local veh = GetVehiclePedIsIn(ped, false)
                local vehicleClass = GetVehicleClass(veh)
                
                -- Class 15 = Helicopters, Class 16 = Planes
                if vehicleClass == 15 or vehicleClass == 16 or IsPedInAnyHeli(ped) or IsPedInAnyPlane(ped) then
                    showRadar = true
                else
                    showRadar = false
                end
            else
                showRadar = false
            end
        end
    end
end)

-- Scan other aircraft
CreateThread(function()
    while true do
        Wait(2000)
        if not showRadar then
            radarTargets = {}
            goto continue
        end

        local nextTargets = {}
        local ped = PlayerPedId()
        local myCoords = GetEntityCoords(ped)

        for _, player in ipairs(GetActivePlayers()) do
            if player ~= PlayerId() then
                local targetPed = GetPlayerPed(player)
                if DoesEntityExist(targetPed) and IsPedInAnyVehicle(targetPed, false) then
                    local veh = GetVehiclePedIsIn(targetPed, false)
                    local vehicleClass = GetVehicleClass(veh)
                    
                    -- Only track if the target is in a helicopter (15) or plane (16) and is in the air
                    if (vehicleClass == 15 or vehicleClass == 16) and IsEntityInAir(veh) then
                        local model = GetEntityModel(veh)
                        local modelName = GetDisplayNameFromVehicleModel(model):lower()
                        local targetCoords = GetEntityCoords(veh)
                        
                        -- Keep stealth vehicles off the radar
                        if not RadarConfig.StealthAircraft[modelName]
                            and #(targetCoords - myCoords) <= (Config.RadarRange or 40000.0) then
                            table.insert(nextTargets, {
                                coords = targetCoords,
                                code = GetAircraftCode(modelName)
                            })
                        end
                    end
                end
            end
        end
        radarTargets = nextTargets
        ::continue::
    end
end)

-- Radar UI Thread
CreateThread(function()
    while true do
        Wait(showRadar and 0 or 250)
        if showRadar then
            DrawRadarUI()
            sweepAngle = (sweepAngle + 1) % 360
        end
    end
end)

-- Draws a square radar with targets
function DrawRadarUI()
    local radarX, radarY = 0.85, 0.5
    local radarSize = 0.18
    local radarRange = Config.RadarRange or 40000.0
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local angleRad = math.rad(-heading)

    -- Draw radar range label in top-right above radar
    local label = string.format("%.0f km", radarRange / 1000)
    SetTextFont(0)
    SetTextScale(0.25, 0.25)
    SetTextColour(0, 255, 0, 200)
    SetTextCentre(false)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandDisplayText(radarX + radarSize / 2 - 0.015, radarY - radarSize / 2 - 0.025)

    -- Radar background
    DrawRect(radarX, radarY, radarSize, radarSize, 10, 20, 10, 150)

    -- Grid lines
    for i = -1, 1 do
        DrawRect(radarX, radarY + i * radarSize / 3, radarSize, 0.001, 0, 255, 0, 100)
        DrawRect(radarX + i * radarSize / 3, radarY, 0.001, radarSize, 0, 255, 0, 100)
    end

    -- Sweep line (rotating)
    local sweepLength = radarSize / 2
    local sweepRad = math.rad(sweepAngle)
    local sx = radarX + math.cos(sweepRad) * sweepLength
    local sy = radarY + math.sin(sweepRad) * sweepLength
    DrawLine(radarX, radarY, 0.0, sx, sy, 0.0, 0, 255, 0, 120)

    -- Player center dot
    DrawRect(radarX, radarY, 0.005, 0.005, 0, 255, 0, 255)

    -- Aircraft blips
    for _, target in pairs(radarTargets) do
        local dx = (target.coords.x - coords.x) / radarRange
        local dy = (target.coords.y - coords.y) / radarRange

        -- Rotate relative to player's heading
        local rx = dx * math.cos(angleRad) - dy * math.sin(angleRad)
        local ry = -(dx * math.sin(angleRad) + dy * math.cos(angleRad))

        if (rx * rx + ry * ry) <= 1.0 then
            local dotX = radarX + rx * (radarSize / 2)
            local dotY = radarY + ry * (radarSize / 2)

            DrawRect(dotX, dotY, 0.01, 0.01, 255, 0, 0, 255)

            SetTextFont(0)
            SetTextScale(0.22, 0.22)
            SetTextColour(0, 255, 0, 220)
            SetTextCentre(true)
            BeginTextCommandDisplayText("STRING")
            AddTextComponentSubstringPlayerName(target.code or "UNK")
            EndTextCommandDisplayText(dotX, dotY - 0.012)
        end
    end
end