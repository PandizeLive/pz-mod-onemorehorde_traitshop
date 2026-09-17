local Progression = {}

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
