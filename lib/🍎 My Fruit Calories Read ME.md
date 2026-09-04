# 🍎 My Fruit Calories

**My Fruit Calories** is a Flutter mobile application that uses an AI-based fruit recognition system to identify fruits from images and provide calorie/nutritional information.

The Flutter application communicates with a **FastAPI AI server running on Google Colab**, which is exposed to the internet using **ngrok**.

---

# 🚀 How to Run the Project

## Requirements

Before running the project, install the following:

- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Android SDK
- Google Chrome
- Python / Google Colab account
- An Android device or Android Emulator
- Internet connection

Check your Flutter installation:

```bash
flutter doctor
```

---

# 1. Download the Flutter Project

Clone this repository:

```bash
git clone https://github.com/umarrkhan7/Calories_Tracker
```

Navigate to the project:

```bash
cd YOUR_PROJECT_FOLDER
```

Install Flutter dependencies:

```bash
flutter pub get
```

---

# 2. AI Server Setup

The AI model is not hosted directly inside the Flutter application.

The AI backend runs using:

```text
Google Colab
      ↓
FastAPI
      ↓
AI Model
      ↓
ngrok
      ↓
Flutter Application
```

You need to start the AI server **before running the fruit recognition feature**.

---

# 3. Download the AI Model Files

The trained AI model files are hosted separately because they are not included in this GitHub repository.

Download the model files from the following Google Drive folder:

**[Download AI Model Files] https://drive.google.com/drive/folders/1Do3XUI00PVwRqU_0WlVq9QZywrlcWkbG?usp=drive_link**

Download all required files.

The model files should include the files required by the FastAPI server, such as:

```text
best_model.pt
class_names.json
yolo_best.pt
yolov8s-seg.pt
```

> The exact files required depend on the AI server code provided below.

Keep the downloaded files available because they will be uploaded to Google Colab.

---

# 4. Open Google Colab

Open:

https://colab.research.google.com/

Create a new notebook.

You do **not** need to upload the complete project to Google Colab.

Instead, copy and paste the following cells into Google Colab **one cell at a time and run them in the given order**.

> ⚠️ **Important:** Do not combine the cells unless you know what you are doing. Run each cell separately in the order provided below.

---

# 5. Google Colab Setup

# Cell 1 — Mount Google Drive
from google.colab import drive
drive.mount('/content/drive')
print('Google Drive mounted!')

Run the cell.

Wait until the installation finishes before continuing.

---

# Cell 2 — Copy required files from Drive to /content
import shutil
import os

DRIVE_FOLDER = '/content/drive/MyDrive/MultiFruit'
DEST_FOLDER  = '/content'

files_needed = [
    'api_server1.py',
    'best_model.pt',
    'class_names.json',
    'yolo_best.pt',
    'yolov8s-seg.pt',
]

print('Copying files from Google Drive...')
all_ok = True

for filename in files_needed:
    src  = os.path.join(DRIVE_FOLDER, filename)
    dest = os.path.join(DEST_FOLDER,  filename)

    if os.path.exists(src):
        shutil.copy(src, dest)
        size_mb = os.path.getsize(dest) / (1024*1024)
        print(f'  {filename} ({size_mb:.1f} MB)')
    else:
        print(f'  NOT FOUND: {filename}')
        print(f'     Expected at: {src}')
        all_ok = False

print()
if all_ok:
    print('All files copied successfully! Proceed to Cell 3.')
else:
    print('Some files missing! Check your FruitRecognition folder in Drive.')

Run the cell.

---

# Cell 3 — Install packages
# torch/torchvision are usually pre-installed on Colab runtimes, so this
# is often near-instant. ultralytics + opencv are needed for the new
# multi-fruit YOLO localizer.
print('Installing packages...')

!pip install -q fastapi uvicorn python-multipart pyngrok
!pip install -q torch torchvision pillow
!pip install -q ultralytics opencv-python-headless

print('\nAll packages installed! Proceed to Cell 4.')

Run the cell.

# Cell 4 — Start the server + open ngrok tunnel
import subprocess
import time
import os
from pyngrok import ngrok

# Paste your ngrok authtoken here (get one at dashboard.ngrok.com)
NGROK_TOKEN = ''   

os.chdir('/content')
subprocess.run(['fuser', '-k', '8000/tcp'], capture_output=True)
subprocess.run(['pkill', '-f', 'uvicorn'], capture_output=True)
ngrok.kill()
time.sleep(3)
print('✅ Cleared port 8000')

process = subprocess.Popen(
    ['uvicorn', 'api_server1:app', '--host', '0.0.0.0', '--port', '8000'],
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE,
    text=True
)

print('⏳ Waiting for model to load (up to 2 mins)...')
started = False
for i in range(120):
    time.sleep(1)
    print(f'  {i+1}s...', end='\r')
    if process.poll() is not None:
        out, err = process.communicate()
        print('\n❌ Server crashed!')
        print(err[-2000:])
        break

    try:
        import select
        if select.select([process.stderr], [], [], 0.1)[0]:
            line = process.stderr.readline()
            if line.strip():
                print(f'\n  LOG: {line.strip()}')
            if 'Application startup complete' in line:
                started = True
                break
    except Exception:
        pass

print()

if started:
    ngrok.set_auth_token(NGROK_TOKEN)
    public_url = ngrok.connect(8000)
    url_str = str(public_url).replace('NgrokTunnel: ', '').split(' ')[0].strip('"')
    print('='*55)
    print('✅ SERVER IS LIVE!')
    print(f'🌍 URL: {url_str}')
    print(f'\n📱 Copy to Flutter:')
    print(f'const String kServerUrl = "{url_str}";')
    print('='*55)
else:
    print('⚠ Timeout reached — trying to connect anyway...')
    try:
        import requests
        r = requests.get('http://localhost:8000/health', timeout=5)
        if r.status_code == 200:
            print('✅ Server IS running!')
            ngrok.set_auth_token(NGROK_TOKEN)
            public_url = ngrok.connect(8000)
            url_str = str(public_url).replace('NgrokTunnel: ', '').split(' ')[0].strip('"')
            print(f'🌍 URL: {url_str}')
            print(f'const String kServerUrl = "{url_str}";')
    except Exception:
        print('❌ Server truly not running')
        print('Try Runtime → Restart session and run all')

# Cell 5 — Health check
import requests

try:
    response = requests.get('http://localhost:8000/health', timeout=5)
    if response.status_code == 200:
        print('✅ Server health check passed!')
        print(f'   Response: {response.json()}')
    else:
        print(f'⚠ Server returned status: {response.status_code}')
except Exception as e:
    print(f'❌ Server not responding: {e}')

# Cell 6 — Keep-alive loop
# NOTE: this only keeps the local loop busy and pings the server; it does
# NOT prevent Colab from disconnecting the runtime after ~90 min of
# browser/tab inactivity, or after the ~12 hr hard session cap. It's
# useful while you're actively testing, not for real production uptime.
import requests
import time

print('🔄 Keep-alive started. Server will stay active while this cell runs.')
print('   Press STOP to end this cell when done testing.')
print()

count = 0
while True:
    try:
        response = requests.get('http://localhost:8000/health', timeout=5)
        count += 1
        print(f'  ✅ Ping #{count} — Server alive! ({time.strftime("%H:%M:%S")})')
    except Exception:
        print(f'  ❌ Server not responding at {time.strftime("%H:%M:%S")}')

    time.sleep(300)


After successful execution, you should receive a public URL similar to:

```text
https://xxxxxxxx.ngrok-free.app
```

Copy this URL.

---

# 8. Update the Flutter API URL

Go to Lib->config->Api config
For example:

```dart
class ApiConstants {
  static const String baseUrl = "YOUR_NGROK_URL";
}
```

Replace the existing URL with your newly generated ngrok URL:

```dart
class ApiConstants {
  static const String baseUrl = "https://xxxxxxxx.ngrok-free.app";
}
```

> Do not add an extra `/` at the end unless the application specifically requires it.

---

# 9. Run the Flutter Application

Make sure your Android device is connected or an Android Emulator is running.

Check connected devices:

```bash
flutter devices
```

Then run:

```bash
flutter run
```

You can also run the application directly from Android Studio or VS Code.

---

# 🔄 Complete Workflow

The complete setup should look like this:

```text
                 ┌─────────────────────┐
                 │   Flutter App       │
                 │   Android Device    │
                 └──────────┬──────────┘
                            │
                            │ HTTP Request
                            ▼
                    ┌───────────────┐
                    │     ngrok     │
                    │ Public URL    │
                    └───────┬───────┘
                            │
                            ▼
                 ┌─────────────────────┐
                 │    Google Colab     │
                 │                     │
                 │     FastAPI         │
                 │        ↓            │
                 │     AI Model        │
                 └─────────────────────┘
```

---

# ⚠️ Important Notes

### Google Colab Must Stay Running

The AI recognition functionality will only work while the Google Colab session and FastAPI server are running.

If the Colab runtime disconnects, the AI server will stop.

---

### Internet Connection Required

The Flutter application needs an active internet connection to communicate with the AI server running on Google Colab.

---

# 🛠️ Troubleshooting

## `flutter pub get` fails

Try:

```bash
flutter clean
flutter pub get
```

Then:

```bash
flutter run
```

---

## AI Recognition Does Not Work

Check that:

- Google Colab is running.
- All required Colab cells were executed.
- FastAPI is running.
- ngrok is running.
- The ngrok URL is correct.
- The Flutter `baseUrl` contains the current ngrok URL.
- The Android device has an internet connection.
- The required model files were uploaded correctly.

---

## API Connection Error

If the Flutter application cannot connect to the AI server:

1. Check that the Colab server is still running.
2. Check that ngrok is still running.
3. Copy the current ngrok URL.
4. Update the Flutter `baseUrl`.
5. Restart the Flutter application.

---

# 📦 Build APK

To create a release APK:

```bash
flutter build apk --release
```

The generated APK will be located at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---
