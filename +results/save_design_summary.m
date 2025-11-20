function save_design_summary(results_folder, caseConfig, metrics)
%SAVE_DESIGN_SUMMARY Write text summary for design optimization runs.

    design_file = fullfile(results_folder, 'design_optimization_summary.txt');
    fid = fopen(design_file, 'w');
    if fid == -1
        fprintf('Warning: Could not create design optimization summary file\n');
        return;
    end

    fprintf(fid, 'DESIGN OPTIMIZATION SUMMARY\n');
    fprintf(fid, '===========================\n\n');
    fprintf(fid, 'TIMESTAMP: %s\n\n', datestr(now));
    fprintf(fid, 'OPTIMIZATION PARAMETERS:\n');
    fprintf(fid, '  Cell Type: %s\n', caseConfig.cell.name);
    fprintf(fid, '  Series Modules (Fixed): %d\n', caseConfig.system.seriesModules);
    fprintf(fid, '  Maximum Parallel Modules Searched: %d\n', caseConfig.constraints.maxParallelModules);
    fprintf(fid, '  Voltage Window: %.1f - %.1f V\n', caseConfig.operating.systemVoltage.min, caseConfig.operating.systemVoltage.max);

    if caseConfig.constraints.currentLimit.enabled
        fprintf(fid, '  Current Limit Enabled: Yes\n');
        fprintf(fid, '  Maximum System Current: %.1f A\n', caseConfig.constraints.currentLimit.maxSystemCurrent);
    else
        fprintf(fid, '  Current Limit Enabled: No\n');
    end

    fprintf(fid, '\n');
    fprintf(fid, 'DESIGN RESULT:\n');
    fprintf(fid, '  Minimum Parallel Modules: %d\n', caseConfig.system.parallelModules);
    fprintf(fid, '  Total Modules: %d\n', caseConfig.system.parallelModules * caseConfig.system.seriesModules);
    fprintf(fid, '  Starting Voltage: %.1f V\n', caseConfig.operating.startVoltage);
    fprintf(fid, '\n');
    fprintf(fid, 'PERFORMANCE SUMMARY:\n');
    fprintf(fid, '  System Max Current: %.1f A\n', metrics.system_max_current);
    fprintf(fid, '  System Max Voltage: %.1f V\n', metrics.system_max_voltage);
    fprintf(fid, '  System Min Voltage: %.1f V\n', metrics.system_min_voltage);
    fprintf(fid, '  System Max Power: %.2f MW\n', metrics.system_max_power/1e6);
    fprintf(fid, '  Lifetime: %.1f years\n', metrics.lifetime_years);
    fclose(fid);
end
