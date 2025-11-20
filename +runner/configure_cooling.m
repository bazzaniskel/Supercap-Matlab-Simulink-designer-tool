function cooling = configure_cooling(cellSpecs, environmentTemp)
%CONFIGURE_COOLING Capture cooling system setup.

    fprintf('\n--- COOLING SYSTEM CONFIGURATION ---\n');

    fprintf('\nAvailable cooling methods:\n');
    fprintf('1. Natural convection (air cooling)\n');
    fprintf('2. Forced air cooling\n');
    fprintf('3. Liquid cooling\n');

    method_choice = runner.get_valid_input('Select cooling method (1-3): ', @(x) x >= 1 && x <= 3);
    cooling = struct();
    cooling.initialCellTemp = environmentTemp;
    cooling.switchCooling = 1;
    cooling.switchDerating = 0;

    switch method_choice
        case 1
            cooling.method = 'Natural convection';
            cooling.mediumTemp = environmentTemp;
            cooling.rthCooling = cellSpecs.Cell_RthToCooling_KpW_naturalCooling;
            cooling.rthEnvironment = cellSpecs.Cell_RthToEnvironment_KpW_naturalCooling;
            fprintf('Selected: Natural convection cooling\n');
        case 2
            cooling.method = 'Forced air';
            cooling.mediumTemp = environmentTemp;
            cooling.rthCooling = cellSpecs.Cell_RthToCooling_KpW_forcedAirCooling;
            cooling.rthEnvironment = cellSpecs.Cell_RthToEnvironment_KpW_forcedAirCooling;
            fprintf('Selected: Forced air cooling\n');
        case 3
            cooling.method = 'Liquid cooling';
            cooling.mediumTemp = runner.get_valid_input('Cooling liquid temperature [°C]: ', @(x) x >= -40 && x <= 85);
            cooling.rthCooling = cellSpecs.Cell_RthToCooling_KpW_liquidCooling;
            cooling.rthEnvironment = cellSpecs.Cell_RthToEnvironment_KpW_liquidCooling;
            fprintf('Selected: Liquid cooling at %.1f°C\n', cooling.mediumTemp);
    end
end
