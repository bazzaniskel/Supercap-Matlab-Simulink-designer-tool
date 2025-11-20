function T_out = solve_cabinet_temperature(hours, T_air, solar_flux, heatCapacity, convection)
%SOLVE_CABINET_TEMPERATURE Solve cabinet temperature for piecewise segments.

    if numel(hours) < 2
        hours = [0 24];
        T_air = [T_air(1) T_air(1)];
    end

    if numel(T_air) == 1
        T_air = repmat(T_air, 1, numel(hours));
    elseif numel(hours) ~= numel(T_air)
        base = linspace(0,1,numel(T_air));
        target = linspace(0,1,numel(hours));
        T_air = interp1(base, T_air, target, 'linear', 'extrap');
    end
    if numel(solar_flux) ~= numel(hours)-1
        if numel(solar_flux) < 1
            solar_flux = zeros(1, numel(hours)-1);
        elseif numel(solar_flux) == 1
            solar_flux = repmat(solar_flux, 1, numel(hours)-1);
        else
            base = linspace(0,1,numel(solar_flux));
            target = linspace(0,1,numel(hours)-1);
            solar_flux = interp1(base, solar_flux, target, 'linear', 'extrap');
        end
    end

    R = 1 / max(convection, eps);
    tau = heatCapacity * R;

    T = T_air(1);
    T_out = zeros(size(T_air));
    T_out(1) = T;

    for idx = 1:numel(hours)-1
        dt = (hours(idx+1) - hours(idx)) * 3600;
        Tamb = T_air(idx);
        Q = solar_flux(idx);
        T_inf = Tamb + Q * R;
        T = T_inf + (T - T_inf) * exp(-dt / tau);
        T_out(idx+1) = T;
    end
end
