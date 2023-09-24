SHELL = /bin/bash
RELEASE_TYPE := RELEASE
export WORKSPACE := $(CURDIR)
export PACKAGES_PATH := $(CURDIR)/pftf-rpi4/edk2:$(CURDIR)/pftf-rpi4/edk2-platforms:$(CURDIR)/pftf-rpi4/edk2-non-osi
export GCC5_AARCH64_PREFIX := aarch64-linux-gnu-

submodules:
ifndef CI
	git submodule update --init --recursive
endif

patch: submodules
	git -C pftf-rpi4/edk2 reset --hard
	git -C pftf-rpi4/edk2-platforms reset --hard
	patch -p1 --binary -d pftf-rpi4/edk2 -i ../0001-MdeModulePkg-UefiBootManagerLib-Signal-ReadyToBoot-o.patch
	patch -p1 --binary -d pftf-rpi4/edk2-platforms -i ../0002-Check-for-Boot-Discovery-Policy-change.patch
	patch -p1 --binary -d pftf-rpi4/edk2-platforms -i $(CURDIR)/0001-RPi4-fix-serial-number.patch
	patch -p1 --binary -d pftf-rpi4/edk2-platforms -i $(CURDIR)/0002-RPi4-fix-usb-on-recent-kernels.patch

edk2-setup: patch
	mkdir -p $WORKSPACE
	$(MAKE) -C pftf-rpi4/edk2/BaseTools

RPI_EFI.fd: edk2-setup
	source pftf-rpi4/edk2/edksetup.sh ;\
	build -a AARCH64 -t GCC5 -b $(RELEASE_TYPE) \
	    --silent \
	    -p pftf-rpi4/edk2-platforms/Platform/RaspberryPi/RPi4/RPi4.dsc \
	    --pcd gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVendor=L"EDK2" \
	    --pcd gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVersionString=L"Raspberry Pi EFI Firmware" \
	    --pcd PcdPlatformBootTimeOut=0 \
	    --pcd PcdRamLimitTo3GB=0 \
	    --pcd PcdRamMoreThan3GB=1 \
	    --pcd PcdSystemTableMode=2 \
	    -D NETWORK_ENABLE=FALSE
	cp -f Build/RPi4/$(RELEASE_TYPE)_GCC5/FV/RPI_EFI.fd ./

.PHONY: patch edk2-setup submodules
