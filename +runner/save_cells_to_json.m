function save_cells_to_json(cells, cellDir)
%SAVE_CELLS_TO_JSON Persist a struct of cells to individual JSON files.

    if nargin < 2 || isempty(cellDir)
        cellDir = runner.get_cell_directory();
    end

    if ~exist(cellDir, 'dir')
        mkdir(cellDir);
    end

    cell_names = fieldnames(cells);
    for idx = 1:numel(cell_names)
        name = cell_names{idx};
        spec = cells.(name);
        if ~isstruct(spec)
            continue;
        end
        file_name = sprintf('%s.json', name);
        file_path = fullfile(cellDir, file_name);
        if exist(file_path, 'file')
            % Do not overwrite user-provided files.
            continue;
        end
        try
            jsonStr = jsonencode(spec, 'PrettyPrint', true);
        catch
            jsonStr = jsonencode(spec);
        end
        fid = fopen(file_path, 'w');
        if fid == -1
            fprintf('⚠  Could not open %s for writing\n', file_path);
            continue;
        end
        fprintf(fid, '%s\n', jsonStr);
        fclose(fid);
        fprintf('✓ Seeded cell definition %s -> %s\n', name, file_path);
    end
end
