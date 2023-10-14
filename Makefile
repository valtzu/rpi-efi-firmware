SHELL = /bin/bash
RELEASE_TYPE := RELEASE
VERSION := dev
CN := Raspberry Pi Platform Key
export WORKSPACE := $(CURDIR)
export PACKAGES_PATH := $(CURDIR)/pftf-rpi4/edk2:$(CURDIR)/pftf-rpi4/edk2-platforms:$(CURDIR)/pftf-rpi4/edk2-non-osi
export GCC5_AARCH64_PREFIX := aarch64-linux-gnu-

$(shell mkdir -p keys)

RPI_EFI.fd: edk2-setup keys
	source pftf-rpi4/edk2/edksetup.sh ;\
	build -a AARCH64 -t GCC5 -b $(RELEASE_TYPE) \
	    --silent \
	    -p pftf-rpi4/edk2-platforms/Platform/RaspberryPi/RPi4/RPi4.dsc \
	    --pcd gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVendor=L"https://github.com/valtzu/rpi-efi-firmware" \
	    --pcd gEfiMdeModulePkgTokenSpaceGuid.PcdFirmwareVersionString=L"EDK2 Firmware $(VERSION)" \
	    --pcd PcdPlatformBootTimeOut=0 \
	    --pcd PcdRamLimitTo3GB=0 \
	    --pcd PcdRamMoreThan3GB=1 \
	    --pcd PcdSystemTableMode=2 \
	    -D SECURE_BOOT_ENABLE=TRUE \
	    -D NETWORK_ENABLE=FALSE \
	    -D SMC_PCI_SUPPORT=1 \
	    -D DEFAULT_KEYS=TRUE \
	    -D PK_DEFAULT_FILE=$$WORKSPACE/keys/pk.cer \
	    -D KEK_DEFAULT_FILE1=$$WORKSPACE/keys/ms_kek.cer \
	    -D DB_DEFAULT_FILE1=$$WORKSPACE/keys/ms_db1.cer \
	    -D DB_DEFAULT_FILE2=$$WORKSPACE/keys/ms_db2.cer \
	    -D DBX_DEFAULT_FILE1=$$WORKSPACE/keys/arm64_dbx.bin
	cp -f Build/RPi4/$(RELEASE_TYPE)_GCC5/FV/RPI_EFI.fd ./

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

keys/pk.cer:
ifndef PRIVATE_KEY
	openssl req -new -x509 -newkey rsa:2048 -subj "/CN=$(CN)/" -keyout /dev/null -outform DER -out $@ -days 7300 -nodes -sha256
else
	openssl req -new -x509 -key $(PRIVATE_KEY) -subj "/CN=$(CN)/" -outform DER -out $@ -days 7300 -nodes -sha256
endif
keys/ms_kek.cer:
	curl -L https://go.microsoft.com/fwlink/?LinkId=321185 -o $@
keys/ms_db1.cer:
	curl -L https://go.microsoft.com/fwlink/?linkid=321192 -o $@
keys/ms_db2.cer:
	curl -L https://go.microsoft.com/fwlink/?linkid=321194 -o $@
keys/arm64_dbx.bin:
	curl -L https://uefi.org/sites/default/files/resources/dbxupdate_arm64.bin -o $@

edk2-setup: patch
	mkdir -p $WORKSPACE
	$(MAKE) -C pftf-rpi4/edk2/BaseTools

.PHONY: patch edk2-setup submodules
