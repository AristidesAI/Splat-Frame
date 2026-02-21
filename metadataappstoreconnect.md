# Splat Frame — App Store Connect Metadata Guide

Everything you need to fill in when creating the app listing in App Store Connect.

---

## App Information

| Field | Value |
|-------|-------|
| **App Name** | Splat Frame |
| **Bundle ID** | `aristides.lintzeris.Splat-Frame` |
| **SKU** | `splatframe-ios-001` |
| **Primary Language** | English (U.S.) |
| **Primary Category** | Entertainment |
| **Secondary Category** | Photo & Video |
| **Content Rights** | Does not contain third-party content that requires rights |
| **Age Rating** | 4+ (no objectionable content) |

---

## Pricing & Availability

| Field | Value |
|-------|-------|
| **Price** | Free |
| **Availability** | All territories |

---

## Version Information

### App Store Listing Copy

**Subtitle** (30 characters max):

```
3D Window Into Another World
```

**Promotional Text** (170 characters max — can be updated without a new build):

```
Explore stunning 3D Gaussian splat scenes right on your iPhone. Move your head and watch the world shift — like looking through a real window.
```

**Description** (4000 characters max):

```
Splat Frame turns your iPhone into a window to another dimension.

Using your front-facing TrueDepth camera, Splat Frame tracks your head in real time and shifts the on-screen perspective to create a convincing parallax depth illusion — like peering through a portal into a 3D space.

TWO IMMERSIVE EXPERIENCES:

◆ Parallax Cube
Place your own photos and videos from your library onto the 5 inner faces of a 3D room. As you move your head, the perspective shifts naturally, creating a mesmerizing depth effect that makes flat media feel alive.

◆ Gaussian Splat Viewer
View cutting-edge 3D Gaussian splat scenes in full-screen with real-time head-tracked camera movement. Splats bring photorealistic 3D captures to life with stunning detail.

DISCOVER & EXPLORE:

Browse an Instagram-style feed of 3D splat scenes from the community. Tap to preview, download your favorites, and experience them with the full head-tracked parallax effect.

KEY FEATURES:

• Real-time head tracking via TrueDepth face tracking
• Off-axis projection for natural parallax depth illusion
• Place personal photos & videos on cube faces
• Browse and download 3D Gaussian splat scenes
• Screen recording built in to share your experience
• Adjustable smoothing and movement sensitivity
• One-tap calibration reset
• Supports .ply, .splat, and .spz file formats
• Optimized for smooth 60fps Metal rendering

BUILT WITH:

• ARKit face tracking for precise head position
• Metal & MetalSplatter for GPU-accelerated splat rendering
• SceneKit for the parallax cube experience
• Off-axis asymmetric frustum projection math

Requires an iPhone with TrueDepth front-facing camera (iPhone X or later).
```

**Keywords** (100 characters max, comma-separated):

```
3D,splat,gaussian,parallax,head tracking,depth,portal,AR,augmented reality,photo frame,cube,Metal
```

---

### What's New in This Version

```
Initial release! Experience the 3D parallax window effect and Gaussian splat viewer for the first time.
```

---

## Support & Links

| Field | Suggested Value |
|-------|-----------------|
| **Support URL** (required) | `https://github.com/YOUR_USERNAME/splat-frame` |
| **Marketing URL** (optional) | Your GitHub Pages site URL once live |
| **Privacy Policy URL** (required) | `https://YOUR_USERNAME.github.io/splat-frame/privacy` (see note below) |

> **Privacy Policy Note:** Apple requires a privacy policy URL. Since the app collects no data, create a simple page stating: "Splat Frame does not collect, store, or transmit any personal data. Camera data is processed entirely on-device for head tracking and is never recorded or shared."

---

## App Privacy (Data Collection)

When prompted in App Store Connect under **App Privacy**:

| Question | Answer |
|----------|--------|
| Do you or your third-party partners collect data? | **No** |

The app processes camera data on-device only for head tracking. No data leaves the device. No analytics, no tracking, no accounts.

Select **"None"** for all data collection categories.

---

## Screenshots

You need screenshots for the following device sizes (at minimum):

| Device | Resolution | Required |
|--------|-----------|----------|
| iPhone 16 Pro Max (6.9") | 1320 × 2868 | Yes |
| iPhone 16 Pro (6.3") | 1206 × 2622 | Yes (or auto-scales from 6.9") |
| iPad Pro 13" (if supporting iPad) | 2064 × 2752 | Not required (iPhone only) |

**Recommended screenshots to capture:**

1. Parallax cube with photos placed on faces — head tilted to show depth
2. Gaussian splat scene with the 3D viewer
3. Splat feed browsing view
4. Splat detail/download view
5. Settings with calibration controls

**Tips:**
- Use a real device (simulator doesn't support face tracking)
- Capture in portrait orientation
- No status bar text preferred — use Xcode's simulator appearance or crop
- You can add device frames and captions using tools like Fastlane Frameit or Screenshots Pro

---

## App Review Information

| Field | Value |
|-------|-------|
| **Contact First Name** | Aristides |
| **Contact Last Name** | Lintzeris |
| **Contact Email** | *(your email)* |
| **Contact Phone** | *(your phone)* |
| **Demo Account** | Not required (no sign-in) |
| **Notes for Review** | This app requires an iPhone with a TrueDepth front-facing camera (iPhone X or later) for the head tracking feature. The camera is used solely for real-time face tracking to create a parallax depth illusion. No images are captured or stored. The app does not use any backend services or require authentication. |

---

## Build Upload Checklist

Before uploading your archive:

- [ ] Version set to `1.0` and build number is `1`
- [ ] Scheme set to **Release** configuration
- [ ] Run on a real device to verify face tracking works
- [ ] Archive via **Product → Archive** in Xcode
- [ ] Validate the archive before uploading
- [ ] Upload via **Distribute App → App Store Connect**
- [ ] Wait for build processing (usually 5–15 minutes)
- [ ] Select the build under your version in App Store Connect

---

## Export Compliance

The Info.plist includes `ITSAppUsesNonExemptEncryption = NO`, so you will **not** be prompted for export compliance documentation on each upload. The app does not use any encryption beyond standard HTTPS.

---

## Submission Summary

Once all metadata is filled in and a build is selected:

1. Fill in all fields above in App Store Connect
2. Upload screenshots
3. Submit for review
4. Typical review time: 24–48 hours
5. Once approved, release manually or set to auto-release
