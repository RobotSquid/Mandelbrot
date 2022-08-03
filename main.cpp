#include <SFML/Graphics.hpp>
#include <bits/stdc++.h>

int main() {
	const int w = 1280;
	const int h = 720;
	int f = 0;
	//sf::Vector2f c = sf::Vector2f(0.3245046418497685, 0.04855101129280834);
	sf::ContextSettings settings;
	//settings.antialiasingLevel = 4;
    sf::RenderWindow window(sf::VideoMode(w, h), "Mandelbrot Set", sf::Style::Default, settings);
	window.setFramerateLimit(10);
    sf::Texture texture;
	texture.create(w, h);
	sf::Sprite sprite(texture);

	if (!sf::Shader::isAvailable()) window.close();

	sf::Shader shader;
	if (!shader.loadFromFile("frag.glsl", sf::Shader::Fragment)) window.close();

	sf::Font font;
	if (!font.loadFromFile("arial.ttf")) window.close();
	sf::Text text;
	text.setFont(font);
	text.setCharacterSize(24);
	text.setFillColor(sf::Color::Red);
	text.setStyle(sf::Text::Bold);

	int shots = 0;
    while (window.isOpen()) {
		sf::Event event;
        while (window.pollEvent(event)) {
            if (event.type == sf::Event::Closed) window.close();
			if (event.type == sf::Event::KeyPressed && event.key.code == sf::Keyboard::S) {
				if (window.capture().saveToFile("screenshot_" + std::to_string(shots++) + ".png")) {
					std::cout << "screenshot saved" << std::endl;
				}
			}
        }
		shader.setUniform("frame", f);
		f++;
		
		window.clear();
		window.draw(sprite, &shader);

		std::ostringstream stream;
		stream << std::pow(10, f*0.2)*5 << std::scientific;
		text.setString(stream.str());
		window.draw(text);

        window.display();
    }
    return 0;
}