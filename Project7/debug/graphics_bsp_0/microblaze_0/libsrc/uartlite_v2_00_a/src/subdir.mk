################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/xuartlite.c \
../graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/xuartlite_g.c \
../graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/xuartlite_intr.c \
../graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/xuartlite_l.c \
../graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/xuartlite_selftest.c \
../graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/xuartlite_sinit.c \
../graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/xuartlite_stats.c 

OBJS += \
./graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/xuartlite.o \
./graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/xuartlite_g.o \
./graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/xuartlite_intr.o \
./graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/xuartlite_l.o \
./graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/xuartlite_selftest.o \
./graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/xuartlite_sinit.o \
./graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/xuartlite_stats.o 

C_DEPS += \
./graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/xuartlite.d \
./graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/xuartlite_g.d \
./graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/xuartlite_intr.d \
./graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/xuartlite_l.d \
./graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/xuartlite_selftest.d \
./graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/xuartlite_sinit.d \
./graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/xuartlite_stats.d 


# Each subdirectory must supply rules for building sources it contributes
graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/%.o: ../graphics_bsp_0/microblaze_0/libsrc/uartlite_v2_00_a/src/%.c
	@echo Building file: $<
	@echo Invoking: MicroBlaze gcc compiler
	mb-gcc -Wall -O0 -g3 -c -fmessage-length=0 -IC:/graphics_application_bsp_0/microblaze_0/include -mxl-barrel-shift -mxl-pattern-compare -mcpu=v8.10.a -mno-xl-soft-mul -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo Finished building: $<
	@echo ' '


