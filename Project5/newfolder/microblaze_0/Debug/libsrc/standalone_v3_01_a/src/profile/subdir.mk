################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../libsrc/standalone_v3_01_a/src/profile/_profile_clean.c \
../libsrc/standalone_v3_01_a/src/profile/_profile_init.c \
../libsrc/standalone_v3_01_a/src/profile/_profile_timer_hw.c \
../libsrc/standalone_v3_01_a/src/profile/profile_cg.c \
../libsrc/standalone_v3_01_a/src/profile/profile_hist.c 

S_UPPER_SRCS += \
../libsrc/standalone_v3_01_a/src/profile/dummy.S \
../libsrc/standalone_v3_01_a/src/profile/profile_mcount_mb.S \
../libsrc/standalone_v3_01_a/src/profile/profile_mcount_ppc.S 

OBJS += \
./libsrc/standalone_v3_01_a/src/profile/_profile_clean.o \
./libsrc/standalone_v3_01_a/src/profile/_profile_init.o \
./libsrc/standalone_v3_01_a/src/profile/_profile_timer_hw.o \
./libsrc/standalone_v3_01_a/src/profile/dummy.o \
./libsrc/standalone_v3_01_a/src/profile/profile_cg.o \
./libsrc/standalone_v3_01_a/src/profile/profile_hist.o \
./libsrc/standalone_v3_01_a/src/profile/profile_mcount_mb.o \
./libsrc/standalone_v3_01_a/src/profile/profile_mcount_ppc.o 

C_DEPS += \
./libsrc/standalone_v3_01_a/src/profile/_profile_clean.d \
./libsrc/standalone_v3_01_a/src/profile/_profile_init.d \
./libsrc/standalone_v3_01_a/src/profile/_profile_timer_hw.d \
./libsrc/standalone_v3_01_a/src/profile/profile_cg.d \
./libsrc/standalone_v3_01_a/src/profile/profile_hist.d 

S_UPPER_DEPS += \
./libsrc/standalone_v3_01_a/src/profile/dummy.d \
./libsrc/standalone_v3_01_a/src/profile/profile_mcount_mb.d \
./libsrc/standalone_v3_01_a/src/profile/profile_mcount_ppc.d 


# Each subdirectory must supply rules for building sources it contributes
libsrc/standalone_v3_01_a/src/profile/%.o: ../libsrc/standalone_v3_01_a/src/profile/%.c
	@echo Building file: $<
	@echo Invoking: MicroBlaze gcc compiler
	mb-gcc -Wall -O0 -g3 -c -fmessage-length=0 -IC:/Users/Jeff/Documents/GitHub/System_on_Chip/Project5/newfolder/microblaze_0/include -mxl-barrel-shift -mxl-pattern-compare -mcpu=v8.10.a -mno-xl-soft-mul -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo Finished building: $<
	@echo ' '

libsrc/standalone_v3_01_a/src/profile/%.o: ../libsrc/standalone_v3_01_a/src/profile/%.S
	@echo Building file: $<
	@echo Invoking: MicroBlaze gcc compiler
	mb-gcc -Wall -O0 -g3 -c -fmessage-length=0 -IC:/Users/Jeff/Documents/GitHub/System_on_Chip/Project5/newfolder/microblaze_0/include -mxl-barrel-shift -mxl-pattern-compare -mcpu=v8.10.a -mno-xl-soft-mul -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo Finished building: $<
	@echo ' '


