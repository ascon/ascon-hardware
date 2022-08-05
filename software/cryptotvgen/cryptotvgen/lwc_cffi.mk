
ifeq ($(CRYPTO_TYPE),)
$(error CRYPTO_TYPE was not specificed )
endif

ifeq ($(CRYPTO_VARIANT),)
$(error CRYPTO_VARIANT was not specificed )
endif

ifeq ($(OS),Windows_NT)
SO_EXT = dll
else
# works for cffi on Linux and macOS
SO_EXT = so
endif

# $(info CANDIDATE_PATH=$(CANDIDATE_PATH))

#required only for schwaemm* variants, disables inlining of functions
ifneq ($(findstring schwaemm,$(CRYPTO_VARIANT)),)
CFLAGS += -D_DEBUG
endif

BASE_DIR := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

INCLUDES_DIR = $(BASE_DIR)/includes

#Default optimization. Prepend, so can be overwritten 
# CFLAGS := -Os $(CFLAGS)

CFLAGS += -shared -fPIC

CRYPTO_DIR=crypto_$(CRYPTO_TYPE)

IMPL_SRC_DIR?=ref

IMPL_SRC_PATH=$(CANDIDATE_PATH)/$(CRYPTO_DIR)/$(CRYPTO_VARIANT)/$(IMPL_SRC_DIR)

C_SRCS=$(wildcard $(IMPL_SRC_PATH)/*.c)
C_HDRS=$(wildcard $(IMPL_SRC_PATH)/*.h) $(wildcard $(INCLUDES_DIR)/*.h)

LIB_PATH ?= $(CANDIDATE_PATH)/lib


default: $(LIB_PATH)/$(CRYPTO_DIR)/$(CRYPTO_VARIANT).$(SO_EXT)


$(LIB_PATH)/$(CRYPTO_DIR):
	@mkdir -p $@

$(LIB_PATH)/$(CRYPTO_DIR)/$(CRYPTO_VARIANT).$(SO_EXT): $(C_SRCS) $(C_HDRS) $(LIB_PATH)/$(CRYPTO_DIR)
	$(CC) $(CFLAGS) -I$(IMPL_SRC_PATH) -I$(INCLUDES_DIR) $(C_SRCS) -o $@
