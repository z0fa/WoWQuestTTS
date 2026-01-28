local __namespace, __module = ...

local module = {} --- @class Array

--- comment
--- @param newValue? table | number
--- @return Array
function module.new(newValue)
  local toRet = setmetatable(
    {}, {
      __index = function(_, key)
        if key == "__isArray" then
          return true
        else
          return module[key]
        end
      end,
      __newindex = function(_, key, value)

      end,
    }
  )

  if type(newValue) == "table" then
    for k, v in pairs(newValue) do
      toRet:push(v)
    end
  elseif type(newValue) == "number" then
    for i = 1, newValue do
      toRet:push(nil)
    end
  end

  return toRet
end

--- comment
--- @param ... any
--- @return Array
function module.of(...)
  local toRet = module.new()

  for i, v in ipairs({ ... }) do
    toRet:push(v)
  end

  return toRet
end

--- comment
--- @param value any
--- @return boolean
function module.isArray(value)
  return (value or {}).__isArray == true
end

--- comment
--- @param value Array | string | table
--- @param mapFn? fun(element: unknown, index: integer, array: Array)
--- @return Array
function module:from(value, mapFn)
  local toRet = module.new()

  if module.isArray(value) then
    for i, v in ipairs(self) do
      toRet:push(v)
    end
  elseif type(value) == "string" then
    for i = 1, #value do
      toRet:push(value:sub(i, i))
    end
  elseif type(value) == "table" then
    for k, v in pairs(value) do
      toRet:push(v)
    end
  end

  if type(mapFn) == "function" then
    toRet = toRet:map(mapFn)
  end

  return toRet
end

--- comment
--- @return integer
function module:length()
  return #self
end

--- comment
--- @param index integer
--- @return unknown
function module:at(index)
  return self[index]
end

--- comment
--- @param ... any
--- @return Array
function module:concat(...)
  local toRet = module.new()

  for i = 1, #self do
    toRet:push(self[i])
  end

  for _, arg in ipairs({ ... }) do
    if module.isArray(arg) then
      for i = 1, #arg do
        toRet:push(arg[i])
      end
    else
      toRet:push(arg)
    end
  end

  return toRet
end

function module:copyWithin()
end

function module:entries()
end

--- comment
--- @param callbackFn fun(element: unknown, index: integer, array: Array): boolean
--- @return boolean
function module:every(callbackFn)
  for i, v in ipairs(self) do
    if not callbackFn(v, i, self) then
      return false
    end
  end

  return true
end

function module:fill()
end

--- comment
--- @param callbackFn fun(element: unknown, index: integer, array: Array): boolean
--- @return Array
function module:filter(callbackFn)
  local toRet = module.new()

  for i, v in ipairs(self) do
    if callbackFn(v, i, self) then
      toRet:push(v)
    end
  end

  return toRet
end

--- comment
--- @param callbackFn fun(element: unknown, index: integer, array: Array): boolean
--- @return unknown | nil
function module:find(callbackFn)
  for i, v in ipairs(self) do
    if callbackFn(v, i, self) then
      return v
    end
  end

  return nil
end

--- comment
--- @param callbackFn fun(element: unknown, index: integer, array: Array): boolean
--- @return integer
function module:findIndex(callbackFn)
  for i, v in ipairs(self) do
    if callbackFn(v, i, self) then
      return i
    end
  end

  return -1
end

function module:flat()
end

function module:flapMap()
end

--- comment
--- @param callbackFn fun(element: unknown, index: integer, array: Array)
function module:forEach(callbackFn)
  for i, v in ipairs(self) do
    callbackFn(v, i, self)
  end
end

function module:groupBy()
end

function module:groupByToMap()
end

function module:includes()
end

function module:indexOf()
end

--- comment
--- @param sep? string
--- @return string
function module:join(sep)
  sep = sep or ","

  local toRet = ""

  for i = 1, #self do
    local v = self[i] or ""
    toRet = toRet .. tostring(v)

    if i < #self then
      toRet = toRet .. sep
    end
  end

  return toRet
end

--- comment
--- @return Array
function module:keys()
  local toRet = module.new()

  for i = 1, #self do
    toRet:push(i)
  end

  return toRet
end

--- comment
--- @param callbackFn fun(element: unknown, index: integer, array: Array): unknown
--- @return Array
function module:map(callbackFn)
  local toRet = module.new()

  for i, v in ipairs(self) do
    toRet:push(callbackFn(v, i, self))
  end

  return toRet
end

function module:pop()
  return table.remove(self)
end

--- comment
--- @param ... any
function module:push(...)
  for i, v in ipairs({ ... }) do
    table.insert(self, v)
  end

  return #self
end

--- comment
--- @param callbackFn fun(accumulator: unknown, element: unknown, index: integer, array: Array): unknown
--- @param initialVal unknown
--- @return Array
function module:reduce(callbackFn, initialVal)
  local toRet = initialVal or nil

  for i, v in ipairs(self) do
    if toRet ~= nil then
      toRet = callbackFn(toRet, v, i, self)
    else
      toRet = v
    end
  end

  return toRet
end

function module:reduceRight()
end

function module:reverse()
  local len = #self
  for i = 1, math.floor(len / 2) do
    self[i], self[len - i + 1] = self[len - i + 1], self[i]
  end
end

function module:shift()
  return table.remove(self, 1)
end

---comment
---@param from? number
---@param to? number
---@return Array
function module:slice(from, to)
  local len = #self

  from = math.max(1, from or 1)
  to = math.min(len, to or len)

  local toRet = module.new()
  for i = from, to do
    toRet:push(self[i])
  end
  return toRet
end

--- comment
--- @param callbackFn fun(element: unknown, index: integer, array: Array): boolean
--- @return boolean
function module:some(callbackFn)
  for i, v in ipairs(self) do
    if callbackFn(v, i, self) then
      return true
    end
  end

  return false
end

function module:sort()
end

function module:splice()
end

function module:toLocaleString()
end

function module:toString()
end

--- comment
--- @param ... any
function module:unshift(...)
  for i, v in ipairs({ ... }) do
    table.insert(self, 1, v)
  end

  return #self
end

function module:values()
end

__module.Array = module
