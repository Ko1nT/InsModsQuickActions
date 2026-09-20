require "ISUI/Maps/ISWorldMapSymbols"
require "ISUI/ISRadialMenu"
require "TimedActions/ISReadWorldMap"
require "TimedActions/ISBaseTimedAction" 
require "TimedActions/ISUnequipAction"
require "TimedActions/ISWearClothing"
require "TimedActions/ISInventoryTransferAction"

function addCustomBind() 
    table.insert(keyBinding, { value = "IMQAOpenMaskMenu", key = Keyboard.KEY_TAB })
end

Events.OnGameBoot.Add(addCustomBind)

IMQA = {}

masksTypes = {
    {name = "NBC Mask", id = "Base.Hat_NBCmask"},
    {name = "Gas Mask", id = "Base.Hat_GasMask"},
    {name = "Respirator", id = "Base.Hat_BuildersRespirator"},
    {name = "Improvised Gas Mask", id = "Base.Hat_ImprovisedGasMask"},
    {name = "Surgical Mask Blue", id = "Base.Hat_SurgicalMask_Blue"},
    {name = "Surgical Mask", id = "Base.Hat_SurgicalMask"},
    {name = "Dusk Mask", id = "Base.Hat_DustMask"},
    {name = "Bandana Mask", id = "Base.Hat_BandanaMask"},
    {name = "Green Bandana Mask", id = "Base.Hat_BandanaMask_Green"},
    {name = "Rag Mask", id = "Base.Hat_RagBandanaMask"},
    {name = "NBC Mask (NF)", id = "Base.Hat_NBCmask_nofilter"},
    {name = "Gas Mask (NF)", id = "Base.Hat_GasMask_nofilter"},
    {name = "Respirator (NF)", id = "Base.Hat_BuildersRespirator_nofilter"},
    {name = "Improvised Gas Mask (NF)", id = "Base.Hat_ImprovisedGasMask_nofilter"}
}
LOCATION_MASK = "Mask"
LOCATION_MASKEYES = "MaskEyes"
LOCATION_MASK_FULLHAT = "FullHat"
ENEQUIP_TIME = 30
EQUIP_TIME = 60
masksLocation = {
    {name = "mask", location = "Mask"},
    {name = "MaskEyes", location = "MaskEyes"},
    {name = "mask", location = "FullHat"}
}
masksGasFilters = {
    "Base.GasmaskFilter",
    "Base.GasmaskFilterCrafted"
}
maskRespiratorFilters = {
    "Base.RespiratorFilters",
    "Base.RespiratorFiltersRecharged"
}
foundMask = {name = nil, id = nil}
local radialMenu = nil
local x
local y
local _uiByPID = {}
local SYMBOL_SCALE = 0.4




IMQARadialMenu = ISRadialMenu:derive("IMQARadialMenu")

function IMQARadialMenu:new(player)
    local menu = getPlayerRadialMenu(player:getPlayerNum())
    x = getPlayerScreenLeft(player:getPlayerNum()) + getPlayerScreenWidth(player:getPlayerNum()) / 2 - menu:getWidth() / 2
    y = getPlayerScreenTop(player:getPlayerNum()) + getPlayerScreenHeight(player:getPlayerNum()) / 2 - menu:getHeight() / 2
    local o = ISRadialMenu:new(x,y,100,180,player)
    setmetatable(o, self)
    self.__index = self
    o.player = player
    return o
end

function IMQARadialMenu:fillMenu()
    -- local fullPath = "media/ui/LootableMaps/" .. data.tid .. ".png"
    local playerNum = 0
	local playerObj = getSpecificPlayer(0)

    self:clear()

    local inv = getCharacterInventory(playerObj) or nil 
    if not inv then return false end

    if isWoreMask(playerObj) then 
        self:addSlice("Take off mask", getTexture("media/ui/LootableMaps/map_x.png"), 
        function()
            IMQARadialMenu:takeOffMask(playerObj, inv)
        end, playerObj)
    else 
        if isHasMask(inv) then 
            self:addSlice("Equip a " .. foundMask.name, getTexture("media/ui/LootableMaps/map_x.png"), 
            function() 
                IMQARadialMenu:equipMask(playerObj, inv)
            end, playerObj)
        end
    end

    self:setX(x)
    self:setY(y)

    self:addToUIManager()
end

function IMQARadialMenu:equipMask(playerObj, inv)
    DebugLog.log("IMQARadialMenu:equipMask Found mask: " .. foundMask.name .. " id: " .. foundMask.id)

    local item = inv:getFirstTypeRecurse(foundMask.id)
    if item then
        local itemContainer = item:getContainer() -- контейнер, в котором предмет реально лежит

        if itemContainer and itemContainer ~= inv then
            -- предмет вложен в сумку — сначала перекладываем его в основной инвентарь
            ISTimedActionQueue.add(ISInventoryTransferAction:new(playerObj, item, itemContainer, inv))
        end

        ISTimedActionQueue.add(ISWearClothing:new(playerObj, item))
    end

    foundMask = {name = nil, id = nil}
end

function IMQARadialMenu:takeOffMask(playerObj, inv)
    DebugLog.log("IMQARadialMenu:takeOffMask Found mask: " .. foundMask.name .. " id: " .. foundMask.id)
    ISTimedActionQueue.add(ISUnequipAction:new(playerObj, inv:getFirstTypeRecurse(foundMask.id), ENEQUIP_TIME, "remove"))
    foundMask = {name = nil, id = nil}
end 

function getCharacterInventory(playerObj)
    local inv = playerObj:getInventory() or nil

    if not inv then return false else return inv end
end

function isWoreMask(player)
    local mask = player:getWornItem(ItemBodyLocation.MASK)
    if isProtectiveMask(mask) then foundMask = {name = mask:getName(), id = mask:getFullType()} return true end

    local maskEyes = player:getWornItem(ItemBodyLocation.MASK_EYES)
    if isProtectiveMask(maskEyes) then foundMask = {name = maskEyes:getName(), id = maskEyes:getFullType()} return true end

    local maskHat = player:getWornItem(ItemBodyLocation.FULL_HAT)
    if isProtectiveMask(maskHat) then foundMask = {name = maskHat:getName(), id = maskHat:getFullType()} return true end

    return false
end

function isProtectiveMask(item) 
    if not item then return false end
    for _, data in ipairs(masksTypes) do 
        if data.id == item:getFullType() then return true end
    end
    return false 
end

function isHasMask(inv) 
    for _, data in ipairs(masksTypes) do
        if inv:containsType(data.id) then 
            foundMask = {name = data.name, id = data.id} 
            return true 
        end
    end
    for _, data in ipairs(masksTypes) do
        if inv:containsTypeRecurse(data.id) then 
            foundMask = {name = data.name, id = data.id} 
            return true 
        end
    end
    return false
end

local HOLD_THRESHOLD = 300 -- мс, сколько нужно удерживать клавишу
local keyHeldSince = nil
local menuOpenedByHold = false

local function checkKeyHold()
    if isKeyDown(getCore():getKey("IMQAOpenMaskMenu")) then
        if keyHeldSince == nil then
            keyHeldSince = getTimestampMs()
        elseif not menuOpenedByHold and (getTimestampMs() - keyHeldSince) >= HOLD_THRESHOLD then
            -- порог удержания достигнут - открываем радиальное меню
            local player = getSpecificPlayer(0)
            if player and not player:isDead() and not isGamePaused() then
                if radialMenu == nil then
                    radialMenu = IMQARadialMenu:new(player)
                end
                if not radialMenu:isReallyVisible() then
                    radialMenu:fillMenu()
                end
                menuOpenedByHold = true
            end
        end
    else
        -- клавиша отпущена - сброс
        keyHeldSince = nil
        if menuOpenedByHold then
            menuOpenedByHold = false
            -- опционально: закрыть меню при отпускании клавиши,
            -- как это работает в ванильных меню (hold R / hold F)
            if radialMenu ~= nil and radialMenu:isReallyVisible() then
                radialMenu:undisplay()
            end
        end
    end
end

Events.OnTick.Add(checkKeyHold)