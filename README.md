### RPi4 EFI firmware

I noticed I'm including EDK2 build in many of my projects, and it takes a lot of time in the pipelines to build it, so I decided to create a separate repository for it.

### How to build

```shell
make
```

...or with pre-generated private key

```shell
make PRIVATE_KEY=/path/to/key.pem "CN=My Organization"
```

#### Difference vs. pftf/RPi4

1. Serial number works correctly (= it is not the same as MAC address)
2. USB boot works on 6+ kernels also
3. GPU firmware, config.txt & device tree overlays are not bundled, we only build RPI_EFI.fd here
4. No support for network boot (http / tftp)
5. No embedded default keys for Secure Boot, use [`virt-firmware`](https://pypi.org/project/virt-firmware/) to pre-populate keys
