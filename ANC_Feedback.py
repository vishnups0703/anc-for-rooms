import sounddevice as sd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation

# **Find Device Indexes**
reference_mic_index = 5    # Update based on your system
antinoise_speaker_index = 9
error_mic_index = 1

# **Audio Parameters**
fs = 44100  # Sampling rate
blocksize = 450  # Block size
duration = 10  # Duration in seconds

# **Adaptive Filter Parameters**
mu = 0.001 # Learning rate
filter_order = 52  # Number of filter taps
w = np.zeros(filter_order)  # Adaptive filter weights

# **Initialize Buffers**
reference_buffer = np.zeros(blocksize)
antinoise_buffer = np.zeros(blocksize)
error_buffer = np.zeros(blocksize)

# **Setup Matplotlib for Real-Time Plotting**
plt.ion()
fig, axs = plt.subplots(3, 1, figsize=(10, 6))
lines = [ax.plot(np.zeros(blocksize))[0] for ax in axs]
titles = ["Reference Signal (Captured Noise)", "Anti-Noise Signal (Generated)", "Error Signal (Residual Noise)"]
for ax, title in zip(axs, titles):
    ax.set_title(title)
    ax.set_ylim(-2, 2)

# **ANC Callback Function**
def anc_callback(indata, outdata, frames, time, status):
    global w, reference_buffer, antinoise_buffer, error_buffer

    if status:
        print(status)

    # **Extract Audio Signals**
    reference_signal = indata[:, 0]  # Reference mic
    error_signal = indata[:, 1]  # Error mic

    # **Generate Anti-Noise Using Adaptive Filter**
    anti_noise = np.convolve(reference_signal, w, mode="same")
    e = error_signal - anti_noise  # Residual noise

    # **LMS Adaptive Filter Update (Optimized)**
    w += mu * e[:filter_order] * reference_signal[:filter_order]

    # **Output Anti-Noise Signal**
    outdata[:, 0] = -anti_noise  

    # **Update Buffers for Plot**
    reference_buffer[:] = reference_signal
    antinoise_buffer[:] = anti_noise
    error_buffer[:] = e

# **Matplotlib Animation Update Function**
def update_plot(frame):
    lines[0].set_ydata(reference_buffer)
    lines[1].set_ydata(antinoise_buffer)
    lines[2].set_ydata(error_buffer)
    return lines

# **Start Real-Time Animation**
ani = animation.FuncAnimation(fig, update_plot, interval=50, blit=True)

# **Run Audio Stream**
with sd.Stream(
    callback=anc_callback,
    samplerate=fs,
    channels=2,
    blocksize=blocksize,
    device=(reference_mic_index, antinoise_speaker_index),
    latency="low"
):
    print("Running ANC... Press Ctrl+C to stop.")
    plt.show(block=True)
