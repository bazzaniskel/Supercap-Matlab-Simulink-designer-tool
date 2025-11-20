function simConfig = select_simulation_backend(profile)
%SELECT_SIMULATION_BACKEND Ask the user which electrical solver to use.
%
%   The ODE backend implements the simplified RC + CPL model directly in
%   MATLAB, while the Simulink backend runs the detailed Simscape model.

    fprintf('\nSimulation backend options:\n');
    fprintf('  1) Simulink (full thermo-electrical model)\n');
    fprintf('  2) ODE (fast RC + constant load model)\n');

    choice = runner.get_valid_input('Select backend (1 or 2): ', @(x) any(x == [1, 2]));
    if choice == 1
        backend = 'simulink';
    else
        if ~isfield(profile, 'switchCurrentOrPower') || ...
                ~ismember(profile.switchCurrentOrPower, [-1, 1])
            warning(['ODE backend expects a power (-1) or current (1) profile. ', ...
                'Profile metadata missing, defaulting to Simulink.']);
            backend = 'simulink';
        else
            backend = 'ode';
        end
    end

    simConfig = struct('backend', backend);
end
