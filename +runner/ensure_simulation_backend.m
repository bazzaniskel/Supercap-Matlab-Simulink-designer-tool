function caseConfig = ensure_simulation_backend(caseConfig)
%ENSURE_SIMULATION_BACKEND Guarantee the case specifies a simulation backend.
%
%   Older saved configurations might not contain the `simulation.backend`
%   field. This helper adds it (prompting the user when possible) so that
%   downstream flows can decide between Simulink and the simplified ODE
%   model.

    if nargin < 1 || isempty(caseConfig)
        return;
    end

    if ~isfield(caseConfig, 'simulation') || ~isstruct(caseConfig.simulation)
        caseConfig.simulation = struct();
    end

    needsPrompt = true;
    if isfield(caseConfig.simulation, 'backend') && ~isempty(caseConfig.simulation.backend)
        backend = lower(string(caseConfig.simulation.backend));
        if any(backend == ["simulink", "ode"])
            caseConfig.simulation.backend = char(backend);
            needsPrompt = false;
        end
    end

    if needsPrompt
        if ~isfield(caseConfig, 'profile') || isempty(caseConfig.profile)
            profileStub = struct('switchCurrentOrPower', -1);
        else
            profileStub = caseConfig.profile;
        end
        caseConfig.simulation = runner.select_simulation_backend(profileStub);
    end
end
