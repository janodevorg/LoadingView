import ProjectDescription

let project = Project(
    name: "LoadingView",
    packages: [
        .package(url: "git@github.com:SimplyDanny/SwiftLintPlugins.git", from: "0.58.2")
    ],
    settings: .settings(base: [
        "SWIFT_VERSION": "6.0",
        "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
        "MACOSX_DEPLOYMENT_TARGET": "26.0",
        "ENABLE_MODULE_VERIFIER": "YES"
    ]),
    targets: [
        .target(
            name: "LoadingView",
            destinations: [.iPhone, .mac],
            product: .framework,
            bundleId: "dev.jano.loadingview",
            sources: ["Sources/Main/**"],
            scripts: [
                swiftlintScript()
            ]
        ),
        .target(
            name: "LoadingViewTests",
            destinations: [.iPhone, .mac],
            product: .unitTests,
            bundleId: "dev.jano.loadingview.test",
            sources: ["Sources/Tests/**"],
            resources: [
            ],
            dependencies: [
            ],
            additionalFiles: [
                "Package.swift",
                "Project.swift"
            ]
        )
    ],
    schemes: [
       Scheme.scheme(
           name: "LoadingView",
           shared: true,
           buildAction: BuildAction.buildAction(
               targets: [TargetReference.target("LoadingView")]
           ),
           testAction: .testPlans(
               [Path.path("LoadingView.xctestplan")],
               configuration: .debug,
               attachDebugger: true
           )
       )
    ]
)

func swiftlintScript() -> ProjectDescription.TargetScript {
    let script = """
    #!/bin/sh

    # Check swiftlint
    command -v /opt/homebrew/bin/swiftlint >/dev/null 2>&1 || { echo >&2 "swiftlint not found at /opt/homebrew/bin/swiftlint. Aborting."; exit 1; }

    # Create a temp file
    temp_file=$(mktemp)

    # Gather all modified and stopiced files within the Sources directory
    git ls-files -m Sources | grep ".swift$" > "${temp_file}"
    git diff --name-only --cached Sources | grep ".swift$" >> "${temp_file}"

    # Make list of unique and sorterd files
    counter=0
    for f in $(sort "${temp_file}" | uniq)
    do
        eval "export SCRIPT_INPUT_FILE_$counter=$f"
        counter=$(expr $counter + 1)
    done

    # Lint
    if [ $counter -gt 0 ]; then
        export SCRIPT_INPUT_FILE_COUNT=${counter}
        /opt/homebrew/bin/swiftlint autocorrect --use-script-input-files
    fi
    """
    return .post(script: script, name: "Swiftlint", basedOnDependencyAnalysis: false, runForInstallBuildsOnly: false, shellPath: "/bin/zsh")
}
