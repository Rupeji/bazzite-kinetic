set fish_greeting

# Añadir binarios compartidos del sistema
fish_add_path "/usr/bin"

# Inicializar Starship Prompt nativo
if command -v starship > /dev/null
    starship init fish | source
end

# Alias útiles para gestionar Bazzite cómodamente

abbr -a "actualizar flatpak" 'flatpak update -y' # Actualiza únicamente los Flatpaks de forma manual si tienes prisa
abbr -a "limpieza" 'flatpak uninstall --unused -y && sudo rpm-ostree cleanup -m' # Limpieza profunda de residuos tanto de apps de usuario como del sistema de archivos atómico
abbr -a "actualizar sistema" 'sudo rpm-ostree upgrade' # Descarga y prepara la última versión de tu ISO de GitHub (requiere reiniciar para aplicar)

# Ejecutar Fastfetch al abrir la terminal si está instalado
if command -v fastfetch > /dev/null
    fastfetch
end
