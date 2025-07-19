local RSGCore = exports['rsg-core']:GetCoreObject()

local function ValidateScale(scale)
    if not scale or type(scale) ~= "number" then
        return false
    end
    return scale >= Config.MinScale and scale <= Config.MaxScale
end

local function LogScaleChange(source, action, scale, targetId)
    if not Config.EnableLogging then return end
    
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player then
        local logMessage = '[PED SCALE] ' .. Player.PlayerData.name .. ' (' .. source .. ') ' .. action
        
        if scale then
            logMessage = logMessage .. ' scale to ' .. scale
        end
        
        if targetId then
            local TargetPlayer = RSGCore.Functions.GetPlayer(targetId)
            if TargetPlayer then
                logMessage = logMessage .. ' for player ' .. TargetPlayer.PlayerData.name .. ' (' .. targetId .. ')'
            else
                logMessage = logMessage .. ' for player ID ' .. targetId
            end
        end
        
        print(logMessage)
    end
end

-- Check if player has size potion and sufficient quantity
local function HasSizePotion(source, requiredAmount)
    requiredAmount = requiredAmount or 1
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local potionItem = Player.Functions.GetItemByName('size_potion')
    return potionItem and potionItem.amount >= requiredAmount
end

-- Consume size potion from player inventory
local function ConsumeSizePotion(source, amount)
    amount = amount or 1
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local potionItem = Player.Functions.GetItemByName('size_potion')
    if potionItem and potionItem.amount >= amount then
        Player.Functions.RemoveItem('size_potion', amount)
        return true
    end
    return false
end

-- Player loaded event
RegisterNetEvent('RSGCore:Server:PlayerLoaded', function(Player)
    if not Player then return end
    
    TriggerClientEvent('pedscale:applyScaleToPlayer', -1, Player.PlayerData.source, Config.DefaultScale or 1.0)
    LogScaleChange(Player.PlayerData.source, 'loaded with default', Config.DefaultScale or 1.0)
end)

-- Regular scale request (for self)
RegisterNetEvent('pedscale:requestScale', function(scale)
    local source = source
    
    if not ValidateScale(scale) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Scale must be between ' .. (Config.MinScale or 0.1) .. ' and ' .. (Config.MaxScale or 3.0)
        })
        return
    end
    
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player then
        TriggerClientEvent('pedscale:applyScaleToPlayer', -1, source, scale)
        LogScaleChange(source, 'changed their', scale)
        
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'success',
            description = 'Your size has been changed to ' .. scale
        })
    end
end)

-- Target scale request (for other players)
RegisterNetEvent('pedscale:requestTargetScale', function(targetId, scale)
    local source = source
    
    if not ValidateScale(scale) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Scale must be between ' .. (Config.MinScale or 0.1) .. ' and ' .. (Config.MaxScale or 3.0)
        })
        return
    end
    
    -- Check if source player has size potion
    if not HasSizePotion(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'You need a size potion to change other players\' size'
        })
        return
    end
    
    local Player = RSGCore.Functions.GetPlayer(source)
    local TargetPlayer = RSGCore.Functions.GetPlayer(targetId)
    
    if not Player or not TargetPlayer then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Player not found'
        })
        return
    end
    
    -- Check cooldown
    local currentTime = os.time()
    if Player.PlayerData.metadata.lastTargetPotionUse and 
       (currentTime - Player.PlayerData.metadata.lastTargetPotionUse) < (Config.TargetPotionCooldown or 10) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'You must wait before using another potion on other players'
        })
        return
    end
    
    -- Consume size potion
    if not ConsumeSizePotion(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Failed to use size potion'
        })
        return
    end
    
    -- Set cooldown
    Player.Functions.SetMetaData('lastTargetPotionUse', currentTime)
    
    -- Apply scale to target
    TriggerClientEvent('pedscale:applyScaleToPlayer', -1, targetId, scale)
    LogScaleChange(source, 'changed target', scale, targetId)
    
    -- Notify both players
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = 'Changed ' .. TargetPlayer.PlayerData.name .. '\'s size to ' .. scale
    })
    
    TriggerClientEvent('ox_lib:notify', targetId, {
        type = 'inform',
        description = Player.PlayerData.name .. ' changed your size to ' .. scale
    })
    
    if Config.EnablePersistence then
        TriggerEvent('pedscale:saveTargetScale', targetId, scale)
    end
end)

-- Target reset request
RegisterNetEvent('pedscale:requestTargetReset', function(targetId)
    local source = source
    
    -- Check if source player has size potion
    if not HasSizePotion(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'You need a size potion to reset other players\' size'
        })
        return
    end
    
    local Player = RSGCore.Functions.GetPlayer(source)
    local TargetPlayer = RSGCore.Functions.GetPlayer(targetId)
    
    if not Player or not TargetPlayer then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Player not found'
        })
        return
    end
    
    -- Check cooldown
    local currentTime = os.time()
    if Player.PlayerData.metadata.lastTargetPotionUse and 
       (currentTime - Player.PlayerData.metadata.lastTargetPotionUse) < (Config.TargetPotionCooldown or 10) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'You must wait before using another potion on other players'
        })
        return
    end
    
    -- Consume size potion
    if not ConsumeSizePotion(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Failed to use size potion'
        })
        return
    end
    
    -- Set cooldown
    Player.Functions.SetMetaData('lastTargetPotionUse', currentTime)
    
    local defaultScale = Config.DefaultScale or 1.0
    
    -- Apply default scale to target
    TriggerClientEvent('pedscale:applyScaleToPlayer', -1, targetId, defaultScale)
    LogScaleChange(source, 'reset target', defaultScale, targetId)
    
    -- Notify both players
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = 'Reset ' .. TargetPlayer.PlayerData.name .. '\'s size to normal'
    })
    
    TriggerClientEvent('ox_lib:notify', targetId, {
        type = 'success',
        description = Player.PlayerData.name .. ' reset your size to normal'
    })
    
    if Config.EnablePersistence then
        TriggerEvent('pedscale:saveTargetScale', targetId, defaultScale)
    end
end)

-- Check if player has potion and open target menu
RegisterNetEvent('pedscale:checkPotionAndOpenTargetMenu', function(targetId)
    local source = source
    
    if not HasSizePotion(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'You need a size potion to change other players\' size'
        })
        return
    end
    
    local Player = RSGCore.Functions.GetPlayer(source)
    local TargetPlayer = RSGCore.Functions.GetPlayer(targetId)
    
    if not Player or not TargetPlayer then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Player not found'
        })
        return
    end
    
    -- Check cooldown
    local currentTime = os.time()
    if Player.PlayerData.metadata.lastTargetPotionUse and 
       (currentTime - Player.PlayerData.metadata.lastTargetPotionUse) < (Config.TargetPotionCooldown or 10) then
        local remainingTime = (Config.TargetPotionCooldown or 10) - (currentTime - Player.PlayerData.metadata.lastTargetPotionUse)
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'You must wait ' .. remainingTime .. ' seconds before using another potion on other players'
        })
        return
    end
    
    -- Open target menu
    TriggerClientEvent('pedscale:openTargetMenu', source, targetId)
end)

-- Regular reset request (for self)
RegisterNetEvent('pedscale:requestReset', function()
    local source = source
    
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player then
        local defaultScale = Config.DefaultScale or 1.0
        
        TriggerClientEvent('pedscale:applyScaleToPlayer', -1, source, defaultScale)
        LogScaleChange(source, 'reset their', defaultScale)
        
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'success',
            description = 'Your size has been reset to normal'
        })
    end
end)

-- Player disconnected event
AddEventHandler('playerDropped', function(reason)
    local source = source
    local Player = RSGCore.Functions.GetPlayer(source)
    
    if Player then
        LogScaleChange(source, 'disconnected', nil)
    end
end)

-- Response current scale
RegisterNetEvent('pedscale:responseCurrentScale', function(scale)
    local source = source
    local Player = RSGCore.Functions.GetPlayer(source)
    
    if Player then
        LogScaleChange(source, 'reported current', scale)
    end
end)

-- Request all scales (for new players)
RegisterNetEvent('pedscale:requestAllScales', function()
    local source = source
    local Players = RSGCore.Functions.GetPlayers()
    
    for _, Player in pairs(Players) do
        if Player and Player.PlayerData.source ~= source then
            local playerScale = Config.DefaultScale or 1.0
            
            if Config.EnablePersistence and Player.PlayerData.metadata.pedscale then
                playerScale = Player.PlayerData.metadata.pedscale
            end
            
            TriggerClientEvent('pedscale:applyScaleToPlayer', source, Player.PlayerData.source, playerScale)
        end
    end
end)

-- Admin set scale
RegisterNetEvent('pedscale:adminSetScale', function(targetId, scale)
    local source = source
    local Player = RSGCore.Functions.GetPlayer(source)
    
    if not Player then return end
    
    if not RSGCore.Functions.HasPermission(source, 'admin') then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'You do not have permission to use this command'
        })
        return
    end
    
    if not ValidateScale(scale) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Scale must be between ' .. (Config.MinScale or 0.1) .. ' and ' .. (Config.MaxScale or 3.0)
        })
        return
    end
    
    local TargetPlayer = RSGCore.Functions.GetPlayer(targetId)
    if TargetPlayer then
        TriggerClientEvent('pedscale:applyScaleToPlayer', -1, targetId, scale)
        LogScaleChange(source, 'admin set', scale, targetId)
        
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'success',
            description = 'Set player ' .. TargetPlayer.PlayerData.name .. ' scale to ' .. scale
        })
        
        TriggerClientEvent('ox_lib:notify', targetId, {
            type = 'inform',
            description = 'Your size has been changed by an admin to ' .. scale
        })
    else
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Player not found'
        })
    end
end)

-- Size potion useable item
RSGCore.Functions.CreateUseableItem("size_potion", function(source, item)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local currentTime = os.time()
    if Player.PlayerData.metadata.lastPotionUse and 
       (currentTime - Player.PlayerData.metadata.lastPotionUse) < (Config.PotionCooldown or 5) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'You must wait before using another potion'
        })
        return
    end
    
    Player.Functions.SetMetaData('lastPotionUse', currentTime)
    
    TriggerClientEvent('pedscale:openMenu', source)
    LogScaleChange(source, 'used size potion', nil)
end)

-- Admin chat command
RSGCore.Commands.Add('setscale', 'Set player scale (Admin Only)', {
    {name = 'id', help = 'Player ID'},
    {name = 'scale', help = 'Scale value'}
}, false, function(source, args)
    local targetId = tonumber(args[1])
    local scale = tonumber(args[2])
    
    if not targetId or not scale then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Usage: /setscale [playerid] [scale]'
        })
        return
    end
    
    TriggerEvent('pedscale:adminSetScale', targetId, scale)
end, 'admin')

-- Export functions
exports('ValidateScale', ValidateScale)
exports('LogScaleChange', LogScaleChange)
exports('HasSizePotion', HasSizePotion)
exports('ConsumeSizePotion', ConsumeSizePotion)

-- Persistence functionality
if Config.EnablePersistence then
    local function SavePlayerScale(source, scale)
        local Player = RSGCore.Functions.GetPlayer(source)
        if Player then
            Player.Functions.SetMetaData('pedscale', scale)
        end
    end
    
    local function LoadPlayerScale(source)
        local Player = RSGCore.Functions.GetPlayer(source)
        if Player then
            local savedScale = Player.PlayerData.metadata.pedscale
            if savedScale and ValidateScale(savedScale) then
                return savedScale
            end
        end
        return Config.DefaultScale or 1.0
    end
    
    RegisterNetEvent('RSGCore:Server:PlayerLoaded', function(Player)
        if not Player then return end
        
        local savedScale = LoadPlayerScale(Player.PlayerData.source)
        
        TriggerClientEvent('pedscale:applyScaleToPlayer', -1, Player.PlayerData.source, savedScale)
        LogScaleChange(Player.PlayerData.source, 'loaded with saved', savedScale)
    end)
    
    RegisterNetEvent('pedscale:saveScale', function(scale)
        local source = source
        SavePlayerScale(source, scale)
    end)
    
    RegisterNetEvent('pedscale:saveTargetScale', function(targetId, scale)
        SavePlayerScale(targetId, scale)
    end)
    
    exports('SavePlayerScale', SavePlayerScale)
    exports('LoadPlayerScale', LoadPlayerScale)
end
