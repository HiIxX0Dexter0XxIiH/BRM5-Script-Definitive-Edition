# Guía para Subir a GitHub y Obtener Raw Links

## Paso 1: Crear Repositorio en GitHub

1. Ve a [GitHub](https://github.com) e inicia sesión
2. Click en el botón **"+"** (arriba derecha) → **"New repository"**
3. Nombre del repositorio: `BRM5-PVE-Modular` (o el que prefieras)
4. Descripción: "BRM5 PVE Script - Modular Version"
5. Selecciona **Public** (debe ser público para usar raw links)
6. ✅ Marca **"Add a README file"**
7. Click en **"Create repository"**

## Paso 2: Subir Archivos

### Opción A: Desde la Web (Más Fácil)

1. En tu repositorio, click en **"Add file"** → **"Upload files"**
2. Arrastra toda la carpeta `brm5-pve` o selecciona los archivos:
   ```
   brm5-pve/
   ├── main.lua
   ├── BRM5-PVE.lua (original)
   ├── README_MODULAR.md
   └── modules/
       ├── config.lua
       ├── services.lua
       ├── npc_manager.lua
      ├── target_sizing.lua
      ├── markers.lua
       ├── lighting.lua
       ├── weapons.lua
       └── gui.lua
   ```
3. Escribe un mensaje de commit: "Initial commit - Modular structure"
4. Click en **"Commit changes"**

### Opción B: Usando Git (Terminal)

```powershell
# Navegar a tu carpeta
cd "C:\Users\darimary\Desktop\Proyectos python\script\Roblox-Dexter-Scripts-main"

# Inicializar git (si no está inicializado)
git init

# Agregar archivos
git add brm5-pve/

# Hacer commit
git commit -m "Add modular BRM5 PVE structure"

# Conectar con tu repositorio (REEMPLAZA CON TU URL)
git remote add origin https://github.com/TU_USUARIO/BRM5-PVE-Modular.git

# Subir archivos
git branch -M main
git push -u origin main
```

## Paso 3: Obtener Raw Links

Una vez subidos los archivos, necesitas obtener los **raw links**:

### Ejemplo:
Si tu repositorio es: `https://github.com/TuUsuario/BRM5-PVE-Modular`

Los raw links serán:
```
https://raw.githubusercontent.com/TuUsuario/BRM5-PVE-Modular/main/brm5-pve/modules/services.lua
https://raw.githubusercontent.com/TuUsuario/BRM5-PVE-Modular/main/brm5-pve/modules/config.lua
https://raw.githubusercontent.com/TuUsuario/BRM5-PVE-Modular/main/brm5-pve/modules/npc_manager.lua
(etc...)
```

### Cómo obtenerlos:
1. Ve a cualquier archivo en GitHub (ej: `modules/config.lua`)
2. Click en el botón **"Raw"** (arriba derecha)
3. Copia la URL de la barra de direcciones
4. Esa es tu URL raw

## Paso 4: Actualizar main.lua

1. Abre `main.lua`
2. En la línea 7, reemplaza:
   ```lua
   local GITHUB_BASE = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/brm5-pve/modules/"
   ```

3. Con tu URL real:
   ```lua
   local GITHUB_BASE = "https://raw.githubusercontent.com/TuUsuario/BRM5-PVE-Modular/main/brm5-pve/modules/"
   ```

4. Guarda y vuelve a subir el `main.lua` actualizado a GitHub

## Paso 5: Usar el Script

Ahora puedes cargar el script en Roblox con:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/TuUsuario/BRM5-PVE-Modular/main/brm5-pve/main.lua"))()
```

## Ejemplo Completo

Si tu usuario de GitHub es **"HiIxX0Dexter0XxIiH"** y tu repo es **"BRM5-PVE-Modular"**:

**URL Base:**
```lua
local GITHUB_BASE = "https://raw.githubusercontent.com/HiIxX0Dexter0XxIiH/BRM5-PVE-Modular/main/brm5-pve/modules/"
```

**Cargar script:**
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/HiIxX0Dexter0XxIiH/BRM5-PVE-Modular/main/brm5-pve/main.lua"))()
```

## Ventajas de Este Método

✅ **Actualizaciones fáciles**: Solo actualiza archivos en GitHub, no necesitas redistribuir  
✅ **Carga remota**: Los scripts siempre cargan la última versión  
✅ **Organizado**: Todos los módulos en un solo repositorio  
✅ **Versionable**: Puedes usar branches para diferentes versiones  

## Notas Importantes

⚠️ El repositorio **DEBE** ser público para que funcione con raw links  
⚠️ Si cambias algo en GitHub, los cambios se reflejan instantáneamente  
⚠️ Asegúrate de que Roblox permita HttpGet en tu juego  
⚠️ Algunas ejecutoras pueden bloquear HttpGet, verifica compatibilidad  

## Solución de Problemas

**Error: "HttpGet is not allowed"**
- Verifica que tu ejecutor soporte HttpGet

**Error: "404 Not Found"**
- Verifica que la URL sea correcta
- Asegúrate de que el repositorio sea público
- Verifica que los archivos estén en la rama "main" (no "master")

**Error: "Module load failed"**
- Verifica tu conexión a internet
- Confirma que todas las URLs sean correctas
- Revisa la consola para ver qué módulo falló
