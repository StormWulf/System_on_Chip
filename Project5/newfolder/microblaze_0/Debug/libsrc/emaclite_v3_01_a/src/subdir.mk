################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../libsrc/emaclite_v3_01_a/src/xemaclite.c \
../libsrc/emaclite_v3_01_a/src/xemaclite_g.c \
../libsrc/emaclite_v3_01_a/src/xemaclite_intr.c \
../libsrc/emaclite_v3_01_a/src/xemaclite_l.c \
../libsrc/emaclite_v3_01_a/src/xemaclite_selftest.c \
../libsrc/emaclite_v3_01_a/src/xemaclite_sinit.c 

OBJS += \
./libsrc/emaclite_v3_01_a/src/xemaclite.o \
./libsrc/emaclite_v3_01_a/src/xemaclite_g.o \
./libsrc/emaclite_v3_01_a/src/xemaclite_intr.o \
./libsrc/emaclite_v3_01_a/src/xemaclite_l.o \
./libsrc/emaclite_v3_01_a/src/xemaclite_selftest.o \
./libsrc/emaclite_v3_01_a/src/xemaclite_sinit.o 

C_DEPS += \
./libsrc/emaclite_v3_01_a/src/xemaclite.d \
./libsrc/emaclite_v3_01_a/src/xemaclite_g.d \
./libsrc/emaclite_v3_01_a/src/xemaclite_intr.d \
./libsrc/emaclite_v3_01_a/src/xemaclite_l.d \
./libsrc/emaclite_v3_01_a/src/xemaclite_selftest.d \
./libsrc/emaclite_v3_01_a/src/xemaclite_sinit.d 


# Each subdirectory must supply rules for building sources it contributes
libsrc/emaclite_v3_01_a/src/%.o: ../libsrc/emaclite_v3_01_a/src/%.c
	@echo Building file: $<
	@echo Invoking: MicroBlaze gcc compiler
	mb-gcc -Wall -O0 -g3 -c -fmessage-length=0 -IC:/Users/Jeff/Documents/GitHub/System_on_Chip/Project5/newfolder/microblaze_0/include -mxl-barrel-shift -mxl-pattern-compare -mcpu=v8.10.a -mno-xl-soft-mul -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo Finished building: $<
	@echo ' '


