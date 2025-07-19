local RSGCore = exports['rsg-core']:GetCoreObject()
local currentScale = Config and Config.DefaultScale or 1.0
local isPlayerLoaded = false
local queuedScale = nil

local playerScales = {}

local function ApplyPedScale(playerPed, scale)
    local maxRetries = 5
    local retryDelay = 500
    local attempt = 1

    while not DoesEntityExist(playerPed) and attempt <= maxRetries do
        Wait(retryDelay)
        attempt = attempt + 1
    end

    if DoesEntityExist(playerPed) then
        SetPedScale(playerPed, scale)
        
        Wait(100)
        if not IsEntityVisible(playerPed) then
           
            SetPedScale(playerPed, Config.DefaultScale or 1.0)
            return false
        end
        return true
    else
        
        return false
    end
end

local function ApplyMyScale(scale)
    local playerPed = PlayerPedId()
    local success = ApplyPedScale(playerPed, scale)
    
    if success then
        currentScale = scale
        return true
    else
        currentScale = Config.DefaultScale or 1.0
        lib.notify({
            title = 'Error',
            description = 'Invalid scale applied, reset to default.',
            type = 'error'
        })
        return false
    end
end

local function ResetPedScale()
    ApplyMyScale(Config.DefaultScale or 1.0)
end

local function GetCurrentScale()
    return currentScale
end

local function GetPlayerPedFromServerId(serverId)
    local players = GetActivePlayers()
    for _, player in ipairs(players) do
        if GetPlayerServerId(player) == serverId then
            return GetPlayerPed(player)
        end
    end
    return nil
end

local function OpenSizeMenu(targetServerId)
    if not lib then
        return
    end

    local options = {}
    local isTargetingOther = targetServerId ~= nil
    
    local sizePresets = {
        { name = "Tiny", description = "Very small size (0.3)", scale = 0.3, icon = "fas fa-compress-alt" },
        { name = "Small", description = "Small size (0.6)", scale = 0.6, icon = "fas fa-compress" },
        { name = "Normal", description = "Default size (1.0)", scale = 1.0, icon = "fas fa-user" },
        { name = "Large", description = "Large size (1.5)", scale = 1.5, icon = "fas fa-expand" },
        { name = "Giant", description = "Very large size (2.0)", scale = 2.0, icon = "fas fa-expand-alt" },
        { name = "Colossal", description = "Massive size (3.0)", scale = 3.0, icon = "fas fa-mountain" }
    }
    
    if Config and Config.SizePresets then
        sizePresets = Config.SizePresets
    end
    
    for i, preset in ipairs(sizePresets) do
        if preset and preset.name and preset.scale and type(preset.name) == "string" and type(preset.scale) == "number" then
            table.insert(options, {
                title = preset.name,
                description = preset.description or "Size scale: " .. preset.scale,
                icon = preset.icon or "fas fa-user",
                onSelect = function()
                    if isTargetingOther then
                        TriggerServerEvent('pedscale:requestTargetScale', targetServerId, preset.scale)
                    else
                        TriggerServerEvent('pedscale:requestScale', preset.scale)
                    end
                end
            })
        end
    end
    
    table.insert(options, {
        title = 'Reset to Normal',
        description = 'Reset ' .. (isTargetingOther and 'target' or 'your') .. ' size to normal (1.0)',
        icon = 'fas fa-undo',
        onSelect = function()
            if isTargetingOther then
                TriggerServerEvent('pedscale:requestTargetReset', targetServerId)
            else
                TriggerServerEvent('pedscale:requestReset')
            end
        end
    })
    
    if not isTargetingOther then
        table.insert(options, {
            title = 'Current Scale: ' .. string.format("%.1f", currentScale),
            description = 'Your current size scale',
            icon = 'fas fa-info-circle',
            disabled = true
        })
    end
    
    if not options or type(options) ~= "table" or #options == 0 then
        lib.notify({
            title = 'Error',
            description = 'Failed to load menu options',
            type = 'error'
        })
        return
    end
    
    local menuTitle = isTargetingOther and 'Target Size Menu' or 'Size Potion Menu'
    
    lib.registerContext({
        id = isTargetingOther and 'target_size_menu' or 'size_potion_menu',
        title = menuTitle,
        options = options
    })
    
    lib.showContext(isTargetingOther and 'target_size_menu' or 'size_potion_menu')
end

-- Function to get player name from server ID
local function GetPlayerNameFromServerId(serverId)
    local players = GetActivePlayers()
    for _, player in ipairs(players) do
        if GetPlayerServerId(player) == serverId then
            return GetPlayerName(player)
        end
    end
    return "Unknown Player"
end

-- Setup ox-target for players
local function SetupPlayerTargeting()
    if not exports['ox_target'] then
        print("ox_target not found, player targeting disabled")
        return
    end
    
    exports['ox_target']:addGlobalPlayer({
        {
            name = 'change_player_size',
            icon = 'fas fa-expand-arrows-alt',
            label = 'Change Size',
            canInteract = function(entity, distance, coords, name)
                -- Only show if player has size potion or admin permissions
                local playerData = RSGCore.Functions.GetPlayerData()
                if not playerData then return false end
                
                -- Check if player has size potion item
                local hasPotion = false
                for _, item in pairs(playerData.items) do
                    if item.name == 'size_potion' and item.amount > 0 then
                        hasPotion = true
                        break
                    end
                end
                
                return hasPotion
            end,
            onSelect = function(data)
                local targetPed = data.entity
                if not targetPed then return end
                
                -- Get the target player's server ID
                local targetServerId = nil
                local players = GetActivePlayers()
                for _, player in ipairs(players) do
                    if GetPlayerPed(player) == targetPed then
                        targetServerId = GetPlayerServerId(player)
                        break
                    end
                end
                
                if targetServerId and targetServerId ~= GetPlayerServerId(PlayerId()) then
                    -- Check if player has a size potion before opening menu
                    TriggerServerEvent('pedscale:checkPotionAndOpenTargetMenu', targetServerId)
                else
                    lib.notify({
                        title = 'Error',
                        description = 'Cannot target yourself or invalid target',
                        type = 'error'
                    })
                end
            end,
        }
    })
end

-- Register network events
RegisterNetEvent('pedscale:applyScale', function(scale)
    if not isPlayerLoaded then
        queuedScale = scale
        return
    end
    ApplyMyScale(scale)
end)

RegisterNetEvent('pedscale:applyScaleToPlayer', function(playerId, scale)
    local myServerId = GetPlayerServerId(PlayerId())
    
    if playerId == myServerId then
        if not isPlayerLoaded then
            queuedScale = scale
            return
        end
        ApplyMyScale(scale)
    else
        local targetPed = GetPlayerPedFromServerId(playerId)
        if targetPed then
            ApplyPedScale(targetPed, scale)
        end
        
        playerScales[playerId] = scale
    end
end)

RegisterNetEvent('pedscale:resetScale', function()
    ResetPedScale()
    if isPlayerLoaded then
        lib.notify({
            title = 'Success',
            description = 'Size reset to normal',
            type = 'success'
        })
    end
end)

RegisterNetEvent('pedscale:showCurrentScale', function()
    lib.notify({
        title = 'Info',
        description = 'Current scale: ' .. GetCurrentScale(),
        type = 'inform'
    })
end)

RegisterNetEvent('pedscale:openMenu', function()
    CreateThread(function()
        Wait(200)
        OpenSizeMenu()
    end)
end)

RegisterNetEvent('pedscale:openTargetMenu', function(targetServerId)
    CreateThread(function()
        Wait(200)
        OpenSizeMenu(targetServerId)
    end)
end)

RegisterNetEvent('pedscale:requestCurrentScale', function()
    TriggerServerEvent('pedscale:responseCurrentScale', currentScale)
end)

RegisterCommand('checkscale', function(source, args)
    TriggerEvent('pedscale:showCurrentScale')
end)

-- Player events
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    isPlayerLoaded = true
    Wait(Config.PersistenceSettings and Config.PersistenceSettings.loadDelay or 2000)
    ApplyMyScale(Config.DefaultScale or 1.0)
    
    -- Setup targeting after player loads
    SetupPlayerTargeting()
end)

RegisterNetEvent('RSGCore:Client:OnPlayerSpawn', function()
    if not isPlayerLoaded then return end
    Wait(Config.PersistenceSettings and Config.PersistenceSettings.spawnDelay or 500)
    if queuedScale then
        ApplyMyScale(queuedScale)
        queuedScale = nil
    elseif currentScale ~= (Config.DefaultScale or 1.0) then
        ApplyMyScale(currentScale)
    end
end)

RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function()
    isPlayerLoaded = false
end)

-- Continuous scale maintenance thread
CreateThread(function()
    while true do
        Wait(1000) -- Check every second
        
        if isPlayerLoaded then
            local playerPed = PlayerPedId()
            if DoesEntityExist(playerPed) and currentScale ~= Config.DefaultScale then
                if math.abs(1.0 - currentScale) > 0.01 then
                    SetPedScale(playerPed, currentScale)
                end
            end
            
            local players = GetActivePlayers()
            for _, player in ipairs(players) do
                if player ~= PlayerId() then
                    local serverId = GetPlayerServerId(player)
                    local storedScale = playerScales[serverId]
                    if storedScale then
                        local playerPed = GetPlayerPed(player)
                        if DoesEntityExist(playerPed) then
                            SetPedScale(playerPed, storedScale)
                        end
                    end
                end
            end
        end
    end
end)

-- Event handlers
AddEventHandler('playerDropped', function(playerId)
    local serverId = GetPlayerServerId(playerId)
    if playerScales[serverId] then
        playerScales[serverId] = nil
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        TriggerServerEvent('pedscale:requestAllScales')
        
        -- Setup targeting when resource starts
        if isPlayerLoaded then
            SetupPlayerTargeting()
        end
    end
end)

-- Export functions
exports('ApplyPedScale', ApplyMyScale)
exports('ResetPedScale', ResetPedScale)
exports('GetCurrentScale', GetCurrentScale)

-- Wait for lib to be available
CreateThread(function()
    while not lib do
        Wait(100)
    end
end)
