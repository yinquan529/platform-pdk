#
# Copyright (C) 2012 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# common build dirs for pdk1 and pdk2
# this list should be minimal to make pdk2 build fast

# BUILD_PDK_SUBDIRS is parsed by a script to extract source tree list automatically.
# To make that parsing simple, the first line should not include any explicit directory name.
BUILD_PDK_SUBDIRS := \
	abi \
	bionic \
	bootable \
	build \
	device \
	hardware \
	prebuilt \
	prebuilts


# if pdk_vendor.mk exist, do not include pdk_google.mk
# pdk_vendor.mk should add more dirs for pdk2 build
# that is, it should include BUILD_PDK_SUBDIRS += \ to add additional dir for build
ifneq (,$(wildcard $(TOPDIR)pdk/build/pdk_vendor.mk))
include $(TOPDIR)pdk/build/pdk_vendor.mk
else
include $(TOPDIR)pdk/build/pdk_google.mk
endif

ifeq ($(PDK_BUILD_TYPE), pdk1)
# addition for pdk1
BUILD_PDK1_SUBDIRS := \
	dalvik \
	development \
	external \
	frameworks \
	libcore \
	packages/apps/Bluetooth \
	packages/apps/Launcher2 \
	packages/apps/Settings \
	packages/inputmethods/LatinIME \
	packages/providers \
	sdk \
	system


BUILD_PDK_SUBDIRS += $(BUILD_PDK1_SUBDIRS)

ifeq ($(TARGET_CPU_SMP), true)
PDK_BIN_NAME := pdk_bin_$(TARGET_ARCH_VARIANT)_true
else # !SMP
PDK_BIN_NAME := pdk_bin_$(TARGET_ARCH_VARIANT)_false
endif # !SMP

.PHONY: pdk_bin_zip
pdk_bin_zip: $(OUT_DIR)/target/$(PDK_BIN_NAME).zip


$(OUT_DIR)/target/$(PDK_BIN_NAME).zip: $(OUT_DIR)/target/$(PDK_BIN_NAME)
	$(info Creating $(OUT_DIR)/target/$(PDK_BIN_NAME).zip)
	$(hide) cd $(dir $@) && rm -rf $(notdir $@) && zip -rq $(notdir $@) $(PDK_BIN_NAME)

# explicitly put dependency on two final images to avoid copying every time
# It is too early and INSTALLED_SYSTEMIMAGE is not defined yet.
$(OUT_DIR)/target/$(PDK_BIN_NAME): $(OUT_DIR)/target/product/$(TARGET_DEVICE)/boot.img \
                                   $(OUT_DIR)/target/product/$(TARGET_DEVICE)/system.img
	python $(TOPDIR)pdk/build/copy_pdk1_bins.py . $(OUT_DIR)/target/$(PDK_BIN_NAME) $(TARGET_DEVICE)

else # pdk2

# overwrite the definition from conflig.mk, no package build in pdk2
BUILD_PACKAGE :=

# addition for pdk2
BUILD_PDK2_SUBDIRS := \
	external/antlr \
	external/bluetooth \
	external/bsdiff \
	external/bzip2 \
	external/dbus \
	external/doclava \
	external/expat \
	external/fdlibm \
	external/flac \
	external/freetype \
	external/gcc-demangle \
	external/giflib \
	external/gtest \
	external/guava \
	external/icu4c \
	external/jhead \
	external/jpeg \
	external/jsilver \
	external/jsr305 \
	external/liblzf \
	external/libpng \
	external/libvpx \
	external/mksh \
	external/openssl \
	external/protobuf \
	external/sonivox \
	external/speex \
	external/stlport \
	external/tinyalsa \
	external/tremolo \
	external/wpa_supplicant \
	external/wpa_supplicant_6 \
	external/wpa_supplicant_8 \
	external/yaffs2 \
	external/zlib \
	frameworks/native \
	system/bluetooth \
	system/core \
	system/extras \
	system/media/audio_utils \
	system/netd \
	system/security \
	system/vold

# system should be put back to common list once system/media is refactored

BUILD_PDK_SUBDIRS += $(BUILD_PDK2_SUBDIRS)

# naming convention for bin repository: pdk_bin_CPUArch_SMPSupport
# ex: pdk_bin_armv7-a_true (armv7-a with SMP support)
ifeq ($(TARGET_CPU_SMP), true)
PDK_BIN_PRIMARY := pdk_bin_$(TARGET_ARCH_VARIANT)_true
# this dir will not exist, so SMP CPU requires SMP version
PDK_BIN_SECONDARY := pdk_bin_no_such_dir
else # !SMP
PDK_BIN_PRIMARY := pdk_bin_$(TARGET_ARCH_VARIANT)_false
# if non-SMP binary does not exist, use SMP version
PDK_BIN_SECONDARY := pdk_bin_$(TARGET_ARCH_VARIANT)_true
endif # !SMP

PDK_BIN_VENDOR_TOP_DIR := $(TOPDIR)vendor/pdk/data/partner

ifneq (,$(wildcard $(PDK_BIN_VENDOR_TOP_DIR)/$(PDK_BIN_PRIMARY)))
PDK_BIN_REPOSITORY := $(PDK_BIN_VENDOR_TOP_DIR)/$(PDK_BIN_PRIMARY)
else # !PRIMARY
ifneq (,$(wildcard $(PDK_BIN_VENDOR_TOP_DIR)/$(PDK_BIN_SECONDARY)))
$(info PDK_BIN using secondary option $(PDK_BIN_SECONDARY) for build)
PDK_BIN_REPOSITORY := $(PDK_BIN_VENDOR_TOP_DIR)/$(PDK_BIN_SECONDARY)
else # !SECONDARY
$(error Neither $(PDK_BIN_VENDOR_TOP_DIR)/$(PDK_BIN_PRIMARY) nor \
  $(PDK_BIN_VENDOR_TOP_DIR)/$(PDK_BIN_SECONDARY) exists.)
endif # !SECONDARY
endif # !PRIMARY


include $(PDK_BIN_REPOSITORY)/pdk_prebuilt.mk

ifeq ($(PDK_BIN_ORIGINAL_TARGET), )
$(error PDK_BIN_ORIGINAL_TARGET not set in $(PDK_BIN_REPOSITORY)/pdk_prebuilt.mk)
endif

ifeq (,$(wildcard $(OUT_DIR)/target/product/$(TARGET_DEVICE)/PDK_BIN_COPIED))
$(error PDK binaries necessary for pdk2 build are not there! Did you run setup_pdk2_bin.py? )
endif # PDK_BIN_COPIED

PRODUCT_PACKAGES += core core-junit

endif # pdk2