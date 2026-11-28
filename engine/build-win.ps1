# llama.cpp with RedGiant's patches for Windows and NVIDIA cards (G32.2), as release.yml's job
# llama-cuda runs it: clone at $env:LLAMA_BUILD, apply.ps1, CUDA build with MSVC and Ninja, the zip
# with CUDA's and Visual C++'s libraries next to the program. Part of the engine's fingerprint
# (engine/fingerprint.sh): changing a command here means a new build at the next release (comments
# and the build.txt label do not).
# Needs: a Visual C++ developer shell (ilammy/msvc-dev-cmd), Ninja, sccache, CUDA in $env:CUDA_DIR.
# Env: LLAMA_BUILD, CUDA_DIR, CUDA_VERSION, CUDA_ARCHS, ZIP (the zip's path).
param(
  # Extra nvcc flags (-allow-unsupported-compiler when no Visual C++ CUDA accepts is installed).
  [string]$CudaFlags = ""
)
$ErrorActionPreference = "Stop"

git clone --depth 1 --branch $env:LLAMA_BUILD https://github.com/ggml-org/llama.cpp llama
if ($LASTEXITCODE -ne 0) { exit 1 }
Push-Location llama
& "$PSScriptRoot/llama-patches/apply.ps1"

$env:CUDA_PATH = $env:CUDA_DIR
$env:PATH = "$env:CUDA_DIR\bin;$env:PATH"
cl 2>&1 | Select-Object -First 1
nvcc --version
# The compiler cache when it is there (choco installs it; once it was missing and the build stopped here).
$cache = Get-Command sccache -ErrorAction SilentlyContinue
$launch = @()
if ($cache) {
  sccache --start-server
  $launch = @("-DCMAKE_C_COMPILER_LAUNCHER=sccache", "-DCMAKE_CXX_COMPILER_LAUNCHER=sccache", "-DCMAKE_CUDA_COMPILER_LAUNCHER=sccache")
} else {
  Write-Host "sccache not found: building without the compiler cache"
}
# Without llama.cpp's own web UI (Rasgeth never serves it): no download from Hugging Face while
# building. The shallow clone has no history, so the build number comes from the tag (else it is 1).
cmake -S . -B build -G Ninja `
  -DCMAKE_BUILD_TYPE=Release `
  @launch `
  -DCMAKE_CUDA_COMPILER="$env:CUDA_DIR/bin/nvcc.exe" -DCUDAToolkit_ROOT="$env:CUDA_DIR" `
  -DCMAKE_CUDA_ARCHITECTURES="$env:CUDA_ARCHS" -DCMAKE_CUDA_FLAGS="$CudaFlags" `
  -DGGML_CUDA=ON -DGGML_NATIVE=OFF -DGGML_BACKEND_DL=ON -DGGML_CPU_ALL_VARIANTS=ON `
  -DLLAMA_CURL=OFF -DLLAMA_OPENSSL=OFF -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF -DLLAMA_BUILD_SERVER=ON `
  -DLLAMA_BUILD_UI=OFF -DLLAMA_USE_PREBUILT_UI=OFF -DLLAMA_BUILD_NUMBER="$($env:LLAMA_BUILD.TrimStart('b'))"
if ($LASTEXITCODE -ne 0) { exit 1 }
# Everything: with GGML_BACKEND_DL the CUDA and CPU backends are modules llama-server loads.
cmake --build build --config Release -j $env:NUMBER_OF_PROCESSORS
if ($LASTEXITCODE -ne 0) { exit 1 }
if ($cache) { sccache --show-stats }
Pop-Location

# The zip, with CUDA's and Visual C++'s libraries next to the program.
$out = New-Item -ItemType Directory -Force pack
Copy-Item llama/build/bin/llama-server.exe, llama/build/bin/*.dll $out
Copy-Item "$env:CUDA_DIR/bin/cudart64_12.dll", "$env:CUDA_DIR/bin/cublas64_12.dll", "$env:CUDA_DIR/bin/cublasLt64_12.dll" $out
# The Visual C++ runtime and OpenMP, so it runs where they are not installed.
$redist = Get-ChildItem "$env:VCToolsRedistDir/x64" -Directory | Where-Object { $_.Name -like "Microsoft.VC*.CRT" -or $_.Name -like "Microsoft.VC*.OpenMP" }
foreach ($d in $redist) { Copy-Item "$($d.FullName)/*.dll" $out }
Set-Content "$out/build.txt" "$env:LLAMA_BUILD + Rasgeth patches (0001 teal, 0002 moe-prefetch, 0003 kv-host), CUDA $env:CUDA_VERSION, $env:CUDA_ARCHS"
foreach ($f in "llama-server.exe", "llama.dll", "ggml.dll", "ggml-base.dll", "ggml-cuda.dll", "cudart64_12.dll", "cublas64_12.dll", "cublasLt64_12.dll") {
  if (-not (Test-Path "$out/$f")) { throw "$f is missing" }
}
if (-not (Get-ChildItem "$out/ggml-cpu*.dll")) { throw "no ggml-cpu backend" }
# No card here: it must start and say its version all the same.
& "$out/llama-server.exe" --version
if ($LASTEXITCODE -ne 0) { exit 1 }
Compress-Archive -Path "$out/*" -DestinationPath $env:ZIP -CompressionLevel Optimal
Get-ChildItem $out | Sort-Object Length -Descending | Format-Table Name, @{ n = "MB"; e = { [math]::Round($_.Length / 1MB, 1) } }
"{0:N0} MB zipped" -f ((Get-Item $env:ZIP).Length / 1MB)
(Get-FileHash -Algorithm SHA256 $env:ZIP).Hash
