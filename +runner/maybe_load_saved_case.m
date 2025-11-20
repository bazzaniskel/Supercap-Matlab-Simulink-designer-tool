function caseConfig = maybe_load_saved_case()
%MAYBE_LOAD_SAVED_CASE Offer the user a chance to load a saved configuration.

    caseConfig = [];
    configDir = runner.get_config_directory();
    configs = runner.list_saved_configs(configDir);

    if isempty(configs)
        fprintf('\nNo saved configurations found in %s.\n', configDir);
        return;
    end

    fprintf('\nSaved configurations available in %s:\n', configDir);
    for idx = 1:numel(configs)
        fprintf('  %d. %s [%s]\n', idx, configs(idx).displayName, configs(idx).typeLabel);
    end

    if ~runner.get_yes_no_input('Load one of these configurations? (y/n): ')
        fprintf('Proceeding with interactive configuration...\n');
        return;
    end

    selection = runner.get_valid_input(sprintf('Select configuration (1-%d): ', numel(configs)), ...
        @(x) isnumeric(x) && x >= 1 && x <= numel(configs));

    try
        caseConfig = runner.load_case_from_file(configs(selection));
        caseConfig = runner.ensure_simulation_backend(caseConfig);
        if ~isfield(caseConfig, 'analysis') || isempty(caseConfig.analysis)
            caseConfig.analysis = config.default_analysis();
        else
            caseConfig.analysis = config.merge_structs(config.default_analysis(), caseConfig.analysis);
        end
        fprintf('Configuration loaded successfully from %s\n', configs(selection).path);
    catch ME
        fprintf('⚠  Failed to load configuration: %s\n', ME.message);
        caseConfig = [];
    end
end
