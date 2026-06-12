import Foundation

enum PreloadedLibrary {
    static let items: [LibraryItem] = basicTexts + basicTextsEnglish + intermediateTexts + intermediateTextsEnglish + advancedTexts + advancedTextsEnglish


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


    static let basicTextsEnglish: [LibraryItem] = [
        LibraryItem(
            title: "The Sun and the Moon",
            body: "The sun shines during the day. The moon shines at night. The sun is big and yellow. The moon is white and round. It is warm during the day. It is cold at night. The sun and the moon take care of the Earth.",
            level: .basic
        ),
        LibraryItem(
            title: "My Pet",
            body: "I have a dog named Buddy. Buddy is brown with white spots. He likes to run and play with his ball. Every day I give him food and fresh water. Buddy makes me very happy.",
            level: .basic
        ),
        LibraryItem(
            title: "The Hard-Working Ant",
            body: "An ant was walking through the field looking for food. She found a big seed and carried it to her home. The seed was very heavy, but the ant did not give up. When she got home, her friends helped her store the seed. Together they would have food for the winter.",
            level: .basic
        ),
        LibraryItem(
            title: "The Seasons of the Year",
            body: "In spring the plants bloom. It is warm and it rains. In summer the sun heats a lot. The days are long. In fall the leaves on the trees change color and fall. In winter it is cold and sometimes it snows. Each season has something special.",
            level: .basic
        ),
        LibraryItem(
            title: "The Village Baker",
            body: "Mr. Baker gets up very early each morning. He lights his oven and prepares the bread dough. He kneads, shapes, and bakes the rolls. At seven in the morning the bread is ready. The delicious smell of bread fills the whole village.",
            level: .basic
        )
    ]


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


    static let intermediateTextsEnglish: [LibraryItem] = [
        LibraryItem(
            title: "The Water We Drink",
            body: "Water is a very valuable resource. Without water, life cannot exist. Most of the water on Earth is in the oceans, but that water is salty. Only a small part is fresh water, which is what we can drink. Fresh water is found in rivers, lakes, and springs. It is important to take care of water: turn off the tap when we are not using it and avoid polluting rivers. We can all help to conserve it.",
            level: .intermediate
        ),
        LibraryItem(
            title: "The Tropical Rainforest",
            body: "The tropical rainforest is one of the richest ecosystems on the planet. Millions of species of plants, animals, and insects live in it. The trees are so tall that they form a green roof called a canopy, which protects small plants from direct sunlight. Rainforests produce a lot of oxygen and regulate Earth's climate. That is why it is so important to protect them from deforestation.",
            level: .intermediate
        ),
        LibraryItem(
            title: "How the Brain Works",
            body: "The brain is the most complex organ in our body. It weighs approximately 1.4 kilograms and is shaped like a walnut. It is made up of billions of cells called neurons. Neurons communicate with each other through electrical and chemical signals. The brain controls all movements of the body, thoughts, memories, and emotions. While we sleep, the brain continues working to process what we learned during the day.",
            level: .intermediate
        )
    ]


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


    static let advancedTextsEnglish: [LibraryItem] = [
        LibraryItem(
            title: "The Industrial Revolution",
            body: "The Industrial Revolution was a period of economic and social transformation that began in England in the late eighteenth century. The invention of the steam engine allowed processes that were previously done by hand to be mechanized, which greatly increased the production of goods. Factories replaced artisan workshops and thousands of people migrated from the countryside to cities in search of work. This change brought important technological advances, but also new social problems such as long working hours, child labor, and pollution. Its effects shaped the modern world as we know it today.",
            level: .advanced
        ),
        LibraryItem(
            title: "Artificial Intelligence",
            body: "Artificial intelligence is a branch of computer science that seeks to create systems capable of performing tasks that normally require human intelligence, such as recognizing images, understanding natural language, or making decisions. AI systems learn from large amounts of data using machine learning algorithms. Today, AI is present in many aspects of our daily lives: in voice assistants, in recommendations on streaming platforms, in medical diagnosis, and in autonomous vehicles. As this technology advances, important ethical questions arise about privacy, employment, and the impact on society.",
            level: .advanced
        )
    ]
}
