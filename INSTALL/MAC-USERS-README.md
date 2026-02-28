# Signing DRAW

After you download and extract DRAW, change to the directory you extracted to and then run:

```sh
xattr -dr com.apple.quarantine ./DRAW
codesign --force --deep --sign - ./DRAW
```
