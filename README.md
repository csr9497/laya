# Laya Studio - Interfaz Interactiva de Decisiones y Routing

Interfaz gráfica moderna, reactiva y modular para interactuar con la librería **Laya** (`convaiinnovations/laya`), permitiendo ingresar contenido dinámico, diseñar y evaluar preguntas semánticas estructuradas en tiempo real, visualizar decisiones en un lienzo visual (Canvas) y registrar el historial completo de ejecuciones.

---

## 🚀 Inicio Rápido

### Ejecución Local

Para iniciar el servidor interactivo en tu equipo local:

```bash
# Con uv (recomendado)
uv run python app.py

# O con python estándar
python3 app.py
```

La interfaz se abrirá automáticamente en tu navegador web en:
👉 **[http://localhost:8000](http://localhost:8000)**

### Opciones de Invocación CLI

```bash
uv run app.py --help

Opciones:
  --host HOST           Dirección de escucha (por defecto: 0.0.0.0)
  --port PORT           Puerto HTTP (por defecto: 8000)
  --no-browser          No abrir el navegador automáticamente (útil en Codespaces o VPS)
  --device {cpu,mps,cuda} Dispositivo de cómputo (por defecto: cpu)
  --skip-warmup         Omitir precalentamiento inicial del modelo
```

---

## 🎯 Características Principales

### 1. Panel de Entrada (`state`) y Configuración de Router
- **Área de Texto Dinámica**: Contador de caracteres en vivo y autolimpieza.
- **Ejemplos Realistas en 1 Clic**: Carga inmediata de casos de soporte (Cobro/Reembolso, Caída Técnica 502, Phishing, Intento de Jailbreak DAN).
- **Modal de Configuración (⚙️)**: 
  - Modal flotante desacoplado que no desplaza ni colapsa la interfaz principal.
  - Selección de modelo de embeddings: `Automático` (detección inteligente), `English (ModernBERT ~130ms)` o `Multilingual (mmBERT)`.
  - Selección de dispositivo de cómputo: `CPU` (recomendado en Apple Silicon para evitar compilación de shaders) o `MPS / GPU`.

### 2. Edición y Gestión de Preguntas
- **Modal de Plantillas Oficiales (📚)**:
  - Presets preconfigurados para *Triage de Soporte*, *Guardrails & Jailbreaks*, *Clasificación de Emails*, *Moderación de Contenido* y *Routing Semántico*.
  - **Submodal de Previsualización (`z-index: 80`)**: Permite inspeccionar en detalle la jerarquía de opciones, instrucciones y criterios de cada plantilla antes de aplicarla. Cierre escalonado con `Esc` o clic en fondo oscuro.
- **Modal de Catálogo Modular (📋)**: Buscador y selector de preguntas prediseñadas para incorporar a la sesión.
- **Modal de Nueva Pregunta (⚡)**: Selección directa por tipo de evaluación (`choice`, `score`, `noul`).
- **Editor Nodal de Preguntas (✏️)**: Edición completa de claves, instrucciones y criterios, con advertencia y confirmación antes de descartar cambios accidentales al pulsar `Esc`.
- **Botón de Ejecución ("Analizar")**:
  - Posición fija sin desplazamientos ni saltos en el layout al hacer clic.
  - Indicador de atajo de teclado sutil integrado: `⌘ + Enter` / `Ctrl + Enter`.

### 3. Lienzo Interactivo de Decisiones (Canvas / Mapa Mental)
- **Visualización Jerárquica Nodal**: Conexiones suaves en curvas Bézier SVG entre el nodo raíz (estado de entrada) y cada pregunta activa.
- **Interacción Completa**:
  - Arrastre fluido de nodos individuales (*drag and drop*).
  - Paneo del lienzo (clic sostenido en fondo) y zoom interactivo (+ / - / rueda del ratón).
  - **Fijar Vista (Bloqueo)**: Alterna entre navegación libre o lienzo fijado.
  - **Ajustar Vista (`Fit View`)**: Centra y escala automáticamente todos los nodos dentro de la ventana visible.
  - **Centrar en Raíz**: Encuadra inmediatamente el nodo del texto analizado.
  - **Selección y Borrado Múltiple**: Selecciona preguntas desde el canvas y bórralas en bloque (`☑️ Borrar Seleccionadas`).
  - **Ejecución Directa desde el Canvas**: Barra de herramientas superior con botón para ejecutar inferencia en tiempo real y visualizar las decisiones destacadas sobre los propios nodos.

### 4. Tablero de Resultados e Historial Bidireccional
La columna derecha organiza los datos en dos pestañas principales:

- **Pestaña `⚡ Reciente`**:
  - **`Resultado` (Por Defecto)**: Tabla compacta con pregunta, tipo, decisión tomada, probabilidad y confianza.
  - **`Detalle`**: Tarjetas descriptivas con barras de distribución probabilística (`choice`), barras graduadas (`score`) y medidor de certeza binaria (`noul`).
  - **`JSON`**: Payload crudo devuelto por el motor de inferencia, con botón de copia rápida.
- **Pestaña `📜 Historial`**:
  - Lista cronológica estricta en orden de ejecución (la consulta más reciente primero, sin barras de búsqueda innecesarias).
  - Indicadores de tiempo transcurrido en milisegundos (`⚡ ms`), fecha/hora y etiquetas compactas con las decisiones.
  - Botón para re-ejecutar en 1 clic o eliminar entradas individuales.
- **Flujo Bidireccional `Historial ↔ Reciente`**:
  - Al cargar una consulta anterior (`🔄 Cargar`) o visualizar su resultado (`👁️ Ver Resultado`), el sistema preserva en memoria el análisis más reciente.
  - Se habilitan automáticamente botones y avisos de retorno: **`⚡ Volver al resultado reciente`** en la cabecera del historial, dentro de la tarjeta cargada, en el editor de preguntas y en la barra superior de la pestaña Reciente.
  - Un solo clic restablece el texto original, las preguntas previas y los resultados de la última inferencia.

---

## 📋 Especificación de Formatos Laya

Laya exige que las preguntas se envíen en un diccionario con una estructura estricta según el tipo:

### 1. Tipo `choice` (Opción Múltiple con Criterios Semánticos)
```python
"departamento": {
    "type": "choice",
    "instructions": "¿Qué departamento o equipo debe atender este caso?",
    "criteria": {
        "facturacion": "invoices, facturas, cobros duplicados, pagos y reembolsos",
        "soporte_tecnico": "errores del sistema, bugs, caídas de servicio o problemas técnicos",
        "ventas": "cotizaciones, contratación y planes comerciales",
        "otro": "cualquier otra consulta general no clasificada"
    }
}
```

### 2. Tipo `score` (Escalas Ordenadas de Niveles / Severidad)
```python
"urgencia": {
    "type": "score",
    "instructions": "¿Qué nivel de urgencia o presión de tiempo tiene la solicitud?",
    "criteria": [
        "Baja: consulta habitual sin prisa ni plazos estrictos",
        "Media: requiere atención pronto pero el servicio sigue operando",
        "Alta / Bloqueante: interrupción total, pérdida financiera o plazo límite inmediato"
    ]
}
```

### 3. Tipo `noul` (Evaluación Booleana y Probabilidad de Afirmación)
```python
"riesgo_churn": {
    "type": "noul",
    "instructions": "¿El cliente amenaza con cancelar el plan, rescindir el contrato o cambiarse a un competidor?"
}
```

---

## ☁️ Despliegue en GitHub Codespaces (1-Click Cloud)

El repositorio incluye soporte nativo para **Dev Containers** (`.devcontainer/devcontainer.json`):

1. Abre tu repositorio en GitHub y haz clic en **Code** > **Codespaces** > **Create codespace on main**.
2. El contenedor se inicializará automáticamente con Python 3.13, instalará `uv` y resolverá las dependencias.
3. En la terminal integrada, inicia el servidor:
   ```bash
   uv run app.py --no-browser
   ```
4. Codespaces redirigirá el puerto `8000` y abrirá la pestaña **Simple Browser** con la aplicación lista para usar.

---

## 🛠️ Estructura del Proyecto

```
laya/
├── .devcontainer/
│   └── devcontainer.json   # Definición de contenedor para Codespaces (Python 3.13, uv, Port 8000)
├── .github/
│   └── workflows/ci.yml    # CI automático en GitHub Actions (Ruff + verificación)
├── .gitignore              # Exclusiones de Git (caches, entornos virtuales, temporales)
├── app.py                  # API FastAPI/Starlette con endpoints REST (/api/predict, /api/catalog, etc.)
├── main.py                 # Script de prueba CLI original
├── static/
│   └── index.html          # Interfaz SPA interactiva (HTML5, Tailwind CDN, Canvas Engine, Historial)
├── pyproject.toml          # Definición de dependencias con uv (laya, torch, transformers, ruff)
├── uv.lock                 # Lockfile multiplataforma determinista
└── README.md               # Documentación general y manual de uso
```

---

## 📌 Estado de Implementación y Pendientes

### ✅ Completado
- [x] Corrección de estabilidad visual del botón de ejecución (sin desplazamiento al hacer clic).
- [x] Agrupación en modales para: *Plantillas*, *Catálogo*, *Nueva Pregunta* y *Configuración del Router*.
- [x] Renombrado unificado de etiquetas (*Canvas*, *Analizar*, *Resultado*, *Historial*).
- [x] Atajo de teclado integrado discretamente en el botón de análisis (`⌘/Ctrl + Enter`).
- [x] Manejo global de la tecla `Esc` con verificación de cambios no guardados en el formulario de edición.
- [x] Canvas completamente interactivo: arrastre nodal, paneo/zoom, encuadre `Fit View`, fijación de vista, selección múltiple, eliminación por bloque y ejecución desde barra superior.
- [x] Estructura de dos pestañas principales: `Reciente` (sub-tabs Resultado, Detalle, JSON) y `Historial` (cronológico por ejecución, sin buscador).
- [x] Submodal de detalles de plantilla con jerarquía corregida (`z-index: 80` sobre `z-index: 60`) y cierre escalonado.
- [x] Botón y banners interactivos de **`⚡ Volver al resultado reciente`** al cargar consultas históricas.
- [x] Configuración de despliegue en la nube mediante GitHub Codespaces y Dev Containers.

### 📋 Pendientes / Próximos Pasos Sugeridos
1. **Control de Versiones (Git)**:
   - Realizar el commit inicial de los archivos preparados (`git add . && git commit -m "feat: Laya Studio interactive decision router and UI"`).
   - Vincular con el repositorio remoto de GitHub (`git remote add origin ... && git push -u origin main`).
2. **Persistencia de Posiciones del Canvas**:
   - Guardar las coordenadas personalizadas `(x, y)` de los nodos en `localStorage` para preservar diagramas reorganizados por el usuario al recargar la página.
3. **Exportación e Importación de Sesiones**:
   - Exportar preguntas o historial a archivos JSON descargables.
   - Importar archivos JSON para compartir plantillas o casos de prueba entre miembros del equipo.
4. **Métricas y Estadísticas Acumuladas**:
   - Panel de resumen con tiempos promedio de inferencia y distribución de categorías clasificadas en el historial.
5. **Inferencia en Lote (Batch CSV)**:
   - Permitir cargar un archivo `.csv` con múltiples textos para analizarlos masivamente en una sola pasada.


