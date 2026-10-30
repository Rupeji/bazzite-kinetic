set fish_greeting

# Añadir binarios compartidos del sistema
fish_add_path "/usr/bin"

# Inicializar Starship Prompt nativo
if command -v starship > /dev/null
    starship init fish | source
end

# Alias útiles para gestionar Bazzite cómodamente

abbr -a "actualizar flatpak" 'flatpak update -y'
abbr -a "limpieza" 'flatpak uninstall --unused -y && sudo rpm-ostree cleanup -m'
abbr -a "actualizar sistema" 'sudo rpm-ostree upgrade && flatpak update -y'

# Ejecutar Fastfetch al abrir la terminal si está instalado
if command -v fastfetch > /dev/null
    fastfetch
end
