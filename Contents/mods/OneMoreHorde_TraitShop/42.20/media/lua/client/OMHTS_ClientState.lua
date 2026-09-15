if isServer() then return end

local TraitShop = require("OMHTS_Bootstrap")
local states = {}
local awaiting = {}
local nextRequest = 0
local counters = { "lifeId", "revision", "tokens", "level", "retainedPrestige", "earnedPrestige", "pendingPrestige" }

---@param snapshot any
---@return nil
function TraitShop.acceptState(snapshot)
    if type(snapshot) ~= "table" or snapshot.schema ~= 1
        or type(snapshot.playerNum) ~= "number" or snapshot.playerNum < 0
        or snapshot.playerNum > 3 or snapshot.playerNum ~= math.floor(snapshot.playerNum)
        or (snapshot.status ~= "alive" and snapshot.status ~= "dead")
        or type(snapshot.unofficial) ~= "boolean" then return end
    local copy = {}
    for index = 1, #counters do
        local key = counters[index]
        local value = snapshot[key]
        if type(value) ~= "number" or value < 0 or value > 1000000000
            or value ~= math.floor(value) then return end
        copy[key] = value
    end
    if type(snapshot.xp) ~= "number" or not (snapshot.xp >= 0 and snapshot.xp <= 1000000000) then return end
    local previous = states[snapshot.playerNum]
    if previous and (snapshot.lifeId < previous.lifeId
        or (snapshot.lifeId == previous.lifeId and snapshot.revision < previous.revision)) then return end
    copy.schema = 1
    copy.playerNum = snapshot.playerNum
    copy.status = snapshot.status
    copy.xp = snapshot.xp
    copy.unofficial = snapshot.unofficial
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
        copy[key] = value
    end
    return copy
end

---@param playerNum number
---@param player IsoPlayer
---@return nil
local function requestState(playerNum, player)
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

---@return nil
local function reset()
    states = {}
    awaiting = {}
    nextRequest = 0
end

---@return nil
local function onGameStart()
    for index = 0, getNumActivePlayers() - 1 do
        requestState(index, getSpecificPlayer(index))
    end
end

---@return nil
local function retryRequests()
    if not isClient() then return end
    local now = getTimestampMs()
    if now < nextRequest then return end
    nextRequest = now + 5000
    for playerNum in pairs(awaiting) do
        requestState(playerNum, getSpecificPlayer(playerNum))
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
Events.OnCreatePlayer.Add(requestState)
Events.OnGameStart.Add(onGameStart)
Events.OnServerCommand.Add(onServerCommand)
Events.OnTick.Add(retryRequests)
