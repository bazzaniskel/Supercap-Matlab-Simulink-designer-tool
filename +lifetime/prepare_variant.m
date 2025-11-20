function variant = prepare_variant(baseCase, parallel_modules, start_voltage)
%PREPARE_VARIANT Create a case configuration for a specific module count and voltage.

    variant = baseCase;
    variant.system.parallelModules = parallel_modules;
    variant.operating.startVoltage = start_voltage;

    % Keep cooling references aligned with ambient adjustments per step.
    variant.cooling.initialCellTemp = variant.operating.environmentTemp;

    variant = config.finalize_case(variant);
end
