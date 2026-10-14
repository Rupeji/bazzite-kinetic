set fish_greeting

# Añadir binarios compartidos del sistema
fish_add_path "/usr/bin"

# Inicializar Starship Prompt nativo
if command -v starship > /dev/null
    starship init fish | source
end

# Alias útiles para gestionar Bazzite cómodamente
alias ll='ls -lh --color=auto'
alias la='ls -lha --color=auto'
alias ..='cd ..'
alias bazzite-update='sudo bootc upgrade'
alias layered-apps='rpm-ostree status'

# Ejecutar Fastfetch al abrir la terminal si está instalado
if command -v fastfetch > /dev/null
    fastfetch
end
