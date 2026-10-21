import fs from 'node:fs';
import path from 'node:path';

const requiredFiles = [
  'settings.gradle.kts',
  'build.gradle.kts',
  'gradle/libs.versions.toml',
  'app/build.gradle.kts',
  'app/src/main/AndroidManifest.xml',
  'app/src/main/res/values/strings.xml',
  'app/src/main/res/drawable/ic_launcher_foreground.xml',
  'app/src/main/res/drawable/ic_launcher_background.xml',
  'app/src/main/java/com/example/MainActivity.kt',
  'app/src/main/java/com/example/ui/AarghScreen.kt',
  'app/src/main/java/com/example/viewmodel/AarghViewModel.kt',
  'app/src/main/java/com/example/webview/AarghWebViewHolder.kt',
  'app/src/main/assets/aargh_bundle/index.html',
  'app/src/main/assets/aargh_bundle/aargh_payload.tar',
  'app/src/main/assets/aargh_bundle/swirl_offline_engine.R',
  'app/src/main/assets/aargh_bundle/webr/webr.mjs'
];

for (const rel of requiredFiles) {
  if (!fs.existsSync(path.resolve(rel))) {
    console.error(`Missing required project file: ${rel}`);
    process.exit(1);
  }
}

console.log('All Android Kotlin/Compose sources and offline webR/swirl bundle assets verified.');
