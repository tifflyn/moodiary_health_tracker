# Moodiary: An Health Tracker Application

## An Airost Intern Project, an app for mental health support, developed by Group ABC
## Project description
With the rise of remote work and digital lifestyles, many people are experiencing increased levels of stress, anxiety, and emotional fatigue. 
Many people are finding ways to cope this problem, however there are many problems arises when they are finding emotional support.
Problem 1: Struggle to find convenient and reliable ways to manage their mental health 
Problem 2: Expensive, Time-Consuming, and Hard-to-Access Traditional Support  
Therefore, our group decided to create an mobile application to solve problems regarding emotions.

### Solution (Main Function of the Applicaiton)
Display emotions of the week 
AI chatbot trained with therapist-style communication
Provide personalized “Love for the World” recommendations 
Proactive AI Check-ins with Mood Logging

## Setup instructions
### Environment Setup
1) Install Prerequisites:
- Download and install the Flutter SDK and Git from the official website.
- Extract the SDK and add it to your system's PATH.

2) Configure Development Environment:
- Run flutter doctor to verify the setup.
- Install Android Studio and set up an Android emulator.
- Install the Flutter extension in Visual Studio Code.

### Application Development
With the environment ready, we began developing the mobile application.
1) Core Interface:
- Created a user dashboard as the main post-login screen, featuring cards for daily energy levels, a to-do list, and an editable daily log.
- Implemented a bottom navigation bar for easy access to the app's primary sections: Diary, Self-Care, and Profile.

2) Backend & Authentication:
- Integrated Firebase to handle user authentication via Gmail and to securely store user data and diary entries.

### Backend & AI Integration
#### Firebase Setup
1) Create a new project in the Firebase Console.
2) Register your Android app within the project and download the google-services.json configuration file.
3) Add this file to your Flutter project (android/app/), include the necessary Firebase dependencies in pubspec.yaml, and update the Android build files.
4) Initialize the Firebase SDK within the Flutter application code.

#### Gemini AI API Integration
1) Obtain API Key: Generate a free API key from Google AI Studio.
2) Secure Configuration: Store the API key securely using environment variables (e.g., a .env file) and ensure it is added to .gitignore.
3) Flutter Implementation:
- Add the required dependencies to pubspec.yaml.
- Create a dedicated service (ai_service.dart) to manage API calls.
- Build the chat interface (ai_chatbot_screen.dart) and manage state using the Provider pattern.

## Execution / Run
Step 1: Verify Setup
- Run flutter doctor in your terminal and resolve any issues it identifies. Proceed only when all checks pass.

Step 2: Launch the Emulator
- Open Android Studio.
- Navigate to More Actions → Virtual Device Manager.
- Click '+' (Create Virtual Device).
- Select Pixel 8 and proceed.
- Name the device Pixel_8_API_34 and choose API Level 34.
- Click Finish, then press Start to launch the emulator.
- VS Code will automatically detect and connect to the running emulator.

Step 3: Run the App
In VS Code, open the Moodiary project folder and run the following command.

<img width="297" height="82" alt="flutter_run_command" src="https://github.com/user-attachments/assets/17eba9fe-5130-47af-a84a-f293bfa44867" />



