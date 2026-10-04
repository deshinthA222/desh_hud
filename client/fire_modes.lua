-- On-foot firearm mode controller.
-- AUTO allows held fire, SEMI allows one shot per trigger press, and BURST
-- allows Config.FireModes.BurstSize shots before requiring trigger release.

local validModes = { SAFE = true, AUTO = true, SEMI = true, BURST = true }
local modeOrder = { 'SAFE', 'SEMI', 'BURST', 'AUTO' }
local currentMode = string.upper((Config.FireModes and Config.FireModes.DefaultMode) or 'SAFE')
local triggerHeld = false
local burstActive = false
local burstShots = 0
local lastAmmo = 0
local lastWeapon = 0

if not validModes[currentMode] then currentMode = 'SAFE' end

local function resetTriggerState()
    triggerHeld = false
    burstActive = false
    burstShots = 0
    lastAmmo = 0
end

local function setFireMode(mode)
    mode = type(mode) == 'string' and string.upper(mode) or nil
    if not mode or not validModes[mode] then return false end

    currentMode = mode
    resetTriggerState()
    SendNUIMessage({ action = 'fireModeUpdate', mode = currentMode })
    return true
end

local function cycleFireMode()
    local nextIndex = 1
    for index, mode in ipairs(modeOrder) do
        if mode == currentMode then
            nextIndex = (index % #modeOrder) + 1
            break
        end
    end
    setFireMode(modeOrder[nextIndex])
end

-- Direct X-key detection (control 73). This avoids cached FiveM key mappings.
CreateThread(function()
    while true do
        -- A normal key press lasts far longer than 5 ms; polling at this rate
        -- avoids a permanent per-frame thread without making the key feel slow.
        Wait(10)
        if Config.FireModes and Config.FireModes.Enabled ~= false
            and not IsPauseMenuActive()
            and (IsControlJustPressed(0, 73) or IsDisabledControlJustPressed(0, 73)) then
            cycleFireMode()
        end
    end
end)

RegisterNetEvent('fighterjet:setFireMode', function(mode)
    setFireMode(mode)
end)

exports('SetFireMode', setFireMode)
exports('GetFireMode', function() return currentMode end)

CreateThread(function()
    Wait(500)
    SendNUIMessage({ action = 'fireModeUpdate', mode = currentMode })
end)

CreateThread(function()
    while true do
        local waitTime = 200
        local ped = PlayerPedId()
        local player = PlayerId()
        local weapon = GetSelectedPedWeapon(ped)
        local shouldControl = Config.FireModes
            and Config.FireModes.Enabled ~= false
            and not IsPedInAnyVehicle(ped, false)
            and not IsEntityDead(ped)
            and IsPedArmed(ped, 4)

        if weapon ~= lastWeapon then
            lastWeapon = weapon
            resetTriggerState()
        end

        if shouldControl and currentMode ~= 'AUTO' then
            waitTime = 0
            local pressed = IsControlPressed(0, 24) or IsDisabledControlPressed(0, 24)

            if currentMode == 'SAFE' then
                -- Block firearm discharge only. Do not block attack controls,
                -- alternate actions or melee inputs globally.
                DisablePlayerFiring(player, true)
            elseif currentMode == 'SEMI' then
                if pressed then
                    if triggerHeld then
                        DisablePlayerFiring(player, true)
                    else
                        -- The first frame is allowed through for exactly one shot.
                        triggerHeld = true
                    end
                else
                    triggerHeld = false
                end
            elseif currentMode == 'BURST' then
                if pressed then
                    if not triggerHeld then
                        triggerHeld = true
                        burstActive = true
                        burstShots = 0
                        lastAmmo = GetAmmoInPedWeapon(ped, weapon)
                    end

                    if burstActive then
                        local ammo = GetAmmoInPedWeapon(ped, weapon)
                        if ammo < lastAmmo then
                            burstShots = burstShots + (lastAmmo - ammo)
                        end
                        lastAmmo = ammo

                        local burstSize = math.max(1, tonumber(Config.FireModes.BurstSize) or 3)
                        if burstShots >= burstSize then
                            burstActive = false
                            DisablePlayerFiring(player, true)
                        end
                    else
                        DisablePlayerFiring(player, true)
                    end
                else
                    resetTriggerState()
                end
            end
        else
            resetTriggerState()
        end

        Wait(waitTime)
    end
end)
