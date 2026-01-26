%% Part 6
% Tell GPT to convert this to my data
% first set new frequency to get interpolation factor
fs2 = 1024;
scalefac = floor(fs2/fs);
% use factor to get new length of signal and arrays
N2 = N*scalefac; % scales by the scale factor fs2
f2 = (0:N2 - 1)/N2*fs2;
dt2 = Ts/scalefac; t2 = 0:dt2:N2*dt2 - dt2;
% create zero-padded fft and force symmetry
G2 = zeros(1, N2); % zero-pad array
G2(1:N/2 + 1) = G(1:N/2+1); %
G2(N2-N/2 + 2:N2) = G(N/2 + 2:N);
G2(N/2 + 1) = G2(N/2 + 1)/2;
G2(N2 - N/2 + 1) = G2(N/2 + 1);
% do inverse FFT on zero-padded fft
g2 = ifft(G2)*scalefac;
% plot old and new signal
figure
hold on
plot(t, g); plot(t2, g2);
hold off
xlim([0.5 1.0]); xlabel("Time (s)");
ylim([-15 20]); ylabel("Amplitude (cm)");
title("g(t)"); grid on; legend(["Original S