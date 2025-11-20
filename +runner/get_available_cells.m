function available_cells = get_available_cells()
%GET_AVAILABLE_CELLS Load supported cell specifications from JSON files.
%   Cell definitions live in the /cells folder as <cellname>.json. If none
%   exist, the built-in set is seeded to JSON for convenience.

    cellDir = runner.get_cell_directory();
    cells = runner.load_cells_from_json(cellDir);

    if isempty(fieldnames(cells))
        builtin_cells = runner.builtin_cell_definitions();
        runner.save_cells_to_json(builtin_cells, cellDir);
        cells = builtin_cells;
    end

    available_cells = cells;
    meta_names = fieldnames(cells);
    available_cells.metadata = struct();
    available_cells.metadata.total_cells = numel(meta_names);
    available_cells.metadata.cell_names = meta_names;
    available_cells.metadata.created_date = datestr(now);
    available_cells.metadata.description = 'Available supercapacitor cell specifications loaded from JSON';
end
