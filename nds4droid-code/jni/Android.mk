# Android ndk makefile for ds4droid

LOCAL_BUILD_PATH := $(call my-dir)

include $(CLEAR_VARS)

include $(LOCAL_BUILD_PATH)/cpudetect/cpudetect.mk

ifeq ($(TARGET_ARCH_ABI),x86)
include $(LOCAL_BUILD_PATH)/desmume/src/utils/tinycc/Android_x86.mk
endif

ifeq ($(TARGET_ARCH_ABI),armeabi)
include $(LOCAL_BUILD_PATH)/desmume/src/utils/tinycc/Android_arm.mk
endif

ifeq ($(TARGET_ARCH_ABI),armeabi-v7a)
include $(LOCAL_BUILD_PATH)/desmume/src/android/dynarec/Android.mk
include $(LOCAL_BUILD_PATH)/desmume/src/utils/tinycc/Android_arm.mk
include $(LOCAL_BUILD_PATH)/desmume_neon.mk
include $(LOCAL_BUILD_PATH)/desmume_v7.mk
endif

include $(LOCAL_BUILD_PATH)/desmume_compat.mk
include $(LOCAL_BUILD_PATH)/desmume/src/android/7z/7z.mk

