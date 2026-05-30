export interface MealPhotoUploadConfig {
  isDebug: 0 | 1;
  cloudinaryCloudName: string;
  cloudinaryUploadPreset: string;
  defaultUserId: string;
  storageRoot: string;
  storageEnvironment: string;
  compressionThresholdBytes: number;
  maxImageWidth: number;
  imageQuality: number;
}

export const mealPhotoUploadConfig: MealPhotoUploadConfig = {
  isDebug: 0,
  cloudinaryCloudName: 'dxdmkv4bt',
  cloudinaryUploadPreset: 'fitrpg_meals_unsigned',
  defaultUserId: '1',
  storageRoot: 'fitrpg',
  storageEnvironment: 'local',
  compressionThresholdBytes: 1_000_000,
  maxImageWidth: 1080,
  imageQuality: 0.8,
};
