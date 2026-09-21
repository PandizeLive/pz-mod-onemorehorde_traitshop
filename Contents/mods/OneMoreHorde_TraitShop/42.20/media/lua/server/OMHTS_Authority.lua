if isClient() then return end

local TraitShop = require("OMHTS_Bootstrap")
local State = require("OMHTS_State")
local Creation = require("OMHTS_Creation")
local Shop = require("OMHTS_Shop")
local Rewards = require("OMHTS_Rewards")
local RewardsConfig = require("OMHTS_RewardsConfig")
local Prestige = require("OMHTS_Prestige")
local Authority = {}
TraitShop.Authority = Authority
local store
local rewardsReady = false
local bindings = {}
local rejected = {}
local nextScan = 0
local STORE_KEY = "OMHTraitShop_State_v1"

---@nodiscard
---@param player IsoPlayer
---@return boolean
local function enabled(player)
    if not RewardsConfig.hasHordeNight() then return true end
    local runtime = rawget(_G, "OneMoreHordeDifficultyRuntime")
    return runtime ~= nil and runtime.isTraitShopEnabled ~= nil and runtime.isTraitShopEnabled(player)
end

---@param player IsoPlayer
---@param record table
---@return nil
local function auditEarnings(player, record)
    if not RewardsConfig.hasHordeNight() then
        record.life.prestigeUnofficial = true
    else
        local runtime = rawget(_G, "OneMoreHordeDifficultyRuntime")
        if not runtime or not runtime.isTraitShopEarningOfficial
            or not runtime.isTraitShopEarningOfficial(player) then
            record.life.prestigeUnofficial = true
        end
    end
    if record.life.prestigeUnofficial and record.prestige.earned > 0 then
        record.prestige.unofficial = true
    end
end

---@param player IsoPlayer
---@param record table
---@return table
local function snapshotFor(player, record)
    local snapshot = Shop.snapshot(player, record)
    snapshot.enabled = enabled(player)
    return snapshot
end

---@nodiscard
---@param player IsoPlayer
---@return string|nil
local function creationKey(player)
    local descriptor = player:getDescriptor()
    if not descriptor or not State.isCounter(descriptor:getID()) then return nil end
    if isServer() then
        local username = player:getUsername()
        if type(username) ~= "string" or #username == 0 or #username > 128 then return nil end
        return "user:" .. #username .. ":" .. username .. ":" .. descriptor:getID()
    end
    return "local:" .. player:getPlayerNum() .. ":" .. descriptor:getID()
end

---@param player IsoPlayer
---@return string|nil
local function accountKey(player)
    local slot = player:getPlayerNum()
    if not State.isCounter(slot) or slot > 3 then return nil end
    if isServer() then
        local username = player:getUsername()
        if type(username) ~= "string" or #username == 0 or #username > 128 then return nil end
        return "user:" .. #username .. ":" .. username .. ":" .. slot
    end
    return "local:" .. slot
end

---@param player IsoPlayer
---@param binding table
---@param nonce number|nil
---@return nil
local function sendSnapshot(player, binding, nonce)
    Prestige.publish(accountKey(player), binding.record)
    local snapshot = snapshotFor(player, binding.record)
    snapshot.nonce = nonce
    if isServer() then
        sendServerCommand(player, "OMHTraitShop", "state", snapshot)
    elseif TraitShop.acceptState then
        TraitShop.acceptState(snapshot)
    end
end

---@param player IsoPlayer
---@return table|nil
local function bind(player)
    if not store or not player or not instanceof(player, "IsoPlayer") or player:isDead() then return nil end
    local current = bindings[player]
    if current then
        if current.lifeId ~= current.record.life.id or current.record.life.status ~= "alive" then return nil end
        return current
    end
    local key = accountKey(player)
    local descriptor = player:getDescriptor()
    if not key or not descriptor or rejected[key] then return nil end
    local birthKey = creationKey(player)
    local capturedPoints
    if birthKey then
        capturedPoints = store.creations[birthKey]
    end
    local hours = player:getHoursSurvived()
    local record, result = State.attach(store, key, descriptor:getID(), hours, capturedPoints ~= nil)
    if not record then
        rejected[key] = true
        print("[OMH Trait Shop] state unavailable: " .. result .. "; saved data preserved")
        return nil
    end
    Creation.settle(player, record, capturedPoints)
    if birthKey then
        store.creations[birthKey] = nil
    end
    Shop.reconcile(player, record, true)
    current = { record = record, lifeId = record.life.id, lastRequest = -10000,
        lastPurchase = -10000, lastBusy = -10000 }
    current.survival = Rewards.session(getGameTime():getWorldAgeHours(), getGameTime():getTimeOfDay(), RewardsConfig.read())
    bindings[player] = current
    current.access = enabled(player)
    print("[OMH Trait Shop] state " .. result .. "; slot=" .. player:getPlayerNum()
        .. "; life=" .. record.life.id .. "; revision=" .. record.revision
        .. "; hours=" .. tostring(hours) .. "; creation=" .. record.life.creation.status
        .. "; startingTokens=" .. record.life.creation.tokens)
    sendSnapshot(player, current)
    return current
end

---@param player IsoPlayer
---@param square IsoGridSquare|nil
---@return nil
local function onNewGame(player, square)
    if not store or not player or not instanceof(player, "IsoPlayer") or player:isDead() then return end
    local key = creationKey(player)
    if not key or store.creations[key] ~= nil then return end
    local account = accountKey(player)
    local record = store.accounts[account]
    if record and not State.isRecord(record) then return end
    if record and record.life.status == "alive"
        and record.life.characterId == player:getDescriptor():getID()
        and record.life.creation.status ~= "legacy" then return end
    local bonus = 0
    if record then
        bonus = record.prestige.pending + record.prestige.retained + record.prestige.earned
    end
    local points = Creation.remainingPoints(player, bonus)
    if points == nil then
        points = -1
    end
    store.creations[key] = points
    print("[OMH Trait Shop] creation captured; character=" .. player:getDescriptor():getID()
        .. "; points=" .. points)
end

---@return nil
local function initialize()
    bindings = {}
    rejected = {}
    nextScan = 0
    store = ModData.getOrCreate(STORE_KEY)
    rewardsReady = false
    if not State.initialize(store) then
        store = nil
        print("[OMH Trait Shop] unsupported or invalid state schema; saved data preserved")
        return
    end
    rewardsReady = Rewards.initialize(store)
    if not rewardsReady then
        print("[OMH Trait Shop] invalid reward state; rewards disabled; saved data preserved")
    end
    for account, record in pairs(store.accounts) do
        if State.isRecord(record) then
            Prestige.publish(account, record)
        end
    end
    print("[OMH Trait Shop] authority ready; schema=" .. State.SCHEMA)
end

---@param killer IsoGameCharacter|nil
---@return table|nil
local function rewardBinding(killer)
    if not killer or not instanceof(killer, "IsoPlayer") or killer:isDead() then return nil end
    if isServer() and not getOnlinePlayers():contains(killer) then return nil end
    if not isServer() and getSpecificPlayer(killer:getPlayerNum()) ~= killer then return nil end
    if not enabled(killer) then return nil end
    return bind(killer)
end

---@param participantId string
---@return IsoPlayer|nil
---@nodiscard
local function hordePlayer(participantId)
    local players
    local count = getNumActivePlayers()
    if isServer() then
        players = getOnlinePlayers()
        count = players:size()
    end
    for index = 0, count - 1 do
        local player
        if isServer() then
            player = players:get(index)
        else
            player = getSpecificPlayer(index)
        end
        if player then
            local id = "singleplayer:" .. player:getPlayerNum()
            if isServer() then
                id = player:getUsername()
            end
            if id == participantId then return player end
        end
    end
    return nil
end

---@param facts table
---@return nil
function Authority.onHordeKill(facts)
    if not rewardsReady or not RewardsConfig.hasHordeRewards()
        or not Rewards.consumeHordeKill(store, facts) or facts.eligible ~= true then return end
    local player = hordePlayer(facts.participantId)
    local binding = rewardBinding(player)
    if binding and Rewards.horde(binding.record, "HordeZombieXP") then
        auditEarnings(player, binding.record)
        binding.rewardDirty = true
    end
end

---@param facts table
---@return nil
function Authority.onHordeFinished(facts)
    if not rewardsReady or not RewardsConfig.hasHordeRewards()
        or not Rewards.consumeHordeFinish(store, facts) or facts.outcome ~= "survived"
        or facts.completionReason == "manual-run-reset"
        or facts.completionReason == "faction-disbanded" then return end
    for participantId, recipient in pairs(facts.rewardParticipants) do
        local player = hordePlayer(participantId)
        if player and type(recipient) == "table"
            and player:getDescriptor():getID() == recipient.characterId then
            local binding = rewardBinding(player)
            if binding and Rewards.horde(binding.record, "HordeSurvivedXP") then
                auditEarnings(player, binding.record)
                binding.rewardDirty = true
            end
        end
    end
end

---@param zombie IsoZombie
---@return nil
local function onZombieDead(zombie)
    if not rewardsReady or not Rewards.consumeZombie(zombie) then return end
    local killer = zombie:getAttackedBy()
    local binding = rewardBinding(killer)
    if binding and Rewards.zombie(zombie, binding.record) then
        auditEarnings(killer, binding.record)
        binding.rewardDirty = true
    end
end

---@param player IsoPlayer
---@return nil
local function observeDeath(player)
    if not player or not instanceof(player, "IsoPlayer") then return end
    local binding = bindings[player]
    if not binding or binding.record.life.id ~= binding.lifeId then return end
    if rewardsReady and player:isDead() and Rewards.consumePlayer(store, player, binding.lifeId) then
        local killer = player:getAttackedBy()
        local killerBinding = rewardBinding(killer)
        if killerBinding and Rewards.player(store, killer, player, killerBinding.record) then
            auditEarnings(killer, killerBinding.record)
            killerBinding.rewardDirty = true
        end
    end
    if State.settleDeath(binding.record, binding.lifeId) then
        print("[OMH Trait Shop] death settled; life=" .. binding.lifeId .. "; wallet reset")
        sendSnapshot(player, binding)
    end
end

---@return nil
local function scanPlayers()
    if not store then return end
    local seen = {}
    local players
    local count = getNumActivePlayers()
    if isServer() then
        players = getOnlinePlayers()
        count = players:size()
    end
    for index = 0, count - 1 do
        local player
        if isServer() then
            player = players:get(index)
        else
            player = getSpecificPlayer(index)
        end
        if player then
            seen[player] = true
            if player:isDead() then
                observeDeath(player)
            else
                local binding = bind(player)
                if binding and binding.record.life.id == binding.lifeId then
                    local access = enabled(player)
                    if binding.access ~= access then
                        binding.access = access
                        binding.rewardDirty = true
                        binding.survival = Rewards.session(getGameTime():getWorldAgeHours(),
                            getGameTime():getTimeOfDay(), RewardsConfig.read())
                    end
                    if rewardsReady and access then
                        local changed
                        binding.survival, changed = Rewards.survival(binding.record, binding.survival,
                            getGameTime():getWorldAgeHours(), getGameTime():getTimeOfDay(), RewardsConfig.read())
                        if changed then
                            auditEarnings(player, binding.record)
                            binding.rewardDirty = true
                        end
                    end
                    Shop.reconcile(player, binding.record, false)
                    if binding.rewardDirty then
                        binding.rewardDirty = nil
                        sendSnapshot(player, binding)
                    end
                    local hours = player:getHoursSurvived()
                    if State.isXP(hours) and hours > binding.record.life.hours then
                        binding.record.life.hours = hours
                    end
                end
            end
        end
    end
    for player in pairs(bindings) do
        if not seen[player] then
            if player:isDead() then
                observeDeath(player)
            end
            bindings[player] = nil
        end
    end
end

---@return nil
local function onTick()
    local now = getTimestampMs()
    if now < nextScan then return end
    nextScan = now + 1000
    scanPlayers()
end

---@param playerNum number
---@param player IsoPlayer
---@return nil
local function onCreatePlayer(playerNum, player)
    if not isServer() then
        bind(player)
    end
end

---@param module string
---@param command string
---@param player IsoPlayer
---@param args table
---@return nil
local function onClientCommand(module, command, player, args)
    if module ~= "OMHTraitShop" or type(args) ~= "table" then return end
    if command == "purchase" then
        Authority.purchase(player, args)
        return
    end
    if command ~= "requestState" then return end
    for key in pairs(args) do
        if key ~= "nonce" then return end
    end
    if args.nonce ~= nil and not State.isCounter(args.nonce) then return end
    local binding = bind(player)
    if not binding then return end
    local now = getTimestampMs()
    if now - binding.lastRequest < 1000 then return end
    binding.lastRequest = now
    Shop.reconcile(player, binding.record, true)
    sendSnapshot(player, binding, args.nonce)
end

---@param player IsoPlayer
---@return table|nil
function Authority.getState(player)
    local binding = bind(player)
    if not binding then return nil end
    return snapshotFor(player, binding.record)
end

---@nodiscard
---@param player IsoPlayer
---@return boolean|nil
function Authority.hasUnofficialPrestige(player)
    local binding = bind(player)
    if not binding then return nil end
    local creation = binding.record.life.creation
    return creation.prestigeUnofficial == true or creation.status == "invalid"
end

---@nodiscard
---@param playerId string
---@return boolean|nil
function Authority.hasUnofficialPrestigeForIdentity(playerId)
    if not store or type(playerId) ~= "string" then return nil end
    for slot = 0, 3 do
        local account
        if isServer() then
            account = "user:" .. #playerId .. ":" .. playerId .. ":" .. slot
        elseif playerId == "singleplayer:" .. slot then
            account = "local:" .. slot
        end
        local record = store.accounts[account]
        if record then
            if not State.isRecord(record) then return nil end
            if record.life.status == "alive" and (record.life.creation.prestigeUnofficial == true
                or record.life.creation.status == "invalid") then return true end
        end
    end
    return false
end

---@param player IsoPlayer
---@param args table
---@return string
function Authority.purchase(player, args)
    local binding = bind(player)
    if not binding then return "unavailable" end
    local now = getTimestampMs()
    local result
    if not enabled(player) then
        result = "disabled"
    elseif now - binding.lastPurchase < 500 then
        if now - binding.lastBusy < 500 then return "busy" end
        binding.lastBusy = now
        result = "busy"
    else
        binding.lastPurchase = now
        result = Shop.purchase(player, binding.record, args)
        if result == "purchased" then
            auditEarnings(player, binding.record)
        end
    end
    local snapshot = snapshotFor(player, binding.record)
    snapshot.result = result
    if type(args) == "table" and State.isCounter(args.revision) then
        snapshot.requestRevision = args.revision
    end
    if isServer() then
        sendServerCommand(player, "OMHTraitShop", "state", snapshot)
    elseif TraitShop.acceptState then
        TraitShop.acceptState(snapshot)
    end
    return result
end

---@param player IsoPlayer
---@param lifeId number
---@param revision number
---@param changes table
---@return boolean
function Authority.updateState(player, lifeId, revision, changes)
    local binding = bind(player)
    if not binding or not enabled(player) or not State.update(binding.record, lifeId, revision, changes) then return false end
    sendSnapshot(player, binding)
    return true
end

---@param player IsoPlayer
---@param lifeId number
---@param revision number
---@param amount number
---@return boolean
function Authority.awardXP(player, lifeId, revision, amount)
    local binding = bind(player)
    if not binding or not enabled(player) then return false end
    auditEarnings(player, binding.record)
    if not State.awardXP(binding.record, lifeId, revision, amount) then return false end
    sendSnapshot(player, binding)
    return true
end

Events.OnInitGlobalModData.Add(initialize)
Events.OnNewGame.Add(onNewGame)
Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnCharacterDeath.Add(observeDeath)
Events.OnZombieDead.Add(onZombieDead)
Events.OnZombieCreate.Add(Rewards.created)
Events.OnTick.Add(onTick)
Events.OnSave.Add(scanPlayers)
Events.OnClientCommand.Add(onClientCommand)

return Authority
