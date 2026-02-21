we are making an iOS app that uses front facing camera to track splat videos and make a 3D depth affect inside the phone screen that moves when you tilt your head. 

Other projects:
https://github.com/ryrotella/decorate_3D_portal https://danielhabib.substack.com/p/a-simpler-way-to-watch-3d https://www.splats.com/ https://www.npmjs.com/package/spatial-player https://danielhabib.substack.com/p/a-simpler-way-to-watch-3d 



I am making an iOS app that does the same thing as these apps. I want to be able to play the splat videos on my phone, Use the built in forward facing camera for head tracking. 

- Default view with the 3D depth affect on all sides of the phone. 
- secondary view to browse and view videos from https://www.splats.com/ - save them to the device, and view in realtime and move with the camera head tracking. 
- allow users to put photos and videos from their photo library into the 5 sides of the internal cube, playback, screen recording. realtime performance, 

- allow for head tracking/eye tracking calibration/reset with a button to improve outcome.

- moving your head/phone around makes the cube/splat move in the same way. Look at the code from the other projects to understand. 



3 "views" - splat player: shows a instagram like "feed" of videos from splats.com, the feed displays images of the videos until the user taps on a video then it plays and when the player tilts their head the 3D video tilts accordingly. 



Camera Permissions: Because you are using the forward-facing camera for head tracking, you will need to add the NSCameraUsageDescription key to your Info.plist. A simple string like "SplatFrame needs camera access to track your head movement and create the 3D window effect" will keep Apple reviewers happy.

ARKit/Face Tracking: You will likely be relying on ARKit's ARFaceTrackingConfiguration to get the relative position of the user's eyes/head to the device screen. Ensure you import ARKit and check for device support early in your app lifecycle.