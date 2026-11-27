p = "android/app/src/main/AndroidManifest.xml"
s = open(p, encoding="utf-8").read()
snip = open("android_overlay/manifest_tambahan.xml", encoding="utf-8").read()
if "CaptureActivity" not in s:
    s = s.replace("</application>", snip + "\n    </application>", 1)
    open(p, "w", encoding="utf-8").write(s)
print("manifest patched")
