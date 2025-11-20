function cellConfig = select_cell()
%SELECT_CELL Let the user choose the cell definition and return metadata.

    fprintf('\n===============================================================\n');
    fprintf('                        CELL SELECTION                        \n');
    fprintf('===============================================================\n');

    available_cells = runner.get_available_cells();
    cell_names = available_cells.metadata.cell_names;
    num_cells = available_cells.metadata.total_cells;

    fprintf('\nAvailable cell types:\n');
    for i = 1:num_cells
        cell_name = cell_names{i};
        cell_spec = available_cells.(cell_name);
        fprintf('%d. %s (%.0fF, %.2fmΩ ESR, %s)\n', ...
            i, cell_name, cell_spec.Cell_CapRated_F, ...
            cell_spec.Cell_ResESR10ms_Ohm * 1000, cell_spec.Module_Name);
    end

    prompt = sprintf('Select cell type (1-%d): ', num_cells);
    selection = runner.get_valid_input(prompt, @(x) x >= 1 && x <= num_cells);

    selected_cell_name = cell_names{selection};
    selected_cell_spec = available_cells.(selected_cell_name);

    cellConfig = struct();
    cellConfig.name = selected_cell_name;
    cellConfig.specs = build_cell_specs_struct(selected_cell_spec);
    cellConfig.moduleNumCellSeries = selected_cell_spec.Module_NumCellSeries;
    cellConfig.moduleRatedVoltage = selected_cell_spec.Module_RatedVoltage_V;
    cellConfig.voltRated = selected_cell_spec.Cell_VoltRated_V;
    cellConfig.numCellSeries = selected_cell_spec.Module_NumCellSeries;
    fprintf('Selected: %s\n', selected_cell_name);
end

function Cell_specs = build_cell_specs_struct(selected_cell_spec)
    Cell_specs = struct();
    fields = fieldnames(selected_cell_spec);
    for idx = 1:numel(fields)
        Cell_specs.(fields{idx}) = selected_cell_spec.(fields{idx});
    end
    % Preserve compatibility with existing scripts
    Cell_specs.Celll_Type = selected_cell_spec.Cell_Type;
end
