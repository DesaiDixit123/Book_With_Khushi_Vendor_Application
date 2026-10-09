const fs = require('fs');
const file = '/Users/rushabhdesai/Desktop/Khushi_Holidays/khushi_vendor_app/android/build.gradle.kts';
let content = fs.readFileSync(file, 'utf8');

const regex1 = /subprojects \{\n\s*project\.evaluationDependsOn\(":app"\)\n\}\n\n/;
const match1 = content.match(regex1);
if (match1) {
    content = content.replace(regex1, '');
    const regex2 = /(subprojects \{\n\s*afterEvaluate \{[\s\S]*?\n\s*\}\n\}\n)/;
    content = content.replace(regex2, `$1\nsubprojects {\n    project.evaluationDependsOn(":app")\n}\n`);
    fs.writeFileSync(file, content);
    console.log("Patched successfully!");
} else {
    console.log("Could not find the target text.");
}
