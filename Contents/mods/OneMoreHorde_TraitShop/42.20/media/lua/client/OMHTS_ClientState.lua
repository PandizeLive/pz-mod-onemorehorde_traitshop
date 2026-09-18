if isServer() then return end

local TraitShop = require("OMHTS_Bootstrap")
local Catalog = require("OMHTS_Catalog")
local Effects = require("OMHTS_Effects")
local RewardsConfig = require("OMHTS_RewardsConfig")
local states = {}
local awaiting = {}
local purchases = {}
local actors = {}
local nonces = {}
local effectLives = {}
local nextNonce = 0
local nextRequest = 0
local counters = { "lifeId", "revision", "tokens", "level", "retainedPrestige", "earnedPrestige", "pendingPrestige", "startingTokens" }
local statuses = { available = true, owned = true, conflict = true, dead = true, loading = true,
    funds = true, unsupported = true, settings = true, limit = true, absent = true, body = true, multiplayer = true, grants = true, granted = true, excluded = true, removal_disabled = true }
local results = { purchased = true, busy = true, invalid = true, dead = true, stale = true, price_changed = true,
    owned = true, conflict = true, funds = true, unsupported = true, settings = true, loading = true, limit = true, absent = true, body = true, multiplayer = true, grants = true, granted = true, excluded = true, removal_disabled = true }

---@param playerNum number
---@param player IsoPlayer
---@return nil
local function trackActor(playerNum, player)
    if actors[playerNum] == player then return end
    actors[playerNum] = player
    nextNonce = nextNonce + 1
    nonces[playerNum] = nextNonce
    effectLives[playerNum] = nil
    states[playerNum] = nil
    purchases[playerNum] = nil
end

---@param snapshot any
---@return nil
function TraitShop.acceptState(snapshot)
    if type(snapshot) ~= "table" or snapshot.schema ~= 3
        or type(snapshot.playerNum) ~= "number" or snapshot.playerNum < 0
        or snapshot.playerNum > 3 or snapshot.playerNum ~= math.floor(snapshot.playerNum)
        or (snapshot.status ~= "alive" and snapshot.status ~= "dead")
        or type(snapshot.unofficial) ~= "boolean" or type(snapshot.offers) ~= "table"
        or #snapshot.offers > Catalog.MAX_PURCHASE_TRAITS then return end
    local player = getSpecificPlayer(snapshot.playerNum)
    if player then
        trackActor(snapshot.playerNum, player)
    end
    if snapshot.nonce ~= nil and snapshot.nonce ~= nonces[snapshot.playerNum] then return end
    if snapshot.creationStatus ~= "pending" and snapshot.creationStatus ~= "granted"
        and snapshot.creationStatus ~= "legacy" and snapshot.creationStatus ~= "invalid" then return end
    local copy = {}
    if type(snapshot.rewardSources) ~= "table" or #snapshot.rewardSources > 6
        or (snapshot.hordeRewards ~= "none" and snapshot.hordeRewards ~= "missing"
            and snapshot.hordeRewards ~= "upcoming") then return end
    copy.rewardSources = {}
    local seenSources = {}
    for index = 1, #snapshot.rewardSources do
        local source = snapshot.rewardSources[index]
        if type(source) ~= "string" or RewardsConfig.defaults[source] == nil
            or source == "PlayerKillCooldownDays" or seenSources[source] then return end
        copy.rewardSources[index] = source
        seenSources[source] = true
    end
    copy.hordeRewards = snapshot.hordeRewards
    for index = 1, #counters do
        local key = counters[index]
        local value = snapshot[key]
        if type(value) ~= "number" or value < 0 or value > 1000000000
            or value ~= math.floor(value) then return end
        copy[key] = value
    end
    if type(snapshot.xp) ~= "number" or not (snapshot.xp >= 0 and snapshot.xp <= 1000000000) then return end
    if type(snapshot.spentTokens) ~= "number" or snapshot.spentTokens < 0
        or snapshot.spentTokens > 100000000000 or snapshot.spentTokens ~= math.floor(snapshot.spentTokens) then return end
    if not Effects.valid(snapshot.effects) then return end
    copy.effects = Effects.copy(snapshot.effects)
    copy.spentTokens = snapshot.spentTokens
    copy.offers = {}
    local seen = {}
    for index = 1, #snapshot.offers do
        local offer = snapshot.offers[index]
        if type(offer) ~= "table" or not Catalog.validId(offer.id) or seen[offer.id]
            or not statuses[offer.status] or type(offer.price) ~= "number"
            or offer.price < 0 or offer.price > 1000000000 or offer.price ~= math.floor(offer.price) then return end
        copy.offers[index] = { id = offer.id, status = offer.status, price = offer.price }
        seen[offer.id] = true
    end
    local previous = states[snapshot.playerNum]
    if previous and (snapshot.lifeId < previous.lifeId
        or (snapshot.lifeId == previous.lifeId and snapshot.revision < previous.revision)) then return end
    copy.schema = 3
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
    local feedbackReady = not isClient() or effectLives[snapshot.playerNum] == copy.lifeId
    if snapshot.nonce ~= nil and snapshot.nonce == nonces[snapshot.playerNum] then
        effectLives[snapshot.playerNum] = copy.lifeId
    end
    if isClient() and player and not player:isDead() and copy.status == "alive"
        and effectLives[snapshot.playerNum] == copy.lifeId then
        Effects.apply(player, copy.effects)
    end
    if not isClient() or effectLives[snapshot.playerNum] == copy.lifeId then
        awaiting[snapshot.playerNum] = nil
    end
    if feedbackReady and player and not player:isDead() and copy.status == "alive"
        and previous and previous.status == "alive" and previous.lifeId == copy.lifeId
        and copy.revision > previous.revision and copy.level > previous.level then
        local sound = "OMHTS_LevelUp"
        if copy.earnedPrestige > previous.earnedPrestige then
            sound = "OMHTS_PrestigeLevelUp"
        end
        getSoundManager():playUISound(sound)
        HaloTextHelper.addText(player, getText("UI_OMHTS_LevelUp"), "[br/]", 231, 180, 40)
    end
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
        if key ~= "offers" and key ~= "effects" and key ~= "rewardSources" then
            copy[key] = value
        end
    end
    copy.effects = Effects.copy(state.effects)
    copy.rewardSources = {}
    for index = 1, #state.rewardSources do
        copy.rewardSources[index] = state.rewardSources[index]
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
    trackActor(playerNum, player)
    if isClient() then
        awaiting[playerNum] = true
        sendClientCommand(player, "OMHTraitShop", "requestState", { nonce = nonces[playerNum] })
    elseif TraitShop.Authority then
        local snapshot = TraitShop.Authority.getState(player)
        if snapshot then
            TraitShop.acceptState(snapshot)
        end
    end
end

---@param player IsoPlayer
---@param selection table|string
---@return boolean
function TraitShop.purchase(player, selection)
    if not player or player:isDead() then return false end
    local slot = player:getPlayerNum()
    local state = states[slot]
    if not state or purchases[slot] then return false end
    if type(selection) == "string" then
        selection = { [selection] = true }
    end
    if type(selection) ~= "table" then return false end
    local items = {}
    for index = 1, #state.offers do
        local offer = state.offers[index]
        if selection[offer.id] then
            if offer.status ~= "available" and offer.status ~= "conflict" and offer.status ~= "funds" then return false end
            local definition = Catalog.definition(offer.id)
            if not definition then return false end
            items[#items + 1] = { id = offer.id, price = offer.price, remove = definition:getCost() < 0 }
        end
    end
    local selectedCount = 0
    for _ in pairs(selection) do
        selectedCount = selectedCount + 1
    end
    if selectedCount ~= #items then return false end
    if #items == 0 or #items > Catalog.MAX_CART then return false end
    local args = { lifeId = state.lifeId, revision = state.revision, items = items }
    state.result = nil
    purchases[slot] = { lifeId = state.lifeId, revision = state.revision, sent = getTimestampMs() }
    if isClient() then
        sendClientCommand(player, "OMHTraitShop", "purchase", args)
    elseif TraitShop.Authority then
        TraitShop.Authority.purchase(player, args)
    end
    return true
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
    actors = {}
    nonces = {}
    effectLives = {}
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
