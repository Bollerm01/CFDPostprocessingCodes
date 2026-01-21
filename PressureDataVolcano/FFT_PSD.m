%% FFT / PSD Analysis for Ramped Scramjet Cavity Shear Layer
% ---------------------------------------------------------
% Data format:
% Column 1  : time [s]
% Columns 2–26 : pressure probes probe00000 ... probe00024
%
% Features:
% - GUI-based .DAT file selection
% - Welch PSD (robust for shear-layer flows)
% - Strouhal scaling
% - Rossiter mode prediction
% - Shear-layer spectral evolution
%
% ---------------------------------------------------------

clear; clc; close all;

%% ===================== FILE SELECTION GUI =================
[fileName, filePath] = uigetfile( ...
    {'*.dat;*.DAT','CFD Probe Files (*.dat, *.DAT)'}, ...
    'Select Pressure Probe Data File');

if isequal(fileName,0)
    error('No file selected. Script terminated.');
end

filename = fullfile(filePath, fileName);
fprintf('Selected file: %s\n', filename);

%% ===================== USER INPUTS ========================
numProbes = 25;

% --- Flow / Geometry Parameters ---
L     = 0.068418;        % SSWT cavity length [m]
Uinf  = 695.0;      % freestream velocity [m/s]
Minf  = 2.0;         % freestream Mach number

% Rossiter constants
alpha = 0.25;
kappa = 0.57;
nRoss = 4;

% Welch PSD parameters
blockFraction = 8;
overlapFrac   = 0.5;

% ---- Bulk PSD integration limits (Strouhal) ----
St_min = 0.02;
St_max = 1.0;

%% ===================== LOAD DATA ==========================
data = readmatrix(filename, 'FileType', 'text');

time = data(:,1);
p    = data(:,2:(numProbes+1));

Nt = length(time);
dt = mean(diff(time));
Fs = 1/dt;

fprintf('Samples: %d | Fs = %.1f Hz\n', Nt, Fs);

%% ===================== PREPROCESS =========================
p = detrend(p, 'constant');

%% ===================== WELCH PSD ==========================
windowLength = floor(Nt / blockFraction);
window       = hann(windowLength);
noverlap     = floor(overlapFrac * windowLength);
nfft         = max(2048, 2^nextpow2(windowLength));

PSD = zeros(nfft/2+1, numProbes);

for k = 1:numProbes
    [PSD(:,k), f] = pwelch(p(:,k), window, noverlap, nfft, Fs);
end

PSD_mean = mean(PSD, 2);

%% ===================== STRouHAL SCALING ===================
St = f * L / Uinf;

%% ===================== ROSSITER MODES =====================
StRoss = zeros(nRoss,1);
for n = 1:nRoss
    StRoss(n) = (n - alpha) / (1/kappa + Minf);
end

%% ===================== BULK PSD PER PROBE =================
% Integrate PSD over selected Strouhal range
idxSt = (St >= St_min) & (St <= St_max);

bulkPSD = zeros(numProbes,1);
for k = 1:numProbes
    bulkPSD(k) = trapz(St(idxSt), PSD(idxSt,k));
end

% Identify top 5 probes
[bulkPSD_sorted, idx_sorted] = sort(bulkPSD, 'descend');
top5 = idx_sorted(1:5);

fprintf('\nTop 5 Probes by Bulk PSD Energy (St = %.2f–%.2f):\n', ...
        St_min, St_max);
for i = 1:5
    fprintf('  %d) probe%05d  |  Bulk PSD = %.3e\n', ...
        i, top5(i)-1, bulkPSD_sorted(i));
end

%% ===================== PLOTS ==============================

% ---- Mean PSD ----
figure;
semilogx(St, PSD_mean, 'k', 'LineWidth', 2); hold on;
for n = 1:nRoss
    xline(StRoss(n),'b--','LineWidth',1.2);
end
grid on;
xlabel('Strouhal Number');
ylabel('PSD');
title('Mean Pressure PSD – Scramjet Cavity');
legend('Mean PSD','Rossiter Modes','Location','best');

% ---- Spectral Evolution Map ----
figure;
imagesc(St, 1:numProbes, log10(PSD'));
set(gca,'YDir','normal');
colorbar;
xlabel('Strouhal Number');
ylabel('Probe Index');
title('Shear-Layer Spectral Energy Evolution');

% ---- Highlight Top 5 Probes ----
figure; hold on;

% Plot all probes in gray
for k = 1:numProbes
    semilogx(St, PSD(:,k), 'Color', [0.7 0.7 0.7]);
end

% Highlight top 5
colors = lines(5);
for i = 1:5
    k = top5(i);
    semilogx(St, PSD(:,k), 'LineWidth', 2.5, 'Color', colors(i,:));
end

grid on;
xlabel('Strouhal Number');
ylabel('PSD');
title('Top 5 Probes by Bulk PSD Energy');

legendStrings = arrayfun(@(x) ...
    sprintf('probe%05d', x-1), top5, 'UniformOutput', false);
legend(legendStrings, 'Location','best');

%% ===================== END SCRIPT =========================
