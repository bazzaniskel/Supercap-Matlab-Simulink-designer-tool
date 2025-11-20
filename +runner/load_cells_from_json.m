function cells = load_cells_from_json(cellDir)
%LOAD_CELLS_FROM_JSON Read all JSON cell definitions from the cells folder.

    if nargin < 1 || isempty(cellDir)
        cellDir = runner.get_cell_directory();
    end

    cells = struct();
    files = dir(fullfile(cellDir, '*.json'));
    if isempty(files)
        return;
    end

    for idx = 1:numel(files)
        try
            raw = fileread(fullfile(files(idx).folder, files(idx).name));
            data = jsondecode(raw);
            [~, baseName] = fileparts(files(idx).name);

            cellName = derive_cell_name(data, baseName);
            cells.(cellName) = data;
        catch ME %#ok<NASGU>
            fprintf('⚠  Skipping invalid cell file %s\n', files(idx).name);
        end
    end
end

function name = derive_cell_name(data, fallback)
    if isstruct(data) && isfield(data, 'name') && ~isempty(data.name)
        name = char(data.name);
    else
        name = fallback;
    end
    name = strrep(name, ' ', '_');
    name = matlab.lang.makeValidName(name);
end
