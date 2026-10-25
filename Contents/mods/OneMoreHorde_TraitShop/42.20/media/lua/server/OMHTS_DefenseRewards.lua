if isClient() then return end

local State = require("OMHTS_State")
local Rewards = require("OMHTS_Rewards")
local D = {}

---@param store table Authoritative Trait Shop store
---@return boolean valid
function D.initialize(store)
    if store.defense == nil then
        store.defense = {schema = 1, members = {}, pending = {}, encounters = {}}
    end
    local data = store.defense
    if type(data) ~= "table" or data.schema ~= 1 or type(data.members) ~= "table"
        or type(data.pending) ~= "table" or type(data.encounters) ~= "table" then return false end
    for key, member in pairs(data.members) do
        if type(key) ~= "string" or type(member) ~= "table" or type(member.username) ~= "string"
            or type(member.identity) ~= "string" or not State.isCounter(member.life) then return false end
    end
    for key, pending in pairs(data.pending) do
        if type(key) ~= "string" or type(pending) ~= "table" or not State.isCounter(pending.life)
            or not State.isXP(pending.amount) or type(pending.unofficial) ~= "boolean" then return false end
    end
    for key, encounter in pairs(data.encounters) do
        if type(key) ~= "string" or type(encounter) ~= "table" or not State.isCounter(encounter.life)
            or type(encounter.assists) ~= "table" then return false end
        for contributor, life in pairs(encounter.assists) do
            if type(contributor) ~= "string" or not State.isCounter(life) then return false end
        end
    end
    for key, record in pairs(store.accounts) do
        if not data.members[key] and State.isRecord(record) and record.life.status == "alive" then
            local length, username = string.match(key, "^user:(%d+):(.*):[0-3]$")
            if username and #username == tonumber(length) then
                data.members[key] = {username = username, identity = username, life = record.life.id}
            end
        end
    end
    return true
end

---@param store table Server store
---@param key string Account key
---@param record table Attached current character
---@param username string Native username
---@param identity string Horde identity
---@return boolean delivered
function D.attach(store, key, record, username, identity)
    local data = store.defense
    data.members[key] = {username = username, identity = identity, life = record.life.id}
    local encounter = data.encounters[key]
    if encounter and encounter.life ~= record.life.id then
        data.encounters[key] = nil
    end
    local pending = data.pending[key]
    if not pending then return false end
    if pending.life ~= record.life.id or record.life.status ~= "alive" then
        data.pending[key] = nil
        return false
    end
    if not State.awardXP(record, record.life.id, record.revision, pending.amount) then return false end
    data.pending[key] = nil
    Rewards.audit("defense-delivered", {recipient = username, life = pending.life, amount = pending.amount})
    if pending.unofficial then
        record.life.prestigeUnofficial = true
        if record.prestige.earned > 0 then
            record.prestige.unofficial = true
        end
    end
    return true
end

---@param store table Server store
---@param key string Victim account
---@param life number Victim life
---@return table encounter
function D.encounter(store, key, life)
    local data = store.defense
    local value = data.encounters[key]
    if not value or value.life ~= life then
        value = {life = life, assists = {}}
        data.encounters[key] = value
    end
    return value
end

---@param store table Server store
---@param key string Victim account
---@return nil
function D.clear(store, key)
    store.defense.encounters[key] = nil
end

---@param store table Server store
---@param key string Dead account
---@return nil
function D.death(store, key)
    D.clear(store, key)
    store.defense.pending[key] = nil
end

---@param members table Eligible life snapshots
---@param amount number One total pool
---@param result table Combined account payouts
---@return nil
local function split(members, amount, result)
    local count = #members
    if count == 0 or amount <= 0 then return end
    local share = amount / count
    for i = 1, count do
        local member = members[i]
        local entry = result[member.key]
        if not entry then
            entry = {member = member, amount = 0}
            result[member.key] = entry
        end
        entry.amount = entry.amount + share
    end
end

---@param reward number Normal configured reward
---@param rate number Defense pool fraction
---@param faction table Eligible faction members, unique accounts
---@param assists table Eligible personal assistants, unique accounts
---@param pvp boolean Only PvP has an assist remainder
---@return table payouts Combined once per beneficiary
function D.plan(reward, rate, faction, assists, pvp)
    local result = {}
    split(faction, reward * rate, result)
    if pvp then
        split(assists, reward * (1 - rate), result)
    end
    for key, entry in pairs(result) do
        entry.beforeMinimum = entry.amount
        if entry.amount > 0 and entry.amount < 1 then
            entry.amount = 1
        end
    end
    return result
end

---@param store table Server store
---@param payouts table Frozen amounts and life snapshots
---@param victim string|nil PvP victim account identity
---@param now number World age hours
---@param cooldownHours number Native configured account cooldown
---@return table changed Online account keys awarded
function D.settle(store, payouts, victim, now, cooldownHours)
    local changed = {}
    for key, entry in pairs(payouts) do
        local member = entry.member
        local record = store.accounts[key]
        local cooldowns = store.rewards.cooldowns[member.username]
        local expiry = cooldowns and victim and cooldowns[victim]
        if State.isRecord(record) and record.life.id == member.life and record.life.status == "alive"
            and State.isXP(entry.amount) and entry.amount > 0 and (not expiry or now >= expiry) then
            local awarded = false
            if member.online then
                awarded = State.awardXP(record, member.life, record.revision, entry.amount)
                if awarded then
                    changed[key] = true
                    if member.unofficial then
                        record.life.prestigeUnofficial = true
                        if record.prestige.earned > 0 then
                            record.prestige.unofficial = true
                        end
                    end
                end
            else
                local pending = store.defense.pending[key]
                if not pending or pending.life ~= member.life then
                    pending = {life = member.life, amount = 0, unofficial = false}
                    store.defense.pending[key] = pending
                end
                local total = pending.amount + entry.amount
                if State.isXP(total) then
                    pending.amount = total
                    pending.unofficial = pending.unofficial or member.unofficial
                    awarded = true
                end
            end
            if awarded and victim then
                if not cooldowns then
                    cooldowns = {}
                    store.rewards.cooldowns[member.username] = cooldowns
                end
                cooldowns[victim] = now + cooldownHours
            end
            local outcome = "defense-rejected"
            if awarded and member.online then
                outcome = "defense-paid"
            elseif awarded then
                outcome = "defense-banked"
            end
            Rewards.audit(outcome, {recipient = member.username, life = member.life,
                amount = entry.amount, beforeMinimum = entry.beforeMinimum, device = entry.device})
        else
            Rewards.audit("defense-stale-or-cooldown", {recipient = member.username, life = member.life})
        end
    end
    return changed
end

return D
