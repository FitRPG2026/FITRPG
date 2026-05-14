export interface MealPhotoStorageName {
  asset_folder: string;
  public_id: string;
  public_id_prefix: string;
  display_name: string;
  original_file_name: string;
}

export interface MealReviewDraft {
  image_name: string;
  created_at: string;
  caption: string;
  url: string;
  rating: number | null;
  storage: MealPhotoStorageName;
}

export interface LocalMealReviewResult {
  success: boolean;
  status: number;
  message: string;
  meal_review: MealReviewDraft;
}

export interface CloudinaryUploadResponse {
  secure_url: string;
  public_id: string;
  original_filename?: string;
  created_at?: string;
  bytes?: number;
  width?: number;
  height?: number;
}
