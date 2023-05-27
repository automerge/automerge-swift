# Release Process

Release process:

Check out the latest code, or at the mark you want to release.
While the CI system is solid, it's worthwhile to do a fresh repository clone, run a full build, and all the relevant tests before proceeding.

This process adds a tag into the GitHub repository, but not until we've made a commit that explicitly sets up the downloadable packages from GitHub release artifacts.

Steps:

- Note the version you are intending to release.
The version's tag number gets used in a number of places through this process.
This example uses the version `0.1.0`.

- Run `./scripts/build-xcframework.sh` to build the XCFramework.
Doing this regenerates the Swift wrappers from UniFFI, so the low-level wrapper swift needs to be aligned with the XCFramework that this script generates.

- Capture the build hash (sha256) of the XCFramework that the script prints out at the end of it's process.
It will look something like:

```
SHA256(/Users/heckj/src/automerge-swift/automergeFFI.xcframework.zip)= 201a464b1585c0b424a1100f506c12368b3e7473afe5907befc95468147f482d```

The part that you need to capture and save from the above example is:

```
201a464b1585c0b424a1100f506c12368b3e7473afe5907befc95468147f482d
```

## Update Package.swift

- Switch the binary target in Package.swift for automergeFFI to an updated url and checksum reference.

- Set the url to the download path for a release artifact from a GitHub release.
The version that you are releasing is embedded in this URL - `0.1.0` in this case.
The pattern is roughly:

```
https://github.com/automerge/automerge-swift/releases/download/0.10/automergeFFI.xcframework.zip
```

The end result of that section of Package.swift should look something like:

```
FFIbinaryTarget = .binaryTarget(
        name: "automergeFFI",
        url: "https://github.com/automerge/automerge-swift/releases/download/0.1.0/automergeFFI.xcframework.zip",
        checksum: "201a464b1585c0b424a1100f506c12368b3e7473afe5907befc95468147f482d"
)
```

- Set the checksum to the one you just captured for the build of the XCFramework.

(Note: at this stage, a local build will not work - as we haven't created the release yet on GitHub with its artifacts)

- Commit the changes to Package.swift.
- Tag the release after the commit, to set a point that we can build a release from.
Set the tag to a semantic version that Package.swift supports.
(Note: GitHub suggests tags like `v0.1.0`, but Swift packages have a rough time with the preceeding `v` in the semantic coding, so I recommend using a bare tag, and suffixing if `-beta` or such if you're making a beta release.)

```
git tag 0.1.0
git push origin --tags
```

- Open a browser and navigate to the URL that you can use to create a release on GitHub.
  - https://github.com/automerge/automerge-swift/releases/new
  - choose the existing tag (`0.1.0` in this example)

![GitHub release page with tag selected, but otherwise empty.](./github_release_empty.png)

  - Add a release title
  - Add in a description for the release
  - Drag the file `automergeFFI.xcframework.zip` from the repository directory onto the github page to attach the binary.
  - Wait for the upload to complete and verify the file is listed.
  - Select the checkout for a pre-release if relevant.

![GitHub release page with tag selected, details filled, and binary uploaded.](./github_release_ready.png)

(NOTE: the title and description details can be editing later without impact, but it is critically important to get the binary with the tag set as you expect - and that isn't editable if you miss it.)

- click `Publish release`

![GitHub release page after creation.](./github_release_ready.png)

## Oops, I made a mistake - what do I do?

If something in the process goes awry, don't worry - that happens.
_Do not_ attempt to delete or move any tsgs that you've made.
Instead, just move on to the next semantic version and call it a day.
For example, when I was testing this process, I learned about the unsafe flags constraint at the last minute.
To resolve this, I repeated the process with the next tag `0.1.1` even though it didn't have any meaningful changes in the code.

## Future Directions

This can likely be completed as an automated workflow using GitHub actions.
The replacements can be managed to a single input value of the tag, updating the relevant files, creating the XCFramework as a build artifact, and publishing a release with GitHub hosting the XCFramework.
