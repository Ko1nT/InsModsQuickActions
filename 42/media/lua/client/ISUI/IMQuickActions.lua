require "ISUI/Maps/ISWorldMapSymbols"
require "ISUI/ISRadialMenu"
require "TimedActions/ISReadWorldMap"
require "TimedActions/ISBaseTimedAction" 
require "TimedActions/ISUnequipAction"
require "TimedActions/ISWearClothing"

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

function addCustomBind() 
    table.insert(keyBinding, { value = "[myClothesMen]", key = Keyboard.KEY_Z })
end

Events.OnGameStart.Add(addCustomBind)


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
            self:addSlice("Equip a mask", getTexture("media/ui/LootableMaps/map_x.png"), 
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
    ISTimedActionQueue.add(ISWearClothing:new(playerObj, inv:getFirstTypeRecurse(foundMask.id)))
    foundMask = {name = nil, id = nil}
    return false
end

function IMQARadialMenu:takeOffMask(playerObj, inv)
    local mask = playerObj:getWornItem(ItemBodyLocation.MASK)
    local maskEyes = playerObj:getWornItem(ItemBodyLocation.MASK_EYES)
    local maskHat = playerObj:getWornItem(ItemBodyLocation.FULL_HAT)

    local queue = ISTimedActionQueue.getTimedActionQueue(character)

    if isProtectiveMask(mask) then 
        ISTimedActionQueue.add(ISUnequipAction:new(playerObj, mask, ENEQUIP_TIME, "remove"))
        return true 
    end
    if isProtectiveMask(maskEyes) then 
        ISTimedActionQueue.add(ISUnequipAction:new(playerObj, maskEyes, ENEQUIP_TIME, "remove"))
        return true 
    end
    if isProtectiveMask(maskHat) then 
        ISTimedActionQueue.add(ISUnequipAction:new(playerObj, maskHat, ENEQUIP_TIME, "remove"))
        return true 
    end 

end 

function getCharacterInventory(playerObj)
    local inv = playerObj:getInventory() or nil

    if not inv then return false else return inv end
end

function isWoreMask(player)
    local mask = player:getWornItem(ItemBodyLocation.MASK)
    local maskEyes = player:getWornItem(ItemBodyLocation.MASK_EYES)
    local maskHat = player:getWornItem(ItemBodyLocation.FULL_HAT)

    if isProtectiveMask(mask) then return true end
    if isProtectiveMask(maskEyes) then return true end
    if isProtectiveMask(maskHat) then return true end 

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
    local hasMask = false
    for _, data in ipairs(masksTypes) do
        hasMask = inv:containsTypeRecurse(data.id)
        if hasMask then foundMask = {name = data.name, id = data.id} break end
    end
    return hasMask
end

function IMQARadialMenu.onKeyPressed(key)
    if key == Keyboard.KEY_Z then
        if isGamePaused() then return end

        local player = getSpecificPlayer(0)
        if not player or player:isDead() then return end

        if radialMenu == nil then 
            radialMenu = IMQARadialMenu:new(player)
        end 

        if radialMenu:isReallyVisible() then 
            radialMenu:undisplay()
        else
            radialMenu:fillMenu()
        end
    end
end

Events.OnKeyPressed.Add(IMQARadialMenu.onKeyPressed)