local __namespace, __module = ...
local module = {} --- @class ArrayFactory

--- comment
--- @param newValue? table | number
--- @return Array
function module.new(newValue)
  local newArray = {} --- @class Array

  --- comment
  --- @param value Array | string | table
  --- @param mapFn fun(element: unknown, index: integer, array: Array)
  --- @return Array
  function newArray.from(value, mapFn)
    local toRet = module.new()

    if module.isArray(value) then
      for i, v in ipairs(newArray) do
        toRet.push(v)
      end
    elseif type(value) == "string" then
      for i = 1, #value do
        toRet.push(value:sub(i, i))
      end
    elseif type(value) == "table" then
      for k, v in pairs(value) do
        toRet.push(v)
      end
    end

    if type(mapFn) == "function" then
      toRet = toRet.map(mapFn)
    end

    return toRet
  end

  --- comment
  --- @return integer
  function newArray.length()
    return #newArray
  end

  --- comment
  --- @param index integer
  --- @return unknown
  function newArray.at(index)
    return newArray[index]
  end

  function newArray.concat()
  end

  function newArray.copyWithin()
  end

  function newArray.entries()
  end

  function newArray.every()
  end

  function newArray.fill()
  end

  --- comment
  --- @param callbackFn fun(element: unknown, index: integer, array: Array)
  --- @return Array
  function newArray.filter(callbackFn)
    local toRet = module.new()

    for i, v in ipairs(newArray) do
      if callbackFn(v, i, newArray) then
        toRet.push(v)
      end
    end

    return toRet
  end

  --- comment
  --- @param callbackFn fun(element: unknown, index: integer, array: Array)
  --- @return unknown | nil
  function newArray.find(callbackFn)
    for i, v in ipairs(newArray) do
      if callbackFn(v, i, newArray) then
        return v
      end
    end

    return nil
  end

  --- comment
  --- @param callbackFn fun(element: unknown, index: integer, array: Array)
  --- @return integer
  function newArray.findIndex(callbackFn)
    for i, v in ipairs(newArray) do
      if callbackFn(v, i, newArray) then
        return i
      end
    end

    return -1
  end

  function newArray.flat()
  end

  function newArray.flapMap()
  end

  --- comment
  --- @param callbackFn fun(element: unknown, index: integer, array: Array)
  function newArray.forEach(callbackFn)
    for i, v in ipairs(newArray) do
      callbackFn(v, i, newArray)
    end
  end

  function newArray.groupBy()
  end

  function newArray.groupByToMap()
  end

  function newArray.includes()
  end

  function newArray.indexOf()
  end

  function newArray.join()
  end

  function newArray.keys()
  end

  --- comment
  --- @param callbackFn fun(element: unknown, index: integer, array: Array)
  --- @return Array
  function newArray.map(callbackFn)
    local toRet = module.new()

    for i, v in ipairs(newArray) do
      toRet.push(callbackFn(v, i, newArray))
    end

    return toRet
  end

  function newArray.pop()
  end

  --- comment
  --- @param ... any
  function newArray.push(...)
    for i, v in ipairs({ ... }) do
      table.insert(newArray, v)
    end
  end

  function newArray.reduce()
  end

  function newArray.reduceRight()
  end

  function newArray.reverse()
  end

  function newArray.shift()
  end

  function newArray.slice()
  end

  function newArray.some()
  end

  function newArray.sort()
  end

  function newArray.splice()
  end

  function newArray.toLocaleString()
  end

  function newArray.toString()
  end

  function newArray.unshift()
  end

  function newArray.values()
  end

  newArray.__isArray = true

  if type(newValue) == "table" then
    for k, v in pairs(newValue) do
      newArray.push(v)
    end
  elseif type(newValue) == "number" then
    for i = 1, newValue do
      newArray.push(nil)
    end
  end

  return newArray
end

--- comment
--- @param ... any
--- @return Array
function module.of(...)
  local toRet = module.new()

  for i, v in ipairs({ ... }) do
    toRet.push(v)
  end

  return toRet
end

--- comment
--- @param value any
--- @return boolean
function module.isArray(value)
  return (value or {}).__isArray == true
end

__module.Array = module
