-- Dedicated custom weapon name/ammo HUD.
-- Kept separate from player status so either system can update independently.

local weaponNames = {
    [GetHashKey('WEAPON_PISTOL')] = 'Pistol',
    [GetHashKey('WEAPON_COMBATPISTOL')] = 'Combat Pistol',
    [GetHashKey('WEAPON_APPISTOL')] = 'AP Pistol',
    [GetHashKey('WEAPON_PISTOL50')] = 'Pistol .50',
    [GetHashKey('WEAPON_SNSPISTOL')] = 'SNS Pistol',
    [GetHashKey('WEAPON_HEAVYPISTOL')] = 'Heavy Pistol',
    [GetHashKey('WEAPON_VINTAGEPISTOL')] = 'Vintage Pistol',
    [GetHashKey('WEAPON_REVOLVER')] = 'Heavy Revolver',
    [GetHashKey('WEAPON_MICROSMG')] = 'Micro SMG',
    [GetHashKey('WEAPON_SMG')] = 'SMG',
    [GetHashKey('WEAPON_ASSAULTSMG')] = 'Assault SMG',
    [GetHashKey('WEAPON_COMBATPDW')] = 'Combat PDW',
    [GetHashKey('WEAPON_MACHINEPISTOL')] = 'Machine Pistol',
    [GetHashKey('WEAPON_ASSAULTRIFLE')] = 'Assault Rifle',
    [GetHashKey('WEAPON_CARBINERIFLE')] = 'Carbine Rifle',
    [GetHashKey('WEAPON_ADVANCEDRIFLE')] = 'Advanced Rifle',
    [GetHashKey('WEAPON_SPECIALCARBINE')] = 'Special Carbine',
    [GetHashKey('WEAPON_BULLPUPRIFLE')] = 'Bullpup Rifle',
    [GetHashKey('WEAPON_COMPACTRIFLE')] = 'Compact Rifle',
    [GetHashKey('WEAPON_PUMPSHOTGUN')] = 'Pump Shotgun',
    [GetHashKey('WEAPON_SAWNOFFSHOTGUN')] = 'Sawed-Off Shotgun',
    [GetHashKey('WEAPON_ASSAULTSHOTGUN')] = 'Assault Shotgun',
    [GetHashKey('WEAPON_BULLPUPSHOTGUN')] = 'Bullpup Shotgun',
    [GetHashKey('WEAPON_HEAVYSHOTGUN')] = 'Heavy Shotgun',
    [GetHashKey('WEAPON_MG')] = 'MG',
    [GetHashKey('WEAPON_COMBATMG')] = 'Combat MG',
    [GetHashKey('WEAPON_SNIPERRIFLE')] = 'Sniper Rifle',
    [GetHashKey('WEAPON_HEAVYSNIPER')] = 'Heavy Sniper',
    [GetHashKey('WEAPON_MARKSMANRIFLE')] = 'Marksman Rifle',
    [GetHashKey('WEAPON_RPG')] = 'RPG',
    [GetHashKey('WEAPON_GRENADELAUNCHER')] = 'Grenade Launcher',
    [GetHashKey('WEAPON_MINIGUN')] = 'Minigun',
    [GetHashKey('WEAPON_GRENADE')] = 'Grenade',
    [GetHashKey('WEAPON_STICKYBOMB')] = 'Sticky Bomb',
    [GetHashKey('WEAPON_MOLOTOV')] = 'Molotov',
    [GetHashKey('WEAPON_KNIFE')] = 'Knife',
    [GetHashKey('WEAPON_BAT')] = 'Baseball Bat',
    [GetHashKey('WEAPON_CROWBAR')] = 'Crowbar',
    [GetHashKey('WEAPON_FLASHLIGHT')] = 'Flashlight'
}

local function ResolveWeaponName(weaponHash)
    if weaponNames[weaponHash] then return weaponNames[weaponHash] end

    local okLabel, label = pcall(GetWeaponDisplayNameFromHash, weaponHash)
    if okLabel and label then
        local okName, name = pcall(GetLabelText, label)
        if okName and name and name ~= 'NULL' and name ~= '' then return name end
        return label:gsub('WT_', ''):gsub('_', ' ')
    end
    return 'CUSTOM WEAPON'
end

local lastWeaponHash = nil
local lastClipAmmo = -1
local lastReserveAmmo = -1

Citizen.CreateThread(function()
    local unarmedHash = GetHashKey('WEAPON_UNARMED')
    while true do
        local ped = PlayerPedId()
        local weaponHash = GetSelectedPedWeapon(ped)

        if weaponHash and weaponHash ~= unarmedHash and not IsEntityDead(ped) then
            local totalAmmo = GetAmmoInPedWeapon(ped, weaponHash) or 0
            local hasClip, clipAmmo = GetAmmoInClip(ped, weaponHash)
            clipAmmo = hasClip and (clipAmmo or 0) or 0
            local usesAmmo = totalAmmo > 0 or hasClip
            
            local currentClip = usesAmmo and clipAmmo or '--'
            local currentReserve = usesAmmo and math.max(0, totalAmmo - clipAmmo) or '--'

            -- Optimization: Only dispatch NUI message if the weapon or ammo count actually changes
            if weaponHash ~= lastWeaponHash or currentClip ~= lastClipAmmo or currentReserve ~= lastReserveAmmo then
                lastWeaponHash = weaponHash
                lastClipAmmo = currentClip
                lastReserveAmmo = currentReserve

                SendNUIMessage({
                    action = 'weaponUpdate',
                    visible = true,
                    name = ResolveWeaponName(weaponHash),
                    clip = currentClip,
                    reserve = currentReserve
                })
            end
        else
            -- Ensure we only send the hide action once, rather than every 100ms
            if lastWeaponHash ~= nil then
                lastWeaponHash = nil
                SendNUIMessage({ action = 'weaponUpdate', visible = false })
            end
        end

        Citizen.Wait(100)
    end
end)

Citizen.CreateThread(function()
    while true do
        DisplayAmmoThisFrame(false)
        HideHudComponentThisFrame(2)
        Citizen.Wait(0)
    end
end)