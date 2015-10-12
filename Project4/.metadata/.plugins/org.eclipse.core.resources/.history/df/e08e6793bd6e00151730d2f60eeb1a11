################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include subdir.mk
-include src/subdir.mk
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
Project4.elf.size \

ELFCHECK += \
Project4.elf.elfcheck \


# All Target
all: Project4.elf secondary-outputs

# Tool invocations
Project4.elf: $(OBJS) ../src/lscript.ld $(USER_OBJS)
	@echo Building target: $@
	@echo Invoking: MicroBlaze gcc linker
	mb-gcc -Wl,-T -Wl,../src/lscript.ld -L../../Project4BSP/microblaze_0/lib -mxl-barrel-shift -mxl-pattern-compare -mcpu=v8.10.a -mno-xl-soft-mul -o"Project4.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo Finished building target: $@
	@echo ' '

Project4.elf.size: Project4.elf
	@echo Invoking: MicroBlaze Print Size
	mb-size Project4.elf  |tee "Project4.elf.size"
	@echo Finished building: $@
	@echo ' '

Project4.elf.elfcheck: Project4.elf
	@echo Invoking: Xilinx ELF Check
	elfcheck Project4.elf -hw ../../hw_platform_0/system.xml -pe microblaze_0  |tee "Project4.elf.elfcheck"
	@echo Finished building: $@
	@echo ' '

# Other Targets
clean:
	-$(RM) $(OBJS)$(C_DEPS)$(EXECUTABLES)$(ELFSIZE)$(ELFCHECK)$(S_UPPER_DEPS) Project4.elf
	-@echo ' '

secondary-outputs: $(ELFSIZE) $(ELFCHECK)

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
