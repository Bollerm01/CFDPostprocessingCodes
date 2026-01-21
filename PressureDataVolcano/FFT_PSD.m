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

% Rossiter model constants
alpha = 0.25;
kappa = 0.57;

% Number of Rossiter modes to plot
nRoss = 4;

% Welch PSD parameters (recommended for cavity flows)
blockFraction = 8;   % Nt / blockFraction = window length
overlapFrac   = 0.5; % 50% overlap

%% ===================== LOAD DATA =========================
data = readmatrix(filename, 'FileType', 'text');

time = data(:,1);
p    = data(:,2:(numProbes+1));

Nt = length(time);
dt = mean(diff(time));
Fs = 1/dt;

fprintf('Samples: %d | dt = %.3e s | Fs = %.1f Hz\n', Nt, dt, Fs);

%% ===================== PREPROCESS ========================
% Remove mean (essential for cavity FFTs)
p = detrend(p, 'constant');

%% ===================== WELCH PSD =========================
windowLength = floor(Nt / blockFraction);
window       = hann(windowLength);
noverlap     = floor(overlapFrac * windowLength);
nfft         = max(2048, 2^nextpow2(windowLength));

PSD = zeros(nfft/2+1, numProbes);

for k = 1:numProbes
    [PSD(:,k), f] = pwelch(p(:,k), window, noverlap, nfft, Fs);
end

PSD_mean = mean(PSD, 2);

%% ===================== STROUHAL SCALING ==================
St = f * L / Uinf;

%% ===================== ROSSITER MODES ====================
fRoss  = zeros(nRoss,1);
StRoss = zeros(nRoss,1);

for n = 1:nRoss
    fRoss(n)  = (Uinf/L) * (n - alpha) / (1/kappa + Minf);
    StRoss(n) = fRoss(n) * L / Uinf;
end

%% ===================== DOMINANT PEAKS ====================
numPeaks = 5;

[pkVals, pkLocs] = findpeaks(PSD_mean, St, ...
    'SortStr','descend', 'NPeaks', numPeaks);

fprintf('\nDominant Strouhal Numbers:\n');
for i = 1:length(pkLocs)
    fprintf('  St = %.3f\n', pkLocs(i));
end

%% ===================== PLOTS =============================

% ---- Mean PSD (Strouhal-scaled) ----
figure;
semilogx(St, PSD_mean, 'k', 'LineWidth', 2); hold on;
semilogx(pkLocs, pkVals, 'ro', 'MarkerSize', 7, 'LineWidth', 1.2);

for n = 1:nRoss
    xline(StRoss(n),'b--','LineWidth',1.2);
end

grid on;
xlabel('Strouhal Number  St = fL/U_\infty');
ylabel('PSD  [p^2/Hz]');
title('Mean Pressure PSD – Scramjet Cavity');
legend('Mean PSD','Dominant Peaks','Rossiter Modes','Location','best');

% ---- Single Probe PSD (Upstream Shear Layer) ----
probeID = 1;  % probe00000

figure;
semilogx(St, PSD(:,probeID), 'LineWidth', 1.5);
grid on;
xlabel('Strouhal Number');
ylabel('PSD  [p^2/Hz]');
title(sprintf('PSD – Probe %02d', probeID-1));

% ---- Spectral Evolution Along Shear Layer ----
figure;
imagesc(St, 1:numProbes, log10(PSD'));
set(gca,'YDir','normal');
colorbar;
xlabel('Strouhal Number');
ylabel('Probe Index (Upstream → Downstream)');
title('Shear-Layer Spectral Energy Evolution');

% ---- All Probes (Optional Diagnostic) ----
figure; hold on;
for k = 1:numProbes
    semilogx(St, PSD(:,k));
end
grid on;
xlabel('Strouhal Number');
ylabel('PSD');
title('PSD – All Probes');

%% ===================== END SCRIPT ========================
