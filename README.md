# planet-kit-flutter
LINE Planet is a cloud-based real-time communications platform as a service (CPaaS) that helps you build a voice and video call environment. With LINE Planet, you can integrate call features into your service at minimum cost.

## Planet Documentation
[LINE Planet Documentation](https://docs.lineplanet.me/) provides additional resources to help you integrate LINE Planet into your service. These resources include LINE Planet specifications, developer guides for each client platform, and server API references.

## Installation

### Requirement
* iOS 12.0 or later
* Android targetSDKVersion 31 or higher

### Add the package

1. In `pubspec.yaml`, add the following lines. Replace `{PLANET_KIT_VERSION}` with the desired PlanetKit-Flutter version (e.g., v0.6.0).

    ```
    dependencies:
      flutter:
        sdk: flutter
 
      planet_kit_flutter:
        git:
          url: git@github.com:line/planet-kit-flutter.git
          ref: {PLANET_KIT_VERSION}
    ```

2. Import `planet_kit_flutter` to application source code.

    ```
    import 'package:planet_kit_flutter/planet_kit_flutter.dart'; 
    ```


## Issues and Inquiries
Please file any issues or inquiries you have to our representative or dl_planet_help@linecorp.com.
Your opinions are always welcome.

## FAQ
You can find answers to our frequently asked questions in the [FAQ](https://docs.lineplanet.me/help/faq/) section.
