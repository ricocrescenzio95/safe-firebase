# Welcome to safe-firebase contribution

Thank you for investing your time in contributing to our project!

## Issues

### Create a new issue

Open an [issue](https://github.com/ricocrescenzio95/safe-firebase/issues/new?assignees=ricocrescenzio95&labels=enhancement&template=feature_request.md&title=%5BNEW%5D) or a [bug](https://github.com/ricocrescenzio95/safe-firebase/issues/new?assignees=ricocrescenzio95&labels=bug&template=bug_report.md&title=%5BBUG%5D).

### Solve an issue

Create a branch from an existing issue (or first create an issue) and work on it!

Just few things:

- Try to follow Swift code-style, indent 4 spaces and 120 char per line
- Use documentation comments as much as you can. Update DocC documentation as well.
- Keep typed Firestore APIs and generated schemas covered by tests.

## Firestore Emulator Tests

The Firestore emulator tests require the following tools to be installed locally:

- Xcode with Swift Package Manager support for this package.
- Node.js and npm.
- The Firebase CLI (`firebase-tools`), installed globally with `npm install --global firebase-tools`.
- Java, required by the Firestore emulator.

The shared `safe-firebase` Xcode scheme starts the Firestore emulator before tests and stops it afterward. Open the package in Xcode, select the `safe-firebase` scheme, and run **Product > Test**. The pre-action and post-action are stored in the repository, so contributors do not need to configure them locally. The scripts use the repository's `firebase.json`, start only the Firestore emulator on port `8080`, and store its PID and output under `/tmp`.

To run the suite from Terminal instead of Xcode, install the same prerequisites, then start the emulator from the repository root:

```bash
firebase emulators:start --only firestore --project demo-safe-firebase
```

Leave that process running in one terminal and run `swift test` from the repository root in another. Stop the emulator with `Ctrl-C` when finished.


## Pull Request

Open a PR and describe your solution, any hidden implementation or workaround (if any).
Don't forget to link the PR to the issue (Github should help you). Assign [me](https://github.com/ricocrescenzio95) as
reviewer and we'll discuss about your solution.

## Your PR is merged!

Congratulations :tada::tada: The solution looks good and we can merge it :sparkles:.
