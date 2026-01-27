%% Standalone RAW FFT Processing Script
% Experimental aeroacoustic pressure data
% Columns: time | probe0000 ... probe0024

clear; clc; close all;

%% ---------------- USER SETTINGS ----------------
nmics = 25;          % Number of probes
N     = 4096;        % Samples per FFT block

%% ---------------- LOAD DATA ----------------
[file, path] = uigetfile('*.dat', 'Select pressure data file');
if isequal(file,0)
    error('No file selected.');
end

data = readtable(fullfile(path,file), 'FileType','text');

time = data{:,1};
pt   = data{:,2:1+nmics};

nsamp = length(time);

%% ---------------- COMPUTE SAMPLING FREQUENCY ----------------
dt = mean(diff(time));   % Mean time step
fs = 1/dt;               % Sampling frequency [Hz]

fprintf('Computed sampling frequency: %.3f Hz\n', fs);

%% ---------------- PREALLOCATE ----------------
Xfsave = zeros(N, nmics);
NB     = zeros(N, nmics);

%% ---------------- FFT SETUP ----------------
h  = 1/fs;
T  = h*N;
df = 1/T;

f = (0:df:fs-df)';

nwin   = hanning(N);
blocks = floor(nsamp/N);

%% ---------------- MAIN LOOP ----------------
for k = 1:nmics

    Xf = zeros(N, blocks-1);

    pt_finish = 0;
    for n = 1:blocks-1

        pt_start  = pt_finish + 1;
        pt_finish = n * N;

        x = pt(pt_start:pt_finish, k);

        X = fft(x .* nwin);

        % Raw pressure amplitude spectrum
        Xf(:,n) = 2 * abs(X) / N;

    end

    % Block-averaged FFT
    Xfsave(:,k) = mean(Xf, 2);

    % Narrowband SPL (re 20 µPa)
    NB(:,k) = 20 * log10(Xfsave(:,k) / 20e-6);

end

%% ---------------- PLOTS ----------------
figure;
plot(f(1:N/2), NB(1:N/2,:));
grid on;
xlabel('Frequency [Hz]');
ylabel('SPL [dB re 20 \muPa]');
title('Raw Narrowband SPL – All Probes');
