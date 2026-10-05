@torniquete @transicionEstados
Feature: Transición de estados del Torniquete del Metro Inteligente
  Como pasajero del metro
  Quiero que el torniquete responda a los eventos según su estado actual
  Para que solo se permita el paso autorizado y el sistema se proteja ante fallas de energía

  # Estados: S1 (Bloqueado), S2 (Autorizado), S3 (Girando), S4 (Mantenimiento)
  # Guardas: "Validar Tarjeta" requiere Saldo Positivo y "Alarma" requiere Falla de Energía

  Background:
    * def steps = 'classpath:features/torniquete/torniquete-steps.feature'

  # ---------------------------------------------------------------------------
  # Escenarios positivos: una transición válida por escenario
  # ---------------------------------------------------------------------------

  @Issue-1 @REQ-TOR-01 @positivo @smoketest
  Scenario: Validar una tarjeta con saldo positivo desbloquea el paso
    # Dado que el torniquete está en el estado "S1 (Bloqueado)"
    Given call read(steps + '@irAEstado') { estadoDestino: 'S1 (Bloqueado)' }
    # Cuando el pasajero valida una tarjeta con saldo positivo
    And url baseUrl
    And path 'torniquete', 'evento'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { evento: 'Validar Tarjeta', guardia: true }
    When method post
    # Entonces el torniquete pasa a "S2 (Autorizado)" y ejecuta la acción "Desbloquear paso"
    Then status 200
    And match response == { estadoAnterior: 'S1 (Bloqueado)', evento: 'Validar Tarjeta', guardia: true, estadoNuevo: 'S2 (Autorizado)', valida: true, accion: 'Desbloquear paso' }
    And def estado = call read(steps + '@consultarEstado')
    And match estado.response.estadoActual == 'S2 (Autorizado)'

  @Issue-2 @REQ-TOR-02 @positivo
  Scenario: Empujar el torniquete autorizado inicia el giro del molinete
    # Dado que el torniquete está en el estado "S2 (Autorizado)"
    Given call read(steps + '@irAEstado') { estadoDestino: 'S2 (Autorizado)' }
    # Cuando el pasajero empuja el torniquete
    And url baseUrl
    And path 'torniquete', 'evento'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { evento: 'Empujar', guardia: null }
    When method post
    # Entonces el torniquete pasa a "S3 (Girando)" y ejecuta la acción "Girar molinete"
    Then status 200
    And match response == { estadoAnterior: 'S2 (Autorizado)', evento: 'Empujar', guardia: null, estadoNuevo: 'S3 (Girando)', valida: true, accion: 'Girar molinete' }
    And def estado = call read(steps + '@consultarEstado')
    And match estado.response.estadoActual == 'S3 (Girando)'

  @Issue-3 @REQ-TOR-03 @positivo
  Scenario: Completar el giro vuelve a bloquear el torniquete
    # Dado que el torniquete está en el estado "S3 (Girando)"
    Given call read(steps + '@irAEstado') { estadoDestino: 'S3 (Girando)' }
    # Cuando el molinete completa el giro
    And url baseUrl
    And path 'torniquete', 'evento'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { evento: 'Completar Giro', guardia: null }
    When method post
    # Entonces el torniquete regresa a "S1 (Bloqueado)" sin acción adicional
    Then status 200
    And match response == { estadoAnterior: 'S3 (Girando)', evento: 'Completar Giro', guardia: null, estadoNuevo: 'S1 (Bloqueado)', valida: true, accion: null }
    And def estado = call read(steps + '@consultarEstado')
    And match estado.response.estadoActual == 'S1 (Bloqueado)'

  @Issue-4 @REQ-TOR-04 @positivo
  Scenario: Una alarma por falla de energía con el torniquete bloqueado lo envía a mantenimiento
    # Dado que el torniquete está en el estado "S1 (Bloqueado)"
    Given call read(steps + '@irAEstado') { estadoDestino: 'S1 (Bloqueado)' }
    # Cuando se dispara una alarma por falla de energía
    And url baseUrl
    And path 'torniquete', 'evento'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { evento: 'Alarma', guardia: true }
    When method post
    # Entonces el torniquete pasa a "S4 (Mantenimiento)" y ejecuta la acción "Cortar energía"
    Then status 200
    And match response == { estadoAnterior: 'S1 (Bloqueado)', evento: 'Alarma', guardia: true, estadoNuevo: 'S4 (Mantenimiento)', valida: true, accion: 'Cortar energía' }
    And def estado = call read(steps + '@consultarEstado')
    And match estado.response.estadoActual == 'S4 (Mantenimiento)'

  @Issue-5 @REQ-TOR-05 @positivo
  Scenario: Una alarma por falla de energía con el torniquete autorizado lo envía a mantenimiento
    # Dado que el torniquete está en el estado "S2 (Autorizado)"
    Given call read(steps + '@irAEstado') { estadoDestino: 'S2 (Autorizado)' }
    # Cuando se dispara una alarma por falla de energía
    And url baseUrl
    And path 'torniquete', 'evento'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { evento: 'Alarma', guardia: true }
    When method post
    # Entonces el torniquete pasa a "S4 (Mantenimiento)" y ejecuta la acción "Cortar energía"
    Then status 200
    And match response == { estadoAnterior: 'S2 (Autorizado)', evento: 'Alarma', guardia: true, estadoNuevo: 'S4 (Mantenimiento)', valida: true, accion: 'Cortar energía' }
    And def estado = call read(steps + '@consultarEstado')
    And match estado.response.estadoActual == 'S4 (Mantenimiento)'

  @Issue-6 @REQ-TOR-06 @positivo
  Scenario: Reparar el torniquete en mantenimiento restaura el servicio
    # Dado que el torniquete está en el estado "S4 (Mantenimiento)"
    Given call read(steps + '@irAEstado') { estadoDestino: 'S4 (Mantenimiento)' }
    # Cuando el técnico repara el torniquete
    And url baseUrl
    And path 'torniquete', 'evento'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { evento: 'Reparar', guardia: null }
    When method post
    # Entonces el torniquete regresa a "S1 (Bloqueado)" y ejecuta la acción "Restaurar servicio"
    Then status 200
    And match response == { estadoAnterior: 'S4 (Mantenimiento)', evento: 'Reparar', guardia: null, estadoNuevo: 'S1 (Bloqueado)', valida: true, accion: 'Restaurar servicio' }
    And def estado = call read(steps + '@consultarEstado')
    And match estado.response.estadoActual == 'S1 (Bloqueado)'

  # ---------------------------------------------------------------------------
  # Escenarios negativos: transiciones inválidas, el estado no debe cambiar
  # ---------------------------------------------------------------------------

  @Issue-7 @REQ-TOR-07 @negativo
  Scenario Outline: Ignorar el evento "<evento>" cuando no está permitido en el estado "<estadoActual>"
    # Dado que el torniquete se encuentra en el estado "<estadoActual>"
    Given call read(steps + '@irAEstado') { estadoDestino: '<estadoActual>' }
    # Cuando se intenta disparar el evento "<evento>" (guarda: <guardia>)
    And url baseUrl
    And path 'torniquete', 'evento'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { evento: '<evento>', guardia: <guardia> }
    When method post
    # Entonces la transición se rechaza y el torniquete permanece en "<estadoActual>"
    Then status 200
    And match response contains { estadoAnterior: '<estadoActual>', estadoNuevo: '<estadoActual>', valida: false }
    And def estado = call read(steps + '@consultarEstado')
    And match estado.response.estadoActual == '<estadoActual>'

    Examples:
      | estadoActual       | evento          | guardia |
      | S1 (Bloqueado)     | Empujar         | null    |
      | S1 (Bloqueado)     | Completar Giro  | null    |
      | S1 (Bloqueado)     | Reparar         | null    |
      | S2 (Autorizado)    | Validar Tarjeta | true    |
      | S2 (Autorizado)    | Validar Tarjeta | false   |
      | S2 (Autorizado)    | Completar Giro  | null    |
      | S2 (Autorizado)    | Reparar         | null    |
      | S3 (Girando)       | Validar Tarjeta | true    |
      | S3 (Girando)       | Validar Tarjeta | false   |
      | S3 (Girando)       | Empujar         | null    |
      | S3 (Girando)       | Alarma          | true    |
      | S3 (Girando)       | Alarma          | false   |
      | S3 (Girando)       | Reparar         | null    |
      | S4 (Mantenimiento) | Validar Tarjeta | true    |
      | S4 (Mantenimiento) | Validar Tarjeta | false   |
      | S4 (Mantenimiento) | Empujar         | null    |
      | S4 (Mantenimiento) | Completar Giro  | null    |
      | S4 (Mantenimiento) | Alarma          | true    |
      | S4 (Mantenimiento) | Alarma          | false   |

  @Issue-8 @REQ-TOR-08 @negativo
  Scenario Outline: Rechazar "<evento>" en "<estadoActual>" cuando no se cumple la guarda "<guarda>"
    # Dado que el torniquete se encuentra en el estado "<estadoActual>"
    Given call read(steps + '@irAEstado') { estadoDestino: '<estadoActual>' }
    # Cuando se dispara el evento "<evento>" sin cumplir la guarda "<guarda>"
    And url baseUrl
    And path 'torniquete', 'evento'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request { evento: '<evento>', guardia: false }
    When method post
    # Entonces la transición se rechaza, no se ejecuta ninguna acción y el estado no cambia
    Then status 200
    And match response == { estadoAnterior: '<estadoActual>', evento: '<evento>', guardia: false, estadoNuevo: '<estadoActual>', valida: false, accion: null }
    And def estado = call read(steps + '@consultarEstado')
    And match estado.response.estadoActual == '<estadoActual>'

    Examples:
      | estadoActual    | evento          | guarda           |
      | S1 (Bloqueado)  | Validar Tarjeta | Saldo Positivo   |
      | S1 (Bloqueado)  | Alarma          | Falla de Energía |
      | S2 (Autorizado) | Alarma          | Falla de Energía |
