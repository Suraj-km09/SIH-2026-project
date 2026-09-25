import fs from 'fs';
import path from 'path';

export interface SecurityCheckResult {
  isSecure: boolean;
  issues: string[];
}

export interface AndroidConfigCheckResult {
  isValid: boolean;
  issues: string[];
}

/**
 * Parses the release build type block from Gradle script content.
 */
export function extractReleaseBlock(gradleContent: string): string | null {
  if (!gradleContent) return null;
  const releaseMatch = gradleContent.match(/release\s*\{([\s\S]*?)\n\s*\}/);
  return releaseMatch ? releaseMatch[1] : null;
}

/**
 * Validates security rules for the Android Gradle build script.
 */
export function validateReleaseSigningSecurity(gradleContent: string): SecurityCheckResult {
  const issues: string[] = [];
  const releaseBlock = extractReleaseBlock(gradleContent);

  if (!releaseBlock) {
    issues.push('Missing release build type configuration block');
    return { isSecure: false, issues };
  }

  // Check for debug signing key usage in release build type
  if (
    releaseBlock.includes('signingConfigs.getByName("debug")') ||
    releaseBlock.includes('signingConfigs.debug') ||
    /signingConfig\s*=\s*signingConfigs\.(getByName\("debug"\)|debug)/.test(releaseBlock)
  ) {
    issues.push('Release build is configured to use the debug signing key (signingConfigs.getByName("debug")).');
  }

  // Check if signingConfig is missing entirely in release block
  if (!/signingConfig\s*=/.test(releaseBlock)) {
    issues.push('Release build type does not configure a signingConfig.');
  }

  return {
    isSecure: issues.length === 0,
    issues,
  };
}

/**
 * Validates required Android build parameters.
 */
export function validateAndroidBuildConfig(gradleContent: string): AndroidConfigCheckResult {
  const issues: string[] = [];

  if (!gradleContent || gradleContent.trim() === '') {
    return { isValid: false, issues: ['Gradle file content is empty.'] };
  }

  if (!/namespace\s*=\s*"[^"]+"/.test(gradleContent)) {
    issues.push('Missing or invalid namespace definition.');
  }

  if (!/compileSdk\s*=\s*\d+/.test(gradleContent)) {
    issues.push('Missing compileSdk configuration.');
  }

  if (!/minSdk\s*=/.test(gradleContent)) {
    issues.push('Missing minSdk configuration.');
  }

  if (!/targetSdk\s*=/.test(gradleContent)) {
    issues.push('Missing targetSdk configuration.');
  }

  if (!gradleContent.includes('JavaVersion.VERSION_17')) {
    issues.push('Target Java compatibility JavaVersion.VERSION_17 is missing.');
  }

  return {
    isValid: issues.length === 0,
    issues,
  };
}

describe('Android Gradle Build Script Security & Integrity', () => {
  const possiblePaths = [
    path.resolve(__dirname, '../android/app/build.gradle.kts'),
    path.resolve(process.cwd(), 'android/app/build.gradle.kts'),
  ];

  let gradleFilePath = possiblePaths[0];

  describe('Unit Tests: validateReleaseSigningSecurity', () => {
    it('should flag insecure debug signing in release build', () => {
      const mockGradle = `
        android {
          buildTypes {
            release {
              signingConfig = signingConfigs.getByName("debug")
            }
          }
        }
      `;
      const result = validateReleaseSigningSecurity(mockGradle);
      expect(result.isSecure).toBe(false);
      expect(result.issues).toContain(
        'Release build is configured to use the debug signing key (signingConfigs.getByName("debug")).'
      );
    });

    it('should pass with proper release signing config', () => {
      const mockGradle = `
        android {
          buildTypes {
            release {
              signingConfig = signingConfigs.getByName("release")
            }
          }
        }
      `;
      const result = validateReleaseSigningSecurity(mockGradle);
      expect(result.isSecure).toBe(true);
      expect(result.issues).toHaveLength(0);
    });

    it('should report issue when release block is missing', () => {
      const mockGradle = `
        android {
          buildTypes {
            debug {
              signingConfig = signingConfigs.getByName("debug")
            }
          }
        }
      `;
      const result = validateReleaseSigningSecurity(mockGradle);
      expect(result.isSecure).toBe(false);
      expect(result.issues).toContain('Missing release build type configuration block');
    });

    it('should report issue when release block has no signingConfig', () => {
      const mockGradle = `
        android {
          buildTypes {
            release {
              isMinifyEnabled = true
            }
          }
        }
      `;
      const result = validateReleaseSigningSecurity(mockGradle);
      expect(result.isSecure).toBe(false);
      expect(result.issues).toContain('Release build type does not configure a signingConfig.');
    });

    it('should handle null or empty content gracefully', () => {
      const result = validateReleaseSigningSecurity('');
      expect(result.isSecure).toBe(false);
      expect(result.issues).toContain('Missing release build type configuration block');
    });
  });

  describe('Unit Tests: validateAndroidBuildConfig', () => {
    it('should return invalid for empty gradle content', () => {
      const result = validateAndroidBuildConfig('');
      expect(result.isValid).toBe(false);
      expect(result.issues).toContain('Gradle file content is empty.');
    });

    it('should report missing namespace or SDK versions', () => {
      const mockGradle = `
        android {
          compileSdk = 37
        }
      `;
      const result = validateAndroidBuildConfig(mockGradle);
      expect(result.isValid).toBe(false);
      expect(result.issues).toContain('Missing or invalid namespace definition.');
      expect(result.issues).toContain('Missing minSdk configuration.');
      expect(result.issues).toContain('Missing targetSdk configuration.');
    });

    it('should validate correctly configured gradle content', () => {
      const mockGradle = `
        android {
          namespace = "ai.mineintel.mineintel_ai"
          compileSdk = 37
          compileOptions {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
          }
          defaultConfig {
            minSdk = flutter.minSdkVersion
            targetSdk = flutter.targetSdkVersion
          }
        }
      `;
      const result = validateAndroidBuildConfig(mockGradle);
      expect(result.isValid).toBe(true);
      expect(result.issues).toHaveLength(0);
    });
  });

  describe('Integration Test: android/app/build.gradle.kts file analysis', () => {
    let gradleContent: string;

    beforeAll(() => {
      const foundPath = possiblePaths.find((p) => fs.existsSync(p));
      if (foundPath) {
        gradleFilePath = foundPath;
        gradleContent = fs.readFileSync(gradleFilePath, 'utf-8');
      }
    });

    it('should verify build.gradle.kts exists and is non-empty', () => {
      expect(gradleContent).toBeDefined();
      expect(gradleContent.trim().length).toBeGreaterThan(0);
    });

    it('should satisfy basic Android build configuration requirements', () => {
      if (!gradleContent) return;
      const result = validateAndroidBuildConfig(gradleContent);
      expect(result.issues).toHaveLength(0);
      expect(result.isValid).toBe(true);
    });

    it('should NOT sign release builds with debug certificate', () => {
      if (!gradleContent) return;
      const securityResult = validateReleaseSigningSecurity(gradleContent);
      expect(securityResult.issues).not.toContain(
        'Release build is configured to use the debug signing key (signingConfigs.getByName("debug")).'
      );
      expect(securityResult.isSecure).toBe(true);
    });
  });
});