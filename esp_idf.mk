# Makefile for CDC

TAG = "\\033[32\;1mMakefile\\033[0m"

# Variables
.PHONY: SDKCONFIG BAUD PORT

all: build flash monitor

SDKCONFIG ?= sdkconfig
BAUD ?= 921600
PORT ?= /dev/ttyUSB0

build:
	@echo "${TAG} | Building IDF project with SDKCONFIG file: ${SDKCONFIG}"
	@idf.py -DSDKCONFIG=$(SDKCONFIG) build

flash:
	@echo "${TAG} | Flashing IDF project"
	@idf.py -b $(BAUD) flash -p $(PORT)

monitor:
	@echo "${TAG} | Monitoring IDF project"
	@idf.py -b $(BAUD) monitor -p $(PORT)

config:
	@echo "${TAG} | Opening menuconfig for SDKCONFIG file: ${SDKCONFIG}"
	@idf.py -DSDKCONFIG=$(SDKCONFIG) menuconfig

print_tasks:
	@echo "${TAG} | Printing task information for SDKCONFIG file: ${SDKCONFIG}"
	@python3 print_all_task_info.py sdkconfig=$(SDKCONFIG)
