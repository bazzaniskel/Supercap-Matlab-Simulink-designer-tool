function [scaled_values, unit_label] = scale_power_for_plot(power_W)
%SCALE_POWER_FOR_PLOT Normalize power data for plotting purposes.

    abs_max = max(abs(power_W));
    if abs_max >= 1e6
        scaled_values = power_W / 1e6;
        unit_label = 'MW';
    elseif abs_max >= 1e3
        scaled_values = power_W / 1e3;
        unit_label = 'kW';
    else
        scaled_values = power_W;
        unit_label = 'W';
    end
end
