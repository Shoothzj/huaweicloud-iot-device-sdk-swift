# huaweicloud-iot-device-sdk-swift

## Usage

### add dependency

#### through git & commit id

```swift
let package = Package(
        name: "YourProject",
        platforms: [
            .iOS(.v13),
            .macOS(.v13),
            .tvOS(.v13),
        ],
        dependencies: [
            .package(url: "https://github.com/your-username/your-package-name.git", .revision("latest commitId")),
        ],
        targets: [
            .target(
                    name: "YourProject",
                    dependencies: ["HuaweiCloudIoTDevice"]),
        ]
)
```
