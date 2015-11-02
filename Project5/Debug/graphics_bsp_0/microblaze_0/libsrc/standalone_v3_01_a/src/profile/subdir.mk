################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/_profile_clean.c \
../graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/_profile_init.c \
../graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/_profile_timer_hw.c \
../graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/profile_cg.c \
../graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/profile_hist.c 

S_UPPER_SRCS += \
../graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/dummy.S \
../graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/profile_mcount_mb.S \
../graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/profile_mcount_ppc.S 

OBJS += \
./graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/_profile_clean.o \
./graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/_profile_init.o \
./graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/_profile_timer_hw.o \
./graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/dummy.o \
./graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/profile_cg.o \
./graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/profile_hist.o \
./graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/profile_mcount_mb.o \
./graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/profile_mcount_ppc.o 

C_DEPS += \
./graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/_profile_clean.d \
./graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/_profile_init.d \
./graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/_profile_timer_hw.d \
./graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/profile_cg.d \
./graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/profile_hist.d 

S_UPPER_DEPS += \
./graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/dummy.d \
./graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/profile_mcount_mb.d \
./graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/profile_mcount_ppc.d 


# Each subdirectory must supply rules for building sources it contributes
graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/%.o: ../graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/%.c
	@echo Building file: $<
	@echo Invoking: MicroBlaze gcc compiler
	mb-gcc -Wall -O0 -g3 -c -fmessage-length=0 -IC:/graphics_application_bsp_0/microblaze_0/include -mxl-barrel-shift -mxl-pattern-compare -mcpu=v8.10.a -mno-xl-soft-mul -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo Finished building: $<
	@echo ' '

graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/%.o: ../graphics_bsp_0/microblaze_0/libsrc/standalone_v3_01_a/src/profile/%.S
	@echo Building file: $<
	@echo Invoking: MicroBlaze gcc compiler
	mb-gcc -Wall -O0 -g3 -c -fmessage-length=0 -IC:/graphics_application_bsp_0/microblaze_0/include -mxl-barrel-shift -mxl-pattern-compare -mcpu=v8.10.a -mno-xl-soft-mul -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo Finished building: $<
	@echo ' '


