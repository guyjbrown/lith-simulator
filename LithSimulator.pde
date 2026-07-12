import controlP5.*;
import java.io.File;
import javax.swing.JOptionPane;

PImage sourceImage;

PImage simView;
ControlP5 cp5;

int panelW = 320;
int panelPadding = 16;
int panelImageGutter = 18;

int simW;
int simH;
int simSize;

float[] toneSeed;
float[] toneNoise;
float[] verticalBandProfile;
float[] horizontalBandProfile;

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
final float DEFAULT_EXPOSURE_STOPS = 0.0;
final float DEFAULT_CURVE_TOE_STOPS = -0.95;
final float DEFAULT_CURVE_SHOULDER_STOPS = 3.28;
final float DEFAULT_LIGHT_HUE = 33;
final float DEFAULT_LIGHT_SATURATION = 25;
final float DEFAULT_PAPER_BASE_DENSITY = 0.05;
final float DEFAULT_NOISE_AMOUNT = 0.1;
final float DEFAULT_GRAIN_BALANCE = 0.5;
final float DEFAULT_VERTICAL_BANDING = 0.0;
final float DEFAULT_HORIZONTAL_BANDING = 0.0;
final float RATE_SLIDER_MIN = 0.001;
final float RATE_SLIDER_MAX = 1.0;
final String PRESETS_FILE_NAME = "presets.json";

float seedRate = DEFAULT_SEED_RATE;
float infectionRate = DEFAULT_INFECTION_RATE;
float developRate = DEFAULT_DEVELOP_RATE;
float exhaustionRate = DEFAULT_EXHAUSTION_RATE;
float exhaustionRecovery = DEFAULT_EXHAUSTION_RECOVERY;
float autocatalyticRate = DEFAULT_AUTOCATALYTIC_RATE;
float exposureStops = DEFAULT_EXPOSURE_STOPS;
float curveToeStops = DEFAULT_CURVE_TOE_STOPS;
float curveShoulderStops = DEFAULT_CURVE_SHOULDER_STOPS;
float lightHue = DEFAULT_LIGHT_HUE;
float lightSaturation = DEFAULT_LIGHT_SATURATION;
float paperBaseDensity = DEFAULT_PAPER_BASE_DENSITY;
float noiseAmount = DEFAULT_NOISE_AMOUNT;
float grainBalance = DEFAULT_GRAIN_BALANCE;
float verticalBanding = DEFAULT_VERTICAL_BANDING;
float horizontalBanding = DEFAULT_HORIZONTAL_BANDING;
boolean paused = false;
boolean simulationReady = false;
boolean suppressRateSliderCallbacks = false;
boolean suppressPresetSelection = false;
JSONArray presets = new JSONArray();
long iterationCount = 0;
long renderedIteration = -1;
float renderedLightHue = Float.NaN;
float renderedLightSaturation = Float.NaN;
float renderedPaperBaseDensity = Float.NaN;
String saveStatus = "";
int saveStatusFrames = 0;

// setup 

void setup() {

	size(1400, 840);
	pixelDensity(displayDensity());

	loadPresets();
	initializeControls();
	saveStatus = "Click Load Image to begin";
	saveStatusFrames = 1000000;
}

void draw() {
	background(0);
	drawPanelBackground();

	if (simulationReady && sourceImage != null && devA != null && exhaustedA != null && developedA != null
		&& toneSeed != null && toneNoise != null && verticalBandProfile != null && horizontalBandProfile != null) {
		if (!paused) {
			stepSimulation();
			iterationCount++;
		}

		// A paused simulation often redraws only because the mouse moved. Reuse
		// its pixels unless simulation state or a render-only control changed.
		if (renderedIteration != iterationCount
			|| renderedLightHue != lightHue
			|| renderedLightSaturation != lightSaturation
			|| renderedPaperBaseDensity != paperBaseDensity) {
			renderSimulation();
		}
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
		drawPixelTooltip(frameView, drawX, drawY, drawW, drawH);
	} else {
		fill(210);
		text("No image loaded", panelW + panelImageGutter + 16, 32);
	}
}

void drawPixelTooltip(PImage imageView, float imageX, float imageY, float imageW, float imageH) {
	if (imageView == null || imageView.pixels == null || imageW <= 0 || imageH <= 0) {
		return;
	}

	if (mouseX < imageX || mouseX >= imageX + imageW
		|| mouseY < imageY || mouseY >= imageY + imageH) {
		return;
	}

	int pixelX = constrain(floor((mouseX - imageX) * imageView.width / imageW), 0, imageView.width - 1);
	int pixelY = constrain(floor((mouseY - imageY) * imageView.height / imageH), 0, imageView.height - 1);
	int pixelIndex = pixelY * imageView.width + pixelX;
	if (pixelIndex < 0 || pixelIndex >= imageView.pixels.length) {
		return;
	}

	int pixelColor = imageView.pixels[pixelIndex];
	String label = "RGB " + round(red(pixelColor)) + ", "
		+ round(green(pixelColor)) + ", " + round(blue(pixelColor));

	textSize(12);
	float paddingX = 7;
	float tooltipW = textWidth(label) + paddingX * 2;
	float tooltipH = 24;
	float tooltipX = constrain(mouseX + 14, 4, width - tooltipW - 4);
	float tooltipY = mouseY + 18;
	if (tooltipY + tooltipH > height - 4) {
		tooltipY = mouseY - tooltipH - 10;
	}

	noStroke();
	fill(20, 24, 28, 230);
	rect(tooltipX, tooltipY, tooltipW, tooltipH, 4);
	fill(240);
	textAlign(LEFT, CENTER);
	text(label, tooltipX + paddingX, tooltipY + tooltipH * 0.5 - 1);
	textAlign(LEFT, BASELINE);
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
	textSize(16);
	text("LITH SIMULATION", panelPadding, 24);
	textSize(12);
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
	suppressRateSliderCallbacks = true;
	suppressPresetSelection = true;
	cp5 = new ControlP5(this);

	int x = panelPadding;
	int y = 58;
	int fullW = 70+panelW - panelPadding * 2;
	int w = fullW / 2;
	int h = 18;
	int gap = 27;
	int actionW = panelW - panelPadding * 2;
	int buttonGap = 16;
	int buttonW = (actionW - buttonGap) / 2;
	int buttonH = 26;
	int buttonRowGap = 42;
	int secondButtonX = x + buttonW + buttonGap;

	cp5.addSlider("seedRateSlider")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 1)
		.setValue(rateToSliderPosition(seedRate))
		.setLabel("seed rate");
	styleSlider(cp5.getController("seedRateSlider"));
	updateLogRateValueLabel("seedRateSlider", seedRate);
	y += gap;

	cp5.addSlider("infectionRateSlider")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 1)
		.setValue(rateToSliderPosition(infectionRate))
		.setLabel("infection rate");
	styleSlider(cp5.getController("infectionRateSlider"));
	updateLogRateValueLabel("infectionRateSlider", infectionRate);
	y += gap;

	cp5.addSlider("developRateSlider")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 1)
		.setValue(rateToSliderPosition(developRate))
		.setLabel("develop rate");
	styleSlider(cp5.getController("developRateSlider"));
	updateLogRateValueLabel("developRateSlider", developRate);
	y += gap;

	cp5.addSlider("exhaustionRateSlider")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 1)
		.setValue(rateToSliderPosition(exhaustionRate))
		.setLabel("exhaustion rate");
	styleSlider(cp5.getController("exhaustionRateSlider"));
	updateLogRateValueLabel("exhaustionRateSlider", exhaustionRate);
	y += gap;

	cp5.addSlider("exhaustionRecoverySlider")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 1)
		.setValue(rateToSliderPosition(exhaustionRecovery))
		.setLabel("recovery rate");
	styleSlider(cp5.getController("exhaustionRecoverySlider"));
	updateLogRateValueLabel("exhaustionRecoverySlider", exhaustionRecovery);
	y += gap;

	cp5.addSlider("autocatalyticRateSlider")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 1)
		.setValue(rateToSliderPosition(autocatalyticRate))
		.setLabel("autocatalytic rate");
	styleSlider(cp5.getController("autocatalyticRateSlider"));
	updateLogRateValueLabel("autocatalyticRateSlider", autocatalyticRate);
	y += gap;

	cp5.addSlider("exposureStopsSlider")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 4)
		.setValue(exposureStops)
		.setDecimalPrecision(2)
		.setLabel("exposure (stops)");
	styleSlider(cp5.getController("exposureStopsSlider"));
	y += gap;

	cp5.addSlider("curveToeStopsSlider")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(-2, 4)
		.setValue(curveToeStops)
		.setDecimalPrecision(2)
		.setLabel("curve toe (stops)");
	styleSlider(cp5.getController("curveToeStopsSlider"));
	y += gap;

	cp5.addSlider("curveShoulderStopsSlider")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0.25, 8)
		.setValue(curveShoulderStops)
		.setDecimalPrecision(2)
		.setLabel("curve shoulder (stops)");
	styleSlider(cp5.getController("curveShoulderStopsSlider"));
	y += gap;

	cp5.addSlider("lightHue")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 360)
		.setValue(lightHue)
		.setNumberOfTickMarks(361)
		.showTickMarks(false)
		.setDecimalPrecision(0)
		.setLabel("hue");
	styleSlider(cp5.getController("lightHue"));
	y += gap;

	cp5.addSlider("lightSaturation")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 100)
		.setValue(lightSaturation)
		.setNumberOfTickMarks(101)
		.showTickMarks(false)
		.setDecimalPrecision(0)
		.setLabel("saturation");
	styleSlider(cp5.getController("lightSaturation"));
	y += gap;

	cp5.addSlider("paperBaseDensity")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 0.3)
		.setValue(paperBaseDensity)
		.setDecimalPrecision(2)
		.setLabel("paper base density");
	styleSlider(cp5.getController("paperBaseDensity"));
	y += gap;

	cp5.addSlider("noiseAmount")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 0.5)
		.setValue(noiseAmount)
		.setLabel("grain amount");
	styleSlider(cp5.getController("noiseAmount"));
	y += gap;

	cp5.addSlider("grainBalance")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 1)
		.setValue(grainBalance)
		.setLabel("grain balance");
	styleSlider(cp5.getController("grainBalance"));
	y += gap;

	cp5.addSlider("verticalBanding")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 1)
		.setValue(verticalBanding)
		.setLabel("VERTICAL BANDING");
	styleSlider(cp5.getController("verticalBanding"));
	y += gap;

	cp5.addSlider("horizontalBanding")
		.setPosition(x, y)
		.setSize(w, h)
		.setRange(0, 1)
		.setValue(horizontalBanding)
		.setLabel("HORIZONTAL BANDING");
	styleSlider(cp5.getController("horizontalBanding"));
	y += gap;

	cp5.addButton("togglePause")
		.setPosition(x, y)
		.setSize(buttonW, buttonH)
		.setLabel("Pause / Run");
	styleRunButton(cp5.getController("togglePause"));
	updateRunButtonState();

	cp5.addButton("nudgeSimulation")
		.setPosition(secondButtonX, y)
		.setSize(buttonW, buttonH)
		.setLabel("NUDGE");
	styleStandardButton(cp5.getController("nudgeSimulation"));

	y += buttonRowGap;
	cp5.addButton("resetSimulation")
		.setPosition(x, y)
		.setSize(buttonW, buttonH)
		.setLabel("Restart")
		.setColorBackground(color(145, 85, 20))
		.setColorForeground(color(175, 105, 30))
		.setColorActive(color(200, 130, 45));

	cp5.addButton("resetControls")
		.setPosition(secondButtonX, y)
		.setSize(buttonW, buttonH)
		.setLabel("Defaults");
	styleStandardButton(cp5.getController("resetControls"));

	y += buttonRowGap;
	cp5.addButton("loadImageFromDialog")
		.setPosition(x, y)
		.setSize(buttonW, buttonH)
		.setLabel("Load Image");
	styleStandardButton(cp5.getController("loadImageFromDialog"));

	cp5.addButton("saveFullResPng")
		.setPosition(secondButtonX, y)
		.setSize(buttonW, buttonH)
		.setLabel("SAVE IMAGE");
	styleStandardButton(cp5.getController("saveFullResPng"));

	y += buttonRowGap;
	cp5.addButton("saveAsPreset")
		.setPosition(x, y)
		.setSize(actionW, buttonH)
		.setLabel("SAVE AS PRESET");
	styleStandardButton(cp5.getController("saveAsPreset"));

	y += buttonRowGap;
	ScrollableList presetMenu = cp5.addScrollableList("presetMenu")
		.setPosition(x, y)
		.setSize(actionW, 116)
		.setBarHeight(24)
		.setItemHeight(22)
		.setType(ControlP5.DROPDOWN)
		.setLabel("PRESETS")
		.close();
	presetMenu.setBackgroundColor(color(20, 24, 28));
	styleStandardButton(presetMenu);
	refreshPresetMenu();

	suppressRateSliderCallbacks = false;
	suppressPresetSelection = false;
}

public void resetSimulation() {
	if (sourceImage == null) {
		saveStatus = "load an image first";
		saveStatusFrames = 180;
		return;
	}

	initializeSimulation();
	paused = false;
	updateRunButtonState();
}

public void resetControls() {
	seedRate = DEFAULT_SEED_RATE;
	infectionRate = DEFAULT_INFECTION_RATE;
	developRate = DEFAULT_DEVELOP_RATE;
	exhaustionRate = DEFAULT_EXHAUSTION_RATE;
	exhaustionRecovery = DEFAULT_EXHAUSTION_RECOVERY;
	autocatalyticRate = DEFAULT_AUTOCATALYTIC_RATE;
	exposureStops = DEFAULT_EXPOSURE_STOPS;
	curveToeStops = DEFAULT_CURVE_TOE_STOPS;
	curveShoulderStops = DEFAULT_CURVE_SHOULDER_STOPS;
	lightHue = DEFAULT_LIGHT_HUE;
	lightSaturation = DEFAULT_LIGHT_SATURATION;
	paperBaseDensity = DEFAULT_PAPER_BASE_DENSITY;
	noiseAmount = DEFAULT_NOISE_AMOUNT;
	grainBalance = DEFAULT_GRAIN_BALANCE;
	verticalBanding = DEFAULT_VERTICAL_BANDING;
	horizontalBanding = DEFAULT_HORIZONTAL_BANDING;

	syncParameterControls();

	saveStatus = "controls reset";
	saveStatusFrames = 180;
}

void syncParameterControls() {
	setLogRateControlValue("seedRateSlider", seedRate);
	setLogRateControlValue("infectionRateSlider", infectionRate);
	setLogRateControlValue("developRateSlider", developRate);
	setLogRateControlValue("exhaustionRateSlider", exhaustionRate);
	setLogRateControlValue("exhaustionRecoverySlider", exhaustionRecovery);
	setLogRateControlValue("autocatalyticRateSlider", autocatalyticRate);
	setControlValue("exposureStopsSlider", exposureStops);
	setControlValue("curveToeStopsSlider", curveToeStops);
	setControlValue("curveShoulderStopsSlider", curveShoulderStops);
	setControlValue("lightHue", lightHue);
	setControlValue("lightSaturation", lightSaturation);
	setControlValue("paperBaseDensity", paperBaseDensity);
	setControlValue("noiseAmount", noiseAmount);
	setControlValue("grainBalance", grainBalance);
	setControlValue("verticalBanding", verticalBanding);
	setControlValue("horizontalBanding", horizontalBanding);
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

float rateToSliderPosition(float rate) {
	float safeRate = constrain(rate, RATE_SLIDER_MIN, RATE_SLIDER_MAX);
	return log(safeRate / RATE_SLIDER_MIN) / log(RATE_SLIDER_MAX / RATE_SLIDER_MIN);
}

float sliderPositionToRate(float position) {
	float normalizedPosition = constrain(position, 0, 1);
	return RATE_SLIDER_MIN * pow(RATE_SLIDER_MAX / RATE_SLIDER_MIN, normalizedPosition);
}

void setLogRateControlValue(String controlName, float rate) {
	boolean wasSuppressed = suppressRateSliderCallbacks;
	suppressRateSliderCallbacks = true;
	setControlValue(controlName, rateToSliderPosition(rate));
	suppressRateSliderCallbacks = wasSuppressed;
	updateLogRateValueLabel(controlName, rate);
}

void updateLogRateValueLabel(String controlName, float rate) {
	if (cp5 == null) {
		return;
	}

	Controller<?> control = cp5.getController(controlName);
	if (control != null) {
		int decimalPlaces = rate < 0.01 ? 4 : 3;
		control.setValueLabel(nf(rate, 1, decimalPlaces));
	}
}

public void seedRateSlider(float position) {
	if (suppressRateSliderCallbacks) {
		return;
	}
	seedRate = sliderPositionToRate(position);
	updateLogRateValueLabel("seedRateSlider", seedRate);
}

public void infectionRateSlider(float position) {
	if (suppressRateSliderCallbacks) {
		return;
	}
	infectionRate = sliderPositionToRate(position);
	updateLogRateValueLabel("infectionRateSlider", infectionRate);
}

public void developRateSlider(float position) {
	if (suppressRateSliderCallbacks) {
		return;
	}
	developRate = sliderPositionToRate(position);
	updateLogRateValueLabel("developRateSlider", developRate);
}

public void exhaustionRateSlider(float position) {
	if (suppressRateSliderCallbacks) {
		return;
	}
	exhaustionRate = sliderPositionToRate(position);
	updateLogRateValueLabel("exhaustionRateSlider", exhaustionRate);
}

public void exhaustionRecoverySlider(float position) {
	if (suppressRateSliderCallbacks) {
		return;
	}
	exhaustionRecovery = sliderPositionToRate(position);
	updateLogRateValueLabel("exhaustionRecoverySlider", exhaustionRecovery);
}

public void autocatalyticRateSlider(float position) {
	if (suppressRateSliderCallbacks) {
		return;
	}
	autocatalyticRate = sliderPositionToRate(position);
	updateLogRateValueLabel("autocatalyticRateSlider", autocatalyticRate);
}

public void exposureStopsSlider(float stops) {
	if (suppressRateSliderCallbacks) {
		return;
	}

	exposureStops = constrain(stops, 0, 4);
	if (sourceImage != null) {
		saveStatus = "exposure applies on next restart";
		saveStatusFrames = 180;
	}
}

public void curveToeStopsSlider(float stops) {
	if (suppressRateSliderCallbacks) {
		return;
	}

	curveToeStops = constrain(stops, -2, 4);
	if (sourceImage != null) {
		saveStatus = "curve toe applies on next restart";
		saveStatusFrames = 180;
	}
}

public void curveShoulderStopsSlider(float stops) {
	if (suppressRateSliderCallbacks) {
		return;
	}

	curveShoulderStops = constrain(stops, 0.25, 8);
	if (sourceImage != null) {
		saveStatus = "curve shoulder applies on next restart";
		saveStatusFrames = 180;
	}
}

void loadPresets() {
	presets = new JSONArray();
	File presetsFile = new File(sketchPath(PRESETS_FILE_NAME));
	if (!presetsFile.exists()) {
		return;
	}

	try {
		JSONObject root = loadJSONObject(presetsFile.getAbsolutePath());
		if (root != null && root.hasKey("presets")) {
			JSONArray loadedPresets = root.getJSONArray("presets");
			if (loadedPresets != null) {
				presets = loadedPresets;
			}
		}
	} catch (Exception error) {
		println("Could not load presets: " + error.getMessage());
	}
}

void savePresets() {
	JSONObject root = new JSONObject();
	root.setInt("version", 1);
	root.setJSONArray("presets", presets);
	saveJSONObject(root, sketchPath(PRESETS_FILE_NAME));
}

JSONObject captureCurrentPreset(String name) {
	JSONObject preset = new JSONObject();
	preset.setString("name", name);
	preset.setFloat("seedRate", seedRate);
	preset.setFloat("infectionRate", infectionRate);
	preset.setFloat("developRate", developRate);
	preset.setFloat("exhaustionRate", exhaustionRate);
	preset.setFloat("exhaustionRecovery", exhaustionRecovery);
	preset.setFloat("autocatalyticRate", autocatalyticRate);
	preset.setFloat("exposureStops", exposureStops);
	preset.setFloat("curveToeStops", curveToeStops);
	preset.setFloat("curveShoulderStops", curveShoulderStops);
	preset.setFloat("lightHue", lightHue);
	preset.setFloat("lightSaturation", lightSaturation);
	preset.setFloat("paperBaseDensity", paperBaseDensity);
	preset.setFloat("noiseAmount", noiseAmount);
	preset.setFloat("grainBalance", grainBalance);
	preset.setFloat("verticalBanding", verticalBanding);
	preset.setFloat("horizontalBanding", horizontalBanding);
	return preset;
}

int findPresetIndex(String name) {
	for (int i = 0; i < presets.size(); i++) {
		JSONObject preset = presets.getJSONObject(i);
		if (preset != null && name.equalsIgnoreCase(preset.getString("name", ""))) {
			return i;
		}
	}
	return -1;
}

public void saveAsPreset() {
	String name = JOptionPane.showInputDialog(null, "Preset name:", "Save as preset", JOptionPane.PLAIN_MESSAGE);
	if (name == null) {
		return;
	}

	name = name.trim();
	if (name.length() == 0) {
		saveStatus = "preset name cannot be empty";
		saveStatusFrames = 180;
		return;
	}

	JSONObject preset = captureCurrentPreset(name);
	int existingIndex = findPresetIndex(name);
	if (existingIndex >= 0) {
		presets.setJSONObject(existingIndex, preset);
	} else {
		presets.append(preset);
	}

	try {
		savePresets();
		refreshPresetMenu();
		saveStatus = "saved preset " + name;
		saveStatusFrames = 240;
	} catch (Exception error) {
		saveStatus = "failed to save preset";
		saveStatusFrames = 240;
		println("Could not save presets: " + error.getMessage());
	}
}

void refreshPresetMenu() {
	if (cp5 == null) {
		return;
	}

	Controller<?> control = cp5.getController("presetMenu");
	if (!(control instanceof ScrollableList)) {
		return;
	}

	boolean wasSuppressed = suppressPresetSelection;
	suppressPresetSelection = true;
	ScrollableList menu = (ScrollableList) control;
	menu.clear();
	menu.setCaptionLabel(presets.size() == 0 ? "NO PRESETS" : "PRESETS");
	for (int i = 0; i < presets.size(); i++) {
		JSONObject preset = presets.getJSONObject(i);
		if (preset != null) {
			String name = preset.getString("name", "Preset " + (i + 1));
			menu.addItem(name, i);
		}
	}
	menu.close();
	suppressPresetSelection = wasSuppressed;
}

public void presetMenu(float selectedValue) {
	if (suppressPresetSelection) {
		return;
	}

	int selectedIndex = round(selectedValue);
	if (selectedIndex < 0 || selectedIndex >= presets.size()) {
		return;
	}

	JSONObject preset = presets.getJSONObject(selectedIndex);
	if (preset == null) {
		return;
	}

	seedRate = constrain(preset.getFloat("seedRate", seedRate), RATE_SLIDER_MIN, RATE_SLIDER_MAX);
	infectionRate = constrain(preset.getFloat("infectionRate", infectionRate), RATE_SLIDER_MIN, RATE_SLIDER_MAX);
	developRate = constrain(preset.getFloat("developRate", developRate), RATE_SLIDER_MIN, RATE_SLIDER_MAX);
	exhaustionRate = constrain(preset.getFloat("exhaustionRate", exhaustionRate), RATE_SLIDER_MIN, RATE_SLIDER_MAX);
	exhaustionRecovery = constrain(preset.getFloat("exhaustionRecovery", exhaustionRecovery), RATE_SLIDER_MIN, RATE_SLIDER_MAX);
	autocatalyticRate = constrain(preset.getFloat("autocatalyticRate", autocatalyticRate), RATE_SLIDER_MIN, RATE_SLIDER_MAX);
	exposureStops = constrain(preset.getFloat("exposureStops", DEFAULT_EXPOSURE_STOPS), 0, 4);
	curveToeStops = constrain(preset.getFloat("curveToeStops", DEFAULT_CURVE_TOE_STOPS), -2, 4);
	curveShoulderStops = constrain(preset.getFloat("curveShoulderStops", DEFAULT_CURVE_SHOULDER_STOPS), 0.25, 8);
	lightHue = constrain(preset.getFloat("lightHue", lightHue), 0, 360);
	lightSaturation = constrain(preset.getFloat("lightSaturation", lightSaturation), 0, 100);
	paperBaseDensity = constrain(preset.getFloat("paperBaseDensity", DEFAULT_PAPER_BASE_DENSITY), 0, 0.3);
	noiseAmount = constrain(preset.getFloat("noiseAmount", noiseAmount), 0, 0.5);
	grainBalance = constrain(preset.getFloat("grainBalance", DEFAULT_GRAIN_BALANCE), 0, 1);
	verticalBanding = constrain(preset.getFloat("verticalBanding", verticalBanding), 0, 1);
	horizontalBanding = constrain(preset.getFloat("horizontalBanding", horizontalBanding), 0, 1);
	syncParameterControls();

	String name = preset.getString("name", "preset");
	saveStatus = "loaded preset " + name;
	saveStatusFrames = 240;
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
		|| toneSeed == null || toneNoise == null || verticalBandProfile == null || horizontalBandProfile == null) {
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

public synchronized void onImageFileSelected(File selection) {
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

// Image selection callbacks may run on a different thread from draw(). Keep
// buffer replacement atomic with respect to simulation steps.
synchronized void clearSimulationBuffers() {
	simulationReady = false;
	simView = null;
	toneSeed = null;
	toneNoise = null;
	verticalBandProfile = null;
	horizontalBandProfile = null;
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

synchronized void initializeSimulation() {
	clearSimulationBuffers();

	simW = sourceImage.width;
	simH = sourceImage.height;
	simSize = simW * simH;
	iterationCount = 0;
	renderedIteration = -1;

	toneSeed = new float[simSize];

	devA = new float[simSize];
	devB = new float[simSize];

	exhaustedA = new float[simSize];
	exhaustedB = new float[simSize];

	developedA = new float[simSize];
	developedB = new float[simSize];
	toneNoise = new float[simSize];
	verticalBandProfile = new float[simW];
	horizontalBandProfile = new float[simH];

	loadToneSeed();
	buildBandProfile(verticalBandProfile);
	buildBandProfile(horizontalBandProfile);

	simView = createImage(simW, simH, RGB);
	simulationReady = true;
}

void loadToneSeed() {
	sourceImage.loadPixels();
	float toe = min(curveToeStops, curveShoulderStops - 0.01);
	float shoulder = max(curveShoulderStops, toe + 0.01);

	for (int y = 0; y < simH; y++) {
		int srcY = y;
		for (int x = 0; x < simW; x++) {
			int srcX = x;
			int srcIdx = srcY * sourceImage.width + srcX;
			int idx = y * simW + x;

			float b = max(brightness(sourceImage.pixels[srcIdx]) / 255.0, 0.0001);
			float logExposure = -log(b) / log(2.0) + exposureStops;
			float response = constrain((logExposure - toe) / (shoulder - toe), 0, 1);
			float t = response * response * (3.0 - 2.0 * response);
			float n = random(-1.0, 1.0);

			toneSeed[idx] = t;
			toneNoise[idx] = n;
			devA[idx] = 0;
			exhaustedA[idx] = 0;
			developedA[idx] = pow(t, 1.6) * 0.015;
		}
	}
}

void buildBandProfile(float[] profile) {
	for (int i = 0; i < profile.length; i++) {
		profile[i] = random(-1.0, 1.0);
	}

	float[] temp = new float[profile.length];
	for (int pass = 0; pass < 6; pass++) {
		for (int i = 0; i < profile.length; i++) {
			float c = profile[i] * 0.5;
			float l = profile[max(0, i - 1)] * 0.25;
			float r = profile[min(profile.length - 1, i + 1)] * 0.25;
			temp[i] = c + l + r;
		}

		arrayCopy(temp, profile);
	}

	float maxAbs = 0.0001;
	for (int i = 0; i < profile.length; i++) {
		maxAbs = max(maxAbs, abs(profile[i]));
	}
	for (int i = 0; i < profile.length; i++) {
		profile[i] /= maxAbs;
	}
}

synchronized void stepSimulation() {
	if (devA == null || devB == null || exhaustedA == null || exhaustedB == null || developedA == null || developedB == null
		|| toneSeed == null || toneNoise == null || verticalBandProfile == null || horizontalBandProfile == null) {
		return;
	}

	// Keep hot data and dimensions local so the JVM can eliminate repeated
	// field lookups and array bounds checks in this full-image loop.
	final int w = simW;
	final int h = simH;
	final float[] currentDev = devA;
	final float[] currentExhausted = exhaustedA;
	final float[] currentDeveloped = developedA;
	final float[] nextDevBuffer = devB;
	final float[] nextExhaustedBuffer = exhaustedB;
	final float[] nextDevelopedBuffer = developedB;
	final float diagonalWeight = 0.7071;
	// Accumulate in the same order as neighborhoodDeveloper() so this fast
	// path has the same floating-point denominator as the original code.
	float interiorWeight = 0;
	interiorWeight += diagonalWeight;
	interiorWeight += 1.0;
	interiorWeight += diagonalWeight;
	interiorWeight += 1.0;
	interiorWeight += 1.0;
	interiorWeight += diagonalWeight;
	interiorWeight += 1.0;
	interiorWeight += diagonalWeight;

	for (int y = 0; y < h; y++) {
		int row = y * w;
		float horizontalBand = horizontalBandProfile[y] * horizontalBanding;
		for (int x = 0; x < w; x++) {
			int idx = row + x;

			float localDev = currentDev[idx];
			float localExhausted = currentExhausted[idx];
			float localDeveloped = currentDeveloped[idx];
			float verticalBand = verticalBandProfile[x] * verticalBanding;
			float darkTone = constrain((toneSeed[idx] - 0.75) / 0.25, 0, 1);
			float darkToneWeight = darkTone * darkTone * (3.0 - 2.0 * darkTone);
			float toneWeight = lerp(darkToneWeight, 1.0, grainBalance);
			float localNoiseAmount = noiseAmount * toneWeight * (1.0 + verticalBand) * (1.0 + horizontalBand);
			float t = constrain(toneSeed[idx] + toneNoise[idx] * localNoiseAmount, 0, 1);

			float neighborDev;
			if (x > 0 && x < w - 1 && y > 0 && y < h - 1) {
				// The vast majority of pixels have all eight neighbors. Handling
				// that case directly avoids 18 bounds checks and a method call per
				// pixel; border pixels retain the original general implementation.
				int above = idx - w;
				int below = idx + w;
				float neighborSum = currentDev[above - 1] * diagonalWeight;
				neighborSum += currentDev[above];
				neighborSum += currentDev[above + 1] * diagonalWeight;
				neighborSum += currentDev[idx - 1];
				neighborSum += currentDev[idx + 1];
				neighborSum += currentDev[below - 1] * diagonalWeight;
				neighborSum += currentDev[below];
				neighborSum += currentDev[below + 1] * diagonalWeight;
				neighborDev = neighborSum / interiorWeight;
			} else {
				neighborDev = neighborhoodDeveloper(x, y);
			}

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

			nextDevBuffer[idx] = nextDev;
			nextExhaustedBuffer[idx] = nextExhausted;
			nextDevelopedBuffer[idx] = nextDeveloped;
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
	float baseReflectance = pow(10.0, -paperBaseDensity);
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

		// Paper base-plus-fog density limits maximum reflectance. Applying it
		// after the image tone keeps this rendering property out of development.
		r *= baseReflectance;
		g *= baseReflectance;
		b *= baseReflectance;

		view.pixels[i] = color(r, g, b);
	}

	view.updatePixels();
	renderedIteration = iterationCount;
	renderedLightHue = lightHue;
	renderedLightSaturation = lightSaturation;
	renderedPaperBaseDensity = paperBaseDensity;
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
