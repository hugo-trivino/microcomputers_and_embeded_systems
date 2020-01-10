# Welcome!
## To the microcomputers and embedded systems repository.


In this folder you will find the implementation of a monitor program that will be used as a tool for programming and troubleshooting applications written for the MC68000 family of microprocessors. This implementation consist of a shell written in assembly language that supports fourteen different debugging commands and it has the ability to handle the most common types of exceptions.


This program can be run in [Easy68k Simulator](http://www.easy68k.com/)

To see full description of the implementation please refer to the **Project_Report.pdf** file.


## List of commands and their basic description
**| Name | Description | Usage | Example |**
--- | --- | --- | ---
|HELP| Display this table| `HELP` | `HELP`|
--- | --- | --- | ---
|BF | Fill memory range with word data | `BF <Addr1> <Addr2> <W>` | `BF 800 900 4848`|
--- | --- | --- | ---
|BMOV| Move range of memory to location | `BMOV<Addr1> <Addr2> <Dest>` | `BMOV 700 800 850`|
--- | --- | --- | ---
|BSCH| Return first match for string in memory range | `BSCH <Addr1> <addr2> <Str>` | `BSCH 800 900 'hi'`| 
--- | --- | --- | ---
|BTST| Destructive R/W test in memory range| `BTST <Addr1> <Addr2>` | `BTST 800 950`|
--- | --- | --- | ---
|DF| Display values in reg: PC,SR,US,SP,D,A| `DF` | `DF` |
--- | --- | --- | ---
|GO| Start Execution at given address | `GO <target addr>` | `GO 900`|
--- | --- | --- | ---
|MDSP| Output Address and Memory Contents |`MDSP <Addr1> <Addr2>` | MDSP 900 9D2|
--- | --- | --- | ---
|MM | Modify memory manually ,default size byte | `MM <addr>;<sz>` | `MM 700`|
|   |    |   |`MM 700;W`|
--- | --- | --- | ---
|MS | Write bytes in memory in Hex or ASCII |`MS <addr> <data>` |`MS 600 ',$27,'hi',$27,`|
|   |    |   |`MS 600 35C`|
--- | --- | --- | ---
|SORTW| Sort words in asc or desc order (A or D) in mem range | `SORTW <addr1> <addr2> <ord>` | `SORTW 600 600 D `|
--- | --- | --- | ---
|EXIT| Terminates Monitor Program|`EXIT` | `EXIT|`    
--- | --- | --- | ---

