# Makefile for CDC

TAG = "\\033[32\;1mMakefile\\033[0m"

# Variables
.PHONY: SDKCONFIG BAUD PORT

BUILD_DIR_PREFIX := build

ESP32_MODEL_FILENAME := .env/esp32_model

ESP32_MODEL := $(shell cat ${ESP32_MODEL_FILENAME} 2>/dev/null)

all: build flash monitor

SDKCONFIG ?= sdkconfig
BAUD ?= 921600
PORT ?= /dev/ttyUSB0

set_target:
	@set -e; \
	echo "List of targets:"; \
	idf.py --list-targets; \
	read -p "Enter ESP32 target: " ESP32_MODEL; \
	idf.py -B ${BUILD_DIR_PREFIX}_$${ESP32_MODEL} -DSDKCONFIG=$(SDKCONFIG) set-target $${ESP32_MODEL}; \
	mkdir -p $(dir ${ESP32_MODEL_FILENAME}); \
	echo "$$ESP32_MODEL" > ${ESP32_MODEL_FILENAME}; \
	echo "ESP32 model [$$ESP32_MODEL] saved to ${ESP32_MODEL_FILENAME}"

build:
ifeq (${ESP32_MODEL},)
	$(error ESP32_MODEL is not set. Run 'make set_target' first)
endif	

	@echo "${TAG} | Building IDF project with SDKCONFIG file: ${SDKCONFIG}"
	@idf.py -B ${BUILD_DIR_PREFIX}_${ESP32_MODEL} -DSDKCONFIG=$(SDKCONFIG) build

flash:
ifeq (${ESP32_MODEL},)
	$(error ESP32_MODEL is not set. Run 'make set_target' first)
endif	

	@echo "${TAG} | Flashing IDF project"
	@idf.py -B ${BUILD_DIR_PREFIX}_${ESP32_MODEL} -b $(BAUD) flash -p $(PORT)

monitor:
	@echo "${TAG} | Monitoring IDF project"
	@idf.py -b $(BAUD) monitor -p $(PORT)

config:
ifeq (${ESP32_MODEL},)
	$(error ESP32_MODEL is not set. Run 'make set_target' first)
endif	

	@echo "${TAG} | Opening menuconfig for SDKCONFIG file: ${SDKCONFIG}"
	@idf.py -B ${BUILD_DIR_PREFIX}_${ESP32_MODEL} -DSDKCONFIG=$(SDKCONFIG) menuconfig

print_tasks:
	@echo "${TAG} | Printing task information for SDKCONFIG file: ${SDKCONFIG}"
	@python3 print_all_task_info.py sdkconfig=$(SDKCONFIG)
