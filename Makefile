 ifndef BUILD_DIR
 BUILD_DIR=build
 endif

CC = gcc
CFLAGS = -m32 -ffreestanding -O2 -Wall -Wextra
CCFLAGS = $(CFLAGS) -std=c++20

$(BUILD_DIR)/%.o : kernel/%.cc
	$(CC)  -c $^ -o $@ $(CCFLAGS)

$(BUILD_DIR)/boot.o : x86/boot.s
	as --32 x86/boot.s -o $(BUILD_DIR)/boot.o

$(BUILD_DIR)/kernel : linker.ld $(BUILD_DIR)/boot.o $(BUILD_DIR)/kernel.o $(BUILD_DIR)/video.o 
	ld -m elf_i386 -T linker.ld $(BUILD_DIR)/kernel.o $(BUILD_DIR)/boot.o -o $(BUILD_DIR)/kernel -nostdlib
	grub-file --is-x86-multiboot $(BUILD_DIR)/kernel

$(BUILD_DIR)/Meta-SO.iso : $(BUILD_DIR)/kernel
	mkdir -p $(BUILD_DIR)/isodir/boot/grub
	cp $(BUILD_DIR)/kernel $(BUILD_DIR)/isodir/boot/
	cp grub.cfg $(BUILD_DIR)/isodir/boot/grub/grub.cfg
	grub-mkrescue -o $(BUILD_DIR)/Meta-SO.iso $(BUILD_DIR)/isodir

run : $(BUILD_DIR)/Meta-SO.iso
	qemu-system-x86_64 -cdrom $(BUILD_DIR)/Meta-SO.iso
	
build : $(BUILD_DIR)/kernel

.PHONY:  clean

clean :
	rm -r $(BUILD_DIR)/*
