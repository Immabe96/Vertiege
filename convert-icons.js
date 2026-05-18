const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

const sizes = {
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

const resDir = path.join(__dirname, 'android', 'app', 'src', 'main', 'res');

async function convertIcon(svgFile, outputName) {
  const svgPath = path.join(__dirname, svgFile);
  const svgContent = fs.readFileSync(svgPath);

  for (const [dir, size] of Object.entries(sizes)) {
    const outDir = path.join(resDir, dir);
    if (!fs.existsSync(outDir)) {
      fs.mkdirSync(outDir, { recursive: true });
    }
    const outPath = path.join(outDir, outputName);
    await sharp(svgContent)
      .resize(size, size)
      .png()
      .toFile(outPath);
    console.log(`Created ${outPath} (${size}x${size})`);
  }
}

(async () => {
  await convertIcon('veritiege-light-mode.svg', 'ic_launcher.png');
  await convertIcon('veritiege-dark-mode.svg', 'ic_launcher_round.png');
  console.log('Done!');
})();
