% Load the real-world noise (chainsaw sound)
[file, path] = uigetfile('*.mp3', 'Select the noise file');
if isequal(file,0)
    disp('No file selected. Using default.');
    [noise, Fs] = audioread('/mnt/data/chainsaw-297887.mp3');
else
    [noise, Fs] = audioread(fullfile(path, file));
end

% Convert stereo to mono if necessary
if size(noise,2) > 1
    noise = mean(noise,2);
end


% Simulate room impulse response (RIR) using the Image Source Method
% Create a basic synthetic Room Impulse Response (RIR)
rir_length = 256;  % Define length of RIR
decay_factor = 0.9;  % Decay rate of reflections
rir = decay_factor.^(0:rir_length-1);  
rir = rir / sum(rir);  % Normalize

% Apply RIR to noise
simulated_noise = conv(noise, rir, 'same');


% Apply RIR to noise to simulate the room effect
simulated_noise = conv(noise, rir, 'same');

% ANC System using FxLMS Algorithm
M = 128;  % Filter length
mu = 0.01;  % Step size
L = length(simulated_noise);
W = zeros(M, 1);  % Adaptive filter coefficients
x = zeros(M, 1);  % Filter input buffer

% Output and Error Signal
y = zeros(L,1);
e = zeros(L,1);

for n = 1:L
    % Shift buffer
    x = [simulated_noise(n); x(1:end-1)];
    
    % ANC output
    y(n) = W' * x;
    
    % Error signal (Assuming reference mic receives only noise)
    e(n) = simulated_noise(n) - y(n);
    
    % Update Filter Coefficients using FxLMS
    W = W + mu * e(n) * x;
end

% Play and Save Processed Audio
sound(e, Fs);
audiowrite('processed_noise.wav', e, Fs);

% Plot Results
figure;
subplot(3,1,1); plot(noise); title('Original Noise');
subplot(3,1,2); plot(simulated_noise); title('Anti Noise');
subplot(3,1,3); plot(e); title('Noise After ANC Processing');

% Plot the positions of the sources and sensors
scatter3(primary_source_pos(1), primary_source_pos(2), primary_source_pos(3), 'ro');
scatter3(secondary_source_pos(1), secondary_source_pos(2), secondary_source_pos(3), 'bo');
scatter3(error_sensor_pos(1), error_sensor_pos(2), error_sensor_pos(3), 'go');
