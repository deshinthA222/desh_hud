-- Separate crouch / crawl toggles.
-- CTRL toggles Crouch <-> Stand. Z toggles Crawl <-> Stand.

local STAND = 0
local CROUCH = 1
local CRAWL = 2

local stance = STAND
local crouchKeyDown = false
local crawlKeyDown = false
local crouchClipset = 'move_ped_crouched'
local crouchStrafeClipset = 'move_ped_crouched_strafing'
local crawlDict = 'move_crawl'

local function requestClipset(name)
    RequestAnimSet(name)
    local timeout = GetGameTimer() + 3000
    while not HasAnimSetLoaded(name) and GetGameTimer() < timeout do
        Wait(10)
    end
    return HasAnimSetLoaded(name)
end

local function requestAnimDict(name)
    RequestAnimDict(name)
    local timeout = GetGameTimer() + 3000
    while not HasAnimDictLoaded(name) and GetGameTimer() < timeout do
        Wait(10)
    end
    return HasAnimDictLoaded(name)
end

local function standUp(ped)
    local wasCrawling = stance == CRAWL
    stance = STAND
    if wasCrawling then
        ClearPedTasksImmediately(ped)
    else
        StopAnimTask(ped, crawlDict, 'onfront_fwd', 0.1)
        StopAnimTask(ped, crawlDict, 'onfront_bwd', 0.1)
    end
    ResetPedMovementClipset(ped, 0.25)
    ResetPedStrafeClipset(ped)
    SetPedUsingActionMode(ped, false, -1, 'DEFAULT_ACTION')
    SetPedCanPlayAmbientAnims(ped, true)
end

local function crouch(ped)
    if requestClipset(crouchClipset) and requestClipset(crouchStrafeClipset) then
        if stance == CRAWL then
            -- Remove crawl root-motion before applying the crouch clipset.
            -- Without this, the previous backwards clip can keep moving the ped.
            ClearPedTasksImmediately(ped)
        else
            StopAnimTask(ped, crawlDict, 'onfront_fwd', 0.1)
            StopAnimTask(ped, crawlDict, 'onfront_bwd', 0.1)
        end
        SetPedMovementClipset(ped, crouchClipset, 0.15)
        SetPedStrafeClipset(ped, crouchStrafeClipset)
        SetPedUsingActionMode(ped, false, -1, 'DEFAULT_ACTION')
        stance = CROUCH
    end
end

local function crawl(ped)
    if requestAnimDict(crawlDict) then
        ResetPedMovementClipset(ped, 0.2)
        ResetPedStrafeClipset(ped)
        ClearPedSecondaryTask(ped)
        stance = CRAWL
    end
end

local function canChangeStance(ped)
    return not IsPedInAnyVehicle(ped, false)
        and not IsEntityDead(ped)
        and not IsPedRagdoll(ped)
end

RegisterCommand('+togglecrouch', function()
    if crouchKeyDown then return end
    crouchKeyDown = true
    local ped = PlayerPedId()
    if not canChangeStance(ped) then return end

    if stance == CROUCH then
        standUp(ped)
    else
        crouch(ped)
    end
end, false)

RegisterCommand('-togglecrouch', function()
    crouchKeyDown = false
end, false)

RegisterCommand('+togglecrawl', function()
    if crawlKeyDown then return end
    crawlKeyDown = true
    local ped = PlayerPedId()
    if not canChangeStance(ped) then return end

    if stance == CRAWL then
        standUp(ped)
    else
        crawl(ped)
    end
end, false)

RegisterCommand('-togglecrawl', function()
    crawlKeyDown = false
end, false)

RegisterKeyMapping(
    '+togglecrouch',
    'Toggle Crouch / Stand',
    'keyboard',
    (Config.MovementStance and Config.MovementStance.CrouchKey) or 'LCONTROL'
)

RegisterKeyMapping(
    '+togglecrawl',
    'Toggle Crawl / Stand',
    'keyboard',
    (Config.MovementStance and Config.MovementStance.CrawlKey) or 'Z'
)

CreateThread(function()
    while true do
        local waitTime = 250
        local ped = PlayerPedId()
        local onFoot = not IsPedInAnyVehicle(ped, false)

        -- Replace GTA's built-in CTRL stealth toggle while the player is on foot.
        if onFoot and not IsEntityDead(ped) then
            waitTime = 0
            DisableControlAction(0, 36, true)
        end

        if stance ~= STAND then
            waitTime = 0

            if not onFoot or IsEntityDead(ped) or IsPedRagdoll(ped) then
                standUp(ped)
            elseif stance == CROUCH then
                if not HasAnimSetLoaded(crouchClipset) then
                    requestClipset(crouchClipset)
                end
                if not HasAnimSetLoaded(crouchStrafeClipset) then
                    requestClipset(crouchStrafeClipset)
                end
                SetPedMovementClipset(ped, crouchClipset, 0.25)
                SetPedStrafeClipset(ped, crouchStrafeClipset)
                EnableControlAction(0, 24, true) -- attack / fire
                EnableControlAction(0, 25, true) -- aim
                EnableControlAction(0, 37, true) -- weapon wheel
            elseif stance == CRAWL then
                DisableControlAction(0, 21, true) -- sprint
                DisableControlAction(0, 22, true) -- jump

                local movingForward = IsControlPressed(0, 32)
                local movingBackward = IsControlPressed(0, 33)
                local clip = movingBackward and 'onfront_bwd' or 'onfront_fwd'
                local speed = (movingForward or movingBackward) and 1.0 or 0.0

                if not IsEntityPlayingAnim(ped, crawlDict, clip, 3) then
                    TaskPlayAnim(ped, crawlDict, clip, 8.0, -8.0, -1, 1, speed, false, false, false)
                else
                    SetEntityAnimSpeed(ped, crawlDict, clip, speed)
                end

                local heading = GetEntityHeading(ped)
                if IsControlPressed(0, 34) then
                    SetEntityHeading(ped, heading + 1.2)
                elseif IsControlPressed(0, 35) then
                    SetEntityHeading(ped, heading - 1.2)
                end
            end
        end

        Wait(waitTime)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        standUp(PlayerPedId())
    end
end)
