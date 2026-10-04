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
local crosshairScanActive = false

CreateThread(function()
    while true do
        Wait(crosshairScanActive and 0 or 150)

        local crosshairConfig = Config.VehicleCrosshair or {}
        local ped = PlayerPedId()
        local playerId = PlayerId()
        local inVehicle = IsPedInAnyVehicle(ped, false)
        local selectedWeapon = GetSelectedPedWeapon(ped)
        crosshairScanActive = inVehicle
            or selectedWeapon ~= GetHashKey('WEAPON_UNARMED')
        local showCrosshair = false

        if crosshairConfig.Enabled ~= false then
            if inVehicle then
                local hasVehicleWeapon, vehicleWeaponHash = GetCurrentPedVehicleWeapon(ped)
                showCrosshair = (hasVehicleWeapon == true or hasVehicleWeapon == 1)
                    and vehicleWeaponHash ~= nil
                    and isVehicleWeaponAllowed(vehicleWeaponHash)

                -- Personal weapons fired from a vehicle remain opt-in.
                if not showCrosshair then
                    local selectedPedWeapon = selectedWeapon
                    showCrosshair = selectedPedWeapon ~= nil
                        and selectedPedWeapon ~= GetHashKey('WEAPON_UNARMED')
                        and isExplicitlyAllowed(selectedPedWeapon)
                end
            else
                local selectedPedWeapon = selectedWeapon
                local isAiming = IsPlayerFreeAiming(playerId) or IsControlPressed(0, 25)
                showCrosshair = isAiming and isOnFootWeaponAllowed(selectedPedWeapon)
            end
        end

        if showCrosshair then
            ShowHudComponentThisFrame(14)
        elseif crosshairConfig.HideOnFoot ~= false or inVehicle then
            HideHudComponentThisFrame(14)
        end
    end
end)
