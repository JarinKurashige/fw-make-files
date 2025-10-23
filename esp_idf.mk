# Makefile for CDC

TAG = "\\033[32\;1mMakefile\\033[0m"

# Targets
.PHONY: all build flash monitor config print_tasks

# Variables
.PHONY: SDKCONFIG BAUD

all: build flash monitor

build:
ifndef SDKCONFIG
	$(error SDKCONFIG file not set. Please include SDKCONFIG=[SDKCONFIG file name] when running commands)
endif

	@echo "${TAG} | Building IDF project with SDKCONFIG file: ${SDKCONFIG}"
	@idf.py -DSDKCONFIG=$(SDKCONFIG) build

flash:
ifndef BAUD
	$(error BAUD not set. Please include BAUD=[baudrate] when running commands)
endif

	@echo "${TAG} | Flashing IDF project"
	@idf.py -b $(BAUD) flash

monitor:
ifndef BAUD
	$(error BAUD not set. Please include BAUD=[baudrate] when running commands)
endif

	@echo "${TAG} | Monitoring IDF project"
	@idf.py -b $(BAUD) monitor

config:
ifndef SDKCONFIG
	$(error SDKCONFIG file not set. Please include SDKCONFIG=[SDKCONFIG file name] when running commands)
endif

	@echo "${TAG} | Opening menuconfig for SDKCONFIG file: ${SDKCONFIG}"
	@idf.py -DSDKCONFIG=$(SDKCONFIG) menuconfig

print_tasks:
ifndef SDKCONFIG
	$(error SDKCONFIG file not set. Please include SDKCONFIG=[SDKCONFIG file name] when running commands)
endif

	@echo "${TAG} | Printing task information for SDKCONFIG file: ${SDKCONFIG}"
	@python3 print_all_task_info.py sdkconfig=$(SDKCONFIG)
