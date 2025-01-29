function dc_dc_converter_gui
    % Create the figure window
    f = figure('Position', [100, 100, 600, 600], 'Name', 'DC-DC Converter Simulator with Topology Selector');

    % Topology selector
    uicontrol('Style', 'text', 'Position', [50, 550, 100, 20], 'String', 'Topology:');
    topologySelector = uicontrol('Style', 'popupmenu', 'Position', [150, 550, 100, 20], ...
        'String', {'Buck', 'Boost', 'Buck-Boost'}, 'Value', 1);

    % Vin input
    uicontrol('Style', 'text', 'Position', [50, 500, 100, 20], 'String', 'Vin (V):');
    vinInput = uicontrol('Style', 'edit', 'Position', [150, 500, 100, 20], 'String', '24');
    
    % Vout input
    uicontrol('Style', 'text', 'Position', [50, 460, 100, 20], 'String', 'Vout (V):');
    voutInput = uicontrol('Style', 'edit', 'Position', [150, 460, 100, 20], 'String', '12');
    
    % Iout input
    uicontrol('Style', 'text', 'Position', [50, 420, 100, 20], 'String', 'Iout (A):');
    ioutInput = uicontrol('Style', 'edit', 'Position', [150, 420, 100, 20], 'String', '1.5');
    
    % Fsw input
    uicontrol('Style', 'text', 'Position', [50, 380, 100, 20], 'String', 'Fsw (Hz):');
    fswInput = uicontrol('Style', 'edit', 'Position', [150, 380, 100, 20], 'String', '50000');
    
    % Loss Parameters: Rsw, Rd, Resr
    uicontrol('Style', 'text', 'Position', [50, 340, 100, 20], 'String', 'Rsw (Ohms):');
    RswInput = uicontrol('Style', 'edit', 'Position', [150, 340, 100, 20], 'String', '0.01');  % Switch resistance
    
    uicontrol('Style', 'text', 'Position', [50, 300, 100, 20], 'String', 'Rd (Ohms):');
    RdInput = uicontrol('Style', 'edit', 'Position', [150, 300, 100, 20], 'String', '0.01');  % Diode resistance
    
    uicontrol('Style', 'text', 'Position', [50, 260, 100, 20], 'String', 'Resr (Ohms):');
    ResrInput = uicontrol('Style', 'edit', 'Position', [150, 260, 100, 20], 'String', '0.01');  % Capacitor ESR
    
    % Time span selection
    uicontrol('Style', 'text', 'Position', [50, 220, 100, 20], 'String', 'Time Span (s):');
    timeSpanInput = uicontrol('Style', 'popupmenu', 'Position', [150, 220, 100, 20], ...
        'String', {'0.01', '0.05', '0.1', '0.2', '0.5', '1.0'}, 'Value', 1);

    % Run simulation button
    uicontrol('Style', 'pushbutton', 'Position', [100, 180, 120, 30], 'String', 'Run Simulation', ...
        'Callback', @runSimulation);
    
    % Display calculated values: L, C, R
    uicontrol('Style', 'text', 'Position', [50, 150, 100, 20], 'String', 'Inductor L (H):');
    LText = uicontrol('Style', 'text', 'Position', [150, 150, 100, 20], 'String', 'N/A');

    uicontrol('Style', 'text', 'Position', [50, 120, 100, 20], 'String', 'Capacitor C (F):');
    CText = uicontrol('Style', 'text', 'Position', [150, 120, 100, 20], 'String', 'N/A');

    uicontrol('Style', 'text', 'Position', [50, 90, 100, 20], 'String', 'Resistance R (Ohms):');
    RText = uicontrol('Style', 'text', 'Position', [150, 90, 100, 20], 'String', 'N/A');

    % Axes for plotting
    ax1 = axes('Position', [0.4, 0.55, 0.55, 0.35]);
    ax2 = axes('Position', [0.4, 0.1, 0.55, 0.35]);

    % Callback function for the simulation
    function runSimulation(~, ~)
        % Get user inputs
        topology = get(topologySelector, 'String');
        topology = topology{get(topologySelector, 'Value')};  % Selected topology
        Vin = str2double(get(vinInput, 'String'));
        Vout = str2double(get(voutInput, 'String'));
        Iout = str2double(get(ioutInput, 'String'));
        fsw = str2double(get(fswInput, 'String'));
        Rsw = str2double(get(RswInput, 'String'));
        Rd = str2double(get(RdInput, 'String'));
        Resr = str2double(get(ResrInput, 'String'));

        % Get time span selection
        timeSpanOptions = [0.01, 0.05, 0.1, 0.2, 0.5, 1.0];
        tspan = timeSpanOptions(get(timeSpanInput, 'Value'));

        % Simulation and component calculation
        [L, C, R, t, I_L, V_C] = dc_dc_converter_simulation(topology, Vin, Vout, Iout, fsw, Rsw, Rd, Resr, tspan);
        
        % Update the text fields with calculated values
        set(LText, 'String', sprintf('%.2e', L));   % Inductance (H)
        set(CText, 'String', sprintf('%.2e', C));   % Capacitance (F)
        set(RText, 'String', sprintf('%.2f', R));   % Resistance (Ohms)

        % Plot results
        cla(ax1);
        plot(ax1, t, I_L, 'b', 'LineWidth', 1.5);
        xlabel(ax1, 'Time (s)');
        ylabel(ax1, 'Inductor Current (A)');
        title(ax1, 'Inductor Current vs Time');
        grid(ax1, 'on');

        cla(ax2);
        plot(ax2, t, V_C, 'r', 'LineWidth', 1.5);
        xlabel(ax2, 'Time (s)');
        ylabel(ax2, 'Output Voltage (V)');
        title(ax2, 'Output Voltage vs Time');
        grid(ax2, 'on');
    end

    % --- DC-DC Converter Simulation Function ---
    function [L, C, R, t, I_L, V_C] = dc_dc_converter_simulation(topology, Vin, Vout, Iout, fsw, Rsw, Rd, Resr, tspan)
        % Design parameters
        Delta_IL_percent = 0.3;       % Desired inductor ripple current as a percentage of Iout (e.g., 30%)
        Delta_Vout_percent = 0.01;    % Desired output voltage ripple as a percentage of Vout (e.g., 1%)

        % Duty cycle calculation based on topology
        switch topology
            case 'Buck'
                D = Vout / Vin;      % Duty cycle for Buck converter
            case 'Boost'
                D = 1 - (Vin / Vout); % Duty cycle for Boost converter
            case 'Buck-Boost'
                D = Vout / (Vin + Vout); % Duty cycle for Buck-Boost converter
        end

        % Ripple current and voltage calculations
        Delta_IL = Delta_IL_percent * Iout;        % Inductor ripple current (A)
        Delta_Vout = Delta_Vout_percent * Vout;    % Output voltage ripple (V)

        % Component calculations
        switch topology
            case 'Buck'
                L = (Vin - Vout) * D / (Delta_IL * fsw);   % Inductance (H)
                C = Delta_IL / (8 * fsw * Delta_Vout);     % Capacitance (F)
            case 'Boost'
                L = Vin * D / (Delta_IL * fsw);            % Inductance (H)
                C = Iout * D / (fsw * Delta_Vout);         % Capacitance (F)
            case 'Buck-Boost'
                L = Vin * D / (Delta_IL * fsw);            % Inductance (H)
                C = Iout * D / (fsw * Delta_Vout);         % Capacitance (F)
        end
        R = Vout / Iout;                           % Load resistance (Ohms)

        % Simulation time span
        tspan = [0 tspan];  % Time span from 0 to selected time

        % Initial conditions
        I0 = 0;                % Initial inductor current (A)
        V0 = 0;                % Initial capacitor voltage (V)
        x0 = [I0; V0];         % Initial state vector

        % ODE solver (use a stiff solver for Boost and Buck-Boost)
        options = odeset('RelTol', 1e-6, 'AbsTol', 1e-6);
        [t, x] = ode15s(@(t, x) dc_dc_converter_ode(t, x, topology, Vin, L, C, R, D, fsw, Rsw, Rd, Resr), tspan, x0, options);

        % Extract results
        I_L = x(:, 1);  % Inductor current
        V_C = x(:, 2);  % Capacitor voltage (output voltage)
    end

    % --- DC-DC Converter ODE Function ---
    function dxdt = dc_dc_converter_ode(t, x, topology, Vin, L, C, R, D, fsw, Rsw, Rd, Resr)
        % State variables
        I_L = x(1); % Inductor current
        V_C = x(2); % Capacitor voltage (output voltage)

        % Switching logic with conduction losses
        Tsw = 1 / fsw; % Switching period
        if mod(t, Tsw) < D * Tsw
            % Switch is ON, consider Rsw
            switch topology
                case 'Buck'
                    dI_Ldt = (Vin - V_C - I_L * Rsw) / L;
                case 'Boost'
                    dI_Ldt = (Vin - I_L * Rsw) / L;
                case 'Buck-Boost'
                    dI_Ldt = (Vin - I_L * Rsw) / L;
            end
        else
            % Switch is OFF, consider Rd
            switch topology
                case 'Buck'
                    dI_Ldt = (-V_C - I_L * Rd) / L;
                case 'Boost'
                    dI_Ldt = (Vin - V_C - I_L * Rd) / L;
                case 'Buck-Boost'
                    dI_Ldt = (-V_C - I_L * Rd) / L;
            end
        end

        % Capacitor voltage derivative with ESR
        dV_Cdt = (I_L - V_C / R - V_C / Resr) / C;

        % State derivatives
        dxdt = [dI_Ldt; dV_Cdt];
    end
end