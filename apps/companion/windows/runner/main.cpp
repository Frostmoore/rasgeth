#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <shlobj.h>
#include <windows.h>

#include <filesystem>
#include <string>
#include <system_error>

#include "flutter_window.h"
#include "utils.h"

namespace {

// The app's own folder (path_provider's application support: %APPDATA%\<CompanyName>\<ProductName>
// from Runner.rc) moved with the name, RedGiant\RGCompanion before 3.9.0 and Rasgeth\Rasgeth now.
// At the first start under the new name the old folder (pairing, settings, the secure storage,
// which DPAPI ties to the user, not to the folder) is copied over, once, when the new one is not
// there yet; the old one stays as it was. From 3.9.8 the app itself also reads the old folder once
// (lib/api/legacy_data.dart): keystore entries and servers the new one lacks are carried over, and
// only the old keystore file is removed, after every entry was written anew and read back.
void CarryOldAppData() {
  PWSTR roaming = nullptr;
  if (FAILED(::SHGetKnownFolderPath(FOLDERID_RoamingAppData, 0, nullptr, &roaming))) return;
  const std::filesystem::path base(roaming);
  ::CoTaskMemFree(roaming);
  const auto from = base / L"RedGiant" / L"RGCompanion";
  const auto to = base / L"Rasgeth" / L"Rasgeth";
  std::error_code e;
  if (std::filesystem::exists(to, e) || !std::filesystem::is_directory(from, e)) return;
  const auto part = base / L"Rasgeth" / L"Rasgeth.part";
  std::filesystem::remove_all(part, e);
  std::filesystem::create_directories(part, e);
  std::filesystem::copy(from, part, std::filesystem::copy_options::recursive, e);
  if (e) {
    std::filesystem::remove_all(part, e);
    return;
  }
  std::filesystem::rename(part, to, e);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  CarryOldAppData();

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"Rasgeth", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
