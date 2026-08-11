# Windows Instructions

## Requirements

Windows Server 2016+
cygwin with bash git autoconf make cmake zip unzip cpio mc
Visual Studio 2022
[LLVM/Clang 64bit](https://releases.llvm.org/7.0.0/LLVM-7.0.0-win64.exe) or [LLVM/Clang 32bit](https://releases.llvm.org/7.0.0/LLVM-7.0.0-win32.exe)
[NASM Assembler v2.15.05 or newer](https://www.nasm.us/pub/nasm/releasebuilds/?C=M;O=D)
Bootstrap JDK as `${HOME}/dev/tools/openjdkXXX`

## Installation & Setup

Put LLVM & NASM to `%PATH%`

Download installer as unprivileged user:

```sh
curl -L "https://aka.ms/vs/17/release/vs_BuildTools.exe" -o vs_BuildTools_2022.exe && chmod +x vs_BuildTools_2022.exe
```

As administrator:

```sh
./vs_BuildTools_2022.exe --includeRecommended --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Runtimes.x86.x64.Spectre --add Microsoft.VisualStudio.Component.VC.v141.x86.x64 --add Microsoft.VisualStudio.Component.VC.v141.x86.x64.Spectre
```

```sh
export INCLUDE='C:\Program Files\Microsoft Visual Studio\2022\Community\DIA SDK\include'
```

```sh
regsvr32 "C:\Program Files\Microsoft Visual Studio\2022\Community\DIA SDK\bin\msdia140.dll"
regsvr32 "C:\Program Files\Microsoft Visual Studio\2022\Community\DIA SDK\bin\amd64\msdia140.dll"
```
