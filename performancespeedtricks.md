Key Strategies for Faster App Launch
Defer Third-Party SDKs: Initialize analytics, crash reporting, and ads after the first screen renders (e.g., in didFinishLaunchingWithOptions using DispatchQueue.main.asyncAfter).
Lazy Loading: Use lazy var or lazy initialization for services (databases, networking) that are not needed immediately upon startup.
Optimize didFinishLaunching: Only perform critical tasks to show the first screen. Move setup work to a background thread (DispatchQueue.global(qos: .userInitiated).async).
Reduce Frameworks: Audit Podfile or Swift Package Manager dependencies; fewer libraries mean faster dyld load times.
Use os_signpost: Track app startup stages using os_signpost to identify specific bottlenecks in Instruments.
Minimize Static Initializers: Reduce complex Swift static initializers, as they run on the main thread before main().
Use Order Files: Optimize the order of functions in the binary to reduce page faults and memory overhead during startup

https://developer.apple.com/documentation/UIKit/UIApplicationDelegate/application(_:didFinishLaunchingWithOptions:)

nstance Method
application(_:didFinishLaunchingWithOptions:)
Tells the delegate that the launch process is almost done and the app is almost ready to run.
iOS 3.0+
iPadOS 3.0+
Mac Catalyst 13.1+
tvOS
visionOS 1.0+
optional func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
) -> Bool
Parameters
application
The singleton app object.

launchOptions
A dictionary indicating the reason the person or system launched the app. The contents of this dictionary may be empty in situations where a person launched the app directly. If the app supports scenes, this is nil. For information about the possible keys in this dictionary and how to handle them, see UIApplication.LaunchOptionsKey.

Return Value
Return false if the app can’t handle the URL resource or continue a user activity, otherwise return true. The system ignores the return value if the app launches as a result of a remote notification.

https://developer.apple.com/documentation/uikit/about-the-app-launch-sequence




https://medium.com/better-programming/checking-for-the-users-first-launch-in-swift-df02a1feb472

https://developer.apple.com/documentation/uikit/performing-one-time-setup-for-your-app


When I say cube, I am refering to the cube and rectangle options. 