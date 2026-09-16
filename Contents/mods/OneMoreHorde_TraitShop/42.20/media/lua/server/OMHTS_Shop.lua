if isClient() then return end

local State = require("OMHTS_State")
local Catalog = require("OMHTS_Catalog")
local Effects = require("OMHTS_Effects")
local Shop = {}

---@param player IsoPlayer
---@param record table
---@param forceSync boolean
---@return boolean
function Shop.reconcile(player, record, forceSync)
    if record.life.status ~= "alive" or player:isDead() then return false end
    local changed = Effects.apply(player, record.life.effects)
    if isServer() and (changed or forceSync) then
        sendSyncPlayerFields(player, 3)
    end
    return changed
end

---@nodiscard
---@param player IsoPlayer
---@param id string
---@return boolean
local function isGranted(player, id)
    local profession = CharacterProfessionDefinition.getCharacterProfessionDefinition(player:getDescriptor():getCharacterProfession())
    if profession then
        local granted = profession:getGrantedTraits()
        for index = 0, granted:size() - 1 do
            if tostring(granted:get(index)) == id then return true end
        end
    end
    local known = player:getCharacterTraits():getKnownTraits()
    for index = 0, known:size() - 1 do
        local definition = Catalog.definition(tostring(known:get(index)))
        if definition then
            local granted = definition:getGrantedTraits()
            for child = 0, granted:size() - 1 do
                if tostring(granted:get(child)) == id then return true end
            end
        end
    end
    return false
end

---@nodiscard
---@param player IsoPlayer
---@param record table
---@param id string
---@return string
---@return number
function Shop.offer(player, record, id)
    local definition = Catalog.definition(id)
    if not definition or definition:isFree() or definition:getCost() == 0 then return "unsupported", 0 end
    local price = Catalog.price(definition)
    if not price then return "settings", 0 end
    local removing = definition:getCost() < 0
    local owned = player:hasTrait(definition:getType())
    if not removing and (owned or record.life.purchases[id] or record.life.effects.traits[id] == true) then
        return "owned", price
    end
    if removing and (not owned or record.life.removals[id]) then return "absent", price end
    local reason = Catalog.exclusion(definition)
    if reason then return reason, price end
    if removing then
        if not Catalog.removalEnabled() then return "removal_disabled", price end
        if not definition:getGrantedTraits():isEmpty() then return "grants", price end
        if isGranted(player, id) then return "granted", price end
    end
    if record.life.status ~= "alive" or player:isDead() then return "dead", price end
    if record.life.creation.status == "pending" then return "loading", price end
    if not removing and Catalog.conflicts(player, definition) then return "conflict", price end
    if record.life.tokens < price then return "funds", price end
    return "available", price
end

---@param player IsoPlayer
---@param record table
---@return table
function Shop.snapshot(player, record)
    local snapshot = State.snapshot(record, player:getPlayerNum())
    snapshot.spentTokens = 0
    for _, price in pairs(record.life.purchases) do
        snapshot.spentTokens = snapshot.spentTokens + price
    end
    for _, price in pairs(record.life.removals) do
        snapshot.spentTokens = snapshot.spentTokens + price
    end
    snapshot.effects = { traits = {}, recipes = {}, perks = Effects.copy(record.life.effects).perks }
    if record.life.effects.traits["base:smoker"] == false then
        snapshot.effects.traits["base:smoker"] = false
    end
    snapshot.offers = {}
    Catalog.definition("")
    for index = 1, #Catalog.entries do
        local id = Catalog.entries[index].id
        local status, price = Shop.offer(player, record, id)
        snapshot.offers[index] = { id = id, status = status, price = price }
    end
    return snapshot
end

---@param player IsoPlayer
---@param record table
---@param args table
---@return string
function Shop.purchase(player, record, args)
    if type(args) ~= "table" then return "invalid" end
    local legacy = args.items == nil
    for key in pairs(args) do
        if key ~= "lifeId" and key ~= "revision" and key ~= "items"
            and not (legacy and (key == "traitId" or key == "price")) then return "invalid" end
    end
    if not State.isCounter(args.lifeId) or not State.isCounter(args.revision) then return "invalid" end
    if record.life.status ~= "alive" or player:isDead() then return "dead" end
    if args.lifeId ~= record.life.id or args.revision ~= record.revision then return "stale" end
    local items = args.items
    if legacy then
        items = { { id = args.traitId, price = args.price, remove = false } }
    end
    if type(items) ~= "table" or #items == 0 or #items > Catalog.MAX_CART then return "invalid" end
    local count = 0
    for key in pairs(items) do
        if not State.isCounter(key) or key < 1 or key > #items then return "invalid" end
        count = count + 1
    end
    if count ~= #items then return "invalid" end
    local changes = {}
    local total = 0
    local receiptCount = 0
    for _ in pairs(record.life.purchases) do
        receiptCount = receiptCount + 1
    end
    for _ in pairs(record.life.removals) do
        receiptCount = receiptCount + 1
    end
    for index = 1, #items do
        local item = items[index]
        if type(item) ~= "table" then return "invalid" end
        for key in pairs(item) do
            if key ~= "id" and key ~= "price" and key ~= "remove" then return "invalid" end
        end
        if type(item.id) ~= "string" or #item.id > 128 or not State.isCounter(item.price)
            or type(item.remove) ~= "boolean" or changes[item.id] ~= nil then return "invalid" end
        local definition = Catalog.definition(item.id)
        if not definition then return "unsupported" end
        if item.remove ~= (definition:getCost() < 0) then return "invalid" end
        local status, price = Shop.offer(player, record, item.id)
        if status ~= "available" and status ~= "conflict" and status ~= "funds" then return status end
        if price ~= item.price then return "price_changed" end
        total = total + price
        changes[item.id] = item.remove
        receiptCount = receiptCount + 1
    end
    if receiptCount > Catalog.MAX_PURCHASE_TRAITS then return "limit" end
    if total > record.life.tokens then return "funds" end
    if record.revision >= State.LIMIT then return "invalid" end
    Shop.reconcile(player, record, false)
    local effects, reason = Effects.plan(player, record.life.effects, changes)
    if not effects then return reason end
    record.life.tokens = record.life.tokens - total
    record.life.effects = effects
    for index = 1, #items do
        local item = items[index]
        if item.remove then
            record.life.removals[item.id] = item.price
        else
            record.life.purchases[item.id] = item.price
        end
    end
    record.revision = record.revision + 1
    Shop.reconcile(player, record, true)
    return "purchased"
end

return Shop
