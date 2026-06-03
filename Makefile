TARGET := iphone:clang:7.0:6.0
INSTALL_TARGET_PROCESSES = accountsd SocialUIService SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = FBIntegrationFix
FBIntegrationFix_FILES = Tweak.x

include $(THEOS_MAKE_PATH)/tweak.mk
CFLAGS = -isystem /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/clang/6.0/include
