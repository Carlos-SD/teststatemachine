@equipaje @tablaDecision
Feature: Validación de Equipaje Automatizada en el Tren de Alta Velocidad
  Como operador del tren de alta velocidad
  Quiero que la compuerta de abordaje evalúe automáticamente el equipaje de cada pasajero
  Para aplicar la política de peso, dimensiones y tarifa sin intervención manual

  # Condiciones (en el orden que espera la API):
  #   C1: Peso total excede los 23 kg
  #   C2: Dimensiones superan el compartimiento superior
  #   C3: Pasajero tiene tarifa 'Preferencial Plus'
  #
  # Tabla de decisión:
  #   | Regla | C1 | C2 | C3 | Acción                                            |
  #   | R1    | -  | S  | -  | Derivación obligatoria a bodega de carga          |
  #   | R2    | S  | N  | S  | Aprobar embarque registrando sobrepeso autorizado |
  #   | R3    | S  | N  | N  | Cobro por exceso de equipaje                      |
  #   | R4    | N  | N  | -  | Paso directo a la plataforma de abordaje          |

  Background:
    * def accionBodega = 'Bloquear compuerta e indicar derivación obligatoria a bodega de carga'
    * def accionSobrepesoAutorizado = 'Aprobar embarque automático registrando sobrepeso autorizado'
    * def accionCobroExceso = 'Bloquear compuerta, emitir tique de cobro por exceso de equipaje y solicitar pago en el módulo de autoservicio'
    * def accionPasoDirecto = 'Permitir el paso directo a la plataforma de abordaje'
    Given url baseUrl
    And path 'decision', 'equipaje', 'evaluar'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }

  @Issue-9 @REQ-EQP-R1 @positivo
  Scenario Outline: Derivar a bodega el equipaje que supera las dimensiones del compartimiento superior
    # Dado un equipaje cuyas dimensiones superan el compartimiento superior
    # Y cuyo peso excede 23 kg: <pesoExcede>, con tarifa Preferencial Plus: <preferencialPlus>
    And request { valores: [<pesoExcede>, true, <preferencialPlus>] }
    # Cuando el pasajero pasa por la compuerta de validación
    When method post
    # Entonces el sistema bloquea la compuerta y deriva el equipaje a la bodega de carga
    Then status 200
    And match response == { valores: [<pesoExcede>, true, <preferencialPlus>], accion: '#(accionBodega)', reglaIndex: 0, noDefinida: false }

    Examples:
      | pesoExcede | preferencialPlus |
      | true       | true             |
      | true       | false            |
      | false      | true             |
      | false      | false            |

  @Issue-10 @REQ-EQP-R2 @positivo
  Scenario: Aprobar el embarque con sobrepeso a un pasajero con tarifa Preferencial Plus
    # Dado un equipaje que excede 23 kg y cabe en el compartimiento superior
    # Y el pasajero tiene tarifa Preferencial Plus
    And request { valores: [true, false, true] }
    # Cuando el pasajero pasa por la compuerta de validación
    When method post
    # Entonces el sistema aprueba el embarque registrando el sobrepeso autorizado
    Then status 200
    And match response == { valores: [true, false, true], accion: '#(accionSobrepesoAutorizado)', reglaIndex: 1, noDefinida: false }

  @Issue-11 @REQ-EQP-R3 @positivo
  Scenario: Cobrar el exceso de equipaje a un pasajero sin tarifa Preferencial Plus
    # Dado un equipaje que excede 23 kg y cabe en el compartimiento superior
    # Y el pasajero no tiene tarifa Preferencial Plus
    And request { valores: [true, false, false] }
    # Cuando el pasajero pasa por la compuerta de validación
    When method post
    # Entonces el sistema bloquea la compuerta y emite el tique de cobro por exceso de equipaje
    Then status 200
    And match response == { valores: [true, false, false], accion: '#(accionCobroExceso)', reglaIndex: 2, noDefinida: false }

  @Issue-12 @REQ-EQP-R4 @positivo @smoketest
  Scenario Outline: Permitir el paso directo al equipaje dentro de peso y dimensiones
    # Dado un equipaje que no excede 23 kg y cabe en el compartimiento superior
    # Y el pasajero tiene tarifa Preferencial Plus: <preferencialPlus>
    And request { valores: [false, false, <preferencialPlus>] }
    # Cuando el pasajero pasa por la compuerta de validación
    When method post
    # Entonces el sistema permite el paso directo a la plataforma de abordaje
    Then status 200
    And match response == { valores: [false, false, <preferencialPlus>], accion: '#(accionPasoDirecto)', reglaIndex: 3, noDefinida: false }

    Examples:
      | preferencialPlus |
      | true             |
      | false            |
