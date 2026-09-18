if isClient() then return end

local Effects = require("OMHTS_Effects")
local Progression = require("OMHTS_Progression")
local State = {}
State.SCHEMA = 3
State.LIMIT = 1000000000

---@param value any
---@return boolean
function State.isCounter(value)
    return type(value) == "number" and value >= 0 and value <= State.LIMIT
        and value == math.floor(value)
end

---@param value any
---@return boolean
function State.isXP(value)
    return type(value) == "number" and value >= 0 and value <= State.LIMIT
end

---@param store table
---@return boolean
function State.initialize(store)
    if store.schema == nil then
        for _ in pairs(store) do
            return false
        end
        store.schema = State.SCHEMA
        store.nextLife = 0
        store.accounts = {}
    end
    if store.schema == 1 and State.isCounter(store.nextLife) and type(store.accounts) == "table" then
        for _, record in pairs(store.accounts) do
            if not State.isLegacyRecord(record) or record.life.creation ~= nil
                or record.life.purchases ~= nil or record.life.effects ~= nil
                or record.life.removals ~= nil then return false end
        end
        for _, record in pairs(store.accounts) do
            record.life.creation = { status = "legacy", tokens = 0 }
            record.life.purchases = {}
        end
        store.schema = 2
    end
    if store.schema == 2 and State.isCounter(store.nextLife) and type(store.accounts) == "table" then
        for _, record in pairs(store.accounts) do
            if not State.isLegacyRecord(record) or type(record.life.creation) ~= "table"
                or type(record.life.purchases) ~= "table" or record.life.removals ~= nil
                or record.life.effects ~= nil then return false end
            local candidate = { revision = record.revision, prestige = record.prestige,
                unofficial = record.unofficial, life = {} }
            for key, value in pairs(record.life) do
                candidate.life[key] = value
            end
            candidate.life.removals = {}
            candidate.life.effects = { traits = {}, recipes = {}, perks = {} }
            if not State.isRecord(candidate) then return false end
        end
        for _, record in pairs(store.accounts) do
            record.life.removals = {}
            record.life.effects = { traits = {}, recipes = {}, perks = {} }
            for id in pairs(record.life.purchases) do
                record.life.effects.traits[id] = true
            end
        end
        store.schema = State.SCHEMA
    end
    if store.schema ~= State.SCHEMA or not State.isCounter(store.nextLife)
        or type(store.accounts) ~= "table" then return false end
    if store.creations == nil then
        store.creations = {}
    end
    if type(store.creations) ~= "table" then return false end
    for key, points in pairs(store.creations) do
        if type(key) ~= "string" or #key > 160
            or (points ~= -1 and not State.isCounter(points)) then return false end
    end
    return true
end

---@param record any
---@return boolean
function State.isLegacyRecord(record)
    if type(record) ~= "table" or not State.isCounter(record.revision)
        or type(record.prestige) ~= "table" or type(record.life) ~= "table" then return false end
    local prestige = record.prestige
    local life = record.life
    return State.isCounter(prestige.retained) and State.isCounter(prestige.earned)
        and State.isCounter(prestige.pending) and State.isCounter(prestige.settledLife)
        and State.isCounter(life.id) and State.isCounter(life.characterId)
        and State.isCounter(life.tokens) and State.isCounter(life.level)
        and State.isXP(life.xp) and State.isXP(life.hours)
        and (life.status == "alive" or life.status == "dead")
        and type(record.unofficial) == "boolean"
end

---@nodiscard
---@param record any
---@return boolean
function State.isRecord(record)
    if not State.isLegacyRecord(record) then return false end
    if record.life.prestigeRule ~= nil and record.life.prestigeRule ~= 2 then return false end
    local creation = record.life.creation
    if type(creation) ~= "table" or not State.isCounter(creation.tokens)
        or type(record.life.purchases) ~= "table" or type(record.life.removals) ~= "table"
        or not Effects.valid(record.life.effects) then return false end
    if creation.status ~= "pending" and creation.status ~= "granted"
        and creation.status ~= "legacy" and creation.status ~= "invalid" then return false end
    local count = 0
    for id, price in pairs(record.life.purchases) do
        if type(id) ~= "string" or #id > 128 or not State.isCounter(price) or price < 1 then return false end
        count = count + 1
        if count > 256 then return false end
    end
    for id, price in pairs(record.life.removals) do
        if type(id) ~= "string" or #id > 128 or not State.isCounter(price) or price < 1 then return false end
        count = count + 1
        if count > 256 then return false end
    end
    return true
end

---@param record table
---@param lifeId number
---@return boolean
function State.settleDeath(record, lifeId)
    if record.life.id ~= lifeId or record.life.status == "dead" then return false end
    local prestige = record.prestige
    local pending = prestige.pending + prestige.retained + prestige.earned
    if not State.isCounter(pending) or record.revision >= State.LIMIT then return false end
    prestige.pending = pending
    prestige.retained = 0
    prestige.earned = 0
    prestige.settledLife = lifeId
    record.life.tokens = 0
    record.life.xp = 0
    record.life.level = 0
    record.life.purchases = {}
    record.life.removals = {}
    record.life.effects = { traits = {}, recipes = {}, perks = {} }
    record.life.status = "dead"
    record.revision = record.revision + 1
    return true
end

---@param store table
---@param account string
---@param characterId number
---@param hours number
---@param fresh boolean|nil
---@return table|nil
---@return string
function State.attach(store, account, characterId, hours, fresh)
    if not State.isCounter(characterId) or not State.isXP(hours) then return nil, "invalid_character" end
    local record = store.accounts[account]
    if record and not State.isRecord(record) then return nil, "invalid_record" end
    if record and record.revision >= State.LIMIT - 1 then return nil, "revision_limit" end
    if record and record.life.status == "alive" then
        if record.life.characterId == characterId and (hours > 0 or record.life.hours == 0) then
            if record.life.prestigeRule == nil then
                local earned = math.max(record.prestige.earned, math.floor((record.life.level + 1) / 5))
                if not State.isCounter(earned + record.prestige.retained + record.prestige.pending) then
                    return nil, "prestige_limit"
                end
                record.prestige.earned = earned
                record.life.prestigeRule = 2
                record.revision = record.revision + 1
            end
            if hours > record.life.hours then
                record.life.hours = hours
            end
            return record, "resumed"
        end
        if not State.settleDeath(record, record.life.id) then return nil, "settlement_failed" end
    end
    if store.nextLife >= State.LIMIT then return nil, "life_limit" end
    store.nextLife = store.nextLife + 1
    if not record then
        record = {
            revision = 0,
            prestige = { retained = 0, earned = 0, pending = 0, settledLife = 0 },
            unofficial = true,
        }
        store.accounts[account] = record
    end
    record.life = {
        id = store.nextLife,
        characterId = characterId,
        hours = hours,
        status = "alive",
        tokens = 0,
        xp = 0,
        level = 0,
        prestigeRule = 2,
        creation = { status = "legacy", tokens = 0 },
        purchases = {},
        removals = {},
        effects = { traits = {}, recipes = {}, perks = {} },
    }
    if hours == 0 or fresh == true then
        record.life.creation.status = "pending"
    end
    record.revision = record.revision + 1
    return record, "created"
end

---@param record table
---@param lifeId number
---@param revision number
---@param amount number
---@return boolean
function State.awardXP(record, lifeId, revision, amount)
    if not State.isRecord(record) or record.life.status ~= "alive"
        or record.life.id ~= lifeId or record.revision ~= revision
        or revision >= State.LIMIT or not State.isXP(amount) or amount <= 0
        or record.life.xp >= Progression.requiredXP(record.life.level) then return false end
    local life = record.life
    local level, xp = Progression.advance(life.level, life.xp, amount)
    local tokens = life.tokens + level - life.level
    local prestige = record.prestige.earned + math.floor((level + 1) / 5) - math.floor((life.level + 1) / 5)
    if not State.isCounter(level) or not State.isXP(xp) or not State.isCounter(tokens)
        or not State.isCounter(prestige + record.prestige.retained + record.prestige.pending) then return false end
    life.tokens = tokens
    life.level = level
    life.xp = xp
    record.prestige.earned = prestige
    record.revision = revision + 1
    return true
end

---@param record table
---@param lifeId number
---@param revision number
---@param changes table
---@return boolean
function State.update(record, lifeId, revision, changes)
    if not State.isRecord(record) or record.life.status ~= "alive"
        or record.life.id ~= lifeId or record.revision ~= revision
        or revision >= State.LIMIT or type(changes) ~= "table" then return false end
    local changed = false
    for key, value in pairs(changes) do
        if key == "xp" then
            if not State.isXP(value) then return false end
        elseif key == "tokens" or key == "level" then
            if not State.isCounter(value) then return false end
        else
            return false
        end
        if record.life[key] ~= value then
            changed = true
        end
    end
    if not changed then return false end
    for key, value in pairs(changes) do
        record.life[key] = value
    end
    record.revision = record.revision + 1
    return true
end

---@param record table
---@param playerNum number
---@return table
function State.snapshot(record, playerNum)
    return {
        schema = State.SCHEMA,
        playerNum = playerNum,
        lifeId = record.life.id,
        revision = record.revision,
        status = record.life.status,
        tokens = record.life.tokens,
        xp = record.life.xp,
        level = record.life.level,
        retainedPrestige = record.prestige.retained,
        earnedPrestige = record.prestige.earned,
        pendingPrestige = record.prestige.pending,
        unofficial = record.unofficial,
        creationStatus = record.life.creation.status,
        startingTokens = record.life.creation.tokens,
    }
end

return State
