# BRM5 PVE - Estructura Modular

Este documento explica la nueva estructura modular del script BRM5 PVE.

## Estructura de Archivos

```
brm5-pve/
├── main.lua              # Script principal
├── BRM5-PVE.lua         # Script original (legacy)
└── modules/
    ├── config.lua        # Configuración y constantes
    ├── services.lua      # Referencias a servicios de Roblox
    ├── npc_manager.lua   # Gestión de NPCs enemigos
    ├── target_sizing.lua # Ajuste de tamaño de objetivos
    ├── markers.lua       # Sistema de marcadores de visibilidad
    ├── lighting.lua      # Control de iluminación
    ├── weapons.lua       # Modificaciones de armas
    └── gui.lua           # Interfaz gráfica
```

## Descripción de Módulos

### 1. config.lua
Contiene todas las configuraciones, constantes y variables de estado del script:
- Tamaños de objetivos
- Estados de toggles (Marcadores, Tamaño, FullBright)
- Colores de marcadores (visible/oculto)
- Opciones de parches de armas

### 2. services.lua
Proporciona acceso centralizado a servicios de Roblox:
- Players, RunService, UserInputService
- Workspace, TweenService, ReplicatedStorage, Lighting
- Acceso rápido a localPlayer y camera

### 3. npc_manager.lua
Gestiona la detección y seguimiento de NPCs enemigos:
- Detecta NPCs con componentes AI
- Mantiene lista de NPCs activos
- Escanea workspace por NPCs existentes
- Configura listeners para NPCs nuevos

### 4. target_sizing.lua
Maneja el ajuste de tamaño de objetivos para precisión/visibilidad:
- Ajusta el tamaño de objetivos de NPCs
- Almacena tamaños originales
- Restaura tamaños al desactivar
- Opción de mostrar cajas de objetivo visualmente

### 5. markers.lua
Sistema de marcadores de visibilidad:
- Crea cajas visuales alrededor de objetivos
- Cambia colores según línea de vista
- Indica si hay obstáculo entre jugador y objetivo
- Gestiona tracking de partes del cuerpo

### 6. lighting.lua
Control de iluminación del juego:
- Implementa función FullBright
- Almacena configuración original de iluminación
- Restaura iluminación al desactivar
- Elimina sombras y oscuridad

### 7. weapons.lua
Modificaciones de armas:
- Estabilidad (reduce retroceso)
- Desbloqueo de modos de disparo
- Parchea configuraciones de armas en ReplicatedStorage

### 8. gui.lua
Interfaz gráfica de usuario:
- Crea menú con pestañas (Combat, Visuals, Weapons, Colors, Credits)
- Botones de toggle para características
- Sliders de color RGB
- Sistema de arrastrado de ventana
- Botón de descarga

### 9. main.lua
Script principal que coordina todos los módulos:
- Carga todos los módulos
- Define callbacks para eventos GUI
- Inicializa sistemas
- Bucle de juego principal
- Gestión de teclas (INSERT para toggle)

## Uso

Para usar el script modular, ejecuta `main.lua`:

```lua
loadstring(game:HttpGet("ruta/a/main.lua"))()
```

## Ventajas de la Estructura Modular

1. **Organización**: Código separado por responsabilidades
2. **Mantenimiento**: Fácil de actualizar componentes individuales
3. **Depuración**: Problemas aislados en módulos específicos
4. **Reutilización**: Módulos pueden usarse en otros proyectos
5. **Legibilidad**: Código más limpio y comprensible
6. **Escalabilidad**: Fácil agregar nuevas características

## Compatibilidad

El script original `BRM5-PVE.lua` se mantiene intacto para compatibilidad con versiones anteriores. La versión modular ofrece la misma funcionalidad con mejor organización.
