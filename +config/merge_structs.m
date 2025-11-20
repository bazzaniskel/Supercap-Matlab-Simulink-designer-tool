function result = merge_structs(baseStruct, overrides)
%MERGE_STRUCTS Shallow merge of structs (overrides dominate).

    result = baseStruct;
    if nargin < 2 || isempty(overrides)
        return;
    end

    fields = fieldnames(overrides);
    for idx = 1:numel(fields)
        key = fields{idx};
        value = overrides.(key);
        if isstruct(value) && isfield(baseStruct, key)
            result.(key) = config.merge_structs(baseStruct.(key), value);
        else
            result.(key) = value;
        end
    end
end
