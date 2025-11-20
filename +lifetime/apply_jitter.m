function profile = apply_jitter(baseProfile, jitter)
%APPLY_JITTER Wrapper around lifetime_perturb_profile for MC trials.

    profile = simulation.lifetime_perturb_profile(baseProfile, jitter);
end
