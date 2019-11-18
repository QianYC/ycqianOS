# ycqianOS
write my os

# how to run

```make```

# milestone

### 2019/11/18

FAT12+1.44M fd, finish boot code, now booter can load loader.

# bug fix

1. It seems like bximage doesn't format the boot.img correctly, this will cause booter fail to read the FAT entry. To fix this problem, use hexedit to edit the first 3 bytes of the 2nd sector. 

```0xf0 0xff 0xff```
