-- ESX Status Display (Food/Drink/Armor). The event is harmless when
-- esx_status is not installed, so this resource no longer hard-depends on ESX.

local statusData = {}
local displayedStamina = 100.0
RegisterNetEvent('esx_status:onTick')
AddEventHandler('esx_status:onTick', function(data)
    statusData = data
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(250)
        local ped = PlayerPedId()
        local armorPercent = GetPedArmour(ped)
        local maxHealth = math.max(GetEntityMaxHealth(ped), 101)
        local healthPercent = ((GetEntityHealth(ped) - 100) / (maxHealth - 100)) * 100
        -- Keep a predictable 100 -> 0 meter. Different FiveM artifacts can
        -- report the sprint native inconsistently, so drive the visible value
        -- from the actual sprint state and recover it while not sprinting.
        if IsPedSprinting(ped) then
            displayedStamina = math.max(0.0, displayedStamina - 1.5)
        else
            displayedStamina = math.min(100.0, displayedStamina + 0.8)
        end
        local staminaPercent = displayedStamina
        local foodPercent, drinkPercent = nil, nil
        if statusData and #statusData > 0 then
            for _, stat in ipairs(statusData) do
                if stat.name == 'hunger' then
                    foodPercent = stat.percent or ((stat.val or 0) / 10000)
                elseif stat.name == 'thirst' then
                    drinkPercent = stat.percent or ((stat.val or 0) / 10000)
                end
            end
        end
        SendNUIMessage({
            action = 'statusUpdate',
            food = foodPercent,
            drink = drinkPercent,
            armor = armorPercent,
            health = math.max(0, math.min(100, healthPercent)),
            stamina = math.max(0, math.min(100, staminaPercent))
        })

    end
end)

-- Hide GTA's default minimap health/armour bars; the custom status HUD replaces them.
Citizen.CreateThread(function()
    local minimap = RequestScaleformMovie('minimap')
    while not HasScaleformMovieLoaded(minimap) do
        Citizen.Wait(100)
    end

    SetRadarBigmapEnabled(true, false)
    Citizen.Wait(0)
    SetRadarBigmapEnabled(false, false)

    while true do
        BeginScaleformMovieMethod(minimap, 'SETUP_HEALTH_ARMOUR')
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()
        -- The minimap scaleform keeps this state; refresh periodically instead
        -- of rebuilding the same method every rendered frame.
        Citizen.Wait(500)
    end
end)
