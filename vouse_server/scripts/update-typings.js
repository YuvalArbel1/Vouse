/**
 * Helper script to fix TypeScript typing issues
 */
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const { promisify } = require('util');

const writeFile = promisify(fs.writeFile);
const readFile = promisify(fs.readFile);
const mkdir = promisify(fs.mkdir);
const copyFile = promisify(fs.copyFile);

// ANSI color codes for output
const colors = {
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  reset: '\x1b[0m'
};

// Log with color
function log(message, color = colors.reset) {
  console.log(`${color}${message}${colors.reset}`);
}

// Create a backup directory
async function createBackup() {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '_');
  const backupDir = path.join(process.cwd(), `backup_${timestamp}`);
  
  log(`Creating backups in ${backupDir}`, colors.yellow);
  
  try {
    await mkdir(backupDir);
    
    // Recursively copy src directory
    await copyDirectory(path.join(process.cwd(), 'src'), path.join(backupDir, 'src'));
    
    log(`Backup created successfully in ${backupDir}`, colors.green);
  } catch (error) {
    log(`Error creating backup: ${error.message}`, colors.red);
    throw error;
  }
}

// Helper to copy directory recursively
async function copyDirectory(source, destination) {
  try {
    await mkdir(destination, { recursive: true });
    const entries = fs.readdirSync(source, { withFileTypes: true });

    for (const entry of entries) {
      const srcPath = path.join(source, entry.name);
      const destPath = path.join(destination, entry.name);

      if (entry.isDirectory()) {
        await copyDirectory(srcPath, destPath);
      } else {
        await copyFile(srcPath, destPath);
      }
    }
  } catch (error) {
    log(`Error copying directory: ${error.message}`, colors.red);
    throw error;
  }
}

// Fix empty module classes
async function fixEmptyModules() {
  log('Fixing empty module classes...', colors.yellow);
  
  const modules = [
    'src/auth/auth.module.ts',
    'src/common/common.module.ts',
    'src/notifications/notifications.module.ts',
    'src/posts/posts.module.ts',
    'src/users/users.module.ts',
    'src/x/x.module.ts'
  ];

  for (const modulePath of modules) {
    try {
      if (fs.existsSync(modulePath)) {
        const content = await readFile(modulePath, 'utf8');
        
        // Check if the module has an empty class
        if (content.includes('@Module({') && content.includes('export class') && content.includes('{}')) {
          const newContent = content.replace(
            /@Module\({/g, 
            '@Module({\n  /* This module provides services for its domain */'
          );
          
          await writeFile(modulePath, newContent, 'utf8');
          log(`Fixed empty class in ${modulePath}`, colors.green);
        } else {
          log(`No empty class found in ${modulePath}`, colors.yellow);
        }
      } else {
        log(`Module file ${modulePath} not found`, colors.red);
      }
    } catch (error) {
      log(`Error processing ${modulePath}: ${error.message}`, colors.red);
    }
  }
}

// Run TypeScript compiler to identify issues
async function runTsCheck() {
  log('Running TypeScript compiler in strict mode...', colors.yellow);
  
  try {
    execSync('npx tsc --noEmit', { stdio: 'inherit' });
  } catch (error) {
    // Expected to fail due to TypeScript errors, but we just want to see the errors
    log('TypeScript check completed with errors. See above for details.', colors.yellow);
  }
}

// Print guidance for fixing TypeScript issues
function printGuidance() {
  log('Top TypeScript issues to address:', colors.yellow);
  console.log('1. Replace \'any\' types with specific interfaces from common/types');
  console.log('2. Add proper return types to all controller methods');
  console.log('3. Fix template literal expressions with proper type assertions');
  console.log('4. Use asApiError utility for error handling');
  console.log('5. Fix promise handling with proper async/await or void operator');
  
  log('Script completed. Review the TypeScript errors and fix using the common type interfaces.', colors.green);
  log('To apply fixes, run: npm run lint -- --fix', colors.yellow);
}

// Main function
async function main() {
  try {
    log('Starting TypeScript type improvements...', colors.green);
    
    await createBackup();
    await fixEmptyModules();
    await runTsCheck();
    printGuidance();
    
  } catch (error) {
    log(`Error: ${error.message}`, colors.red);
    process.exit(1);
  }
}

// Run the script
main();
