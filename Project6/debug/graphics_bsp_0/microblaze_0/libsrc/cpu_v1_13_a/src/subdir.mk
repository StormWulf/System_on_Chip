################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../graphics_bsp_0/microblaze_0/libsrc/cpu_v1_13_a/src/xio.c 

OBJS += \
./graphics_bsp_0/microblaze_0/libsrc/cpu_v1_13_a/src/xio.o 

C_DEPS += \
./graphics_bsp_0/microblaze_0/libsrc/cpu_v1_13_a/src/xio.d 


# Each subdirectory must supply rules for building sources it contributes
graphics_bsp_0/microblaze_0/libsrc/cpu_v1_13_a/src/%.o: ../graphics_bsp_0/microblaze_0/libsrc/cpu_v1_13_a/src/%.c
	@echo Building file: $<
	@echo Invoking: MicroBlaze gcc compiler
	mb-gcc -Wall -O0 -g3 -c -fmessage-length=0 -IC:/graphics_application_bsp_0/microblaze_0/include -mxl-barrel-shift -mxl-pattern-compare -mcpu=v8.10.a -mno-xl-soft-mul -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo Finished building: $<
	@echo ' '


