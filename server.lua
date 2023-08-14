local function assertion(v, bool)
    if bool then
        if type(v) == 'number' then
            if v > 0 then return true end
            return false
        end
        if v then return true end
        return false
    end

    if type(v) == 'number' then
        if v > 0 then return false end
        return true
    end

    if v then return false end
    return true
end

local function Migrate(migrations)
    assert(type(migrations) == 'table')
    
    for i = 1, #migrations do
        local migration = migrations[i]
        if not migration then break end

        if type(migration) == 'string' then
            MySQL.query.await(migration, {})
            goto continue
        end

        local shouldMigrate = true
        if migration.conditions and type(migration.conditions) == 'table' and #migration.conditions > 0 then
            for j = 1, #migration.conditions do
                local condition = migration.conditions[j]
                local q = condition
                local params = {}
                local a = false
                if type(condition) == 'table' then
                    q = condition.query
                    params = condition.params or {}
                    a = condition.assertion or false
                end
                local result = MySQL.scalar.await(q, params)
                if not assertion(result, condition.assertion) then
                    shouldMigrate = false
                    break
                end
            end
        end

        if not shouldMigrate then break end
        for j = 1, #migration.queries do
            local query = migration.queries[j]
            local q = query
            if type(q) ~= 'string' then
                q = query.query
            end
            local params = {}
            if type(query) == 'table' then
                params = query.params or {}
            end
            MySQL.query.await(q, params)
        end

        ::continue::
    end
end

exports('Migrate', Migrate)
