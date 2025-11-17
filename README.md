# fw-make-files

Global make file repo for all projects being worked on

## USE

1. Store this repo anywhere acceptable on your machine
2. Add the FW_MAKE_FILE_PATH environment variable that points to the fw-make-file repo that you cloned
3. In whatever project you are working on, create a make file that has `include $(FW_MAKE_FILE_PATH)/[sub_path_if_applicable]/[makefile_name.mk]`
   - This can be a relative or absolute path
   - EX: `$(FW_MAKE_FILE_PATH)/pico_sdk/pico_sdk.mk`

It will work as if that make file exists at your project root!
