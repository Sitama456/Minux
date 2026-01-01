IMAGE_DIR := ./image
BUILD_DIR := ./build
SRC_DIR := ./src


# $@ 表示目标文件 $< 表示依赖文件
$(IMAGE_DIR)/master.img: $(BUILD_DIR)/boot.bin $(BUILD_DIR)/loader.bin
	$(shell mkdir -p $(dir $@))
	dd if=/dev/zero of=$@ bs=512 count=32768 conv=notrunc # 创建一个 16M 的硬盘镜像
	dd if=$(BUILD_DIR)/boot.bin of=$@ bs=512 count=1 conv=notrunc # 将 boot.bin 写入到主引导扇区
	dd if=$(BUILD_DIR)/loader.bin of=$@ bs=512 count=4 seek=2 conv=notrunc # 将 loader.bin 写入到主引导扇区，起始扇区为2，大小为4

# boot.bin
 $(BUILD_DIR)/boot.bin: $(SRC_DIR)/boot/boot.asm
	$(shell mkdir -p $(dir $@))
	nasm -f bin $< -o $@

# loader.bin
 $(BUILD_DIR)/loader.bin: $(SRC_DIR)/boot/loader.asm
	$(shell mkdir -p $(dir $@))
	nasm -f bin $< -o $@

./PHONY: qemu
qemu: $(IMAGE_DIR)/master.img
	qemu-system-i386 -m 2048M -drive file=$<,if=ide,index=0,media=disk,format=raw

.PHONY: clean
clean:
	rm -rf $(IMAGE_DIR)
	rm -rf $(BUILD_DIR)