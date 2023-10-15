### RPi4 EFI firmware

I noticed I'm including EDK2 build in many of my projects, and it takes a lot of time in the pipelines to build it, so I decided to create a separate repository for it.

### How to build

```shell
make -j$(nproc)
```

#### Difference vs. pftf/RPi4

1. Serial number works correctly (= it is not the same as MAC address)
2. USB boot works on 6+ kernels also
3. GPU firmware, config.txt & device tree overlays are not bundled, we only build RPI_EFI.fd here
4. No support for network boot (http / tftp)
5. No embedded default keys for Secure Boot, use [`virt-firmware`](https://pypi.org/project/virt-firmware/) to pre-populate keys, see below.

```bash
# Create key which you then use to sign .efi files
openssl req \
    -new -x509 \
    -newkey rsa:2048 \
    -subj "/CN=My custom key/" \
    -keyout my.key \
    -out my.crt \
    -outform PEM \
    -days 7300 \
    -nodes -sha256

# Download pre-built image or build yourself
curl -Lo RPI_EFI.orig.fd https://github.com/valtzu/rpi-efi-firmware/releases/download/0.2.2/RPI_EFI.fd

virt-fw-vars \
  -i RPI_EFI.orig.fd \
  -o RPI_EFI.fd \
  --no-microsoft \
  --secure-boot \
  --enroll-cert my.crt \
  --add-db a0baa8a3-041d-48a8-bc87-c36d121b5e3d my.crt
```
