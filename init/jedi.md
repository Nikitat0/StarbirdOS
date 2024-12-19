# JEDI v0

JEDI stands for "Jedi's executable and linkable image".

## Header

| Value                                          | Offset |
| ---------------------------------------------- | ------ |
| magic number 0x6964656a (ASCII-endoded "jedi") | 0x0    |
| version number, should be zero                 | 0x4    |
| page size of .text section                     | 0x8    |
| page size of .rodata section                   | 0x10   |
| page size of .data section                     | 0x18   |
| page size of .bss section                      | 0x20   |
