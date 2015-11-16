################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/xtmrctr.c \
../graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/xtmrctr_g.c \
../graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/xtmrctr_intr.c \
../graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/xtmrctr_l.c \
../graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/xtmrctr_options.c \
../graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/xtmrctr_selftest.c \
../graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/xtmrctr_stats.c 

OBJS += \
./graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/xtmrctr.o \
./graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/xtmrctr_g.o \
./graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/xtmrctr_intr.o \
./graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/xtmrctr_l.o \
./graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/xtmrctr_options.o \
./graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/xtmrctr_selftest.o \
./graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/xtmrctr_stats.o 

C_DEPS += \
./graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/xtmrctr.d \
./graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/xtmrctr_g.d \
./graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/xtmrctr_intr.d \
./graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/xtmrctr_l.d \
./graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/xtmrctr_options.d \
./graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/xtmrctr_selftest.d \
./graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/xtmrctr_stats.d 


# Each subdirectory must supply rules for building sources it contributes
graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/%.o: ../graphics_bsp_0/microblaze_0/libsrc/tmrctr_v2_03_a/src/%.c
	@echo Building file: $<
	@echo Invoking: MicroBlaze gcc compiler
	mb-gcc -Wall -O0 -g3 -c -fmessage-length=0 -IC:/graphics_application_bsp_0/microblaze_0/include -mxl-barrel-shift -mxl-pattern-compare -mcpu=v8.10.a -mno-xl-soft-mul -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo Finished building: $<
	@echo ' '


