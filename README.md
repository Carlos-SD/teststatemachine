# Automatización de pruebas backend con Karate Framework

Suite de pruebas automatizadas de API (caja negra) construida con **Karate Framework**, ejecutada en **GitHub Actions** y trazada contra **GitHub Issues**.

Ejercicios seleccionados del taller:

| Bloque | Ejercicio | Técnica |
|---|---|---|
| 1 – Transición de estados | **1.7. Torniquete del Metro Inteligente** | Tabla de transición de estados |
| 2 – Tablas de decisión | **2.4. Validación de Equipaje Automatizada (Tren de Alta Velocidad)** | Tabla de decisión |

API bajo prueba: `https://taller-de-tecnicas-de-prueba-de-caja.onrender.com/api/` (configurada en [`karate-config.js`](src/test/resources/karate-config.js)).

---

## Resumen

| | Escenarios | Ejecuciones (incluye filas de `Examples`) | Issues |
|---|---|---|---|
| Torniquete | 8 | 28 | #1 – #8 |
| Equipaje | 4 | 8 | #9 – #12 |
| **Total** | **12** | **36** | **12** |

Cada escenario tiene tres tipos de tags:

- `@Issue-N`: vincula el escenario con el issue #N del repositorio.
- `@REQ-...`: indica el requisito (transición o regla) que valida.
- `@positivo` / `@negativo` / `@smoketest`: clasifican el caso.

---

## 1. Torniquete del Metro Inteligente: transición de estados

Feature: [`torniquete.feature`](src/test/resources/features/torniquete/torniquete.feature) · Tags del feature: `@torniquete @transicionEstados`

### Modelo

Estados: **S1 (Bloqueado)**, **S2 (Autorizado)**, **S3 (Girando)**, **S4 (Mantenimiento)**.
Guardas: *Validar Tarjeta* requiere **Saldo Positivo** y *Alarma* requiere **Falla de Energía**.

| Estado actual | Evento | Guarda | Estado nuevo | Acción |
|---|---|---|---|---|
| S1 (Bloqueado) | Validar Tarjeta | Saldo Positivo | S2 (Autorizado) | Desbloquear paso |
| S2 (Autorizado) | Empujar | – | S3 (Girando) | Girar molinete |
| S3 (Girando) | Completar Giro | – | S1 (Bloqueado) | – |
| S1 (Bloqueado) | Alarma | Falla de Energía | S4 (Mantenimiento) | Cortar energía |
| S2 (Autorizado) | Alarma | Falla de Energía | S4 (Mantenimiento) | Cortar energía |
| S4 (Mantenimiento) | Reparar | – | S1 (Bloqueado) | Restaurar servicio |

### Endpoints

| Método | Ruta | Uso |
|---|---|---|
| `GET` | `torniquete/estado` | Consultar el estado actual |
| `POST` | `torniquete/reiniciar` | Volver a S1 (Bloqueado) |
| `POST` | `torniquete/evento` | Enviar `{ evento, guardia }` |

### Escenarios

| Issue | Requisito | Tipo | Escenario | Ejecuciones |
|---|---|---|---|---|
| [#1](https://github.com/Carlos-SD/teststatemachine/issues/1) | REQ-TOR-01 | Positivo · smoke | S1 + Validar Tarjeta (saldo positivo) → S2, *Desbloquear paso* | 1 |
| [#2](https://github.com/Carlos-SD/teststatemachine/issues/2) | REQ-TOR-02 | Positivo | S2 + Empujar → S3, *Girar molinete* | 1 |
| [#3](https://github.com/Carlos-SD/teststatemachine/issues/3) | REQ-TOR-03 | Positivo | S3 + Completar Giro → S1 | 1 |
| [#4](https://github.com/Carlos-SD/teststatemachine/issues/4) | REQ-TOR-04 | Positivo | S1 + Alarma (falla de energía) → S4, *Cortar energía* | 1 |
| [#5](https://github.com/Carlos-SD/teststatemachine/issues/5) | REQ-TOR-05 | Positivo | S2 + Alarma (falla de energía) → S4, *Cortar energía* | 1 |
| [#6](https://github.com/Carlos-SD/teststatemachine/issues/6) | REQ-TOR-06 | Positivo | S4 + Reparar → S1, *Restaurar servicio* | 1 |
| [#7](https://github.com/Carlos-SD/teststatemachine/issues/7) | REQ-TOR-07 | Negativo | Eventos no permitidos en cada estado: el estado no cambia | 19 |
| [#8](https://github.com/Carlos-SD/teststatemachine/issues/8) | REQ-TOR-08 | Negativo | Validar Tarjeta / Alarma sin cumplir la guarda: el estado no cambia | 3 |

**Qué valida cada escenario:**

1. **Precondición:** consulta el estado, reinicia a S1 y recorre la ruta mínima hasta el estado de partida (`@irAEstado`).
2. **Acción:** envía el evento con `POST torniquete/evento`.
3. **Respuesta:** `status 200` y JSON completo (`estadoAnterior`, `estadoNuevo`, `valida`, `accion`).
4. **Persistencia:** vuelve a consultar `torniquete/estado` y confirma el estado final.

Para las transiciones inválidas, la API responde `200` con `valida: false` y el estado se mantiene.

Los pasos reutilizables están en [`torniquete-steps.feature`](src/test/resources/features/torniquete/torniquete-steps.feature). Ese archivo está marcado `@ignore`, así que el runner no lo ejecuta por sí solo; se invoca con `call`.

---

## 2. Validación de Equipaje: tabla de decisión

Feature: [`equipaje.feature`](src/test/resources/features/equipaje/equipaje.feature) · Tags del feature: `@equipaje @tablaDecision`

### Modelo

Condiciones (en el orden que espera la API):

- **C1:** el peso total excede 23 kg
- **C2:** las dimensiones superan el compartimiento superior
- **C3:** el pasajero tiene tarifa *Preferencial Plus*

| Regla | C1 | C2 | C3 | Acción |
|---|---|---|---|---|
| R1 | – | S | – | Bloquear compuerta e indicar derivación obligatoria a bodega de carga |
| R2 | S | N | S | Aprobar embarque automático registrando sobrepeso autorizado |
| R3 | S | N | N | Bloquear compuerta, emitir tique de cobro por exceso de equipaje y solicitar pago |
| R4 | N | N | – | Permitir el paso directo a la plataforma de abordaje |

`–` = la condición no influye en la regla.

### Endpoint

`POST decision/equipaje/evaluar` con `{ "valores": [C1, C2, C3] }`. La respuesta incluye `accion`, `reglaIndex` (0–3 → R1–R4) y `noDefinida`.

### Escenarios

| Issue | Requisito | Tipo | Escenario | Combinaciones probadas (C1, C2, C3) |
|---|---|---|---|---|
| [#9](https://github.com/Carlos-SD/teststatemachine/issues/9) | REQ-EQP-R1 | Positivo | Derivar a bodega por dimensiones | (S,S,S) (S,S,N) (N,S,S) (N,S,N) |
| [#10](https://github.com/Carlos-SD/teststatemachine/issues/10) | REQ-EQP-R2 | Positivo | Aprobar sobrepeso a Preferencial Plus | (S,N,S) |
| [#11](https://github.com/Carlos-SD/teststatemachine/issues/11) | REQ-EQP-R3 | Positivo | Cobrar exceso sin Preferencial Plus | (S,N,N) |
| [#12](https://github.com/Carlos-SD/teststatemachine/issues/12) | REQ-EQP-R4 | Positivo · smoke | Paso directo dentro de peso y dimensiones | (N,N,S) (N,N,N) |

Las 8 combinaciones posibles de C1–C3 quedan cubiertas. Cada escenario valida `status 200`, la acción exacta, el `reglaIndex` y que la regla esté definida.

---

## Ejercicio de clase

[`onOff.feature`](src/test/resources/features/onOff.feature) es el ejercicio del interruptor de encendido/apagado que se trabajó en clase, contra otra API (Replit). No hace parte de los escenarios evaluados y no tiene issues asociados.

---

## Estructura del proyecto

```
├── build.gradle                         # Karate 1.4.1 + JUnit 5 + logback
├── .github/workflows/ci.yml             # Pipeline de GitHub Actions
└── src/test/
    ├── java/runner/cajanegra2runner.java  # Runner: ejecuta classpath:features
    └── resources/
        ├── karate-config.js             # baseUrl, timeouts y logs
        ├── logback-test.xml
        └── features/
            ├── onOff.feature
            ├── torniquete/torniquete.feature
            ├── torniquete/torniquete-steps.feature
            └── equipaje/equipaje.feature
```

---

## Ejecución local

Requiere Java 21.

```bash
./gradlew test                                              # toda la suite
./gradlew test -Dkarate.options="--tags @Issue-7"           # un escenario (issue)
./gradlew test -Dkarate.options="--tags @torniquete"        # un ejercicio
./gradlew test -Dkarate.options="--tags @smoketest"         # pruebas de humo
./gradlew test -Dkarate.options="--tags @positivo,@negativo" # varios tags (OR)
```

Reporte: `target/karate-reports/karate-summary.html`. Al abrir un escenario se ve el request, los headers y la respuesta de cada paso. El runner también genera los resultados en formato Cucumber JSON (`outputCucumberJson`).

---

## Integración continua y trazabilidad

El pipeline [`ci.yml`](.github/workflows/ci.yml) se ejecuta:

- **En `push` / `pull_request` a `main` o `develop`:** corre los escenarios `@smoketest` (Issue-1, Issue-12 y el smoke del ejercicio de clase).
- **Manualmente (`workflow_dispatch`):** en *Actions → CI / CD Pipeline → Run workflow*, escribir el tag en `testTag`, por ejemplo `@Issue-3`.

Cuando se ejecuta manualmente con un tag `@Issue-N`, el pipeline:

1. Corre solo ese escenario.
2. Sube los artefactos `karate-reports` y `test-results`.
3. Actualiza el issue #N:
   - comentario con el resultado, la fecha y el enlace a la corrida;
   - label **`automated-passed`** si pasó;
   - labels **`automated-failed`** y **`bug`** si falló.

Los issues #1 a #12 están vinculados al proyecto (tablero de TestCases) del repositorio.
