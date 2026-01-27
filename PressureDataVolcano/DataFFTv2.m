%% Standalone RAW FFT Processing Script
% Experimental aeroacoustic data
% Columns: time | probe0000 ... probe0024

clear; clc; close all;

%% ---------------- USER SETTINGS ----------------
nmics        = 25;                 % Total number of probes
df_desired   = 50;                 % Hz per FFT bin
plot_probes  = 0:4;      % <<< PROBES TO OVERLAY <<<

%% ---------------- LOAD DATA ----------------
%[file, path] = uigetfile('*.dat', 'Select pressure data file');
file = 'rampLine.pressure.dat';
path = 'E:\Boller CFD\AVIATION CFD\PressureProbeData\';
if isequal(file,0)
    error('No file selected.');
end

data = readtable(fullfile(path,file), 'FileType','text');

time = data{:,1};
pt   = data{:,2:1+nmics};

nsamp = length(time);

%% ---------------- COMPUTE SAMPLING FREQUENCY ----------------
dt = mean(diff(time));
fs = 1/dt;

fprintf('Computed sampling frequency: %.3f Hz\n', fs);

%% ---------------- FFT LENGTH FROM BIN WIDTH ----------------
Nfft = round(fs / df_desired);
if mod(Nfft,2) ~= 0
    Nfft = Nfft + 1;
end

df_actual = fs / Nfft;

fprintf('Requested bin width: %.3f Hz\n', df_desired);
fprintf('Actual bin width:    %.3f Hz\n', df_actual);
fprintf('FFT length used:     %d samples\n', Nfft);

%% ---------------- PREALLOCATE ----------------
Xfsave = zeros(Nfft, nmics);
NB     = zeros(Nfft, nmics);

%% ---------------- FFT SETUP ----------------
f = (0:Nfft-1).' * df_actual;

nwin   = hanning(Nfft);
blocks = floor(nsamp / Nfft);

%% ---------------- MAIN FFT LOOP ----------------
for k = 1:nmics

    Xf = zeros(Nfft, blocks-1);

    pt_finish = 0;
    for n = 1:blocks-1

        pt_start  = pt_finish + 1;
        pt_finish = n * Nfft;

        x = pt(pt_start:pt_finish, k);

        X = fft(x .* nwin);

        % Raw amplitude spectrum
        Xf(:,n) = 2 * abs(X) / Nfft;

    end

    Xfsave(:,k) = mean(Xf, 2);
    NB(:,k)     = 20 * log10(Xfsave(:,k) / 20e-6);

end

%% ---------------- PLOT SELECTED PROBES ----------------
figure; hold on; grid on;

for i = 1:length(plot_probes)
    pidx = plot_probes(i) + 1;   % convert probe number → MATLAB index

    semilogx(f(1:Nfft/2), NB(1:Nfft/2, pidx), ...
        'DisplayName', sprintf('Probe %02d', plot_probes(i)));
end

xlabel('Frequency [Hz]');
ylabel('SPL [dB re 20 \muPa]');
title('Raw Narrowband SPL – Selected Probes');
legend('show');
set(gca,'XScale','log');
% xlim([df_actual fs/2]);
