import numpy as np
import sounddevice as sd
import time
import threading

fs = 44100  # Sample rate
duration = 15  # Total duration
delay = 3  # Delay before anti-sine starts
frequency = 440  # Frequency of sine wave

t_sine = np.linspace(0, duration, int(fs * duration), endpoint=False, dtype=np.float32)
sine_wave = np.sin(2 * np.pi * frequency * t_sine).astype(np.float32 ) # Convert to float32
delay_samples = int(fs * delay)
t_anti = t_sine[delay_samples:]  # Keep the correct time scale
anti_sine_wave = -sine_wave[delay_samples:]  # Correct phase inversion


device1 =  11 # Speakers (AB13X USB Audio)
device2 = 8 # Headphones 2 (Realtek HD Audio)

# Normalize and ensure float32 conversion
sine_wave /= np.max(np.abs(sine_wave))
anti_sine_wave /= np.max(np.abs(anti_sine_wave))

# Function to play sound in a separate thread
def play_sound(data, device_id):
    with sd.OutputStream(device=device_id, samplerate=fs, channels=1, dtype='float32') as stream:
        stream.write(data)

# Start playing sine wave immediately in a separate thread
sine_thread = threading.Thread(target=play_sound, args=(sine_wave, device1))
sine_thread.start()

# Wait for 10 seconds before starting anti-sine wave
time.sleep(delay)

# Start playing anti-sine wave on a separate thread
anti_sine_thread = threading.Thread(target=play_sound, args=(anti_sine_wave, device2))
anti_sine_thread.start()

# Wait until both threads finish
sine_thread.join()
anti_sine_thread.join()

print("Playback complete!")
