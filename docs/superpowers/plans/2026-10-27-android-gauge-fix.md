# Android header gauge correction

**Request:** User's Android screenshot shows thin gold vertical lines rising
from the start and end of both progress fills.

**Investigation:** Both fills use a 3px-high rounded StyleBoxFlat with an
asymmetric 1px top border and antialiasing. The tracks and other controls do
not exhibit the screenshot's gold lines. Godot 4.7.2's AA/rounded border path
generates a separate triangle mesh. Precise device/driver cause is unconfirmed.
The native NVIDIA baseline passed 40 containment cases, including fractional
scales and oversampling overrides. No Android device is attached.

**Fix:** Keep the layout and values; remove the thin rounded/AA border path
from fills, use a flat borderless gold fill and clip child painting to each
existing rounded track. This is a targeted rendering workaround, not a claim
that the exact phone artifact was reproduced on desktop.

- [x] Inspect screenshot, source, Godot drawing code and baseline captures.
- [x] Apply bounded flat fill; increase APK version code to 2 / 0.1.1-test.
- [x] Pixel containment/fill checks, native gameplay capture and focused review.
- [x] Build/sign/inspect new APK with same package/certificate; publish direct link.

No game rules, save schema, artwork, camera or normal player saves changed.
Preserve the previously uploaded APK. Phone confirmation remains necessary.

Final verification: 40 native GPU cases pass with no leaks, visible fill and
zero fill at 0%. Focused review: no runtime issue; causality comment softened.
Import/export and native startup of extracted APK resources exit0, empty stderr.
Initial/prepared/four catalogues/raid exercised; prepared screenshot inspected.
apksigner v2/v3 valid, same certificate as code1. APK 61,076,174 bytes.
SHA256 D7A5CEB26AA8B5B27975A51367944177ECD3C72565B86B78A61549A01647C4ED.
Published as GitHub prerelease `android-test-0.1.1`; remote digest equals local
APK and anonymous download endpoint returns HTTP200. Previous release preserved.
