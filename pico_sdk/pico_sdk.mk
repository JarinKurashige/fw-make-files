# Makefile for Pico projects

TAG = "\\033[32\;1mMakefile\\033[0m"

# Variables
.PHONY: BUS ADDRESS INTERFACE PROJECT_NAME

MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

VALID_PICO_MODELS := RP2040 RP2350
RP2040_BUILD_DIR := build_rp2040
RP2350_BUILD_DIR := build_rp2350

CHIPID_FILENAME := .env/chipid
PICO_MODEL_FILENAME := .env/pico_model
INTERFACE_FILENAME := .env/interface
PROJECT_FILENAME := .env/project_name

LOG_DIR := ./logs

CHIPID := $(shell cat ${CHIPID_FILENAME} 2>/dev/null)
PICO_MODEL := $(shell cat ${PICO_MODEL_FILENAME} 2>/dev/null)
INTERFACE := $(shell cat ${INTERFACE_FILENAME} 2>/dev/null)
PROJECT_NAME := $(shell cat ${PROJECT_FILENAME} 2>/dev/null)

ifeq ($(PICO_MODEL),RP2040)
CURRENT_BUILD_DIR := ${RP2040_BUILD_DIR}
PICO_BOARD := pico
else ifeq ($(PICO_MODEL),RP2350)
CURRENT_BUILD_DIR := ${RP2350_BUILD_DIR}
PICO_BOARD := pico2
endif

all:
	@$(MAKE) build
	@sleep 1
	@$(MAKE) flash
	@sleep 1
	@$(MAKE) monitor

set_interface:
	@set -e; \
	INTERFACE=${INTERFACE}; \
	mkdir -p $(dir ${INTERFACE_FILENAME}); \
	echo "$$INTERFACE" > ${INTERFACE_FILENAME}; \
	echo "Interface [$$INTERFACE] saved to ${INTERFACE_FILENAME}"

set_board:
	@set -e; \
	echo "List of boards:"; \
	echo "${VALID_PICO_MODELS}"; \
	read -p "Enter RPxxxx target: " PICO_MODEL; \
	mkdir -p $(dir ${PICO_MODEL_FILENAME}); \
	echo "$$PICO_MODEL" > ${PICO_MODEL_FILENAME}; \
	echo "Pico model [$$PICO_MODEL] saved to ${PICO_MODEL_FILENAME}"

set_project_name:
	@set -e; \
	PROJECT_NAME=${PROJECT_NAME}; \
	mkdir -p $(dir ${PROJECT_FILENAME}); \
	echo "$$PROJECT_NAME" > ${PROJECT_FILENAME}; \
	echo "Project name [$$PROJECT_NAME] saved to ${PROJECT_FILENAME}"

get_sn:
	@set -e; \
	echo "${TAG} | picotool requires root access. Please input credentials if required"; \
	CHIPID=$$(sudo picotool info -df | grep "chipid:" | awk '{print toupper(substr($$2, 3))'}); \
	mkdir -p $(dir ${CHIPID_FILENAME}); \
	echo "$$CHIPID" > ${CHIPID_FILENAME}; \
	echo "Chip ID [$$CHIPID] saved to ${CHIPID_FILENAME}"

build:
ifndef PICO_MODEL
	$(error PICO_MODEL is not set. Please run 'make set_board')
endif
ifeq (,$(filter $(PICO_MODEL), $(VALID_PICO_MODELS)))
	$(error PICO_MODEL is invalid. Please run 'make set_board')
endif

	@set -e; \
	if [ ! -d "${CURRENT_BUILD_DIR}" ]; then \
		echo "Creating build directory '${CURRENT_BUILD_DIR}'"; \
		mkdir -p ${CURRENT_BUILD_DIR}; \
	fi
	@echo "${TAG} | Building project for ${PICO_MODEL}"
	@cd ${CURRENT_BUILD_DIR} && \
	cmake -DPICO_BOARD=${PICO_BOARD} ../ && \
	make --no-print-directory -j16 && \
	cd ../
	@echo "${TAG} | Build completed. Files at ${CURRENT_BUILD_DIR}"
	
flash_picotool:
ifndef PICO_MODEL
	$(error PICO_MODEL is not set. Please run 'make set_board')
endif
ifeq (,$(filter $(PICO_MODEL), $(VALID_PICO_MODELS)))
	$(error PICO_MODEL is invalid. Please run 'make set_board')
endif
ifeq (${CHIPID},)
	$(error CHIPID is not set. Run 'make get_sn' first)
endif
ifeq (${PROJECT_NAME},)
	$(error PROJECT_NAME is not set. Run "make set_project_name PROJECT_NAME=[MyProjectName]". Where MyProjectName is the name given to the top level CMake)
endif

	@set -e; \
	echo "${TAG} | picotool requires root access. Please input credentials if required"; \
	echo "${TAG} | Flashing to pico device ${CHIPID} using Picotool"; \
	sudo picotool load ${CURRENT_BUILD_DIR}/main/${PROJECT_NAME}.uf2 -f --ser ${CHIPID}; \
	echo "${TAG} | Pico flashed"

flash_swd:
ifndef PICO_MODEL
	$(error PICO_MODEL is not set. Please run 'make set_board')
endif
ifeq (,$(filter $(PICO_MODEL), $(VALID_PICO_MODELS)))
	$(error PICO_MODEL is invalid. Please run 'make set_board')
endif
ifeq (${PROJECT_NAME},)
	$(error PROJECT_NAME is not set. Run "make set_project_name PROJECT_NAME=[MyProjectName]". Where MyProjectName is the name given to the top level CMake)
endif

	@set -e; \
	echo "${TAG} | Flashing to pico device using SWD"; \
	bash ${MAKEFILE_DIR}flash_rpxxxx_over_swd.sh -f ${CURRENT_BUILD_DIR}/main/${PROJECT_NAME}.elf; \
	echo "${TAG} | Pico flashed"

monitor:
ifeq (${CHIPID},)
	$(error CHIPID is not set. Run 'make get_sn' first)
endif
ifeq (${INTERFACE},)
	$(error INTERFACE is not set. Run 'make set_interface INTERFACE=[/dev/*]' first)
endif
	@set -e; \
	echo "${TAG} | picotool requires root access. Please input credentials if required"; \
	echo "${TAG} | Restarting $(PICO_MODEL)"; \
	sudo picotool reboot -f --ser ${CHIPID}; \
	echo "${TAG} | Waiting for Pico to reboot"; \
	sleep 2; \
	echo "${TAG} | Monitoring ${PICO_MODEL} output on ${INTERFACE}"; \
	while [ ! -e "${INTERFACE}" ]; do sleep 0.2; done; \
	mkdir -p "${LOG_DIR}"; \
	LOG_FILE="pico_monitor_$$(date +%Y%m%d_%H%M%S).log"; \
	script -q -c "minicom -D ${INTERFACE} -w -c on -O timestamp=extended" "${LOG_DIR}/$$LOG_FILE"; \
	reset; \
	ls -1t "${LOG_DIR}"/pico_monitor_*.log | tail -n +6 | xargs -r rm --; \

open_latest_log:

	@set -e \
	LATEST_LOG=$$(ls -t ${LOG_DIR}/pico_monitor_*.log 2>/dev/null | head -n 1); \
	if [ -z "$$LATEST_LOG" ]; then \
		echo "${TAG} | No logs found in ${LOG_DIR}"; \
		exit 1; \
	fi; \
	echo "${TAG} | Opening log file: $$LATEST_LOG"; \
	less -R $$LATEST_LOG
