%% ============================================================
%  KULITE CSV -> PRESSURE -> RMS -> SPL -> FFT PROCESSING
%
%  DUAL CSV INPUT: K1-3 (floor) and K4-6 (ramp)
%  K4-6 CSV: Voltage_0=K4, Voltage_1=K6, Voltage_2=K5
%  K1-3 CSV: Voltage_0=K1, Voltage_1=K2, Voltage_2=K3
%
%% ============================================================

clear all; close all; clc;

%% ---------------- USER SETTINGS ----------------

df_desired = 25;          % Desired FFT bin width [Hz]
fs         = 50000;       % Sampling frequency [Hz]
PREF       = 20e-6;       % Acoustic reference pressure [Pa]
PSI_TO_PA  = 6894.757;

% ===== KULITE SENSOR SENSITIVITY =====
% Order matches K1..K6 after reordering

% K1-K3: Voltage_0->K1, Voltage_1->K2, Voltage_2->K3
man_cal_sens_K13 = [ ...
    30.104/1000 ...   % K1
    30.024/1000 ...   % K2
    29.976/1000];     % K3

% K4-K6 (raw CSV order): Voltage_0->K4, Voltage_1->K6, Voltage_2->K5
% Stored here in RAW CSV column order; reordering happens below
man_cal_sens_K46_raw = [ ...
    29.972/1000 ...   % Voltage_0 -> K4
    29.824/1000 ...   % Voltage_1 -> K6
    30.178/1000];     % Voltage_2 -> K5

% ===== GAINS =====
% K1-K3 (in K1,K2,K3 order)
gain_K13 = [64.0, 64.0, 64.0];

% K4-K6 in RAW CSV column order (Voltage_0, Voltage_1, Voltage_2)
gain_K46_raw = [64.0, 64.0, 64.0];

%% ---------------- LOAD CSVs ----------------

[file13, path13] = uigetfile('*.csv', 'Select K1-3 CSV File');
if isequal(file13, 0), error('No K1-3 CSV selected.'); end
T13 = readtable(fullfile(path13, file13));

[file46, path46] = uigetfile('*.csv', 'Select K4-6 CSV File');
if isequal(file46, 0), error('No K4-6 CSV selected.'); end
T46 = readtable(fullfile(path46, file46));

disp('K1-3 Columns:'); disp(T13.Properties.VariableNames)
disp('K4-6 Columns:'); disp(T46.Properties.VariableNames)

%% ---------------- REORDER K4-6 COLUMNS ----------------
% Raw:      Voltage_0=K4, Voltage_1=K6, Voltage_2=K5
% Reorder to logical K4, K5, K6 sequence: [col1, col3, col2]

reorder_46 = [1, 2, 3];   % K4=col1, K5=col3, K6=col2

man_cal_sens_K46 = man_cal_sens_K46_raw(reorder_46);
gain_K46         = gain_K46_raw(reorder_46);
% man_cal_sens_K46 = man_cal_sens_K46_raw;
% gain_K46 = gain_K46_raw;

%% ---------------- CHANNEL DEFINITIONS ----------------
% All 6 channels unified in K1..K6 order

sensorLabels = {'K1','K2','K3','K4','K5','K6'};

rawChannels = {'Voltage_0','Voltage_1','Voltage_2'};  % same names in both CSVs

% Map each K# to its source table and raw column index after reordering
%   sourceTable{i} : 'K13' or 'K46'
%   rawColIdx(i)   : which raw CSV column (1,2,3) holds this sensor
sourceTable = {'K13','K13','K13','K46','K46','K46'};

% K1-3: trivial mapping [1,2,3]
% K4-6: reorder_46 maps logical [K4,K5,K6] -> raw col [1,3,2]
rawColIdx   = [1, 2, 3, reorder_46];

man_cal_sens_all = [man_cal_sens_K13, man_cal_sens_K46];
gain_all         = [gain_K13,         gain_K46];

%% ---------------- TIME VECTORS ----------------

time13 = T13.Time_;
time46 = T46.Time_;

%% ---------------- FFT SETUP ----------------

Nfft = round(fs / df_desired);
if mod(Nfft,2) ~= 0, Nfft = Nfft + 1; end

df_actual = fs / Nfft;

fprintf('Desired df: %.2f Hz\n', df_desired);
fprintf('Actual  df: %.2f Hz\n', df_actual);
fprintf('FFT Length: %d\n',      Nfft);

f    = (0:Nfft-1).' * df_actual;
nwin = hann(Nfft);

%% ---------------- FIGURES ----------------

figure(1); hold on; grid on;
title('Pressure Fluctuation Time Traces');
xlabel('Time [s]'); ylabel('Pressure Fluctuation [Pa]');

figure(2); hold on; grid on;
title('Kulite Narrowband SPL Spectrum');
xlabel('Frequency [Hz]'); ylabel('SPL [dB re 20 \muPa]');

figure(3); hold on; grid on;
title('Power Spectral Density');
xlabel('Frequency [Hz]'); ylabel('PSD [Pa^2/Hz]');

%% ---------------- BANDPASS FILTER ----------------

nyq = fs / 2;
Wn  = [100 20000] / nyq;
[b, a] = butter(5, Wn, 'bandpass');

%% ---------------- LOOP THROUGH ALL 6 CHANNELS ----------------

for ch = 4:6

    %% ----- SELECT SOURCE TABLE & RAW COLUMN -----

    colIdx = rawColIdx(ch);
    colName = rawChannels{colIdx};

    if strcmp(sourceTable{ch}, 'K13')
        V    = T13.(colName);
        time = time13;
    else
        V    = T46.(colName);
        time = time46;
    end

    %% ----- SENSITIVITY & GAIN -----

    sensor_sens = man_cal_sens_all(ch);
    current_gain = gain_all(ch);
    system_sens  = sensor_sens * current_gain;

    %% ----- VOLTAGE -> PRESSURE -----

    p_psi   = V ./ system_sens;
    p_pa    = p_psi * PSI_TO_PA;
    p_fluct = p_pa - mean(p_pa);

    %% ----- FILTER -----

    p_filt = filtfilt(b, a, p_fluct);

    %% ----- RMS / OASPL -----

    prms  = rms(p_filt);
    OASPL = 20*log10(prms / PREF);

    fprintf('\n=====================================\n');
    fprintf('Sensor : %s  (source: %s, raw col: %s)\n', ...
        sensorLabels{ch}, sourceTable{ch}, colName);
    fprintf('Gain   : %.2f\n',    current_gain);
    fprintf('RMS    : %.6f Pa\n', prms);
    fprintf('OASPL  : %.2f dB re 20uPa\n', OASPL);

    %% ----- FFT / SPL -----

    nsamp  = length(p_filt);
    blocks = floor(nsamp / Nfft);
    Xf     = zeros(Nfft, blocks-1);
    pt_finish = 0;

    for n = 1:blocks-1
        pt_start  = pt_finish + 1;
        pt_finish = n * Nfft;
        x  = p_filt(pt_start:pt_finish);
        xw = x .* nwin;
        X  = fft(xw);
        Xmag = 2 * abs(X) / Nfft;
        Xf(:,n) = Xmag;
    end

    Xavg = mean(Xf, 2);
    NB   = 20*log10(Xavg / PREF);

    %% ----- PSD -----

    win_power = mean(nwin.^2);
    PSD = (Xavg(1:Nfft/2).^2) / (2 * df_actual * win_power);

    %% ----- DOMINANT FREQUENCY -----

    [~, idx] = max(NB(2:Nfft/2));
    idx = idx + 1;
    fprintf('Dominant Freq: %.2f Hz\n', f(idx));

    %% ----- PLOTS -----

    figure(1)
    plot(time, p_fluct, 'DisplayName', sensorLabels{ch}, 'LineWidth', 1);

    figure(2)
    semilogx(f(1:Nfft/2), NB(1:Nfft/2), ...
        'DisplayName', sensorLabels{ch}, 'LineWidth', 1.5);

    figure(3)
    semilogx(f(1:Nfft/2), 10*log10(PSD), ...
        'DisplayName', sensorLabels{ch}, 'LineWidth', 1.5);

end

%% ---------------- FINALIZE PLOTS ----------------

figure(1); legend('Location','best');

figure(2); set(gca,'XScale','log'); legend('Location','best');

figure(3); 
set(gca,'XScale','log'); 
ylabel('PSD [dB re Pa^2/Hz]');
legend('Location','best');