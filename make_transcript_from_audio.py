import speech_recognition as sr

# Load the audio file
audio_file_path = "/Users/randall.white/Downloads/Sherlock_on-boarding.mp3"

# Initialize the recognizer
recognizer = sr.Recognizer()

# Convert the audio file to audio data
with sr.AudioFile(audio_file_path) as source:
    audio_data = recognizer.record(source)

# Recognize (convert from speech to text)
transcript = recognizer.recognize_google(audio_data)

# Print the transcript
print(transcript)