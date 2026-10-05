@ignore
Feature: Pasos reutilizables del Torniquete del Metro Inteligente
  Escenarios auxiliares que se invocan con call desde torniquete.feature.
  El tag @ignore evita que el runner los ejecute como casos de prueba independientes.

  @consultarEstado
  Scenario: Consultar el estado actual del torniquete
    Given url baseUrl
    And path 'torniquete', 'estado'
    And header Accept = 'application/json'
    When method get
    Then status 200
    And match response.estadoActual == '#string'

  @reiniciar
  Scenario: Reiniciar el torniquete al estado inicial S1 (Bloqueado)
    Given url baseUrl
    And path 'torniquete', 'reiniciar'
    And header Accept = 'application/json'
    When method post
    Then status 200
    And match response.estadoActual == 'S1 (Bloqueado)'

  @enviarEvento
  Scenario: Enviar un evento al torniquete
    # Parámetros: evento (obligatorio) y guardia (true/false para eventos con guarda, null en otro caso)
    * def guardia = karate.get('guardia', null)
    Given url baseUrl
    And path 'torniquete', 'evento'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And request ({ evento: evento, guardia: guardia })
    When method post
    Then status 200

  @irAEstado
  Scenario: Llevar el torniquete desde S1 (Bloqueado) hasta el estado requerido
    # Parámetro: estadoDestino. Ruta mínima de eventos válidos desde S1 hasta cada estado.
    * def rutas =
      """
      {
        "S1 (Bloqueado)": [],
        "S2 (Autorizado)": [{ "evento": "Validar Tarjeta", "guardia": true }],
        "S3 (Girando)": [{ "evento": "Validar Tarjeta", "guardia": true }, { "evento": "Empujar", "guardia": null }],
        "S4 (Mantenimiento)": [{ "evento": "Alarma", "guardia": true }]
      }
      """
    * def ruta = rutas[estadoDestino]
    * match ruta == '#array'
    # 1. Consultar el estado en que quedó el torniquete
    * def estadoPrevio = call read('@consultarEstado')
    * print 'Estado del torniquete antes de la precondición:', estadoPrevio.response.estadoActual
    # 2. Mover el torniquete hasta S1 (Bloqueado)
    * call read('@reiniciar')
    # 3. Recorrer los eventos válidos hasta el estado requerido
    * call read('@enviarEvento') ruta
    # 4. Verificar que el torniquete quedó en el estado requerido
    * def estadoFinal = call read('@consultarEstado')
    * match estadoFinal.response.estadoActual == estadoDestino
