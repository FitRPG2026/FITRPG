export interface CloudinaryUploadResponse {
  secure_url: string;
  public_id?: string;
  asset_folder?: string;
}

export interface MealImagePayload {
  image_url: string;
}

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
  blob_url: string;
  meal_review: MealReviewDraft;
}

export interface MealImageResult {
  imageUrl: string;
  localOnly: boolean;
}

export interface BackendMealImageResult {
  success: boolean;
  image_url: string;
  localOnly?: boolean;
}
