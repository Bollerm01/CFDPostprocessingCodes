%% ============================================================
%  KULITE CSV -> PRESSURE -> RMS -> SPL -> FFT PROCESSING
%
%  OVERLAY FFTs FOR ALL CHANNELS
%  WITH INDIVIDUAL CHANNEL GAINS
%
%% ============================================================

clear; clc; 

%% ---------------- USER SETTINGS ----------------

df_desired = 75;          % Desired FFT bin width [Hz]

fs = 50000;               % Sampling frequency [Hz]

% ===== KULITE SENSOR SENSITIVITY =====

sensor_sens = 0.03;       % [V/psi]

% ===== INDIVIDUAL CHANNEL GAINS =====
% Match order with Voltage_0 -> Voltage_5

gain = [ ...
    65.3 ...   % Voltage_0
    65.9 ...   % Voltage_1
    65.1 ...   % Voltage_2
    67.15 ...  % Voltage_3
    65.2 ...   % Voltage_4
    66.4];     % Voltage_5

PREF = 20e-6;             % Acoustic reference pressure [Pa]

PSI_TO_PA = 6894.757;

%% ---------------- LOAD CSV ----------------
[file,path] = uigetfile('*.csv','Select CSV File');

if isequal(file,0)
    error('No CSV file selected.');
end

fname = fullfile(path,file);
% fname = "D:\KuliteTestData19May26\Run2.csv";
T = readtable(fname);

disp('Available Columns:')
disp(T.Properties.VariableNames)

%% ---------------- TIME VECTOR ----------------

time = T.Voltage_0_Time_;

%% ---------------- CHANNEL LIST ----------------

% Flipped K1 and K6 due to amp card mismatch
channelNames = { ...
    'Voltage_5', ...
    'Voltage_1', ...
    'Voltage_2', ...
    'Voltage_3', ...
    'Voltage_4', ...
    'Voltage_0'};

nChannels = length(channelNames);

legendNames = { ...
    'K1', ...
    'K2', ...
    'K3', ...
    'K4', ...
    'K5', ...
    'K6'};

%% ---------------- FFT SETUP ----------------

Nfft = round(fs / df_desired);

if mod(Nfft,2) ~= 0
    Nfft = Nfft + 1;
end

df_actual = fs / Nfft;

fprintf('Desired df: %.2f Hz\n',df_desired);
fprintf('Actual df : %.2f Hz\n',df_actual);
fprintf('FFT Length: %d\n',Nfft);

f = (0:Nfft-1).' * df_actual;

nwin = hann(Nfft);

%% ---------------- FIGURES ----------------

figure(1)
hold on
grid on
title('Pressure Fluctuation Time Traces')
xlabel('Time [s]')
ylabel('Pressure Fluctuation [Pa]')

figure(2)
hold on
grid on
title('Kulite Narrowband SPL Spectrum')
xlabel('Frequency [Hz]')
ylabel('SPL [dB re 20 \muPa]')

%% ---------------- LOOP THROUGH CHANNELS ----------------

for ch = 1:nChannels

    %% ----- LOAD CHANNEL -----

    V = T.(channelNames{ch});

    %% ----- CHANNEL-SPECIFIC GAIN -----

    current_gain = gain(ch);

    system_sens = sensor_sens * current_gain;

    %% ----- VOLTAGE -> PRESSURE -----

    p_psi = V ./ system_sens;

    p_pa = p_psi * PSI_TO_PA;

    %% ----- REMOVE MEAN -----

    p_fluct = p_pa - mean(p_pa);

    %% ----- RMS / SPL -----

    prms = rms(p_fluct);

    SPL = 20*log10(prms / PREF);

    fprintf('\n=====================================\n');
    fprintf('Channel: %s\n',channelNames{ch});
    fprintf('Gain: %.2f\n',current_gain);
    fprintf('RMS Pressure = %.6f Pa\n',prms);
    fprintf('Overall SPL  = %.2f dB re 20uPa\n',SPL);

    %% ----- FFT PROCESSING -----

    nsamp = length(p_fluct);

    blocks = floor(nsamp / Nfft);

    Xf = zeros(Nfft,blocks-1);

    pt_finish = 0;

    for n = 1:blocks-1

        pt_start  = pt_finish + 1;
        pt_finish = n * Nfft;

        x = p_fluct(pt_start:pt_finish);

        % Apply Hanning window
        xw = x .* nwin;

        % FFT
        X = fft(xw);

        % Single-sided amplitude spectrum
        Xmag = 2 * abs(X) / Nfft;

        Xf(:,n) = Xmag;

    end

    %% ----- AVERAGE FFT -----

    Xavg = mean(Xf,2);

    %% ----- SPL SPECTRUM -----

    NB = 20*log10(Xavg / PREF);

    %% ----- DOMINANT FREQUENCY -----

    [pk,idx] = max(NB(2:Nfft/2));

    idx = idx + 1;

    peak_freq = f(idx);

    fprintf('Dominant Frequency = %.2f Hz\n',peak_freq);

    %% ----- TIME TRACE PLOT -----

    figure(1)

    plot( ...
        time, ...
        p_fluct, ...
        'DisplayName',legendNames{ch}, ...
        'LineWidth',1);

    %% ----- FFT OVERLAY PLOT -----

    figure(2)

    semilogx( ...
        f(1:Nfft/2), ...
        NB(1:Nfft/2), ...
        'DisplayName',legendNames{ch}, ...
        'LineWidth',1.5);

end
% set(gca, "XScale","log")

%% ---------------- FINALIZE PLOTS ----------------

figure(1)
legend('Location','best')

figure(2)

xlim([1500 20000])
set(gca, "XScale","log")

legend('Location','best')