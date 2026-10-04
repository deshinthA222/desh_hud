-- GTA/FiveM native reticle controller.
-- HUD component 14 is allowed only for configured vehicle weapons and
-- explicitly configured on-foot weapons.

local allowedWeaponHashes = {}
local onFootWeaponHashes = {}

local function addWeaponHash(target, weapon)
    local weaponHash = weapon
    if type(weapon) == 'string' then
        weaponHash = GetHashKey(weapon)
    end

    if type(weaponHash) == 'number' then
        target[weaponHash] = true
    end
end

local function rebuildAllowedWeapons()
    allowedWeaponHashes = {}
    onFootWeaponHashes = {}
    local crosshairConfig = Config.VehicleCrosshair or {}

    for _, weapon in ipairs(crosshairConfig.AllowedWeapons or {}) do
        addWeaponHash(allowedWeaponHashes, weapon)
    end

    for _, weapon in ipairs(crosshairConfig.OnFootWeapons or {}) do
        addWeaponHash(onFootWeaponHashes, weapon)
    end
end

local function isVehicleWeaponAllowed(weaponHash)
    local crosshairConfig = Config.VehicleCrosshair or {}
    if crosshairConfig.AllVehicleWeapons ~= false then
        return true
    end

    return allowedWeaponHashes[weaponHash] == true
end

local function isExplicitlyAllowed(weaponHash)
    return allowedWeaponHashes[weaponHash] == true
end

local function isOnFootWeaponAllowed(weaponHash)
    return onFootWeaponHashes[weaponHash] == true
end

rebuildAllowedWeapons()

-- Pull configuration values out of the loop
local crosshairConfig = Config.VehicleCrosshair or {}
local isCrosshairEnabled = crosshairConfig.Enabled ~= false
local hideOnFoot = crosshairConfig.HideOnFoot ~= false

CreateThread(function()
    while true do
        local sleep = 150
        local ped = PlayerPedId()
        local inVehicle = IsPedInAnyVehicle(ped, false)
        local selectedWeapon = GetSelectedPedWeapon(ped)
        
        -- Fallback to active scanning only when armed or driving
        if inVehicle or selectedWeapon ~= GetHashKey('WEAPON_UNARMED') then
            sleep = 0
            local showCrosshair = false

            if isCrosshairEnabled then
                if inVehicle then
                    local hasVehicleWeapon, vehicleWeaponHash = GetCurrentPedVehicleWeapon(ped)
                    showCrosshair = (hasVehicleWeapon == true or hasVehicleWeapon == 1)
                        and vehicleWeaponHash ~= nil
                        and isVehicleWeaponAllowed(vehicleWeaponHash)

                    -- Personal weapons fired from a vehicle remain opt-in.
                    if not showCrosshair and selectedWeapon ~= GetHashKey('WEAPON_UNARMED') then
                        showCrosshair = isExplicitlyAllowed(selectedWeapon)
                    end
                else
                    local isAiming = IsPlayerFreeAiming(PlayerId()) or IsControlPressed(0, 25)
                    showCrosshair = isAiming and isOnFootWeaponAllowed(selectedWeapon)
                end
            end

            if showCrosshair then
                ShowHudComponentThisFrame(14)
            elseif hideOnFoot or inVehicle then
                HideHudComponentThisFrame(14)
            end
        end
        
        Wait(sleep)
    end
end)