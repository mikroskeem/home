# home

## macOS stuff

```bash
sudo install -d -m 755 -o root -g root /etc/synthetic.d
sudo tee /etc/synthetic.d/nix <<EOF
nix
run	private/var/run
EOF
sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t
```

Note that synthetic.conf expects tab characters as separators, other whitespace won't do.

Use [DeterminateSystems/nix-installer](https://github.com/DeterminateSystems/nix-installer)
