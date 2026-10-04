local crouched = false
local crawling = false
local crawlClip = nil

local CROUCH_CLIPSET = 'move_ped_crouched'
local CROUCH_STRAFE_CLIPSET = 'move_ped_crouched_strafing'
local CRAWL_DICT = 'move_crawl'

local function loadClipset(name)
    RequestAnimSet(name)
    local timeout = GetGameTimer() + 3000
    while not HasAnimSetLoaded(name) and GetGameTimer() < timeout do
        Wait(10)
    end
    return HasAnimSetLoaded(name)
end

local function loadAnimDict(name)
    RequestAnimDict(name)
    local timeout = GetGameTimer() + 3000
    while not HasAnimDictLoaded(name) and GetGameTimer() < timeout do
        Wait(10)
    end
    return HasAnimDictLoaded(name)
end

local function stopCrouching(ped)
    crouched = false
    ResetPedMovementClipset(ped, 0.25)
    ResetPedStrafeClipset(ped)
    SetPedStealthMovement(ped, false, 0)
end

local function stopCrawling(ped)
    crawling = false
    crawlClip = nil
    StopAnimTask(ped, CRAWL_DICT, 'onfront_fwd', 1.5)
    StopAnimTask(ped, CRAWL_DICT, 'onfront_bwd', 1.5)
    ClearPedSecondaryTask(ped)
end

local function resetMovement(ped)
    if crouched then stopCrouching(ped) end
    if crawling then stopCrawling(ped) end
end

local function canChangeStance(ped)
    return not IsEntityDead(ped)
        and not IsPedInAnyVehicle(ped, false)
        and not IsPedRagdoll(ped)
        and not IsPedFalling(ped)
end

local function startCrouching(ped)
    if not loadClipset(CROUCH_CLIPSET) or not loadClipset(CROUCH_STRAFE_CLIPSET) then
        return false
    end

    crouched = true
    SetPedMovementClipset(ped, CROUCH_CLIPSET, 0.25)
    SetPedStrafeClipset(ped, CROUCH_STRAFE_CLIPSET)
    SetPedStealthMovement(ped, false, 0)
    return true
end

local function startCrawling(ped)
    if not loadAnimDict(CRAWL_DICT) then return false end

    crawling = true
    crawlClip = 'onfront_fwd'
    TaskPlayAnim(ped, CRAWL_DICT, crawlClip, 4.0, -4.0, -1, 1, 0.0, false, false, false)
    SetEntityAnimSpeed(ped, CRAWL_DICT, crawlClip, 0.0)
    return true
end

RegisterCommand('crouchtoggle', function()
    local ped = PlayerPedId()
    if not canChangeStance(ped) then return end

    -- CTRL cycles: standing -> crouch -> crawl -> standing.
    if crawling then
        stopCrawling(ped)
    elseif crouched then
        stopCrouching(ped)
        startCrawling(ped)
    else
        startCrouching(ped)
    end
end, false)

RegisterKeyMapping('crouchtoggle', 'Cycle Crouch / Crawl / Stand', 'keyboard', 'LCONTROL')

RegisterCommand('crawltoggle', function()
    local ped = PlayerPedId()
    if not canChangeStance(ped) then return end

    if crawling then
        stopCrawling(ped)
        return
    end

    if crouched then stopCrouching(ped) end
    startCrawling(ped)
end, false)

CreateThread(function()
    while true do
        local waitTime = 250
        local ped = PlayerPedId()

        if (crouched or crawling) and (IsEntityDead(ped) or IsPedInAnyVehicle(ped, false)) then
            resetMovement(ped)
        end

        if crouched then
            waitTime = 0
            DisableControlAction(0, 36, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 21, true)
        elseif crawling then
            waitTime = 0
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 23, true)
            DisableControlAction(0, 36, true)

            local nextClip = nil
            if IsControlPressed(0, 32) then
                nextClip = 'onfront_fwd'
            elseif IsControlPressed(0, 33) then
                nextClip = 'onfront_bwd'
            end

            if IsControlPressed(0, 34) then
                SetEntityHeading(ped, GetEntityHeading(ped) + 1.2)
            elseif IsControlPressed(0, 35) then
                SetEntityHeading(ped, GetEntityHeading(ped) - 1.2)
            end

            if nextClip then
                if crawlClip ~= nextClip or not IsEntityPlayingAnim(ped, CRAWL_DICT, nextClip, 3) then
                    crawlClip = nextClip
                    TaskPlayAnim(ped, CRAWL_DICT, crawlClip, 4.0, -4.0, -1, 1, 0.0, false, false, false)
                end
                SetEntityAnimSpeed(ped, CRAWL_DICT, crawlClip, 1.0)
            elseif crawlClip and IsEntityPlayingAnim(ped, CRAWL_DICT, crawlClip, 3) then
                SetEntityAnimSpeed(ped, CRAWL_DICT, crawlClip, 0.0)
            end
        end

        Wait(waitTime)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        resetMovement(PlayerPedId())
    end
end)
