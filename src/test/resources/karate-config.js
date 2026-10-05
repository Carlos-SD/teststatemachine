function fn() {
    var config = {
        env: karate.env || 'dev',
        // API de los ejercicios de caja negra (transición de estados y tablas de decisión)
        baseUrl: 'https://taller-de-tecnicas-de-prueba-de-caja.onrender.com/api/'
    };

    // La API está en Render (plan gratuito): la primera petición puede tardar mientras el servicio despierta
    karate.configure('connectTimeout', 60000);
    karate.configure('readTimeout', 60000);

    // Simplifica y formatea el JSON/XML de los Requests y Responses en la consola
    karate.configure('logPrettyRequest', true);
    karate.configure('logPrettyResponse', true);

    return config;
}
