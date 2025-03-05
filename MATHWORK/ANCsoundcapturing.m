clc;
clear;
close all;

% ✅ Step 1: Set Up Audio Devices
Fs = 44100; % Sampling frequency
frameSize = 1024; % Frame size for processing
mic = audioDeviceReader('SampleRate', Fs, 'SamplesPerFrame', frameSize);  
speaker = audioDeviceWriter('SampleRate', Fs);

% ✅ Step 2: LMS Filter Parameters
filterLength = 64; % Filter length (Increase for better noise removal)
stepSize = 0.01; % Adaptive step size (Reduce if unstable)
lmsWeights = zeros(filterLength, 1); % Initialize LMS filter weights

disp('🔊 ANC Running... Press Ctrl+C to stop.');

% ✅ Step 3: ANC Processing Loop
while true
    % 🎤 Read microphone input (contains both noise & speech)
    noiseInput = mic();

    % Ensure reference noise has correct dimensions
    if length(noiseInput) < filterLength
        continue;
    end

    % 📢 Reference noise (previous noisy input as reference)
    referenceNoise = noiseInput(1:filterLength); 
    referenceNoise = referenceNoise(:); % Convert to column vector

    % 🏎 LMS Adaptive Filtering
    estimatedNoise = lmsWeights' * referenceNoise; % Filter output
    errorSignal = noiseInput - estimatedNoise; % Error signal (clean output)

    % 🎯 LMS Weight Update Rule
    lmsWeights = lmsWeights + stepSize * referenceNoise * errorSignal(1);

    % 🎧 Send the cleaned output to the speaker
    speaker(errorSignal);
end

% ✅ Step 4: Release Resources When Stopped
release(mic);
release(speaker);
