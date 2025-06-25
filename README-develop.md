# FitnessAppVaso (Develop Branch)

This is the `develop` branch of the FitnessAppVaso project. This branch is used for ongoing development, feature integration, and testing before merging into `master`.

## 🚧 What is in `develop`?
- Latest features and bug fixes under active development
- Experimental changes and new ideas
- May be unstable or incomplete at times

## 🛠️ How to Use
1. **Clone the repository:**
   ```sh
   git clone <repo-url>
   cd fitnessapp
   git checkout develop
   ```
2. **Install dependencies:**
   ```sh
   flutter pub get
   ```
3. **Run the app:**
   ```sh
   flutter run
   ```
   For web:
   ```sh
   flutter run -d chrome
   ```

## 🧪 Testing
Run all tests with:
```sh
flutter test
```

## 🔀 Workflow
- All new features and bugfixes should be merged into `develop` first.
- When `develop` is stable, changes are merged into `master` for release.

## 📄 Documentation
- See the main [`README.md`](./README.md) for full project details, features, and usage.
- This file documents only the workflow and expectations for the `develop` branch.

## 🤝 Contributing
- Please branch from `develop` for new features or fixes.
- Open pull requests against `develop`.
- Follow code style and commit message guidelines.

## ⚠️ Disclaimer
The `develop` branch may contain unfinished or experimental code. For production use, always use the `master` branch.
