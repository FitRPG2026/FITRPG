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
