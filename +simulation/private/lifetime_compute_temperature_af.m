function AF_T = lifetime_compute_temperature_af(t_vector, T_vector, mask, fallback_temp, f_t)
%LIFETIME_COMPUTE_TEMPERATURE_AF Average acceleration factor for a segment.

    if ~any(mask)
        AF_T = f_t(fallback_temp);
        return;
    end

    t_seg = t_vector(mask);
    T_seg = T_vector(mask);
    if numel(t_seg) < 2 || (t_seg(end) - t_seg(1)) <= 0
        AF_T = f_t(T_seg(end));
        return;
    end

    af_values = f_t(T_seg);
    avg_af = trapz(t_seg, af_values) / (t_seg(end) - t_seg(1));
    AF_T = max(avg_af, f_t(min(T_seg)));
end
