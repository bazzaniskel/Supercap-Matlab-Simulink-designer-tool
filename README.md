# Supercap Simple Runner

Interactive MATLAB/Simulink tool to design, simulate, and time‑march lifetime for supercapacitor racks. Run `supercap_simple_runner.m` to step through every choice: pick cells, build the electrical stack, set temperatures and duty cycles, define the load profile, choose a solver, and optionally search the design space. Results (plots, tables, workspace) are written under `results/` for handover or replay.

## Quick start
1) Open MATLAB in the repo root.  
2) Ensure Simulink is available if you plan to use the full model (`CellModel/Supercap_Thermo_Electrical_Cell_Simulation_Model.slx`).  
3) Optional: run `create_cell_tool` if you need to add or tweak a cell definition before starting (writes JSON into `cells/`).  
4) Run `supercap_simple_runner`. The runner will try to load configs from `configs/` first; otherwise it will guide you interactively.  
5) Generated outputs land in `results/<timestamp>_...`.

## Repository map (runnable pieces)
- `supercap_simple_runner.m` – entrypoint orchestrating the whole flow.
- `+runner` – interactive prompts (cells, system sizing, temps, cooling, backends, saving/loading).
- `+profiles` – power/current profile creation and loading.
- `+config` – normalization of environments/analysis defaults and derived fields.
- `+design` – optimization routines (binary search for parallel count, voltage grid search).
- `+simulation` – Simulink and MATLAB ODE solvers plus metrics/lifetime maths.
- `+lifetime` – time‑marching lifetime search (monthly temps).
- `+results` – plots, summary tables, result directory builder.
- `+performance` – optional power/time-domain capability searches.
- `power_profiles/` – custom load profile scripts (created if absent).
- `temperature_profiles/` – ambient/irradiance profiles as `.m` functions.
- `cells/` – JSON cell definitions; seeded automatically from the built-in set on first run.
- `configs/` – saved case files; runner lists `.json`, `.mat`, `.m`.

## End‑to‑end runner flow (what each prompt does)
1) **Environment setup** – adds key folders (cell models, profiles, analysis) to the MATLAB path and loads `ESR.mat` if present.
2) **Load saved config** – lists files in `configs/` (JSON/MAT/function). If selected, the config is merged with defaults and the missing backend is prompted for.
3) **Operation mode**  
   - `Design optimization`: binary search for minimum parallel modules; optionally also searches starting voltage.  
   - `Simulation`: runs exactly the configuration you enter.  
   - `Lifetime`: marches month by month using ambient curves; can also optimize start voltage.
4) **Cell selection** – choose one of the predefined cells in `+runner/get_available_cells.m` (Skelgrid SKUs and single‑cell variants). Specs (capacitance, ESR, rated voltage, thermal params) are pushed into the workspace.
5) **System configuration & constraints**  
   - Always: number of series modules (module cell count comes from the selected cell).  
   - Design/Lifetime modes: max parallel modules to consider, optional system current limit, lifetime requirement (mandatory in lifetime mode), divisibility constraint for parallels, and (if enabled) a voltage search range + number of grid points.  
   - Simulation mode: fixed parallel module count only.
6) **Operating conditions**  
   - SOH [%]; scales capacitance/ESR with a health lookup.  
   - Ambient temperature profile (see “Temperature profile definition”).  
   - Optional solar exposure model that perturbs daily temps using presets or custom irradiance/area/absorptivity/thermal mass.  
   - Start voltage: entered manually unless voltage optimization is on (then the mean of the range is used as a placeholder until the search runs).  
   - Duty cycle [0–1] and operating hours/day.  
   - System voltage window (min/max).  
   - Ambient Monte Carlo (optional): number of trials, days/month to sample, 99th‑percentile temp jitter (converted to Gaussian sigma), smoothing hours, design‑time toggle, RNG seed; shown with min/mean/max previews.
7) **Power/current profile definition** (see details below).  
8) **Timestep** – default is `min(pulse_duration/100, 1 ms)`; you can pick finer/coarser or custom. Sets `Sim_TimeStep_s` and informs the ODE grid.  
9) **Cooling** – choose natural, forced air, or liquid. The runner pulls Rth values from the cell and captures coolant temperature and initial cell temp.  
10) **Thermal limit search** – optional: compute maximum duty cycle that still meets a lifetime target (needs a lifetime requirement to be set).  
11) **Performance/optimization add-ons** (optional):  
    - Max duration search (time domain): fixed requested power, find max duration over SOH sweep while enforcing both voltage and current limits.  
    - Max power search (power domain): fixed pulse duration, find max deliverable power at each SOH.  
    - Efficiency vs lifetime (SOH sweep): compute efficiency curve as SOH decays (proxy for lifetime progression).  
    - Max thermal load (duty-cycle solver): determine the highest duty cycle that still satisfies the lifetime target with current cooling.
12) **Simulation backend** – choose solver:  
    - **Simulink** (`simulation.backend = simulink`): runs `CellModel/Supercap_Thermo_Electrical_Cell_Simulation_Model.slx`, using base‑workspace variables prepared in `+simulation/assign_base_variables`. Uses the detailed thermo‑electrical Simscape model.  
    - **ODE** (`simulation.backend = ode`): fast MATLAB‑only solver (`+simulation/run_case_ode.m`) modeling two capacitive poles (main/fast), split ESR (10 ms vs 1 s), and a single thermal RC. Handles constant‑power loads via algebraic solve, enforces a minimum cell voltage, and steps temperature with conduction to ambient (`Rth`, `Cth`). Profiles are interpolated to the solver grid and scaled per cell; positive user values mean charging and are inverted to the load convention internally.
13) **Confirmation** – summary via `runner.print_configuration_summary`; you can abort before execution.
14) **Execution path**  
    - **Lifetime mode**: builds monthly periods from the ambient profile, then either (a) voltage grid search (`lifetime.voltage_search`) or (b) fixed‑voltage parallel search (`lifetime.parallel_search`). Tracks SOH decay, achieves/declares lifetime, plots start vs end waveforms, steady temperature, and optionally Monte Carlo percentiles.  
    - **Design/Simulation modes**: runs the chosen backend, computes metrics (`+simulation/compute_metrics`), optional thermal duty‑cycle search, and optional performance scans.

## Power/current profile logic
- Mode is chosen up front: *current* (`switchCurrentOrPower = 1, units = A`) or *power* (`switchCurrentOrPower = -1, units = W`).  
- **Standard pulse**: duration + magnitude; the runner adds 10% padding before/after, builds a high‑resolution vector, and sets everything else to zero.  
- **Custom profile**: select a `.m` file in `power_profiles/`. Each script must create `<filename>_pp` with fields:
  ```matlab
  time_data   % seconds, vector
  power_data  % or current_data; units depend on mode
  description % optional
  ```
  Example loader pattern inside the file:
  ```matlab
  my_profile_pp.time_data = [0 1 2 3];
  my_profile_pp.power_data = [0 5e3 5e3 0];  % W if mode=power
  my_profile_pp.description = '2 s 5 kW block';
  ```
- Scaling & sign conventions (apply to both backends): profile values are system‑level; the runner divides by parallels (and series × cells for power) to get per‑cell demand. Positive entries mean charging at the system level; the solver expects discharge as positive, so values are negated before simulation. Profiles are linearly interpolated to the chosen timestep.

## Temperature profile definition
- Options at the prompt:  
  1) Constant temperature (single value).  
  2) Load from `temperature_profiles/*.m`.  
  3) Manual entry of 12 monthly averages.  
- A temperature profile function must return a struct with *at least* one of:  
  - `monthlyTemps` (1x12 vector, °C)  
  - `dailyProfiles` (cell of structs with `hours`, `temps`, optional `label`)  
  - `hourlyTemps` (12 x N matrix, °C)  
  It can also include `name` and `description`. The runner normalizes missing pieces: fills daily curves from monthly averages, back‑fills monthly mean from daily/hourly data, and computes the overall average (`temperature_C`). Solar exposure (if enabled) is applied to derive cabinet‑effective temps.
- Monte Carlo ambient analysis perturbs these daily curves with a Gaussian derived from the 99th‑percentile delta, applies optional smoothing, and repeats the lifetime calc over `numTrials` and `daysPerMonth`.

## Grid search vs fixed starting voltage
- **Fixed start voltage** (default): you type `operating.startVoltage`. Design mode runs a binary search **only** on parallel modules at that voltage. Lifetime simulation does the same with the provided voltage.  
- **Voltage grid search** (when you enable optimization): you supply a [Vmin, Vmax] range and number of points. For each grid voltage, the runner:  
  1) Sets `startVoltage` to that grid value.  
  2) Runs the parallel-module binary search (design) or lifetime parallel search.  
  3) Records whether constraints are met (voltage window, current limit, lifetime).  
  It then picks the highest voltage among the solutions that use the *fewest* parallel modules. This avoids over‑designing parallels when a slightly lower voltage would have sufficed, and surfaces the best admissible start voltage automatically.

## Saving and reusing configurations
- At startup the runner offers to load any file in `configs/` (`.json`, `.mat` with `caseConfig`, or `.m` returning a struct). Metadata is inferred if absent.  
- To save a config interactively, use `runner.prompt_save_config(caseConfig)` (invoked by `create_config_tool.m` if you want to build configs without running a simulation). Files are pretty-printed JSON by default.  
- Saved configs can mix interactive defaults with overrides; missing fields are re-hydrated via `+config/default_analysis` and `runner.ensure_simulation_backend`.

## Managing cell definitions (JSON)
- All cells now live as JSON files under `cells/`. If the folder is empty, the built-in library is seeded automatically the first time `runner.get_available_cells` is called.  
- Each file contains the electrical/thermal fields previously hardcoded in `get_available_cells`. Field names match the MATLAB structs (e.g., `Cell_CapRated_F`, `Cell_ResESR10ms_Ohm`, `Module_NumCellSeries`, etc.).
- To add or edit a cell interactively, run `create_cell_tool` from the repo root. It prompts for every required field (name, ESR values, capacitance, voltage, module layout, thermal resistances, etc.), previews defaults, and then writes `<CellName>.json` into `cells/` (with overwrite confirmation). Any new JSON files are automatically picked up the next time the runner is launched or when `runner.get_available_cells` is called from the workspace.

## Operation modes (inputs & outputs)
### Design optimization
- **Key inputs**:  
  - Operation mode = Design.  
  - Max parallel modules, optional divisibility constraint, optional current limit, lifetime requirement (optional but recommended), and optional voltage optimization range.  
  - Duty cycle, hours/day, start voltage (placeholder if voltage search), thermal settings, performance add-ons, backend selection.  
- **Processing**: Binary search (and optional voltage grid search) iterates on parallel module counts until constraints are met. `design.parallel_search` and `design.voltage_search` emit progress in the console.  
- **Outputs** (in `results/<timestamp>_DESIGN_...`):  
  - Standard simulation artifacts (MAT workspace, summary Excel/CSV, plots).  
  - `design_summary.json` via `results.save_design_summary` containing optimal module count, voltage, and constraint status.  
  - Optional performance analysis plots/tables if enabled.  
  - Console summary with min/max voltages, currents, powers, and lifetime at the selected operating point.

### Simulation (fixed configuration)
- **Key inputs**:  
  - Operation mode = Simulation.  
  - Explicit series and parallel module counts (no binary search).  
  - Same operating condition prompts as design (SOH, environment, solar, duty cycle, hours, voltage limits) plus optional Monte Carlo and profile selection.  
  - Backend choice (Simulink vs ODE) and optional performance add-ons.  
- **Processing**: Direct run of the selected solver with provided config. No optimization loops, so the run time is dominated by the electrical model and optional analyses.  
- **Outputs** (in `results/<timestamp>_SIM_...`):  
  - `simulation_workspace.mat`, `simulation_summary.xlsx/.csv`, `time_series_data.xlsx/.csv`.  
  - Plot set from `results.generate_plots`.  
  - Optional performance folders/files if time-domain/power-domain/efficiency analyses are toggled.  
  - Console key-results summary printed by `results.display_key_results`.

### Lifetime mode
- **Key inputs**:  
  - Operation mode = Lifetime (requires minimum lifetime constraint).  
  - Aging timestep (months), maximum simulated years, Monte Carlo options (trial count, percentile requirement, random seed).  
  - Whether to optimize starting voltage within a range or keep a fixed voltage.  
  - All standard operating condition inputs (SOH, environment profile, solar, duty cycle, etc.).  
- **Processing**: `lifetime.run_mode` builds monthly periods from the environment profile, then performs either a voltage grid search or fixed-voltage parallel search to find the minimum hardware that satisfies the lifetime target. Thermal and SOH decay are tracked over the simulated years, with optional Monte Carlo replayed on the full lifetime timeline.  
- **Outputs** (in `results/<timestamp>_SIM_...` with lifetime metadata inside `caseConfig`):  
  - Start/end waveform plots via `lifetime.plot_waveform_comparison`.  
  - SOH evolution plot, steady temperature trend, Monte Carlo percentile plot (if enabled).  
  - Lifetime summary file produced by `lifetime.save_summary` capturing achieved years, final SOH, Monte Carlo pass/fail, and selected hardware.  
  - Standard simulation workspace/summary/time-series files for the start-of-life configuration, plus any performance analyses requested.  
  - Console report highlighting achieved lifetime, final SOH, and Monte Carlo stats.

## Performance optimization modes
These optional analyses can be toggled during the performance prompts (step 11) or when enabling the thermal duty-cycle solver (step 10). Each mode writes its own plots/tables under `results/<timestamp>_.../performance_*`.

1. **Max duration search (time-domain)** – Specify a constant system power (kW) and the maximum pulse duration to consider. The tool sweeps SOH downward (default 5% steps) and, for each SOH, performs a binary search on pulse length until either system voltage limits or the configured current limit would be exceeded. Outputs include a plot of achievable duration vs SOH and a table summarizing duration, voltage droop, and peak current at the boundary.
2. **Max power search (power-domain)** – Provide a fixed pulse duration and the maximum power you want to investigate. The runner iteratively increases power until the system violates voltage/current constraints, again repeating for each SOH step. Results include max deliverable power vs SOH plots and tabulated voltages/currents at the limit.
3. **Efficiency vs lifetime (SOH sweep)** – Evaluates round-trip efficiency at each SOH point, which effectively shows how efficiency degrades with aging/lifetime (since SOH tracks life). Outputs are plots/tables of efficiency vs SOH and optional CSV summaries.
4. **Max thermal load (duty-cycle solver)** – When you enable the thermal limit question, the runner iteratively searches for the highest duty cycle that still meets the lifetime requirement given the cooling configuration. This yields a single maximum duty-cycle percentage stored in `metrics.max_duty_cycle` and reported alongside the main results.

## Outputs
- `results/<timestamp>_<mode>_<cell>_<series>x<parallel>_<V>_<profile>.`  
- Contents per run:  
  - `simulation_workspace.mat` (Results struct + caseConfig + metrics).  
  - `simulation_summary.xlsx` (or `.csv` fallback) with derived metrics.  
  - `time_series_data.xlsx` (or `.csv`) with per‑sample currents, voltages, powers (cell and system).  
  - Plots from `+results/generate_plots` (voltage/current/power/temperature, lifetime traces).  
  - Design runs: extra summary via `+results/save_design_summary`.  
  - Performance scans: additional figures/tables from `+performance/*`.

## Tips 
- Keep `power_profiles/` and `temperature_profiles/` under version control so future users inherit the same stimuli.  
- If the Simulink model is unavailable, set the backend to ODE for a fast check (reduced physics, but good for load/voltage sanity). The ODE model is accurate enough 99% of the times, and also its implementation reflect the simulink one. 
- For repeatability across machines, prefer loading/saving JSON configs in `configs/` and point to the matching profiles.  
- Lifetime mode requires a lifetime target; design/simulation do not, but setting one enables thermal duty‑cycle search.  
- When enabling Monte Carlo (ambient or lifetime), expect longer runtimes—set seeds if you need deterministic reproduction.

## To be implemented

- Dependency with temperature: now the electrical parameters of the model don't depend on the temperature. 

- SOH curves. Implement new and more accurate curves.
