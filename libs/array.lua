local __namespace, __module = ...

local module = {} --- @class Array

--- comment
--- @param newValue? table | number
--- @return Array
function module.new(newValue)
  local toRet = {}

  toRet.__isArray = true
  setmetatable(toRet, { __index = module })

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
--- @param mapFn fun(element: unknown, index: integer, array: Array)
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

function module:concat()
end

function module:copyWithin()
end

function module:entries()
end

function module:every()
end

function module:fill()
end

--- comment
--- @param callbackFn fun(element: unknown, index: integer, array: Array)
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
--- @param callbackFn fun(element: unknown, index: integer, array: Array)
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
--- @param callbackFn fun(element: unknown, index: integer, array: Array)
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

function module:join()
end

function module:keys()
end

--- comment
--- @param callbackFn fun(element: unknown, index: integer, array: Array)
--- @return Array
function module:map(callbackFn)
  local toRet = module.new()

  for i, v in ipairs(self) do
    toRet:push(callbackFn(v, i, self))
  end

  return toRet
end

function module:pop()
end

--- comment
--- @param ... any
function module:push(...)
  for i, v in ipairs({ ... }) do
    table.insert(self, v)
  end
end

--- comment
--- @param callbackFn fun(accumulator: unknown, element: unknown, index: integer, array: Array)
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
end

function module:shift()
end

function module:slice()
end

function module:some()
end

function module:sort()
end

function module:splice()
end

function module:toLocaleString()
end

function module:toString()
end

function module:unshift()
end

function module:values()
end

__module.Array = module
