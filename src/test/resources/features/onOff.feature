Feature:  Yo como tester evaluar la transición de estados de un control de interruptor de luz inteligente

  @smoketest
  Scenario: Verificar que el interruptor acepta solicitudes
    Given url 'https://statemachine--maria7221.replit.app/api/'
    And path 'switch/state'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    When method get
    * print 'Get status:', responseStatus
    * match responseStatus == 200

  @ignore @doOn
  Scenario: Do Turn On
    Given url 'https://statemachine--maria7221.replit.app/api/'
    And path 'switch/on'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And headers 'Content-Length': '0'
    When method post
    * print 'Response status when state is Off and do On :', responseStatus
    * match responseStatus == 200
    * match response == { state: 'on' }


  @ignore  @invalidTransicion @invalidtransicionDoOn
  Scenario: Do Turn On
    Given url 'https://statemachine--maria7221.replit.app/api/'
    And path 'switch/on'
    And headers { Content-Type: 'application/json', Accept: 'application/json' }
    And headers 'Content-Length': '0'
    When method post
    * print 'Response status when state is On and do On :', responseStatus
    * match responseStatus == 409
    * match response == { error: 'Invalid transition: the switch is already on' }


  @startOn
  Scenario: Verificar que el interruptor puede encenderse
    * def response = call read('@smoketest')
    * eval if (response.state == 'off') karate.call(read('@doOn'))
    * eval if (response.state == 'on') karate.call(read('@invalidtransicionDoOn'))