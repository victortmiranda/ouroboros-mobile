#include <flutter_inappwebview_linux/flutter_inappwebview_linux_plugin.h>
// ... (outros includes que já existam no seu main.cc)

// ... (outras funções que já existam no seu main.cc)

// Esta é a função onde você deve adicionar o registro do plugin.
// Se ela já existir no seu main.cc, adicione apenas o bloco 'if' dentro dela.
// Se não existir, você pode copiar e colar esta função inteira.
void flutter_plugins_register_with_registrar_for_plugin(
    flutter::PluginRegistrar* registrar,
    const char* plugin_name) {
  // ... (outros registros de plugins que já existam aqui)

  if (std::strcmp(plugin_name, "flutter_inappwebview_linux") == 0) {
    flutter_inappwebview_linux_plugin_register_with_registrar(registrar);
  }
}
