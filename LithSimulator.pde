import controlP5.*;
import java.io.File;

PImage sourceImage;

PImage simView;
ControlP5 cp5;

int panelW = 280;
int panelPadding = 16;
int panelImageGutter = 18;

int simW;
int simH;
int simSize;

float[] toneSeed;
float[] toneNoise;
float[] bandProfile;

float[] devA;
float[] devB;

float[] exhaustedA;
float[] exhaustedB;

float[] developedA;
float[] developedB;

final float DEFAULT_SEED_RATE = 0.030;
final float DEFAULT_INFECTION_RATE = 0.170;
final float DEFAULT_DEVELOP_RATE = 0.110;
final float DEFAULT_EXHAUSTION_RATE = 0.055;
final float DEFAULT_EXHAUSTION_RECOVERY = 0.012;
final float DEFAULT_AUTOCATALYTIC_RATE = 0.150;
final float DEFAULT_LIGHT_HUE = 33;
final float DEFAULT_LIGHT_SATURATION = 25;
final float DEFAULT_NOISE_AMOUNT = 0.0;
final float DEFAULT_AGITATION_BANDS = 0.0;

float seedRate = DEFAULT_SEED_RATE;
float infectionRate = DEFAULT_INFECTION_RATE;
float developRate = DEFAULT_DEVELOP_RATE;
float exhaustionRate = DEFAULT_EXHAUSTION_RATE;
float exhaustionRecovery = DEFAULT_EXHAUSTION_RECOVERY;
float autocatalyticRate = DEFAULT_AUTOCATALYTIC_RATE;
float lightHue = DEFAULT_LIGHT_HUE;
float lightSaturation = DEFAULT_LIGHT_SATURATION;
float noiseAmount = DEFAULT_NOISE_AMOUNT;
float agitationBands = DEFAULT_AGITATION_BANDS;
boolean paused = false;
boolean simulationReady = false;
long iterationCount = 0;
String saveStatus = "";
int saveStatusFrames = 0;

// setup 

void setup() {

    size(1300, 857);
	pixelDensity(displayDensity());

	initializeControls();
	saveStatus = "Click Load Image to begin";
	saveStatusFrames = 1000000;
}

void draw() {
	background(0);
	drawPanelBackground();

	if (simulationReady && sourceImage != null && devA != null && exhaustedA != null && developedA != null
		&& toneSeed != null && toneNoise != null && bandProfile != null) {
		if (!paused) {
			stepSimulation();
			iterationCount++;
		}

		renderSimulation();
		PImage frameView = simView;
		if (frameView == null || frameView.width <= 0 || frameView.height <= 0) {
			fill(210);
			text("No image loaded", panelW + panelImageGutter + 16, 32);
			return;
		}

		boolean portraitImage = frameView.height > frameView.width;

		float viewportX = panelW + panelImageGutter;
		float viewportW = width - viewportX - panelImageGutter;
		float viewportY = portraitImage ? panelImageGutter : 0;
		float viewportH = portraitImage ? height - panelImageGutter * 2 : height;

		float scale = min(viewportW / frameView.width, viewportH / frameView.height);
		float drawW = frameView.width * scale;
		float drawH = frameView.height * scale;
		float drawX = viewportX + (viewportW - drawW) * 0.5;
		float drawY = viewportY + (viewportH - drawH) * 0.5;

		image(frameView, drawX, drawY, drawW, drawH);
	} else {
		fill(210);
		text("No image loaded", panelW + panelImageGutter + 16, 32);
	}
}

void drawPanelBackground() {
	noStroke();
	fill(20, 24, 28);
	rect(0, 0, panelW, height);

	stroke(60);
	line(panelW - 1, 0, panelW - 1, height);
	noStroke();

	String status = paused ? "paused" : "running";
	fill(232);
	text("LITH SIMULATION", panelPadding, 24);
	text("status: " + status, panelPadding, 42);

	if (saveStatusFrames > 0) {
		fill(190);
		text(saveStatus, panelPadding, height - 14);
		saveStatusFrames--;
	}

	fill(210);
	text("iteration: " + iterationCount, panelPadding, height - 32);
}

void initializeControls() {
	cp5 = new ControlP5(this);

	int x = panelPadding;
	int y = 58;
	int fullW = panelW - panelPadding * 2;
	int w = fullW / 2;
	int h = 18;
	int gap = 34;

	cp5.addSlider("seedRate")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 1)
		.setValue(seedRate)
		.setLabel("seed rate");
	styleSlider(cp5.getController("seedRate"));
	y += gap;

	cp5.addSlider("infectionRate")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 1)
		.setValue(infectionRate)
		.setLabel("infection rate");
	styleSlider(cp5.getController("infectionRate"));
	y += gap;

	cp5.addSlider("developRate")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 1)
		.setValue(developRate)
		.setLabel("develop rate");
	styleSlider(cp5.getController("developRate"));
	y += gap;

	cp5.addSlider("exhaustionRate")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 1)
		.setValue(exhaustionRate)
		.setLabel("exhaustion rate");
	styleSlider(cp5.getController("exhaustionRate"));
	y += gap;

	cp5.addSlider("exhaustionRecovery")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 1)
		.setValue(exhaustionRecovery)
		.setLabel("recovery rate");
	styleSlider(cp5.getController("exhaustionRecovery"));
	y += gap;

	cp5.addSlider("autocatalyticRate")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 1)
		.setValue(autocatalyticRate)
		.setLabel("autocatalytic rate");
	styleSlider(cp5.getController("autocatalyticRate"));
	y += gap;

	cp5.addSlider("lightHue")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 360)
		.setValue(lightHue)
		.setLabel("light hue");
	styleSlider(cp5.getController("lightHue"));
	y += gap;

	cp5.addSlider("lightSaturation")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 100)
		.setValue(lightSaturation)
		.setLabel("light saturation");
	styleSlider(cp5.getController("lightSaturation"));
	y += gap;

	cp5.addSlider("noiseAmount")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 0.5)
		.setValue(noiseAmount)
		.setLabel("noise amount");
	styleSlider(cp5.getController("noiseAmount"));
	y += gap;

	cp5.addSlider("agitationBands")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 1)
		.setValue(agitationBands)
		.setLabel("agitation bands");
	styleSlider(cp5.getController("agitationBands"));
	y += gap;

	cp5.addButton("togglePause")
		.setPosition(x, y)
		.setSize(w, 48)
		.setLabel("Pause / Run");
	styleRunButton(cp5.getController("togglePause"));
	updateRunButtonState();

	y += 58;
	cp5.addButton("nudgeSimulation")
		.setPosition(x, y)
		.setSize(w, 24)
		.setLabel("NUDGE");
	styleStandardButton(cp5.getController("nudgeSimulation"));

	y += 34;
	cp5.addButton("resetSimulation")
		.setPosition(x, y)
		.setSize(w, 24)
		.setLabel("Restart")
		.setColorBackground(color(145, 85, 20))
		.setColorForeground(color(175, 105, 30))
		.setColorActive(color(200, 130, 45));

	y += 44;
	cp5.addButton("resetControls")
		.setPosition(x, y)
		.setSize(w, 24)
		.setLabel("Defaults");
	styleStandardButton(cp5.getController("resetControls"));

	y += 44;
	cp5.addButton("loadImageFromDialog")
		.setPosition(x, y)
		.setSize(w, 24)
		.setLabel("Load Image");
	styleStandardButton(cp5.getController("loadImageFromDialog"));

	y += 34;
	cp5.addButton("saveFullResPng")
		.setPosition(x, y)
		.setSize(w, 24)
		.setLabel("SAVE IMAGE");
	styleStandardButton(cp5.getController("saveFullResPng"));
}

public void resetSimulation() {
	if (sourceImage == null) {
		saveStatus = "load an image first";
		saveStatusFrames = 180;
		return;
	}

	initializeSimulation();
}

public void resetControls() {
	seedRate = DEFAULT_SEED_RATE;
	infectionRate = DEFAULT_INFECTION_RATE;
	developRate = DEFAULT_DEVELOP_RATE;
	exhaustionRate = DEFAULT_EXHAUSTION_RATE;
	exhaustionRecovery = DEFAULT_EXHAUSTION_RECOVERY;
	autocatalyticRate = DEFAULT_AUTOCATALYTIC_RATE;
	lightHue = DEFAULT_LIGHT_HUE;
	lightSaturation = DEFAULT_LIGHT_SATURATION;
	noiseAmount = DEFAULT_NOISE_AMOUNT;
	agitationBands = DEFAULT_AGITATION_BANDS;

	setControlValue("seedRate", seedRate);
	setControlValue("infectionRate", infectionRate);
	setControlValue("developRate", developRate);
	setControlValue("exhaustionRate", exhaustionRate);
	setControlValue("exhaustionRecovery", exhaustionRecovery);
	setControlValue("autocatalyticRate", autocatalyticRate);
	setControlValue("lightHue", lightHue);
	setControlValue("lightSaturation", lightSaturation);
	setControlValue("noiseAmount", noiseAmount);
	setControlValue("agitationBands", agitationBands);

	saveStatus = "controls reset";
	saveStatusFrames = 180;
}

void setControlValue(String controlName, float value) {
	if (cp5 == null) {
		return;
	}

	Controller<?> control = cp5.getController(controlName);
	if (control != null) {
		control.setValue(value);
	}
}

void styleSlider(Controller<?> slider) {
	if (slider == null) {
		return;
	}

	slider.setColorBackground(color(50,50,50));
	slider.setColorForeground(color(145, 85, 20));
	slider.setColorActive(color(175, 105, 30));
}

void styleStandardButton(Controller<?> button) {
	if (button == null) {
		return;
	}

	button.setColorBackground(color(50));
	button.setColorForeground(color(70));
	button.setColorActive(color(90));
}

void styleRunButton(Controller<?> button) {
	if (button == null) {
		return;
	}

	button.setColorBackground(color(50, 90, 50));
	button.setColorForeground(color(70, 120, 70));
	button.setColorActive(color(90, 150, 90));
}

void updateRunButtonState() {
	if (cp5 == null) {
		return;
	}

	Controller<?> runButton = cp5.getController("togglePause");
	if (runButton == null) {
		return;
	}

	styleRunButton(runButton);
}

public void togglePause() {
	paused = !paused;
	updateRunButtonState();
}

public void nudgeSimulation() {
	if (!paused || !simulationReady || sourceImage == null || devA == null || exhaustedA == null || developedA == null
		|| toneSeed == null || toneNoise == null || bandProfile == null) {
		return;
	}

	stepSimulation();
	iterationCount++;
}

public void saveFullResPng() {
	selectOutput("Save image as", "onSaveFileSelected");
}

public void onSaveFileSelected(File selection) {
	if (selection == null) {
		saveStatus = "save canceled";
		saveStatusFrames = 180;
		return;
	}

	if (simView == null) {
		saveStatus = "save failed: no image";
		saveStatusFrames = 180;
		return;
	}

	String filePath = selection.getAbsolutePath();
	if (!filePath.toLowerCase().endsWith(".tif")) {
		filePath += ".tif";
	}

	simView.save(filePath);
	saveStatus = "saved " + selection.getName();
	saveStatusFrames = 240;
}

public void loadImageFromDialog() {
	selectInput("Select an image", "onImageFileSelected");
}

public void onImageFileSelected(File selection) {
	if (selection == null) {
		saveStatus = "image selection canceled";
		saveStatusFrames = 180;
		return;
	}

	PImage loaded = loadImage(selection.getAbsolutePath());
	if (loaded == null || loaded.width <= 0 || loaded.height <= 0) {
		saveStatus = "failed to load image";
		saveStatusFrames = 240;
		return;
	}

	clearSimulationBuffers();
	sourceImage = loaded;
	initializeSimulation();
	paused = false;
	updateRunButtonState();
	saveStatus = "loaded " + selection.getName();
	saveStatusFrames = 240;
}

void clearSimulationBuffers() {
	simulationReady = false;
	simView = null;
	toneSeed = null;
	toneNoise = null;
	bandProfile = null;
	devA = null;
	devB = null;
	exhaustedA = null;
	exhaustedB = null;
	developedA = null;
	developedB = null;
	simW = 0;
	simH = 0;
	simSize = 0;
}

void initializeSimulation() {
	clearSimulationBuffers();

	simW = sourceImage.width;
	simH = sourceImage.height;
	simSize = simW * simH;
	iterationCount = 0;

	toneSeed = new float[simSize];

	devA = new float[simSize];
	devB = new float[simSize];

	exhaustedA = new float[simSize];
	exhaustedB = new float[simSize];

	developedA = new float[simSize];
	developedB = new float[simSize];
	toneNoise = new float[simSize];
	bandProfile = new float[simW];

	loadToneSeed();
	buildBandProfile();

	simView = createImage(simW, simH, RGB);
	simulationReady = true;
}

void loadToneSeed() {
	sourceImage.loadPixels();

	for (int y = 0; y < simH; y++) {
		int srcY = y;
		for (int x = 0; x < simW; x++) {
			int srcX = x;
			int srcIdx = srcY * sourceImage.width + srcX;
			int idx = y * simW + x;

			float b = brightness(sourceImage.pixels[srcIdx]) / 255.0;
			float t = constrain(1.0 - b, 0, 1);
			float n = random(-1.0, 1.0);

			toneSeed[idx] = t;
			toneNoise[idx] = n;
			devA[idx] = 0;
			exhaustedA[idx] = 0;
			developedA[idx] = pow(t, 1.6) * 0.015;
		}
	}
}

void buildBandProfile() {
	for (int x = 0; x < simW; x++) {
		bandProfile[x] = random(-1.0, 1.0);
	}

	float[] temp = new float[simW];
	for (int pass = 0; pass < 6; pass++) {
		for (int x = 0; x < simW; x++) {
			float c = bandProfile[x] * 0.5;
			float l = bandProfile[max(0, x - 1)] * 0.25;
			float r = bandProfile[min(simW - 1, x + 1)] * 0.25;
			temp[x] = c + l + r;
		}

		arrayCopy(temp, bandProfile);
	}

	float maxAbs = 0.0001;
	for (int x = 0; x < simW; x++) {
		maxAbs = max(maxAbs, abs(bandProfile[x]));
	}
	for (int x = 0; x < simW; x++) {
		bandProfile[x] /= maxAbs;
	}
}

void stepSimulation() {
	if (devA == null || devB == null || exhaustedA == null || exhaustedB == null || developedA == null || developedB == null
		|| toneSeed == null || toneNoise == null || bandProfile == null) {
		return;
	}

	for (int y = 0; y < simH; y++) {
		for (int x = 0; x < simW; x++) {
			int idx = y * simW + x;

			float localDev = devA[idx];
			float localExhausted = exhaustedA[idx];
			float localDeveloped = developedA[idx];
			float band = bandProfile[x] * agitationBands;
			float localNoiseAmount = max(0, noiseAmount * (1.0 + band));
			float t = constrain(toneSeed[idx] + toneNoise[idx] * localNoiseAmount, 0, 1);

			float neighborDev = neighborhoodDeveloper(x, y);

			float freshFraction = 1.0 - localExhausted;
			float seed = seedRate * t * freshFraction * (1.0 - localDeveloped);
			float autocatalysis = autocatalyticRate * localDeveloped * t * freshFraction;
			float infection = infectionRate * max(0, neighborDev - localDev) * freshFraction;

			float devGain = seed + autocatalysis + infection;
			float devLoss = exhaustionRate * localDev;
			float nextDev = constrain(localDev + devGain - devLoss, 0, 1);

			float dDevelop = developRate * nextDev * t * (1.0 - localDeveloped);
			float nextDeveloped = constrain(localDeveloped + dDevelop, 0, 1);

			float exhaustGain = exhaustionRate * (nextDev + dDevelop * 0.5);
			float exhaustLoss = exhaustionRecovery * (1.0 - nextDev);
			float nextExhausted = constrain(localExhausted + exhaustGain - exhaustLoss, 0, 1);

			devB[idx] = nextDev;
			exhaustedB[idx] = nextExhausted;
			developedB[idx] = nextDeveloped;
		}
	}

	swapBuffers();
}

float neighborhoodDeveloper(int x, int y) {
	float sum = 0;
	float weight = 0;

	for (int oy = -1; oy <= 1; oy++) {
		int ny = y + oy;
		if (ny < 0 || ny >= simH) {
			continue;
		}

		for (int ox = -1; ox <= 1; ox++) {
			int nx = x + ox;
			if (nx < 0 || nx >= simW) {
				continue;
			}

			if (ox == 0 && oy == 0) {
				continue;
			}

			float w = (abs(ox) + abs(oy) == 2) ? 0.7071 : 1.0;
			sum += devA[ny * simW + nx] * w;
			weight += w;
		}
	}

	if (weight == 0) {
		return devA[y * simW + x];
	}

	return sum / weight;
}

void swapBuffers() {
	float[] tmp;

	tmp = devA;
	devA = devB;
	devB = tmp;

	tmp = exhaustedA;
	exhaustedA = exhaustedB;
	exhaustedB = tmp;

	tmp = developedA;
	developedA = developedB;
	developedB = tmp;
}

void renderSimulation() {
	PImage view = simView;
	float[] developed = developedA;
	float[] exhausted = exhaustedA;

	if (view == null || developed == null || exhausted == null) {
		return;
	}

	view.loadPixels();
	if (view.pixels == null) {
		return;
	}

	// Light-tone anchor is controlled by hue/saturation sliders.
	float[] lightTone = hueSatToRgb(lightHue, lightSaturation, 80);
	float sepiaR = lightTone[0];
	float sepiaG = lightTone[1];
	float sepiaB = lightTone[2];
	float sepiaPivot = 0.55;
	int maxCount = min(simSize, min(view.pixels.length, min(developed.length, exhausted.length)));

	for (int i = 0; i < maxCount; i++) {
		float d = developed[i];
		float e = exhausted[i];

		float ink = constrain(d + 0.35 * d * d, 0, 1);
		float paper = 1.0 - ink;
		paper *= (1.0 - 0.10 * e);

		// density: 0 -> white paper, 1 -> fully developed black.
		float density = 1.0 - constrain(paper, 0, 1);
		float r;
		float g;
		float b;

		if (density <= sepiaPivot) {
			// Low density: white to sepia.
			float t = density / sepiaPivot;
			r = lerp(255, sepiaR, t);
			g = lerp(255, sepiaG, t);
			b = lerp(255, sepiaB, t);
		} else {
			// High density: sepia to black.
			float t = (density - sepiaPivot) / (1.0 - sepiaPivot);
			r = lerp(sepiaR, 0, t);
			g = lerp(sepiaG, 0, t);
			b = lerp(sepiaB, 0, t);
		}

		view.pixels[i] = color(r, g, b);
	}

	view.updatePixels();
}

float[] hueSatToRgb(float hueDeg, float satPct, float valuePct) {
	float h = (hueDeg % 360 + 360) % 360;
	float s = constrain(satPct, 0, 100) / 100.0;
	float v = constrain(valuePct, 0, 100) / 100.0;

	float c = v * s;
	float hp = h / 60.0;
	float x = c * (1.0 - abs(hp % 2 - 1.0));

	float rp = 0;
	float gp = 0;
	float bp = 0;

	if (hp < 1) {
		rp = c;
		gp = x;
	} else if (hp < 2) {
		rp = x;
		gp = c;
	} else if (hp < 3) {
		gp = c;
		bp = x;
	} else if (hp < 4) {
		gp = x;
		bp = c;
	} else if (hp < 5) {
		rp = x;
		bp = c;
	} else {
		rp = c;
		bp = x;
	}

	float m = v - c;
	float r = (rp + m) * 255.0;
	float g = (gp + m) * 255.0;
	float b = (bp + m) * 255.0;

	return new float[] {r, g, b};
}
