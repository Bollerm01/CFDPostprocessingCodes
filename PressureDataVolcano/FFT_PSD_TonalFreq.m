%% Very-Coarse-Bin Tonal FFT Extraction
% -----------------------------------
% Purpose:
% - Aggressively smooth spectrum
% - Extract only dominant cavity tones
% - Suppress numerical / grid noise
%
% This version intentionally sacrifices resolution
% for robustness.
% -----------------------------------

clear; clc; close all;

%% ===================== FILE SELECTION =====================
[fileName, filePath] = uigetfile( ...
    {'*.dat;*.DAT','CFD Probe Files (*.dat, *.DAT)'}, ...
    'Select Pressure Probe Data File');

if isequal(fileName,0)
    error('No file selected.');
end

filename = fullfile(filePath, fileName);
fprintf('Selected file: %s\n', filename);

%% ===================== USER INPUTS ========================
numProbes = 25;

% ---- Physical scaling ----
L     = 0.068418;        % SSWT cavity length [m]
Uinf  = 695.0;      % freestream velocity [m/s]

% ---- Aggressive coarsening controls ----
decimFactor   = 4;     % 4–8 recommended
segmentFrac   = 0.25;  % use only 25% of record per FFT
NFFT_fixed    = 512;   % hard cap on FFT size

% ---- Peak detection ----
numTones     = 4;
minFreqHz    = 300;
peakPromFrac = 0.15;

% ---- Signal choice ----
useProbeAveraging = false;
probeID = 5;

%% ===================== LOAD DATA ==========================
data = readmatrix(filename, 'FileType', 'text');

time = data(:,1);
p    = data(:,2:(numProbes+1));

dt = mean(diff(time));
Fs = 1/dt;

fprintf('Original Fs = %.1f Hz\n', Fs);

%% ===================== PREPROCESS =========================
p = detrend(p, 'constant');

%% ===================== SIGNAL SELECTION ===================
if useProbeAveraging
    signal = mean(p,2);
    fprintf('Using probe-averaged signal\n');
else
    signal = p(:,probeID);
    fprintf('Using probe %02d\n', probeID-1);
end

%% ===================== DECIMATION =========================
signal = decimate(signal, decimFactor);
Fs = Fs / decimFactor;

fprintf('Decimated Fs = %.1f Hz\n', Fs);

%% ===================== SEGMENT SELECTION ==================
Nt = length(signal);
segLength = floor(segmentFrac * Nt);

signal = signal(1:segLength);
Nt = length(signal);

fprintf('Using %d samples (%.0f%% of record)\n', ...
        Nt, 100*segmentFrac);

%% ===================== FFT COMPUTATION ====================
window = hann(Nt);
signal_w = signal .* window;

% Force very coarse bins
NFFT = min(NFFT_fixed, Nt);

X = fft(signal_w, NFFT);

f = Fs/2 * linspace(0,1,NFFT/2+1);

PSD = (2/(Fs*sum(window.^2))) * abs(X(1:NFFT/2+1)).^2;

df = Fs / NFFT;
fprintf('Bin width Δf = %.1f Hz\n', df);

%% ===================== PEAK DETECTION =====================
validIdx = f >= minFreqHz;

PSD_valid = PSD(validIdx);
f_valid   = f(validIdx);

minProminence = peakPromFrac * max(PSD_valid);

[pkVals, pkLocs] = findpeaks(PSD_valid, f_valid, ...
    'NPeaks', numTones, ...
    'SortStr','descend', ...
    'MinPeakProminence', minProminence);

%% ===================== REPORT =============================
fprintf('\nDominant Tones (Very Coarse Bins):\n');
fprintf('----------------------------------\n');

for i = 1:length(pkLocs)
    St = pkLocs(i) * L / Uinf;
    fprintf('Tone %d:  f ≈ %7.0f Hz   |   St ≈ %.3f\n', ...
            i, pkLocs(i), St);
end

%% ===================== PLOTS ==============================

figure;
plot(f, PSD, 'k', 'LineWidth', 1.4); hold on;
plot(pkLocs, pkVals, 'ro', 'MarkerSize', 8, 'LineWidth', 1.6);
grid on;
xlabel('Frequency [Hz]');
ylabel('PSD');
title('Very-Coarse-Bin Tonal Spectrum');
xlim([0 max(pkLocs)*1.4]);

figure;
loglog(f, PSD, 'k', 'LineWidth', 1.4); hold on;
loglog(pkLocs, pkVals, 'ro', 'MarkerSize', 8, 'LineWidth', 1.6);
grid on;
xlabel('Frequency [Hz]');
ylabel('PSD');
title('Very-Coarse-Bin Spectrum (Log Frequency)');

%% ===================== END SCRIPT =========================
