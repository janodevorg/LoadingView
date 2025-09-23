import ProjectDescription

nonisolated(unsafe) let project = Project(
    name: "Demo",
    packages: [
        .package(path: "..")
    ],
    settings: .settings(base: [
        "SWIFT_VERSION": "6.2",
        "IPHONEOS_DEPLOYMENT_TARGET": "26.0",
        "MACOSX_DEPLOYMENT_TARGET": "26.0"
    ]),
    targets: [
        .target(
            name: "Demo-iOS",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.jano.apple.loadingview.demo",
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [
                    "UIColorName": "AccentColor",
                    "UIImageName": ""
                ]
            ]),
            sources: ["Sources/SwiftUI/**"],
            resources: ["Sources/Resources/**"],
            scripts: [
                swiftlintScript()
            ],
            dependencies: [
                .package(product: "LoadingView"),
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "CODE_SIGN_IDENTITY": "Apple Development",
                    "DEVELOPMENT_TEAM": "23KN7M4FPW",
                    "PROVISIONING_PROFILE_SPECIFIER": ""
                ]
            )
        ),

        .target(
            name: "Demo-MacOS",
            destinations: .macOS,
            product: .app,
            bundleId: "dev.jano.apple.loadingview.demo",
            sources: ["Sources/SwiftUI/**"],
            resources: ["Sources/Resources/**"],
            scripts: [
                swiftlintScript()
            ],
            dependencies: [
                .package(product: "LoadingView"),
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "CODE_SIGN_IDENTITY": "Apple Development",
                    "DEVELOPMENT_TEAM": "23KN7M4FPW",
                    "PROVISIONING_PROFILE_SPECIFIER": ""
                ]
            )
        ),
        .target(
            name: "Demo-MacOS-Tests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "dev.jano.apple.loadingview.demo.tests",
            infoPlist: .default,
            sources: ["Tests/**"],
            resources: [],
            scripts: [
                swiftlintScript()
            ],
            dependencies: [
                .target(name: "Demo-MacOS")
            ]
        ),
        .target(
            name: "Demo-iOS-UITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "dev.jano.apple.loadingview.demo.uitests",
            sources: ["UITests/**"],
            dependencies: [
                .target(name: "Demo-iOS")
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "CODE_SIGN_IDENTITY": "Apple Development",
                    "DEVELOPMENT_TEAM": "23KN7M4FPW",
                    "PROVISIONING_PROFILE_SPECIFIER": ""
                ]
            )
        ),
        .target(
            name: "Demo-MacOS-UITests",
            destinations: .macOS,
            product: .uiTests,
            bundleId: "dev.jano.apple.loadingview.demo.uitests",
            sources: ["UITests/**"],
            dependencies: [
                .target(name: "Demo-MacOS")
            ],
            settings: .settings(
                base: [
                    "CODE_SIGN_STYLE": "Automatic",
                    "CODE_SIGN_IDENTITY": "Apple Development",
                    "DEVELOPMENT_TEAM": "23KN7M4FPW",
                    "PROVISIONING_PROFILE_SPECIFIER": ""
                ]
            )
        ),
    ],
    schemes: [
        Scheme.scheme(
            name: "Demo-iOS",
            shared: true,
            buildAction: BuildAction.buildAction(
                targets: [TargetReference.target("Demo-iOS")]
            ),
            testAction: .testPlans(
                [Path.path("Demo-iOS.xctestplan")],
                configuration: .debug,
                attachDebugger: true
            ),
            runAction: RunAction.runAction(
                configuration: .debug,
                executable: TargetReference.target("Demo-iOS")
            )
        ),
        Scheme.scheme(
            name: "Demo-MacOS",
            shared: true,
            buildAction: BuildAction.buildAction(
                targets: [TargetReference.target("Demo-MacOS")]
            ),
            testAction: .testPlans(
                [Path.path("Demo-MacOS.xctestplan")],
                configuration: .debug,
                attachDebugger: true
            ),
            runAction: RunAction.runAction(
                configuration: .debug,
                executable: TargetReference.target("Demo-MacOS")
            )
        )
    ],
    additionalFiles: [
        "Project.swift",
        ".swiftlint.yml",
        "Demo-iOS.xctestplan",
        "Demo-MacOS.xctestplan"
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
