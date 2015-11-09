################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include subdir.mk
-include objects.mk

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
ifneq ($(strip $(S_UPPER_DEPS)),)
-include $(S_UPPER_DEPS)
endif
endif

-include ../makefile.defs

# Add inputs and outputs from these tool invocations to the build variables 
ELFSIZE += \
Lab_5_0.elf.size \

ELFCHECK += \
Lab_5_0.elf.elfcheck \


# All Target
all: Lab_5_0.elf secondary-outputs

# Tool invocations
Lab_5_0.elf: $(OBJS) ../src/lscript.ld $(USER_OBJS)
	@echo Building target: $@
	@echo Invoking: MicroBlaze gcc linker
	mb-gcc -Wl,-T -Wl,../src/lscript.ld -LC:/Users/wputn1/Desktop/Project5/graphics_bsp_0/microblaze_0/lib -mxl-barrel-shift -mxl-pattern-compare -mcpu=v8.10.a -mno-xl-soft-mul -o"Lab_5_0.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo Finished building target: $@
	@echo ' '

Lab_5_0.elf.size: Lab_5_0.elf
	@echo Invoking: MicroBlaze Print Size
	mb-size Lab_5_0.elf  |tee "Lab_5_0.elf.size"
	@echo Finished building: $@
	@echo ' '

Lab_5_0.elf.elfcheck: Lab_5_0.elf
	@echo Invoking: Xilinx ELF Check
	elfcheck Lab_5_0.elf -hw C:/Users/wputn1/Desktop/Project5/hw_platform_0/system.xml -pe microblaze_0  |tee "Lab_5_0.elf.elfcheck"
	@echo Finished building: $@
	@echo ' '

# Other Targets
clean:
	-$(RM) $(OBJS)$(C_DEPS)$(EXECUTABLES)$(ELFSIZE)$(ELFCHECK)$(S_UPPER_DEPS) Lab_5_0.elf
	-@echo ' '

secondary-outputs: $(ELFSIZE) $(ELFCHECK)

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
