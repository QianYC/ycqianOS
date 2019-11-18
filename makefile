run:myboot.bin boot.img bochsrc loader.bin
	dd if=myboot.bin of=boot.img bs=512 count=1 conv=notrunc
	sudo mount boot.img /media/yc_qian/ -t vfat -o loop
	sudo cp loader.bin	/media/yc_qian/
	sudo sync
	sudo umount /media/yc_qian/
	bochs -f bochsrc

myboot.bin:myboot.asm
	nasm myboot.asm -o myboot.bin

loader.bin:loader.asm
	nasm loader.asm -o loader.bin

clean:
	rm myboot.bin loader.bin
