################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../graphics_bsp_0/microblaze_0/libsrc/mpmc_v4_01_a/src/xmpmc.c \
../graphics_bsp_0/microblaze_0/libsrc/mpmc_v4_01_a/src/xmpmc_g.c \
../graphics_bsp_0/microblaze_0/libsrc/mpmc_v4_01_a/src/xmpmc_intr.c \
../graphics_bsp_0/microblaze_0/libsrc/mpmc_v4_01_a/src/xmpmc_selftest.c \
../graphics_bsp_0/microblaze_0/libsrc/mpmc_v4_01_a/src/xmpmc_sinit.c \
../graphics_bsp_0/microblaze_0/libsrc/mpmc_v4_01_a/src/xmpmc_stats.c 

OBJS += \
./graphics_bsp_0/microblaze_0/libsrc/mpmc_v4_01_a/src/xmpmc.o \
./graphics_bsp_0/microblaze_0/libsrc/mpmc_v4_01_a/src/xmpmc_g.o \
./graphics_bsp_0/microblaze_0/libsrc/mpmc_v4_01_a/src/xmpmc_intr.o \
./graphics_bsp_0/microblaze_0/libsrc/mpmc_v4_01_a/src/xmpmc_selftest.o \
./graphics_bsp_0/microblaze_0/libsrc/mpmc_v4_01_a/src/xmpmc_sinit.o \
./graphics_bsp_0/microblaze_0/libsrc/mpmc_v4_01_a/src/xmpmc_stats.o 

C_DEPS += \
./graphics_bsp_0/microblaze_0/libsrc/mpmc_v4_01_a/src/xmpmc.d \
./graphics_bsp_0/microblaze_0/libsrc/mpmc_v4_01_a/src/xmpmc_g.d \
./graphics_bsp_0/microblaze_0/libsrc/mpmc_v4_01_a/src/xmpmc_intr.d \
./graphics_bsp_0/microblaze_0/libsrc/mpmc_v4_01_a/src/xmpmc_selftest.d \
./graphics_bsp_0/microblaze_0/libsrc/mpmc_v4_01_a/src/xmpmc_sinit.d \
./graphics_bsp_0/microblaze_0/libsrc/mpmc_v4_01_a/src/xmpmc_stats.d 


# Each subdirectory must supply rules for building sources it contributes
graphics_bsp_0/microblaze_0/libsrc/mpmc_v4_01_a/src/%.o: ../graphics_bsp_0/microblaze_0/libsrc/mpmc_v4_01_a/src/%.c
	@echo Building file: $<
	@echo Invoking: MicroBlaze gcc compiler
	mb-gcc -Wall -O0 -g3 -c -fmessage-length=0 -IC:/graphics_application_bsp_0/microblaze_0/include -mxl-barrel-shift -mxl-pattern-compare -mcpu=v8.10.a -mno-xl-soft-mul -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo Finished building: $<
	@echo ' '

