# Makefile for nRF Connect SDK

TAG = "\\033[32\;1mMakefile\\033[0m"

# Variables
.PHONY: build

MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

NRF_CONNECT_BOARD_FILENAME := .env/nrf_connect_board
INTERFACE_FILENAME := .env/interface

LOG_DIR := ./logs
WEST_WORKSPACE_DIR := $(shell west topdir)

BOARD_NAME := $(shell cat ${NRF_CONNECT_BOARD_FILENAME} 2>/dev/null)
INTERFACE := $(shell cat ${INTERFACE_FILENAME} 2>/dev/null)

all: build flash monitor

set_interface:
	@set -e; \
	echo "${TAG} | List of available devices:"; \
	ls /dev/tty* | grep -E "ACM|USB"; \
	read -p "Enter interface: " INTERFACE_STR; \
	mkdir -p $(dir ${INTERFACE_FILENAME}); \
	echo "$$INTERFACE_STR" > ${INTERFACE_FILENAME}; \
	echo "${TAG} | Interface [$$INTERFACE_STR] saved to ${INTERFACE_FILENAME}"

set_board:
	@set -e; \
	echo "${TAG} | List of boards:"; \
	west boards | grep -i "nrf"; \
	read -p "Enter nRF Connect target: " NRF_CONNECT_BOARD; \
	echo "${TAG} | List of boards with qualifiers to select from:"; \
	find ${WEST_WORKSPACE_DIR}/zephyr/boards/nordic/$$NRF_CONNECT_BOARD/*.yaml | sed 's#.*/##' | sed 's/.yaml//' | sed 's/_/\//g'; \
	read -p "Enter nRF Connect target with qualifiers: " NRF_CONNECT_BOARD_WITH_QUALIFIERS; \
	mkdir -p $(dir ${NRF_CONNECT_BOARD_FILENAME}); \
	echo "$$NRF_CONNECT_BOARD_WITH_QUALIFIERS" > ${NRF_CONNECT_BOARD_FILENAME}; \
	echo "${TAG} | nRF Connect target [$$NRF_CONNECT_BOARD_WITH_QUALIFIERS] saved to ${NRF_CONNECT_BOARD_FILENAME}"

build:
	@set -e;
	@echo "${TAG} | Building project for ${BOARD_NAME}"
	west build -p always -b ${BOARD_NAME} app
	@echo "${TAG} | Build completed!"

flash:
	@set -e;
	west flash --erase;
	@echo "${TAG} | Flash completed!"

monitor:
	@set -e; \
	echo "${TAG} | Monitoring output"; \
	while [ ! -e "${INTERFACE}" ]; do sleep 0.2; done; \
	mkdir -p "${LOG_DIR}"; \
	LOG_FILE="nrf_monitor_$$(date +%Y%m%d_%H%M%S).log"; \
	script -q -c "minicom -D ${INTERFACE} -w -c on" "${LOG_DIR}/$$LOG_FILE"; \
	reset; \
	ls -1t "${LOG_DIR}"/pico_monitor_*.log | tail -n +6 | xargs -r rm --;

open_latest_log:
	@set -e \
	LATEST_LOG=$$(ls -t ${LOG_DIR}/pico_monitor_*.log 2>/dev/null | head -n 1); \
	if [ -z "$$LATEST_LOG" ]; then \
		echo "${TAG} | No logs found in ${LOG_DIR}"; \
		exit 1; \
	fi; \
	echo "${TAG} | Opening log file: $$LATEST_LOG"; \
	less -R $$LATEST_LOG
