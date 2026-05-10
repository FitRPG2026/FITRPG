export interface MealPhotoUploadConfig {
  cloudName: string;
  uploadPreset: string;
  backendBaseUrl: string;
  storageRoot: string;
  storageEnvironment: string;
  useLocalMock: boolean;
}

export const mealPhotoUploadConfig: MealPhotoUploadConfig = {
  cloudName: '',
  uploadPreset: '',
  backendBaseUrl: 'http://localhost:8000',
  storageRoot: 'fitrpg',
  storageEnvironment: 'local',
  useLocalMock: true,
};
