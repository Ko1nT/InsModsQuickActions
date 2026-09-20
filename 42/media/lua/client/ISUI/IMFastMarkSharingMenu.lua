require "ISUI/Maps/ISWorldMapSymbols"
require "ISUI/ISRadialMenu"
require "TimedActions/ISReadWorldMap"
require "TimedActions/ISBaseTimedAction"

local IMQA = {}

local masksTypes = {
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
    table.insert(keyBinding, { value = "[myRadMen]", key = Keyboard.KEY_B })
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
    local playerNum = 0
	local playerObj = getSpecificPlayer(0)

    self:clear()

    local inv = getCharacterInventory(playerObj) or nil 
    if not inv return false end

    if inv:containsTypeRecurse()

    for _, data in ipairs(IMQA.Symbols) do 
        if canMark then
            local fullPath = "media/ui/LootableMaps/" .. data.tid .. ".png"
            self:addSlice(data.name, getTexture(fullPath), 
            function ()
                IMQARadialMenu:makeAndShareMark(playerObj, data.name)
            end, playerObj)
        else
            local fullPath = "media/ui/LootableMaps/" .. data.tid .. ".png"
            self:addSlice("Requre a red pen", getTexture(fullPath), 
            function ()
                return false
            end, playerObj)
        end
    end

    self:setX(x)
    self:setY(y)

    self:addToUIManager()
end

function IMQARadialMenu:makeAndShareMark(playerObj, sid)

    local playerNum = 0
	local playerObj = getSpecificPlayer(0)

    DebugLog.log("IMQA: trying to fetch the sympolAPI")
    local symapi = nil
    symapi = _getSymAPI(playerObj)
    if not symapi then return false end

    ISTimedActionQueue.add(IMQA_ISMakeMarkOnMap:new(playerObj))

    local newsym = symapi:addTexture(sid, playerObj:getX(), playerObj:getY())

    if newsym then
        newsym:setAnchor(0.5, 0.5)
        newsym:setRGBA(1, 0, 0, 1)
        newsym:setScale(SYMBOL_SCALE)
        newsym:setUserDefined(true)
        applySharing(newsym, shareOptions())
        DebugLog.log("IMQA: Shared Symbol: " .. tostring(sid)) 
    end

    DebugLog.log(tostring(newsym))

end 

function getCharacterInventory(playerObj)
    local inv = playerObj:getInventory() or nil

    if not inv then return false else return inv end
end

function isWoreMask(inv)
    local mask = inv:getWornItem(LOCATION_MASK)
    local maskEyes = inv:getWornItem(LOCATION_MASKEYES)
    local maskHat = inv:getWornItem(LOCATION_MASK_FULLHAT)

    if isProtectiveMask(mask) then return true end
    if isProtectiveMask(maskEyes) then return true end
    if isProtectiveMask(maskHat) then return true end 

    return false
end

function isProtectiveMask(item) 
    for _, data in inpairs(masksTypes) do 
        if data.id == item:getFullType() then return true
    end
    return false 
end

function isHasMask(inv) 
    local hasMask = false
    for _, data in inpairs(masksTypes) do 
        hasMask = inv:containsTypeRecurse(data.id)
        if hasMask then break end
    end
    return hasMask
end



function isHasRedPen(playerObj)
    local inv = playerObj:getInventory() or nil

    if not inv then return false end 

    local hasCrayons = inv:containsTypeRecurse("Base.Crayons")
    local hasRedPen = inv:containsTypeRecurse("Base.RedPen")
    local hasRedMarker = inv:containsTypeRecurse("Base.RedMarker")

    return hasCrayons or hasRedMarker or hasRedPen
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

function IMQA.OnGameStart()
    local p = getPlayer(); if not p then return end
    _ensureHiddenMap(p)
end

Events.OnKeyPressed.Add(IMQARadialMenu.onKeyPressed)