%% Step 1: Define Room Properties and Parameters
Lx = 5; % Room length in meters
Ly = 5; % Room width in meters
Lz = 3; % Room height in meters
fs = 44100; % Sampling frequency (Hz)
t = 0:1/fs:10; % Time vector (10 seconds of simulation)

% Primary Noise Source (e.g., a low-frequency sine wave)
f_noise = 100; % Frequency of primary noise (Hz)
x_p = sin(2*pi*f_noise*t); % Primary noise signal

% Secondary Source and Error Sensor Position
primary_source_pos = [2, 2, 1]; % Position of the primary source (x, y, z)
secondary_source_pos = [4, 4, 1]; % Position of the secondary source (x, y, z)
error_sensor_pos = [3, 3, 1]; % Position of the error sensor (x, y, z)

%% Step 2: Model Room Acoustics (RIRs)
% Use rir_generator (or equivalent) to calculate the Room Impulse Response (RIR)
% In this case, use a simplified assumption of impulse response.

% Generate impulse response from primary source to error sensor (h_p) and secondary to error sensor (h_s)
h_p = room_impulse_response(primary_source_pos, error_sensor_pos, fs); % Simulated RIR
h_s = room_impulse_response(secondary_source_pos, error_sensor_pos, fs); % Simulated RIR

% Convolve the noise signal with RIRs
y_p = conv(x_p, h_p, 'same'); % Primary noise propagation
y_s = conv(x_p, h_s, 'same'); % Secondary noise propagation

% Error signal at sensor
e = y_p + y_s;

%% Step 3: Implement Adaptive Noise Cancellation (FIR + LMS)
% FIR filter setup
M = 32; % Number of filter taps
w = zeros(M, 1); % Initialize filter coefficients
mu = 0.01; % Step size for LMS

% Pad input signal if necessary
if length(x_p) < M
    x_p = [zeros(M-1, 1); x_p(:)];
end

y_s_output = zeros(size(x_p)); % Anti-noise output signal

for n = M:length(x_p)
    % Extract the input vector
    x_fir = x_p(n:-1:n-M+1); % Ensure it's Mx1
    x_fir = x_fir(:);        % Force column vector

    % Filter output (anti-noise)
    y_s_output(n) = w' * x_fir; % w' (1xM) * x_fir (Mx1) = scalar

    % Error signal
    e(n) = y_p(n) - y_s_output(n);

    % Update filter weights using LMS
    w = w + 2 * mu * e(n) * x_fir; % LMS weight update
end



%% Step 4: Evaluate ANC Performance
% Plot error signal (e(n))
figure;
subplot(2, 1, 1);
plot(t, e);
title('Error Signal (e(n))');
xlabel('Time (s)');
ylabel('Amplitude');

% Signal-to-Noise Ratio (SNR) or dB attenuation
SNR_before = 10*log10(var(y_p) / var(e));
SNR_after = 10*log10(var(y_p) / var(y_s_output));

disp(['SNR before ANC: ', num2str(SNR_before), ' dB']);
disp(['SNR after ANC: ', num2str(SNR_after), ' dB']);

% Plot the attenuation
subplot(2, 1, 2);
plot(t, y_p, 'r', t, y_s_output, 'b');
title('Primary Noise vs Anti-Noise Output');
legend('Primary Noise', 'Anti-Noise Output');
xlabel('Time (s)');
ylabel('Amplitude');

%% Step 5: Visualization of the 3D Room
% Room dimensions
figure;
room_plot = plot3([0, Lx, Lx, 0, 0, 0], ...
                  [0, 0, Ly, Ly, 0, 0], ...
                  [0, 0, 0, 0, Lz, Lz], 'k');
hold on;
% Plot the positions of the sources and sensors
scatter3(primary_source_pos(1), primary_source_pos(2), primary_source_pos(3), 'ro');
scatter3(secondary_source_pos(1), secondary_source_pos(2), secondary_source_pos(3), 'bo');
scatter3(error_sensor_pos(1), error_sensor_pos(2), error_sensor_pos(3), 'go');

% Annotate positions
text(primary_source_pos(1), primary_source_pos(2), primary_source_pos(3), ' Primary Source');
text(secondary_source_pos(1), secondary_source_pos(2), secondary_source_pos(3), ' Secondary Source');
text(error_sensor_pos(1), error_sensor_pos(2), error_sensor_pos(3), ' Error Sensor');

% Labels and axes limits
xlabel('X Position (m)');
ylabel('Y Position (m)');
zlabel('Z Position (m)');
title('3D Room with Sources and Sensors');
axis([0 Lx 0 Ly 0 Lz]);
grid on;
hold off;

%% Step 6: Further Evaluation (Optimization)
% For more advanced scenarios, you can explore genetic algorithms for optimizing sensor and source placement.
% Plot the attenuation
% Check if the lengths match
if length(t) == length(y_p) && length(t) == length(y_s_output)
    % Plot the attenuation
    figure;
    subplot(2, 1, 2);
    plot(t, y_p, 'r', t, y_s_output, 'b');
    title('Primary Noise vs Anti-Noise Output');
    legend('Primary Noise', 'Anti-Noise Output');
    xlabel('Time (s)');
    ylabel('Amplitude');
else
    disp('Length mismatch between time vector and signals');
end
if mod(n, 500) == 0  % Print every 500 iterations
    disp(['Filter weights at iteration ', num2str(n), ':']);
disp(w);
end
