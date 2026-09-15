if isServer() then return end

local TraitShop = require("OMHTS_Bootstrap")
local Catalog = require("OMHTS_Catalog")
local states = {}
local awaiting = {}
local purchases = {}
local nextRequest = 0
local counters = { "lifeId", "revision", "tokens", "level", "retainedPrestige", "earnedPrestige", "pendingPrestige", "startingTokens" }
local statuses = { available = true, owned = true, conflict = true, dead = true, loading = true,
    funds = true, unsupported = true, settings = true }
local results = { purchased = true, busy = true, invalid = true, dead = true, stale = true, price_changed = true,
    owned = true, conflict = true, funds = true, unsupported = true, settings = true, loading = true }

---@param snapshot any
---@return nil
function TraitShop.acceptState(snapshot)
    if type(snapshot) ~= "table" or snapshot.schema ~= 2
        or type(snapshot.playerNum) ~= "number" or snapshot.playerNum < 0
        or snapshot.playerNum > 3 or snapshot.playerNum ~= math.floor(snapshot.playerNum)
        or (snapshot.status ~= "alive" and snapshot.status ~= "dead")
        or type(snapshot.unofficial) ~= "boolean" or type(snapshot.offers) ~= "table"
        or #snapshot.offers ~= #Catalog.entries then return end
    if snapshot.creationStatus ~= "pending" and snapshot.creationStatus ~= "granted"
        and snapshot.creationStatus ~= "legacy" and snapshot.creationStatus ~= "invalid" then return end
    local copy = {}
    for index = 1, #counters do
        local key = counters[index]
        local value = snapshot[key]
        if type(value) ~= "number" or value < 0 or value > 1000000000
            or value ~= math.floor(value) then return end
        copy[key] = value
    end
    if type(snapshot.xp) ~= "number" or not (snapshot.xp >= 0 and snapshot.xp <= 1000000000) then return end
    copy.offers = {}
    for index = 1, #Catalog.entries do
        local offer = snapshot.offers[index]
        if type(offer) ~= "table" or offer.id ~= Catalog.entries[index].id
            or not statuses[offer.status] or type(offer.price) ~= "number"
            or offer.price < 0 or offer.price > 1000000000 or offer.price ~= math.floor(offer.price) then return end
        copy.offers[index] = { id = offer.id, status = offer.status, price = offer.price }
    end
    local previous = states[snapshot.playerNum]
    if previous and (snapshot.lifeId < previous.lifeId
        or (snapshot.lifeId == previous.lifeId and snapshot.revision < previous.revision)) then return end
    copy.schema = 2
    copy.playerNum = snapshot.playerNum
    copy.status = snapshot.status
    copy.xp = snapshot.xp
    copy.unofficial = snapshot.unofficial
    copy.creationStatus = snapshot.creationStatus
    if results[snapshot.result] then
        copy.result = snapshot.result
    elseif previous and previous.lifeId == copy.lifeId then
        copy.result = previous.result
    end
    local pending = purchases[snapshot.playerNum]
    if pending and (pending.lifeId ~= copy.lifeId or copy.revision > pending.revision
        or snapshot.requestRevision == pending.revision) then
        purchases[snapshot.playerNum] = nil
    end
    states[snapshot.playerNum] = copy
    awaiting[snapshot.playerNum] = nil
    if not previous or previous.lifeId ~= copy.lifeId then
        print("[OMH Trait Shop] client state ready; slot=" .. copy.playerNum .. "; life=" .. copy.lifeId)
    end
end

---@param playerNum number
---@return table|nil
function TraitShop.getState(playerNum)
    local state = states[playerNum]
    if not state then return nil end
    local copy = {}
    for key, value in pairs(state) do
        if key ~= "offers" then
            copy[key] = value
        end
    end
    copy.offers = {}
    for index = 1, #state.offers do
        local offer = state.offers[index]
        copy.offers[index] = { id = offer.id, status = offer.status, price = offer.price }
    end
    return copy
end

---@param playerNum number
---@param player IsoPlayer
---@return nil
function TraitShop.requestState(playerNum, player)
    if not player or player:isDead() then return end
    if isClient() then
        awaiting[playerNum] = true
        sendClientCommand(player, "OMHTraitShop", "requestState", {})
    elseif TraitShop.Authority then
        local snapshot = TraitShop.Authority.getState(player)
        if snapshot then
            TraitShop.acceptState(snapshot)
        end
    end
end

---@param player IsoPlayer
---@param id string
---@return boolean
function TraitShop.purchase(player, id)
    if not player or player:isDead() then return false end
    local slot = player:getPlayerNum()
    local state = states[slot]
    if not state or purchases[slot] then return false end
    for index = 1, #state.offers do
        local offer = state.offers[index]
        if offer.id == id and offer.status == "available" then
            local args = { lifeId = state.lifeId, revision = state.revision, traitId = id, price = offer.price }
            purchases[slot] = { lifeId = state.lifeId, revision = state.revision, sent = getTimestampMs() }
            if isClient() then
                sendClientCommand(player, "OMHTraitShop", "purchase", args)
            elseif TraitShop.Authority then
                TraitShop.Authority.purchase(player, args)
            end
            return true
        end
    end
    return false
end

---@nodiscard
---@param playerNum number
---@return boolean
function TraitShop.purchasePending(playerNum)
    return purchases[playerNum] ~= nil
end

---@return nil
local function reset()
    states = {}
    awaiting = {}
    purchases = {}
    nextRequest = 0
end

---@return nil
local function onGameStart()
    for index = 0, getNumActivePlayers() - 1 do
        TraitShop.requestState(index, getSpecificPlayer(index))
    end
end

---@return nil
local function retryRequests()
    if not isClient() then return end
    local now = getTimestampMs()
    if now < nextRequest then return end
    nextRequest = now + 5000
    for playerNum in pairs(awaiting) do
        TraitShop.requestState(playerNum, getSpecificPlayer(playerNum))
    end
    for playerNum, pending in pairs(purchases) do
        if now - pending.sent >= 10000 then
            purchases[playerNum] = nil
        end
        TraitShop.requestState(playerNum, getSpecificPlayer(playerNum))
    end
end

---@param module string
---@param command string
---@param args table
---@return nil
local function onServerCommand(module, command, args)
    if module == "OMHTraitShop" and command == "state" then
        TraitShop.acceptState(args)
    end
end

Events.OnInitGlobalModData.Add(reset)
Events.OnDisconnect.Add(reset)
Events.OnCreatePlayer.Add(TraitShop.requestState)
Events.OnGameStart.Add(onGameStart)
Events.OnServerCommand.Add(onServerCommand)
Events.OnTick.Add(retryRequests)
