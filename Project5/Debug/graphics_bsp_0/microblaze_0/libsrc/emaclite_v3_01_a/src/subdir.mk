################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../graphics_bsp_0/microblaze_0/libsrc/emaclite_v3_01_a/src/xemaclite.c \
../graphics_bsp_0/microblaze_0/libsrc/emaclite_v3_01_a/src/xemaclite_g.c \
../graphics_bsp_0/microblaze_0/libsrc/emaclite_v3_01_a/src/xemaclite_intr.c \
../graphics_bsp_0/microblaze_0/libsrc/emaclite_v3_01_a/src/xemaclite_l.c \
../graphics_bsp_0/microblaze_0/libsrc/emaclite_v3_01_a/src/xemaclite_selftest.c \
../graphics_bsp_0/microblaze_0/libsrc/emaclite_v3_01_a/src/xemaclite_sinit.c 

OBJS += \
./graphics_bsp_0/microblaze_0/libsrc/emaclite_v3_01_a/src/xemaclite.o \
./graphics_bsp_0/microblaze_0/libsrc/emaclite_v3_01_a/src/xemaclite_g.o \
./graphics_bsp_0/microblaze_0/libsrc/emaclite_v3_01_a/src/xemaclite_intr.o \
./graphics_bsp_0/microblaze_0/libsrc/emaclite_v3_01_a/src/xemaclite_l.o \
./graphics_bsp_0/microblaze_0/libsrc/emaclite_v3_01_a/src/xemaclite_selftest.o \
./graphics_bsp_0/microblaze_0/libsrc/emaclite_v3_01_a/src/xemaclite_sinit.o 

C_DEPS += \
./graphics_bsp_0/microblaze_0/libsrc/emaclite_v3_01_a/src/xemaclite.d \
./graphics_bsp_0/microblaze_0/libsrc/emaclite_v3_01_a/src/xemaclite_g.d \
./graphics_bsp_0/microblaze_0/libsrc/emaclite_v3_01_a/src/xemaclite_intr.d \
./graphics_bsp_0/microblaze_0/libsrc/emaclite_v3_01_a/src/xemaclite_l.d \
./graphics_bsp_0/microblaze_0/libsrc/emaclite_v3_01_a/src/xemaclite_selftest.d \
./graphics_bsp_0/microblaze_0/libsrc/emaclite_v3_01_a/src/xemaclite_sinit.d 


# Each subdirectory must supply rules for building sources it contributes
graphics_bsp_0/microblaze_0/libsrc/emaclite_v3_01_a/src/%.o: ../graphics_bsp_0/microblaze_0/libsrc/emaclite_v3_01_a/src/%.c
	@echo Building file: $<
	@echo Invoking: MicroBlaze gcc compiler
	mb-gcc -Wall -O0 -g3 -c -fmessage-length=0 -IC:/graphics_application_bsp_0/microblaze_0/include -mxl-barrel-shift -mxl-pattern-compare -mcpu=v8.10.a -mno-xl-soft-mul -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo Finished building: $<
	@echo ' '


