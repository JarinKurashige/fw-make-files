# Makefile for Pico projects

TAG = "\\033[32\;1mMakefile\\033[0m"

# Targets. don't know if we need to populate these or if they are automatically included, implied by the creation of a command below
.PHONY: build flash monitor get_sn set_board

# Variables
.PHONY: PICO_MODEL BUS ADDRESS INTERFACE

PROJECT_NAME := vehicle_comm

VALID_PICO_MODELS := RP2040 RP2350
RP2040_BUILD_DIR := build_rp2040
RP2350_BUILD_DIR := build_rp2350

CHIPID_FILENAME := .env/chipid
PICO_MODEL_FILENAME := .env/pico_model
INTERFACE_FILENAME := .env/interface

LOG_DIR := ./logs

CHIPID := $(shell cat ${CHIPID_FILENAME} 2>/dev/null)
PICO_MODEL := $(shell cat ${PICO_MODEL_FILENAME} 2>/dev/null)
INTERFACE := $(shell cat ${INTERFACE_FILENAME} 2>/dev/null)

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
	@INTERFACE=${INTERFACE}; \
	mkdir -p $(dir ${INTERFACE_FILENAME}); \
	echo "$$INTERFACE" > ${INTERFACE_FILENAME}; \
	echo "Interface [$$INTERFACE] saved to ${INTERFACE_FILENAME}"

set_board:
	@PICO_MODEL=${PICO_MODEL}; \
	mkdir -p $(dir ${PICO_MODEL_FILENAME}); \
	echo "$$PICO_MODEL" > ${PICO_MODEL_FILENAME}; \
	echo "Pico model [$$PICO_MODEL] saved to ${PICO_MODEL_FILENAME}"

get_sn:
	@CHIPID=$$(sudo picotool info -df | grep "chipid:" | awk '{print toupper(substr($$2, 3))'}); \
	mkdir -p $(dir ${CHIPID_FILENAME}); \
	echo "$$CHIPID" > ${CHIPID_FILENAME}; \
	echo "Chip ID [$$CHIPID] saved to ${CHIPID_FILENAME}"

build:
ifndef PICO_MODEL
	$(error PICO_MODEL is not set. Please run 'make build PICO_MODEL=['RP2040', 'RP2350']')
endif
ifeq (,$(filter $(PICO_MODEL), $(VALID_PICO_MODELS)))
	$(error PICO_MODEL is invalid. Please run 'make build PICO_MODEL=['RP2040', 'RP2350']')
endif

	@if [ ! -d "${CURRENT_BUILD_DIR}" ]; then \
		echo "Creating build directory '${CURRENT_BUILD_DIR}'"; \
		mkdir -p ${CURRENT_BUILD_DIR}; \
	fi
	@echo "${TAG} | Building project for ${PICO_MODEL}"
	@cd ${CURRENT_BUILD_DIR} && \
	cmake -DPICO_BOARD=${PICO_BOARD} ../ && \
	make --no-print-directory -j16 && \
	cd ../
	@echo "${TAG} | Build completed. Files at ${CURRENT_BUILD_DIR}"
	
flash:
ifndef PICO_MODEL
	$(error PICO_MODEL is not set. Please run 'make flash PICO_MODEL=['RP2040', 'RP2350']')
endif
ifeq (,$(filter $(PICO_MODEL), $(VALID_PICO_MODELS)))
	$(error PICO_MODEL is invalid. Please run 'make flash PICO_MODEL=['RP2040', 'RP2350']')
endif

ifeq (${CHIPID},)
	$(error CHIPID is not set. Run 'make get_sn' first)
endif
	@echo "${TAG} | Flashing to pico device ${CHIPID}"; \
	sudo picotool load ${CURRENT_BUILD_DIR}/main/${PROJECT_NAME}.uf2 -f --ser ${CHIPID}; \
	echo "${TAG} | Pico flashed"

monitor:
ifeq (${CHIPID},)
	$(error CHIPID is not set. Run 'make get_sn' first)
endif
ifeq (${INTERFACE},)
	$(error INTERFACE is not set. Run 'make set_interface INTERFACE=[/dev/*]' first)
endif
	@echo "${TAG} | Restarting $(PICO_MODEL)"; \
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

	@LATEST_LOG=$$(ls -t ${LOG_DIR}/pico_monitor_*.log 2>/dev/null | head -n 1); \
	if [ -z "$$LATEST_LOG" ]; then \
		echo "${TAG} | No logs found in ${LOG_DIR}"; \
		exit 1; \
	fi; \
	echo "${TAG} | Opening log file: $$LATEST_LOG"; \
	less -R $$LATEST_LOG
