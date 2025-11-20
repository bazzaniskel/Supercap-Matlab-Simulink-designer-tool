function cellDir = get_cell_directory()
%GET_CELL_DIRECTORY Return the absolute path to the cells folder.
%   Ensures the folder exists so JSON cell definitions can be stored.

    runner_root = fileparts(fileparts(mfilename('fullpath')));
    cellDir = fullfile(runner_root, 'cells');

    if ~exist(cellDir, 'dir')
        mkdir(cellDir);
    end
end
