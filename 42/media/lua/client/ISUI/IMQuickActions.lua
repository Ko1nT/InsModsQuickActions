require "ISUI/Maps/ISWorldMapSymbols"
require "ISUI/ISRadialMenu"
require "TimedActions/ISReadWorldMap"
require "TimedActions/ISBaseTimedAction"

local IMQA = {}

IMQARadialMenu.masksTypes = {
    {name = "Dusk Mask", id = "Base.Hat_DustMask"},
    {name = "Bandana Mask", id = "Base.Hat_BandanaMask"},
    {name = "Green Bandana Mask", id = "Base.Hat_BandanaMask_Green"},
    {name = "Gas Mask", id = "Base.Hat_GasMask"},
    {name = "Gas Mask (NF)", id = "Base.Hat_GasMask_nofilter"},
    {name = "Improvised Gas Mask", id = "Base.Hat_ImprovisedGasMask"},
    {name = "Improvised Gas Mask (NF)", id = "Base.Hat_ImprovisedGasMask_nofilter"},
    {name = "Surgical Mask", id = "Base.Hat_SurgicalMask_Blue"},
    {name = "NBC Mask", id = "Base.Hat_NBCmask"},
    {name = "NBC Mask (NF)", id = "Base.Hat_NBCmask_nofilter"},
    {name = "Rag Mask", id = "Base.Hat_RagBandanaMask"},
    {name = "Surgical Mask", id = "Base.Hat_SurgicalMask"},
    {name = "Respirator (NF)", id = "Base.Hat_BuildersRespirator_nofilter"},
    {name = "Respirator", id = "Base.Hat_BuildersRespirator"}
}
local LOCATION_MASK = "Mask"
local LOCATION_MASKEYES = "MaskEyes"
local LOCATION_MASK_FULLHAT = "FullHat"
local masksLocation = {
    {name = "mask", location = "Mask"},
    {name = "MaskEyes", location = "MaskEyes"},
    {name = "mask", location = "FullHat"}
}
local masksGasFilters = {
    "Base.GasmaskFilter",
    "Base.GasmaskFilterCrafted"
}
local maskRespiratorFilters = {
    "Base.RespiratorFilters",
    "Base.RespiratorFiltersRecharged"
}
local foundMask = nil
local radialMenu = nil
local x
local y
local _uiByPID = {}
local SYMBOL_SCALE = 0.4

function addCustomBind() 
    table.insert(keyBinding, { value = "[myClothesMen]", key = Keyboard.KEY_B })
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

    if isWoreMask(inv) then 
        self:addSlice("Take off mask", "media/ui/LootableMaps/X.png", 
        function()
            IMQARadialMenu:takeOffMask(playerObj, inv)
        end, playerObj)
    else 
        if isHasMask(playerObj) then 
            self:addSlice("Equip a mask", "media/ui/LootableMaps/X.png", 
            function() 
                IMQARadialMenu:equipMask()
            end, playerObj)
        end
    end

    self:setX(x)
    self:setY(y)

    self:addToUIManager()
end

function IMQARadialMenu:equipMask()
    return false
end

function IMQARadialMenu:takeOffMask(playerObj, inv)
    local mask = inv:getWornItem(ItemBodyLocation.MASK)
    local maskEyes = inv:getWornItem(ItemBodyLocation.MASK_EYES)
    local maskHat = inv:getWornItem(ItemBodyLocation.FULL_HAT)

    if isProtectiveMask(mask) then 
        playerObj:getWornItems():setItem(mask:canBeEquipped(), mask)
        return true 
    end
    if isProtectiveMask(maskEyes) then 
        playerObj:getWornItems():setItem(maskEyes:canBeEquipped(), maskEyes)
        return true 
    end
    if isProtectiveMask(maskHat) then 
        playerObj:getWornItems():setItem(maskHat:canBeEquipped(), maskHat)
        return true 
    end 

end 

function getCharacterInventory(playerObj)
    local inv = playerObj:getInventory() or nil

    if not inv then return false else return inv end
end

function isWoreMask(inv)
    local mask = inv:getWornItem(ItemBodyLocation.MASK)
    local maskEyes = inv:getWornItem(ItemBodyLocation.MASK_EYES)
    local maskHat = inv:getWornItem(ItemBodyLocation.FULL_HAT)

    if isProtectiveMask(mask) then return true end
    if isProtectiveMask(maskEyes) then return true end
    if isProtectiveMask(maskHat) then return true end 

    return false
end

function IMQARadialMenu:isProtectiveMask(item) 
    if not item then return false end
    for _, data in inpairs(IMQARadialMenu.masksTypes) do 
        if data.id == item:getFullType() then return true end
    end
    return false 
end

function isHasMask(inv) 
    local hasMask = false
    for _, data in inpairs(IMQARadialMenu.masksTypes) do 
        hasMask = inv:containsTypeRecurse(data.id)
        if hasMask then break end
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