if isClient() then return end

local TraitShop = require("OMHTS_Bootstrap")
local State = require("OMHTS_State")
local Creation = require("OMHTS_Creation")
local Shop = require("OMHTS_Shop")
local Authority = {}
TraitShop.Authority = Authority
local store
local bindings = {}
local rejected = {}
local nextScan = 0
local STORE_KEY = "OMHTraitShop_State_v1"

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
---@return nil
local function sendSnapshot(player, binding)
    local snapshot = Shop.snapshot(player, binding.record)
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
    local record, result = State.attach(store, key, descriptor:getID(), player:getHoursSurvived())
    if not record then
        rejected[key] = true
        print("[OMH Trait Shop] state unavailable: " .. result .. "; saved data preserved")
        return nil
    end
    Creation.settle(player, record)
    Shop.reconcile(player, record, true)
    current = { record = record, lifeId = record.life.id, lastRequest = -10000,
        lastPurchase = -10000, lastBusy = -10000 }
    bindings[player] = current
    print("[OMH Trait Shop] state " .. result .. "; slot=" .. player:getPlayerNum()
        .. "; life=" .. record.life.id .. "; revision=" .. record.revision)
    sendSnapshot(player, current)
    return current
end

---@return nil
local function initialize()
    bindings = {}
    rejected = {}
    nextScan = 0
    store = ModData.getOrCreate(STORE_KEY)
    if not State.initialize(store) then
        store = nil
        print("[OMH Trait Shop] unsupported or invalid state schema; saved data preserved")
        return
    end
    print("[OMH Trait Shop] authority ready; schema=" .. State.SCHEMA)
end

---@param player IsoPlayer
---@return nil
local function observeDeath(player)
    if not player or not instanceof(player, "IsoPlayer") then return end
    local binding = bindings[player]
    if not binding or binding.record.life.id ~= binding.lifeId then return end
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
                    Shop.reconcile(player, binding.record, false)
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
    for _ in pairs(args) do
        return
    end
    local binding = bind(player)
    if not binding then return end
    local now = getTimestampMs()
    if now - binding.lastRequest < 1000 then return end
    binding.lastRequest = now
    Shop.reconcile(player, binding.record, true)
    sendSnapshot(player, binding)
end

---@param player IsoPlayer
---@return table|nil
function Authority.getState(player)
    local binding = bind(player)
    if not binding then return nil end
    return Shop.snapshot(player, binding.record)
end

---@param player IsoPlayer
---@param args table
---@return string
function Authority.purchase(player, args)
    local binding = bind(player)
    if not binding then return "unavailable" end
    local now = getTimestampMs()
    local result
    if now - binding.lastPurchase < 500 then
        if now - binding.lastBusy < 500 then return "busy" end
        binding.lastBusy = now
        result = "busy"
    else
        binding.lastPurchase = now
        result = Shop.purchase(player, binding.record, args)
    end
    local snapshot = Shop.snapshot(player, binding.record)
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
    if not binding or not State.update(binding.record, lifeId, revision, changes) then return false end
    sendSnapshot(player, binding)
    return true
end

Events.OnInitGlobalModData.Add(initialize)
Events.OnCreatePlayer.Add(onCreatePlayer)
Events.OnCharacterDeath.Add(observeDeath)
Events.OnTick.Add(onTick)
Events.OnSave.Add(scanPlayers)
Events.OnClientCommand.Add(onClientCommand)

return Authority
