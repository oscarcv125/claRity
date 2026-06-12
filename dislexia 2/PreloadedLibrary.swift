import Foundation

enum PreloadedLibrary {
    static let items: [LibraryItem] = basicTexts + intermediateTexts + advancedTexts

    // MARK: - Básico

    static let basicTexts: [LibraryItem] = [
        LibraryItem(
            title: "El sol y la luna",
            body: "El sol brilla de día. La luna brilla de noche. El sol es grande y amarillo. La luna es blanca y redonda. De día hace calor. De noche hace frío. El sol y la luna cuidan la Tierra.",
            level: .basic
        ),
        LibraryItem(
            title: "Mi mascota",
            body: "Tengo un perro que se llama Canelo. Canelo es café con manchas blancas. Le gusta correr y jugar con su pelota. Todos los días le doy de comer y agua fresca. Canelo me hace muy feliz.",
            level: .basic
        ),
        LibraryItem(
            title: "La hormiga trabajadora",
            body: "Una hormiga caminaba por el campo buscando comida. Encontró una semilla grande y la cargó hasta su casa. La semilla era muy pesada, pero la hormiga no se rindió. Cuando llegó a casa, sus amigas la ayudaron a guardar la semilla. Juntas tendrían comida para el invierno.",
            level: .basic
        ),
        LibraryItem(
            title: "Las estaciones del año",
            body: "En primavera florecen las plantas. Hace calor y llueve. En verano el sol calienta mucho. Los días son largos. En otoño las hojas de los árboles cambian de color y caen. En invierno hace frío y a veces nieva. Cada estación tiene algo especial.",
            level: .basic
        ),
        LibraryItem(
            title: "El panadero del pueblo",
            body: "Don Ramón se levanta muy temprano cada mañana. Enciende su horno y prepara la masa del pan. Amasa, da forma y hornea los bolillos. A las siete de la mañana el pan ya está listo. El olor rico del pan llena todo el pueblo.",
            level: .basic
        )
    ]

    // MARK: - Intermedio

    static let intermediateTexts: [LibraryItem] = [
        LibraryItem(
            title: "El agua que bebemos",
            body: "El agua es un recurso muy valioso. Sin agua no puede existir la vida. La mayor parte del agua de la Tierra está en los océanos, pero esa agua es salada. Solo una pequeña parte es agua dulce, que es la que podemos beber. El agua dulce se encuentra en ríos, lagos y manantiales. Es importante cuidar el agua: cerrar la llave cuando no la usamos y evitar contaminar los ríos. Todos podemos ayudar a conservarla.",
            level: .intermediate
        ),
        LibraryItem(
            title: "La selva tropical",
            body: "La selva tropical es uno de los ecosistemas más ricos del planeta. En ella viven millones de especies de plantas, animales e insectos. Los árboles son tan altos que forman un techo verde llamado dosel, que protege a las plantas pequeñas del sol directo. Las selvas producen mucho oxígeno y regulan el clima de la Tierra. Por eso es tan importante protegerlas de la deforestación.",
            level: .intermediate
        ),
        LibraryItem(
            title: "Cómo funciona el cerebro",
            body: "El cerebro es el órgano más complejo de nuestro cuerpo. Pesa aproximadamente 1.4 kilogramos y tiene forma de nuez. Está formado por miles de millones de células llamadas neuronas. Las neuronas se comunican entre sí mediante señales eléctricas y químicas. El cerebro controla todos los movimientos del cuerpo, los pensamientos, los recuerdos y las emociones. Mientras dormimos, el cerebro sigue trabajando para procesar lo que aprendimos durante el día.",
            level: .intermediate
        )
    ]

    // MARK: - Avanzado

    static let advancedTexts: [LibraryItem] = [
        LibraryItem(
            title: "La Revolución Industrial",
            body: "La Revolución Industrial fue un periodo de transformación económica y social que comenzó en Inglaterra a finales del siglo XVIII. La invención de la máquina de vapor permitió mecanizar procesos que antes se hacían a mano, lo que aumentó enormemente la producción de bienes. Las fábricas reemplazaron a los talleres artesanales y miles de personas migraron del campo a las ciudades en busca de trabajo. Este cambio trajo avances tecnológicos importantes, pero también nuevos problemas sociales como las largas jornadas laborales, el trabajo infantil y la contaminación. Sus efectos moldearon el mundo moderno tal como lo conocemos hoy.",
            level: .advanced
        ),
        LibraryItem(
            title: "La inteligencia artificial",
            body: "La inteligencia artificial es una rama de la informática que busca crear sistemas capaces de realizar tareas que normalmente requieren inteligencia humana, como reconocer imágenes, entender lenguaje natural o tomar decisiones. Los sistemas de IA aprenden a partir de grandes cantidades de datos mediante algoritmos de aprendizaje automático. Hoy en día la IA está presente en muchos aspectos de nuestra vida cotidiana: en los asistentes de voz, en las recomendaciones de plataformas de streaming, en el diagnóstico médico y en los vehículos autónomos. A medida que esta tecnología avanza, surgen importantes preguntas éticas sobre privacidad, empleo y el impacto en la sociedad.",
            level: .advanced
        )
    ]
}
