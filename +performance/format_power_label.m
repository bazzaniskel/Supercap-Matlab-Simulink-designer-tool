function label = format_power_label(power_W)
%FORMAT_POWER_LABEL Convert watts to compact string with SI units.

    abs_power = abs(power_W);
    if abs_power >= 1e6
        label = sprintf('%.2f MW', power_W/1e6);
    elseif abs_power >= 1e3
        label = sprintf('%.2f kW', power_W/1e3);
    else
        label = sprintf('%.0f W', power_W);
    end
end
