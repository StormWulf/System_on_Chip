################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../graphics_bsp_0/microblaze_0/libsrc/gpio_v3_00_a/src/xgpio.c \
../graphics_bsp_0/microblaze_0/libsrc/gpio_v3_00_a/src/xgpio_extra.c \
../graphics_bsp_0/microblaze_0/libsrc/gpio_v3_00_a/src/xgpio_g.c \
../graphics_bsp_0/microblaze_0/libsrc/gpio_v3_00_a/src/xgpio_intr.c \
../graphics_bsp_0/microblaze_0/libsrc/gpio_v3_00_a/src/xgpio_selftest.c \
../graphics_bsp_0/microblaze_0/libsrc/gpio_v3_00_a/src/xgpio_sinit.c 

OBJS += \
./graphics_bsp_0/microblaze_0/libsrc/gpio_v3_00_a/src/xgpio.o \
./graphics_bsp_0/microblaze_0/libsrc/gpio_v3_00_a/src/xgpio_extra.o \
./graphics_bsp_0/microblaze_0/libsrc/gpio_v3_00_a/src/xgpio_g.o \
./graphics_bsp_0/microblaze_0/libsrc/gpio_v3_00_a/src/xgpio_intr.o \
./graphics_bsp_0/microblaze_0/libsrc/gpio_v3_00_a/src/xgpio_selftest.o \
./graphics_bsp_0/microblaze_0/libsrc/gpio_v3_00_a/src/xgpio_sinit.o 

C_DEPS += \
./graphics_bsp_0/microblaze_0/libsrc/gpio_v3_00_a/src/xgpio.d \
./graphics_bsp_0/microblaze_0/libsrc/gpio_v3_00_a/src/xgpio_extra.d \
./graphics_bsp_0/microblaze_0/libsrc/gpio_v3_00_a/src/xgpio_g.d \
./graphics_bsp_0/microblaze_0/libsrc/gpio_v3_00_a/src/xgpio_intr.d \
./graphics_bsp_0/microblaze_0/libsrc/gpio_v3_00_a/src/xgpio_selftest.d \
./graphics_bsp_0/microblaze_0/libsrc/gpio_v3_00_a/src/xgpio_sinit.d 


# Each subdirectory must supply rules for building sources it contributes
graphics_bsp_0/microblaze_0/libsrc/gpio_v3_00_a/src/%.o: ../graphics_bsp_0/microblaze_0/libsrc/gpio_v3_00_a/src/%.c
	@echo Building file: $<
	@echo Invoking: MicroBlaze gcc compiler
	mb-gcc -Wall -O0 -g3 -c -fmessage-length=0 -IC:/graphics_application_bsp_0/microblaze_0/include -mxl-barrel-shift -mxl-pattern-compare -mcpu=v8.10.a -mno-xl-soft-mul -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo Finished building: $<
	@echo ' '


