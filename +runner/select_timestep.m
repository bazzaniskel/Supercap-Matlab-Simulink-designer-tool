function timestep = select_timestep(profile)
%SELECT_TIMESTEP Suggest and capture timestep selection.

    fprintf('\n===============================================================\n');
    fprintf('                    TIMESTEP SELECTION                        \n');
    fprintf('===============================================================\n');

    default_timestep = min(profile.time(end)/100, 0.001);
    fprintf('\nDefault calculated timestep: %.6f s (%.3f ms)\n', default_timestep, default_timestep*1000);
    fprintf('Calculation: min(Cell_LoadInputTime_s(end)/100, 0.001) = min(%.3f/100, 0.001) = %.6f s\n', ...
        profile.time(end), default_timestep);

    fprintf('\nTimestep options:\n');
    fprintf('  1. Use default calculated timestep (%.6f s)\n', default_timestep);
    fprintf('  2. Use finer timestep (%.6f s)\n', default_timestep/10);
    fprintf('  3. Use coarser timestep (%.6f s)\n', default_timestep*10);
    fprintf('  4. Custom timestep\n');

    choice = runner.get_valid_input('Select timestep option (1-4): ', @(x) x >= 1 && x <= 4);
    switch choice
        case 1
            timestep.value = default_timestep;
            fprintf('Using default timestep: %.6f s\n', timestep.value);
        case 2
            timestep.value = default_timestep / 10;
            fprintf('Using finer timestep: %.6f s (%.3f ms)\n', timestep.value, timestep.value*1000);
        case 3
            timestep.value = default_timestep * 10;
            fprintf('Using coarser timestep: %.6f s (%.3f ms)\n', timestep.value, timestep.value*1000);
        case 4
            fprintf('\nCustom timestep selection:\n');
            fprintf('  Recommended range: %.6f s to %.6f s\n', default_timestep/100, default_timestep*100);
            fprintf('  Note: Very small timesteps increase simulation time\n');
            fprintf('  Note: Very large timesteps may reduce accuracy\n');
            custom_value = runner.get_valid_input('Enter custom timestep [s]: ', @(x) x > 0 && x <= profile.time(end));
            timestep.value = custom_value;
            fprintf('Using custom timestep: %.6f s (%.3f ms)\n', timestep.value, timestep.value*1000);
    end

    timestep.default = default_timestep;
    timestep.numPoints = round(profile.time(end)/timestep.value);
    fprintf('\nTIMESTEP CONFIRMATION:\n');
    fprintf('  Selected Timestep: %.6f s (%.3f ms)\n', timestep.value, timestep.value*1000);
    fprintf('  Simulation Duration: %.3f s\n', profile.time(end));
    fprintf('  Number of Time Points: ~%.0f\n', profile.time(end)/timestep.value);
end
