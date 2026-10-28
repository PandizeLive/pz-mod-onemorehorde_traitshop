local Progression = {}

---@nodiscard
---@return number|nil tokensPerLevel
---@return number|nil prestigeInterval
function Progression.rewards()
    local options = SandboxVars.OMHTraitShop
    if type(options) ~= "table" then return nil, nil end
    local tokens = options.TokensPerLevel
    local interval = options.PrestigeLevelInterval
    -- Older saved sandbox tables predate these options.
    if tokens == nil then
        tokens = 1
    end
    if interval == nil then
        interval = 5
    end
    if type(tokens) ~= "number" or tokens < 0 or tokens > 1000 or tokens ~= math.floor(tokens)
        or type(interval) ~= "number" or interval < 1 or interval > 1000
        or interval ~= math.floor(interval) then return nil, nil end
    return tokens, interval
end

---@nodiscard
---@param level number
---@return number
function Progression.requiredXP(level)
    return math.floor((100 + 35 * level + (65 / 19) * level * level) / 50 + 0.5) * 50
end

---@nodiscard
---@param level number
---@param xp number
---@param amount number
---@return number
---@return number
function Progression.advance(level, xp, amount)
    local remaining = xp + amount
    local required = Progression.requiredXP(level)
    while remaining >= required do
        remaining = remaining - required
        level = level + 1
        required = Progression.requiredXP(level)
    end
    return level, remaining
end

return Progression
